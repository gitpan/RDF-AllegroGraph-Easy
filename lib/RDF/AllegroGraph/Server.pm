package LWP::UserAgent::AG;

use LWP::UserAgent;
use base 'LWP::UserAgent';

#use LWP::Debug qw(+ -conns);

sub new {
    my $class = shift;
    my %options = @_;
    my $self  = $class->SUPER::new;
    $self->timeout(10);
    $self->env_proxy;
    $self->default_header('Accept' => "application/json");
    if ($options{AUTHENTICATION}) {
	( $self->{USERNAME}, $self->{PASSWORD} ) = ($options{AUTHENTICATION} =~ /^(.+):(.*)$/);
    }
    return $self;
}

sub get_basic_credentials {
    my $self = shift;
    return ($self->{USERNAME}, $self->{PASSWORD});
}

package RDF::AllegroGraph::Server;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);

=pod

=head1 NAME

RDF::AllegroGraph::Server - AllegroGraph server handle

=cut

our $VERSION  = '0.02';

=head1 SYNOPSIS

  #-- orthodox approach
  my $server = new RDF::AllegroGraph::Server (ADDRESS        => 'http://localhost:8080',
                                              TEST           => 0,
                                              AUTHENTICATION => 'joe:secret');
  my @catalogs = $server->catalogs;

  #-- commodity
  # get handles to all models (repositories) at the server
  my @models = $server->models;

  # get one in particular
  my $model  = $server->model ('/testcat/testrepo');

=cut

use JSON;
use Data::Dumper;

use RDF::AllegroGraph::Catalog;

=pod

=head1 DESCRIPTION

Objects of this class represent handles to remote AllegroGraph HTTP server. Such a server can hold
several I<catalogs> and each of them can hold I<repositories>. Here we also use the orthodox concept
of a I<model> which is simply one particular repository in one particular catalog.

For addressing one model we use a simple path structure, such as C</testcat/testrepo>.

All methods die with C<protocol error> if they do not receive an expected success.

=head1 INTERFACE

=head2 Constructor

To get a handle to the AG server, you can instantiate this class. The following options are
recognized:

=over

=item C<ADDRESS> (no default)

Specifies the REST HTTP address. Must be an absolute URL, without trailing slash. The
constructor dies otherwise.

=item C<TEST> (default: 0)

If set, the client will try to test connectivity with the AG server.

=item C<AUTHENTICATION> (no default)

String which must be of the form C<something:somethingelse> (separated by C<:>). That will be interpreted
as username and password to do basic HTTP authentication against the server.

=back

=cut

sub new {
    my $class   = shift;
    my %options = @_;
    die "no HTTP URL as ADDRESS specified" unless $options{ADDRESS} =~ q|^http://|;
    my $self = bless \%options, $class;
    $self->{ua} = new LWP::UserAgent::AG (AUTHENTICATION => $options{AUTHENTICATION});
    $self->{TEST} and 
        ( $self->ping or die "server unreachable" );
    return $self;
}

=pod

=head2 Methods

=over

=item B<catalogs>

I<@cats> = I<$server>->catalogs

This method lists the catalogs available on the remote server. The result is a list of relative
paths. 

=cut

sub catalogs {
    my $self = shift;
    my $resp = $self->{ua}->get ($self->{ADDRESS} . '/catalogs');
    die "protocol error: ".$resp->status_line unless $resp->is_success;
    my $cats = from_json ($resp->content);
    return 
	map { $_ => RDF::AllegroGraph::Catalog->new (NAME => $_, SERVER => $self) }
        map { s|^/catalogs|| && $_ }   
        @$cats;
}

=pod

=item B<ping>

I<$server>->ping

This method tries to connect to the server and will return C<1> on success. Otherwise an exception
will be raised.

=cut

sub ping {
    my $self = shift;
    $self->catalogs and return 1;                                    # even if there are no catalogs, we survived the call
}

=pod

=item B<models>

I<%models> = I<$server>->models

This method lists all models available on the server. Returned is a hash reference. The keys are the
model identifiers, all of the form C</somecatalog/somerepository>. The values are repository objects.

=cut

sub models {
    my $self = shift;
    my %cats = $self->catalogs;                                      # find all catalogs
    return
	map { $_->id => $_ }                                         # generate a hash, because the id is a good key
	map { $_->repositories }                                     # generate from the catalog all its repos
        values %cats;          
}

=pod

=item B<model>

I<$server>->model (I<$mod_id>, I<option1> => I<value1>, ...)

This method tries to find an repository in a certain catalog. This I<model id> is always of the form
C</somecatalog/somerepository>. The following options are understood:

=over

=item C<MODE> (default: C<O_RDONLY>)

This POSIX file mode determines how the model will be opened.

=back

If the model does already exist, then an L<RDF::AllegroGraph::Repository> object will be
returned. If the specified catalog does not exist, then a C<no catalog> exception will be raised.
Otherwise, if the repository there does not exist and the C<MODE> option is C<O_CREAT>, then it will
be generated. Otherwise an exception C<cannot open repository> will be raised.

=cut

sub model {
    my $self = shift;
    my $id   = shift;
    my %options = @_;

    my ($catid, $repoid) = ($id =~ q|(/.+?)(/.+)|) or die "id must be of the form /something/else";

    my %catalogs = $self->catalogs;
    die "no catalog '$catid'" unless $catalogs{$catid};

    return $catalogs{$catid}->repository ($id, $options{mode});
}

=back

=head1 AUTHOR

Robert Barta, C<< <rho at devc.at> >>

=head1 COPYRIGHT & LICENSE

Copyright 200[9] Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

L<RDF::AllegroGraph>

=cut

1;

__END__

#sub protocol {
#    my $self = shift;
#    my $resp = $self->{ua}->get ($self->{ADDRESS} . '/protocol');
#    die "protocol error: ".$resp->status_line unless $resp->is_success;
#    return $resp->content;
#}

