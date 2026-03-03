echo "================================"
echo "   Starting Home Server..."
echo "================================"

# Detect if this is the first SSH session
SESSION_COUNT=$(who | wc -l)

if [ "$SESSION_COUNT" -le 1 ]; then
    echo "First session — starting all services..."
    FIRST_SESSION=true
else
    echo "Session #${SESSION_COUNT} — services already running."
    FIRST_SESSION=false
fi

# 1. SSH Server (always ensure it's running)
echo "[1/6] Starting SSH Server..."
mkdir -p /run/sshd
chmod 755 /run/sshd
if pgrep sshd > /dev/null; then
    echo "    SSH already running"
else
    /usr/sbin/sshd
    echo "    SSH OK - Port 2222"
fi

# 2. Free port 53 (always)
systemctl stop systemd-resolved 2>/dev/null
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

if [ "$FIRST_SESSION" = true ]; then

    # 3. Nginx
    echo "[2/6] Starting Nginx..."
    pkill nginx 2>/dev/null; sleep 1
    nginx
    echo "    Nginx OK"

    # 4. AdGuard Home
    echo "[3/6] Starting AdGuard Home..."
    pkill AdGuardHome 2>/dev/null; sleep 1
    nohup /opt/AdGuardHome/AdGuardHome > /tmp/adguard.log 2>&1 &
    sleep 3
    echo "    AdGuard OK"

    # 5. File Browser
    echo "[4/6] Starting File Browser..."
    pkill filebrowser 2>/dev/null; sleep 1
    nohup filebrowser -r /srv/shared -p 8081 -a 0.0.0.0 \
      -d /opt/filebrowser/filebrowser.db \
      > /tmp/filebrowser.log 2>&1 &
    echo "    FileBrowser OK"

    # 6. Jellyfin
    echo "[5/6] Starting Jellyfin..."
    pkill jellyfin 2>/dev/null; sleep 1
    nohup jellyfin > /tmp/jellyfin.log 2>&1 &
    echo "    Jellyfin starting (takes ~20 seconds)..."

    # 7. Tailscale
    echo "[6/6] Starting Tailscale..."
    pkill tailscaled 2>/dev/null
    pkill tailscale 2>/dev/null
    sleep 2
    rm -f /var/run/tailscale/tailscaled.sock
    mkdir -p /var/run/tailscale
    tailscaled --state=/var/lib/tailscale/tailscaled.state \
               --tun=userspace-networking \
               --socket=/var/run/tailscale/tailscaled.sock > /tmp/tailscale.log 2>&1 &
    sleep 5
    tailscale up --reset
    sleep 2
    echo "    Tailscale OK"

    # 8. Stats + Cron
    /var/www/html/stats-gen.sh > /var/www/html/stats 2>/dev/null
    service cron start 2>/dev/null

else
    echo "    Nginx        : $(pgrep nginx > /dev/null && echo running || echo STOPPED)"
    echo "    AdGuard      : $(pgrep AdGuardHome > /dev/null && echo running || echo STOPPED)"
    echo "    FileBrowser  : $(pgrep filebrowser > /dev/null && echo running || echo STOPPED)"
    echo "    Jellyfin     : $(pgrep jellyfin > /dev/null && echo running || echo STOPPED)"
    echo "    Tailscale    : $(pgrep tailscaled > /dev/null && echo running || echo STOPPED)"
fi

echo ""
echo "================================"
echo "   All services started!"
echo "================================"
IP=$(hostname -I | awk '{print $1}')
TSIP=$(tailscale ip 2>/dev/null | grep "^100." | head -1)
echo "  SSH (local)     : $IP:2222"
echo "  SSH (remote)    : $TSIP:2222"
echo "  Homer Dashboard : http://$IP:8080"
echo "  AdGuard Home    : http://$IP:8082"
echo "  File Browser    : http://$IP:8081"
echo "  Jellyfin        : http://$IP:8096"
echo "  Website         : http://$IP:80"
echo "  Serveo Tunnel   : https://sudo.serveousercontent.com"
echo "================================"