#!/bin/sh
# Cross-build isle-portable + sdl3on2 for Mac OS X Tiger PowerPC.
# Runs inside the gcc-powerpc-apple-darwin8 container with:
#   /work/isle      -> isle-portable checkout
#   /work/sdl3on2   -> the shim
#   /work/tiger     -> this directory (toolchain file, SDL2 headers)
set -e

apk add cmake ninja git 2>/dev/null || (apt-get update -q && apt-get install -y -q cmake ninja-build git) 2>/dev/null || true

cd /work/isle
cmake -S . -B build-tiger -G Ninja \
    --toolchain /work/tiger/powerpc-apple-darwin8.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DISLE_WERROR=OFF \
    -DISLE_BUILD_CONFIG=OFF \
    -DISLE_EXTENSIONS=OFF \
    -DISLE_USE_LWS=OFF \
    -DISLE_RENDERER_SDLGPU=OFF \
    -DISLE_RENDERER_SOFTWARE=OFF \
    -DDOWNLOAD_DEPENDENCIES=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DFETCHCONTENT_SOURCE_DIR_SDL3=/work/sdl3on2 \
    -DSDL3ON2_SDL2_INCLUDE_DIR=/work/tiger/include-parent
cmake --build build-tiger -j"$(nproc)" --target isle
/usr/local/bin/powerpc-apple-darwin8-otool -hv build-tiger/isle | head -4
