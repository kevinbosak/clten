package clten;
use Dancer ':syntax';
use LWP::UserAgent;
use URI;
use Session::Token;
use JSON qw//;
use JSON::WebToken qw//;
use Data::Dumper;
use Dancer::Plugin::DBIC;
use CltEn::Manager;
use CltEn::Queue;
use GroupMe;

our $VERSION = '0.1';

hook 'before' => sub {
    if (!session('user_id') && request->path_info =~ m{^/(secure|profile|admin)}) {
        session redirect_path => request->path_info;
        return redirect '/';

    } elsif (session('user_id')) {
        my $user = schema->resultset('Agent')->find(session('user_id'), {prefetch => ['access_level', 'room_access']});
        if (!$user || $user->status eq 'deleted') {
            session->destroy();
            return redirect '/';
        }

        var user => $user;
        if (config->{require_frog_code}) {
            unless ($user->status eq 'unregistered' || $user->agreed_to_terms || request->path_info =~ m{^/secure/frog_code} || request->path_info eq '/logout') {
                return redirect '/secure/frog_code';
            }
        }

        return redirect '/profile' if $user->status eq 'unregistered' & request->path_info !~ m{^/profile};
    }
};

get '/' => sub {
    template 'index';
};

get '/help' => sub {
    template 'help';
};

get '/community' => sub {
    template 'community';
};

get '/logout' => sub {
    session->destroy();
    redirect '/';
};

get '/secure/frog_code/agree' => sub {
    my $user = vars->{user};
    $user->update({'agreed_to_terms' => 1}); 
    redirect '/';
};

get '/secure/frog_code' => sub {
    template 'code';
};

get '/secure/group/:room_id/history' => sub {
    my $user = vars->{user};
    my $room = schema->resultset('Room')->find(params->{room_id});

    my $access = $user->room_access->search({room_id => params->{room_id}})->first;
    if ($user->access_level->value < $room->access_level->value || !$access || !$access->is_member) {
        send_error("User not authorized", 403);
    }

    # check that the user has access to the room
    if ($room->is_moderated) {
        # FIXME
    }

    my $page = params->{page} || 1;
    my $per_page = 30;

    my $history_set = $room->search_related('logs', { }, {
            order_by => 'message_time desc',
            rows => $per_page,
            page => $page,
            prefetch => 'agent',
        });
    my $count = $history_set->pager->total_entries;
    my @history = $history_set->all;
#    my $history = [reverse @history];
    my $history = \@history;

    my $pages = $count/$per_page;
    $pages++ if $count % $per_page;

    template 'history', {messages => $history, room => $room, page_count => $pages};
};

post '/secure/groupme/:room_id' => sub {
    my $user = vars->{user};

    my $groupme = GroupMe->new(
            token => config->{GM_token},
        );
    my $manager = CltEn::Manager->new(
            schema => schema,
            groupme => $groupme,
        );


    if (params->{action} eq 'leave') {
        debug($user->id . ' is leaving ' . params->{room_id});
        if (!$manager->remove_user_from_group($user, params->{room_id})) {
            var errors => 'ERROR leaving group';
            warning("Could not leave group, no access found");
        }

    } elsif (params->{action} eq 'join') {
        my $existing_access = $user->room_access->search({is_member => 1, room_id => params->{room_id}})->first;

        # check access
        if ($existing_access) {
            debug("Already joined");

        } else {
            debug("Joining room");

            if (!$manager->add_user_to_group($user, params->{room_id})) {
                var errors => 'Error joining one or more groups';
                warning("ERROR JOINING GROUP");
            }
        }
    }

    return redirect '/secure/groupme';
};

get '/secure/groupme' => sub {
    my $user = vars->{user};

    my @user_rooms = $user->room_access->search({is_member => 1})->all;
    my $joined_rooms = {};
    for my $room (@user_rooms) {
        $joined_rooms->{$room->room_id} = 1;
    }
    my @accessible_rooms = $user->accessible_rooms();
    my @display_rooms = ();
    for my $room (@accessible_rooms) {
        push @display_rooms, $room if $room->is_visible;
    }

    template 'groupme', {accessible_rooms => \@display_rooms, joined_rooms => $joined_rooms};
};

