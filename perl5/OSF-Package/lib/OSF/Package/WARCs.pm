package OSF::Package::WARCs;
use parent 'OSF::Package';

use warnings;
use strict;

use Log::Report 'osf-package';

use OSF::WARC::Sink    ();

use File::Copy         qw(move);
use File::Path         qw(make_path);
use File::Glob         qw(bsd_glob);
use POSIX              qw(strftime);
use IO::Compress::Gzip qw(gzip $GzipError);
use JSON               ();
use File::Slurper      qw(write_binary);

my $json = JSON->new->pretty;

=chapter NAME

OSF::Package::WARCs - package results into WARC files

=chapter SYNOPSIS

    my $pkg = OSF::Package::WARCs->new(tmp => $dir1, publish => $dir2);
    $pkg->addWARCRecord($record, $facts);
    $pkg->possibleBreakpoint;

=chapter DESCRIPTION

Publish filter Task results in a stream of WARC files.  While those are
being filled, the have a C<-part> name in the temporary directory.

WARC files are "full" when their compressed size gets over 1GB.  When
a batch process has completed, it probably was writing to a WARC which
was not full.  That file moves to a C<-orphan> name, to be adopted by the
next batch processes.

Special care is taken not to publish WARCs before they are complete and
to lock-free let parallel batches re-use orphans.

=chapter METHODS

=section Constructors

=c_method new %options
The C<tmp> and C<publish> directories must be on the same file-system.

=requires tmp DIRECTORY
Where the WARCs are being filled.

=requires publish DIRECTORY
Where the external user of the data can collect filled WARCs and their
indices.
=cut

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

#----------------
=section Attributes
=method tmp
=method publish
=cut

sub tmp()         { $_[0]->{OPW_tmp} }
sub publish()     { $_[0]->{OPW_publish} }
sub currentWARC() { $_[0]->{OPW_warc} }

#----------------
=section Handling WARC files

=method createWARC
Create a new, empty WARC file.  This returns an M<OSF::WARC::Sink>.
=cut

sub createWARC()
{   my $self   = shift;
    my $unique = strftime "%Y%m%d-%H%M%S-$$", gmtime;
    my $fn     = $self->tmp . "/$unique.warc.gz-part";
    $self->{OPW_warc} = OSF::WARC::Sink->new(filename => $fn);
}

sub _saveIndex($)
{   my ($self, $warc) = @_;
    my $fn   = $warc->filename =~ s!-part$!-index.json!r;
    write_binary $fn, $json->encode($warc->index);
    $fn;
}

=method orphanWARC
Make a WARC file into an orphan: this process does not need it anymore,
hopefully someone else will adopt it.
=cut

sub orphanWARC()
{   my $self   = shift;

    my $warc   = delete $self->{OPW_warc} or return;
    $self->_saveIndex($warc);    # before offering warc for adoption

    my $fn     = $warc->filename;
    my $offer  = $fn =~ s/-part$/-orphan/r;
    move $fn, $offer
        or fault __x"Cannot put {fn} on offer", fn => $fn;
}

=method adoptWARC
Try to adopt an orphaned WARC, left by a cleanly terminated batch process.
This may return C<undef> when there is none available.
=cut

sub adoptWARC()
{   my $self = shift;
    my $tmp  = $self->tmp;

    foreach my $adopt (bsd_glob "$tmp/*-orphan")
    {   my $filebase = $adopt =~ s/-orphan$//r;
        my $part     = "$filebase-part";
        move $adopt, $part
            or next;  # next when race condition

        my $index    = $json->decode("$filebase-index.json");
        return $self->{OPW_warc} = OSF::WARC::Sink->new(
            filename => $part,
            index    => $index,
            reopen   => 1,
        );
    }

    undef;
}

=method publishWARC
The WARC file is full, and can be published to the external customer.  The index file
is moved first, because it must be present before the warc file is opened.
=cut

sub publishWARC()
{   my $self    = shift;
    my $warc    = delete $self->{OPW_warc} or return;
    my $part_fn = $warc->filename;
    my $unique  = $part_fn =~ m!.*/(.*?).warc.gz-part$! ? $1 : panic $part_fn;

    # Publish the index file in compressed form
    my $tmpindex = $self->_saveIndex($warc);
    gzip $tmpindex, "$tmpindex.gz"
        or fault __x"Cannot gzip {fn}", fn => $tmpindex, _code => $GzipError;

    my $index_fn = $self->publish . "/$unique.index.json.gz";
    move $tmpindex, $index_fn
        or fault __x"Cannot publish WARC index from {from} to {to}", from => $tmpindex, to => $index_fn;

    # Publish the WARC file
    my $warc_fn = $self->publish . "/$unique.warc.gz";
    move $part_fn, $warc_fn
        or fault __x"Cannot publish WARC from {from} to {to}", from => $part_fn, to => $warc_fn;


    $self;
}

=method addWARCRecord $record, [ \%facts ]
Add a record to the currently active WARC file, or open a new one when there is none open.

When you specify C<%facts>, they are added to the index for that record.
=cut

sub addWARCRecord($$)
{   my ($self, $record, $facts) = @_;
    my $warc = $self->currentWARC || $self->adoptWARC || $self->createWARC;
    $warc->write($record, $facts || {});
    $self;
}

=method possibleBreakpoint
Flag that the WARC is in a complete state: we wish to keep related records in the same
WARC file, so after a set is written, we signal the packager that it may be a good moment
to publish.
=cut

sub possibleBreakpoint()
{   my $self = shift;
    my $warc = $self->currentWARC or return;
    $self->publishWARC if $warc->isFull;
    $self;
}

# Inherited
sub batchFinished()
{   my $self = shift;

    # a next batch process may continue with this file
    $self->orphanWARC;
    $self->SUPER::batchFinised;
}

1;
