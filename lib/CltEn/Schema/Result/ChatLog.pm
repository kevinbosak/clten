package CltEn::Schema::Result::ChatLog;

use base qw(DBIx::Class::Core);
use JSON;

__PACKAGE__->load_components(qw/TimeStamp/);
__PACKAGE__->table('chat_log');
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
                'room_id' => {
                    data_type => 'bigint',
                    is_nullable => 0,
                },
                'message_id' => {
                    data_type => 'bigint',
                    is_nullable => 0,
                },
                'avatar_url' => {
                    data_type => 'varchar',
                    size => 255,
                    is_nullable => 1,
                },
                'message' => {
                    data_type => 'text',
                    is_nullable => 1,
                },
                'attachments' => {
                    data_type => 'json',
                    is_nullable => 1,
                },
                'hearted_by' => { # agent IDs
                    data_type => 'text[]',
                    default_value => '{}',
                    is_nullable => 1,
                },
                'message_time' => {
                    data_type => 'datetime',
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
__PACKAGE__->add_unique_constraint('room_message_key' => ['room_id', 'message_id']);
__PACKAGE__->belongs_to('room', 'CltEn::Schema::Result::Room', 'room_id');
__PACKAGE__->belongs_to('agent', 'CltEn::Schema::Result::Agent', 'agent_id');
__PACKAGE__->inflate_column('attachments', {
        inflate => sub {decode_json(shift)},
        deflate => sub {encode_json(shift)},
    });

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(name => 'message_id_key', fields => ['message_id']);
}

1;
