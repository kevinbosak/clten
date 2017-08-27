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

my $group_name;
my $access_level_id;
my $is_moderated = 0;
my $is_hidden = 0;
my $verbose;
my $help;

GetOptions(
        "group_name|group=s" => \$group_name,
        "access_level_id=i" => \$access_level_id,
        "is_moderated" => \$is_moderated,
        "is_hidden" => \$is_hidden,
        "verbose" => \$verbose,
        "help" => \$help,
);

if ($help) {
    help();
    exit;
}

die "Must specify group name" unless $group_name;
die "Must specify access level" unless $access_level_id;

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

my @members = (
#        {name => 'Kevin (philote L15)', id => 9885606},
#        {name => 'Bonnie (MissingPluto)', id => 10145151},
#        {name => 'Andrew (xzre L11)', id => 23649161},
#        {name => 'Jay (PrideV2 L15)', id => 21900829},
#        {name => 'Chase(HKY DeweyB, L10)', id => 9145370},
#        {name => 'Bob (USNA1981 L11)', id => 15090190},
#        {name => 'Brad (Kick808)', id => 10399416},
#        {name => 'Mike (Kimsey L10)', id => 22490185},
#        {name => 'Will (c0leslaw L10)', id => 19278098},
#        {name => 'David (saleenone L15)', id => 17793814},
#        {name => 'David (Forte)', id => },
#        {name => 'Erin (CrustyToe L10)', id => 20018192},
#        {name => 'Ra Sod (DaGodRa)', id => 2283946},
#        {name => 'ke ( Buffy23 L11)', id => 19904746},
#        {name => 'Simon (Dancecommander)', id => 16240617},
#        {name => 'Jeannie (thewhitemouse77 Lvl10)', id => 23445337},
#        {name => 'Scott (Quexser, L15)', id => 13736795},
#        {name => 'Anatol (MoxieKai L15)', id => 13857449},
#        {name => 'Daniel (Zakall)', id => 13728511},
#        {name => 'Bryan (KingJedi L15)', id => 14845535},
#        {name => '"OB" Batista (AnarchystV3)', id => 10128115},
#        {name => 'Marc (digitlgrfx L16)', id => 13729522},
#        {name => 'Jon (SithLordCraven)', id => 9898395},
#        {name => 'Steven (SkyBlast, L15)', id => 14985407},
#        {name => 'Cheryl (AttutudeAngel L10)', id => 20262040},
#        {name => 'Robin (ThursdayLast-L14)', id => 19573974},
#        {name => 'Boyer (ZombieDub L14)', id => 18736885},
#        {name => 'Matt (Snacks28217)', id => 16097921},
#        {name => 'Scott (FreeBeak L15)', id => 10238106},
#        {name => 'Jason (NurseBurster)', id => 17440630},
#        {name => 'Magan (LadyMayMay L10)', id => 20473735},
#        {name => 'Kym (GypsyWalker Lvl 10)', id => 23444450},
#        {name => 'Wayne (PortalHaxxer)', id => 16316150},
#        {name => 'David(ripper58 L11)', id => 10138914},
#        {name => 'Landin (KidGlyph?)', id => 22601102},
);

say "Creating GM object" if $verbose;
my $gm = GroupMe->new(
        token => $token,
    );

say "Creating Manager object" if $verbose;
my $manager = CltEn::Manager->new(
        groupme => $gm,
        schema => schema,
    );

say "Creating Room" if $verbose;
my $room = $manager->create_room({
        group_name => $group_name,
        is_moderated => $is_moderated,
        is_visible => !$is_hidden,
        access_level_id => $access_level_id,
    });

# create bot for the room
$gm->create_bot($room->groupme_id, {
    name => "CltEn HelperBot",
    avatar_url => 'https://i.groupme.com/400x400.png.b1adfb9ab34841989190fddc05c8213f',
});

for my $member (@members) {
    # look up user
    say "Finding Agent " . $member->{name} if $verbose;
    my $agent = schema->resultset('Agent')->find({
                groupme_id => $member->{id},
            }, {
                key => 'agent_groupme_id_key',
        });
    die "Agent " . $member->{name} . ' not in DB' unless $agent;

    say "Adding agent to room" if $verbose;
    die 'Could not add agent ' . $member->{name} . ' to group' unless $manager->add_user_to_group($agent, $room->id);
}

my $members = $gm->get_members($room->groupme_id);
print Dumper($members) . "\n";

sub help {
    say "\nperl create_group.pl --group_name 'Some Group' --access_level 4 [--is_moderated] [--verbose]\n";
    say "    group_name:       Name of the group (required)";
    say "    access_level_id:  DB ID of rthe access level (required)";
    say "    is_moderated:     If passed, group will be set as moderated";
    say "    verbose:          Turn on verbosity\n";
}
