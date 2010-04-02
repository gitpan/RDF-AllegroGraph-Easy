package RDF::AllegroGraph::Utils;

use Data::Dumper;

sub _hash_to_perl {
    my $h = shift;
#    warn "hash to perl ".Dumper $h;
    my $h2;
    foreach my $k (keys %$h) {
#	warn $k;
	$h2->{$k} = _data_to_perl ($h->{$k});
    }
    return $h2;
}

sub _data_to_perl {
    my $d = shift;
    if ($d =~ q|"true"\^\^<http://www.w3.org/2001/XMLSchema#boolean>|) {
	return 1;
    } elsif ($d =~ q|"false"\^\^<http://www.w3.org/2001/XMLSchema#boolean>|) {
	return undef;
    } elsif ($d =~ q|^<(.*)>$|) {
	return $1;
    } elsif ($d =~ q|^"(.*)"$|) {
	return $1;
    } elsif (ref ($d) eq 'JSON::XS::Boolean') {
	return JSON::XS::true == $d;
    } else {
	return $d;
    }
}

1;
