#!/bin/sh
set -eu

: "${DSVPN_SERVER:?Set DSVPN_SERVER}"
: "${DSVPN_PORT:=443}"
: "${DSVPN_KEY:=/run/secrets/dsvpn_key}"

: "${DNS_SERVER:=88.198.92.222}"

# Write DNS directly to resolv.conf BEFORE flushing iptables.
# Docker's embedded DNS proxy at 127.0.0.11 relies on nat DNAT rules
# which get wiped by iptables -t nat -F below. Without them, DNS breaks.
echo "nameserver $DNS_SERVER" > /etc/resolv.conf

echo "Installing firewall kill switch..."

iptables -F
iptables -t nat -F
iptables -X

# Default: block outbound and forwarded traffic.
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
iptables -P INPUT DROP

# Allow loopback.
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established traffic.
iptables -A INPUT  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow dsvpn client to connect to the VPS outside the tunnel.
iptables -A OUTPUT -p tcp -d "$DSVPN_SERVER" --dport "$DSVPN_PORT" -j ACCEPT
# Allow DNS resolution outside the tunnel.
iptables -A OUTPUT -d "$DNS_SERVER" -j ACCEPT

# Allow all traffic through the VPN tunnel.
iptables -A OUTPUT -o tun0 -j ACCEPT
iptables -A INPUT  -i tun0 -j ACCEPT

# Allow access to Transmission Web UI from your LAN/Docker host.
iptables -A INPUT  -p tcp --dport 9091 -s 10.0.0.0/8 -j ACCEPT
iptables -A INPUT  -p tcp --dport 9091 -s 172.16.0.0/12 -j ACCEPT
iptables -A INPUT  -p tcp --dport 9091 -s 192.168.0.0/16 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 9091 -j ACCEPT

echo "Installing IPv6 firewall kill switch..."

ip6tables -F
ip6tables -X

# Default: block all IPv6 — there is no IPv6 tunnel.
ip6tables -P INPUT   DROP
ip6tables -P OUTPUT  DROP
ip6tables -P FORWARD DROP

# Allow loopback.
ip6tables -A INPUT  -i lo -j ACCEPT
ip6tables -A OUTPUT -o lo -j ACCEPT

echo "Starting dsvpn..."
exec /usr/local/bin/dsvpn client "$DSVPN_KEY" "$DSVPN_SERVER" "$DSVPN_PORT"
