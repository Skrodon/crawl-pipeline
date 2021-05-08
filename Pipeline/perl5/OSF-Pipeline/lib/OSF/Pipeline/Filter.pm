
package OSF::Pipeline::Filter;

use warnings;
use strict;

use JSON        ();
my $json = JSON->new->utf8;

# my $filter = OSF::Pipeline::Filter->new(%options)
# Options:
#   text_contains_words   => ARRAY of strings
#   text_contains_regexes => ARRAY of Regexps
#   domain-names          => ARRAY of strings (includes all subdomains)
#   accept_content_types  => ARRAY of strings (not patterns)
#   requires_text         => BOOLEAN (default false)
#   minimum_text_size     => INTEGER (default 0)

sub new(%) { my $class = shift; (bless {}, $class)->init({@_}) }

sub init($)
{   my ($self, $args) = @_;

    ### Content-Type restrictions
    #

    $self->{OPF_ct} = +{ map +(lc $_ => 1), $args->{accept_content_types} };

    ### Flags
    #

    # No not inspect a product unless it has a text extract.
    $self->{OPF_req_text} = $args->{requires_text}     || 0;

    # Small texts extracts are usually garbage
    $self->{OPF_min_text} = $args->{minimum_text_size} || 0;

    ### Words
    #   May contain \W, but f.i. blanks are not handled as \s+

    my $words = $args->{text_contains_words} || [];
    if(@$words)
    {   # For the first, optimized scan
        my $any = join '|', map quotemeta, @$words;
        $self->{OPF_any_word} = qr!\b(?:$any)\b!;

        # Translate word into regex
        $self->{OPF_words} = +{ map +($_ => qr/\b\Q$_\E\b/i), @$words };
    }

    ### Regex
    #   Passed as LIST of pairs.

    my $regexes = $self->{OPF_regexes}
       = +{ @{$args->{text_contains_regexes} || []} };

    if(keys %$regexes)
    {   my $any = join '|', values %$regexes;
        $self->{OPF_any_regex} = qr!\b(?:$any)\b!;
    }

    ### Domain-names

    my $domains = $self->{OPF_domains} = $args->{domain_names} || [];
    if(@$domains)
    {   # Matching them reverse sorted makes regex internal optimizations
        # possible.
        my $domains = join '|', sort map lc scalar reverse, @$domains;
        $domains    =~ s/\./\\./g;
        $self->{OPF_any_domain} = qr/^($domains)(?:\.|$)/;
    }

    ### Statistics
    $self->{OPF_stats} = { taken => 0 };

    $self;
}

# my $taken = $filter->filter($product)
# Process the product: take what we need if we need it.

sub filter($)
{   my ($self, $product) = @_;
    my $stats = $self->{OPF_stats};
    $stats->{products}++;

    return 0
        if $self->exclude($product);

    $stats->{inspected}++;

    # Do we need this object?
    my $hits = $self->selects($product);
    @$hits or return 0;

    # write
    $self->save($product, $hits);
    $stats->{taken}++;
}

# my $exclude = $filter->exclude($product);
# Do not inspect the product any further which this returns true.

sub exclude($$)
{   my ($self, $product) = @_;

    if(my $accept_ct = $self->{OPF_ct})
    {   $accept_ct->{lc $product->contentType}
            or return 1;
    }

    my $text;
    if($self->{OPF_req_text})
    {   $text = $product->part('text');
        $text or return 1;
    }

    if(my $min = $self->{OPF_min_text})
    {   $text ||= $product->part('text');
        return 1 if length ${$text->ref_body} < $min;
    }

    0;
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
                if defined $any_word && $$text =~ $any_word;

            push @hits, $self->_find_regexes($text)
                if defined $any_regex && $$text =~ $any_regex;
        }
    }

    if(my $domains = $self->{OPF_any_domain})
    {   my $hostname = lc $product->uri->host;

        if(reverse($hostname) =~ $domains)
        {   my $domain = reverse $1;
            push @hits, +{ rule => 'domain name', name => $domain };

            # Don't overdo the stats
            my $counter = @{$self->{OPF_domains}} > 10 ? 'domain'
               : "domain in $domain";

            $self->{OPF_stats}{rule}{$counter}++;
        }
    }

    \@hits;
}

sub _find_words($)
{   my ($self, $text) = @_;
    my @hits;
    my $words = $self->{OPF_words};

    foreach my $word (keys %$words)
    {   $$text =~ $words->{$word} or next;

        push @hits, +{ rule => 'word in text', word => $word };
        $self->{OPF_stats}{rule}{"word $word"}++;
    }

    @hits;
}

sub _find_regexes($)
{   my ($self, $text) = @_;
    my @hits;
    my $regexes = $self->{OPF_regexes};

    foreach my $name (keys %$regexes)
    {   $$text =~ $regexes->{$name} or next;
        push @hits, +{ rule => 'regex in text', name => $name };
        $self->{OPF_stats}{rule}{"regex $name"}++;
    }

    @hits;
}

# Called when one batch of input has been processed.  It may
# trigger statistics to be written, files to be closed or whatever.
sub finish(%)
{   my ($self, %args) = @_;

use Data::Dumper;
warn "STATS=", Dumper($self->{OPF_stats});
}

1;
