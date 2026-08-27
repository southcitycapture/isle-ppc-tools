# Big-endian smoke-test rig for isle-portable (Phase 1 validation).
# Cross-compiles for s390x (big-endian) at native speed inside an amd64
# container, then runs the game under qemu-user emulation.
FROM --platform=linux/amd64 debian:trixie

RUN dpkg --add-architecture s390x && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential cmake ninja-build git ca-certificates pkg-config \
        g++-s390x-linux-gnu g++-powerpc-linux-gnu \
        qemu-user-static \
        xvfb gdb-multiarch \
        libx11-dev:s390x libxext-dev:s390x libxrandr-dev:s390x \
        libxcursor-dev:s390x libxi-dev:s390x libxfixes-dev:s390x \
        libxss-dev:s390x libgl-dev:s390x libglx-dev:s390x libgl1:s390x \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
COPY s390x-toolchain.cmake /work/s390x-toolchain.cmake
