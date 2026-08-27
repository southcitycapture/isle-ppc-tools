#!/bin/sh
# Build isle-portable for big-endian s390x and smoke-test it under qemu-user.
# Usage: run inside the be-test container with the repo mounted at /work/isle
# and the game assets at /work/gamedata.
set -e

cd /work/isle
cmake -S . -B build-s390x -G Ninja \
    --toolchain /work/be-test/s390x-toolchain.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DISLE_WERROR=OFF \
    -DISLE_BUILD_CONFIG=OFF \
    -DISLE_EXTENSIONS=OFF \
    -DISLE_USE_LWS=OFF \
    -DDOWNLOAD_DEPENDENCIES=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DSDL_X11_XTEST=OFF
cmake --build build-s390x -j"$(nproc)"

file build-s390x/isle || true

# Headless smoke test: dummy video/audio, software renderer.
mkdir -p /root/.local/share/isledecomp/isle
cat > /root/.local/share/isledecomp/isle/isle.ini <<EOF
[isle]
diskpath = /work/gamedata
cdpath = /work/gamedata
Full Screen = false
EOF

# X11 is endian-independent on the wire: the amd64 Xvfb serves the s390x game.
Xvfb :99 -screen 0 640x480x24 +extension GLX &
sleep 2
export DISPLAY=:99
export SDL_AUDIODRIVER=dummy
export QEMU_LD_PREFIX=/usr/s390x-linux-gnu
timeout 300 qemu-s390x-static ./build-s390x/isle 2>&1 | tee /work/isle-be-run.log || true

grep -q "Game started" /work/isle-be-run.log && echo "BE SMOKE TEST: game started OK" || echo "BE SMOKE TEST: FAILED (no 'Game started' in log)"
