package OSF::CommonCrawl::WarcSet;

use warnings;
use strict;

use OSF::WARC::Supply ();
use OSF::CommonCrawl::Product   ();

use File::Glob  qw(bsd_glob);

sub new(%) { my $class = shift; (bless {}, $class)->init( {@_} ) }

sub init($$)
{   my ($self, $args) = @_;
    my $dir = $args->{dir} or die "No dir";

    my $crawl_fn = (bsd_glob "$dir/*-CRAWL.warc.gz")[0] or die "No Crawl";
    $self->{OC_crawl} = OSF::WARC::Supply->new(filename => $crawl_fn);
#use Data::Dumper;
# warn Dumper $crawl->info;

    my $wat_fn   = (bsd_glob "$dir/*-WAT.warc.gz")[0] or die "No WAT";
    $self->{OC_wat} = OSF::WARC::Supply->new(filename => $wat_fn);

    my $wet_fn   = (bsd_glob "$dir/*-WET.warc.gz")[0] or die "No WET";
    $self->{OC_wet} = OSF::WARC::Supply->new(filename => $wet_fn);
    $self;
}

sub getProduct()
{   my $self = shift;

    # In CommonCrawl products, the CRAWL file always have matching
    # request, response and metadata records.  In other WARC files,
    # that's not required.

    my $request = $self->{OC_crawl}->getRecord or return;
    my $set_id  = $request->setId;

    my $response = $self->{OC_crawl}->getRecord;
    $response->setId eq $set_id
        or die;

    my $metadata = $self->{OC_crawl}->getRecord;
    $response->setId eq $set_id
        or die;

    OSF::CommonCrawl::Product->new(
        name  => $request->uri,
        parts => {
            request => $request,
            response => $response,
            metadata => $metadata,
            text     => $self->{OC_wet}->getRecord($set_id),
        },
    );
}

1;
