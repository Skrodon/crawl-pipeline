#!/bin/bash
# Generic settings, to be included from all specific profiles.

set -e

umask ug=rwx

#
### Modules
#   Mostly, modules do not need each other, but for some
#   cases we make exceptions.
#

: ${PROJECTS:="Pipeline CommonCrawl KB-NL.Fryslan LinkCollector"}
export PROJECTS

for PROJECT in $PROJECTS
do  DIR="$PWD/$PROJECT"

    if [ ! -d "$DIR" ]
    then echo "Project $PROJECT is not known: skipped" >&2
         continue
    fi

    # Needs blib/lib when we start with XS
    for PERL5 in "$DIR"/perl5/*
    do [ -d "$PERL5/lib" ] && PERL5LIB="${PERL5LIB:+$PERL5LIB:}$PERL5/lib"
    done

    [ -d "$DIR/bin" ] && PATH="$DIR/bin:$PATH"
done

export PERL5LIB PATH

# Where publications are stored (temporarily)
: ${PUBLISH:=$BIGDISK/publish}
export PUBLISH
