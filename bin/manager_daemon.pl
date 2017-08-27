#!/usr/bin/perl

use warnings;
use 5.020;
use autodie;
use Dancer qw(:script);
use Dancer::Plugin::DBIC;
use Daemon::Daemonize qw(:all);
use CltEn::Manager;
use CltEn::Queue;
use Log::Any::Adapter;
use Log::Dispatch;
use GroupMe;
use DateTime;

# PURPOSE:
#   Log incoming messages (from incoming queue)
#   Process bot commands (from incoming queue)
#   Manage rooms: change name/topic/add users? (from manager queue)
#   Check room status and fix accordingly (no queue, cron instead?)

my $WAIT_TIME = 1; # wait a second if no messages found
my $logfile = '/var/log/clten/manager.log';

# Check/write pid file
say 'Trying to start...';

my $pidfile = '/var/run/clten/manager.pid';
if (my $pid = check_pidfile($pidfile)) {
    say "Already Running with PID $pid";
    exit();
}

write_pidfile($pidfile);

say 'Trying to Daemonize...';
daemonize(
        chdir => '/home/ubuntu/clten',
        close => 1,
        stderr => '/tmp/error',
    );

my $logger = Log::Dispatch->new(
    outputs => [
        ['File', min_level => 'debug', filename => $logfile, mode => 'append', binmode => ':encoding(UTF-8)'],
    ],
    callbacks => sub {
        my %params = @_;
        my $dt = DateTime->now();
        return $dt->ymd . ' ' . $dt->hms . ': ' . $params{message} . "\n";
    },
);
$logger->info('Started');
Log::Any::Adapter->set('Dispatch', dispatcher => $logger);

my $incoming_queue = CltEn::Queue->new(
    queue_url => config->{SQS_INCOMING_QUEUE},
    config => config,
);

my $groupme = GroupMe->new(
        token => config->{GM_token},
    );
my $manager = CltEn::Manager->new(
        schema => schema,
        groupme => $groupme,
    );

while (1) {
    my $msg = $incoming_queue->receive_message();
    if (!$msg) {
        sleep($WAIT_TIME);
        next;
    }

    $manager->process_message($msg);
    $incoming_queue->clear_message;
}
