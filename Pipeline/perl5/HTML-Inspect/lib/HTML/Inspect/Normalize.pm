
package HTML::Inspect::Normalize;
use parent 'Exporter';

use warnings;
use strict;
use Encode      qw(encode);

our @EXPORT = qw(set_base normalize_url);
use Inline 'C' => config => libs => '-lidn2';
use Inline 'C' => 'DATA';

Inline->init;

sub set_base($)      { _set_base(encode utf8 => $_[0]) }
sub normalize_url($) { _normalize_url(encode utf8 => $_[0]) }

1;

__DATA__
__C__

/*
 * We go to great extend to avoid mallocs.  The code is "hit and run": when
 * the url has been processed, the internal data is not needed anymore.  So,
 * preallocation is not a problem but NOT THREAD SAFE.
 */

#include <arpa/inet.h>
#include <idn2.h>

#define MAX_INPUT_URL   1024
#define MAX_STORE_PART  (4*MAX_INPUT_URL)
#define MAX_PORT_NUMBER 32767

#define EOL    '\0'

#define UNSAFE_CHARS    "<>{}|\\^~[]`\""   # rfc1738
#define RESERVED_CHARS  ";/?:@=&"
#define BLANKS          " \t\v\r\n"
#define DIGITS          "0123456789"
#define UNENCODED       "abcdefghijklmnopqrstuvwxyz" \
                        "ABCDEFGHIJKLMNOPQRSTUVWXYZ" \
                        DIGITS \
                        "$-_.+!*'(),"
#define IPv6_CHARS      DIGITS ":"
#define IPv4_CHARS      DIGITS "."

typedef unsigned char byte;

typedef struct url {
   char scheme   [8];                 /* http or https */
   char port     [8];
   char username [MAX_STORE_PART];
   char password [MAX_STORE_PART];
   char host     [MAX_STORE_PART];
   char path     [MAX_STORE_PART];
   char query    [MAX_STORE_PART];
} url;

url default_url = { "https:", "", "localhost", "", "/", "" };

url global_base;

static int normalize_part(char *out, char *part); /* XXX reorder */

static char * rc;
static char * errmsg;

static int strip_blanks(char **str) {
    char * end;
    *str += strspn(*str, BLANKS);     /* leading blanks */

    end = *str + strlen(*str) -1;     /* trailing blanks */
    while(end >= *str) {
        if(strrchr(BLANKS, end[0])==NULL) {
            break;
        }

        end[0] = EOL;
        end--;
    }

    return 1;
}

static int strip_fragment(char **str) {
    char * end;
    if(end = index(*str, '#')) {
        end[0] = EOL;
    }

    return 1;
}

static int unhex(char *part) {
   /* The part does not contain url serialization anymore.  The
    * changes are made in-place, because we reduce the number of
    * characters when %XX is found.  normalize_part() with put
    * then back in, only if needed.
    */
   char *writer = part;
   while(part[0] != EOL) {
       char c = *part++;
       if(c=='%')
       {   char h1 = tolower(*part++);
           char h2 = h1 ? tolower(*part++) : EOL;

           if( !isxdigit(h1) || !isxdigit(h2) ) {
               rc     = "HIN_ILLEGAL_HEX";
               errmsg = "Illegal hexadecimal digit";
               return 0;
           }
           int d1 = h1 <= '9' ? h1 - '0' : h1 - 'a';
           int d2 = h2 <= '9' ? h2 - '0' : h2 - 'a';
           c = (d1 << 4) + d2;
       }
       *writer++ = c;
   }

   *writer = EOL;
   return 1;
}

static int normalize_scheme(url *norm, char **relative, url *base) {
    if(strncasecmp(*relative, "http://", 7)==0) {
        *relative += 5;                   /* keep the // */
        strcpy(norm->scheme, "http");
    }
    else
    if(strncasecmp(*relative, "https://", 8)==0) {
        *relative += 6;
        strcpy(norm->scheme, "https");
    }
    else
    if((*relative)[0]=='/' && (*relative)[1]=='/') {
        strcpy(norm->scheme, base->scheme);
    }
    else
    if(strstr(*relative, "://")) {
        rc     = "HIN_UNSUPPORTED_SCHEME";
        errmsg = "Only http(s) is supported";
        return 0;
    }

    return 1;
}

