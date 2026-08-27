LEGO ISLAND ON THE G4 — WEEKEND KIT
====================================
Build: 2026-08-27 "round 13" (all 14 Tiger fixes; validated end-to-end
in a QEMU Tiger guest: intro, Infocenter, registration, open island).

WHAT'S IN THE BUNDLE
--------------------
isle.app                      self-contained PPC binary (Tiger 10.4+)
  Contents/Frameworks/        libSDL2-2.0.0.dylib — SDL 2.0.3 built FOR
                              TIGER from panther-sdl2 (the old Leopard
                              dylib can never load on 10.4: it needs
                              $UNIX2003 symbols Tiger doesn't have)

SETUP ON THE G4
---------------
1. Copy isle.app anywhere (Desktop is fine).
2. Copy the game assets (gamedata/ from the Pi share) somewhere local,
   e.g. /Users/you/gamedata  — running from a mounted share also works.
3. Create the config (Terminal):

   mkdir -p ~/Library/Application\ Support/isledecomp/isle
   printf '[isle]\ndiskpath = /Users/you/gamedata\ncdpath = /Users/you/gamedata\nFull Screen = false\n' \
     > ~/Library/Application\ Support/isledecomp/isle/isle.ini

4. First run from Terminal so the log is visible:

   ~/Desktop/isle.app/Contents/MacOS/isle 2>&1 | tee ~/Desktop/isle-log.txt

WHAT TO EXPECT
--------------
- The Radeon 9000 does real OpenGL: full-speed rendering, movies, the
  works. QEMU's slideshow pace was software GL only.
- AUDIO PLAYS FOR THE FIRST TIME on this machine — the VM had no sound
  device (a silent-sink shim kept the game paced). If the audio device
  fails, the game still runs silently and says so in the log.
- "Detected game version 1.1" and "Game started" in the log = healthy.

KNOWN QUIRKS (as of this build)
-------------------------------
- QUIT CRASHES: closing the window trips a texture double-release in
  shutdown. Harmless (game is over anyway) but expect a crash report.
- Registration-book letters may not draw on slow streaming; the click
  targets still work, and the name registers.
- If the screen ever parks on empty sky after a transition: press ESC —
  it returns to the Infocenter. (Only ever seen under emulation.)
- Fullscreen movies show under the OpenGL renderer (default). The
  paletted software renderer skips them; only use it if GL misbehaves:
   add this line to isle.ini:  3D Device ID = 0 0x682656f3 0x0 0x0 0x7

IF SDL2 WON'T LOAD
------------------
The loader searches Contents/Frameworks first and prints per-path
dlerror reasons on failure. Override with:
   SDL3ON2_SDL2_PATH=/path/to/libSDL2-2.0.0.dylib ./isle.app/Contents/MacOS/isle

DIAGNOSTICS
-----------
- Game log: whatever you tee'd above.
- Crash reports: ~/Library/Logs/CrashReporter/isle.crash.log (appends;
  read the LAST entry).
- A hang can be profiled live: /usr/bin/sample isle 10

SOURCES
-------
https://github.com/southcitycapture/isle-portable   (branch ppc-endian-phase1)
https://github.com/southcitycapture/sdl3on2         (SDL3-on-SDL2 shim)
https://github.com/southcitycapture/panther-sdl2    (Tiger SDL 2.0.3 patches)
