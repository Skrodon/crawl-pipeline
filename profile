#!/bin/bash
# Generic settings, to be included from all specific profiles.

set -e

umask ug=rwx

# Add the generic programs
PATH+=":$PIPELINE_REPO/bin"

# Add the generic perl5 modules
PERL5LIB+=":$PIPELINE_REPO/perl5/OSF-Package/lib"
PERL5LIB+=":$PIPELINE_REPO/perl5/OSF-WARC/lib"

# Nearly everyone needs this
PERL5LIB+=":$PIPELINE_REPO/Pipeline/perl5/OSF-HTML/lib"
PERL5LIB+=":$PIPELINE_REPO/Pipeline/perl5/OSF-Pipeline/lib"
export PERL5LIB

# Where publications are stored (temporarily)

: ${PUBLISH:=$BIGDISK/publish}
export PUBLISH
