
package OSF::WARC::Supply;

use OSF::WARC::Request  ();
use OSF::WARC::Response ();
use OSF::WARC::Metadata ();
use OSF::WARC::WarcInfo ();
use OSF::WARC::Conversion ();

use IO::Uncompress::Gunzip qw($GunzipError);

my %warc_type_class = (
    request    => 'OSF::WARC::Request',
    response   => 'OSF::WARC::Response',
    metadata   => 'OSF::WARC::Metadata',
    warcinfo   => 'OSF::WARC::WarcInfo',
    conversion => 'OSF::WARC::Conversion',
);

sub new(%)
{   my $class = shift;
    (bless {}, $class)->init({@_});
}

sub init($)
{   my ($self, $args) = @_;

    my $fn = $self->{OWS_fn} = $args->{filename}
        or die "ERROR: No warc filename supplied\n";

    $fn =~ /\.gz/
        or die "ERROR: Expected file as gzip-compressed, $fn\n";

    my $fh = IO::Uncompress::Gunzip->new($fn, MultiStream => 1)
        or die "ERROR: Cannot open warc-file '$fn' for read: $!\n";

    $self->{OWS_fh}   = $fh;
    $self->{OWS_recs} = 0;
    $self->{OWS_info} = $self->readInfo;
    $self;
}

sub filename   { $_[0]->{OWS_fn} }
sub fh         { $_[0]->{OWS_fh} }
sub info       { $_[0]->{OWS_info} }
sub nr_records { $_[0]->{OWS_recs} }

sub getRecord(;$)
{   my ($self, $uri) = @_;
    my $fh   = $self->fh;

    if(my $next = $self->{OWS_next})
    {   return delete $self->{OWS_next}
            if ! $uri || $next->uri eq $uri;
    }

    my $version = $fh->getline;
    $version = $fh->getline
        while ! $fh->eof && $version eq "\r\n";

    return undef if $fh->eof;

    $version =~ m!^WARC/1\.!
         or die "ERROR: version '$version' not supported.\n";

    my (%head, $body);
    my ($key, $val);
    my $line = $fh->getline;
    while(! $fh->eof && $line !~ m/^\r?$/)
    {   ($key, $val) = split /\: /, $line, 2;
        $head{lc $key} = $val =~ s/\r?\n$//r;
        $line = $fh->getline;
    }

    my $len = $head{'content-length'}
        or die "ERROR: record does not have a content length\n";

    $fh->read($body, $len) == $len
        or die "ERROR: file is too short\n";;

    my $type = $head{'warc-type'} || 'unknown';
    my $class = $warc_type_class{$type}
        or die "ERROR: unknown warc type $type";

    $self->{OWS_recs}++;
    my $record = $class->new(\%head, \$body);

    if($uri && $record->uri ne $uri)
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
