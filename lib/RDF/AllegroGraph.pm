package RDF::AllegroGraph;

=pod

=head1 NAME

RDF::AllegroGraph - Client implementation for the AllegroGraph tuple server

=head1 DESCRIPTION

The AllegroGraph server is a tuple store server, produced by Franz Inc. (L<http://agraph.franz.com/allegrograph/>).
When running, you can communicate with it via a RESTful web interface, as described in

L<http://agraph.franz.com/support/documentation/3.2/new-http-server.html>

This package offers a client implementation of that protocol. With it you can either use
a rather orthodox style (L<RDF::AllegroGraph::Server>) or a quick-n-easy approach (L<RDF::AllegroGraph::Easy>).

B<NOTE>: This is still exploratory. See the TODO.

=head1 AUTHOR

Robert Barta, C<< <rho at devc.at> >>

=head1 COPYRIGHT & LICENSE

Copyright 200[9] Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=head1 SEE ALSO

L<RDF::AllegroGraph::Server>, L<RDF::AllegroGraph::Easy>

=cut

our $VERSION = '0.01';

1;
