#!/bin/sh
# Cross-build panther-sdl2 (SDL 2.0.3 backport) for Mac OS X Tiger PowerPC.
# Runs inside the gcc-powerpc-apple-darwin8 container with
#   /work/panther-sdl2 -> the panther-sdl2 checkout
set -e
export MACOSX_DEPLOYMENT_TARGET=10.4
cd /work/panther-sdl2
mkdir -p build-tiger && cd build-tiger
../configure --host=powerpc-apple-darwin8 --build=x86_64-pc-linux-gnu \
  --without-x --disable-joystick --disable-haptic --disable-altivec \
  --prefix=/work/panther-sdl2/build-tiger/prefix \
  CC=powerpc-apple-darwin8-gcc \
  CFLAGS="-O2 -std=gnu89 -fcommon -mone-byte-bool -maltivec -fobjc-exceptions" \
  OBJCFLAGS="-O2 -fcommon -mone-byte-bool -maltivec -fobjc-exceptions"
make -j"$(nproc)"
make install
echo "=== BUILD OK ==="
ls -la prefix/lib/
