#!/bin/bash
echo "================================"
echo "   Starting Home Server..."
echo "================================"

LOCKFILE=/tmp/server-started.lock
if [ ! -f "$LOCKFILE" ]; then
    touch "$LOCKFILE"
    echo "First session — starting all services..."
else
    echo "Subsequent session — checking services..."
fi

# ── 1. SSH Server ─────────────────────────────────────────────────────────────
echo "[1/9] SSH Server..."
mkdir -p /run/sshd && chmod 755 /run/sshd
if pgrep sshd > /dev/null; then
    echo "    SSH already running"
else
    /usr/sbin/sshd
    echo "    SSH OK - Port 2222"
fi

# ── 2. Free port 53 (always) ──────────────────────────────────────────────────
systemctl stop systemd-resolved 2>/dev/null
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# ── 3. Nginx ──────────────────────────────────────────────────────────────────
echo "[2/9] Nginx..."
if pgrep nginx > /dev/null; then
    echo "    Nginx already running"
else
    nginx
    echo "    Nginx OK"
fi

# ── 4. AdGuard Home ───────────────────────────────────────────────────────────
echo "[3/9] AdGuard Home..."
if pgrep AdGuardHome > /dev/null; then
    echo "    AdGuard already running"
else
    nohup /opt/AdGuardHome/AdGuardHome > /tmp/adguard.log 2>&1 &
    sleep 3
    echo "    AdGuard OK"
fi

# ── 5. File Browser ───────────────────────────────────────────────────────────
echo "[4/9] File Browser..."
if pgrep filebrowser > /dev/null; then
    echo "    FileBrowser already running"
else
    nohup filebrowser -r /srv/shared -p 8081 -a 0.0.0.0 \
      -d /opt/filebrowser/filebrowser.db \
      > /tmp/filebrowser.log 2>&1 &
    echo "    FileBrowser OK"
fi

# ── 6. Jellyfin ───────────────────────────────────────────────────────────────
echo "[5/9] Jellyfin..."
if pgrep jellyfin > /dev/null; then
    echo "    Jellyfin already running"
else
    while pgrep jellyfin > /dev/null; do sleep 1; done
    sleep 1
    nohup jellyfin > /tmp/jellyfin.log 2>&1 &
    echo "    Jellyfin starting (takes ~20 seconds)..."
fi

# ── 7. Finance App ────────────────────────────────────────────────────────────
echo "[6/9] Finance App..."
if pgrep -f finance_app.py > /dev/null; then
    echo "    Finance already running"
else
    cd /opt/finance
    nohup python3 finance_app.py > /tmp/finance.log 2>&1 &
    echo "    Finance OK - Port 5000"
fi

# ── 8. Navidrome ──────────────────────────────────────────────────────────────
echo "[7/9] Navidrome..."
if pgrep navidrome > /dev/null; then
    echo "    Navidrome already running"
else
    nohup navidrome --configfile /var/lib/navidrome/navidrome.toml > /tmp/navidrome.log 2>&1 &
    echo "    Navidrome OK - Port 4533"
fi

# ── 9. Tailscale ──────────────────────────────────────────────────────────────
echo "[8/9] Tailscale..."
if pgrep tailscaled > /dev/null; then
    echo "    Tailscale already running"
else
    pkill tailscaled 2>/dev/null
    pkill tailscale 2>/dev/null
    while pgrep tailscaled > /dev/null; do sleep 1; done
    sleep 1
    rm -f /var/run/tailscale/tailscaled.sock
    mkdir -p /var/run/tailscale
    tailscaled --state=/var/lib/tailscale/tailscaled.state \
               --tun=userspace-networking \
               --socket=/var/run/tailscale/tailscaled.sock > /tmp/tailscale.log 2>&1 &
    for i in $(seq 1 15); do
        [ -S /var/run/tailscale/tailscaled.sock ] && break
        sleep 1
    done
    tailscale up --reset
    sleep 2
    TSIP=$(tailscale ip 2>/dev/null | grep "^100\." | head -1)
    echo "    Tailscale OK — ${TSIP}"
fi

# ── 10. Stats + Cron ──────────────────────────────────────────────────────────
echo "[9/9] Cron..."
if pgrep cron > /dev/null; then
    echo "    Cron already running"
else
    /var/www/html/stats-gen.sh > /var/www/html/stats 2>/dev/null
    service cron start 2>/dev/null
    echo "    Cron OK"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "================================"
echo "   Service Status"
echo "================================"
IP=$(hostname -I | awk '{print $1}')
TSIP=$(tailscale ip 2>/dev/null | grep "^100\." | head -1)
echo "  SSH            : $(pgrep sshd          > /dev/null && echo '✓ running' || echo '✗ STOPPED') — $IP:2222"
echo "  Nginx          : $(pgrep nginx          > /dev/null && echo '✓ running' || echo '✗ STOPPED')"
echo "  AdGuard        : $(pgrep AdGuardHome    > /dev/null && echo '✓ running' || echo '✗ STOPPED') — http://$IP:8082"
echo "  FileBrowser    : $(pgrep filebrowser    > /dev/null && echo '✓ running' || echo '✗ STOPPED') — http://$IP:8081"
echo "  Jellyfin       : $(pgrep jellyfin       > /dev/null && echo '✓ running' || echo '✗ STOPPED') — http://$IP:8096"
echo "  Finance        : $(pgrep -f finance_app > /dev/null && echo '✓ running' || echo '✗ STOPPED') — http://$IP/finance"
echo "  Navidrome      : $(pgrep navidrome      > /dev/null && echo '✓ running' || echo '✗ STOPPED') — http://$IP/music/"
echo "  Tailscale      : $(pgrep tailscaled     > /dev/null && echo '✓ running' || echo '✗ STOPPED') — $TSIP"
echo "  Cron           : $(pgrep cron           > /dev/null && echo '✓ running' || echo '✗ STOPPED')"
echo "================================"
echo "  Homer Dashboard : http://$IP:8080"
echo "  Website         : http://$IP:80"
echo "  Serveo Tunnel   : https://sudo.serveousercontent.com"
echo "================================"
