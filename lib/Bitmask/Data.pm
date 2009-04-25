# ============================================================================
package Bitmask::Data;
# ============================================================================
use strict;
use warnings;

use base qw(Class::Data::Inheritable);
use 5.010;

use Carp;
use List::Util qw(reduce);

our $VERSION = '1.08';

use overload 
    '0+'    => 'mask',
    '""'    => 'string',
    '<=>'   => sub {
        my ($self,$value,$order) = @_;
        $value = $value->mask
            if ref $value && $value->isa('Bitmask::Data');
        $self = $self->mask;
        return ($order) ? 
            $self <=> $value :
            $value <=> $self;
    },
    'cmp'   => sub {
        my ($self,$value,$order) = @_;
        $value = $value->string
            if ref $value && $value->isa('Bitmask::Data');
        $self = $self->string;
        return ($order) ? 
            $self cmp $value :
            $value cmp $self;
    },
    '+='     => sub {
        my ($self,$value) = @_;
        return $self->add($value);
    },
    '-='     => sub {
        my ($self,$value) = @_;
        return $self->remove($value);
    },
    '|'     => sub {
        my ($self,$value) = @_;
        return $self->mask | $value; 
    },
    '^'     => sub {
        my ($self,$value) = @_;
        return $self->mask ^ $value; 
    };
    
    
__PACKAGE__->mk_classdata( bitmask_length   => 16 );
__PACKAGE__->mk_classdata( bitmask_items    => {} );
__PACKAGE__->mk_classdata( bitmask_default  => undef );
__PACKAGE__->mk_classdata( bitmask_complex  => 0 );
__PACKAGE__->mk_classdata( bitmask_lazyinit => 0 );

=encoding utf8

=head1 NAME

Bitmask::Data - Handle bitmasks in an easy and flexible way

