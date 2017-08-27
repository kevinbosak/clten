#!/usr/bin/env perl

use warnings;
use 5.020;
use Dancer qw(:script);
use Dancer::Plugin::DBIC;
use Getopt::Long;
use GroupMe;
use CltEn::Util qw(:all);
use Data::Dumper;

my $group_id;
my $token_file;

GetOptions(
        'group_id=i' => \$group_id,
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

my $data = $gm->get_group($group_id);

say Dumper $data;
