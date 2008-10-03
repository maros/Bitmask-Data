# -*- perl -*-

# t/009_overload.t - overload

use Test::More tests => 9;
use Test::NoWarnings;

use strict;
use warnings;

use lib qw(t/lib);
use_ok( 'Testmask5' );

my $tm1 = Testmask5->new('value1');
my $tm2 = Testmask5->new('value1','value5');

is(Testmask5->new('value1','value2'),'00011');
is($tm1 += 3,'00011');
ok(Testmask5->new('value1') == 1);
ok(Testmask5->new('value1') != 2);
ok(Testmask5->new('value1','value5') eq '10001');
ok(Testmask5->new('value1','value5') ne '10011');
is($tm2 -= 1,'10000');