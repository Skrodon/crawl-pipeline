package OSF::CommonCrawl::Product;

use warnings;
use strict;

use JSON   qw(decode_json);
use URI    ();

sub new(%) { my $class = shift; (bless {}, $class)->init( {@_} ) }

sub init($)
{   my ($self, $args) = @_;
    $self->{OCP_parts} = $args->{parts} || {};
    $self;
}

sub origin
{   my $self = shift;
     +{ crawler => 'CommonCrawl',
      , source  => $self->id,
      };
}

sub part($) { $_[0]->{OCP_parts}{$_[1]} }

sub id()   { $_[0]->{OCP_id} ||= $_[0]->part('request')->setId }
sub name() { $_[0]->{OCP_name} ||= $_[0]->uri->as_string }

sub uri()
{   my $self = shift;
    $self->{OCP_uri} ||= URI->new($self->part('request')->uri)->canonical;
}

sub cld2()
{   my $self = shift;
    return $self->{OCP_cld2} if defined $self->{OCP_cld2};

    my $meta = $self->part('metadata') or return;
    my $cld2 = $meta->value('languages-cld2') or return;
    $self->{OCP_cld2} = decode_json $cld2;
}

sub contentType()
{   my $self = shift;
    return $self->{OCP_ct} if $self->{OCP_ct};

    my $ct;
    if(my $response = $self->part('response'))
    {   $ct = $response->header('WARC-Identified-Payload-Type')
           || $response->contentType;
    }
    else
    {   # We could try to use MIME::Type->mimeTypeOf($uri) to
        # autodetect the type, but that's what server software
        # usually already does for us.
    }

    $self->{OCP_ct} = $ct || 'application/octet-stream';
}

1;
