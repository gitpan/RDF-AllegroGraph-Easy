package RDF::AllegroGraph::Repository;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);

use Switch;
use Data::Dumper;

use JSON;
use URI::Escape qw/uri_escape_utf8/;

=pod

=head1 NAME

RDF::AllegroGraph::Repository - AllegroGraph repository handle

=head1 DESCRIPTION

An AllegroGraph repository corresponds to an RDF model. Into such a model you can park RDF
information, either as individual statements or via file bulk loading. Then you can navigate through
it on a statement level, or query that model.

=head1 INTERFACE

=head2 Constructor

The constructor expects the following fields:

=over

=item C<CATALOG> (mandatory)

This is the handle to the catalog the repository belongs to.

=item C<id> (mandatory)

This identifier is always of the form C</whatever>.

=back

Example:

  my $repo = new RDF::AllegroGraph::Repository (CATALOG => $cat, id => '/whereever');

=cut

sub new {
    my $class = shift;
    my %options = @_;
    my $self = bless \%options, $class;
    $self->{path} = $self->{CATALOG}->{SERVER}->{ADDRESS} . '/catalogs' . $self->{CATALOG}->{NAME} . '/repositories/' . $self->{id};
    return $self;
}

=pod

=head2 Methods

=over

=item B<id>

This read-only accessor method returns the id of the repository.

=cut

sub id {
    my $self = shift;
    return $self->{CATALOG}->{NAME} . '/' . $self->{id};
}

=pod

=item B<disband>

I<$repo>->disband

This method removes the repository from the server. The object cannot be used after that, obviously.

=cut

sub disband {
    my $self = shift;
    my $requ = HTTP::Request->new (DELETE => $self->{path});
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->request ($requ);
    die "protocol error: ".$resp->status_line unless $resp->is_success;
}

=pod

=item B<size>

I<$nr_triples> = I<$repo>->size

Returns the size of the repository in terms of the number of triples.

B<NOTE>: As of time of writing, AllegroGraph counts duplicate triples!

=cut

sub size {
    my $self = shift; 
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->get ($self->{path} . '/size');
    die "protocol error: ".$resp->status_line unless $resp->is_success; 
    return $resp->content;
}

=pod

=item B<add>

I<$repo>->add ('file://....', ...)

I<$repo>->add ('http://....', ...)

I<$repo>->add (' triples in N3 ', ...)

I<$repo>->add ([ I<$subj_uri>, I<$pred_uri>, I<$obj_uri> ], ...)

This method adds triples to the repository. The information can be provided in any of the following
ways (also mixed):

=over

=item file, HTTP, FTP URL

If a string looks like an URL, it will be dereferenced, the contents of the resource consulted and
that shipped to the repository on the server. If the resource cannot be read, an exception C<Could
not open> will be raised. Any number of these URL can be provided as parameter.

B<NOTE>: Only N3 files are supported, and also only when the URL ends with the extension C<nt> or
C<n3>.

=item N3 triple string

If the string looks like N3 notated triples, that content is shipped to the server.

=item ARRAY reference

The reference is interpreted as one triple (statement), containing 3 URIs. These will be shipped
as-is to the server.

=back

If the server chokes on any of the above, an exception C<protocol error> is raised.

B<NOTE>: There are no precautions for over-large content. Yet.

B<NOTE>: Named graphs (aka I<contexts>) are not handled. Yet.


=cut

sub add {
    _put_post_stmts ('POST', @_);
}

