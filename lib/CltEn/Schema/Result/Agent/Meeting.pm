package CltEn::Schema::Result::Agent::Meeting;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/TimeStamp/);
__PACKAGE__->table('agent_meeting');
__PACKAGE__->add_columns(
                'id' => {
                    data_type => 'bigint',
                    is_nullable => 0,
                    is_auto_increment => 1,
                },
                'initiating_agent_id' => {
                    data_type => 'bigint',
                    is_nullable => 0,
                },
                'confirming_agent_id' => {
                    data_type => 'bigint',
                    is_nullable => 0,
                },
                'status' => {
                    data_type => 'enum',
                    size => 50,
                    extra => {
                        list => [qw/proposed confirmed/],
                    },
                    default_value => 'proposed',
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
__PACKAGE__->add_unique_constraint('agent_ids_key' => ['initiating_agent_id', 'confirming_agent_id']);
__PACKAGE__->belongs_to('initiating_agent', 'CltEn::Schema::Result::Agent', 'initiating_agent_id');
__PACKAGE__->belongs_to('confirming_agent', 'CltEn::Schema::Result::Agent', 'confirming_agent_id');

1;
