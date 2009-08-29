#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Verifier' );
}

diag( "Testing Data::Verifier $Data::Verifier::VERSION, Perl $], $^X" );
