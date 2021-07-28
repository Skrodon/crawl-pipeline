use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use lib "$Bin/lib";
use lib "$Bin/../lib";
use Test::More;
use TestUtils qw(slurp);
use HTML::Inspect;

# Testing collectOpenGraph() thoroughly here
unless (-d "$Bin/data/open-graph-protocol-examples") {
    plan(skip_all => 'OpenGraph example data is not redistributed with this module.');
}

# article-offset.html
sub article_offset {
    my $html = slurp("$Bin/data/open-graph-protocol-examples/article-offset.html");
    my $i    = HTML::Inspect->new(request_uri => 'http://examples.opengraphprotocol.us/article-offset.html', html_ref => \$html);
    my $og   = $i->collectOpenGraph();
    note explain $og;
    is_deeply(
        $og => {
            'article' => {
                'author'         => 'http://examples.opengraphprotocol.us/profile.html',
                'published_time' => '1972-06-17T20:23:45-05:00',
                'section'        => 'Front page',
                'tag'            => 'Watergate'
            },
            'og' => {
                'image' => {
                    'height'     => '50',
                    'secure_url' => 'https://d72cgtgi6hvvl.cloudfront.net/media/images/50.png',
                    'type'       => 'image/png',
                    'url'        => 'http://examples.opengraphprotocol.us/media/images/50.png',
                    'width'      => '50'
                },
                'locale'    => 'en_US',
                'site_name' => 'Open Graph protocol examples',
                'title'     => '5 Held in Plot to Bug Office',
                'type'      => 'article',
                'url'       => 'http://examples.opengraphprotocol.us/article-offset.html'
            },
            'prefixes' => {'article' => 'http://ogp.me/ns/article#', 'og' => 'http://ogp.me/ns#'}
        },
        'Right structure for article-offset.html'
    );
}

# article-utc.html
sub article_utc {
    my $html = slurp("$Bin/data/open-graph-protocol-examples/article-utc.html");
    my $i    = HTML::Inspect->new(request_uri => 'http://examples.opengraphprotocol.us/article-utc.html', html_ref => \$html);
    my $og   = $i->collectOpenGraph();
    note explain $og;
    is_deeply(
        $og =>

          {
            'article' => {
                'author'         => 'http://examples.opengraphprotocol.us/profile.html',
                'published_time' => '1972-06-18T01:23:45Z',
                'section'        => 'Front page',
                'tag'            => 'Watergate'
            },
            'og' => {
                'image' => {
                    'height'     => '50',
                    'secure_url' => 'https://d72cgtgi6hvvl.cloudfront.net/media/images/50.png',
                    'type'       => 'image/png',
                    'url'        => 'http://examples.opengraphprotocol.us/media/images/50.png',
                    'width'      => '50'
                },
                'locale'    => 'en_US',
                'site_name' => 'Open Graph protocol examples',
                'title'     => '5 Held in Plot to Bug Office',
                'type'      => 'article',
                'url'       => 'http://examples.opengraphprotocol.us/article-utc.html'
            },
            'prefixes' => {'article' => 'http://ogp.me/ns/article#', 'og' => 'http://ogp.me/ns#'}
          },
        'Right structure for article-utc.html'
    );
}

#article.html
sub article {
    my $html = slurp("$Bin/data/open-graph-protocol-examples/article.html");
    my $i    = HTML::Inspect->new(request_uri => 'http://examples.opengraphprotocol.us/article.html', html_ref => \$html);
    my $og   = $i->collectOpenGraph();
    note explain $og;
    is_deeply(
        $og => {
            'article' => {
                'author'         => 'http://examples.opengraphprotocol.us/profile.html',
                'published_time' => '1972-06-18',
                'section'        => 'Front page',
                'tag'            => 'Watergate'
            },
            'og' => {
                'image' => {
                    'height'     => '50',
                    'secure_url' => 'https://d72cgtgi6hvvl.cloudfront.net/media/images/50.png',
                    'type'       => 'image/png',
                    'url'        => 'http://examples.opengraphprotocol.us/media/images/50.png',
                    'width'      => '50'
                },
                'locale'    => 'en_US',
                'site_name' => 'Open Graph protocol examples',
                'title'     => '5 Held in Plot to Bug Office',
                'type'      => 'article',
                'url'       => 'http://examples.opengraphprotocol.us/article.html'
            },
            'prefixes' => {'article' => 'http://ogp.me/ns/article#', 'og' => 'http://ogp.me/ns#'}
        },
        'Right structure for article.html'
    );
}

