#!/usr/bin/env perl

use warnings;
use 5.020;
use Dancer qw(:script);
use Dancer::Plugin::DBIC;
use Getopt::Long;
use GroupMe;
use CltEn::Util qw(:all);

my $group_id;
my $max_messages = 10000;
my $token_file;

GetOptions(
        'group_id=i' => \$group_id,
        'max_messages=i'  => \$max_messages,
        'token_file=s' => \$token_file,
        'help'    => sub{ show_help(); exit(); },
    );

if (!$group_id) {
    say "MUST specify a group_id!!\n";
    show_help();
    exit;
}
if (!$token_file) {
    say "MUST specify a token_file!!\n";
    show_help();
    exit;
}

sub show_help {
    say "HELP!";
}

my $gm = GroupMe->new(
        token_file => $token_file,
    );

my $count = $gm->get_message_count($group_id);
say "TOTAL: $count";

my @messages = $gm->get_messages($group_id, {
        maximum => $max_messages,
    });

for my $message (reverse @messages) {
    my $date = convert_groupme_date($message->{created_at});
    $date->set_time_zone('America/New_York');
    my $date_string = $date->ymd . ' ' . $date->hms;
    my $agent = $message->{name};
    my $agent_id = $message->{user_id};
    my $id = $message->{id};
    my $msg = $message->{text};
    say "$date_string $id ($agent - $agent_id): $msg";
}
