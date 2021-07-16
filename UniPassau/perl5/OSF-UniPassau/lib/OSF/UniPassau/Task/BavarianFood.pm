package OSF::UniPassau::Task::BavarianFood;
use parent 'OSF::Pipeline::Task';

use warnings;
use strict;
use utf8;

use charnames ':full', ':alias' => {
   a_CIRCUM   => 'LATIN SMALL LETTER A WITH CIRCUMFLEX',
   o_CIRCUM   => 'LATIN SMALL LETTER O WITH CIRCUMFLEX',
   u_CIRCUM   => 'LATIN SMALL LETTER U WITH CIRCUMFLEX',
   CIRCUMFLEX => 'COMBINING CIRCUMFLEX ACCENT',
};

use HTTP::Status       qw(is_success);
use File::Path         qw(mkpath);

my $collect       = $ENV{UP_COLLECT}
    or die "Environment variable UP_COLLECT missing";

my $publish       = $ENV{UP_PUBLISH}
    or die "Environment variable UP_PUBLISH missing";

my @content_types = qw(text/html text/xhtml);
my @domain_names  = qw(bayern);

my @simple_city_names = qw/
  Amberg
  Ansbach
  Aschaffenburg
  Augsburg
  Bamberg
  Bayern
  Bayreuth
  Coburg
  Dachau
  Deggendorf
  Erding
  Erlangen
  Forchheim
  Freising
  Germering
  Ingolstadt
  Kaufbeuren
  Kempten
  Kitzingen
  Kulmbach
  Landshut
  Lindau
  Marktredwitz
  Memmingen
  Passau
  Regensburg
  Rosenheim
  Schwabach
  Schweinfurt
  Straubing
 /;
# City 'Hof' will produce too many false positives

my $_a_uml  = '(?:ae|a\N{CIRCUMFLEX}|\N{a_CIRCUM})';
my $_o_uml  = '(?:oe|o\N{CIRCUMFLEX}|\N{o_CIRCUM})';
my $_u_uml  = '(?:ue|u\N{CIRCUMFLEX}|\N{u_CIRCUM})';

my $_in_der = '(?i:\s+in\s+der\s+|\s+i\.?\s*d\.?\s*|\s*i\s*/\s*d\s+|\s*/\s*)';
my $_an_der = '(?i:\s+an\s+der\s+|\s+a\.?\s*d\.?\s*|\s*a\s*/\s*d\s+|\s*/\s*)';
my $_am     = '(?i:\s+am?\s+|\s*/\s*)';

my %composed_city_names =
  ( 'Bad Kissingen'           => qr/\bBad\s+Kissingen\b/,
  , 'Bad Reichenhall'         => qr/\bBad\s+Reichenhall\b/,
  , 'Dillingen an der Donau'  => qr/\bDillingen${_an_der}Donau\b/,
  , 'Dinkelsbühl'             => qr/\bDinkelsb${_u_uml}hl\b/,
  , 'Donauwörth'              => qr/\bDonauw${_o_uml}rth\b/,
  , 'Eichstätt'               => qr/\bEichst${_a_uml}tt\b/,
  , 'Fürstenfeldbruck'        => qr/\bF${_u_uml}rstenfeldbruck\b/,
  , 'Fürth'                   => qr/\bF${_u_uml}rth\b/,
  , 'Günzburg'                => qr/\nG${_u_uml}nzburg\b/,
  , 'Landsberg am Lech'       => qr/\bLandsberg${_am}Lech\b/,
  , 'München'                 => qr/\bM${_u_uml}nchen\b/,
  , 'Neuburg an der Donau'    => qr/\bNeuburg${_an_der}Donau\b/,
  , 'Nürnberg'                => qr/\bN${_u_uml}rnberg\b/,
  , 'Weiden in der Oberpfalz' => qr/\bWeiden${_in_der}Oberpfalz\b/,
  , 'Würzburg'                => qr/\bW${_u_uml}rzburg\b/,
  );

# Not used yet
my @simple_food = qw/
   dessert
   hauptgerichte
   restaurant
   rezepte
   salate
   speisekarte
   suppen
   vorspeisen
   /;

# not used yet
my %composed_food =
  ( 'getränke' => qr/\bgetr${_a_uml}nke\b/,
  , 'menü'     => qr/\bmen${_u_uml}\b/,
  );

sub _init($)
{   my ($self, $args) = @_;
    mkpath $_ for $collect, $publish;

    $self->{OKT_save} = OSF::Package::WARCs->new(tmp => $collect, publish => $publish);
    $self->SUPER::init($args);
}

sub createFilter()
{   my $self  = shift;
    my $size  = $self->filterRequiresText(minimum_words => 300);
    my $ct    = $self->filterContentType(\@content_types);
    my $rid   = $self->filterDomain(\@domain_names);
    my $lang  = $self->filterLanguage('DEU');
    my $cities1 = $self->filterFullWords(\@simple_city_names);
    my $cities2 = $self->filterRegexps(\%composed_city_names);

    sub {
        my $product = shift;

           is_success($product->responseStatus)
        && $product->origin eq 'CommonCrawl'
        && $ct->($product)
        && $lang->($product)
        && $size->($product)
            or return undef;

        my @hits =
          ( $cities1->($product)
          , $cities2->($product)
          , $rid->($product)
          );

        @hits ? \@hits : undef;
    };
}

sub save($$)
{   my ($self, $product, $hits) = @_;
warn "SAVE ", $product->name;
    my %facts =
      ( origin => $product->origin
      , hits   => $hits
      );

    my $save = $self->{OKT_save};
    $save->addWARCRecord($product->part('response'));
    $save->addWARCRecord($product->part('text'));
    $save->addWARCRecord($product->part('metadata'), \%facts);
    $save->possibleBreakpoint;
}

sub batchFinished
{   my $self = shift;
    $self->{OKT_save}->batchFinished;
    $self->SUPER::batchFinished;
}

1;
