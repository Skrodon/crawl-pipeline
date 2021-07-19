use strict;
use warnings;
use Test::More;
use File::Basename;

eval { require Test::Perl::Critic; };
### use_ok 'Test::Perl::Critic';

if($@) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan(skip_all => $msg);
}

my $rcfile = dirname(__FILE__) . '/../.perlcriticrc';
### my $rcfile = dirname(dirname(__FILE__)) . '.perlcriticrc';
### my $rcfile = '../../.perlcriticrc';

Test::Perl::Critic->import(-profile => $rcfile, -verbose => 10);
all_critic_ok();
