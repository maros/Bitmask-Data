# -*- perl -*-

# t/008_testmask4.t - check testmask 4

use Test::More tests => 31;
use Test::NoWarnings;

use strict;
use warnings;

use lib qw(t/lib);
use_ok( 'Testmask4' );

is(Testmask4->new('de_DE','de_AT')->string,'00000010000101');
is(Testmask4->new('de_DE')->string,'00000010000100');
is(Testmask4->new('de')->string,'00000010000000');
is(Testmask4->new('de','it')->string,'00001010000000');
is(Testmask4->new('DE','BR')->string,'00000000001100');
is(Testmask4->new('DE','BR')->length,2);
is(Testmask4->new('de_DE','de','AT')->length,4);
is(Testmask4->new('fr_CH')->length,3);
ok(Testmask4->new(0b00000000001100)->hasall('DE','BR'));

ok(Testmask4->new('de_DE','de_AT')->hasany('de'));
ok(Testmask4->new('de_DE','de_AT')->hasany('de_DE'));
ok(Testmask4->new('de_DE','de_AT')->hasany('AT'));
ok(Testmask4->new('de_DE','de_AT')->hasany('de','de_AT','de_CH'));
ok(Testmask4->new('de_DE','de_AT')->hasall('de','de_AT'));
ok(! Testmask4->new('de_DE','de_AT')->hasall('de','de_AT','de_CH'));
ok(Testmask4->new('de_DE','de_AT')->hasany('de_CH','de_AT'));
ok(!Testmask4->new('de_DE','de_AT')->hasall('de_CH'));
ok(Testmask4->new('de_DE','de_AT','fr_CH')->hasall('de_CH'));#
ok(Testmask4->new('de_DE','de_AT','fr_CH')->hasall('de_AT'));
ok(Testmask4->new('de_DE','de_AT','fr_CH')->hasall('fr','de','AT'));
ok(Testmask4->new('de_DE','de_AT','fr_CH')->hasall('fr','de','AT','de_CH'));#

ok(Testmask4->new('de_DE','de_AT','de_CH')->hasexact('de','AT','DE','CH'));

ok(Testmask4->new('de','fr')->hasany('fr'));
ok(Testmask4->new('de','fr')->hasany('de_DE'));
ok(! Testmask4->new('de','fr')->hasall('de','it'));

ok(Testmask4->new('de')->hasany('de'));
ok(Testmask4->new('de')->hasany('de_DE'));
ok(! Testmask4->new('de')->hasall('de_DE'));
ok(Testmask4->new('de_DE','de_AT','de_CH')->hasexact('de','AT','DE','CH'));
