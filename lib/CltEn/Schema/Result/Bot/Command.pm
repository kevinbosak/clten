package CltEn::Schema::Result::Bot::Command;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/TimeStamp/);
__PACKAGE__->table('bot_command');
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
                'name' => {
                    data_type => 'varchar',
                    size => 50,
                    is_nullable => 0,
                },
                'help_text' => {
                    data_type => 'text',
                    is_nullable => 1,
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
__PACKAGE__->has_many('room_commmands', 'CltEn::Schema::Result::Bot::RoomCommand', 'command_id');

1;
