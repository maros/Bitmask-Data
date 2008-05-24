# ============================================================================
package Bitmask::Data;
# ============================================================================
use strict;
use warnings;

use base qw(Class::Data::Inheritable Class::Accessor::Fast);
use 5.010;

use Config;
use List::Util qw(reduce);

our $VERSION = '1.00';

use overload
    '""' => sub {
        shift->mask,
    };

__PACKAGE__->mk_classdata(
    bitmask_length => 16,
    bitmask_items  => [],
);

__PACKAGE__->mk_accessors(
    '_data'
);

=encoding utf8

=head1 NAME

Bitmask::Data - Handle bitmasks in an easy and flexible way

=head1 SYNOPSIS

 # Create a simple bitmask class
 packacke MyBitmask;
 use base qw(Bitmask::Data);
 __PACKAGE__->bitmask_length(20);
 __PACKAGE__->init(
    [ 'value1' => 0b000000000000000001 ],
    [ 'value2' => 0x2 ],
    [ 'value2' => 4 ],
    'value4',
    'value5',
 );
 
 ## Somewhere else in your code
 use MyBitmask;
 my $bm = MyBitmask->new('value1','value3');
 $bm->mask;

=head1 DESCRIPTION

This package helps you dealing with bitmasks. First you need to subclass
Bitmask::Data and set the bitmask values and length. (If you are only working
with a single bitmask in a simple application you might also initialize
the bitmask directly in the Bitmask::Data module).

After the initialization you can create an arbitrary number of bitmask 
objects which can be accessed and manipulated with convenient methods.

=head1 METHODS

=head2 Class Methods

=head3 bitmask_length

Set/Get the length of the bitmask. Changing this value after the 
initialization is not recommended.

=head3 bitmask_items

HASHREF of all bitmask items. Don't mess around here unless you know 
what you are doing.

=head3 init

    CLASS->init(LIST of VALUES);

Initializes the bitmask class. You can supply a list of possible values.
Optionally you can also specify the bits for the mask by adding ARRAY
references. 
 
    CLASS->init(
        'value1'
        [ 'value2' => 0x2 ],
        'value3',
        [ 'value4' => 16 ],
        [ 'value5' => 0b100000 ],
        
    );

=cut

sub init {
    my $class = shift;

    croak('Bitmask length not set')
         unless $class->bitmask_length;

    croak('Too many values in bitmask: max.'.$class->bitmask_length)
        if (scalar(@_) > $class->bitmask_length);
    
    my $items = {};
    my $count = 0;
    while (my $item = shift) {
        my ($name,$bit);
        $count ++;
        if (ref $item eq 'ARRAY') {
            ($name,$bit) = @{$item};
        } else {
            $name = $item;
            $bit = $count ** 2;
        }
        
        $class->_check_bit($bit)
            or croak('Invalid bit value: '.$bit);

        croak('Item/Bit already in bitmask: '.$name.' '.$bit)
            if grep { $_->[0] eq $name || $_->[1] eq $bit }  @{$items};
        
        $items->{$name} = $bit;
    }
    $class->bitmask_items($items);
    return;
}

sub _check_bit {
    my $class = shift;
    my $bit = shift;
    
    return 1 if $bit == 0;
    my $value = log($bit)/log(2);
    return 0 
        if ($value > $class->bitmask_length);
    return (int $value == $value) ? 1:0;
}


=head3 data2int

    CLASS->data2int(VALUE);

Returns the corresponding bit for the given value.

=cut

sub data2bit {
    my ($class, $value) = @_;
    return exists $class->bitmask_items->{$value} ? 
        $class->bitmask_items->{$value} :
        undef;
}

=head3 bit2data

    CLASS->bit2data(BIT);

Returns the corresponding value for the given bit.

=cut

sub bit2data {
    my ($class, $bit) = @_;
    while (my @item = each %{$class->bitmask_items}) {
        return $item[0]
            if $item[1] == $bit;
    }
    return undef;
}

=head3 bm2data

    CLASS->bm2data(BITMASK);

Returns all the value for the given bitmask.

=cut

sub bm2data {
    my ( $class, $bitmask ) = @_;

    my @all = map { $_ & $bitmask } keys %{ $class->bitmask_items };
    my @bitmasks = grep { $_ ~~ %{ $class->bitmask_items } } @all;
    my @result =  @{ $class->bitmask_items }{@bitmasks};
    return wantarray ? @result : \@result;
}

=head3 any2data

    CLASS->any2data(124);
    CLASS->any2data('de_DE');
    CLASS->any2data(0b110001001);