get '/profile' => sub {
    my @pending_meetings = schema->resultset('Agent::Meeting')->search({
            status => 'proposed',
            confirming_agent_id => vars->{user}->id,
        })->all();

    my $confirmed_meetings = schema->resultset('Agent::Meeting')->search({
            status => 'confirmed',
            '-or' => [
                {confirming_agent_id => vars->{user}->id},
                {initiating_agent_id => vars->{user}->id},
            ],
        });

    my @met_agents = ();
    while (my $meeting = $confirmed_meetings->next) {
        if ($meeting->initiating_agent_id != vars->{user}->id) {
            push @met_agents, $meeting->initiating_agent;
        } else {
            push @met_agents, $meeting->confirming_agent;
        }
    }

    template 'profile', {pending_meetings => \@pending_meetings, met_agents => \@met_agents};
};

post '/secure/groupme_connect' => sub {
    my $user = vars->{user};
    my $groupme_info = params->{groupme_info};
    if ($groupme_info) {
        my $groupme = GroupMe->new(
                token => config->{GM_token},
            );
        my $params = {};

        debug("Got Groupme Info: $groupme_info for user " . $user->id);
        if ($groupme_info =~ m/^[(1\-\s]*(\d{3})[)\s\-]*(\d{3})[\s\-]*(\d{4})/) {
            $params->{phone} = '1+ ' . join('', $1,$2,$3);
            debug("PHONE: " . join('', $1,$2,$3));
        } elsif ($groupme_info =~ m/\@/)  {
            debug('EMAIL: ' . $groupme_info);
            $params->{email} = $groupme_info;
        } elsif ($groupme_info =~ m/^\d+$/) {
            $params->{user_id} = $groupme_info;
        } else {
            # FIXME
            warning("INVALID");
            die "INVALID INPUT";
        }

        my $manager = CltEn::Manager->new(
                schema => schema,
                groupme => $groupme,
            );

        if ($manager->add_user_to_group($user, config->{UNVERIFIED_ROOM_ID}, $params)) {
            my $room = schema->resultset('Room')->find(config->{UNVERIFIED_ROOM_ID});
            $groupme->create_message($room->groupme_id, "!welcome");
            return redirect('/secure/groupme');

        } else {
            die "Could not add account";
        }
        return redirect('/secure/groupme');

    } else {
        # FIXME
        die "INVALID INPUT";
    }
};

get '/secure/missions' => sub {
    template 'missions';
};

get '/secure/missions/:mission' => sub {
    my $template = "mission_" . params->{mission};
    template $template;
};

get '/secure/maps' => sub {
    template 'maps';
};

get '/secure/farms/:farm' => sub {
    my $template = "farm_" . params->{farm};
    template $template;
};

post '/profile' => sub {
    my $user = vars->{user};
    my $errors = {};

    for my $field (qw/first_name agent_name agent_level/) {
        if (!params->{$field} || params->{$field} =~ m/^\s*$/) {
            $errors->{$field} = 'required';
        }
    }

    # FIXME: make some fields required
    if (!%$errors) {
        $user->update({
            first_name => params->{first_name},
            last_name => params->{last_name},
            agent_level => params->{agent_level},
            agent_name => params->{agent_name},
            play_area => params->{play_area},
            bio => params->{bio},
            status => 'active',
        });
    }

    template 'profile', {errors => $errors};
};

post '/secure/user/:user_id/meet' => sub {
    my $agent = schema->resultset('Agent')->find(params->{user_id});
    my $user = vars->{user};
    send_error("Agent not found", 404) unless $agent;

    $user->meet_agent(params->{user_id});

    my $referer = request->referer;
    redirect $referer;
};

get '/secure/user/:user_id' => sub {
    my $agent = schema->resultset('Agent')->find(params->{user_id});
    send_error("Agent not found", 404) unless $agent;

    template 'user', {agent => $agent};
};

