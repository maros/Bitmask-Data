# -*- perl -*-

# t/010_long.t - bitmasks with 64 items

use Test::More;
use Config; 

use lib qw(t/lib);

use strict;
use warnings;


plan skip_all => '64 bit required'
    unless ($Config{longsize} >= 8);;

plan tests => 2;    
        
use_ok( 'Testmask6' );
        
my $tm1 = Testmask6->new('value64');
    
is($tm1->string,'0000000000000000000000000000000000000000000000000000000000000001');
