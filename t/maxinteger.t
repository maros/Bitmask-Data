# -*- perl -*-

# t/long.t - check for max integer bitmasks

use Config;
use Test::More tests => 7;
use Test::NoWarnings;

use lib qw(t/lib);

use strict;
use warnings;

use_ok('Testmask7');
use_ok('Testmask8');

my $tm1 = Testmask7->new('value40');
my $tm2 = Testmask8->new('value64');

isnt(ref $tm1->integer,'Math::BigInt');

if ($Config{use64bitint}) {
    isnt(ref $tm2->integer,'Math::BigInt');
} else {
    isa_ok($tm2->integer,'Math::BigInt');
}

my $tm3 = Testmask7->new($tm1->integer);
my $tm4 = Testmask8->new($tm2->integer);

is($tm3->string,$tm1->string);
is($tm4->string,$tm2->string);