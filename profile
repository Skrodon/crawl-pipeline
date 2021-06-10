#!/bin/bash
# Generic settings, to be included from all specific profiles.

set -e

umask ug=rwx

# Add the generic programs
export PATH="$PATH:$PIPELINE_REPO/bin"

# Add the generic perl5 modules
export PERL5LIB="$PERL5LIB:$PIPELINE_REPO/perl5/OSF-Package/lib:$PIPELINE_REPO/perl5/OSF_WARC/lib"

# Where publications are stored (temporarily)

: ${PUBLISH:=$BIGDISK/publish}
export PUBLISH