static int normalize_authorization(url *norm, char *auth, url *base) {
    char * passwd = NULL;       /* points inside auth buffer */
    char * colon;

    if(colon = index(auth, ':')) {
        colon[0] = EOL;         /* chop username */
        passwd   = colon+1;     /* remainer is password */
        if( ! unhex(passwd)) return 0;
    }
    else {
        passwd   = auth + strlen(auth);  /* EOL */
    }

    if( ! unhex(auth)) return 0;
    if( ! normalize_part(norm->username, auth))   return 0;
    if(strcmp(norm->username, "anonymous")==0) {
        norm->username[0] = EOL;
    }

    if( ! normalize_part(norm->password, passwd)) return 0;
    return 1;
}

static int normalize_host(url *norm, char *host) {
    if( ! unhex(host)) return 0;

    if(host[0]=='[') {
        /* IPv6 address */
        host[strlen(host) -1] = EOL;  /* remove trailing ] */
        norm->host[0] = '[';
        byte bin_addr[sizeof(struct in6_addr)];
        if(inet_pton(AF_INET6, host+1, bin_addr)) {
            rc     = "HIN_IPV6_BROKEN";
            errmsg = "The IPv6 host address incorrect";
            return 0;
        }

        inet_ntop(AF_INET6, bin_addr, norm->host +1, INET6_ADDRSTRLEN);
        strcat(norm->host, "]");
        return 1;
    }

    if(strspn(host, IPv4_CHARS)==strlen(host)) {
        /* IPv4 address */
        byte bin_addr[sizeof(struct in_addr)];
        if(inet_pton(AF_INET, host, bin_addr)) {
            rc     = "HIN_IPV4_BROKEN";
            errmsg = "The IPv4 host address incorrect";
            return 0;
        }
        inet_ntop(AF_INET, bin_addr, norm->host, INET_ADDRSTRLEN);
        return 1;
    }

    /* Normal or utf8 hostname.
     * Whether we need IDN is not important: it also validates.
     */

    uint8_t * idn;
    int idn_rc = idn2_lookup_u8(host, &idn, IDN2_NFC_INPUT);
    if(idn_rc != IDN2_OK) {
        rc     = (char *)idn2_strerror_name(idn_rc);
        errmsg = (char *)idn2_strerror(idn_rc);
        return 0;
    }

    strcpy(norm->host, idn);
    idn2_free(idn);

    return 1;
}

static int normalize_port(url *norm, char *port) {
    if( ! unhex(port)) return 0;

    int portnr = 0;
    while(isdigit(port[0])) {
        portnr = portnr * 10 + *port++ - '0';
    }

    if(port[0] != EOL) {
        rc     = "HIN_PORT_NON_DIGIT";
        errmsg = "The portnumber contains a non-digit";
        return 0;
    }

    if(portnr > MAX_PORT_NUMBER) {
        rc     = "HIN_PORT_NUMBER_TOO_HIGH";
        errmsg = "The portnumber is out of range";
        return 0;
    }

    if(portnr==80 && strcmp(norm->scheme, "http")==0) {
        norm->port[0] = EOL;  /* ignore default for http */
    }
    else
    if(portnr==431 && strcmp(norm->scheme, "https")==0) {
        norm->port[0] = EOL;  /* ignore default for https */
    }
    else {
        sprintf(norm->port, "%d", port);
    }

    return 1;
}

static int normalize_hostport(url *norm, char *host, url *base) {
    if(strlen(host)==0) {
        /* We had auth, but no host or port. */
        strcpy(norm->host, base->host);
        strcpy(norm->port, base->port);
        return 1;
    }

    char *port = NULL;
    if(host[0]=='[') {
        /* IPv6 address.  It contains ':' which may confuse ":port" */
        char *end = strpbrk(host, "]");
        if(!end) {
            rc     = "HIN_IPV6_UNTERMINATED";
            errmsg = "The IPv6 host address is not terminated";
            return 0;
        }

        end++;
        if(end[0]!=EOL && end[0]!=':' && end[0]!='/') {
            rc     = "HIN_IPV6_ENDS_INCORRECTLY";
            errmsg = "The IPv6 host address terminated unexpectedly";
            return 0;
        }

        if(end[0]==':') {
            *end++ = EOL;
            port   = end;
        }
    }
    else
    if(port = index(host, ':')) {
        *port++ = EOL;
    }

    if( !normalize_host(norm, host)) return 0;

    if(port && strlen(port)) {
       if( !normalize_port(norm, port)) return 0;
    }
    else {
       norm->port[0] = EOL;
    }

    return 1;
}

