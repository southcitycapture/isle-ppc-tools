#!/bin/sh
# THE test that matters: 32-bit big-endian PowerPC (the G4's byte order and
# word size), console-only SDL, dummy video -- no X11, no Mesa, no GL.
set -e
cd /work/isle

cmake -S . -B build-ppc -G Ninja \
    --toolchain /work/be-test/powerpc-toolchain.cmake \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DISLE_WERROR=OFF \
    -DISLE_BUILD_CONFIG=OFF \
    -DISLE_EXTENSIONS=OFF \
    -DISLE_USE_LWS=OFF \
    -DDOWNLOAD_DEPENDENCIES=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DSDL_UNIX_CONSOLE_BUILD=ON \
    "-DCMAKE_CXX_STANDARD_LIBRARIES=-latomic"
cmake --build build-ppc -j"$(nproc)"

mkdir -p /root/.local/share/isledecomp/isle
cat > /root/.local/share/isledecomp/isle/isle.ini <<INI
[isle]
diskpath = /work/gamedata
cdpath = /work/gamedata
Full Screen = false
INI

export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy
export QEMU_LD_PREFIX=/usr/powerpc-linux-gnu

set +e
timeout 5400 qemu-ppc-static ./build-ppc/isle > /work/isle-ppc-run.log 2>&1
echo "game exit: $?"
tail -12 /work/isle-ppc-run.log
grep -q "Game started" /work/isle-ppc-run.log && echo "PPC BE SMOKE TEST: game started OK" || echo "PPC BE SMOKE TEST: FAILED"
