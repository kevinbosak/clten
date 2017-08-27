package CltEn::Schema::Result::Bot::RoomCommand;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/TimeStamp/);
__PACKAGE__->table('bot_room_command');
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
                'command_id' => {
                    data_type => 'bigint',
                    is_nullable => 0,
                },
                'alias' => { # overrides name from Command
                    data_type => 'varchar',
                    size => 50,
                    is_nullable => 0,
                },
                'access_level_id' => { # min access level to use the command
                    data_type => 'bigint',
                    is_nullable => 0,
                },
                'mod_only' => { # if true, only mods can use this command, regardless of access level
                    data_type => 'boolean',
                    is_nullable => 0,
                    default_value => 0,
                },
                'time_created' => {
                    data_type => 'datetime',
                    set_on_update => 1,
                    set_on_create => 1,
                },
                'time_updated' => {
                    data_type => 'datetime',
                    set_on_update => 1,
                    set_on_create => 1,
                },
        );

__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('room', 'CltEn::Schema::Result::Room', 'room_id');
__PACKAGE__->belongs_to('command', 'CltEn::Schema::Result::Bot::Command', 'command_id');

1;
