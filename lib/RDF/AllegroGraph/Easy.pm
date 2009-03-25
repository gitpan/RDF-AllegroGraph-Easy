package RDF::AllegroGraph::Easy;

use warnings;
use strict;

require Exporter;
use base qw(Exporter);

=pod

=head1 NAME

RDF::AllegroGraph::Easy - Simplistic Interface to AllegroGraph HTTP server

=head1 SYNOPSIS

  my $storage = new RDF::AllegroGraph::Easy ('http://my:secret@localhost:8080');
  my $model   = $storage->model ('/scratch/catlitter', mode => O_CREAT);

  $model->add (....);                            # add stuff
  $model->delete (...);                          # get rid of stuff
  my @tuples = $model->sparql ('SELECT ...');    # query it
  $model->disband;                               # remove the whole thing

=head1 DESCRIPTION

The idea of this interface is to concentrate on the essentials:

=over

=item how to get a handle to a remote tuple store

=item how to get RDF content into that model

=item how to query the model

=back

=head1 INTERFACE

=head2 Constructor

The constructor expects one parameter which is interpreted as HTTP endpoint
for your AllegroGraph server. If left C<undef>, then the default C<http://localhost:8080>
will be used.

B<NOTE>: No trailing slash!

=cut

sub new {
    my $class   = shift;
    my $address = shift || 'http://localhost:8080';
    use RDF::AllegroGraph::Server;
    return new RDF::AllegroGraph::Server (ADDRESS => $address, @_);
}

=pod

=head1 AUTHOR

Robert Barta, C<< <rho at devc.at> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rdf-allegrograph-easy at rt.cpan.org>, or
through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RDF-AllegroGraph-Easy>.  I will be notified, and
then you'll automatically be notified of progress on your bug as I make changes.


=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.


=cut

our $VERSION = '0.01';

1;

__END__

