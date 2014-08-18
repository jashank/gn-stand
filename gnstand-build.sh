#!/bin/sh
# gnstand-build.sh: magic to build a standalone GN
# Jashank Jeremy <jashank@rulingia.com>

set -e

cd gn.stand

if [ `uname -s` = 'Linux' ]
then
    if [ `uname -m` = 'x86_64' ]
    then
	GN=buildtools/linux64/gn
    elif [ `uname -m` = 'i386' ]
    then
	GN=buildtools/linux32/gn
    else
	echo "=== unsupported architecture!"
    fi
elif [ `uname -s` = 'Darwin' ]
then
    GN=buildtools/mac/gn
else
    echo "=== unsupported OS!"
fi

# Notes: 
#
# - force !Clang because this depends on in-tree LLVM and other magic;
#
# - force GCC to use ld.gold, not ld.bfd;

# Use buildtools GN to build a bootstrap version
$GN gen --args='is_clang=false' out/GNBoot && \
    sed -i.bak -e 's/g++ \$ldflags/g++ -fuse-ld=gold \$ldflags/' \
               -e 's/g++ -shared/g++ -fuse-ld=gold -shared/' out/GNBoot/toolchain.ninja && \
    ninja -C out/GNBoot gn -j 15

# Use bootstrapped GN to build GN
out/GNBoot/gn gen --args='is_clang=false' out/GNStrap && \
    sed -i.bak -e 's/g++ \$ldflags/g++ -fuse-ld=gold \$ldflags/' \
               -e 's/g++ -shared/g++ -fuse-ld=gold -shared/' out/GNStrap/toolchain.ninja && \
    ninja -C out/GNStrap gn -j 15

# Use built GN to build GN
out/GNStrap/gn gen --args='is_clang=false' out/GNStand && \
    sed -i.bak -e 's/g++ \$ldflags/g++ -fuse-ld=gold \$ldflags/' \
               -e 's/g++ -shared/g++ -fuse-ld=gold -shared/' out/GNStand/toolchain.ninja && \
    ninja -C out/GNStand gn gn_unittests -j 15

out/GNStand/gn_unittests

# if we've gotten this far, it worked
