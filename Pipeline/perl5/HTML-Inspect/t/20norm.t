use warnings;
use strict;
use Test::More;

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

done_testing;
