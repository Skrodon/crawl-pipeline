#!/bin/bash
# Generic settings, to be included from all specific profiles.

set -e

umask ug=rwx

# Add the generic programs
PATH+=":$PIPELINE_REPO/bin"

# Add the generic perl5 modules
PERL5LIB+=":$PIPELINE_REPO/perl5/OSF-Package/lib"
PERL5LIB+=":$PIPELINE_REPO/perl5/OSF-WARC/lib"

# Where publications are stored (temporarily)

: ${PUBLISH:=$BIGDISK/publish}
export PUBLISH
