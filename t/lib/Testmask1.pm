package Testmask1;

use strict;
use warnings;

use base qw(Bitmask::Data);

__PACKAGE__->bitmask_lazyinit(1);
__PACKAGE__->init(
    'value1', #1
    'value2' => 0b0000000000000010, #2
    'value3' => 0x8000, #16
    'value4' => 0x4, #3
    'value5', # 5
    'value6', # 6 
    'value7' => 8, #4
);

1;