package CltEn::Schema::Result::Room;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/TimeStamp +CltEn::Components::WhiteList/);
__PACKAGE__->table('room');
__PACKAGE__->add_columns(
                'id' => {
                    data_type => 'bigint',
                    is_nullable => 0,
                    is_auto_increment => 1,
                },
                'name' => {
                    data_type => 'varchar',
                    size => 200,
                    is_nullable => 0,
                },
                'access_level_id' => {
                    data_type => 'bigint',
                    is_nullable => 0,
                },
                'topic' => {
                    data_type => 'varchar',
                    size => 200,
                    is_nullable => 0,
                },
                'image_url' => {
                    data_type => 'varchar',
                    size => 200,
                    is_nullable => 1,
                },
                'groupme_id' => {
                    data_type => 'varchar',
                    is_nullable => 0,
                },
                'bot_id' => {
                    data_type => 'varchar',
                    size => 50,
                    is_nullable => 1,
                },
                'groupme_bot_token' => {
                    data_type => 'varchar',
                    size => 50,
                    is_nullable => 1,
                },
                'is_moderated' => {
                    data_type => 'boolean',
                    default_value => 0,
                    is_nullable => 0,
                },
                'is_visible' => {
                    data_type => 'boolean',
                    default_value => 1,
                    is_nullable => 0,
                },
                'whitelist' => {
                    data_type => 'integer[]',
                    is_nullable => 0,
                    default_value => \'ARRAY[]::integer[]',
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
__PACKAGE__->add_unique_constraint('room_groupme_id_key' => ['groupme_id']);
__PACKAGE__->has_many('room_access', 'CltEn::Schema::Result::RoomAccess', 'room_id');
__PACKAGE__->has_many('logs', 'CltEn::Schema::Result::ChatLog', 'room_id');
__PACKAGE__->belongs_to('access_level', 'CltEn::Schema::Result::AccessLevel', 'access_level_id');
__PACKAGE__->has_many('bot_commands', 'CltEn::Schema::Result::Bot::RoomCommand', 'room_id');

1;
