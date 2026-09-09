POWER MAC G4 AS A REMOTE TEST BENCH
===================================
Plan page: https://claude.ai/code/artifact/1ecf1c2a-baba-4a0d-81fc-3c4ce43813f1
Helper:    g4/g4  (put it on your PATH or alias it; see "g4 help")

HOW IT HANGS TOGETHER
---------------------
Mac (anywhere) --Tailscale--> littlejelly --wired LAN--> Power Mac G4 (Tiger)

Tiger cannot run Tailscale. littlejelly advertises the wired LAN
(192.168.0.0/24) as a Tailscale subnet route, so the Mac reaches the G4's
LAN address from anywhere. On the G4 only Tiger's own services are used:
Remote Login (sshd) and Apple Remote Desktop (VNC).

BEFORE THE G4 EXISTS (Phase 0)
------------------------------
littlejelly:  sudo sh ~/setup-g4-route.sh        (staged there already)
              then approve the route in the Tailscale admin console and
              turn on "Use Tailscale subnets" in the Mac's Tailscale menu.
Mac:          ~/.ssh/config has Host g4 / tiger-vm / littlejelly stanzas
              with the SHA-1-era algorithms Tiger's sshd needs, and
              ~/.ssh/id_rsa_g4 (RSA; Tiger cannot verify ed25519).
Dry run:      boot a throwaway overlay of the QEMU Tiger guest with
                -nic user,model=sungem,hostfwd=tcp::2222-:22,hostfwd=tcp::5901-:5900
              turn on Remote Login + ARD VNC in the guest, then
                G4_HOST=tiger-vm G4_VNC=localhost:5901 g4 doctor
              That settles: SSH negotiation, screencapture over SSH,
              launching the game from SSH, and VNC from Screen Sharing.

SETUP DAY - ONCE, AT THE G4's KEYBOARD (Phase 1)
------------------------------------------------
[ ] Network: System Preferences > Network > Built-in Ethernet > Configure
    IPv4: Manually. 192.168.0.200, mask 255.255.255.0, router 192.168.0.1,
    DNS 192.168.0.1. Write down the Ethernet ID (MAC).
    TP-Link admin: reserve the address; Access Control: block it from
    the internet.
[ ] Accounts: user "isle", Allow user to administer, Login Options >
    Automatically log in as: isle. (The GUI session must exist after a
    remote power cycle, or nothing can launch the game or serve VNC.)
[ ] Sharing > Services: Remote Login ON. Firewall tab: leave off.
[ ] Sharing > Services: Apple Remote Desktop ON > Access Privileges >
    "VNC viewers may control screen with password" ON, set a password.
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
[ ] From the Mac:  g4 assets && g4 ini && g4 push && g4 run && g4 shot
[ ] Prove the remote path BEFORE leaving the room: unplug the Mac from
    the wire, on Wi-Fi or a phone hotspot run
                   g4 status && g4 shot && g4 vnc

THE DAILY LOOP (Phase 2)
------------------------
    tiger/build-tiger.sh             # Mac, Docker cross toolchain
    g4 push-bin && g4 run            # ship the 3 MB executable, start it
    g4 log -f                        # "Detected game version 1.1" ... "Game started"
    g4 shot infocenter               # PNG lands in g4-shots/, look at it
    g4 crash                         # when it dies
    g4 keys "zach" ; g4 key return   # scripted input

A run that never crashes can still draw polygon soup (the meshbuilder
endian bug). End every autonomous pass with a screenshot.

RECOVERY
--------
    g4 reboot && g4 wait             # soft
    g4 power cycle && g4 wait        # hard, once the smart plug exists (Phase 3)
Tiger's "Restart automatically after a power failure" is what turns the
plug into a reset button. Crash reports append to
~/Library/Logs/CrashReporter/isle.crash.log on the G4; "g4 crash" shows
the last entry.
