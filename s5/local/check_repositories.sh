#!/bin/bash

#
# This script checks whether all source code repositories needed for 
# preparing custom models are alreadydownloaded to the specified 
# output or not. Those repositories not found are downloaded to the
# specified output.
#
# Usage: check_repositories.sh <output directory>
#

if [ $# != 2 ]; then
    echo "Check all repositories are ready on a specified output folder."
    echo
    echo "Wrong #arguments ($#, expected 2)"
    echo "Usage: check_repositories.sh <output-dir> <kaldi-tools-dir>"
    exit 1;
fi

outdir=$1
LEXI=$outdir/lexiconator
CTMATOR=$outdir/ctmator
CHECK_DUR=$outdir/check_duration_audio_files
[ ! -d $LEXI ] && git clone https://github.com/cristiantg/lexiconator $LEXI
[ ! -d $CTMATOR ] && git clone https://github.com/cristiantg/ctmator $CTMATOR
[ ! -d $CHECK_DUR ] && git clone https://github.com/cristiantg/check_duration_audio_files $CHECK_DUR
SRILM=$outdir/srilm.zip
[ ! -d $2/srilm/bin ] && $2/install_srilm.sh pepe pepeorg pepe@thefrog.com
# Alternative:
## wget -O srilm-1.7.3.tar.gz https://github.com/weimeng23/SRILM/raw/master/srilm-1.7.3.tar.gz