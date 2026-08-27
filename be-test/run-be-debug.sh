#!/bin/sh
# Syscall-trace the s390x debug build up to the crash: shows the last file
# reads before the segfault, localizing the mis-parsed stream.
set -e
cd /work/isle

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

set +e
timeout 300 qemu-s390x-static -strace ./build-s390x-dbg/isle > /work/isle-be-game.log 2> /work/isle-be-strace.log
echo "exit: $?"
echo "=== last game log lines ==="
tail -8 /work/isle-be-game.log
echo "=== last syscalls (reads/opens only) ==="
grep -E "openat|read|pread|lseek|mmap.*\.SI|\.WDB|\.DTA" /work/isle-be-strace.log | tail -30
echo "=== raw strace tail ==="
tail -15 /work/isle-be-strace.log
