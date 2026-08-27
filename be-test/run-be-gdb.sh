#!/bin/sh
# Build s390x with symbols and capture a backtrace of the crash via qemu's
# gdbstub + gdb-multiarch.
set -e
cd /work/isle

cmake -S . -B build-s390x-nogl -G Ninja \
    --toolchain /work/be-test/s390x-toolchain.cmake \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_CXX_FLAGS=-fstack-protector-all \
    -DCMAKE_C_FLAGS=-fstack-protector-all \
    -DISLE_WERROR=OFF \
    -DISLE_BUILD_CONFIG=OFF \
    -DISLE_EXTENSIONS=OFF \
    -DISLE_USE_LWS=OFF \
    -DDOWNLOAD_DEPENDENCIES=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DSDL_X11_XTEST=OFF \
    -DCMAKE_DISABLE_FIND_PACKAGE_OpenGL=TRUE
cmake --build build-s390x-nogl -j"$(nproc)"

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
export QEMU_LD_PREFIX=/usr/s390x-linux-gnu
export MALLOC_CHECK_=3
export MALLOC_PERTURB_=165

timeout 600 qemu-s390x-static -g 1234 ./build-s390x-nogl/isle > /work/isle-be-gdb-game.log 2>&1 &
sleep 3

timeout 590 gdb-multiarch -batch \
    -ex 'set pagination off' \
    -ex 'set architecture s390:64-bit' \
    -ex 'file build-s390x-nogl/isle' \
    -ex 'target remote localhost:1234' \
    -ex 'continue' \
    -ex 'bt 30' \
    -ex 'info registers' \
    2>&1 | tail -60

echo "=== game log tail ==="
tail -15 /work/isle-be-gdb-game.log
