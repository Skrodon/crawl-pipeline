use ExtUtils::MakeMaker;

require 5.020;

my $VERSION = '0.010';

my %prereq =
 ( Log::Report        => 0
 , Test::More         => 0
 , File::Copy         => 0
 , File::Path         => 0
 , POSIX              => 0
 , IO::Compress::Gzip => 0
 );

WriteMakefile
 ( NAME       => 'OSF::Pachakge'
 , VERSION    => $VERSION
 , AUTHOR     => 'Mark Overmeer'
 , ABSTRACT   => 'Various packaging methods'
 , PREREQ_PM  => \%prereq
 , LICENSE    => 'perl_5'
 , META_MERGE =>
    { 'meta-spec' => { version => 2 }
    }
 );
