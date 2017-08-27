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
use DateTime;

my $day_threshold = 21;
my $verbose;
my $help;

GetOptions(
        "day_threshold=i" => \$day_threshold,
        "verbose" => \$verbose,
        "help" => \$help,
);

die 'NO HELP!' if $help;

my $agent_rs = schema->resultset('Agent')->search({
        status => 'active',
        groupme_id => {-not => undef},
    });

my $now = DateTime->now->set_time_zone('UTC');

while (my $agent = $agent_rs->next) {
    my $last_chat = $agent->search_related('chat_logs', {
        }, {
            order_by => 'message_time desc',
            rows => 1,
        })->first();

    if ($last_chat) {
        my $date = $last_chat->message_time;
        $date->set_time_zone('UTC');

        my $duration = $now->delta_days($date);
        my $days = $duration->in_units('days');
#        say $agent->agent_name . ': ' . $days . ': ' . $date;
        next unless $days > $day_threshold;

        $date->set_time_zone('America/New_York');
        print $agent->agent_name . '(' . $agent->id . '): ' . $date->ymd . ' ' . $date->hms . "\n";

    } else {
        print $agent->agent_name . '(' . $agent->id . ")\n";
    }
}
