package Testmask5;
use strict;
use warnings;
use base qw(Bitmask::Data);


__PACKAGE__->bitmask_length(5);
__PACKAGE__->bitmask_lazyinit(1);
__PACKAGE__->init(
    'value1',
    'value2',
    'value3',
    'value4',
    'value5'
);

1;