# -*- perl -*-

# t/002_pod.t - check pod

use Test::Pod tests => 1;

pod_file_ok( "lib/Bitmask/Data.pm", "Valid POD file" );