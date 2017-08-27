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
use autodie;

my $verbose = 1;
my $old_users = {'L8.users' => 5, 'General.users' => 6};

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

for my $file (keys %$old_users) {
    my $access_level_id = $old_users->{$file};
    my $access_level = schema->resultset('AccessLevel')->find($access_level_id);
    say "$file";

    open(my $fh, $file);

    while (my $gm_id = <$fh>) {
        chomp $gm_id;
        my $user = schema->resultset('Agent')->search({ groupme_id => $gm_id }, { prefetch => 'access_level'})->first();
        next unless $user;

        if ($user->access_level->value < $access_level->value) {
            say $user->agent_name . ' (' . $user->id . ') is ' . $user->access_level->name . ' but should be ' . $access_level->name;
        }
        if (!$user->is_verified) {
            say $user->agent_name . ' (' . $user->id . ') needs to be verified';
        }
    }
    close $fh;
}
