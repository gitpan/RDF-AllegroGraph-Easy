package RDF::AllegroGraph::Utils;

sub _hash_to_perl {
    my $h = shift;
    foreach my $k (keys %$h) {
	$h->{$k} = _data_to_perl ($h->{$k});
    }
    return $h;
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
    } else {
	return $d;
    }
}

1;
