# -*- perl -*-

# t/007_testmask3.t - check testmask 3

use Test::More tests => 4;
use Test::NoWarnings;

use strict;
use warnings;

use lib qw(t/lib);
use_ok( 'Testmask3' );

my $tm = Testmask3->new();

$tm->setall;
is($tm->length,3);
is($tm->mask,7);