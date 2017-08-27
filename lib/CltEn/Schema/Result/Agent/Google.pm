package CltEn::Schema::Result::Agent::Google;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/TimeStamp/);
__PACKAGE__->table('agent_google');
__PACKAGE__->add_columns(
                'id' => {
                    data_type => 'bigint',
                    is_nullable => 0,
                    is_auto_increment => 1,
                },
                'agent_id' => {
                    data_type => 'bigint',
                    is_nullable => 0,
                },
                'google_sub' => {
                    data_type => 'varchar',
                    size => 50,
                    is_nullable => 0,
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
__PACKAGE__->belongs_to('agent', 'CltEn::Schema::Result::Agent', 'agent_id');

1;
