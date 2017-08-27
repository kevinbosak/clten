#!/usr/bin/env perl

use warnings;
use 5.020;
use Dancer qw(:script);
use Dancer::Plugin::DBIC;
use CltEn::Manager;
use Log::Any::Adapter;
use Log::Dispatch;
use Data::Dumper;
use Getopt::Long;

my $agent1_id;
my $agent2_id;
my $verbose;
my $help;

GetOptions(
        "initiator=i" => \$agent1_id,
        "target=i" => \$agent2_id,
        "verbose" => \$verbose,
        "help" => \$help,
);

if ($help) {
    help();
    exit;
}

die "Must specify both agent IDs" unless $agent1_id && $agent2_id;

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

say "Creating Manager object" if $verbose;
my $manager = CltEn::Manager->new(
        schema => schema,
    );

my $meeting = $manager->meet_user($agent1_id, $agent2_id);

sub help {
    say "\nperl meet_user.pl --initiator 15 --target 4 [--verbose]\n";
    say "    initiator       DB ID of the agent initiating the meeting request";
    say "    target          DB ID of the agent that was met";
    say "    verbose:        Turn on verbosity\n";
}
