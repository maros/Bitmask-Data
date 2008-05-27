# -*- perl -*-

# t/005_testmask2.t - check testmask 2

use Test::More tests => 62;

use strict;
use warnings;

use lib qw(t/lib);
use_ok( 'Testmask2' );

my $tm = Testmask2->new();

isa_ok($tm,'Bitmask::Data');
isa_ok($tm,'Testmask2');

my $sprintf   = '%014b';
my %locs = (    
    de_AT   => 0b0000001_0000001,
    de_CH   => 0b0000001_0000010,
    de_DE   => 0b0000001_0000100,
    fr_CH   => 0b0000010_0000010,
    it_CH   => 0b0000100_0000010,
    pt_BR   => 0b0001000_0001000,
);

while ( my ( $l, $bm ) = each(%locs) ) {
    my $loc = Testmask2->new($l);
    ok( $loc, "Created bitmasl $l : $loc" );
    is( join( " ", @{ $loc->{_data} } ), $l, "List really is $l" );
    is( $loc->mask(), $bm, "->mask() call returns correct result" );
    is( $loc->string(), sprintf( $sprintf, $bm ), "->sql() correct " );
}

{
    while ( my ( $l, $bm ) = each(%locs) ) {
        my $a = Testmask2->new($l);
        
        my $b = Testmask2->new( $a->mask );
        is( $a->mask, $b->mask, "new -> int" );

        my $c = Testmask2->new( "0b" . $b->string );
        is( $b->mask, $c->mask, "new -> bitstring, perl format" );

        my $d = Testmask2->new( "0b" . $c->string );
        is( $c->mask, $d->mask, "new -> bitstring, pg format" );

        my $e = Testmask2->new( $d->list );
        is( $d->mask, $e->mask, "new -> human readable de_DE format" );
    }
}

{
    my $all = Testmask2->new(0b0001111_0001111);
    my $b   = Testmask2->new( $all->list );

    is( $all->string, $b->string, "Multi locale constructor" );

    $b->remove( $all->list );
    is( $b->string, "0" x 14, "Multi remove (all) from object" );

    $b->add( $all->list );
    is( $all->string, '00011110001111',
        "Multi add (" . join( ", ", $all->list ) . ") to object " );
    $b->add( $all->list );
    ok( $all->list ~~ $b->list, "No duplicates " . join( ", ", $b->list ) );

    my @arr = $b->list;
    is( keys %locs, @arr, "->list behaves well in list-context" );

    my $arr = $b->list;
    is( keys %locs, @$arr,
        "->list behaves well in scalar-context" );

    $b->remove('0b00010000001000');
    is( $b->mask, 0b00001110000111, "removing bitmask" );
    
    $b->remove('de_AT');
    is( $b->mask, 0b0000111_0000110, "removing string de_AT" );

    $b->remove('de_CH');
    is( $b->mask, 0b0000111_0000110, "removing string de_CH" );

    $b->remove('de_DE');
    is( $b->mask, 0b00001100000010, "removing string de_DE" );

    $b->add('de_DE');
    is( $b->mask, 0b00001110000110, "adding string de_DE" );

}
#

#{
#    my $country_bitmasks = {
#        de_ => 0b00000010000111,
#        fr_ => 0b00000100000010,
#        it_ => 0b00001000000010,
#        pt_ => 0b00010000001000,
#        _CH => 0b00001110000010,
#        _DE => 0b00000010000100,
#        _AT => 0b00000010000001,
#        _BR => 0b00010000001000,
#    };
#
#    foreach my $loc ( keys %$country_bitmasks ) {
#        my $bl = Testmask2->new($loc);
#        is( $bl->mask, $country_bitmasks->{$loc},
#            "Bitmask for country $loc" );
#    }
#}
#
#{
#
#    my $all = Testmask2->new(0b0001111_0001111);
#    ok( $all->list > 3, "Some locales in Bitlocale" );
#
#    $all->set('de_DE');
#    ok( 'de_DE' ~~ $all->list, "Germany is in the list" );
#
#    my @all = $all->list;
#    is( scalar @all, 1, "Germany is the only one after ->set('de_DE')" );
#
#}