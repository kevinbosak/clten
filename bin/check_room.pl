#!/usr/bin/env perl

use warnings;
use 5.020;
use Dancer qw(:script);
use Dancer::Plugin::DBIC;
use GroupMe;
use CltEn::Manager;
use Log::Any::Adapter;
use Log::Dispatch;
use Data::Dumper;
use Getopt::Long;

my $room_id;
my $verbose;
my $help;

GetOptions(
        "room_id|room=s" => \$room_id,
        "verbose" => \$verbose,
        "help" => \$help,
);

if ($help) {
    help();
    exit;
}

die "Must specify Room ID" unless $room_id;

say "Setting up logger" if $verbose;
my $logfile = '/var/log/clten/log_message.log';
my $logger = Log::Dispatch->new(
    outputs => [
        ['Screen', min_level => 'debug'],
#        ['File', min_level => 'debug', filename => $logfile],
    ],
    callbacks => sub {
        my %params = @_;
        my $dt = DateTime->now();
        return $dt->ymd . ' ' . $dt->hms . ': ' . $params{message};
    },
);
Log::Any::Adapter->set('Dispatch', dispatcher => $logger);

my $token = config->{GM_token};

say "Creating GM object" if $verbose;
my $gm = GroupMe->new(
        token => $token,
    );

say "Creating Manager object" if $verbose;
my $manager = CltEn::Manager->new(
        groupme => $gm,
        schema => schema,
    );

$manager->check_room_members($room_id);
