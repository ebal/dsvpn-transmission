#!/bin/bash
set -e

if [ ! -f dsvpn.key ]; then
    echo "============================================"
    echo "  dsvpn.key not found!"
    echo ""
    echo "  Copy the key from your VPS:"
    echo "    scp root@<vps-ip>:/etc/dsvpn.key ./dsvpn.key"
    echo ""
    echo "  Or paste it as base64:"
    echo "    echo '<base64-key>' | base64 -d > dsvpn.key"
    echo "============================================"
    exit 1
fi

if [ ! -f dsvpn.env ]; then
    echo "============================================"
    echo "  dsvpn.env not found!"
    echo ""
    echo "  Create it from the template:"
    echo "    cp dsvpn.env.example dsvpn.env"
    echo ""
    echo "  Then edit dsvpn.env and set your VPS IP and DNS:"
    echo "    DSVPN_SERVER=your-vps-ip"
    echo "    DNS_SERVER=88.198.92.222"
    echo "============================================"
    exit 1
fi

docker compose down

docker compose up -d --build
