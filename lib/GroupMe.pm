package GroupMe;

use warnings;
use 5.020;
use autodie;
use Moo;
use Log::Any;
use Readonly;
use autodie;
use LWP::UserAgent;
use JSON;
use URI;
use Data::GUID;
use Data::Dumper;

Readonly my $BASE_URL => 'https://api.groupme.com/v3';

has '_json' => (
#        isa => 'Object',
        is => 'ro',
        init_arg => undef,
        default => sub {
            return JSON->new();
        },
    );

has '_user_agent' => (
#        isa => 'Object',
        is => 'ro',
        init_arg => undef,
        default => sub {
            return LWP::UserAgent->new();
        },
    );

has 'token_file' => (
#        isa => 'Str',
        is => 'rw',
    );

has 'token' => (
#        isa => 'Str',
        is => 'lazy',
        predicate => 'has_token',
#        default => '',
    );

has 'logger' => (
    is => 'ro',
    default => sub {Log::Any->get_logger },
);

sub _build_token {
    my $self = shift;
#    return if $self->has_token;

    $self->logger->debug('building token');

    die "Must specify a token or token_file attribute" unless $self->token_file || $self->token;

    open my $fh, $self->token_file;
    my $token = <$fh>;
    close $fh;
    $token =~ s/(\n|\s)+//g;
    $self->logger->debug($token);
    return $token;
}

sub _make_call {
    my ($self, $url, $method, $args) = @_;

    $args ||= {};

    my $ua = $self->_user_agent;
    $self->logger->debug("Calling $url with args: " . Dumper $args);

    my $response;
    if($method eq 'GET') {
        $args->{token} = $self->token;
        my $uri = URI->new($url);
        $uri->query_form($args);
        $response = $ua->get($uri->as_string);

    } else {
        my $uri = URI->new($url);
        $uri->query_form({token => $self->token});
        if ($args) {
            $args = $self->_json->encode($args) if $args;
            $response = $ua->post($uri->as_string, Content_Type => 'application/json', Content => $args);
        } else {
            $response = $ua->post($uri->as_string);
        }
    }

    my $response_data = {response_code => $response->code};
    if (!$response || !$response->content) {
        die "Error processing URI: " . $response->status_line . ': ' . $response->content;
    }

    # FIXME no response content on group destroy, code throws an error
    my $decoded_response;
    eval {
        $decoded_response = $self->_json->decode($response->content);
    };
    return if $response->content && $response->content =~ m/^\s*$/;

    if ($response->content && !$decoded_response) {
        die "ERROR decoding response: " . $response->content;
    }
    if ($decoded_response && ($decoded_response->{meta}->{code} == 400 || $decoded_response->{meta}->{code} == 401)) {
        die "Error processing URI: " . $response->status_line;
    }

    $response_data->{errors} = $decoded_response->{meta}->{errors};
    $response_data->{response} = $decoded_response->{response};

    return $response_data;
}

sub get_my_info {
    my $self = shift;

    my $url = $BASE_URL . '/users/me';

    my $response = $self->_make_call($url, 'GET');
    if ($response->{response_code} == 200) {
        my $return = $response->{response};
        return $return;
    }

    return undef;
}

sub get_members {
    my ($self, $group_id) = @_;

    die "Must specify a valid group ID" unless $group_id || $group_id !~ m/^\d+$/;

    my $url = $BASE_URL . '/groups/' . $group_id;
    print "calling $url\n";

    my $response = $self->_make_call($url, 'GET');
    use Data::Dumper;

    print Dumper $response;
    if ($response->{response_code} == 200) {
        my $return = $response->{response}->{members};
        return wantarray ? @$return : $return;
    }

    return undef;
}

sub create_direct_message {
    my ($self, $user_id, $message) = @_;

    my $url = $BASE_URL . "/direct_messages";

    my $guid = Data::GUID->new->as_base64;
    my $message_params = {
        message => {
            source_guid => $guid,
            text => $message,
            recipient_id => $user_id,
        },
    };

    my $response = $self->_make_call($url, 'POST', $message_params);
    if ($response->{response_code} == 201) {
        return $response->{response}->{message}->{id};
    }
    return undef;
}

sub create_message {
    my ($self, $group_id, $message, $attachments) = @_;

    my $url = $BASE_URL . "/groups/$group_id/messages";

    my $guid = Data::GUID->new->as_base64;
    my $message_params = {
        message => {
            source_guid => $guid,
            text => $message,
        },
    };

    if ($attachments && ref $attachments && ref $attachments eq 'ARRAY') {
        $message_params->{message}->{attachments} = $attachments;
    }

    my $response = $self->_make_call($url, 'POST', $message_params);
    if ($response->{response_code} == 201) {
        return $response->{response}->{message}->{id};
    }
    return undef;
}