Turns a single value (bit, bitmask,value) into a value.

=cut

sub any2data {
    my ( $class, $any ) = @_;

    my $bl = $class->bitmask_length;
    my @data;
    given ($any) {
        when (%{ $class->bitmask_items }) {
            @data = ($any);
        }
        when (/\A(?:0b)?([01]{$bl})\Z/o) {
            @data = ( $class->bm2data( oct("0b$1") ) );
        }
        when (/\A\d+\Z/) {
            #say("<$any> is an int: ");
            @data = ( $class->bm2data($any) );
        }
        default { die "Could not turn <$any> in anyything meaningfull" };
    }

    return @data;
}

=head4 _parse_params

    CLASS->_parse_params(LIST)

Helper method for parsing params passed to various methods.

=cut

sub _parse_params {
    my ( $class, @args ) = @_;

    my @data = ();
    foreach my $param (@args) {
        my @tmp;
        if ( ref $param eq 'ARRAY' ) {
            push( @tmp, $class->_parse_params(@$param) );
            next;
        } 
        elsif (ref $param 
            && $param->isa(ref $class || $class)) {
            push(@tmp, $param->list );
        }
        else {
            push(@tmp, $class->any2data($param) );
        }
        
        foreach my $item (@tmp) {
            push @data,$item
                unless $item ~~ \@data;
        }
        
    }

    return @data;
}

=head3 Public Methods

=head3 new

    my $bm = MyBitmask->new();
    my $bm = MyBitmask->new('value1');
    my $bm = MyBitmask->new('value2', 'value3');
    my $bm = MyBitmask->new('00010000010000');
    my $bm = MyBitmask->new(124);
    my $bm = MyBitmask->new(0b00010000010000);
    my $bm = MyBitmask->new(0x2);
    my $bm = MyBitmask->new([32, 'value1', 0b00010000010000]);

Create a new bitmask object. You can supply almost any combination of 
bits, bitmasks and values, even mix different types. 

=over

=item * LIST or ARRAYREF of values

=item * LIST or ARRAYREF of bits (integers)

=item * LIST or ARRAYREF of strings representing bits or bitmasks

=item * LIST or ARRAYREF of bitmasks

=item * Any combination of the above

=back

=cut

sub new {
    my ( $class, @args ) = @_;
    
    croak('Bitmask not initialized')
        unless scalar keys %{$class->bitmask_items};
    
    my $self = bless {
        _data   => [],
    },$class;
    
    $self->add( $self->_parse_params(@args) );
    
    return $self;
}

=head3 set

    $bm->set(ITEMS);
    
This method takes the same arguments as C<new>. It resets the current bitmask
and sets the supplied arguments.

=cut

sub set {
    my ($self, @args) = @_;
    
    croak('Set must be called with at least one value') 
        unless @args;
    $self->_data([ $self->_parse_params(@args) ]);
}

=head3 list

    $bm->list

In list context, this returns a list of the set values in scalar context, 
this returns an array reference to the list of values.

=cut

sub list {
    my $self = shift;
    my $data = $self->_data // [];
    return wantarray ? @$data : $data;
}

=head3 length

    $bm->length

Number of set bitmask values.

=cut

sub length {
    my $self = shift;
    my $data = $self->_data // [];
    return scalar @{$data};
}

=head3 first 

    $bm->first
    
Returns the first set value (the order of the values is determied by the 
sequence of the addition)

=cut

sub first {
    my $self = shift;
    my $data = $self->_data // [];
    return $data->[0];
}

=head3 remove

    $bm->remove(ITEMS);

This method takes the same arguments as C<new>. The values supplied in the
arguments will be unset.

=cut

sub remove {
    my ( $self, @args ) = @_;

    my @remove = $self->_parse_params(@args);
    my @data = $self->list;
    
    $self->_data( [ grep { ! ( $_ ~~ @remove ) } @data ] );
}

=head3 reset

    $bm->reset();

Unsets all values, leaving an empty list.

=cut

sub reset {
    my ( $self ) = @_;
    $self->_data([]);
}

=head3 add

    $bm->add(ITEMS);

This method takes the same arguments as C<new>. The specified values will
be set.

=cut

sub add {
    my ( $self, @args ) = @_;

    my @set = $self->_parse_params(@args);

    my @data = $self->list ;
    push( @data,  grep { !( $_ ~~ @data ) } @set  );
    $self->_data( \@data  );
}

=head3 mask

    $bm->mask();

Returns the integer representing the bitmask of all the set values.

=cut

