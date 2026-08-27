#!/bin/sh
# QEMU Mac OS X Tiger guest for isle.app testing.
# Usage: ./run-tiger.sh install   (boot the Tiger installer DVD)
#        ./run-tiger.sh           (boot the installed system + transfer ISO)
DIR="$(cd "$(dirname "$0")" && pwd)"
DISK="$DIR/tiger.qcow2"
INSTALLER="$DIR/tiger-install.iso"

[ -f "$DISK" ] || qemu-img create -f qcow2 "$DISK" 16G

if [ "$1" = "install" ]; then
    exec qemu-system-ppc -M mac99,via=pmu -cpu g4 -m 1024 \
        -drive file="$DISK",if=none,id=hd,format=qcow2 -device ide-hd,drive=hd,bus=ide.0 \
        -drive file="$INSTALLER",if=none,id=cd,format=raw,media=cdrom -device ide-cd,drive=cd,bus=ide.1 \
        -g 1024x768x32 -boot d
else
    exec qemu-system-ppc -M mac99,via=pmu -cpu g4 -m 1024 \
        -drive file="$DISK",if=none,id=hd,format=qcow2 -device ide-hd,drive=hd,bus=ide.0 \
        -drive file="$DIR/isle-transfer.iso",if=none,id=cd,format=raw,media=cdrom -device ide-cd,drive=cd,bus=ide.1 \
        -g 1024x768x32 -boot c
fi