#audio-array.html
sub audio_array {
    my $html = slurp("$Bin/data/open-graph-protocol-examples/audio-array.html");
    my $i    = HTML::Inspect->new(request_uri => 'http://examples.opengraphprotocol.us/audio-array.html', html_ref => \$html);
    my $og   = $i->collectOpenGraph();
    note explain $og;
    is_deeply(
        $og => {
            'og' => {
                'audio' => [
                    {
                        'secure_url' => 'https://d72cgtgi6hvvl.cloudfront.net/media/audio/1khz.mp3',
                        'type'       => 'audio/mpeg',
                        'url'        => 'http://examples.opengraphprotocol.us/media/audio/1khz.mp3'
                    },
                    {
                        'secure_url' => 'https://d72cgtgi6hvvl.cloudfront.net/media/audio/250hz.mp3',
                        'type'       => 'audio/mpeg',
                        'url'        => 'http://examples.opengraphprotocol.us/media/audio/250hz.mp3'
                    }
                ],
                'image' => {
                    'height'     => '50',
                    'secure_url' => 'https://d72cgtgi6hvvl.cloudfront.net/media/images/50.png',
                    'type'       => 'image/png',
                    'url'        => 'http://examples.opengraphprotocol.us/media/images/50.png',
                    'width'      => '50'
                },
                'locale'    => 'en_US',
                'site_name' => 'Open Graph protocol examples',
                'title'     => 'Two structured audio properties',
                'type'      => 'website',
                'url'       => 'http://examples.opengraphprotocol.us/audio-array.html'
            },
            'prefixes' => {'og' => 'http://ogp.me/ns#'}
          }

        ,
        'Right structure for audio-array.html'
    );
}

# audio-url.html
sub audio_url {
    my $html = slurp("$Bin/data/open-graph-protocol-examples/audio-url.html");
    my $i    = HTML::Inspect->new(request_uri => 'http://examples.opengraphprotocol.us/audio-url.html', html_ref => \$html);
    my $og   = $i->collectOpenGraph();
    note explain $og;
    is_deeply(
        $og => {
            'og' => {
                'audio' => {
                    'secure_url' => 'https://d72cgtgi6hvvl.cloudfront.net/media/audio/250hz.mp3',
                    'type'       => 'audio/mpeg',
                    'url'        => 'http://examples.opengraphprotocol.us/media/audio/250hz.mp3'
                },
                'image' => {
                    'height'     => '50',
                    'secure_url' => 'https://d72cgtgi6hvvl.cloudfront.net/media/images/50.png',
                    'type'       => 'image/png',
                    'url'        => 'http://examples.opengraphprotocol.us/media/images/50.png',
                    'width'      => '50'
                },
                'locale'    => 'en_US',
                'site_name' => 'Open Graph protocol examples',
                'title'     => 'Structured audio property',
                'type'      => 'website',
                'url'       => 'http://examples.opengraphprotocol.us/audio-url.html'
            },
            'prefixes' => {'og' => 'http://ogp.me/ns#'}
        },
        'Right structure for audio-url.html'
    );
}

#audio.html
sub audio {
    my $html = slurp("$Bin/data/open-graph-protocol-examples/audio.html");
    my $i    = HTML::Inspect->new(request_uri => 'http://examples.opengraphprotocol.us/audio.html', html_ref => \$html);
    my $og   = $i->collectOpenGraph();
    note explain $og;
    is_deeply(
        $og => {
            'og' => {
                'audio' => {
                    'secure_url' => 'https://d72cgtgi6hvvl.cloudfront.net/media/audio/250hz.mp3',
                    'type'       => 'audio/mpeg',
                    'url'        => 'http://examples.opengraphprotocol.us/media/audio/250hz.mp3'
                },
                'image' => {
                    'height'     => '50',
                    'secure_url' => 'https://d72cgtgi6hvvl.cloudfront.net/media/images/50.png',
                    'type'       => 'image/png',
                    'url'        => 'http://examples.opengraphprotocol.us/media/images/50.png',
                    'width'      => '50'
                },
                'locale'    => 'en_US',
                'site_name' => 'Open Graph protocol examples',
                'title'     => 'Structured audio property',
                'type'      => 'website',
                'url'       => 'http://examples.opengraphprotocol.us/audio.html'
            },
            'prefixes' => {'og' => 'http://ogp.me/ns#'}
        },
        'Right structure for audio.html'
    );
}

# book-isbn10.html
sub book_isbn10 {
    my $html = slurp("$Bin/data/open-graph-protocol-examples/book-isbn10.html");
    my $i    = HTML::Inspect->new(request_uri => 'http://examples.opengraphprotocol.us/book-isbn10.html', html_ref => \$html);
    my $og   = $i->collectOpenGraph();
    note explain $og;
    is_deeply($og => {}, 'Right structure for book-isbn10.html');
}

#book.html
#canadian.html
#error.html
#favicon.ico
#image-array.html
#image-toosmall.html
#image-url.html
#image.html
#index.html
#min.html
#nomedia.html
#plain.html
#profile.html
#required.html
#robots.txt
#sitemap.xml
#video-array.html
#video-movie.html
#video.html
subtest 'article-offset.html' => \&article_offset;
subtest 'article-utc.html'    => \&article_utc;
subtest 'article.html'        => \&article;
subtest 'audio-array.html'    => \&audio_array;
subtest 'audio-url.html'      => \&audio_url;
subtest 'audio.html'          => \&audio;
# subtest 'book-isbn10.html'    => \&book_isbn10;

done_testing;
