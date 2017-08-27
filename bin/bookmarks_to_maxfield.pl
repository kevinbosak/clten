#!/usr/bin/env perl

use warnings;
use 5.020;
use autodie;
use Getopt::Long;
use JSON;

my $bookmark_file;

GetOptions(
        'bookmarks=s' => \$bookmark_file,
        'help'    => sub{ show_help(); exit(); },
    );
if (!$bookmark_file) {
    say "Must specify file where bookmarks are stored";
    print "\n";
    show_help();
    exit();
}

sub show_help {
    say <<EOF
Prints out maxfield format of portals given file in IITC bookmark format..

USAGE: 
    bookmarks_to_maxfield.pl --bookmarks=bookmark_file > save_file
EOF
}

my $data;
open(my $fh, $bookmark_file);
{
    local $/;
    $data = from_json(<$fh>);
}
close $fh;

my $portal_groups = $data->{portals};
for my $portal_group (keys %$portal_groups) {
    my $portals = $portal_groups->{$portal_group}->{bkmrk};
    for my $portal_id (keys %$portals) {
        my $portal = $portals->{$portal_id};
        say join(';', $portal->{label}, make_link($portal),0);
    }
}

sub make_link {
    my $portal = shift;
    return 'https://www.ingress.com/intel?ll=' . $portal->{latlng} . '&z=17&pll=' . $portal->{latlng};
}
