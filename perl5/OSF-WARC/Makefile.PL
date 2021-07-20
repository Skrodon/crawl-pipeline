use ExtUtils::MakeMaker;

require 5.020;

my $VERSION = '0.010';

my %prereq =
 ( Log::Report     => 0
 , Test::More      => 0.47
 );

WriteMakefile
 ( NAME       => 'OSF::WARC'
 , VERSION    => $VERSION
 , AUTHOR     => 'Mark Overmeer'
 , ABSTRACT   => 'Processing WARC data'
 , PREREQ_PM  => \%prereq
 , LICENSE    => 'perl_5'
 , META_MERGE =>
    { 'meta-spec' => { version => 2 }
    }
 );
