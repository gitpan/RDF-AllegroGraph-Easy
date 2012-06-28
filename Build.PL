use v5.8;
use strict;
use warnings;
use Module::Build;

use Module::Build;
my $class = Module::Build->subclass(
    class => "Module::Build::Custom",
    code => <<'SUBCLASS' );

sub ACTION_upload {
    my $self = shift;
    my $v = $self->dist_version();
    $self->do_system(('cpan-upload', "RDF-AllegroGraph-Easy-$v.tar.gz"));
}
SUBCLASS

$class->new(
    module_name         => 'RDF::AllegroGraph::Easy',
    license             => 'perl',
    dist_author         => 'Robert Barta <rho@devc.at>',
    dist_version_from   => 'lib/RDF/AllegroGraph/Easy.pm',
    build_requires => {
	'DateTime'            => 0,
	'JSON'                => 0,
	'JSON::XS'            => 0,
	'LWP'                 => 0,
	'Regexp::Common'      => 0,
	'Test::Exception'     => 0,
        'Test::More'          => 0,
	'Test::Pod::Coverage' => 0,
	'Time::HiRes'         => 0,
	'URI::Escape'         => 0,
    },
	    configure_requires => {
		'Module::Build'       => 0.40,
	    },
    add_to_cleanup      => [ 'RDF-AllegroGraph-Easy-*' ],
    create_makefile_pl => 'traditional',
)->create_build_script();



__END__

