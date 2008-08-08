package Testmask4;
use strict;
use warnings;
use base qw(Bitmask::Data);

__PACKAGE__->bitmask_length(14);
__PACKAGE__->bitmask_complex(1);
__PACKAGE__->init(
    AT      => 0b0000000_0000001,
    CH      => 0b0000000_0000010,
    DE      => 0b0000000_0000100,
    BR      => 0b0000000_0001000,
    de      => 0b0000001_0000000,
    fr      => 0b0000010_0000000,
    it      => 0b0000100_0000000,
    pt      => 0b0001000_0000000,
    de_AT   => 0b0000001_0000001,
    de_CH   => 0b0000001_0000010,
    de_DE   => 0b0000001_0000100,
    fr_CH   => 0b0000010_0000010,
    it_CH   => 0b0000100_0000010,
    pt_BR   => 0b0001000_0001000,
);


1;