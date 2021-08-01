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
    # note explain $og;
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
    # note explain $og;
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
    # note explain $og;
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

# audio-array.html
sub audio_array {
    my $html = slurp("$Bin/data/open-graph-protocol-examples/audio-array.html");
    my $i    = HTML::Inspect->new(request_uri => 'http://examples.opengraphprotocol.us/audio-array.html', html_ref => \$html);
    my $og   = $i->collectOpenGraph();
    # note explain $og;
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
    # note explain $og;
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

# audio.html
sub audio {
    my $html = slurp("$Bin/data/open-graph-protocol-examples/audio.html");
    my $i    = HTML::Inspect->new(request_uri => 'http://examples.opengraphprotocol.us/audio.html', html_ref => \$html);
    my $og   = $i->collectOpenGraph();
    # note explain $og;
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
    # note explain $og;
    is_deeply(
        $og => {
            'book' => {
                'author'       => 'http://examples.opengraphprotocol.us/profile.html',
                'isbn'         => '1451648537',
                'release_date' => '2011-10-24',
                'tag'          => [ 'Steve Jobs', 'Apple', 'Pixar' ]
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
                'title'     => 'Steve Jobs',
                'type'      => 'book',
                'url'       => 'http://examples.opengraphprotocol.us/book-isbn10.html'
            },
            'prefixes' => {'book' => 'http://ogp.me/ns/book#', 'og' => 'http://ogp.me/ns#'}
        },
        'Right structure for book-isbn10.html'
    );
}
# book.html
# this file is structuraly the same as book-isbn10.html, so we skip it.


subtest 'article-offset.html' => \&article_offset;
subtest 'article-utc.html'    => \&article_utc;
subtest 'article.html'        => \&article;
subtest 'audio-array.html'    => \&audio_array;
subtest 'audio-url.html'      => \&audio_url;
subtest 'audio.html'          => \&audio;
subtest 'book-isbn10.html'    => \&book_isbn10;
# rest of the files are tested as one
my $test_files = {
    'canadian.html' => {
        'og' => {
            'image'  => 'http://examples.opengraphprotocol.us/media/images/50.png',
            'locale' => 'en_CA',
            'title'  => 'Canadian, eh?',
            'type'   => 'website',
            'url'    => 'http://examples.opengraphprotocol.us/canadian.html'
        },
        'prefixes' => {'og' => 'http://ogp.me/ns#'}
    },
    'error.html'       => {},
    'image-array.html' => {
        'og' => {
            'image' => [
                {
                    'height'     => '75',
                    'secure_url' => 'https://d72cgtgi6hvvl.cloudfront.net/media/images/75.png',
                    'type'       => 'image/png',
                    'url'        => 'http://examples.opengraphprotocol.us/media/images/75.png',
                    'width'      => '75'
                },
                {
                    'height'     => '50',
                    'secure_url' => 'https://d72cgtgi6hvvl.cloudfront.net/media/images/50.png',
                    'type'       => 'image/png',
                    'url'        => 'http://examples.opengraphprotocol.us/media/images/50.png',
                    'width'      => '50'
                }
            ],
            'locale'    => 'en_US',
            'site_name' => 'Open Graph protocol examples',
            'title'     => 'Two structured image properties',
            'type'      => 'website',
            'url'       => 'http://examples.opengraphprotocol.us/image-array.html'
        },
        'prefixes' => {'og' => 'http://ogp.me/ns#'}
    },
    'image-toosmall.html' => {
        'og' => {
            'description' => 'Will an indexer accept a 1x1 transparent PNG?',
            'image'       => {
                'height'     => '1',
                'secure_url' => 'https://d72cgtgi6hvvl.cloudfront.net/media/images/1.png',
                'type'       => 'image/png',
                'url'        => 'http://examples.opengraphprotocol.us/media/images/1.png',
                'width'      => '1'
            },
            'locale'    => 'en_US',
            'site_name' => 'Open Graph protocol examples',
            'title'     => 'Structured image too small',
            'type'      => 'website',
            'url'       => 'http://examples.opengraphprotocol.us/image-toosmall.html'
        },
        'prefixes' => {'og' => 'http://ogp.me/ns#'}
    },
    'image-url.html' => {
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
            'title'     => 'Full structured image property',
            'type'      => 'website',
            'url'       => 'http://examples.opengraphprotocol.us/image-url.html'
        },
        'prefixes' => {'og' => 'http://ogp.me/ns#'}
    },
    'image.html' => {
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
            'title'     => 'Structured image property',
            'type'      => 'website',
            'url'       => 'http://examples.opengraphprotocol.us/image.html'
        },
        'prefixes' => {'og' => 'http://ogp.me/ns#'}
      }

    ,
    'min.html'     => {'og' => {'description' => 'Content not on page', 'site_name' => 'Open Graph protocol examples'}},
    'nomedia.html' => {
        'og' => {
            'description' => 'Required and optional properties without associated media.',
            'determiner'  => 'the',
            'image'       => 'http://examples.opengraphprotocol.us/media/images/50.png',
            'locale'      => 'en_US',
            'site_name'   => 'Open Graph protocol examples',
            'title'       => 'No media properties',
            'type'        => 'website',
            'url'         => 'http://examples.opengraphprotocol.us/nomedia.html'
        },
        'prefixes' => {'og' => 'http://ogp.me/ns#'}
    },
    'plain.html'   => {},
    'profile.html' => {
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
            'title'     => 'John Doe profile page',
            'type'      => 'profile',
            'url'       => 'http://examples.opengraphprotocol.us/profile.html'
        },
        'prefixes' => {'og' => 'http://ogp.me/ns#', 'profile' => 'http://ogp.me/ns/profile#'},
        'profile'  => {'first_name' => 'John', 'gender' => 'male', 'last_name' => 'Doe', 'username' => 'johndoe'}
      }

    ,
    'required.html' => {
        'og' => {
            'image' => 'http://examples.opengraphprotocol.us/media/images/50.png',
            'title' => 'Minimum required properties',
            'url'   => 'http://examples.opengraphprotocol.us/required.html'
        },
        'prefixes' => {'og' => 'http://ogp.me/ns#'}
    },
    'video-array.html' => {
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
            'title'     => 'Structured video array',
            'type'      => 'website',
            'url'       => 'http://examples.opengraphprotocol.us/video-array.html',
            'video'     => [
                {
                    'height'     => '296',
                    'secure_url' =>
                      'https://fpdownload.adobe.com/strobe/FlashMediaPlayback.swf?src=https%3A%2F%2Fd72cgtgi6hvvl.cloudfront.net%2Fmedia%2Fvideo%2Ftrain.mp4',
                    'type' => 'application/x-shockwave-flash',
                    'url'  =>
                      'http://fpdownload.adobe.com/strobe/FlashMediaPlayback.swf?src=http%3A%2F%2Fexamples.opengraphprotocol.us%2Fmedia%2Fvideo%2Ftrain.mp4',
                    'width' => '472'
                },
                {
                    'height'     => '296',
                    'secure_url' => 'https://d72cgtgi6hvvl.cloudfront.net/media/video/train.mp4',
                    'type'       => 'video/mp4',
                    'url'        => 'http://examples.opengraphprotocol.us/media/video/train.mp4',
                    'width'      => '472'
                },
                {
                    'height'     => '320',
                    'secure_url' => 'https://d72cgtgi6hvvl.cloudfront.net/media/video/train.webm',
                    'type'       => 'video/webm',
                    'url'        => 'http://examples.opengraphprotocol.us/media/video/train.webm',
                    'width'      => '480'
                }
            ]
        },
        'prefixes' => {'og' => 'http://ogp.me/ns#'}
    },
    'video-movie.html' => {
        'og' => {
            'description' =>
              "L'arriv\x{e9}e d'un train en gare de La Ciotat is an 1895 French short black-and-white silent documentary film directed and produced by Auguste and Louis Lumi\x{e8}re. Its first public showing took place in January 1896.",
            'image' => {
                'height'     => '328',
                'secure_url' => 'https://d72cgtgi6hvvl.cloudfront.net/media/images/train.jpg',
                'type'       => 'image/jpeg',
                'url'        => 'http://examples.opengraphprotocol.us/media/images/train.jpg',
                'width'      => '500'
            },
            'locale'    => 'en_US',
            'site_name' => 'Open Graph protocol examples',
            'title'     => 'Arrival of a Train at La Ciotat',
            'type'      => 'video.movie',
            'url'       => 'http://examples.opengraphprotocol.us/video-movie.html',
            'video'     => [
                {
                    'height'     => '296',
                    'secure_url' =>
                      'https://fpdownload.adobe.com/strobe/FlashMediaPlayback.swf?src=https%3A%2F%2Fd72cgtgi6hvvl.cloudfront.net%2Fmedia%2Fvideo%2Ftrain.mp4',
                    'type' => 'application/x-shockwave-flash',
                    'url'  =>
                      'http://fpdownload.adobe.com/strobe/FlashMediaPlayback.swf?src=http%3A%2F%2Fexamples.opengraphprotocol.us%2Fmedia%2Fvideo%2Ftrain.mp4',
                    'width' => '472'
                },
                {
                    'height'     => '296',
                    'secure_url' => 'https://d72cgtgi6hvvl.cloudfront.net/media/video/train.mp4',
                    'type'       => 'video/mp4',
                    'url'        => 'http://examples.opengraphprotocol.us/media/video/train.mp4',
                    'width'      => '472'
                },
                {
                    'height'     => '320',
                    'secure_url' => 'https://d72cgtgi6hvvl.cloudfront.net/media/video/train.webm',
                    'type'       => 'video/webm',
                    'url'        => 'http://examples.opengraphprotocol.us/media/video/train.webm',
                    'width'      => '480'
                }
            ]
        },
        'prefixes' => {'og' => 'http://ogp.me/ns#', 'video' => 'http://ogp.me/ns/video#'},
        'video'    => {
            'director'     => 'http://examples.opengraphprotocol.us/profile.html',
            'duration'     => '50',
            'release_date' => '1895-12-28',
            'tag'          => [ 'La Ciotat', 'train' ]
        }
    },
    'video.html' => {
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
            'title'     => 'Structured video property',
            'type'      => 'website',
            'url'       => 'http://examples.opengraphprotocol.us/video.html',
            'video'     => {
                'height'     => '296',
                'secure_url' =>
                  'https://fpdownload.adobe.com/strobe/FlashMediaPlayback.swf?src=https%3A%2F%2Fd72cgtgi6hvvl.cloudfront.net%2Fmedia%2Fvideo%2Ftrain.mp4',
                'type' => 'application/x-shockwave-flash',
                'url'  =>
                  'http://fpdownload.adobe.com/strobe/FlashMediaPlayback.swf?src=http%3A%2F%2Fexamples.opengraphprotocol.us%2Fmedia%2Fvideo%2Ftrain.mp4',
                'width' => '472'
            }
        },
        'prefixes' => {'og' => 'http://ogp.me/ns#'}
    },
};
for my $filename (sort keys %$test_files) {
    my $file = "$Bin/data/open-graph-protocol-examples/$filename";
    ok(-f $file, "$filename found");
    my $html = slurp($file);
    my $i    = HTML::Inspect->new(request_uri => "http://examples.opengraphprotocol.us/$filename", html_ref => \$html);
    my $og   = $i->collectOpenGraph();
    # note explain $og;
    is_deeply($og => $test_files->{$filename}, "Right structure for $filename");
}
done_testing;
