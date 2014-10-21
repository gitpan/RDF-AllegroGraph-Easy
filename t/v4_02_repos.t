use Test::More 'no_plan';
use Test::Exception;

use Data::Dumper;

use constant DONE => 1;

my $AG_SERVER = $ENV{AG4_SERVER};
unless ($AG_SERVER) {
    ok (1, 'Tests skipped. Use "export AG4_SERVER=http://my.server:port" before running the test suite. See README for details.');
    exit;
}

if (DONE) {
    use RDF::AllegroGraph::Server;
    my $server = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
    # TODO: generate scratch here
    use RDF::AllegroGraph::Catalog4;
    my $scratch = new RDF::AllegroGraph::Catalog4 (NAME => '/scratch', SERVER => $server);

    use Fcntl;
    my $model  = $scratch->repository ('/scratch/catlitter', O_CREAT);

    is ($model->size, 0, 'empty model');
    $model->add ();
    is ($model->size, 0, 'still empty model');

    $model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:rho>']);
    is ($model->size, 1, 'added: model of 1');

    $model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:rho>']);
    is ($model->size, 2, 'added: model of 2');
    
    $model->replace (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>']);
    is ($model->size, 1, 'replaced: model of 1');

    $model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:katty>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:ketty>'],
	);
    is ($model->size, 4, 'replaced/added: model of 4');

    $model->delete (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>']);
    is ($model->size, 3, 'deleted (fact): model of 3');

    $model->delete ([undef, '<urn:x-me:hates>', undef]);
    is ($model->size, 1, 'deleted (wildcard): model of 1');

    $model->delete (['<urn:x-me:rumsti>', undef, undef]);
    is ($model->size, 1, 'deleted (wildcard): model of 1');

    $model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:katty>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
	);
    $model->delete ([undef, '<urn:x-me:loves>', undef ],
		    [undef, undef, '<urn:x-me:kitty>' ]	);
    is ($model->size, 1, 'deleted (wildcard): model of 1');

    $model->replace (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:katty>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
	);
    $model->delete ([undef, '<urn:x-me:loves>', undef ],
                    ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>' ] );
    is ($model->size, 2, 'deleted (wildcard): model of 2');

    $model->disband;
}

if (DONE) { # blank nodes
    my $server  = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
    my $scratch = new RDF::AllegroGraph::Catalog4 (NAME => '/scratch', SERVER => $server);
    my $model   = $scratch->repository ('/scratch/catlitter', O_CREAT);

    $model->replace (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:katty>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
	             );
    my @bs = $model->blanks (10);
    is ((scalar @bs), 10, 'enough blanks');
    map { like ($_, qr/^_:.+/, 'blanks look good') } @bs;
    $model->disband;
}

if (DONE) {
    my $server  = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
    my $scratch = new RDF::AllegroGraph::Catalog4 (NAME => '/scratch', SERVER => $server);
    my $model   = $scratch->repository ('/scratch/catlitter', O_CREAT);

    $model->replace (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:katty>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
	             );

    my @ss = $model->match ([undef, undef, '<urn:x-me:kitty>']);
    is (scalar @ss, 2, 'match found kitty');
    map { is ($_->[2], '<urn:x-me:kitty>', 'kitty!') } @ss;

    @ss = $model->match (['<urn:x-me:sacklpicker>', undef, undef]);
    is (scalar @ss, 4, 'match found sacklpicker');
    map { is ($_->[0], '<urn:x-me:sacklpicker>', 'sacklpicker!') } @ss;

    @ss = $model->match (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>']);
    is (scalar @ss, 2, 'match found exactly two identical');

    @ss = $model->match ([undef, '<urn:x-me:hates>', undef],
			 [undef, '<urn:x-me:loves>', undef]);
    is (scalar @ss, 4, 'match found love and hate');

    @ss = $model->match ({ limit => 2 },
			 [undef, '<urn:x-me:hates>', undef],
			 [undef, '<urn:x-me:loves>', undef]);
    is (scalar @ss, 3, 'match found love and hate (4->2)');

    $model->disband;
}

if (DONE) {
    my $server  = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
    my $scratch = new RDF::AllegroGraph::Catalog4 (NAME => '/scratch', SERVER => $server);
    my $model   = $server->model ('/scratch/catlitter', mode => O_CREAT);

    $model->add ('<urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:tomcat> .');
    is (scalar $model->match (['<urn:x-me:sacklpicker>', undef, undef]), 1, 'added N3: 1');

    $model->add ('<urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:kitty> .
                  <urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:katty> .');
    is (scalar $model->match (['<urn:x-me:sacklpicker>', undef, undef]), 3, 'added N3: 3');

    $model->replace ('<urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:ketty> .
                      <urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:kotty> .');
    is (scalar $model->match (['<urn:x-me:sacklpicker>', undef, undef]), 2, 'replaced N3: 2');

    $model->disband;
}

my $file;
END { $AG_SERVER && unlink $file; }

if (DONE) {
    use POSIX qw(tmpnam);
    use IO::File;
    do { $file = tmpnam().".n3";  } until IO::File->new ($file, O_RDWR|O_CREAT|O_EXCL);
    my $fh = IO::File->new ("> $file") || die "so what?";
    print $fh "
<urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:ketty> .
<urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:kotty> .
";
    $fh->close;

    my $server  = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
    my $scratch = new RDF::AllegroGraph::Catalog4 (NAME => '/scratch', SERVER => $server);
    my $model   = $server->model ('/scratch/catlitter', mode => O_CREAT);

    $model->add ('file://'. $file);
    is (scalar $model->match (['<urn:x-me:sacklpicker>', undef, undef]), 2, 'added N3 file: 2');

    $model->replace (('file://'. $file ) x 3);
    is (scalar $model->match (['<urn:x-me:sacklpicker>', undef, undef]), 2*3, 'added N3 file: 2*3');

    $model->disband;
}


if (DONE) { # sparql and prolog queries
    my $server  = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
    my $scratch = new RDF::AllegroGraph::Catalog4 (NAME => '/scratch', SERVER => $server);
    my $model   = $server->model ('/scratch/catlitter', mode => O_CREAT);

    $model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:katty>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
	);

    my @ss = $model->sparql ('SELECT ?s ?p ?o WHERE {?s ?p ?o .}' );
#    warn Dumper \@ss;
    is (scalar @ss, 4, 'query: all triples');
    map { is ($_->[0], '<urn:x-me:sacklpicker>', 'sackelpicker everywhere') } @ss;
    map { is (scalar @$_, 3,                     'triple everywhere')       } @ss;

    @ss = $model->sparql ('SELECT ?thing WHERE { ?cat <urn:x-me:hates> ?thing . }' );
    is (scalar @ss, 2, 'query: all that hate (SPARQL)');
    map {  like ($_->[0], qr/<urn:x-me:(kitty|tomcat)>/, 'tomcat/kitty everywhere') } @ss;
    map { is (scalar @$_, 1,                 'singleton everywhere')        } @ss;

    @ss = $model->prolog (q{
 (select (?thing)
            (q ?cat !<urn:x-me:hates> ?thing)
  )
});
    is (scalar @ss, 3, 'query: all that hate (Prolog), delivers duplicate');
    map {  like ($_->[0], qr/<urn:x-me:(kitty|tomcat)>/, 'tomcat/kitty everywhere') } @ss;
    map { is (scalar @$_, 1,                 'singleton everywhere')        } @ss;
#    warn Dumper \@ss;

    $model->disband;
}

if (DONE) {
    my $server  = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
    my $scratch = new RDF::AllegroGraph::Catalog4 (NAME => '/scratch', SERVER => $server);
    my $model   = $scratch->repository ('/scratch/catlitter', O_CREAT);

    $model->replace (['<urn:x-me:sacklpicker>', '<urn:x-me:nrlegs>', '"6"^^<http://www.w3.org/2001/XMLSchema#long>'],
		     ['<urn:x-me:tomcat>',      '<urn:x-me:nrlegs>', '"2"^^<http://www.w3.org/2001/XMLSchema#long>'],
		     ['<urn:x-me:kitty>',       '<urn:x-me:nrlegs>', '"3"^^<http://www.w3.org/2001/XMLSchema#long>'],
		     ['<urn:x-me:fluffy>',      '<urn:x-me:nrlegs>', '"4"^^<http://www.w3.org/2001/XMLSchema#long>'],
	             );

    my @ss = $model->match ([undef, undef, '"3"^^<http://www.w3.org/2001/XMLSchema#long>']);
    is ((scalar @ss), 1, 'match with singular literal');

    @ss = $model->match ([undef, undef, [ '"3"^^<http://www.w3.org/2001/XMLSchema#long>', '"5"^^<http://www.w3.org/2001/XMLSchema#long>']]);
    is ((scalar @ss), 2, 'match with range literal');
    
    ok (eq_array ([ 3, 4 ],
		  [ sort
		    map { $_ =~ /"(\d+)"/ && $1 } 
		    map { $_->[2] }
		    @ss
		    ]), 'correct range values');

#    warn Dumper \@ss;

    $model->disband;
}

if (DONE) { # indices
    my $server = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
    my $scratch = new RDF::AllegroGraph::Catalog4 (NAME => '/scratch', SERVER => $server);
    use Fcntl;
    my $model  = $scratch->repository ('/scratch/catlitter', O_CREAT);

    my @vidxs = $model->valid_indices;
    ok ((grep { $_ eq 'spogi' } @vidxs), 'valid indices listed');

    my @idxs = $model->indices;
    ok (eq_set ([
		 'i',
		 'gospi',
		 'gposi',
		 'gspoi',
		 'ospgi',
		 'posgi',
		 'spogi'
		 ], \@idxs), 'default indices in the store');

    @idxs = $model->indices ('-gospi', '-gposi');
    ok (eq_set ([
		 'i',
		 'gspoi',
		 'ospgi',
		 'posgi',
		 'spogi'
		 ], \@idxs), 'after removal: indices in the store');

    ok (eq_set ([ 'spogi' ],
		[ $model->indices (map  { "-$_" }
                                   grep { $_ ne 'spogi' } @idxs) ]), 'removed all indices except one');

    throws_ok {
	$model->indices ('-spogi');
    } qr/at least one/, 'cannot remove last index';

    foreach my $idx (@vidxs) { # gradually adding all indices
	ok ((	grep { $_ eq $idx }
		$model->indices ("+$idx") ), "$idx has been added");
    }

    @idxs = $model->indices;
    ok (eq_set (\@vidxs, \@idxs), 'after adding all indices: all valid ones');

    $model->disband;
}

if (DONE) { # bulk, commit and duplicate modes
    my $server  = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
    my $scratch = new RDF::AllegroGraph::Catalog4 (NAME => '/scratch', SERVER => $server);
    my $model   = $scratch->repository ('/scratch/catlitter', O_CREAT);

    ok (!$model->bulk_loading_mode, 'bulk loading disabled by default');

    ok ( $model->bulk_loading_mode (1), 'switched on');
    ok ( $model->bulk_loading_mode,     'still switched on');

    ok (!$model->bulk_loading_mode (0), 'switched off');
    ok (!$model->bulk_loading_mode,     'still switched off');

    ok ( $model->bulk_loading_mode (1), 'switched on again');

    ok ( $model->commit_mode, 'commit enabled by default');
    ok (!$model->commit_mode (0), 'switched off');
    ok (!$model->commit_mode,     'still switched off');
    ok ( $model->commit_mode (1), 'switched on');
    ok ( $model->commit_mode,     'still switched on');

    ok ( $model->duplicate_suppression_mode, 'duplicate suppression enabled by default');
    ok (!$model->duplicate_suppression_mode (0), 'switched off');
    ok (!$model->duplicate_suppression_mode,     'still switched off');
    ok ( $model->duplicate_suppression_mode (1), 'switched on');
    ok ( $model->duplicate_suppression_mode,     'still switched on');

    $model->disband;
}

__END__

