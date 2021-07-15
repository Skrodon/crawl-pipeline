package OSF::Package::WARCs;
use parent 'OSF::Package';

use warnings;
use strict;

use Log::Report 'osf-package';

use OSF::WARC::Sink    ();

use File::Copy         qw(move);
use File::Path         qw(make_path);
use POSIX              qw(strftime);
use IO::Compress::Gzip qw($GzipError);

sub _init($)
{   my ($self, $args) = @_;
    $self->SUPER::_init($args);

    # We need to create the files on an internal location first,
    # because we do not know when external parties are scanning
    # for files.

    my $tmp = $self->{OPW_tmp} = $args->{tmp}
        or panic "tmp directory required";

    my $dir = $self->{OPW_publish} = $args->{publish}
        or panic "publish directory required";

    make_path $_ for $dir, $tmp;
    $self;
}

sub tmp()         { $_[0]->{OPW_tmp} }
sub publish()     { $_[0]->{OPW_publish} }

sub currentWARC() { $_[0]->{OPW_warc} }

sub createWARC()
{   my $self   = shift;

    my $unique = strftime "%Y%m%d-%H%M%S-$$", gmtime;
    my $fn     = $self->tmp . "/$unique.warc.gz-part";
    $self->{OPW_warc} = OSF::WARC::Sink->new(filename => $fn);
}

sub acceptWARC()
{   my $self   = shift;
    my $warc   = delete $self->{OPW_warc} or return;
    my $unique = $warc->filename =~ m!.*/(.*?)-part$! ? $1 : panic $warc->filename;

    # Create index file
    my $tmpindex = $self->tmp . "/$unique.index.json.gz";
    my $gzip = IO::Compress::Gzip->new($tmpindex)
        or fault __x"Cannot create gzip of WARC index in file {fn}", fn => $tmpindex, _code => $GzipError;

    # Publish the WARC file
    my $warc_fn = $self->publish . "/$unique.warc.gz";
    move $warc->filename, $warc_fn
       or fault __x"Cannot publish WARC from {from} to {to}", from => $warc->filename, to => $warc_fn;

    # Publish the index file
    my $index_fn = $self->publish . "/$unique.index.json.gz";
    move $tmpindex, $index_fn
       or fault __x"Cannot publish WARC index from {from} to {to}", from => $tmpindex, to => $index_fn;

    $self;
}

sub addWarcRecord($$)
{   my ($self, $record) = @_;
    my $warc = $self->currectWARC || $self->createWARC;
    $warc->write($record);
}

sub finish()
{   my $self = shift;
    $self->acceptWARC;

    $self->SUPER::finish;
}

1;
