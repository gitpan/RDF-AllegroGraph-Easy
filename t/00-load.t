#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RDF::AllegroGraph::Easy' );
}

diag( "Testing RDF::AllegroGraph::Easy $RDF::AllegroGraph::Easy::VERSION, Perl $], $^X" );