sub _put_post_stmts {
    my $method = shift;
    my $self   = shift;

    my @stmts;                                                                  # collect triples there
    my $n3;                                                                     # collect N3 stuff there
    my @files;                                                                  # collect file names here
    use Regexp::Common qw /URI/;
    foreach my $item (@_) {                                                     # walk through what we got
	if (ref($item) eq 'ARRAY') {                                            # a triple statement
	    push @stmts, $item;
	} elsif (ref ($item)) {
	    die "don't know what to do with it";
	} elsif ($item =~ /^$RE{URI}{HTTP}/) {
	    push @files, $item;
	} elsif ($item =~ /^$RE{URI}{FTP}/) {
	    push @files, $item;
	} elsif ($item =~ /^$RE{URI}{file}/) {
	    push @files, $item;
	} else {                                                                # scalar => N3
	    $n3 .= $item;
	}
    }

    my $ua = $self->{CATALOG}->{SERVER}->{ua};                                  # local handle

    if (@stmts) {                                                               # if we have something to say to the server
	switch ($method) {
	    case 'POST' {
		my $resp  = $ua->post ($self->{path} . '/statements',
				       'Content-Type' => 'application/json', 'Content' => encode_json (\@stmts) );
		die "protocol error: ".$resp->status_line unless $resp->is_success;
	    }
	    case 'PUT' {
		my $requ = HTTP::Request->new (PUT => $self->{path} . '/statements',
					       [ 'Content-Type' => 'application/json' ], encode_json (\@stmts));
		my $resp = $ua->request ($requ);
		die "protocol error: ".$resp->status_line unless $resp->is_success;
	    }
	    case 'DELETE' {                                                     # DELETE
		# first bulk delete facts, i.e. where there are no wildcards
		my @facts      = grep { defined $_->[0]   &&   defined $_->[1] &&   defined $_->[2] } @stmts;
		my $requ = HTTP::Request->new (POST => $self->{path} . '/statements/delete',
					       [ 'Content-Type' => 'application/json' ], encode_json (\@facts));
		my $resp = $ua->request ($requ);
		die "protocol error: ".$resp->status_line unless $resp->is_success;

		# the delete one by one those with wildcards
		my @wildcarded = grep { ! defined $_->[0] || ! defined $_->[1] || ! defined $_->[2] } @stmts;
		foreach my $w (@wildcarded) {
		    my $requ = HTTP::Request->new (DELETE => $self->{path} . '/statements' . '?' . _to_uri ($w) );
		    my $resp = $ua->request ($requ);
		    die "protocol error: ".$resp->status_line unless $resp->is_success;
		}
	    }
	    else { die $method; }
	}
    }
    if ($n3) {                                                                  # if we have something to say to the server
	my $requ = HTTP::Request->new ($method => $self->{path} . '/statements', [ 'Content-Type' => 'text/plain' ], $n3);
	my $resp = $ua->request ($requ);
	die "protocol error: ".$resp->status_line unless $resp->is_success;
    }
    for my $file (@files) {                                                     # if we have something to say to the server
	use LWP::Simple;
	my $content = get ($file) or die "Could not open URL '$file'";
	my $mime;                                                               # lets guess the mime type
	switch ($file) {                                                        # magic does not normally cope well with RDF/N3, so do it by extension
	    case /\.n3$/ { $mime = 'text/plain'; }                              # well, not really, since its text/n3
	    case /\.nt$/ { $mime = 'text/plain'; }
	    case /\.xml$/ { $mime = 'application/rdf+xml'; }
	    case /\.rdf$/ { $mime = 'application/rdf+xml'; }
	    else { die; }
	}

	my $requ = HTTP::Request->new ($method => $self->{path} . '/statements', [ 'Content-Type' => $mime ], $content);
	my $resp = $ua->request ($requ);
	die "protocol error: ".$resp->status_line unless $resp->is_success;

	$method = 'POST';                                                        # whatever the first was, the others must add to it!
    }


}

sub _to_uri {
    my $w = shift;
    my @params;
    push @params, 'subj='.$w->[0] if $w->[0];
    push @params, 'pred='.$w->[1] if $w->[1];
    push @params, 'obj=' .$w->[2] if $w->[2];
    return join ('&', @params);   # TODO URI escape?
}

=pod

=item B<replace>

This method behaves exactly like C<add>, except that any content is wiped before adding anything.

=cut

sub replace {
    _put_post_stmts ('PUT', @_);
}

=pod

=item B<delete>

I<$repo>->delete ([ I<$subj_uri>, I<$pred_uri>, I<$obj_uri> ], ...)

This method removes the passed in triples from the repository. In that process, any combination of
the subject URI, the predicate or the object URI can be left C<undef>. That is interpreted as
wildcard which matches anything.

Example: This deletes anything where the Stephansdom is the subject:

  $air->delete ([ '<urn:x-air:stephansdom>', undef, undef ])

=cut

sub delete {
    _put_post_stmts ('DELETE', @_);
}

=pod

=item B<match>

I<@stmts> = I<$repo>->match ([ I<$subj_uri>, I<$pred_uri>, I<$obj_uri> ], ...)

This method returns a list of all statements which match one of the triples provided
as parameter. Any C<undef> as URI within such a triple is interpreted as wildcard, matching
any other URI.

=cut

sub match {
    my $self = shift;
    my @stmts;

    my $ua = $self->{CATALOG}->{SERVER}->{ua};
    foreach my $w (@_) {
	my $resp  = $ua->get ($self->{path} . '/statements' . '?' . _to_uri ($w));
	die "protocol error: ".$resp->status_line unless $resp->is_success;
	push @stmts, @{ from_json ($resp->content) };
    }
    return @stmts;
}

=pod

=item B<sparql>

I<@tuples> = I<$repo>->sparql ('SELECT ...')

I<@tuples> = I<$repo>->sparql ('SELECT ...' [, I<$option> => I<$value> ])

This method takes a SPARQL query string and returns a list of tuples which the query produced from
the repository.

B<NOTE>: At the moment only SELECT queries are supported.

As additional options are accepted:

=over

=item C<RETURN> (default: C<TUPLE_LIST>)

The result will be a sequence of (references to) arrays. All naming of the individual columns is
currently lost.

=back

=cut

sub sparql {
    my $self = shift;
    my $query = shift;
    my %options = @_;
    $options{RETURN} ||= 'TUPLE_LIST';        # a good default

    my @params;
    push @params, 'queryLn=sparql';
    push @params, 'query='.uri_escape_utf8 ($query);
    
    my $resp  = $self->{CATALOG}->{SERVER}->{ua}->get ($self->{path} . '?' . join ('&', @params) );
    die "protocol error: ".$resp->status_line unless $resp->is_success;

    my $json = from_json ($resp->content);
    switch ($options{RETURN}) {
	case 'TUPLE_LIST' {
	    return @{ $json->{values} };
	}
	else { die };
    }
}

=pod

=back

=head1 AUTHOR

Robert Barta, C<< <rho at devc.at> >>

=head1 COPYRIGHT & LICENSE

Copyright 200[9] Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

L<RDF::AllegroGraph>

=cut

our $VERSION  = '0.02';

1;

__END__
