#!/usr/bin/env perl

use warnings;
use 5.020;
use Dancer qw(:script);
use Dancer::Plugin::DBIC;
use Getopt::Long;

my $level_value;
my $level_name;

GetOptions(
        'value=i' => \$level_value,
        'name=s'  => \$level_name,
        'help'    => sub{ show_help(); exit(); },
    );
if (!$level_value or !$level_name) {
    say "Must specify access level value (numeric)!" unless $level_value;
    say "Must specify access level name!" unless $level_name;
    print "\n";
    show_help();
    exit();
}

sub show_help {
    say <<EOF
Creates a new database entry for an access level.

USAGE: 
    create_access_level.pl --value=i --name=s
        --value      numeric value of the access level
        --name       human readable name of the access level
EOF
}

my $level = schema->resultset('AccessLevel')->create({
        value => $level_value,
        name  => $level_name,
    });
say "New level created with ID: " . $level->id;