=head1 SYNOPSIS

 # Create a simple bitmask class
 package MyBitmask;
 use base qw(Bitmask::Data);
 __PACKAGE__->bitmask_length(18);
 __PACKAGE__->bitmask_default(0b000000000000000011);
 __PACKAGE__->init(
    'value1' => 0b000000000000000001,
    'value2' => 0b000000000000000010,
    'value2' => 0b000000000000000100,
    'value4' => 0b000000000000001000,
    'value5' => 0b000000000000010000,
    ...
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

Bitmask length is limited to 32 (respectively 64 on 64-bit perl).

Default: 16

=head3 bitmask_default

Set/Get the default bitmask for empty Bitmask::Data objects.

Default: undef

=head3 bitmask_complex

Boolean value that enables/disables checks for composed bitmasks. If false
init will only accept bitmask bit values that are powers of 2. 

Default: 0

Complex bitmask also allow the creation of overlapping bitmask values:
 
 packacke LocaleBitmask;
 use base qw(Bitmask::Data);
 __PACKAGE__->bitmask_length(8); # 8 bits
 __PACKAGE__->bitmask_complex(1); # enable overlapping bitmasks
 __PACKAGE__->init(
    AT      => 0b000_00001, # Austria
    CH      => 0b000_00010, # Switzerland
    DE      => 0b000_00100, # Germany
    FR      => 0b000_01000, # France
    IT      => 0b000_10000, # Italy
    
    de      => 0b001_00000, # German
    fr      => 0b010_00000, # French
    it      => 0b100_00000, # Italian
    
    de_AT   => 0b001_00001, # German / Austria
    de_CH   => 0b001_00010, # German / Switzerland
    de_DE   => 0b001_00100, # German / Germany
    fr_CH   => 0b010_00010, # French / Switzerland
    fr_FR   => 0b010_01000, # French / France
    it_CH   => 0b100_00010, # Italian / Switzerland    
    it_IT   => 0b100_10000, # Italian / Italy
 );
 
 # Somewhere else
 
 LocaleBitmask->new('de')->hasany('de'); # true
 LocaleBitmask->new('de')->hasany('de_DE'); # true ('de' matches)
 LocaleBitmask->new('de')->hasall('de_DE'); # false
 LocaleBitmask->new('de_DE','de_AT','de_CH')->hasexact('de','AT','DE','CH'); # true
 LocaleBitmask->new('de_DE','de_AT','de_CH')->list # de,DE,de_DE,de_AT,AT,de_CH,CH

=head3 bitmask_lazyinit

Boolean value that enables/disables warnings for lazy initialization. (
Lazy initialization = call of init without bitmask bit values)

Default: 0

 __PACKAGE__->bitmask_lazyinit(1);
 __PACKAGE__->init(
    'value1', # will be 0b001
    'value2', # will be 0b010
    'value3'  # will be 0b100
 );

=head3 bitmask_items

HASHREF of all bitmask items. Don't mess around here unless you know 
what you are doing.

=head3 init

    CLASS->init(LIST of VALUES);

Initializes the bitmask class. You can supply a list of possible values.
Optionally you can also specify the bits for the mask by adding bit values
after the value. 
 
    CLASS->init(
        'value1' => 0b000001,
        'value2' => 0b000010,
        'value3' => 0b001000,
        'value4' => 0b010000,
    );
    
With C<bitmask_lazyinit> enabled you can also skip the bitmask bit values

    CLASS->bitmask_lazyinit(1);
    CLASS->init(
        'value1',
        'value2',
        'value3',
        'value4',
    );

=cut

sub init {
    my $class = shift;

    my $length = $class->bitmask_length;

    croak('Bitmask length not set')
        unless $length;

    my $items = {};
    my $count = 0;
    
    # Take first element from @_
    while (my $name = shift @_) {
        my $bit;

        $count++;

        croak( 'Too many values in bitmask: max ' . $class->bitmask_length )
            if $count > $class->bitmask_length;

        given ( $_[0] // '' ) {
            when (m/^\d+$/) {
                $bit = shift @_;
            }
            when (m/\A(?:0b)?([01]{$length})\Z/) {
                $bit = oct('0b' . $1);
				shift @_;
            }
            default {
                carp( "Lazy bitmask initialization detected: Please enable"
                        . " <bitmask_lazyinit> or change init parameters" )
                    unless ( $class->bitmask_lazyinit );
                $bit = 2**( $count - 1 );
            }
        }

        $class->_check_bit($bit)
            or croak( 'Invalid bit value: ' . $bit );

        croak( 'Value already in bitmask: ' . $name )
            if exists $items->{$name};

        croak( 'Bit already in bitmask: ' . $bit )
            if grep { $class->bitmask_complex ? ($_ eq $bit) : ($_ & $bit) } values %{$items};

        $items->{$name} = $bit;
    }

    $class->bitmask_items($items);
    return;
}

sub _check_bit {
    my $class = shift;
    my $bit   = shift;

    return 1 if $bit == 0;

    # Check it it is a power of 2 or complex
    return 0 if !$class->bitmask_complex && $bit & ( $bit - 1 );

    # Get bit length
    my $value = int( log($bit) / log(2) );

    # Reject too long values
    return 0 if ( $value >= $class->bitmask_length );

    return 1;
}

=head3 data2bit

    CLASS->data2bit(VALUE);

Returns the corresponding bit for the given value.

=cut

sub data2bit {
    my ( $class, $value ) = @_;
    return
        exists $class->bitmask_items->{$value}
        ? $class->bitmask_items->{$value}
        : undef;
}

=head3 bit2data

    CLASS->bit2data(BIT);

Returns the corresponding value for the given bit.

=cut

sub bit2data {
    my ( $class, $bit ) = @_;
    while ( my @item = each %{ $class->bitmask_items } ) {
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

    die "Invalid bitmask value <$bitmask>"
        if ( $bitmask > ( 2**$class->bitmask_length ) - 1 );

    my @result;
    my $items = $class->bitmask_items;

    my $check = 0;
    $check = $_ | $check foreach ( values %{$items} );
    die "Invalid bitmask items <$bitmask>"
        if ( $bitmask & ~$check );

    if ( $class->bitmask_complex ) {
        my %bm;
        @bm{ values %$items } = keys %$items;
        my @all = map { $_ & $bitmask } keys %bm;
        my @bitmasks = grep { $_ ~~ %bm } @all;
        @result = @bm{@bitmasks};
    }
    else {
        @result = grep { $items->{$_} & $bitmask } keys %{$items};
    }

    return wantarray ? @result : \@result;
}

=head3 any2data

    CLASS->any2data(124); # Bitmask
    CLASS->any2data('de_DE'); # Value
    CLASS->any2data(0b110001001); # Bitmask in bit notation
    CLASS->any2data('0B110001001'); # Bitmask string
    CLASS->any2data('0b111000001'); # Bitmask string

Turns a single value (bit, bitmask,value, bitmask string) into a value.

=cut

sub any2data {
    my ( $class, $any ) = @_;

    my $bl = $class->bitmask_length;
    my @data;
    
    croak "Bitmask, Item or integer expected"
        unless defined $any;
    
    given ($any) {
        when ( %{ $class->bitmask_items } ) {
            @data = ($any);
        }
        when (m/\A0[bB]([01]{$bl})\Z/) {
            @data = ( $class->bm2data( oct("0b$1") ) );
        }
        when (m/\A\d+\Z/) {
            @data = ( $class->bm2data($any) );
        }
        default {
            die "Could not turn <$any> into something meaningful";
        };
    }

    return @data;
}

=head3 _parse_params

    CLASS->_parse_params(LIST)

Helper method for parsing params passed to various methods.

=cut

sub _parse_params {
    my ( $class, @args ) = @_;

    my @data = ();
    foreach my $param (@args) {
        next unless defined $param;
        my @tmp;
        if ( ref $param eq 'ARRAY' ) {
            push( @tmp, $class->_parse_params(@$param) );
        }
        elsif (ref $param
            && $param->isa( ref $class || $class )
            && $param->can('list') )
        {
            push( @tmp, $param->list );
        }
        else {
            push( @tmp, $class->any2data($param) );
        }

        foreach my $item (@tmp) {
            if ( $class->bitmask_complex ) {
                foreach ($class->bm2data($class->data2bit($item))) {
                    push @data, $_
                        unless $_ ~~ \@data;
                }
            } else {
                push @data, $item
                    unless $item ~~ \@data;
            }
        }

    }

    return @data;
}

=head2 Overloaded operators

Bitmask::Data uses overload by default. 

=over

=item * Numeric context

Returns bitmask integer value (see L<mask> method)

=item * Scalar context

Returns bitmask string representation (see L<string> method)

=item * String comparison

=item * Numeric comparison

=item * -=

Removes bitmask value (see L<remove> method)

=item * +=

Adds bitmask value (see L<ass> method)

=item * ~, ^, &, |

Performs the bit operations on the bitmask

=back

=head2 Public Methods

=head3 new

    my $bm = MyBitmask->new();
    my $bm = MyBitmask->new('value1');
    my $bm = MyBitmask->new('value2', 'value3');
    my $bm = MyBitmask->new('0b00010000010000');
    my $bm = MyBitmask->new(124);
    my $bm = MyBitmask->new(0b00010000010000);
    my $bm = MyBitmask->new(0x2);
    my $bm = MyBitmask->new([32, 'value1', 0b00010000010000]);

Create a new bitmask object. You can supply almost any combination of 
bits, bitmasks and values, even mix different types. 

=over

=item * LIST or ARRAYREF of values

=item * LIST or ARRAYREF of strings representing bits or bitmasks (starting with '0b')

=item * LIST or ARRAYREF of bitmasks

=item * Any combination of the above

=back

=cut

sub new {
    my ( $class, @args ) = @_;

    croak('Bitmask not initialized')
        unless scalar keys %{ $class->bitmask_items };

    my $self = bless { _data => [], }, $class;

    $self->set( @args );

    return $self;
}

=head3 clone

    $bm2 = $bm->clone();
    
Clones a bitmask object

=cut

sub clone {
    my ( $self ) = @_;

    my $new = bless { _data => \ @{$self->{_data}}, }, ref $self;
    
    return $new;
}

=head3 set

    $bm->set(ITEMS);
    
This method takes the same arguments as C<new>. It resets the current bitmask
and sets the supplied arguments. 

Returns the object.

=cut

sub set {
    my ( $self, @args ) = @_;

    $self->{_data} = [];
    $self->add(@args);

    unless ( scalar @{ $self->{_data} } ) {
        $self->add( $self->bitmask_default )
            if defined $self->bitmask_default;
    }
    
    return $self;
}

=head3 list

    $bm->list()

In list context, this returns a list of the set values in scalar context, 
this returns an array reference to the list of values.

=cut

sub list {
    my $self = shift;
    my $data = $self->{_data} // [];
    return wantarray ? @$data : $data;
}

=head3 length

    $bm->length()

Number of set bitmask values.

=cut

sub length {
    my $self = shift;
    my $data = $self->{_data} // [];
    return scalar @{$data};
}

=head3 first 

    $bm->first()
    
Returns the first set value (the order of the values is determined by the 
sequence of the addition)

=cut

sub first {
    my $self = shift;
    my $data = $self->{_data} // [];
    return $data->[0];
}

=head3 remove

    $bm->remove(ITEMS);

This method takes the same arguments as C<new>. The values supplied in the
arguments will be unset.

Returns the object.

=cut

sub remove {
    my ( $self, @args ) = @_;

    my @remove = $self->_parse_params(@args);

    $self->{_data} = [ grep { !( $_ ~~ @remove ) } @{ $self->{_data} } ];
    return $self;
}

=head3 reset

    $bm->reset();

Unsets all values, leaving an empty list.

Returns the object.

=cut

sub reset {
    my ($self) = @_;
    $self->set();
    return $self;
}

=head3 setall

    $bm->setall();

Sets all values.

Returns the object.

=cut

sub setall {
    my ($self) = @_;
    $self->{_data} = [ keys %{ $self->bitmask_items } ];
    return $self;
}

=head3 add

    $bm->add(ITEMS);

This method takes the same arguments as C<new>. The specified values will
be set.

Returns the object.

=cut

sub add {
    my ( $self, @args ) = @_;

    my @set = $self->_parse_params(@args);

    my @data = $self->list;
    push( @data, grep { !( $_ ~~ @{ $self->{_data} } ) } @set );
    $self->{_data} = \@data;
    return $self;
}

=head3 neg

    $bm->neg();

Negates the bitmask. Sets all unset values and vice versa.

Returns the object.

=cut

sub neg {
    my ( $self ) = @_;

    my $new = [];
    foreach my $item (keys %{$self->bitmask_items}) {
        push @{$new},$item
            unless grep {$_ eq $item} @{$self->{_data}};
    }
    $self->{_data} = $new;
    return $self;
}

=head3 mask

    $bm->mask();

Returns the integer representing the bitmask of all the set values.

=cut

sub mask {
    my ($self) = @_;
    my $items = $self->bitmask_items;
    return
        int( ( reduce { $a | $b } map { $items->{$_} } @{ $self->{_data} } )
        // 0 );
}

=head3 string

    $bm->string();

Retuns the string representing the bitmask.

=cut

sub string {
    my ($self) = @_;
    return sprintf( '%0' . $self->bitmask_length . 'b', $self->mask() );
}

=head3 sqlfilter_all

    $bm->sqlfilter_all($field);

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
            $bm->sqlfilter_all('mytable.bitmaskfield'),
        }
    );

Example how to use sqlfilter with DBIx::Class:
   
    my $list = $resultset->search(
        { 
            $bm->sqlfilter_all('me.bitmaskfield'), 
        },
    );


=cut

=head3 sqlfilter

Shortcut for C<sqlfilter_all>

=cut

*sqlfilter = \&sqlfilter_all;

sub sqlfilter_all {
    my ( $self, $field ) = @_;

    my $sql_mask = $self->string();
    my $format   = "bitand( $field, B'$sql_mask' )";
    return ( $format, \" = B'$sql_mask'" );
}

=head3 sqlfilter_any

    $bm->sqlfilter_any($field);

Works like C<sqlfilter_all> but checks for any bit matching

=cut

sub sqlfilter_any {
    my ( $self, $field ) = @_;

    my $sql_mask = $self->string();
    my $format   = "bitand( $field, B'$sql_mask' )";
    return ( $format, \" = TRUE" );
}


=head3 hasall

    $bm->hasall(ITEMS);

This method takes the same arguments as C<new>. Checks if all requestes items
are set and returns true or false.

=cut

sub hasall {
    my ( $self, @args ) = @_;

    my $class = ref $self;

    my $mask = $class->new(@args)->mask;
     
    return (($mask & $self->mask) == $mask) ? 1:0;
}

=head3 hasexact

    $bm->hasexact(ITEMS);

This method takes the same arguments as C<new>. Checks if the requestes items
exactly match the set values.

=cut

sub hasexact {
    my ( $self, @args ) = @_;

    my $class = ref $self;

    return $class->new(@args)->mask == $self->mask ? 1:0;
}

=head3 hasany

    $bm->hasany(ITEMS);

This method takes the same arguments as C<new>. Checks if at least one set 
value matches the supplied value list and returns true or false

=cut

sub hasany {
    my ( $self, @args ) = @_;

    my $class = ref $self;

    return $class->new(@args)->mask & $self->mask ? 1:0;
}

=head1 CAVEATS

Since Bitmask::Data is very liberal with input data you cannot use numbers
as bitmask values. (It would think that you are supplying a bitmask and not
a value)

Bitmask::Data adds a considerable processing overhead (especially when 
the bitmask_complex option is enabled) to bitmask manipulations. If you don't
need the extra comfort please use the perl built in bit operators.

Bitmask length is limited to 32 (respectively 64 on 64-bit perl).

=head1 SUBCLASSING

Bitmask::Data was designed to be subclassed.
 
    package MyBitmask;
    use base qw(Bitmask::Data);
    __PACKAGE__->bitmask_length(20); # Default length is 16
    __PACKAGE__->init(
        'value1' => 0b000000000000000001,
        'value2' => 0x2,
        'value2' => 4,
        'value4', # lazy initlialization
        'value5', # lazy initlialization
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

The length of the bitmask field must match C<CLASS-E<gt>bitmask_length>.

This module provides three convenient methods to work with databases:

=over

=item * L<sqlfilter_all>: Search for matching bitmasks

=item * L<sqlfilter_any>: Search for bitmasks with matching bits

=item * L<string>: Print the bitmask string as used by postgres database

=back

If you are working with DBIx::Class you might also install de- and inflators
for Bitmask objects:

    __PACKAGE__->inflate_column('fieldname',{
        inflate => sub {
            my $value = shift;
            return MyBitmask->new($value);
        },
        deflate => sub {
            my $value = shift;
            undef $value 
                unless ref($value) && $value->isa('MyBitmask');
            $value //= MyBitmask->new();
            return $value->string;
        },
    });

=head1 SUPPORT

Please report any bugs or feature requests to 
C<bug-bitmask-data@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Bitmask::Data>.
I will be notified and then you'll automatically be notified of the progress 
on your report as I make changes.

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

0b000000000001;
