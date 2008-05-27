package Testmask2;
use strict;
use warnings;
use base qw(Bitmask::Data);


__PACKAGE__->bitmask_length(14);
__PACKAGE__->bitmask_complex(1);
#__PACKAGE__->bitmask_default(0b1000000_0000000);

__PACKAGE__->init(
    de_AT   => 0b0000001_0000001,
    de_CH   => 0b0000001_0000010,
    de_DE   => 0b0000001_0000100,
    fr_CH   => 0b0000010_0000010,
    it_CH   => 0b0000100_0000010,
    pt_BR   => 0b0001000_0001000,
);

1;