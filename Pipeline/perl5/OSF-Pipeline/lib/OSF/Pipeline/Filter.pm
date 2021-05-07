
package OSF::Pipeline::Filter;

use JSON     ();
my $json = JSON->new->utf8;

# my $filter = OSF::Pipeline::Filter->new(%options)
# Options:
#   text_contains_words   => ARRAY
#   text_contains_regexes => ARRAY

sub new(%) { my $class = shift; (bless {}, $class)->init({@_}) }

sub init($)
{   my ($self, $args) = @_;

    ### Words
    #   May contain \W, but f.i. blanks are not handled as \s+

    my $words = $args->{text_contains_words} || [];
    if(@$words)
    {   # For the first, optimized scan
        my $any = join '|', map quotemeta, @$words;
        $self->{OPF_any_word} = qr!\b(?:$any)\b!;

        # Translate word into regex
        $self->{OPF_words} = +{ map +($_ => qr/\b\Q$word\E\b/i), @$words };
    }

    ### Regex

    my $regexes = $self->{OPF_regexes} = $args->{text_contains_regexes} || {};
    if(keys %$regexes)
    {   my $any = join '|', values %$regexes;
        $self->{OPF_any_regex} = qr!\b(?:$any)\b!;
    }

    ### Domain-names

    my $domains = $args->{domain_names} || [];
    if(@$domains)
    {   # Matching them reverse sorted makes regex internal optimizations
        # possible.
        my $domains = join '|', sort map lc scalar reverse, @$domains;
        $domains    =~ s/\./\\./g;
        $self->{OPF_domains} = qr/^($domains)(?:\.|$)/;
    }

    ### Statistics
    $self->{OPF_taken} = 0;

    $self;
}

# my $taken = $filter->filter($product)
# Process the product: take what we need if we need it.

sub filter($)
{   my ($self, $product) = @_;

    # Do we need this object?
    my $hits = $self->selects($product);
    @$hits or return 0;

    # write
    $self->save($product);
    $self->{OPF_taken}++;
}

# my $hits = $filter->selects($product);
# Returns an ARRAY of HASHes with information about the reasons of
# selection, when the product needs to be sent to consumer.

sub selects($)
{   my ($self, $product) = @_;

    my $any_word  = $self->{OPF_any_word};
    my $any_regex = $self->{OPF_any_regex};

    my ($text, @hits);
    if(defined $any_word || defined $any_regex)
    {   if(my $p = $product->part('text'))
        {   $text = $p->ref_body;    # is ref to text

            push @hits, $self->_find_words($text)
                if $$text =~ $any_word;

            push @hits, $self->_find_regexes($text)
                if $$text =~ $any_regex;
        }
    }

    if(my $domains = $self->{OPF_domains})
    {   my $hostname = lc $product->uri->host;

        push @hits, +{ rule => 'domain name', name => $1 }
           if reverse($hostname) =~ $domains;
    }

    \@hits;
}

sub _find_words($)
{   my ($self, $text) = @_;
    my @hits;
    my $words = $self->{OPF_words};

    foreach my $word (keys %$words)
    {   $$text =~ $words{$word} or next;
        push @hits, +{ rule => 'word in text', word => $word };
        $self->{OPF_rule}{"word"}++;
    }

    @hits;
}

sub _find_regexes($)
{   my ($self, $text) = @_;
    my @hits;
    my $regexes = $self->{OPF_regexes};

    foreach my $name (keys %$regexes)
    {   $$text =~ $regexes{$name} or next;
        push @hits, +{ rule => 'regex in text', name => $name };
        $self->{OPF_rule}{"regex $name"}++;
    }

    @hits;
}

# Called when one batch of input has been processed.  It may
# trigger statistics to be written, files to be closed or whatever.
sub finish(%)
{   my ($self, %args) = @_;

use Data::Dumper;
warn "TAKEN=", $self->{OPF_taken};
warn "STATS=", Dumper($self->{OPF_rule});
}

1;
