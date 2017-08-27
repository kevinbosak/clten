package CltEn::Schema::Result::Drawing;

use base qw(DBIx::Class::Core);


__PACKAGE__->load_components(qw/TimeStamp +CltEn::Components::WhiteList/);
__PACKAGE__->table('drawing');
__PACKAGE__->add_columns(
                'id' => {
                    data_type => 'integer',
                    is_nullable => 0,
                    is_auto_increment => 1,
                },
                'name' => {
                    data_type => 'varchar',
                    size => 100,
                    is_nullable => 0,
                },
                'owner_id' => {
                    data_type => 'bigint',
                    is_nullable => 0,
                },
                'map_data' => {
                    data_type => 'json',
                    is_nullable => 0,
                },
                'access_level_id' => {
                    data_type => 'bigint',
                    is_nullable => 0,
                },
                'center' => {
                    data_type => 'point',
                    is_nullable => 1,
                },
                'zoom_level' => {
                    data_type => 'integer',
                    is_nullable => 1,
                },
                proposed_throw_time => {
                    data_type => 'datetime',
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
__PACKAGE__->belongs_to('access_level', 'CltEn::Schema::Result::AccessLevel', 'access_level_id');
__PACKAGE__->belongs_to('agent', 'CltEn::Schema::Result::Agent', 'owner_id');

1;
