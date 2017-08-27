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

GetOptions(
        'token_file=s' => \$token_file,
        'help'    => sub{ show_help(); exit(); },
    );

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

my @bots = @{$gm->list_bots};
for my $bot (@bots) {
    say $bot->{name} . ': ' . $bot->{group_id};
}
