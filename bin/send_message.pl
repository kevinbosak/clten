#!/usr/bin/env perl

use warnings;
use 5.020;
use Dancer qw(:script);
use Dancer::Plugin::DBIC;
use Getopt::Long;
use GroupMe;
use CltEn::Util qw(:all);
use Data::Dumper;

my $token_file;
my $message;
my $group_id;

GetOptions(
        'token_file=s' => \$token_file,
        'message=s' => \$message,
        'group_id=s' => \$group_id,
        'help'    => sub{ show_help(); exit(); },
    );

if (!$message) {
    say "MUST give a message!\n";
    show_help();
    exit;
}

if (!$group_id) {
    say "MUST specify a group ID!!\n";
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

$gm->create_message($group_id, $message);
