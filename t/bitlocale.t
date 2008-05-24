#!/opt/perl5.10/bin/perl

use strict;
use warnings;
use Test::More tests => 81;
use Test::NoWarnings;

# diag("Testing Babilu::BitLocale");

BEGIN {
    use_ok('Babilu::BitLocale');
}

my $locale_bm = Babilu::BitLocale->new()->locale_bitmask;
my $sprintf   = '%014b';
ok( $locale_bm, "Default initialisation worked" );

{
    while ( my ( $l, $bm ) = each(%$locale_bm) ) {
        my $loc = Babilu::BitLocale->new($l);
        ok( $loc, "Created locale <$l> BitLocale $loc" );
        is( join( " ", @{ $loc->_locales() } ), $l, "List really is $l" );
        is( $loc->mask(), $bm, "->mask() call returns correct result" );
        is( $loc->sql(), sprintf( $sprintf, $bm ), "->sql() correct " );
    }
}

# diag("any2bm");
{
    while ( my ( $l, $bm ) = each(%$locale_bm) ) {
        my $a = Babilu::BitLocale->new($l);

        my $b = Babilu::BitLocale->new( $a->mask );
        is( $a->mask, $b->mask, "new -> int" );

        my $c = Babilu::BitLocale->new( "0b" . $b->sql );
        is( $b->mask, $c->mask, "new -> bitstring, perl format" );

        my $d = Babilu::BitLocale->new( $c->sql );
        is( $c->mask, $d->mask, "new -> bitstring, pg format" );

        my $e = Babilu::BitLocale->new( $d->list );
        is( $d->mask, $e->mask, "new -> human readable de_DE format" );
    }
}

{
    my $all = Babilu::BitLocale->new(0b0001111_0001111);
    my $b   = Babilu::BitLocale->new( $all->list );

    is( $all->sql, $b->sql, "Multi locale constructor" );

    $b->remove( $all->list );
    is( $b->sql, "0" x 14, "Multi remove (all) from object" );

    $b->add( $all->list );
    is( $all->sql, '00011110001111',
        "Multi add (" . join( ", ", $all->list ) . ") to object " );
    $b->add( $all->list );
    ok( $all->list ~~ $b->list, "No duplicates " . join( ", ", $b->list ) );

    my @arr = $b->list;
    is( keys %$locale_bm, 1 + @arr, "->list behaves well in list-context" );

    my $arr = $b->list;
    is( keys %$locale_bm, 1 + @$arr,
        "->list behaves well in scalar-context" );

    # diag(join(", ", $b->sql, $b->list));
    $b->remove('0b00010000001000');
    is( $b->mask, 0b00001110000111, "removing bitmask" );

    # diag(join(", ", $b->sql, $b->list));
    $b->remove('de_AT');
    is( $b->mask, 0b0000111_0000110, "removing string de_AT" );

    $b->remove('de_CH');
    # diag( join( ", ", $b->sql, $b->list ) );
    is( $b->mask, 0b0000111_0000110, "removing string de_CH" );

    $b->remove('de_DE');
    # diag( join( ", ", $b->sql, $b->list ) );
    is( $b->mask, 0b00001100000010, "removing string de_DE" );

    $b->add('de_DE');
    # diag( join( ", ", $b->sql, $b->list ) );
    is( $b->mask, 0b00001110000110, "adding string de_DE" );

}

# diag("Incomplete Locales");
{
    my $country_bitmasks = {
        de_ => 0b00000010000111,
        fr_ => 0b00000100000010,
        it_ => 0b00001000000010,
        pt_ => 0b00010000001000,
        _CH => 0b00001110000010,
        _DE => 0b00000010000100,
        _AT => 0b00000010000001,
        _BR => 0b00010000001000,
    };

    foreach my $loc ( keys %$country_bitmasks ) {
        my $bl = Babilu::BitLocale->new($loc);
        is( $bl->mask, $country_bitmasks->{$loc},
            "Bitmask for country $loc" );
    }
}

{

    my $all = Babilu::BitLocale->new(0b0001111_0001111);
    ok( $all->list > 3, "Some locales in Bitlocale" );

    $all->set('de_DE');
    ok( 'de_DE' ~~ $all->list, "Germany is in the list" );

    my @all = $all->list;
    is( scalar @all, 1, "Germany is the only one after ->set('de_DE')" );

}

