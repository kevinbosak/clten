#!/usr/bin/perl

use warnings;
use strict;

#!/usr/bin/env perl

use warnings;
use 5.020;
use Dancer qw(:script);
use Dancer::Plugin::DBIC;
use Getopt::Long;

use GroupMe;

#my @rooms = schema->resultset('Room')->all();
my $room = schema->resultset('Room')->find();
my @rooms = ($room);
my $groupme = GroupMe->new(
        token => config->{GM_token},
    );

for my $room (@rooms) {
    say $room->name;
            $groupme->create_message($room->groupme_id, "!welcome");
}
