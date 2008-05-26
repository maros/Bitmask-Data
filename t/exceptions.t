# -*- perl -*-

# t/004_basic.t - check basic stuff

use Test::More tests=>5;

use strict;
use warnings;

use lib qw(t/lib);
use Testmask1;

my $tm = Testmask1->new();

my @broken_input = (
    'hase',
    131071,
    '11000000000000100',
    'value99',
    ['value1',131072]
);

foreach (@broken_input) {
    eval {
        $tm->add($_);
    };
    isnt($@,undef);
    is($@,'hase')
}
