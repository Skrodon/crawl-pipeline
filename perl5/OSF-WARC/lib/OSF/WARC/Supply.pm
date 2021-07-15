
package OSF::WARC::Supply;

use warnings;
use strict;

use Log::Report  'osf-warc';

use OSF::WARC::Conversion ();
use OSF::WARC::Metadata   ();
use OSF::WARC::Request    ();
use OSF::WARC::Response   ();
use OSF::WARC::Revisit    ();
use OSF::WARC::WarcInfo   ();

use IO::Uncompress::Gunzip qw($GunzipError);

my %warc_type_class = (
    conversion => 'OSF::WARC::Conversion',
    metadata   => 'OSF::WARC::Metadata',
    request    => 'OSF::WARC::Request',
    response   => 'OSF::WARC::Response',
    revisit    => 'OSF::WARC::Revisit',
    warcinfo   => 'OSF::WARC::WarcInfo',
);

sub new(%) { my $class = shift; (bless {}, $class)->_init({@_}) }

sub _init($)
{   my ($self, $args) = @_;

    my $fn = $self->{OWS_fn} = $args->{filename}
        or die "ERROR: No warc filename supplied\n";

    ### Set-up uncompressing the data

    $fn =~ /\.gz/
        or die "ERROR: Expected file as gzip-compressed, $fn\n";

    $self->{OWS_unzip} = IO::Uncompress::Gunzip->new($fn, MultiStream => 1)
        or error "Cannot open warc-file '$fn' for read: $!\n";

    $self->{OWS_recs} = 0;
    $self->{OWS_info} = $self->readInfo;
    $self;
}

sub filename   { $_[0]->{OWS_fn} }
sub fh         { $_[0]->{OWS_fh} }
sub unzip      { $_[0]->{OWS_unzip} }
sub warcinfo   { $_[0]->{OWS_info} }
sub nr_records { $_[0]->{OWS_recs} }

sub getRecord(;$)
{   my ($self, $set_id) = @_;
    my $unzip   = $self->unzip;

    if(my $next = $self->{OWS_next})
    {   return delete $self->{OWS_next}
            if ! $set_id || $next->basedOn eq $set_id;

        return undef if $set_id;
    }

    my $version = $unzip->getline;
    $version = $unzip->getline
        while ! $unzip->eof && $version eq "\r\n";

    return undef if $unzip->eof;

    $version =~ m!^WARC/1\.!
         or die "ERROR: version '$version' not supported.\n";

    my (%head, $body);
    my ($key, $val);
    my $line = $unzip->getline;
    while(! $unzip->eof && $line !~ m/^\r?$/)
    {   ($key, $val) = split /\: /, $line, 2;
        $head{$key} = $val =~ s/\r?\n$//r;
        $line = $unzip->getline;
    }

    my $len = $head{'Content-Length'}
        or die "ERROR: record does not have a Content-Length\n";

    $unzip->read($body, $len) == $len
        or die "ERROR: file is too short\n";;

    my $type = $head{'WARC-Type'} || 'unknown';
    my $class = $warc_type_class{$type}
        or die "ERROR: unknown warc type $type";

    $self->{OWS_recs}++;

    my $record = $class->new
      ( head => \%head,
        body => \$body,    # scalar by reference to avoid copies

        # The gzip is a MultiStream, where each record is compressed
        # separately, so we should be able to do this.  However, the
        # tell() returns the uncompressed location: we need to be able
        # to find the start byte of the zip stream.
#       compressed => [ $self->fh, $start, $unzip->tell - $start ],
      );

    if($set_id && $record->basedOn ne $set_id)
    {   $self->{OWS_next} = $record;
        return undef;
    }

    $record;
}

sub readInfo()
{   my $self = shift;

    my $info = $self->{OWS_head} = $self->getRecord;

    $info->header('WARC-Type') eq 'warcinfo'
        or die "ERROR: file does not start with a warcinfo record.\n";

    $info;
}

1;
