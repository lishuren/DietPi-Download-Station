#!/bin/bash
# vpn-toggle: Toggle transparent full-device / full-LAN VPN routing via Mihomo
# Usage: vpn-toggle on|off|status
#
# Default state (config.yaml): mode=direct (VPN off, all traffic goes direct)
# ON:  Mihomo GLOBAL selector → Proxy group, mode → global  + iptables TPROXY rules
# OFF: Mihomo mode → direct  + remove TPROXY rules (traffic goes direct)
#
# The Pi's own traffic (Aria2, etc.) is handled by TUN mode in config.yaml
# (tun.auto-route: true) — no per-app proxy settings needed.
# LAN devices are covered when the Pi is used as their default gateway.

set -e

MIHOMO_API="http://127.0.0.1:9090"
TPROXY_PORT=7893
CHAIN="MIHOMO_TP"

_api_patch_mode() {
    curl -sf -X PATCH "$MIHOMO_API/configs" \
        -H "Content-Type: application/json" \
        -d "{\"mode\":\"$1\"}" >/dev/null
}

_api_select_global_proxy() {
    # Point the built-in GLOBAL selector at a named proxy/group
    curl -sf -X PUT "$MIHOMO_API/proxies/GLOBAL" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$1\"}" >/dev/null
}

_setup_tproxy() {
    # Load required kernel module
    modprobe xt_TPROXY 2>/dev/null || true

    # Enable IP forwarding for LAN traffic
    sysctl -w net.ipv4.ip_forward=1 >/dev/null

    # Mark-based policy routing (TPROXY requires this)
    ip rule show | grep -q "fwmark 0x1 lookup 100" || \
        ip rule add fwmark 1 table 100
    ip route show table 100 2>/dev/null | grep -q "local default" || \
        ip route add local default dev lo table 100

    # Create TPROXY chain (flush if already exists)
    iptables -t mangle -N "$CHAIN" 2>/dev/null || iptables -t mangle -F "$CHAIN"

    # Skip reserved / private ranges (no LAN-to-LAN proxying)
    iptables -t mangle -A "$CHAIN" -d 127.0.0.0/8        -j RETURN
    iptables -t mangle -A "$CHAIN" -d 224.0.0.0/4        -j RETURN
    iptables -t mangle -A "$CHAIN" -d 255.255.255.255/32  -j RETURN
    iptables -t mangle -A "$CHAIN" -d 172.16.0.0/12       -j RETURN
    iptables -t mangle -A "$CHAIN" -d 10.0.0.0/8          -j RETURN
    iptables -t mangle -A "$CHAIN" -d 192.168.0.0/16 -p tcp              -j RETURN
    iptables -t mangle -A "$CHAIN" -d 192.168.0.0/16 -p udp ! --dport 53 -j RETURN
    # Skip fake-ip range used by Mihomo DNS
    iptables -t mangle -A "$CHAIN" -d 198.18.0.0/15       -j RETURN
    # Skip traffic already processed by Mihomo (avoid routing loop)
    iptables -t mangle -A "$CHAIN" -m mark --mark 0xff    -j RETURN

    # TPROXY all remaining TCP + UDP to Mihomo tproxy-port
    iptables -t mangle -A "$CHAIN" -p tcp -j TPROXY \
        --on-port "$TPROXY_PORT" --tproxy-mark 1
    iptables -t mangle -A "$CHAIN" -p udp -j TPROXY \
        --on-port "$TPROXY_PORT" --tproxy-mark 1

    # Hook into PREROUTING (covers forwarded LAN traffic)
    iptables -t mangle -C PREROUTING -j "$CHAIN" 2>/dev/null || \
        iptables -t mangle -A PREROUTING -j "$CHAIN"
}

_teardown_tproxy() {
    iptables -t mangle -D PREROUTING -j "$CHAIN" 2>/dev/null || true
    iptables -t mangle -F "$CHAIN"                2>/dev/null || true
    iptables -t mangle -X "$CHAIN"                2>/dev/null || true
    ip rule del fwmark 1 table 100                2>/dev/null || true
    ip route del local default dev lo table 100   2>/dev/null || true
}

case "$1" in
    on)
        _setup_tproxy
        _api_select_global_proxy Proxy
        _api_patch_mode global
        echo "VPN ON: all traffic (Pi + LAN) routes through proxy."
        ;;
    off)
        _teardown_tproxy
        _api_patch_mode direct
        echo "VPN OFF: all traffic goes direct."
        ;;
    status)
        mode=$(curl -sf "$MIHOMO_API/configs" \
            | grep -o '"mode":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo unknown)
        echo "Mihomo mode: $mode"
        if iptables -t mangle -L "$CHAIN" >/dev/null 2>&1; then
            echo "TPROXY rules: active"
        else
            echo "TPROXY rules: inactive"
        fi
        ;;
    *)
        echo "Usage: vpn-toggle on|off|status"
        exit 1
        ;;
esac