sub create_group {
    my ($self, $args) = @_;

    die "Must specify a group name" unless $args->{name};

    my $url = $BASE_URL . "/groups";

    my $params = $args;
    # FIXME validate args
    $params->{description} = delete $params->{topic} if $params->{topic};

    my $response = $self->_make_call($url, 'POST', $params);

    if ($response->{response_code} == 201) {
        return $response->{response}->{id};
    }
    return undef;
}

sub update_group {
    my ($self, $group_id, $args) = @_;

    die "Must specify a group ID" unless $group_id;
    # image_url, name, description, share, office_mode are possible args
    
    my $params = {};
    $params->{name} = $args->{name} if $args->{name};
    $params->{description} = $args->{topic} if $args->{topic};
    $params->{image_url} = $args->{image_url} if $args->{image_url};

    # FIXME error checking
    if ($args->{image_path} && -e $args->{image_path}) {
        my $url = $self->upload_pic($args->{image_path});
        $params->{image_url} = $url if $url;
    }

    if (defined $args->{office_mode}) {
        if ($args->{office_mode}) {
            $params->{office_mode} = JSON::true;
        } else {
            $params->{office_mode} = JSON::false;
        }
    }
    if (defined $args->{share}) {
        if ($args->{share}) {
            $params->{share} = JSON::true;
        } else {
            $params->{share} = JSON::false;
        }
    }
    
    return 1 unless %$params;

    my $url = $BASE_URL . "/groups/$group_id/update";

    my $response = $self->_make_call($url, 'POST', $params);

    if ($response->{response_code} == 200) {
        return 1;
    }
    return undef;
}

sub upload_pic {
    my ($self, $filename) = @_;

    die "Must specify a valid filename" unless $filename && -e $filename;

    my $url = 'https://image.groupme.com/pictures';

    my $uri = URI->new($url);
    $uri->query_form({token => $self->token});

#    my $args = $self->_json->encode($args) if $args;
    my $ua = $self->_user_agent;
    my $response = $ua->post($uri->as_string, Content_Type => 'multipart/form-data', Content => [file => [$filename]]);

    my $response_data = {response_code => $response->code};
    if (!$response || !$response->content) {
        die "Error processing URI: " . $response->status_line . ': ' . $response->content;
    }

    my $decoded_response = $self->_json->decode($response->content) if $response->content && length($response->content);

    if ($decoded_response && $decoded_response->{errors}) {
        die "Error processing URI: " . $decoded_response->{errors}->[0];
    }

    return $decoded_response->{payload}->{url};

    return undef;
}

sub add_member {
    my ($self, $group_id, $args) = @_;

    die "Must specify a valid group ID" unless $group_id || $group_id !~ m/^\d+$/;

    die "Nickname is required" unless $args->{nickname};
    die "Need one of user ID, phone #, or email" unless $args->{user_id} || $args->{phone} || $args->{email};

    my $url = $BASE_URL . "/groups/$group_id/members/add";
    my $guid = Data::GUID->new->as_base64;

    my $message_params = {
        members => [{
            guid => $guid,
            nickname => $args->{nickname},
        }]
    };

    if ($args->{user_id}) {
        $message_params->{members}->[0]->{user_id} = $args->{user_id};

    } elsif ($args->{phone}) {
        $message_params->{members}->[0]->{phone_number} = $args->{phone};

    } else {
        $message_params->{members}->[0]->{email} = $args->{email};
    }

    my $response = $self->_make_call($url, 'POST', $message_params);
    if ($response->{response_code} == 202) {
        return $response->{response}->{results_id};
    }
    return undef;
}

sub check_add_member {
    my ($self, $group_id, $guid) = @_;

    die "Must specify a valid group ID" unless $group_id || $group_id !~ m/^\d+$/;
    die "Must specify a valid request GUID" unless $guid;

    my $url = $BASE_URL . "/groups/$group_id/members/results/$guid";

    my $response = $self->_make_call($url, 'GET');
    if ($response->{response_code} == 200) {
        return $response->{response}->{members};
    }
    return undef;
}

sub remove_member {
    my ($self, $group_id, $membership_id) = @_;

    die "Must specify a valid group ID" unless $group_id || $group_id !~ m/^\d+$/;
    die "Must specify a valid request GUID" unless $membership_id;

    my $url = $BASE_URL . "/groups/$group_id/members/$membership_id/remove";

    my $response = $self->_make_call($url, 'POST');
    if ($response->{response_code} == 200) {
        return 1;
    }
    warn $response->{response_code};
    return undef;
}

