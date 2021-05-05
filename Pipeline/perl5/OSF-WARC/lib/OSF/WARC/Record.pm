package OSF::WARC::Record;

#!!! $body is reference to a scalar, because Perl makes copies in
#!!! some cases, which may be avoided this way.

sub new($$)
{   my ($class, $head, $body) = @_;
    bless { OWR_head => $head, OWR_body => $body }, $class;
}

sub header($)
{   my ($self, $field) = @_;
    $self->{OWR_head}{lc $field};
}

sub uri() { $_[0]->header('WARC-Target-URI') }

sub ref_body() { $_[0]->{OWR_body} }

sub _warc_fields()
{   my $body = shift->ref_body;
    +{ $$body =~ /^([^:]+)\:\s+(.*?)\s*$/gm };
}

1;
