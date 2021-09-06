# This code is part of distribution HTML::Inspect.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

package HTML::Inspect;

use 5.020000;
use strict;
use warnings;
use utf8;

use ExtUtils::MakeMaker 7.24;

my $module_file = 'lib/' . (__PACKAGE__ =~ s|::|/|gr) . '.pm';

# TODO: Mark should say what will be the public repo.
my $git_url = 'https://github.com/kberov/' . (__PACKAGE__ =~ s|::|-|gr);


WriteMakefile(
    NAME             => __PACKAGE__,
    VERSION_FROM     => $module_file,
    AUTHOR           => 'Красимир Беров <berov@cpan.org>',
    PREREQ_PM        => {
        'Log::Report'  => 1.32,
        'Net::LibIDN2' => 1.01,
        'URI'          => 5.09,
        'URI::Fast'    => 0.54,
        'XML::LibXML'  => 2.0207,
    },
    test             => {TESTS         => 't/*.t'},
    clean            => {FILES         => '*.bak HTML-Inspect-*'},
    MIN_PERL_VERSION => '5.020000',
    META_MERGE       => {
        dynamic_config => 0,
        'meta-spec'    => {version   => 2},
        no_index       => {directory => [ 't', 'xt', ]},
        prereqs        => {runtime   => {requires => {perl => '5.020000'}}},
        resources      => {
            bugtracker => {web => "$git_url/issues"},
            homepage   => $git_url,
            license    => ['http://www.opensource.org/licenses/artistic-license-2.0'],
            repository => {type => 'git', url => "$git_url.git", web => $git_url,},
        },
    },
);

sub MY::postamble {
    my $preop          = qq 'podselect $module_file > README.pod;';
    my @perltidy_files = qw(Makefile.PL);
    my $options        = {
        no_chdir => 1,
        wanted   => sub {
            push @perltidy_files, $_ if $_ =~ /\.(PL|pm|pl|t)$/;
        }
    };
    File::Find::find($options, 'lib', 't', 'xt');
    my $perltidy_files = join '\\' . $/ . "\t ", @perltidy_files;
    return <<"TARGETS";
readme ::
\t$preop
dist : readme

perltidy ::
\tperltidy -pro=.perltidyrc \\
\t$perltidy_files

TARGETS
}
