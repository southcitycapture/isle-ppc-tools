#!/usr/bin/env python3
# Guest<->host command bridge for the QEMU Tiger VM.
#
# The guest runs a tiny poll loop (agent.sh). The host queues shell
# commands via POST /submit and reads results via GET /read. The guest
# fetches the next command via GET /poll and posts output to PUT /out.
# Files can be served to the guest (GET /serve/<name>) and uploaded from
# it (PUT /up/<name>).
import os, threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

BASE = "/Users/zachjack/Apps/islandPowerPC/qemu-tiger"
SERVE_DIR = os.path.join(BASE, "serve")
UP_DIR = os.path.join(BASE, "from-guest")
os.makedirs(SERVE_DIR, exist_ok=True)
os.makedirs(UP_DIR, exist_ok=True)

LOCK = threading.Lock()
S = {"cmd_id": 0, "cmd": b"", "sent_id": 0, "out_id": -1, "out": b""}


class H(BaseHTTPRequestHandler):
    def _send(self, code, body=b"", ctype="text/plain"):
        if isinstance(body, str):
            body = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    def _read_body(self):
        n = int(self.headers.get("Content-Length", 0))
        return self.rfile.read(n) if n else b""

    def do_GET(self):
        u = urlparse(self.path)
        p = u.path
        if p == "/poll":
            with LOCK:
                if S["cmd_id"] > S["sent_id"]:
                    S["sent_id"] = S["cmd_id"]
                    self._send(200, b"%d\n" % S["cmd_id"] + S["cmd"])
                else:
                    self._send(200, b"")
            return
        if p == "/read":
            q = parse_qs(u.query)
            want = int(q.get("id", ["0"])[0])
            with LOCK:
                if S["out_id"] >= want:
                    self._send(200, S["out"])
                else:
                    self._send(202, b"")
            return
        if p == "/agent.sh":
            self._send(200, AGENT, "text/plain")
            return
        if p.startswith("/serve/"):
            fn = os.path.join(SERVE_DIR, os.path.basename(p))
            if os.path.isfile(fn):
                with open(fn, "rb") as f:
                    self._send(200, f.read(), "application/octet-stream")
            else:
                self._send(404, b"not found\n")
            return
        self._send(404, b"?\n")

    def do_POST(self):
        if urlparse(self.path).path == "/submit":
            body = self._read_body()
            with LOCK:
                S["cmd_id"] += 1
                S["cmd"] = body
                cid = S["cmd_id"]
            self._send(200, str(cid))
            return
        self._send(404, b"?\n")

    def do_PUT(self):
        p = urlparse(self.path).path
        body = self._read_body()
        if p == "/out":
            nl = body.find(b"\n")
            with LOCK:
                S["out_id"] = int(body[:nl])
                S["out"] = body[nl + 1:]
            self._send(201, b"ok\n")
            return
        if p.startswith("/up/"):
            fn = os.path.join(UP_DIR, os.path.basename(p))
            with open(fn, "wb") as f:
                f.write(body)
            self._send(201, b"ok\n")
            return
        self._send(404, b"?\n")

    def log_message(self, *a):
        pass


AGENT = b"""#!/bin/sh
echo "=== sdl3on2 guest agent live; host is driving. Ctrl-C to stop. ==="
while :; do
  R=`curl -s http://10.0.2.2:8765/poll`
  if [ -n "$R" ]; then
    ID=`echo "$R" | head -1`
    echo "$R" | sed 1d > /tmp/cmd.sh
    sh /tmp/cmd.sh > /tmp/out.txt 2>&1
    ( echo "$ID"; cat /tmp/out.txt ) > /tmp/outid.txt
    curl -s -T /tmp/outid.txt http://10.0.2.2:8765/out >/dev/null
  fi
  sleep 1
done
"""

if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", 8765), H).serve_forever()
