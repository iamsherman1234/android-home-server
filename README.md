# 📱 sudo.local — Home Server on Samsung S10+

> A fully self-hosted personal cloud running on a rooted Samsung S10+ via DroidSpaces, exposed to the internet using Serveo reverse tunneling — no port forwarding, no static IP required.

![Platform](https://img.shields.io/badge/Platform-Android%20(Rooted)-green?style=flat-square&logo=android)
![OS](https://img.shields.io/badge/Container-Debian%2011%20Bullseye-red?style=flat-square&logo=debian)
![Arch](https://img.shields.io/badge/Arch-ARM64-blue?style=flat-square)
![Kernel](https://img.shields.io/badge/Kernel-4.14%20FreeRunner-orange?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Hardware Requirements](#hardware-requirements)
- [Software Requirements](#software-requirements)
- [Limitations](#limitations)
- [Architecture](#architecture)
- [Services](#services)
- [Installation](#installation)
  - [Phase 1 — Prepare Android](#phase-1--prepare-android)
  - [Phase 2 — Enter Debian Container](#phase-2--enter-debian-container)
  - [Phase 3 — System Preparation](#phase-3--system-preparation)
  - [Phase 4 — SSH Server](#phase-4--ssh-server)
  - [Phase 5 — Nginx Web Server](#phase-5--nginx-web-server)
  - [Phase 6 — AdGuard Home](#phase-6--adguard-home)
  - [Phase 7 — File Browser](#phase-7--file-browser)
  - [Phase 8 — Jellyfin Media Server](#phase-8--jellyfin-media-server)
  - [Phase 9 — Homer Dashboard](#phase-9--homer-dashboard)
  - [Phase 10 — Live Stats Endpoint](#phase-10--live-stats-endpoint)
  - [Phase 11 — Serveo Public Tunnel](#phase-11--serveo-public-tunnel)
  - [Phase 12 — Auto-Start Script](#phase-12--auto-start-script)
- [Network Configuration](#network-configuration)
- [Storage Guide](#storage-guide)
- [File Structure](#file-structure)
- [Troubleshooting](#troubleshooting)
- [Security Notes](#security-notes)
- [Health Check](#health-check)

---

## Overview

This project documents how to turn a **Samsung S10+** into a fully functional home server using **DroidSpaces** — an Android container manager — running a **Debian 11 (Bullseye)** Linux environment natively on the phone.

All services are installed **natively** inside Debian. Docker and Podman were tested and found to be incompatible with this kernel/environment (see [Limitations](#limitations)).

The server is accessible both on your local network and from anywhere in the world via a **Serveo SSH reverse tunnel** — no router port forwarding or static IP needed.

### What you get

| Service | Purpose | Local Port | Remote Path |
|---|---|---|---|
| 🌐 Nginx | Web server + reverse proxy | 80 | `/` |
| 🏠 Homer | Unified dashboard | 8080 | `/` |
| 🛡️ AdGuard Home | DNS ad blocker | 8082 / 53 | `/adguard/` |
| 📁 File Browser | Web file manager | 8081 | `/files/` |
| 🎬 Jellyfin | Media streaming server | 8096 | `/media/` |
| 🔐 SSH | Remote terminal access | 2222 | — |

---

## Hardware Requirements

| Component | Minimum | Tested On |
|---|---|---|
| Device | Any Android phone | Samsung Galaxy S10+ |
| RAM | 4GB | 8GB (7.4GB usable) |
| Storage | 32GB internal | 32GB |
| CPU Architecture | ARM64 | Exynos 9820 · 8 Cores |
| Android Version | 8.0+ | Android 16 |
| Root Access | Required | [KSUN](https://github.com/KernelSU-Next/KernelSU-Next) |
| ROM | Any with root | [Infinity X](https://projectinfinity-x.com/downloads/beyond2lte) |
| Kernel | 4.9+ | [FrEeRuNnErKeRnEl-v3.6+ (4.14.356)](https://github.com/LeDrew2017/FreeRunnerKernel/releases/tag/v3.6) |
| Network | WiFi | 2.4GHz / 5GHz |

> ⚠️ **Root access is mandatory.** DroidSpaces requires root to create and manage Linux containers on Android.

> ⚠️ **Keep the phone plugged in.** Running a 24/7 server will drain the battery. Plug it into a charger and monitor temperatures.

---

## Software Requirements

### On Android (required before starting)

| Software | Purpose | Where to Get |
|---|---|---|
| **KernelSU-Next** | Root manager | [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next)) |
| **DroidSpaces** | Linux container manager | [DroidSpaces](https://github.com/ravindu644/Droidspaces-OSS) |
| **Termux** | Terminal emulator to access container | [F-Droid](https://f-droid.org/packages/com.termux/) |
| **Stock/Custom ROM** | Stable rooted Android base | [Rooting and Android Kernel Requirement](https://github.com/ravindu644/Droidspaces-OSS/blob/main/README.md#rooting-requirements)|
### Inside the Debian Container (installed during setup)

| Software | Version | Purpose |
|---|---|---|
| Debian | 11 Bullseye (ARM64) | [Container Image](https://images.linuxcontainers.org/images/debian/bullseye/arm64/default/20260228_05%3A24/rootfs.tar.xz)|
| Nginx | Latest stable | Web server + reverse proxy |
| OpenSSH Server | 8.4+ | SSH remote access |
| AdGuard Home | Latest | DNS + ad blocking |
| File Browser | Latest | Web-based file manager |
| Jellyfin | 10.11.6+ | Media server |
| jellyfin-ffmpeg6 | 6.x | Media transcoding (replaces system ffmpeg) |
| Homer | Latest | Service dashboard |
| autossh | Latest | Persistent Serveo tunnel |
| curl, wget, gnupg | — | Download and verification tools |

### On Your Client Devices (to access the server)

| Client | Recommended App |
|---|---|
| Windows | PowerShell SSH / PuTTY / Any browser |
| macOS / Linux | Terminal SSH / Any browser |
| iOS | Termius, SSH Files, Prompt 3 |
| Android | Termux, JuiceSSH |

---

## Limitations

> Read these carefully before starting. These are real-world constraints discovered during setup.

### ❌ Docker — Not Supported

Docker was installed and tested but **fails to start** on this environment:

```
Error: Devices cgroup isn't mounted
```

**Root cause:** Android kernel 4.14 (FreeRunner) does not allow cgroup v1 device subsystem to be mounted from inside a chroot. DroidSpaces containers do not have the privileges to mount cgroup subsystems.

**Solution:** Install all services natively on Debian instead.

### ❌ Podman — Not Supported

Podman was tested as a Docker alternative but also fails:

```
open /proc/self/uid_map: no such file or directory
```

**Root cause:** User namespaces are disabled in the FreeRunner kernel. `/proc/self/uid_map` does not exist, which Podman requires for rootless operation. Even with `--cgroups=disabled` and other flags, Podman cannot start containers.

**Solution:** Native installation only.

### ⚠️ systemd — Partially Working

systemd is available in DroidSpaces but has limitations:

- Services **cannot reliably auto-start** via `systemctl enable` on container boot
- `systemctl start` works manually after boot
- The Serveo tunnel service (`serveo.service`) works via systemd after initial boot
- **Solution:** Use a bash startup script in `.bashrc` to launch all services when entering the container

### ⚠️ Port 53 — Blocked by systemd-resolved

systemd-resolved occupies port 53 by default, blocking AdGuard from using it:

```
Error: listen udp 0.0.0.0:53: bind: address already in use
```

**Solution:** Disable systemd-resolved and set fallback DNS manually before starting AdGuard.

### ⚠️ iptables — nf_tables Not Supported

Modern iptables (nf_tables backend) does not work on Android kernel 4.14:

```
iptables: Protocol not available
```

**Solution:** Switch to legacy iptables:

```bash
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
```

### ⚠️ ffmpeg — System Version Too Old

Debian 11 ships with ffmpeg 4.3.x. Jellyfin 10.11.6 requires **4.4 or newer**.

**Solution:** Install `jellyfin-ffmpeg6` from the Jellyfin repository.

### ⚠️ Jellyfin Web UI — Wrong Default Path

Jellyfin looks for its web client at `/usr/lib/jellyfin/bin/jellyfin-web` but Debian installs it to `/usr/share/jellyfin/web`.

**Solution:** Create a symlink.

### ⚠️ File Browser — baseURL Bug

File Browser v2.60.0+ has a known bug where `--baseURL /files/` does not work correctly when behind a reverse proxy. Assets and API calls break.

**Solution:** Proxy `/static/` and `/api/` paths separately at the Nginx level.

### ⚠️ IP Address Changes

The phone's IP changes if:
- DHCP reassigns it on router reboot
- MAC randomization is enabled (Android default)

**Solution:** Disable MAC randomization and set a DHCP reservation in your router.

### ⚠️ Jellyfin Hardware Transcoding — Not Available

Hardware transcoding (VAAPI, NVENC, etc.) is not available on this ARM64 Android kernel environment. Only **software transcoding** works.

### ⚠️ Serveo Free Tier — 3 Tunnel Limit

Serveo free accounts are limited to 3 simultaneous active tunnels.

**Solution:** Route all services through a **single port 80 tunnel** using Nginx path-based reverse proxying.

### ⚠️ Log Directory Write Errors on Boot

DroidSpaces briefly mounts the container filesystem as read-only during startup. Writing logs to `/var/log/` during this window causes errors.

**Solution:** Use `/tmp/` for service logs in the startup script or enable SElinux Permissive in DroidSpaces.

---

## Architecture

```
Internet
    │
    ▼
serveo.net (SSH Reverse Tunnel)
    │
    ▼
Nginx :80 (Reverse Proxy)
    ├── /              → Homer Dashboard  :8080
    ├── /adguard/      → AdGuard Home     :8082
    ├── /files/        → File Browser     :8081
    ├── /static/       → File Browser     :8081 (assets)
    ├── /api/          → File Browser     :8081 (API)
    ├── /media/        → Jellyfin         :8096
    └── /stats         → Stats JSON file  (static)

Local Network
    ├── 192.168.100.149:80    → Website
    ├── 192.168.100.149:8080  → Homer
    ├── 192.168.100.149:8082  → AdGuard UI
    ├── 192.168.100.149:53    → AdGuard DNS (all network devices)
    ├── 192.168.100.149:8081  → File Browser
    ├── 192.168.100.149:8096  → Jellyfin
    └── 192.168.100.149:2222  → SSH
```

---

## Services

| Service | Local URL | Remote URL |
|---|---|---|
| 🌐 Website | `http://192.168.100.149` | `https://yourownservername.serveousercontent.com` |
| 🏠 Homer | `http://192.168.100.149:8080` | `https://yourownservername.serveousercontent.com` |
| 🛡️ AdGuard | `http://192.168.100.149:8082` | `https://yourownservername.serveousercontent.com/adguard/` |
| 📁 File Browser | `http://192.168.100.149:8081` | `https://yourownservername.serveousercontent.com/files/` |
| 🎬 Jellyfin | `http://192.168.100.149:8096` | `https://yourownservername.serveousercontent.com/media/` |
| 🔐 SSH | `192.168.100.149:2222` | — |

---

## Installation

### Phase 1 — Prepare Android

#### 1.1 — Root your phone

Install a custom ROM with [Requirement](#software-requirements). This project was tested on **InfinityOS** with **KSUN 3.1.0**.

#### 1.2 — Install DroidSpaces

Install DroidSpaces from [Latest Release](https://github.com/ravindu644/Droidspaces-OSS/releases/tag/v4.5.1). DroidSpaces is a Linux container manager for Android that creates an isolated linux environment.

#### 1.3 — Install Termux

Install Termux from **[F-Droid](https://f-droid.org/packages/com.termux/)** (not Google Play — the Play Store version is outdated).

#### 1.4 — Create Debian Container in DroidSpaces
**[Installation](https://github.com/ravindu644/Droidspaces-OSS/blob/main/Documentation/Installation-Android.md)**
1. Open DroidSpaces
2. Tap **+** to create a new container
3. Select **[Your Tarball](https://images.linuxcontainers.org/images/debian/bullseye/arm64/default/20260228_05%3A24/rootfs.tar.xz)**
4. **Name** : give it a name (my case, ,i set debian)
5. Enable **Set DNS Server (1.1.1.1,8.8.8.8), Android Storage, Hardware Access, SELinux Permissive and Run at Boot**
6. Create the container and wait for completion.
7. Start the container
8. Copy login script

#### 1.5 — Fix MAC Randomization (Prevent IP Changes)

On your phone: **Settings → WiFi → Your Network → Advanced → MAC Address → Use Device MAC**

Then set a **DHCP reservation** in your router to always assign the same IP to your phone's MAC address.

#### 1.6 — Set Timezone

```bash
timedatectl set-timezone Asia/Phnom_Penh
# Replace with your timezone, e.g. Asia/Bangkok, America/New_York
```

---

### Phase 2 — Enter Debian Container

From Termux, enter the container by paste the copied script from copy login in Droidspaces.
in my case:
```bash
su -c '/data/local/Droidspaces/bin/droidspaces --name="debian" enter'
```

Every command from this point is run **inside the Debian container**.

---

### Phase 3 — System Preparation

#### 3.1 — Update system

```bash
apt update && apt upgrade -y
```

#### 3.2 — Install base dependencies

```bash
apt install -y curl wget ca-certificates gnupg nano net-tools \
               unzip autossh openssh-client openssh-server \
               cron iptables
```

#### 3.3 — Fix iptables (required — Android kernel does not support nf_tables)

```bash
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
```

#### 3.4 — Create shared media directories linked to Android storage

```bash
mkdir -p /srv/shared/{movies,music,photos,documents,downloads}
ln -sf /storage/emulated/0/Movies    /srv/shared/movies
ln -sf /storage/emulated/0/Music     /srv/shared/music
ln -sf /storage/emulated/0/Pictures  /srv/shared/photos
ln -sf /storage/emulated/0/Download  /srv/shared/downloads
ln -sf /storage/emulated/0/Documents /srv/shared/documents
```

> These symlinks let Jellyfin and File Browser access your Android storage without copying files into the container.

---

### Phase 4 — SSH Server

#### 4.1 — Configure SSH

```bash
cat > /etc/ssh/sshd_config << 'EOF'
Port 2222
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF
```

#### 4.2 — Set root password

```bash
passwd root
```

#### 4.3 — Generate host keys

```bash
ssh-keygen -A
```

#### 4.4 — Start SSH

```bash
mkdir -p /run/sshd
chmod 755 /run/sshd
/usr/sbin/sshd
```

#### 4.5 — Verify

```bash
ss -tulnp | grep 2222
```

Expected output: sshd listening on port 2222.

#### 4.6 — Connect from any device

```bash
# Windows / Mac / Linux
ssh root@192.168.100.149 -p 2222

# iOS — use Termius app with:
# Host: 192.168.100.149
# Port: 2222
# User: root
```

---

### Phase 5 — Nginx Web Server

#### 5.1 — Install

```bash
apt install -y nginx
```

> ⚠️ Ignore the systemd startup failure during install — expected in a chroot environment.

#### 5.2 — Start Nginx directly (not via systemd)

```bash
nginx
```

#### 5.3 — Remove default config

```bash
rm -f /etc/nginx/sites-enabled/default
```

#### 5.4 — Create reverse proxy config

```bash
cat > /etc/nginx/sites-available/proxy << 'EOF'
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
        add_header Access-Control-Allow-Origin *;
    }

    location /stats {
        default_type application/json;
        add_header Access-Control-Allow-Origin *;
        add_header Cache-Control "no-cache";
    }

    location /adguard/ {
        proxy_pass http://127.0.0.1:8082/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_redirect ~^/(.*)$ /adguard/$1;
        proxy_cookie_path / /adguard/;
    }

    location /files/ {
        proxy_pass http://127.0.0.1:8081/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_redirect / /files/;
    }

    location /static/ {
        proxy_pass http://127.0.0.1:8081/static/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:8081/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /media/ {
        proxy_pass http://127.0.0.1:8096/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_buffering off;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
        client_max_body_size 100M;
    }
}

server {
    listen 8080;
    root /var/www/homer;
    index index.html;
    location / { try_files $uri $uri/ =404; }
}
EOF

ln -sf /etc/nginx/sites-available/proxy /etc/nginx/sites-enabled/proxy
nginx -t
```

#### 5.5 — Reload Nginx

```bash
nginx_pid=$(ps aux | grep "nginx: master" | grep -v grep | awk '{print $2}')
echo $nginx_pid > /run/nginx.pid
nginx -s reload
```

---

### Phase 6 — AdGuard Home

#### 6.1 — Free port 53 (occupied by systemd-resolved by default)

```bash
systemctl stop systemd-resolved
systemctl disable systemd-resolved

# Set fallback DNS so internet still works
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
```

#### 6.2 — Install AdGuard Home

```bash
curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh \
  | sh -s -- -v
```

#### 6.3 — Configure DNS port to 53

```bash
sed -i 's/port: 5353/port: 53/' /opt/AdGuardHome/AdGuardHome.yaml
```

#### 6.4 — Start AdGuard Home

```bash
nohup /opt/AdGuardHome/AdGuardHome > /tmp/adguard.log 2>&1 &
```

#### 6.5 — Complete setup wizard

Open `http://YOUR PHONE'S IP:3000` in your browser and complete the wizard:

- **Admin web interface port:** `8082`
- **DNS server port:** `53`
- Create admin username and password

#### 6.6 — Configure upstream DNS

In AdGuard web UI: **Settings → DNS Settings → Upstream DNS Servers**

```
https://dns.cloudflare.com/dns-query
https://dns.google/dns-query
tls://1.1.1.1
tls://8.8.8.8
```

Click **Test upstreams** then **Save**.

#### 6.7 — Add blocklists

Go to **Filters → DNS Blocklists → Add Blocklist → Add a custom list**:

| Name | URL |
|---|---|
| AdGuard DNS Filter | `https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt` |
| Steven Black Hosts | `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts` |
| OISD Big | `https://big.oisd.nl` |

Click **Update Filters** after adding all lists.

#### 6.8 — Point your router DNS to AdGuard

In your router's DHCP settings:
- **Primary DNS:** `YOUR PHONE's IP`
- **Secondary DNS:** `1.1.1.1`

#### 6.9 — Verify DNS blocking

From Termux (outside DroidSpaces):

```bash
# Should return 0.0.0.0 = BLOCKED
nslookup doubleclick.net 192.168.100.149

# Should return real IP = ALLOWED
nslookup google.com 192.168.100.149
```

---

### Phase 7 — File Browser

#### 7.1 — Install

```bash
curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
mkdir -p /opt/filebrowser
```

#### 7.2 — Start File Browser

> ⚠️ Always use `-a 0.0.0.0` — without it, File Browser only binds to localhost and is inaccessible from other devices on the network.

```bash
nohup filebrowser \
  -r /srv/shared \
  -p 8081 \
  -a 0.0.0.0 \
  -d /opt/filebrowser/filebrowser.db \
  > /tmp/filebrowser.log 2>&1 &
```
After first start, it will show the initial password. Copy and keep it.
#### 7.3 — First login

Open `http://YOUR PHONE'S IP:8081`

Default credentials: **admin / from the output when first start** — change immediately after first login.

---

### Phase 8 — Jellyfin Media Server

#### 8.1 — Add Jellyfin repository

```bash
curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key \
  | gpg --dearmor -o /etc/apt/keyrings/jellyfin.gpg

cat > /etc/apt/sources.list.d/jellyfin.list << 'EOF'
deb [arch=arm64 signed-by=/etc/apt/keyrings/jellyfin.gpg] https://repo.jellyfin.org/debian bullseye main
EOF

apt update
```

#### 8.2 — Install Jellyfin and bundled ffmpeg

```bash
apt install -y jellyfin jellyfin-web jellyfin-ffmpeg6
```

> ⚠️ Do NOT use the system ffmpeg. Debian 11 ships ffmpeg 4.3.x which is too old. `jellyfin-ffmpeg6` provides version 6.x.

#### 8.3 — Fix web client symlink

```bash
ln -sf /usr/share/jellyfin/web /usr/lib/jellyfin/bin/jellyfin-web
```

#### 8.4 — Fix ffmpeg path

```bash
mkdir -p /root/.config/jellyfin
cat > /root/.config/jellyfin/encoding.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<EncodingOptions>
  <EncoderAppPath>/usr/lib/jellyfin-ffmpeg/ffmpeg</EncoderAppPath>
  <EncoderAppPathDisplay>/usr/lib/jellyfin-ffmpeg/ffmpeg</EncoderAppPathDisplay>
</EncodingOptions>
EOF
```

#### 8.5 — Start Jellyfin

```bash
nohup jellyfin > /tmp/jellyfin.log 2>&1 &
```

> ⚠️ Jellyfin takes 20–30 seconds to initialize. Wait before opening the browser.

#### 8.6 — Complete setup wizard

Open `http://YOUR PHONE'S IP:8096` and complete the wizard.

When adding media libraries, use these paths:

| Type | Path |
|---|---|
| Movies | `/srv/shared/movies` |
| Music | `/srv/shared/music` |
| Photos | `/srv/shared/photos` |

---

### Phase 9 — Homer Dashboard

#### 9.1 — Install

```bash
mkdir -p /var/www/homer
cd /var/www/homer
wget -q $(curl -s https://api.github.com/repos/bastienwirtz/homer/releases/latest \
  | grep "browser_download_url.*homer.zip" \
  | cut -d '"' -f 4)
unzip homer.zip && rm homer.zip
```

#### 9.2 — Configure dashboard

```bash
cat > /var/www/homer/assets/config.yml << 'EOF'
title: "sudo.local Server"
subtitle: "Home Server Dashboard"
header: true
footer: false
theme: default

services:
  - name: "Network"
    icon: "fas fa-network-wired"
    items:
      - name: "AdGuard Home"
        logo: "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/adguard-home.png"
        subtitle: "DNS & Ad Blocker"
        url: "http://192.168.100.149:8082"
        target: "_blank"

  - name: "Media"
    icon: "fas fa-film"
    items:
      - name: "Jellyfin"
        logo: "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/jellyfin.png"
        subtitle: "Media Server"
        url: "http://192.168.100.149:8096"
        target: "_blank"

  - name: "Files"
    icon: "fas fa-folder"
    items:
      - name: "File Browser"
        logo: "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/filebrowser.png"
        subtitle: "File Manager"
        url: "http://192.168.100.149:8081"
        target: "_blank"

  - name: "Web"
    icon: "fas fa-globe"
    items:
      - name: "Website"
        logo: "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/nginx.png"
        subtitle: "Nginx Web Server"
        url: "http://192.168.100.149:80"
        target: "_blank"
EOF
```

---

### Phase 10 — Live Stats Endpoint

This generates live system stats as a JSON file served by Nginx at `/stats`.

#### 10.1 — Create stats generator script

```bash
cat > /var/www/html/stats-gen.sh << 'EOF'
#!/bin/bash
CPU=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4+$5)} END {printf "%.1f", usage}')
RAM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')
RAM_FREE=$(grep MemAvailable /proc/meminfo | awk '{print int($2/1024)}')
RAM_USED=$((RAM_TOTAL - RAM_FREE))
DISK_TOTAL=$(df / | tail -1 | awk '{printf "%.1f", $2/1024/1024}')
DISK_USED=$(df / | tail -1 | awk '{printf "%.1f", $3/1024/1024}')
DISK_PCT=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
UPTIME_SECS=$(cat /proc/uptime | awk '{print int($1)}')
UPTIME_HRS=$(( (UPTIME_SECS%86400)/3600 ))
UPTIME_MINS=$(( (UPTIME_SECS%3600)/60 ))
UPTIME="${UPTIME_HRS}h ${UPTIME_MINS}m"
LOAD=$(cat /proc/loadavg | awk '{print $1}')

# Battery
BAT_PCT=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo "0")
BAT_STAT=$(cat /sys/class/power_supply/battery/status 2>/dev/null || echo "Unknown")

# Temps — battery in tenths of a degree, others in millidegrees
BAT_RAW=$(cat /sys/class/power_supply/battery/temp 2>/dev/null || echo "0")
BAT_TEMP=$(awk "BEGIN {printf \"%.1f\", $BAT_RAW/10}")

CPU_RAW=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "0")
CPU_TEMP=$(awk "BEGIN {printf \"%.1f\", $CPU_RAW/1000}")

GPU_RAW=$(cat /sys/class/thermal/thermal_zone3/temp 2>/dev/null || echo "0")
GPU_TEMP=$(awk "BEGIN {printf \"%.1f\", $GPU_RAW/1000}")

CHAS_RAW=$(cat /sys/class/thermal/thermal_zone5/temp 2>/dev/null || echo "0")
CHAS_TEMP=$(awk "BEGIN {printf \"%.1f\", $CHAS_RAW/1000}")

echo "{\"cpu\":\"${CPU}\",\"ram_used\":${RAM_USED},\"ram_total\":${RAM_TOTAL},\"disk_used\":\"${DISK_USED}\",\"disk_total\":\"${DISK_TOTAL}\",\"disk_pct\":\"${DISK_PCT}\",\"uptime\":\"${UPTIME}\",\"load\":\"${LOAD}\",\"cpu_info\":\"Exynos 9820 · ARM64\",\"battery_pct\":${BAT_PCT},\"battery_status\":\"${BAT_STAT}\",\"bat_temp\":\"${BAT_TEMP}\",\"cpu_temp\":\"${CPU_TEMP}\",\"gpu_temp\":\"${GPU_TEMP}\",\"chas_temp\":\"${CHAS_TEMP}\"}"
EOF

chmod +x /var/www/html/stats-gen.sh
```

#### 10.2 — Generate first stats file immediately

```bash
/var/www/html/stats-gen.sh > /var/www/html/stats
cat /var/www/html/stats
```

#### 10.3 — Set up cron to refresh every minute

```bash
(crontab -l 2>/dev/null; echo "* * * * * /var/www/html/stats-gen.sh > /var/www/html/stats 2>/dev/null") | crontab -

# Start cron
service cron start
```

#### 10.4 — Test the endpoint

```bash
curl http://YOUR PHONE'S IP/stats
```

---

### Phase 11 — Serveo Public Tunnel

Serveo exposes your server to the internet via an SSH reverse tunnel. No port forwarding or static IP needed.

#### 11.1 — Install autossh

```bash
apt install -y autossh
```

#### 11.2 — Generate SSH key for Serveo

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/serveo_key -N ""
```

#### 11.3 — Register your key with Serveo

```bash
# Print your public key fingerprint
ssh-keygen -lf ~/.ssh/serveo_key.pub
```

Visit `https://console.serveo.net` and log in with Google or GitHub. Add your public key to claim a custom subdomain like `sudo`.

#### 11.4 — Test tunnel manually first

```bash
ssh -i ~/.ssh/serveo_key \
    -o "StrictHostKeyChecking=no" \
    -R YOURSERVERNAME:80:localhost:80 \
    serveo.net
```

If successful you will see:

```
Forwarding HTTP traffic from https://YOURSERVERNAME.serveousercontent.com
```

Press Ctrl+C after confirming it works.

#### 11.5 — Create systemd service for persistent tunnel

```bash
cat > /etc/systemd/system/serveo.service << 'EOF'
[Unit]
Description=Serveo Reverse Tunnel
After=network.target network-online.target
Wants=network-online.target

[Service]
User=root
ExecStartPre=/bin/sleep 15
ExecStart=/usr/bin/autossh -M 0 -N \
  -i /root/.ssh/serveo_key \
  -o "ServerAliveInterval 30" \
  -o "ServerAliveCountMax 3" \
  -o "StrictHostKeyChecking=no" \
  -R YOURSERVERNAME:80:localhost:80 \
  serveo.net
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable serveo
systemctl start serveo
```

> **Note:** `ExecStartPre=/bin/sleep 15` gives the network time to stabilize before attempting the tunnel connection on boot.

#### 11.6 — Verify tunnel is active

```bash
# Check service status
systemctl status serveo

# Test from outside your network
curl -I https://YOURSERVERNAME.serveousercontent.com
```

Expected: `HTTP/2 200`

---

### Phase 12 — Auto-Start Script

This script runs every time you enter the DroidSpaces container, starting all services automatically.

#### 12.1 — Create the script

```bash
cat > /opt/start-server.sh << 'EOF'
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
    echo "    SSH OK - Port 2222"
else
    echo "    SSH already running"
fi

# 2. Free port 53 for AdGuard
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
nohup filebrowser \
  -r /srv/shared \
  -p 8081 \
  -a 0.0.0.0 \
  -d /opt/filebrowser/filebrowser.db \
  > /tmp/filebrowser.log 2>&1 &
echo "    FileBrowser OK"

# 6. Jellyfin
echo "[5/5] Starting Jellyfin..."
pkill jellyfin 2>/dev/null; sleep 1
nohup jellyfin > /tmp/jellyfin.log 2>&1 &
echo "    Jellyfin starting (takes ~20 seconds)..."

# 7. Stats
/var/www/html/stats-gen.sh > /var/www/html/stats 2>/dev/null
service cron start 2>/dev/null

echo ""
echo "================================"
echo "   All services started!"
echo "================================"
IP=$(hostname -I | awk '{print $1}')
echo "  SSH             : $IP:2222"
echo "  Homer Dashboard : http://$IP:8080"
echo "  AdGuard Home    : http://$IP:8082"
echo "  File Browser    : http://$IP:8081"
echo "  Jellyfin        : http://$IP:8096"
echo "  Website         : http://$IP:80"
echo "  Serveo Tunnel   : https://YOURSERVERNAME.serveousercontent.com"
echo "================================"
EOF

chmod +x /opt/start-server.sh
```

> **Note:** The Serveo tunnel is managed by systemd (`serveo.service`) and not started in this script to avoid duplicate tunnel connections.

#### 12.2 — Add to .bashrc for automatic execution

```bash
echo 'bash /opt/start-server.sh' >> ~/.bashrc
```

From now on, every time you enter the container the script runs automatically and all services start.

---

## Network Configuration

### Prevent IP Changes

**Step 1 — Disable MAC Randomization on your phone:**

Settings → WiFi → Your Network → Advanced → MAC Address → **Use Device MAC**

**Step 2 — Set DHCP Reservation in Router:**

1. Login to your router admin page (usually `192.168.1.1`)
2. Find **DHCP Reservation** / **Static DHCP** / **Address Reservation**
3. Add your phone's MAC address and assign it a fixed IP
4. Save and reboot router

### Router DNS Setup

In your router's DHCP/DNS settings:

- **Primary DNS:** `YOUR PHONE'S IP` (your phone's IP)
- **Secondary DNS:** `1.1.1.1` (fallback)

This routes all DNS queries from every device on your network through AdGuard for network-wide ad blocking.

---

## Storage Guide

| Location | Purpose | Notes |
|---|---|---|
| Debian container (`/`) | OS + all services | ~5–6GB used |
| `/storage/emulated/0/` | Android internal storage | For media files |
| `/srv/shared/` | Symlinks to Android storage | Accessed by Jellyfin & File Browser |
| `/tmp/` | Service logs | Cleared on reboot |

### Check disk usage

```bash
df -h /
du -sh /* 2>/dev/null | sort -rh | head -10
apt clean && apt autoremove -y
```

### Thermal zones (Samsung S10+ / Exynos 9820)

| Sensor | Path |
|---|---|
| CPU (Exynos BIG cores) | `/sys/class/thermal/thermal_zone0/temp` |
| GPU (G3D) | `/sys/class/thermal/thermal_zone3/temp` |
| Chassis | `/sys/class/thermal/thermal_zone5/temp` |
| Battery | `/sys/class/power_supply/battery/temp` |

> CPU, GPU, and Chassis temps are reported in **millidegrees** (divide by 1000). Battery temp is in **tenths of a degree** (divide by 10).

---

## File Structure

```
/
├── etc/
│   ├── nginx/
│   │   └── sites-enabled/
│   │       └── proxy                   # Nginx reverse proxy config
│   ├── ssh/
│   │   └── sshd_config                 # SSH server config (port 2222)
│   └── systemd/system/
│       └── serveo.service              # Serveo autossh systemd service
├── opt/
│   ├── start-server.sh                 # Auto-start script (runs on container entry)
│   ├── AdGuardHome/                    # AdGuard Home binary + config
│   │   └── AdGuardHome.yaml            # DNS port: 53, Web port: 8082
│   └── filebrowser/
│       └── filebrowser.db              # File Browser database
├── var/www/
│   ├── html/
│   │   ├── index.html                  # Custom landing page with live stats
│   │   ├── stats                       # Live stats JSON (generated by cron)
│   │   └── stats-gen.sh                # Stats generator (CPU, RAM, temp, battery)
│   └── homer/                          # Homer dashboard static files
│       └── assets/
│           └── config.yml              # Homer service configuration
├── srv/
│   └── shared/                         # File Browser root (symlinks to Android storage)
│       ├── movies -> /storage/emulated/0/Movies
│       ├── music  -> /storage/emulated/0/Music
│       ├── photos -> /storage/emulated/0/Pictures
│       ├── documents -> /storage/emulated/0/Documents
│       └── downloads -> /storage/emulated/0/Download
└── root/
    ├── .bashrc                          # Contains: bash /opt/start-server.sh
    ├── .config/jellyfin/
    │   └── encoding.xml                 # Points Jellyfin to jellyfin-ffmpeg6
    └── .ssh/
        └── serveo_key                   # SSH key for Serveo tunnel
```

---

## Troubleshooting

### Test all services at once

```bash
IP=$(hostname -I | awk '{print $1}')
curl -s -o /dev/null -w "SSH:         Port 2222\n"
curl -s -o /dev/null -w "Homer:       %{http_code}\n" http://$IP:8080
curl -s -o /dev/null -w "AdGuard:     %{http_code}\n" http://$IP:8082
curl -s -o /dev/null -w "FileBrowser: %{http_code}\n" http://$IP:8081
curl -s -o /dev/null -w "Jellyfin:    %{http_code}\n" http://$IP:8096
curl -s -o /dev/null -w "Website:     %{http_code}\n" http://$IP:80
```

Expected: `200` or `302` for all services.

### Nginx fails to reload — pid error

```bash
nginx_pid=$(ps aux | grep "nginx: master" | grep -v grep | awk '{print $2}')
echo $nginx_pid > /run/nginx.pid
nginx -s reload
```

### AdGuard won't start — port 53 in use

```bash
systemctl stop systemd-resolved
echo "nameserver 1.1.1.1" > /etc/resolv.conf
pkill AdGuardHome
nohup /opt/AdGuardHome/AdGuardHome > /tmp/adguard.log 2>&1 &
```

### File Browser only accessible on localhost

Always include the `-a 0.0.0.0` flag:

```bash
pkill filebrowser
nohup filebrowser -r /srv/shared -p 8081 -a 0.0.0.0 \
  -d /opt/filebrowser/filebrowser.db > /tmp/filebrowser.log 2>&1 &
```

### Jellyfin — ffmpeg version error

```bash
apt install -y jellyfin-ffmpeg6
cat > /root/.config/jellyfin/encoding.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<EncodingOptions>
  <EncoderAppPath>/usr/lib/jellyfin-ffmpeg/ffmpeg</EncoderAppPath>
  <EncoderAppPathDisplay>/usr/lib/jellyfin-ffmpeg/ffmpeg</EncoderAppPathDisplay>
</EncodingOptions>
EOF
```

### Jellyfin — web UI not found (404)

```bash
ln -sf /usr/share/jellyfin/web /usr/lib/jellyfin/bin/jellyfin-web
```

### SSH — "connection closed with error: end of file"

```bash
# Create missing privilege separation directory
mkdir -p /run/sshd
chmod 755 /run/sshd
/usr/sbin/sshd
```

### Serveo — 502 Bad Gateway on boot

The tunnel tries to connect before the network is ready. The systemd service includes `ExecStartPre=/bin/sleep 15` as a delay. If still failing:

```bash
systemctl restart serveo
systemctl status serveo
```

### Docker / Podman not working

Docker and Podman are **not supported** on this environment. The Android kernel 4.14 lacks cgroup device mounting support, and user namespaces are disabled. Use native service installation as documented in this guide.

### AdGuard login loop behind reverse proxy

This is caused by cookies being set with path `/` instead of `/adguard/`. The Nginx config includes `proxy_cookie_path / /adguard/;` to fix this. Make sure your proxy config matches Phase 5.

---

## Security Notes

- SSH is on non-standard **port 2222** to reduce automated scan noise
- Change the default **File Browser password**  immediately after first login
- AdGuard Home and File Browser require login credentials
- Serveo provides **HTTPS automatically** via their SSL certificate
- AdGuard blocks malicious domains at DNS level for all network devices
- For additional security, consider adding **HTTP Basic Auth** at the Nginx level for sensitive services
- Consider switching to **SSH key authentication** and disabling password auth for SSH

---

## Health Check

Run this on the server to verify all services are running:

```bash
ps aux | grep -E "nginx|AdGuard|filebrowser|jellyfin|autossh|sshd" | grep -v grep
```

Check Serveo tunnel is live:

```bash
curl -I https://YOURSERVERNAME.serveousercontent.com
```

Expected: `HTTP/2 200`

Check DNS blocking is working:

```bash
nslookup doubleclick.net 192.168.100.149
# Expected: Address: 0.0.0.0
```

---

## Tested On

| Component | Value |
|---|---|
| Device | Samsung Galaxy S10+ |
| ROM | InfinityOS |
| Kernel | FreeRunner Kernel 4.14.356 (ARM64) |
| Container Manager | DroidSpaces |
| Container OS | Debian 11 Bullseye (ARM64) |
| Timezone | Asia/Phnom_Penh (UTC+7) |

---

## License

MIT License — free to use, modify, and share.

---

*Running 24/7 on a Samsung S10+ · Debian 11 Bullseye · DroidSpaces · ARM64*
