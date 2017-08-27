package CltEn::Schema::Result::Agent;

use CltEn::Util qw(has_access);
use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/TimeStamp/);
__PACKAGE__->table('agent');
__PACKAGE__->add_columns(
                'id' => {
                    data_type => 'bigint',
                    is_nullable => 0,
                    is_auto_increment => 1,
                },
                'access_level_id' => {
                    data_type => 'bigint',
                    is_nullable => 0,
                },
                'groupme_id' => {
                    data_type => 'varchar',
                    size => 50,
                    is_nullable => 1,
                },
                'agent_name' => {
                    data_type => 'varchar',
                    size => 50,
                    is_nullable => 1,
                },
                'agent_level' => {
                    data_type => 'int',
                    is_nullable => 1,
                },
                'first_name' => {
                    data_type => 'varchar',
                    size => 50,
                    is_nullable => 1,
                },
                'last_name' => {
                    data_type => 'varchar',
                    size => 50,
                    is_nullable => 1,
                },
                'play_area' => {
                    data_type => 'varchar',
                    size => 255,
                    is_nullable => 1,
                },
                'bio' => {
                    data_type => 'text',
                    is_nullable => 1,
                },
                'is_verified' => {
                    data_type => 'boolean',
                    default_value => 0,
                    is_nullable => 0,
                },
                'gplus' => {
                    data_type => 'varchar',
                    size => 100,
                    is_nullable => 1,
                },
                'agreed_to_terms' => {
                    data_type => 'boolean',
                    default_value => 0,
                    is_nullable => 0,
                },
                'status' => {
                    data_type => 'enum',
                    size => 100,
                    extra => {
                        list => [qw/unregistered active deleted/],
                    },
                    default_value => 'unregistered',
                    is_nullable => 0,
                },
                'time_created' => {
                    data_type => 'datetime',
                    set_on_create => 1,
                },
                'time_updated' => {
                    data_type => 'datetime',
                    set_on_update => 1,
                    set_on_create => 1,
                },
                # TODO:
                # google/G+ integration fields? or separate table?
        );

sub accessible_rooms {
    my $self = shift;

    my $schema = $self->result_source->schema;

    my $access_levels = $schema->resultset('AccessLevel')->search({
            value => {'<=' => $self->access_level->value},
        }, {
            prefetch => 'rooms',
    });

    my @accessible_rooms = ();

    while (my $access_level = $access_levels->next) {
        push @accessible_rooms, $access_level->rooms->all;
    }

    return wantarray ? @accessible_rooms : \@accessible_rooms;
}

sub join_room {
    my ($self, $room_id) = @_;
    
    my $schema = $self->result_source->schema;

    return 0 unless $self->status eq 'active';

    my $room = $schema->resultset('Room')->find($room_id);
    die "Invalid room ID" unless $room;

    # check access
    my @accessible_rooms = $self->accessible_rooms;
    return 0 unless grep {$_->id == $room_id} @accessible_rooms;

    my $room_access;

    if ($room->is_moderated) {
        $room_access = $schema->resultset('RoomAccess')->find({
                room_id => $room_id,
                agent_id => $self->id,
            }, {
                key => 'agent_room_access_key',
        });

    } else {
        $room_access = $schema->resultset('RoomAccess')->find_or_create({
                room_id => $room_id,
                agent_id => $self->id,
            }, {
                key => 'agent_room_access_key',
        });
    }

    return unless $room_access;
    $room_access->update({is_member => 1}) unless $room_access->is_member;

    return $room_access;
}

sub unjoin_room {
    my ($self, $room_id) = @_;

    my $schema = $self->result_source->schema;
    my $room_access = $schema->resultset('RoomAccess')->find_or_create({
            room_id => $room_id,
            agent_id => $self->id,
        }, {
            key => 'agent_room_access_key',
    });
    $room_access->update({is_member => 0}) if $room_access->is_member;

    return $room_access;
}

sub meet_agent {
    my ($self, $agent_id) = @_;
    my $schema = $self->result_source->schema;

    # already initiated a meeting
    return if $self->initiated_meeting->search({
            confirming_agent_id => $agent_id,
        })->first;

    # check for a confirmed meeting, and confirm if necessary
    my $meeting = $self->confirmed_meeting->search({
            initiating_agent_id => $agent_id,
        })->first;

    if ($meeting) {
        $meeting->update({ status => 'confirmed' });

    } else {
        # No existing meeting, so initiate one
        $meeting = $self->initiated_meeting->create({
                confirming_agent_id => $agent_id,
            });
    }
    return $meeting;
}

sub meetings {
    my ($self, $access_level_value) = @_;
    if ($access_level_value) {
        my $initiated = $self->search_related('initiated_meeting', {
                    'me.status' => 'confirmed',
                }, {
                    prefetch => {'confirming_agent' => 'access_level'},
            });
        my $confirmed = $self->search_related('confirmed_meeting', {
                    'me.status' => 'confirmed',
                }, {
                    prefetch => {'initiating_agent' => 'access_level'},
            });
        my $count = 0;
        for my $meet ($initiated->all()) {
            my $agent = $meet->confirming_agent;
#            if ($meet->confirming_agent{status => 'active'})->first->access_level->value >= $access_level_value) {
            next unless $agent->status eq 'active';
            if ($agent->access_level->value >= $access_level_value) {
                $count++;
            }
        }
        for my $meet ($confirmed->all()) {
            my $agent = $meet->initiating_agent;
            next unless $agent->status eq 'active';
            if ($agent->access_level->value >= $access_level_value) {
                $count++;
            }
        }
        return $count;

    } else {
        # FIXME need logic to only look at active agents that were met
        return 
            $self->search_related('initiated_meeting', {status => 'confirmed'})->count 
            + $self->search_related('confirmed_meeting', {status => 'confirmed'})->count;
    }
}

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint('agent_groupme_id_key' => ['groupme_id']);
__PACKAGE__->has_many('room_access', 'CltEn::Schema::Result::RoomAccess', 'agent_id');
__PACKAGE__->has_many('google_account', 'CltEn::Schema::Result::Agent::Google', 'agent_id');
__PACKAGE__->has_many('chat_logs', 'CltEn::Schema::Result::ChatLog', 'agent_id');
__PACKAGE__->has_many('initiated_meeting', 'CltEn::Schema::Result::Agent::Meeting', 'initiating_agent_id');
__PACKAGE__->has_many('confirmed_meeting', 'CltEn::Schema::Result::Agent::Meeting', 'confirming_agent_id');
__PACKAGE__->has_many('drawings', 'CltEn::Schema::Result::Drawing', 'owner_id');
__PACKAGE__->belongs_to('access_level', 'CltEn::Schema::Result::AccessLevel', 'access_level_id');

1;
