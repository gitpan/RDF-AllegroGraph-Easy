package RDF::AllegroGraph::Catalog;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);

=pod

=head1 NAME

RDF::AllegroGraph::Catalog - AllegroGraph catalog handle

=head1 SYNOPSIS

   my $server = new RDF::AllegroGraph::Server ('http://localhost:8080');
   my $vienna = new RDF::AllegroGraph::Catalog (NAME => '/vienna', SERVER => $server);

   warn "all repositories in vienna: ".Dumper $vienna->repositories;

   # open an existing
   my $air   = $vienna->repository ('/air-quality');
   # create one if it does not exist
   use Fcntl;
   my $water = $vienna->repository ('/water', mode => O_CREAT);

=head1 DESCRIPTION

Allegrograph catalogs are a container for individual repositories
(L<RDF::AllegrGraph::Repository>). The latter roughly correspond to what the RDF folks call a
I<model>. You can get a catalog handle from the AG server (L<RDF::AllegroGraph::Server>).

=cut

use RDF::AllegroGraph::Repository;
use RDF::AllegroGraph::Utils;

use JSON;
use HTTP::Status;
use Fcntl;
use Data::Dumper;

=pod

=head1 INTERFACE

=head2 Constructor

The constructor expects the following options:

=over

=item C<NAME> (mandatory, string)

This is a string of the form C</mycatalog> and it identifies that very catalog on the server.

=item C<SERVER> (mandatory, L<RDF::AllegroGraph::Server> object)

This is the handle to the server.

=back

Example:

   my $server = new RDF::AllegroGraph::Server (...);
   my $vienna = new RDF::AllegroGraph::Catalog (NAME => '/vienna', SERVER => $server);

=cut

sub new {
    my $class   = shift;
    my %options = @_;
    die "no NAME"   unless $options{NAME};
    die "no SERVER" unless $options{SERVER};
    return bless \%options, $class;
} 

=pod

=head2 Methods

=over

=item B<repositories>

I<@repos> = I<$cat>->repositories

This method returns L<RDF::AllegroGraph::Repository> objects for B<all> repositories in the catalog.

=cut

sub repositories {
    my $self = shift;
    my $resp = $self->{SERVER}->{ua}->get ($self->{SERVER}->{ADDRESS} . '/catalogs' . $self->{NAME} . '/repositories');
    die "protocol error: ".$resp->status_line unless $resp->is_success;
    my $repo = from_json ($resp->content);
    return
	map { RDF::AllegroGraph::Repository->new (%$_, CATALOG => $self) }
	map { RDF::AllegroGraph::Utils::_hash_to_perl ($_) }
        @$repo;
}

=pod

=item B<repository>

I<$repo> = I<$cat>->repository (I<$repo_id> [, I<$mode> ])

This method returns an L<RDF::AllegroGraph::Repository> object for the repository with
the provided id. That id always has the form C</somerepository>.

If that repository does not exist in the catalog, then an exception C<cannot open> will be
raised. That is, unless the optional I<mode> is provided having the POSIX value C<O_CREAT>. Then the
repository will be created.

=cut

sub repository {
    my $self = shift;
    my $id   = shift;
    my $mode = shift || O_RDONLY;

    if (my ($repo) = grep { $_->id eq $id } $self->repositories) {
	return $repo;
    } elsif ($mode == O_CREAT) {
	(my $repoid = $id) =~ s|^/.+?/|/|;                                                 # get rid of the catalog name
	use HTTP::Request;
	my $requ = HTTP::Request->new (PUT => $self->{SERVER}->{ADDRESS} . '/catalogs' . $self->{NAME} . '/repositories' . $repoid);
	my $resp = $self->{SERVER}->{ua}->request ($requ);
	die "protocol error: ".$resp->status_line unless $resp->code == RC_NO_CONTENT;
	return $self->repository ($id);                                                    # recursive, but without forced create
    } else {
	die "cannot open repository '$id'";
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

