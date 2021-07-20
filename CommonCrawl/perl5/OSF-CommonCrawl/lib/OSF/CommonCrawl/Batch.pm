package OSF::CommonCrawl::Batch;
use parent 'OSF::Pipeline::Batch';

use warnings;
use strict;

use Log::Report 'osf-commoncrawl';

use OSF::WARC::Supply         ();
use OSF::WARC::Request        ();
use OSF::WARC::Response       ();
use OSF::WARC::Metadata       ();
use OSF::WARC::Conversion     ();
use OSF::CommonCrawl::Product ();

use File::Glob  qw(bsd_glob);

sub _init($$)
{   my ($self, $args) = @_;

    my $dir = $args->{source} or die "No source dir";

    my $crawl_fn = (bsd_glob "$dir/*-CRAWL.warc.gz")[0]
        or error "No CRAWL.warc.gz in $dir";

    $args->{name} ||= $crawl_fn =~ m!/([^/]+)-CRAWL\.warc\.gz$! ? $1 : $dir;

    $self->SUPER::_init($args);

    $self->{OCW_crawl} = OSF::WARC::Supply->new(filename => $crawl_fn);

#use Data::Dumper;
# warn Dumper $crawl->info;

    my $wat_fn   = (bsd_glob "$dir/*-WAT.warc.gz")[0]
        or error "No WAT.warc.gz in $dir";

    $self->{OCW_wat} = OSF::WARC::Supply->new(filename => $wat_fn);

    my $wet_fn   = (bsd_glob "$dir/*-WET.warc.gz")[0]
        or error "No WET.warc.gz in $dir";

    $self->{OCW_wet} = OSF::WARC::Supply->new(filename => $wet_fn);
    $self;
}

sub getProduct()
{   my $self = shift;

    # In CommonCrawl products, the CRAWL file always have matching
    # request, response and metadata records.  In other WARC files,
    # that's not required.

    my $request = OSF::WARC::Request->getRecord($self->{OCW_crawl}) or return;
    my $set_id  = $request->recordId;

    my $response = OSF::WARC::Response->getRecord($self->{OCW_crawl}) or return;
    $response->basedOn eq $set_id or panic;

    my $metadata = OSF::WARC::Metadata->getRecord($self->{OCW_crawl}) or return;
    $response->basedOn eq $set_id or panic;

    my $text     = OSF::WARC::Conversion->getRecord($self->{OCW_wet},
        $response->recordId);

    OSF::CommonCrawl::Product->new(
        name  => $request->uri,
        parts => {
            request => $request,
            response => $response,
            metadata => $metadata,
            text     => $text,
        },
    );
}

1;
