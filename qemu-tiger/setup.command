#!/bin/sh
# LEGO Island one-click setup: config + fresh app copy + launch with a log.
DISC="`cd \`dirname "$0"\` && pwd`"
mkdir -p "$HOME/Library/Application Support/isledecomp/isle"
printf '[isle]\ndiskpath = %s/gamedata\ncdpath = %s/gamedata\nFull Screen = false\n' "$DISC" "$DISC" > "$HOME/Library/Application Support/isledecomp/isle/isle.ini"
rm -rf "$HOME/Desktop/isle.app"
cp -R "$DISC/isle.app" "$HOME/Desktop/"
echo "=== launching LEGO Island; log also saved to Desktop/isle-log.txt ==="
"$HOME/Desktop/isle.app/Contents/MacOS/isle" 2>&1 | tee "$HOME/Desktop/isle-log.txt"
