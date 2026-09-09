POWER MAC G4 AS A REMOTE TEST BENCH
===================================
Plan page: https://claude.ai/code/artifact/1ecf1c2a-baba-4a0d-81fc-3c4ce43813f1
Helper:    g4/g4  (put it on your PATH or alias it; see "g4 help")

HOW IT HANGS TOGETHER
---------------------
Mac (anywhere) --Tailscale--> littlejelly --wired LAN--> Power Mac G4

Tiger/Leopard cannot run Tailscale. littlejelly advertises the wired LAN
(192.168.0.0/24) as a Tailscale subnet route, so the Mac reaches the G4's
LAN address from anywhere. On the G4 only the OS's own services are used:
Remote Login (sshd) and VNC (Tiger: Apple Remote Desktop pane; Leopard:
Screen Sharing pane).

DRY RUN RESULTS (2026-09-09, QEMU Tiger 10.4.0 guest, real OpenSSH 3.8.1p1)
-----------------------------------------------------------------------
PROVEN  Mac OpenSSH 10.3 + the SHA-1-era stanza negotiates with Tiger's
        sshd: diffie-hellman-group-exchange-sha1, ssh-rsa host key,
        aes128-ctr/hmac-sha1, publickey auth with id_rsa_g4. Leopard's
        OpenSSH 5.1 speaks the same set, so the stanza carries over.
PROVEN  `screencapture -x` works over SSH as the console user (Tiger has
        no per-session WindowServer isolation). Tiger's screencapture has
        NO -t flag: `-t png` returns 0 and writes nothing. Don't use it.
FOUND   A windowed app launched by a raw SSH exec ABORTS (exit 134,
        "CFMessagePort bootstrap_register failed"): the SSH session is a
        different Mach bootstrap namespace than the console GUI session.
        `open isle.app` reaches the right session but injects a -psn_
        argument that isle's CLI parser rejects ("Invalid CLI arguments").
        => the game is launched by a small RUNNER that lives in the
        console session (g4 install-runner); run/stop hand it a request
        file over SSH. Validated end to end: install-runner, run, stop,
        log, shot, doctor, status.
FOUND   Tiger's sudo 1.6.8 has no -n. The helper uses `sudo -S ... </dev/null`.
NOTED   A log that says "Game started" can still be polygon soup on screen
        (the old pre-meshbuilder-fix binary on the transfer ISO did exactly
        that). End every autonomous pass with `g4 shot`.
UNTESTED  VNC (needs admin in the guest; will be tested on the real G4).

SETUP DAY - ONCE, AT THE G4's KEYBOARD (Phase 1)
------------------------------------------------
Tiger names in [ ]; Leopard equivalents in ( ) where they differ.
[ ] Network: System Preferences > Network > Built-in Ethernet > Configure
    IPv4: Manually. 192.168.0.200, mask 255.255.255.0, router 192.168.0.1,
    DNS 192.168.0.1. Write down the Ethernet ID (MAC).
    TP-Link admin: reserve the address; Access Control: block it from
    the internet.
[ ] Accounts: user "isle", Allow user to administer, Login Options >
    Automatically log in as: isle. (The GUI session must exist after a
    remote power cycle, or nothing can launch the game or serve VNC.)
[ ] Sharing > Services: Remote Login ON. Firewall tab: leave off.
[ ] Sharing: [Apple Remote Desktop ON > Access Privileges > "VNC viewers
    may control screen with password" ON, set a password]
    (Leopard: Screen Sharing ON; Computer Settings > "VNC viewers may
    control screen with password").
[ ] Energy Saver: Computer sleep Never. Options tab: "Restart automatically
    after a power failure" ON, "Wake for Ethernet network administrator
    access" ON.
[ ] Desktop & Screen Saver: screen saver Never.
    Security: no password to wake. Software Update: off.
[ ] Universal Access: "Enable access for assistive devices" ON
    (lets "g4 keys" type into the game via osascript).
[ ] From the Mac:  g4 setup-key           (password once)
                   g4 doctor              (expect sudo: needs a password)
    On the G4:     sudo visudo  ->  add the line
                   isle ALL=(ALL) NOPASSWD: /sbin/reboot, /sbin/shutdown, /usr/sbin/bless
    then in /etc/sshd_config set  PasswordAuthentication no  and
                   sudo kill -HUP `cat /var/run/sshd.pid`
[ ] From the Mac:  g4 install-runner      (writes ~/.g4/runner.sh + a
                                           LaunchAgent; starts at next login)
                   g4 assets && g4 ini && g4 push
                   g4 reboot && g4 wait   (auto-login brings the runner up)
                   g4 doctor              (runner: installed and has run)
                   g4 run && g4 shot
[ ] Prove the remote path BEFORE leaving the room: unplug the Mac from
    the wire, on Wi-Fi or a phone hotspot run
                   g4 status && g4 shot && g4 vnc

THE DAILY LOOP (Phase 2)
------------------------
    tiger/build-tiger.sh             # Mac, Docker cross toolchain
    g4 push-bin && g4 run            # ship the 3 MB executable, runner starts it
    g4 log -f                        # "Detected game version 1.1" ... "Game started"
    g4 shot infocenter               # PNG lands in g4-shots/, look at it
    g4 crash                         # when it dies
    g4 keys "zach" ; g4 key return   # scripted input

A run that never crashes can still draw polygon soup (the meshbuilder
endian bug). End every autonomous pass with a screenshot.

RECOVERY
--------
    g4 reboot && g4 wait             # soft (also restarts the runner)
    g4 power cycle && g4 wait        # hard, once the smart plug exists (Phase 3)
"Restart automatically after a power failure" is what turns the plug
into a reset button. Crash reports append to
~/Library/Logs/CrashReporter/isle.crash.log on the G4; "g4 crash" shows
the last entry.

DRY RUN AGAIN LATER
-------------------
    cd ~/Apps/islandPowerPC/qemu-tiger
    qemu-img create -f qcow2 -b tiger.qcow2 -F qcow2 tiger-lab.qcow2
    ./run-tiger-lab.sh               # monitor.sock + ports 2222/5901 forwarded
    ./mon "mouse_set 3"              # select the usb-tablet (a relative HID
                                     #   mouse is also present and wins by default)
    Spotlight (./keys meta_l-spc) -> ./kbd Terminal -> ./keys down ret
    ./kbd 'curl -s 10.0.2.2:8765/agent.sh | sh' ; ./keys ret   # bridge agent
    Remote Login needs the guest admin password; without it, run a user-
    space sshd as the console user on 2022 and ./mon "hostfwd_add tcp::2223-:2022"
    (Host tiger-lab in ~/.ssh/config), then G4_HOST=tiger-lab g4 doctor.