get '/secure/user' => sub {
    # TODO: sorting
    my $search_params = {is_verified => 1, status => 'active'};
    my $page = params->{page} || 1;
    my $per_page = 30;

    if (my $search = params->{search_terms}) {
        $search_params->{'-or'} = {
            agent_name => {-ilike => '%' . $search . '%'},
            first_name => {-ilike => '%'.$search.'%'},
            last_name  => {-ilike =>  '%'.$search.'%'},
            play_area  => {-ilike =>  '%'.$search.'%'},
        };
    }

    my $initiated_meetings = {};
    my $confirmed_meetings = {};

    my $agent_rs = schema->resultset('Agent')->search($search_params, {
            order_by => 'agent_name',
            rows => $per_page,
            page => $page,
        });
    my @agents = $agent_rs->all;
    for my $agent (@agents) {
        my $initiated_meeting = $agent->search_related('initiated_meeting', { confirming_agent_id => vars->{user}->id })->first();
        $initiated_meetings->{$agent->id} = $initiated_meeting if $initiated_meeting;
        my $confirmed_meeting = $agent->search_related('confirmed_meeting', { initiating_agent_id => vars->{user}->id })->first();
        $confirmed_meetings->{$agent->id} = $confirmed_meeting if $confirmed_meeting;
    }
    my $count = $agent_rs->pager->total_entries;
    my $pages = $count/$per_page;
    $pages++ if $count % $per_page;

    template 'users', {agents => \@agents, initiated_meetings => $initiated_meetings, confirmed_meetings => $confirmed_meetings, page_count => $pages };
};

# TODO: use Net::OAuth2::Profile::WebServer or Net::Google::DataAPI::Auth::OAuth2
post '/login' => sub {
    # get referer so we know where to return user
    # create 'state' token (32 random chars)
    my $state_token = Session::Token->new->get;
    session state_token => $state_token;

    my $uri = URI->new('https://accounts.google.com/o/oauth2/auth');
    $uri->query_form({
            client_id => config->{google_client_id},
            response_type => 'code',
            scope => 'openid profile',
            state => $state_token,
#            login_hint => 'email',
            redirect_uri => config->{oauth_callback},
        });

    redirect $uri->as_string;
};

get '/oauth2callback' => sub {
    my $state_token_retrieved = params->{state};
    my $code = params->{code};
#    my $session_state = params->{session_state};

    if (!$state_token_retrieved || $state_token_retrieved ne session('state_token')) {
        send_error("Invalid state parameter", 401);
    }
    debug('State token matches');

    my $ua = LWP::UserAgent->new;
    my $uri = URI->new('https://www.googleapis.com/oauth2/v3/token');
    my $json = JSON->new;

    debug('Sending POST to: ' . $uri->as_string);
    my $response = $ua->post($uri->as_string, {
        code => $code,
        client_id => config->{google_client_id},
        client_secret => config->{google_client_secret},
        redirect_uri => config->{oauth_callback},
        response_type => 'code',
        grant_type => 'authorization_code',
    });
    debug('Got response');

    my $decoded_response;
    eval { $decoded_response  = $json->decode($response->content);};
    if ($@) {
         die $response->content;
    }
    my $jwt = $decoded_response->{id_token};
    my $jwt_data = JSON::WebToken->decode($jwt, undef, 0);

    # See if user is already registered
    my $google_user = schema->resultset('Agent::Google')->search({
        google_sub => $jwt_data->{sub},
    })->first;
    
    if(!$google_user) {

        my $user = schema->resultset('Agent')->create({access_level_id => config->{UNVERIFIED_ACCESS_LEVEL_ID}});
        send_error("User not authorized", 403) if $user->status eq 'deleted';

        $google_user = $user->create_related('google_account', {
            google_sub => $jwt_data->{sub},
        });
        session user_id => $user->id;
        # FIXME: store any other tokens/expirations? id_token?
        # redirect to registration page
        return redirect '/profile';
    }

    my $user = $google_user->agent;
    session user_id => $user->id;
    my $redirect_to = '/profile';

    if ($user->status ne 'unregistered') {
        $redirect_to = session('redirect_path') || '/';
    }

    session redirect_path => '';
    redirect $redirect_to;
};

any '/admin' => sub {
    my $user = vars->{user};
    return pass if $user->access_level->value >= 500;
    send_error("Not authorized!", 401);
};

get '/admin' => sub {
    template 'admin';
};

get '/admin/groups' => sub {
    my @groups = schema->resultset('Room')->search({})->all();
    template 'admin_groups', {groups => \@groups};
};

