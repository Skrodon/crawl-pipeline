use warnings;
use strict;
use Test::More;
use utf8;

use_ok 'HTML::Inspect::Normalize';
HTML::Inspect::Normalize->import;

# We can use 'set_base' to check much of the parsing

### Blanks
is set_base('  http://example.com'),     'http://example.com/',      'leading blanks';
is set_base('http://example.com  '),     'http://example.com/',      'trailing blanks';
is set_base(' http://example.com '),     'http://example.com/',      'both side blanks';

### Fragment
is set_base('http://example.com#abc'),   'http://example.com/',      'remove fragment';

### Scheme
is set_base('http://example.com'),       'http://example.com/',      'http';
is set_base('https://example.com'),      'https://example.com/',     'https';
is set_base('HtTP://example.com'),       'http://example.com/',      'schema in caps';
is set_base('//example.com'),            'https://example.com/',     'schema from default';

### Auth
is set_base('http://ab@exAmPle.cOm'),    'http://ab@example.com/',   'username';
is set_base('http://ab:cd@exAmPle.cOm'), 'http://ab:cd@example.com/','username + password';
is set_base('http://:cde@exAmPle.cOm'),  'http://:cde@example.com/', 'password';

### Host
is set_base('http://exAmPle.cOm'),       'http://example.com/',      'hostname in caps';
is set_base('http://'),                  'http://localhost/',        'missing host';
is set_base('http:///'),                 'http://localhost/',        'missing host 2';

### Port
is set_base('http://exAmPle.cOm:80'),    'http://example.com/',      'remove default port';
is set_base('https://exAmPle.cOm:431'),  'https://example.com/',     'remove default port';
is set_base('http://example.com:81'),    'http://example.com:81/',   'keep other port';
is set_base('http://example.com:082'),   'http://example.com:82/',   'remove leading zeros';
is set_base('http://example.com:'),      'http://example.com/',      'accidental no port';
is set_base('http://:42'),               'http://localhost:42/',     'missing host 3';

### PATH
is set_base('http://example.com/'),      'http://example.com/',      'only root path';
is set_base('http://example.com/a'),     'http://example.com/a',     'two level path';
is set_base('http://example.com/a/bc'),  'http://example.com/a/bc',  'two level path';
is set_base('http://example.com/a/bc/'), 'http://example.com/a/bc/', 'directory';

is set_base('http://example.com/.'),     'http://example.com/',      'useless dot';
is set_base('http://example.com/a/.'),   'http://example.com/a/',    'dot keep /';
is set_base('http://example.com/./a/'),  'http://example.com/a/',    'dot path removed';
is set_base('http://example.com/./a/././b'), 'http://example.com/a/b','dot path removed multi';
is set_base('http://example.com/.;a'),    'http://example.com/;a',   'dot with attribute';
is set_base('http://example.com/b/.;a'),  'http://example.com/b/;a', 'dot with attribute';
is set_base('http://example.com/.?a'),    'http://example.com/?a',   'dot with query';

is set_base('http://example.com/..'),     'http://example.com/',     'leading dot-dot';
is set_base('http://example.com/../..'),  'http://example.com/',     'leading dot-dot x2';
is set_base('http://example.com/../a'),   'http://example.com/a',    'leading dot-dot with more';
is set_base('http://example.com/b/..'),   'http://example.com/',     'trailing dot-dot';
is set_base('http://example.com/b/../c'), 'http://example.com/c',    'intermediate dot-dot';
is set_base('http://example.com/b/../../c'), 'http://example.com/c', 'too many interm dot-dot';

is set_base('http://e.com/a/./b/.././../c'), 'http://e.com/c',       'hard';

is set_base('http://e.com/μαρκ'), 'http://e.com/%CE%BC%CE%B1%CF%81%CE%BA', 'unicode';

### HEX encoding
is set_base('http://e.com/a%6D%237%40%41'), 'http://e.com/am%237%40A', 'rehex';
is set_base('http://e.com/%2F%25+%20 %3F'), 'http://e.com/%2F%25%20%20%20%3F', 'rehex blanks';

### IDN
is set_base('http://müller.de/abc'), 'http://xn--mller-kva.de/abc', 'idn';

done_testing;
