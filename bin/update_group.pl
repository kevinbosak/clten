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

my $group_id;
my $name;
my $topic;
my $is_moderated;
my $access_level_id;
my $avatar;
my $verbose;
my $help;

GetOptions(
        "group_id=i" => \$group_id,
        "name=s" => \$access_level_id,
        "topic=s" => \$topic,
        "avatar=s" => \$avatar,
        "access_level_id=i" => \$access_level_id,
        "is_moderated=i" => \$is_moderated,
        "verbose" => \$verbose,
        "help" => \$help,
);

if ($help) {
    help();
    exit;
}

die "Must specify group ID" unless $group_id;

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

say "Gathering params" if $verbose;
my $params = {};
$params->{name} = $name if $name;
$params->{topic} = $topic if $topic;
$params->{access_level_id} = $access_level_id if $access_level_id;
$params->{is_moderated} = $is_moderated if defined $is_moderated;

if ($avatar) {
    my $url = $gm->upload_pic($avatar);
    $params->{image_url} = $url;
}

say "Updating Room" if $verbose;
my $room = $manager->update_room($group_id, $params);

sub help {
    say "\nperl update_group.pl --group_id 1234 --access_level 4 [--is_moderated] [--verbose]\n";
    say "    group_name:       Name of the group (required)";
    say "    access_level_id:  DB ID of rthe access level (required)";
    say "    is_moderated:     If passed, group will be set as moderated";
    say "    verbose:          Turn on verbosity\n";
}
