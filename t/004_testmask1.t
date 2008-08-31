# -*- perl -*-

# t/004_testmask1.t - check testmask 1

use Test::More tests=>52;
use Test::NoWarnings;

use strict;
use warnings;

use lib qw(t/lib);
use_ok( 'Testmask1' );

my $tm = Testmask1->new();
my $tm2 = Testmask1->new('value4');

isa_ok($tm,'Bitmask::Data');
isa_ok($tm,'Testmask1');
isa_ok($tm2,'Bitmask::Data');
isa_ok($tm2,'Testmask1');
is($tm->length,0);
is($tm2->length,1);
ok($tm->add('value1',2));
ok($tm2->add('value1'));
is($tm->hasall('value1','value2'),1);
is($tm2->hasall('value1','value4'),1);
is($tm->hasany('value1'),1);
is($tm->hasany('value3'),0);
is($tm->hasany('value3'),0);
is($tm->hasall('value1'),1);
is($tm->hasexact('value1'),0);
is($tm->hasexact('value1','value2'),1);
is($tm->hasexact('value1','value4'),0);
is($tm->hasexact('value1','value2','value5'),0);
is($tm2->hasexact('value1'),0);
is($tm->hasall('value1','value2','value3'),0);
is($tm->length,2);
is($tm->mask,0b0000000000000011);
ok($tm->add('value3','value7'));
is($tm->length,4);
ok($tm->add(2));
is($tm->length,4);
is($tm->mask,0b1000000000001011);
ok($tm->remove(0b0000000000000011));
is($tm->length,2);
is($tm->mask,0b1000000000001000);
is($tm->first,'value3');
is($tm->string,'1000000000001000');
my @sqlsearch = $tm->sqlfilter('field');
is($sqlsearch[0],"bitand( field, B'1000000000001000' )");
is(${$sqlsearch[1]}," = B'1000000000001000'");
$tm->reset;
is($tm->length,0);
ok($tm->add(0b1000000000111111));
is($tm->length,7);
is($tm->mask,0b1000000000111111);
ok($tm->remove(32768,[ 0b0000000000000101 ]));
is($tm->length,4);
is($tm->mask,0b0000000000111010);
$tm->set([0b0000000000000010],[0b0000000000100010]);
is($tm->mask,0b0000000000100010);
$tm->add($tm2);
ok($tm->hasany('value4'));
my $tm3 = $tm->clone();
$tm->remove('value4');
ok(! $tm->hasany('value4'));
ok($tm3->hasany('value4'));
is($tm->length + 1,$tm3->length);

# Utility functions
is(Testmask1->bit2data(0b0000000000000010),'value2');
is(Testmask1->bit2data(0b0100000000000000),undef);
is(Testmask1->data2bit('value2'),0b0000000000000010);
is(Testmask1->data2bit('novalue'),undef);