#!/usr/bin/env perl

use warnings;
use 5.020;
use Dancer qw(:script);
use Dancer::Plugin::DBIC;
use Getopt::Long;

GetOptions(
#        'value=i' => \$level_value,
#        'name=s'  => \$level_name,
        'help'    => sub{ show_help(); exit(); },
    );

sub show_help {
    say <<EOF
Shows all active access levels (ID, value, and name).

USAGE: 
    show_access_levels.pl
EOF
}

my $rs = schema->resultset('AccessLevel')->search({is_active => 1}, {order_by => 'value asc'});
while (my $level = $rs->next) {
    say sprintf('%4s: %4s => %s', $level->id, $level->value, $level->name)
}
