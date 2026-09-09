#!/bin/sh
# setup-g4-route.sh - make littlejelly a Tailscale subnet router for the wired LAN,
# so the Mac can reach the Power Mac G4 (which cannot run Tailscale) from anywhere.
#
# Run ON littlejelly:   sudo sh ~/setup-g4-route.sh [subnet]
# Default subnet is the wired LAN, 192.168.0.0/24 (enp1s0f0).
# Needs Tailscale >= 1.44 for `tailscale set`; littlejelly has 1.102.
set -e
ROUTE="${1:-192.168.0.0/24}"

cat > /etc/sysctl.d/99-tailscale.conf <<SYSCTL
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
SYSCTL
sysctl -p /etc/sysctl.d/99-tailscale.conf

# Keeps every other Tailscale setting as-is; only adds the advertised route.
tailscale set --advertise-routes="$ROUTE"

echo
echo "Advertised $ROUTE. Two clicks remain:"
echo "  1. https://login.tailscale.com/admin/machines -> littlejelly -> Edit route settings -> approve $ROUTE"
echo "  2. On the Mac: Tailscale menu -> 'Use Tailscale subnets' on"
echo "Proof from the Mac on Wi-Fi only:  ping 192.168.0.1"
echo
tailscale status --self --peers=false
