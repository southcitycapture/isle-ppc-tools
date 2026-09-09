# isle-ppc-tools

Build rigs, toolchain files, and debug infrastructure for porting
[isle-portable](https://github.com/isledecomp/isle-portable) — the portable
LEGO Island (1997) decompilation — to big-endian PowerPC Macs:
Mac OS X Tiger first, Mac OS 9 someday.

The port itself lives in three repos:

| Repo | What |
|---|---|
| [southcitycapture/isle-portable](https://github.com/southcitycapture/isle-portable) | game fork, branch `ppc-endian-phase1` — endianness work + Tiger fixes |
| [southcitycapture/sdl3on2](https://github.com/southcitycapture/sdl3on2) | SDL3-subset shim over SDL2, for platforms where SDL3 cannot exist |
| [southcitycapture/panther-sdl2](https://github.com/southcitycapture/panther-sdl2) | SDL 2.0.3 Tiger backport, patched to build with GNU GCC cross-compilers |

No game assets, OS images, or built binaries are included here — bring your
own LEGO Island 1.1 disc and your own Apple installers.

## Layout

### `tiger/` — cross-compiling for Mac OS X Tiger

Runs inside the
[`gcc-powerpc-apple-darwin8`](https://github.com/VariantXYZ/gcc-powerpc-apple-darwin8)
Docker image (GCC 14.2 + MacOSX10.4u SDK).

- `powerpc-apple-darwin8.cmake` — the toolchain file. The hard-won parts:
  linker flags via `*_LINKER_FLAGS_INIT` **strings**, `CMAKE_FIND_FRAMEWORK
  FIRST` (`ONLY` breaks CMake's own `find_file`), `-mone-byte-bool`
  (Darwin PPC C `bool` is 4 bytes), static `libatomic` via
  `CMAKE_CXX_STANDARD_LIBRARIES` (ppc32 lacks 64-bit atomics),
  `-static-libstdc++ -static-libgcc` (no GCC runtime dylibs on a stock G4).
- `build-tiger.sh` — configures and builds isle-portable + the shim.
  Expects mounts: `/work/isle`, `/work/sdl3on2`, `/work/tiger`.
- `build-sdl2-tiger.sh` — cross-builds panther-sdl2 into a Tiger-native
  `libSDL2-2.0.0.dylib` (ppc_7400, links against Tiger's libSystem 88.x).

The shim compiles against SDL2 headers; a 2.0.22 header checkout needs two
local patches for this toolchain: neuter the 10.6 availability guard in
`SDL_platform_defines.h`-adjacent headers, and gate `memset_pattern4` off
for ppc (it appeared in 10.5). `build-tiger.sh` points at that tree via
`SDL3ON2_SDL2_INCLUDE_DIR`.

### `be-test/` — big-endian validation on Linux

Docker rig (see `Dockerfile`) with qemu-user for 32-bit PowerPC and s390x,
cross toolchains, Xvfb, and gdb-multiarch. The `run-*.sh` scripts cover
console/dummy-video soaks, LE control runs, syscall tracing, and gdbstub
attach. Hard lesson encoded here: **a headless soak validates
crash-freedom, not pixels** — the mesh-builder endian bug rendered garbage
geometry through months of "passing" runs. Screenshot your frames.

### `qemu-tiger/` — a Tiger guest as a test bench

- `run-tiger.sh` — QEMU mac99/G4 guest (`install` mode boots the installer
  DVD; default boots the installed disk with a transfer ISO inserted).
- `setup.command` — double-clickable in the guest: writes `isle.ini`,
  copies the app off the transfer disc, launches with a log.
- `bridge.py` + `gx` — the fast iteration loop. The host runs `bridge.py`
  (HTTP on :8765); the guest runs
  `curl -s 10.0.2.2:8765/agent.sh | sh`
  in a Terminal, which polls for commands. Then `gx 'any shell command'`
  on the host executes it in the guest: push fresh binaries
  (`curl -o ... 10.0.2.2:8765/serve/isle`), pull logs and crash reports,
  run `/usr/bin/sample` on hangs — no ISO rebuilds, no VM typing.
  Paths at the top of `bridge.py` are machine-specific; adjust.

Guest-side launch idiom that survives the agent's Ctrl+C:

    ( sh -c "trap \"\" INT HUP; exec ./isle.app/Contents/MacOS/isle" > isle-log.txt 2>&1 & )

### `g4-weekend/` — real-hardware kit notes

`README-WEEKEND.txt` — setup steps, expectations, and known quirks for the
first run on the Power Mac G4 Quicksilver.

### `g4/` — the real G4 as a remote test bench

Everything needed to work on the Power Mac from anywhere once it sits on
the wired LAN next to an always-on Linux box that is also on Tailscale.

- `g4` — the helper. `g4 push`, `g4 run`, `g4 log -f`, `g4 shot`, `g4 crash`,
  `g4 keys`, `g4 reboot`, `g4 power cycle` … all short SSH one-liners against
  Tiger's own Remote Login. `g4 doctor` prints the negotiated SSH algorithms
  and checks sudo, VNC, screencapture, assets. Config via `~/.config/g4/config`
  (see `config.example`); point `G4_HOST=tiger-vm` at the QEMU guest for a dry run.
- `setup-g4-route.sh` — run with sudo on the hub to advertise the wired LAN as a
  Tailscale subnet route (Tiger cannot run Tailscale, so the hub is the door).
- `README-G4.txt` — the one-time keyboard checklist for setup day, the daily
  loop, and recovery.

The Mac's `~/.ssh/config` needs the SHA-1-era algorithms Tiger's OpenSSH
3.8/4.5 speaks (`KexAlgorithms +diffie-hellman-group-exchange-sha1,…`,
`HostKeyAlgorithms +ssh-rsa`, `PubkeyAcceptedAlgorithms +ssh-rsa`) and an RSA
key; the stanza is in `README-G4.txt`.
