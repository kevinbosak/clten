package CltEn::Queue;

use warnings;
use 5.020;
use Moo;
use Log::Any;
use CltEn::Util qw(:all);
use Amazon::SQS::Simple;
use JSON;

has 'config' => (
    is => 'ro',
);

has 'queue_url' => (
    is => 'rw',
);

has 'logger' => (
    is => 'ro',
    default => sub {Log::Any->get_logger },
);

has 'queue' => (
    is => 'lazy',
);

has '_current_message' => (
    is => 'rw',
);

sub _build_queue {
    my $self = shift;
    my $sqs = Amazon::SQS::Simple->new($self->config->{AWS_ACCESS_KEY}, $self->config->{AWS_SECRET_KEY} );

    return $sqs->GetQueue($self->queue_url);
}

sub send_message {
    my ($self, $message) = @_;
    my $q = $self->queue; 

    eval{
        $q->SendMessage(encode_json($message));
    };
    if ($@) {
        $self->logger->warning("Could not send SQS message: $@");
        return 0;
    }
    return 1;
}

sub receive_message {
    my ($self, $message) = @_;
    my $q = $self->queue;

    my $received_msg;
    eval { $received_msg = $q->ReceiveMessage()};
    if ($@) {
        $self->logger->warning("Could not receive SQS message: $@");
        return 0;
    }
    return 0 unless $received_msg;
    $self->_current_message($received_msg);

    my $decoded_msg;
    my $msg = $received_msg->MessageBody;

    eval { $decoded_msg = decode_json($msg) };

    if ($@) {
        $self->logger->warning("Could not decode message: $@ : MSG '$msg'");
        die "Could not JSON decode $msg";
    }
    return $decoded_msg;
}

sub clear_message {
    my $self = shift;

    my $q = $self->queue;
    my $msg = $self->_current_message;
    return unless $msg;

    eval { $q->DeleteMessage($msg->ReceiptHandle);};
    if ($@) {
        $self->logger->warning("Could not delete message: $@");
        return 0;
    }
    return 1;
}

1;
