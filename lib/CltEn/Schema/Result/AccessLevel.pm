package CltEn::Schema::Result::AccessLevel;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/TimeStamp/);
__PACKAGE__->table('access_level');
__PACKAGE__->add_columns(
                'id' => {
                    data_type => 'bigint',
                    is_nullable => 0,
                    is_auto_increment => 1,
                },
                'value' => {
                    data_type => 'integer',
                    is_nullable => 0,
                },
                'name' => {
                    data_type => 'varchar',
                    size => 50,
                },
                'required_level' => {
                    data_type => 'int',
                    default_value => 0,
                    is_nullable => 0,
                },
                'required_mets' => {
                    data_type => 'int',
                    default_value => 0,
                    is_nullable => 0,
                },
                'met_access_level_id' => {
                    data_type => 'bigint',
                    is_nullable => 1,
                },
                'is_active' => {
                    data_type => 'boolean',
                    default_value => 1,
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
__PACKAGE__->has_many('agents', 'CltEn::Schema::Result::Agent', 'access_level_id');
__PACKAGE__->has_many('rooms', 'CltEn::Schema::Result::Room', 'access_level_id');
__PACKAGE__->has_many('drawings', 'CltEn::Schema::Result::Drawing', 'access_level_id');
__PACKAGE__->belongs_to('met_access_level', 'CltEn::Schema::Result::AccessLevel', 'met_access_level_id');

1;
