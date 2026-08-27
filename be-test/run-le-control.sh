#!/bin/sh
# Control experiment: identical build/run on little-endian amd64 (native).
# If this also fails headless, the BE failure is environmental, not endian.
set -e

cd /work/isle
cmake -S . -B build-amd64 -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DISLE_WERROR=OFF \
    -DISLE_BUILD_CONFIG=OFF \
    -DISLE_EXTENSIONS=OFF \
    -DISLE_USE_LWS=OFF \
    -DDOWNLOAD_DEPENDENCIES=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DSDL_UNIX_CONSOLE_BUILD=ON \
    -DSDL_LIBUDEV=OFF
cmake --build build-amd64 -j"$(nproc)"

mkdir -p /root/.local/share/isledecomp/isle
cat > /root/.local/share/isledecomp/isle/isle.ini <<EOF
[isle]
diskpath = /work/gamedata
cdpath = /work/gamedata
Full Screen = false
EOF

export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy
export SDL_LOGGING="*=verbose"
timeout 120 ./build-amd64/isle 2>&1 | tee /work/isle-le-control.log
echo "exit: $?"
grep -q "Game started" /work/isle-le-control.log && echo "LE CONTROL: game started OK" || echo "LE CONTROL: did not start"
