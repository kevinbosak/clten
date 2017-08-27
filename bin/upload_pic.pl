#!/usr/bin/env perl

use warnings;
use 5.020;
use Dancer qw(:script);
use GroupMe;

my $filename = shift;
die "Must specify file" unless $filename;

my $token = config->{GM_token};

my $gm = GroupMe->new(
        token => $token,
    );


my $url = $gm->upload_pic($filename);
say $url;
