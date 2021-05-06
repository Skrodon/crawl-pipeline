#!/bin/bash
# Generic settings, to be included from all specific profiles.

set -e

umask ug=rwx

#
### Modules
#   Mostly, modules do not need each other, but for some
#   cases we make exceptions.
#

: ${MODULES:="Pipeline CommonCrawl KB-NL.Fryslan"}
export MODULES

for MODULE in $MODULES
do  DIR="$PWD/$MODULE"

    # Needs blib/lib when we start with XS
    for PERL5 in "$DIR"/perl5/*
    do [ -d "$PERL5/lib" ] && PERL5LIB="${PERL5LIB:+$PERL5LIB:}$PERL5/lib"
    done

    [ -d "$DIR/bin" ] && PATH="$DIR/bin:$PATH"
done

export PERL5LIB PATH

# Where publication are stored (temporarily)
: ${PUBLISH:=$BIGDISK/publish}
export PUBLISH

#
###
#

function log() { printf "[%s] %s\n" "$(date +'%F %T')" "$*"; }
