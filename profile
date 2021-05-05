#!/bin/bash
# Generic settings, to be included from all specific profiles.

set -e

if [ -z "$BIGDISK" ]
then echo "You need to set BIGDISK to your bulk store." >&2
     exit 6    # ENXIO
fi

if [ ! -d "$BIGDISK" ]
then echo "BIGDISK '$BIGDISK' does not exist or not a directory." >&2
     exit 2    # ENOENT
fi

: ${BIGTMP:=$BIGDISK/tmp}
[ -d "$BIGTMP" ] || mkdir "$BIGTMP"

umask ug=rwx

#
### TMP directories cleaned-up automagically
#

: ${TMP_HOUR:=$BIGTMP/cache-hour}
[ -d "$TMP_HOUR" ] || mkdir "$TMP_HOUR"

: ${TMP_DAY:=$BIGTMP/cache-day}
[ -d "$TMP_DAY" ] || mkdir "$TMP_DAY"

: ${TMP_MONTH:=$BIGTMP/cache-month}
[ -d "$TMP_MONTH" ] || mkdir "$TMP_MONTH"

: ${LOGS:=$TMP_MONTH/logs}
[ -d "$LOGS" ] || mkdir "$LOGS"

export BIGTMP TMP_HOUR TMP_DAY TMP_MONTH LOGS

#
### Modules
#   Mostly, modules do not need each other, but for some
#   cases we make exceptions.
#

export MODULES="Pipeline CommonCrawl"

for MODULE in $MODULES
do  DIR="$PWD/$MODULE"

    # Needs blib/lib when we start with XS
    for PERL5 in "$DIR"/perl5/*
    do [ -d "$PERL5/lib" ] && PERL5LIB="${PERL5LIB:+$PERL5LIB:}$PERL5/lib"
    done

done

export PERL5LIB

#
###
#

function log() {
    printf "[%s] %s\n" "$(date +'%F %T')" "$*"
}
