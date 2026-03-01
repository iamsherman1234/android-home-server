#!/bin/bash
echo "================================"
echo "   Starting Home Server..."
echo "================================"
# 1. SSH Server
echo "[1/5] Starting SSH Server..."
mkdir -p /run/sshd
chmod 755 /run/sshd
if ! pgrep sshd > /dev/null; then
    /usr/sbin/sshd
    echo " SSH OK - Port 2222"
else
    echo " SSH already running"
fi
# 2. Free port 53
systemctl stop systemd-resolved 2>/dev/null
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
# 3. Nginx
echo "[2/5] Starting Nginx..."
pkill nginx 2>/dev/null; sleep 1
nginx
echo "    Nginx OK"
# 4. AdGuard Home
echo "[3/5] Starting AdGuard Home..."
pkill AdGuardHome 2>/dev/null; sleep 1
nohup /opt/AdGuardHome/AdGuardHome > /tmp/adguard.log 2>&1 &
sleep 3
echo "    AdGuard OK"
# 5. File Browser
echo "[4/5] Starting File Browser..."
pkill filebrowser 2>/dev/null; sleep 1
nohup filebrowser -r /srv/shared -p 8081 -a 0.0.0.0 \
  -d /opt/filebrowser/filebrowser.db \
  > /tmp/filebrowser.log 2>&1 &
echo "    FileBrowser OK"
# 6. Jellyfin
echo "[5/5] Starting Jellyfin..."
pkill jellyfin 2>/dev/null; sleep 1
nohup jellyfin > /tmp/jellyfin.log 2>&1 &
echo "    Jellyfin starting (takes ~20 seconds)..."
echo ""
echo "================================"
echo "   All services started!"
echo "================================"
IP=$(hostname -I | awk '{print $1}')
echo "  SSH Server      : at Port 2222"
echo "  Homer Dashboard : http://$IP:8080"
echo "  AdGuard Home    : http://$IP:8082"
echo "  File Browser    : http://$IP:8081"
echo "  Jellyfin        : http://$IP:8096"
echo "  Website         : http://$IP:80"
echo "  Serveo Tunnel   : https://sudo.serveousercontent.com"
echo "================================"