static int resolve_external_address(url *norm, char **relative, url *base) {
    if((*relative)[0]==EOL || (*relative)[0]=='/') {
        /* empty location */
        strcpy(norm->username, base->username);
        strcpy(norm->password, base->password);
        strcpy(norm->host, base->host);
        strcpy(norm->port, base->port);
        return 1;
    }

    char *end = strpbrk(*relative, "@/");
    if(end && end[0]=='@') {
        /* Authorization */
        size_t auth_strlen = end - *relative - 1;
        char   auth[MAX_STORE_PART];

        strncpy(auth, *relative, auth_strlen);
        auth[auth_strlen] = EOL;
        *relative = end +1;

        if( !normalize_authorization(norm, auth, base)) return 0;
        end = index(*relative, '/');
    }
    else {
        /* No authorization, but have something else: no base */
        norm->username[0] = EOL;
        norm->password[0] = EOL;
    }

    char host[MAX_STORE_PART];
    if(end) {
        strncpy(host, *relative, end - *relative);
        *relative = end +1;
    }
    else {
        strcpy(host, *relative);
    }

    if( !normalize_host(norm, host)) return 0;

    return 1;
}

static int normalize_part(char *out, char *part) {
    /* XXX decode hex */
    /* check utf8 bytes */
    /* encode hex which is needed only */
    return 1;
}

static int normalize_path(url *norm, char **path) {
    /* XXX split on / and ;, normalize all parts, rejoin */
    /* remove ./ and ../ */
    return 1;
}

static int normalize_query(url *norm, char *query) {
    /* XXX split on & and =, normalize all parts, rejoin */
    return 1;
}

static int path2abs(url *norm, char **relative, url *base) {
    /* prepend base.path to relative remains */
    return 1;
}

static int normalize(url *norm, char *relative, url *base) {
    char * end;

    if(strlen(relative) > MAX_INPUT) {
        rc     = "HIN_INPUT_TOO_LONG";
        errmsg = "Input url too long.";
        return 0;
    }

    if( !strip_blanks(&relative)) return 0;
    if( !strip_fragment(&relative)) return 0;

    norm->scheme[0] = norm->username[0] = norm->password[0] = norm->host[0] =
    norm->port[0] = norm->path[0] = norm->query[0] = EOL;

    if( !normalize_scheme(norm, &relative, base)) return 0;

    if(relative[0]=='/' && relative[1]=='/') {
        /* Absolute address */
        relative += 2;
        if( !resolve_external_address(norm, &relative, base)) return 0;

        if(relative[0]==EOL) {
            /* Empty path */
            norm->path[0] = '/';
            norm->path[1] = EOL;
            return 1;
        }

        if( !normalize_path(norm, &relative) ) return 0;

        return 1;
    }

    /* Relative address */
    strcpy(norm->username, base->username);
    strcpy(norm->password, base->password);
    strcpy(norm->host, base->host);
    strcpy(norm->port, base->port);

    if(relative[0]==EOL) {
        /* Empty path: take base which is normalized already */
        strcpy(norm->path, base->path);
        strcpy(norm->query, base->query);
        return 1;
    }

    return 1;
}

static void serialize(char *out, url *norm) {
    strcpy(out, norm->scheme);
    strcat(out, "//:");
    if(strlen(norm->username)) {
        strcat(out, norm->username);
    }
    if(strlen(norm->password)) {
        strcat(out, ":");
        strcat(out, norm->password);
    }
    if(strlen(norm->username) || strlen(norm->password)) {
        strcat(out, "@");
    }
    strcat(out, norm->host);
    if(strlen(norm->port)) {
        strcat(out, ":");
        strcat(out, norm->port);
    }
    strcat(out, norm->path);
    if(strlen(norm->query)) {
        strcat(out, "?");
        strcat(out, norm->query);
    }
}

static void answer(url *result) {
    char normalized[MAX_STORE_PART];
    inline_stack_vars;

    serialize(normalized, result);

    if(strlen(rc)==0) errmsg = "";

    inline_stack_reset;
    inline_stack_push(sv_2mortal(newSVpv(rc, PL_na)));
    inline_stack_push(sv_2mortal(newSVpv(errmsg, PL_na)));
    inline_stack_push(sv_2mortal(newSVpv(normalized, PL_na)));
    inline_stack_done;
}

void _set_base(char *b) {
    rc = "";
    if(! normalize(&global_base, b, &default_url)) {
        return;
    }
    answer(&global_base);  /* Usefull for debugging */
}

/* returns a LIST */
void _normalize_url(char *r) {
    url  absolute;

    rc = "";
    if(! normalize(&absolute, r, &global_base)) {
        return;
    }
    answer(&absolute);
}
