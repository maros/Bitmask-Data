# Load the Module::Install bundled in ./inc/
use strict;
use inc::Module::Install;

# Define metadata
name            'Bitmask-Data';
all_from        'lib/Bitmask/Data.pm';

perl_version    '5.010';

# Specific dependencies
requires        'Carp'                      => 0;
requires        'List::Util'                => 0;
requires        'Class::Data::Inheritable'  => 0;
build_requires  'Test::More'                => 0;
build_requires  'Test::Pod'                 => 0;
build_requires  'Test::Pod::Coverage'       => 0;
build_requires  'Test::Warn'                => 0;
build_requires  'Test::NoWarnings'          => 0;

WriteAll;