sub mask {
    my ($self) = @_;
    my $items = $self->bitmask_items;
    return int( 
        ( 
        reduce { $a | $b } map { $items->{$_} } $self->list) // 0  
        );
}

=head3 sql

    $bm->sql();

Retuns the string representing the bitmask as used by POSTGRESQL.

=cut

sub sql {
    my ($self) = @_;
    return sprintf( '%0' . $self->bitmask_length . 'b' , $self->mask() );
}

=head3 sqlfilter

    $bm->sqlfilter($field);

This method can be used for database searches in conjunction with 
L<SQL::Abstract> an POSTGRESQL (SQL::Abstract is used by C<DBIx::Class> for
generating searches). The search will find all database rows
with bitmask that have at least the given values set. (use
the C<sql> method for an exact match)

Example how to use sqlfilter with SQL::Abstract:

    my($stmt, @bind) = $sql->select(
        'mytable', 
        \@fields,
        {
            $bm->sqlfilter('mytable.bitmaskfield'),
        }
    );

Example how to use sqlfilter with DBIx::Class:
   
    my $list = $resultset->search(
        { 
            $bm->sqlfilter('me.bitmaskfield'), 
        },
    );


=cut

sub sqlfilter {
    my ($self,$field) = @_;

    my $sql_mask = $self->sql();
    my $format = "bitand( $field, B'$sql_mask' )";
    return ( $format, \" = B'$sql_mask'" );
}

=head3 hasall

    $bm->hasall(ITEMS);

This method takes the same arguments as C<new>. Checks if the set value 
exactly match the value list and returns true or false.

=cut

sub hasall {
    my ($self, @args) = @_;
    
    my @check = $self->_parse_params(@args);
    
    foreach my $data (@check) {
        return 0 unless $data ~~ $self->list;
    }
    return 1;
}

=head3 hasany

    $bm->hasany(ITEMS);

This method takes the same arguments as C<new>. Checks if at least one set 
value 
matches the supplied value list and returns true or false

=cut

sub hasany {
    my ($self, @args) = @_;
    
    my @check = $self->_parse_params(@args);
        
    foreach my $data (@check) {
        return 1 if $data ~~ $self->list;
    }
    return 0;
}

=head1 SUBCLASSING

Bitmask::Data was designed to be subclassed.
 
    package MyBitmask;
    use base qw(Bitmask::Data);
    __PACKAGE__->bitmask_length(20); # Default length is 16
    __PACKAGE__->init(
       [ 'value1' => 0b000000000000000001 ],
       [ 'value2' => 0x2 ],
       [ 'value2' => 4 ],
       'value4',
       'value5',
    );

=head1 WORKING WITH DATABASES

This module comes with support for POSTGRESQL databases (patches for other
database vendors are welcome). 

First you need to create the correct column types:

    CREATE TABLE bitmaskexample ( 
        id integer DEFAULT nextval('pkey_seq'::regclass) NOT NULL,
        bitmask bit(14),
        otherfields character varying
    );

The length of the bitmask field must match C<CLAS-E<gt>bitmask_length>.

This module provides two convenient methods to work with databases:

=over

=item * L<sqlfilter>: Search which have the current values set

=item * L<sql>: Print the bitmask string as used by the database

=back

If you are working with DBIx::Class you might also install de- and inflators
for Bitmask objects:

    sub register_column {
        my ( $self, $column, $info, @rest ) = @_;
        $self->next::method( $column, $info, @rest );
    
        # For bitmask column
        if ($column eq 'bitmask') {
            $self->inflate_column('bitmask',{
                inflate => sub {
                    my $value = shift;
                    return MyBitmask->new($value);
                },
                deflate => sub {
                    my $value = shift;
                    undef $value 
                        unless ref($value) && $value->isa('MyBitmask');
                    $value //= MyBitmask->new();
                    return $value->sql;
                },
            });
            return;
        }
    }

=head1 SUPPORT

Please report any bugs or feature requests to 
C<bug-bitmask-data@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Bitmask::Data>.
I will be notified and then you'll automatically be notified of the progress on 
your report as I make changes.

=head1 AUTHOR

    Klaus Ita
    koki [at] worstofall.com

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.revdev.at>

=head1 ACKNOWLEDGEMENTS 

This module was originally written by Klaus Ita (Koki) for Revdev 
L<http://www.revdev.at>, a nice litte software company I (Maros) run with 
Koki and Domm (L<http://search.cpan.org/~domm/>).

=head1 COPYRIGHT

Bitmask::Data is Copyright (c) 2008 Klaus Ita, Maroš Kollár 
- L<http://www.revdev.at>

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

'0b000000000001';