package CltEn::Schema::Result::RoomAccess;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/TimeStamp/);
__PACKAGE__->table('room_access');
__PACKAGE__->add_columns(
                'id' => {
                    data_type => 'bigint',
                    is_nullable => 0,
                    is_auto_increment => 1,
                },
                'room_id' => {
                    data_type => 'bigint',
                    is_nullable => 0,
                },
                'agent_id' => {
                    data_type => 'bigint',
                    is_nullable => 0,
                },
                'group_user_id' => { # groupme ID for this member in this room
                    data_type => 'bigint',
                    is_nullable => 1,
                },
                'time_added' => {
                    data_type => 'datetime',
                    is_nullable => 1,
                },
                'is_member' => { # user is actually in the room
                    data_type => 'boolean',
                    default_value => 1,
                    is_nullable => 0,
                },
                'can_search' => { # user can search history (regardless of being in the room)
                    data_type => 'boolean',
                    default_value => 1,
                    is_nullable => 0,
                },
                'is_mod' => { # user can boot/add people
                    data_type => 'boolean',
                    default_value => 0,
                    is_nullable => 0,
                },
                # TODO: we probably don't need this ever
                'is_owner' => { # user created the room and therefore cannot leave
                    data_type => 'boolean',
                    default_value => 0,
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
        );

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint('agent_room_access_key' => ['agent_id', 'room_id']);
__PACKAGE__->belongs_to('room', 'CltEn::Schema::Result::Room', 'room_id');
__PACKAGE__->belongs_to('agent', 'CltEn::Schema::Result::Agent', 'agent_id');

1;
