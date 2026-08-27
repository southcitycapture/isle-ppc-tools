#!/bin/sh
# Sample the ppc32 "spin": let the game run under qemu's gdbstub for a
# while, then interrupt and print backtraces of wherever it is.
set -e
cd /work/isle

cmake --build build-ppc -j"$(nproc)" > /dev/null

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

qemu-ppc-static -g 1234 ./build-ppc/isle > /work/isle-ppc-spin-game.log 2>&1 &
QPID=$!
sleep 3

set +e
# SIGINT stops the inferior; the remaining batch commands then run.
timeout -s INT 240 gdb-multiarch -batch \
    -ex 'set pagination off' \
    -ex 'file build-ppc/isle' \
    -ex 'target remote localhost:1234' \
    -ex 'continue' \
    -ex 'bt 25' \
    -ex 'echo === second sample ===\n' \
    -ex 'continue&' \
    -ex 'shell sleep 5' \
    -ex 'interrupt' \
    -ex 'shell sleep 1' \
    -ex 'bt 25' \
    2>&1 | tail -60

kill $QPID 2>/dev/null
echo "=== game log tail ==="
tail -6 /work/isle-ppc-spin-game.log