sub get_message_count {
    my ($self, $group_id) = @_;

    die "Must specify a valid group ID" unless $group_id || $group_id !~ m/^\d+$/;

    my $url = $BASE_URL . "/groups/$group_id/messages";

    my $response = $self->_make_call($url, 'GET', {limit => 1});
    if ($response->{response_code} == 200) {
        return $response->{response}->{count};
    }
    return undef;
}

sub get_messages {
    my ($self, $group_id, $args) = @_;

    die "Must specify a valid group ID" unless $group_id || $group_id !~ m/^\d+$/;

    my $url = $BASE_URL . "/groups/$group_id/messages";

    my $retrieved = 0;
    my @messages = ();

    my $params = {limit => $args->{per_page} || 50};
    $params->{before_id} = $args->{before_id} if $args->{before_id};
    $params->{since_id} = $args->{since_id} if $args->{since_id};
    $params->{after_id} = $args->{after_id} if $args->{after_id};

    my $max  = $args->{maximum} || 50000;
    my $message_count = $self->get_message_count($group_id);
    $max = $message_count if $max > $message_count;

    while ($retrieved < $max) {
        my $response = $self->_make_call($url, 'GET', $params);

#        if ($response->{response_code} == 200) {
#            return $response->{response}->{messages};
#        }
        return wantarray ? @messages : \@messages if !$response->{response} || !$response->{response}->{messages} || scalar(@{$response->{response}->{messages}}) == 0;

        if (!$params->{after_id} && !$params->{since_id}) {
            $params->{before_id} = $response->{response}->{messages}->[-1]->{id};

        } elsif (!$params->{before_id} && !$params->{since_id}) {
            $params->{after_id} = $response->{response}->{messages}->[-1]->{id};

        } elsif (!$params->{since_id}) {
            # FIXME:
        }

        $retrieved += scalar(@{$response->{response}->{messages}});
#        warn ref $response->{response}->{messages};
        push @messages, @{$response->{response}->{messages}};
    }

    return wantarray ? @messages : \@messages;
}

sub get_group {
    my ($self, $group_id) = @_;

    die "Must specify a valid group ID" unless $group_id || $group_id !~ m/^\d+$/;

    my $url = $BASE_URL . "/groups/$group_id";

    my $group = $self->_make_call($url, 'GET');
    return $group->{response};
}

sub get_groups {
    my ($self, $args) = @_;

    my $url = $BASE_URL . "/groups";
    my $count = 0;
    my $params = {
        per_page => $args->{per_page} || 10,
        page => 1,
    };

    my @groups = ();

    while (1) {
        my $response = $self->_make_call($url, 'GET', $params);
        if ($response->{response_code} == 200) {
            my $page_groups = $response->{response};
            if (@$page_groups > 0) {
                push @groups, @$page_groups;
                $params->{page}++;
            } else {
                return wantarray ? @groups : \@groups;
            }
        } else {
            return;
        }
    }
    return wantarray ? @groups : \@groups;
}

sub delete_group {
    my ($self, $group_id) = @_;

    die "Must specify a valid group ID" unless $group_id || $group_id !~ m/^\d+$/;

    my $url = $BASE_URL . "/groups/$group_id/destroy";

    my $group = $self->_make_call($url, 'POST');
    return 1;
}

sub set_group_image {
    my ($self, $group_id, $image_url) = @_;

    return $self->update_group($group_id, {image_url => $image_url});
}

sub update_user {
    my ($self, $args) = @_;

    my $params = {};
    for (qw/avatar_url name email zip_code/) {
        $params->{$_} = $args->{$_} if defined $args->{$_};
    }
    die "Must specify something" unless keys %$params;

    my $url = $BASE_URL . '/users/update';
    my $response = $self->_make_call($url, 'POST', $params);

    return $response->{response_code} == 200;
}

sub create_bot {
    my ($self, $group_id, $args) = @_;

    die "Must specify a group ID" unless $group_id;
    die "Must specify a bot name" unless $args->{name};

    $args->{group_id} = $group_id;

    my $url = $BASE_URL . '/bots';
    my $response = $self->_make_call($url, 'POST', {bot => $args});
    my $params = {name => $args->{name}};
    $params->{avatar_url} = $args->{avatar_url} if $args->{avatar_url};
    $params->{callback_url} = $args->{callback_url} if $args->{callback_url};

    return $response->{response}->{bot}->{bot_id};
}

sub list_bots {
    my $self = shift;
    my $url = $BASE_URL . '/bots';

    my $response = $self->_make_call($url, 'GET');
    die "Could not get a list of bots" unless $response->{response_code} == 200; 
    return $response->{response};
}

#__PACKAGE__->meta->make_immutable;

1;

