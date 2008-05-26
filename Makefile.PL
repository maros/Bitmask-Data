# Load the Module::Install bundled in ./inc/
use strict;
use inc::Module::Install;

# Define metadata
name            'Bitmask-Data';
all_from        'lib/Bitmask/Data.pm';

perl_version    '5.010';

# Specific dependencies
requires        'List::Util'                => 0;
requires        'Class::Data::Inheritable'  => 0;
build_requires  'Test::Pod'                 => 0;
build_requires  'Test::Pod::Coverage'       => 0;

WriteAll;