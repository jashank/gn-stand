#!/bin/sh
# gnstand-update.sh: magic to update standalone GN build
# Jashank Jeremy <jashank@rulingia.com>

set -e

cd gn.stand

if [ X$CR = 'X' ]
then
    echo "\$CR unset, assuming you have depot_tools in your path."
    echo "If download_from_google_storage fails, set \$CR to the directory containing depot_tools."
fi

cr_trunk=http://src.chromium.org/chrome/trunk
target_rev=289113

### Update the necessary bits of Cr sources.
(cd base && svn up -r $target_rev )

# build and buildtools
(cd build && svn up -r $target_rev )
(cd buildtools && git pull )

# testing
(cd testing && \
    svn up -r $target_rev && \
    (cd gtest && svn up) && \
    (cd gmock && svn up) )

# third_party
(cd third_party && \
    svn up -r $target_rev &&
    cd icu && svn up -r $target_rev )

# tools
(cd tools && svn up -r $target_rev )

python2 build/util/lastchange.py -o build/util/LASTCHANGE

DFGS=download_from_google_storage
if [ X$CR != 'X' ]
then
    DFGS=$CR/depot_tools/download_from_google_storage
fi

$DFGS --no_resume --no_auth --bucket chromium-gn \
    --platform=linux\* -s buildtools/linux64/gn.sha1
$DFGS --no_resume --no_auth --bucket chromium-gn \
    --platform=darwin -s buildtools/mac/gn.sha1
$DFGS --no_resume --no_auth --bucket chromium-gn \
    --platform=linux\* -s buildtools/linux32/gn.sha1
