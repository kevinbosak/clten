#!/usr/bin/env perl

use warnings;
use strict;

use Dancer qw(:script);
use Dancer::Plugin::DBIC;

eval {
    schema->deploy({ add_drop_table => 1}, '.');
};
die "Could not deploy schema; $@" if $@;

#use Dancer ':script';
#use Dancer::Plugin::DBIC 'schema';
#
#my $schema = schema;
#
#eval {
#    $schema->deploy({ add_drop_table => 1 }, '.');
#    };
#
