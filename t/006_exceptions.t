# -*- perl -*-

# t/004_basic.t - check basic stuff

use Test::More tests=>6;

use strict;
use warnings;

use lib qw(t/lib);
use Testmask1;

my $tm = Testmask1->new();

my @broken_input = (
    'hase', qr/Could not turn <hase> in anything meaningfull/,
    262143, qr/Invalid bitmask value <262143>/,
    '0b11001010101010101', qr/Could not turn <0b11001010101010101> in anything meaningfull/,
    'value99', qr/Could not turn <value99> in anything meaningfull/,
    ['value1',262149], qr/Invalid bitmask value <262149>/,
    '0b1100101010101010', qr/Invalid bitmask items <51882>/,
);

while (scalar @broken_input ) {
    my $test = shift @broken_input;
    my $error = shift @broken_input;
    $@ = '';
    eval {
        $tm->add($test);
    };
    like($@,$error);
}
