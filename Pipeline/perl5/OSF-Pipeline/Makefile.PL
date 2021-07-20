use ExtUtils::MakeMaker;

require 5.020;

my $VERSION = '0.010';

my %prereq =
 ( Log::Report     => 0
 , List::MoreUtils => 0
 , Test::More      => 0.47
 );

WriteMakefile
 ( NAME       => 'OSF::Pipeline'
 , VERSION    => $VERSION
 , AUTHOR     => 'Mark Overmeer'
 , ABSTRACT   => 'Filtering crawler results'
 , PREREQ_PM  => \%prereq
 , LICENSE    => 'perl_5'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
#     , resources  =>
#         {
#           repository =>
#             { type => 'git'
#             , url  => 'https://github.com/markov2/perl5-Mail-Box.git'
#             , web  => 'https://github.com/markov2/perl5-Mail-Box'
#             }
#         , homepage => 'http://perl.overmeer.net/CPAN/'
#         , license  => [ 'http://dev.perl.org/licenses/' ]
#         }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/osf-pipeline/raw
DISTDIR         = ../public_html/osf-pipeline/source
EXTENDS         = 

# for POD
FIRST_YEAR      = 2021
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/

# for HTML
HTML_OUTPUT     = ../public_html/osf-pipeline/html
HTML_DOCROOT    = /osf/html
HTML_PACKAGE    = ../public_html/osf-pipeline/htmlpkg

__POSTAMBLE
