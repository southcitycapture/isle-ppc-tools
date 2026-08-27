#!/bin/sh
# Little-endian control under the same Xvfb rig as the s390x test.
set -e
cd /work/isle

cmake -S . -B build-amd64 -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DISLE_WERROR=OFF \
    -DISLE_BUILD_CONFIG=OFF \
    -DISLE_EXTENSIONS=OFF \
    -DISLE_USE_LWS=OFF \
    -DDOWNLOAD_DEPENDENCIES=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DSDL_X11_XTEST=OFF \
    -DSDL_LIBUDEV=OFF
cmake --build build-amd64 -j"$(nproc)"

mkdir -p /root/.local/share/isledecomp/isle
cat > /root/.local/share/isledecomp/isle/isle.ini <<EOF
[isle]
diskpath = /work/gamedata
cdpath = /work/gamedata
Full Screen = false
EOF

Xvfb :99 -screen 0 640x480x24 +extension GLX &
sleep 2
export DISPLAY=:99
export SDL_AUDIODRIVER=dummy

set +e
timeout 240 ./build-amd64/isle > /work/isle-le2.log 2>&1
echo "exit: $?"
tail -10 /work/isle-le2.log
grep -q "Game started" /work/isle-le2.log && echo "LE CONTROL (X11): game started OK" || echo "LE CONTROL (X11): did not start"
