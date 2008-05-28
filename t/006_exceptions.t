# -*- perl -*-

# t/004_basic.t - check basic stuff

use Test::More tests=>13;

use strict;
use warnings;

use lib qw(t/lib);
use Testmask1;

my $tm = Testmask1->new();

my @broken_input = (
    'hase', qr/Could not turn <hase> in anything meaningfull/,
    262143, qr/Invalid bitmask value <262143>/,
    '0b11001010101010101', qr/Could not turn <0b11001010101010101> in anything meaningfull/,
    'value99', qr/Could not turn <value99> in anything meaningfull/,
    ['value1',262149], qr/Invalid bitmask value <262149>/,
    '0b1100101010101010', qr/Invalid bitmask items <51882>/,
);

while (scalar @broken_input ) {
    my $test = shift @broken_input;
    my $error = shift @broken_input;
    $@ = '';
    eval {
        $tm->add($test);
    };
    like($@,$error);
}

push @Testmask4::ISA,qw(Bitmask::Data);

Testmask4->bitmask_length(undef);
eval {
    Testmask4->init(
        'hase',
        'baer',
        'luchs'
    );
};
like($@,qr/Bitmask length not set/);

Testmask4->bitmask_length(4);
eval {
    Testmask4->init(
        'hase',
        'baer',
        'luchs',
        'sackratte',
        'maus'
    );
};
like($@,qr/Too many values in bitmask: max/);

Testmask4->bitmask_items({});
eval {
    Testmask4->init(
        'hase',
        'baer',
        'baer',
        'luchs',
    );
};
like($@,qr/Value already in bitmask/);

Testmask4->bitmask_items({});
eval {
    Testmask4->init(
        'hase'      => 1,
        'baer'      => 2,
        'luchs'     => 4,
        'sackratte' => 4,
    );
};
like($@,qr/Bit already in bitmask/);


Testmask4->bitmask_items({});
eval {
    Testmask4->init(
        'hase'      => 1,
        'baer'      => 2,
        'luchs'     => 3,
        'sackratte' => 8,
    );
};
like($@,qr/Invalid bit value/);


Testmask4->bitmask_items({});
eval {
    Testmask4->new();
};
like($@,qr/Bitmask not initialized/);

Testmask4->bitmask_items({});
eval {
    Testmask4->init(
        'hase'      => '0b0001',
        'baer'      => 2,
        'luchs'     => 4,
        'sackratte' => 16,
    );
};
like($@,qr/Invalid bit value/);