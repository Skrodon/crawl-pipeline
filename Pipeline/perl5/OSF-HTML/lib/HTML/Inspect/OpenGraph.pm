##no critic [Modules::RequireFilenameMatchesPackage]
package HTML::Inspect;    # role OpenGraph

use strict;
use warnings;
use utf8;
no warnings 'experimental::lexical_subs';    # needed if $] < 5.026;
no warnings 'experimental::signatures';
use feature qw (:5.20 lexical_subs signatures);

use Log::Report 'html-inspect';
use XML::LibXML ();


# When the property itself does not contain an attribute, but we know
# that it may have attributes ("structured properties"), we need to create
# a HASH which stores this content.  We want consistent output, whether
# the attributes are actually present or not.
my %is_structural = (
    'og:image'    => 'url',
    'og:video'    => 'url',
    'og:audio'    => 'url',
    'og:locale'   => 'this',
    'music:album' => 'location',       # not sure about this one
    'music:song'  => 'description',    # not sure about this one
    'video:actor' => 'profile',
);

# Some properties or attributes can appear more than once.  They will always
# be collected as ARRAY, even if there is only one presence: this helps
# implementors.
my %is_array = map { $_ => 1 } qw/
  article:author
  article:tag
  book:author
  book:tag
  music:album
  music:musician
  music:song
  og:audio
  og:image
  og:locale:alternate
  og:restrictions
  og:video
  video:actor
  video:director
  video:tag
  video:writer
  /;

my $X_META_PROPERTY = XML::LibXML::XPathExpression->new('//meta[@property]');

sub collectOpenGraph ($self, %args) {
    return $self->{HIO_og} if $self->{HIO_og};

    my $data = $self->{HIO_og} = {};
    foreach my $meta ($self->doc->findnodes($X_META_PROPERTY)) {
        my ($used_prefix, $name, $attr) = split /\:/, lc $meta->getAttribute('property'), 3;
        my $content  = _trimss $meta->getAttribute('content');
        my $property = "$used_prefix:$name";
        my $table    = $data->{$used_prefix} ||= {};
        #warn "($used_prefix, $name, $attr)";
        if($attr) {
#            if ($is_array{$property} && !$table->{$name}){
#                $table->{$name} =[{$attr=>$content}];
#                next;
#            }elsif($is_array{$property} && $table->{$name}){
#                push @{$table->{$name}},{$attr=>$content};
#                next;
#            }
            if(my $structure = $is_array{$property} ? $table->{$name}[-1] : ($table->{$name} //= {})) {
                if($is_array{"$property:$attr"}) {
                    push @{$structure->{$attr}}, $content;
                }
                else {
                    $structure->{$attr} = $content;
                }
            }
            # ignore attributes without starting property
        }
        elsif(my $default_attr = $is_structural{$property}) {
            if($is_array{$property}) {
                push @{$table->{$name}}, {$default_attr => $content};
            }
            else {
                $table->{$name} = {$default_attr => $content};
            }
        }
        else {
            if($is_array{$property}) {
                push @{$table->{$name}}, $content;
            }
            else {
                $table->{$name} = $content;
            }
        }
    }
    return $data;
}

1;
