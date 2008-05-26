# ============================================================================
package Bitmask::Factory;
# ============================================================================
use strict;
use warnings;

use base qw(Class::Accessor::Fast);
use 5.010;

use Carp;
use Config;

our $VERSION = '1.00';
our $BITLENGTH = 16;

__PACKAGE__->mk_ro_accessors(
    name
    length
    items
);

=head1 NAME

Bitmask::Factory - Create classes for bitmask handling

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

sub new {
    my $class = shift;
    my $name = shift;
    my $length = shift || $BITLENGTH;
    
    my $obj = bless { 
        name        => $name,
        items       => [],
        length      => $length,
    }, $class;
    
    return $class;
}
    
sub add_item {
    my $obj = shift;
    
    while (my $item = shift) {
        my $bit = ($_[0] =~ m/\A(?:0b)?([01]{$obj->{length}})\Z/) ?
            shift :
            scalar(@{$obj->{items}}) ** 2;
        
        croak('Invalid bitmask item')
            unless ($item && ref $item eq '');
        
        croak('Item/Bit already in bitmask')
            if grep { $_->[0] eq $item || $_->[1] eq $bit }  @{$obj->{items}};
      
        croak('Too many items in bitmask') 
            if ($obj->{length} < scalar @{$obj->{items}} + 1);
      
        push @{$obj->{items}}, [ $item, $bit ]
            unless grep { $_->[0] eq $item } $item ~~ @{$obj->{items}};
    }

    return;
}

sub build {
    my $obj = shift;
    
    my $package = $obj->{name};
    push @{$package.'::ISA'}, 'Bitmask::Data'
        unless grep { $_ eq 'Bitmask::Data' } @{$obj->{name}.'::ISA'};
    
    $package->mk_classdata(bitmask_length => $obj->{length});
    $package->mk_classdata(bitmask_items => $obj->{items} });
}
