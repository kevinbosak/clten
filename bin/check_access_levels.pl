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

# This script will check for people that meet the requirements for an 
# access level but aren't yet assigned that level

my $notify_chat_id;
my $access_level_id;
my $upgrade_users;
my $skip_agents;
my $verbose;
my $help;

GetOptions(
        "notify_chat_id=i" => \$notify_chat_id,
        "access_level_id=i" => \$access_level_id,
        "upgrade_users"    => \$upgrade_users,
        "skip_agents=s"    => \$skip_agents,
        "verbose" => \$verbose,
        "help" => \$help,
);

my $user_message = "You have met the criteria to gain access to more chats.  Check https://clten.com/secure/groupme to join. This message will self-destruct.";

if ($help) {
    help();
    exit;
}

my @skip_agents = $skip_agents ? split(',', $skip_agents) : ();

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

my @access_levels = (); 
if ($access_level_id) {
    push @access_levels, schema->resultset('AccessLevel')->find($access_level_id);
} else {
    @access_levels = schema->resultset('AccessLevel')->search({}, {order_by => 'value desc'})->all();
}

my $agent_rs = schema->resultset('Agent')->search({
        status => 'active',
    }, {
        prefetch => 'access_level',
    });

my %levels = ();

while (my $agent = $agent_rs->next) {
    next if grep($_ == $agent->id, @skip_agents);
    next unless $agent->groupme_id;

    for my $access_level (@access_levels) {
        $levels{$access_level->name}->{id} = $access_level->id;

        my $required_level = $access_level->required_level;
        my $required_mets = $access_level->required_mets;

        next unless $required_level || $required_mets;
        next if $agent->access_level->value >= $access_level->value;

        if ($required_level) {
            next unless $agent->agent_level >= $required_level;
        }

        if ($required_mets) {
            my $met_access_level = $access_level->met_access_level;
            my $meetings = $agent->meetings($met_access_level->value);

            next unless $meetings >= $required_mets;
        }
        push @{$levels{$access_level->name}->{agents}}, $agent;
    }
}

my $output = $upgrade_users ? "Agents received upgraded access:\n" : "Agents meeting access level requirements:\n";
for my $level_name (keys %levels) {
    my $level = $levels{$level_name};
    my $agents = $level->{agents};
    my $level_id = $level->{id};
    $output .= "  $level_name\n";

    for my $agent (@$agents) {
        $output .= "    " . $agent->id . ': ' . $agent->agent_name . "\n";
        if ($upgrade_users) {
            $agent->update({ access_level_id => $level_id });
            $gm->create_direct_message($agent->groupme_id, $user_message);
        }
    }
}
say $output;

if ($notify_chat_id) {
    my $room = schema->resultset('Room')->find($notify_chat_id);
    die "Could not find room with ID $notify_chat_id" unless $room;
    $gm->create_message($room->groupme_id, $output);
}