any '/admin/groups/:group_id' => sub {
    my @access_levels = schema->resultset('AccessLevel')->search({},{ order_by => 'value' })->all;

    my $group_id = params->{group_id};
    if (request->method eq 'POST') {
        my $params = params;
        delete $params->{group_id};
        if ($params->{is_moderated} eq '1') {
            $params->{is_moderated} = 1;
        } else { 
            $params->{is_moderated} = 0;
        }

        my $groupme = GroupMe->new(
                token => config->{GM_token},
            );
        my $manager = CltEn::Manager->new(
                schema => schema,
                groupme => $groupme,
            );
        my $upload = request->upload('avatar');
#        if (my $upload = request->upload('avatar')) {
        if ($upload) {
            my $url = $groupme->upload_pic($upload->tempname);
            debug("URL: $url");
            $params->{image_url} = $url;
            delete $params->{avatar};
        }

        $manager->update_room($group_id, $params);
#        {
#                name => $params->{name},
#                access_level_id => $params->{access_level_id},
#                topic => $params->{topic},
#            });
    }
    my $group = schema->resultset('Room')->find($group_id);

    template 'admin_group', {group => $group, access_levels => \@access_levels};
};

get '/admin/access_levels' => sub {
    my @access_levels = schema->resultset('AccessLevel')->search({}, {order_by => 'value asc'})->all();
    template 'admin_access_levels', {access_levels => \@access_levels};
};

any '/admin/access_levels/:access_level_id' => sub {
    my $access_level_id = params->{access_level_id};
    my $access_level = schema->resultset('AccessLevel')->find($access_level_id);

    my @access_levels = schema->resultset('AccessLevel')->search({}, {order_by => 'value asc'})->all();

    if (request->method eq 'POST') {
        my $params = params;
        $params->{required_mets} = 0 unless $params->{required_mets};
        $params->{met_access_level_id} = undef unless $params->{met_access_level_id};
        delete $params->{access_level_id};

        $access_level->update($params);
    }

    template 'admin_access_level', {access_level => $access_level, access_levels => \@access_levels};
};

get '/admin/users' => sub {
    # TODO: sorting
    my $search_params = {-not => {status => 'deleted'}};
    my $page = params->{page} || 1;
    my $per_page = 30;

    if (my $search = params->{search_terms}) {
        $search_params->{'-or'} = {
            agent_name => {-ilike => '%' . $search . '%'},
            first_name => {-ilike => '%'.$search.'%'},
            last_name  => {-ilike =>  '%'.$search.'%'},
            play_area  => {-ilike =>  '%'.$search.'%'},
        };
    }

    if (params->{access_level_id}) {
        $search_params->{access_level_id} = params->{access_level_id};
    }
    
    my @access_levels = schema->resultset('AccessLevel')->search({},{ order_by => 'value' })->all;

    my $user_rs = schema->resultset('Agent')->search($search_params, {
            order_by => 'agent_name',
            rows => $per_page,
            page => $page,
        });
    my $count = $user_rs->pager->total_entries;
    my @users = $user_rs->all();

    my $pages = $count/$per_page;
    $pages++ if $count % $per_page;
    template 'admin_users', {users => \@users, access_levels => \@access_levels, page_count => $pages};
};

post '/admin/users/:user_id/verify' => sub {
    my $user_id = params->{user_id};
    my $user = schema->resultset('Agent')->find(params->{user_id});
    send_error('User not found', 404) unless $user;

    $user->update({
            is_verified => 1,
            access_level_id => config->{VERIFIED_ACCESS_LEVEL_ID},
        });

    my $referer = request->referer;
    redirect $referer;
};

any '/admin/users/:user_id' => sub {
    my $user = schema->resultset('Agent')->find(params->{user_id});
    send_error('User not found', 404) unless $user;
    my @access_levels = schema->resultset('AccessLevel')->search({},{ order_by => 'value' })->all;

    if (request->method eq 'POST') {
        my $params = params;
        delete $params->{user_id};
        if ($params->{is_verified} eq '1') {
            $params->{is_verified} = 1;
        } else { 
            $params->{is_verified} = 0;
        }
        $user->update($params);
        # FIXME remove from groups if demoted in level, remove room_access entries too
    }
    my @access = $user->search_related('room_access', {
                is_member => 1,
            }, {
                prefetch => 'room',
#                order_by => 'room.name',
        })->all;

    template 'admin_user', {user => $user, access_levels => \@access_levels, room_access => \@access};
};

post '/bot' => sub {
    # just send to SQS and be done
    my $queue = CltEn::Queue->new(
            queue_url => config->{SQS_INCOMING_QUEUE},
            config => config,
        );

    my $message_data = from_json(request->body);
    $queue->send_message({
            message_type => 'incoming_groupme',
            message_content => $message_data,
            bot => params->{botname},
        });
    return '';
};

true;
