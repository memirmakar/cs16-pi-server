# CS 1.6 Server on Raspberry Pi 5

A Counter-Strike 1.6 dedicated server running on Raspberry Pi 5 using Linux HLDS (steam_legacy) + ReHLDS engine + Metamod-R + AMX Mod X, running natively through Box86.

## Hardware & OS
- Raspberry Pi 5 (4GB or 8GB)
- Raspberry Pi OS 64-bit (Debian Trixie)

## Stack
- **HLDS**: Linux steam_legacy branch via Box86
- **Engine**: ReHLDS 3.13 (replaces engine_i486.so)
- **Game DLL**: ReGameDLL_CS (replaces cs.so)
- **Metamod**: Metamod-R
- **Plugins**: AMX Mod X 1.10
- **Firewall**: ufw

## Performance
- ~400-450 FPS server tick rate
- ~8% CPU usage with players connected
- Much better performance than Windows HLDS + Wine approach

---

## Pre-requisites

Install via Pi-Apps BEFORE running setup.sh:

    wget -qO- https://raw.githubusercontent.com/Botspot/pi-apps/master/install | bash

Then open Pi-Apps and install:
1. **Box86** — required to run x86 Linux binaries on ARM64. Reboot after.

---

## Setup

    git clone git@github.com:memirmakar/cs16-pi-server.git
    cd cs16-pi-server
    ./setup.sh

### What setup.sh does
1. Updates the system
2. Installs dependencies (curl, tmux, ufw, unzip)
3. Fixes Box86 memory map (vm.mmap_min_addr=0)
4. Downloads SteamCMD
5. Downloads steam_legacy HLDS via SteamCMD
6. Copies ReHLDS engine_i486.so
7. Sets up Metamod-R
8. Sets up AMX Mod X 1.10
9. Copies server.cfg
10. Configures ufw firewall

---

## Manual Steps

### 1. Download ReHLDS 3.13
Download from https://github.com/dreamstalker/rehlds/releases/download/3.13.0.788/rehlds-bin-3.13.0.788.zip

    unzip rehlds-bin-3.13.0.788.zip -d rehlds
    cp rehlds/bin/linux32/engine_i486.so ~/Steam/steamapps/common/Half-Life/

### 2. Metamod-R
Download from https://github.com/theAsmodai/metamod-r/releases/latest

    mkdir -p ~/Steam/steamapps/common/Half-Life/cstrike/addons/metamod/dlls
    cp addons/metamod/metamod_i386.so ~/Steam/steamapps/common/Half-Life/cstrike/addons/metamod/dlls/

Edit liblist.gam:

    sed -i 's|gamedll_linux "dlls/cs.so"|gamedll_linux "addons/metamod/dlls/metamod_i386.so"|' ~/Steam/steamapps/common/Half-Life/cstrike/liblist.gam

Create plugins.ini:

    linux addons/amxmodx/dlls/amxmodx_mm_i386.so

### 3. AMX Mod X 1.10
Download base + cstrike Linux packages from https://www.amxmodx.org/downloads-new.php

    tar zxvf amxmodx-*-base-linux.tar.gz -C ~/Steam/steamapps/common/Half-Life/cstrike/
    tar zxvf amxmodx-*-cstrike-linux.tar.gz -C ~/Steam/steamapps/common/Half-Life/cstrike/

### 4. Fix consistency check
Add to server launch or server.cfg:

    mp_consistency 0

### 5. Copy Windows CS 1.6 Resource Files
Run on your Windows PC:

    scp -r "C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\sprites" raspmemco@192.168.1.140:~/Steam/steamapps/common/Half-Life/cstrike/
    scp -r "C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\models" raspmemco@192.168.1.140:~/Steam/steamapps/common/Half-Life/cstrike/
    scp -r "C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\sound" raspmemco@192.168.1.140:~/Steam/steamapps/common/Half-Life/cstrike/
    scp -r "C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\gfx" raspmemco@192.168.1.140:~/Steam/steamapps/common/Half-Life/cstrike/
    scp -r "C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\resource" raspmemco@192.168.1.140:~/Steam/steamapps/common/Half-Life/cstrike/

---

## Running the Server

    tmux new -s csserver ~/start_cs.sh

Detach: Ctrl+B then D
Reattach: tmux attach -t csserver

---

## Live Console Commands

    changelevel de_inferno
    map de_nuke
    maxplayers 16
    sv_password mypassword
    exec server.cfg
    meta list
    amxx plugins

---

## Adding Plugins

1. Drop .amxx file into ~/Steam/steamapps/common/Half-Life/cstrike/addons/amxmodx/plugins/
2. Add plugin name to ~/Steam/steamapps/common/Half-Life/cstrike/addons/amxmodx/configs/plugins.ini
3. Restart server

---

## Admin Setup

Edit ~/Steam/steamapps/common/Half-Life/cstrike/addons/amxmodx/configs/users.ini:

    "STEAM_0:0:XXXXXXX" "" "abcdefghijklmnopqrstu" "ce"

Find your Steam ID at https://steamidfinder.com

---

## Updating Config

Edit configs/server.cfg, push to GitHub, then on Pi:

    ~/cs16-server/update.sh

---

## Services

Nothing runs as systemd — server is started manually via tmux.
playit.gg is no longer used — server is accessible locally only unless CG-NAT is resolved.

---

## Connecting

- Local network: connect 192.168.1.140
- Via DDNS: connect yaralisiskomc.servecounterstrike.com (local network only due to CG-NAT)

---

## Network Notes

- TurkNet uses CG-NAT — external connections not possible without tunnel
- DDNS hostname yaralisiskomc.servecounterstrike.com tracks your WAN IP via No-IP
- Port 27015 UDP forwarded on Huawei LG8245X6-50 router
- VNC access via WayVNC on port 5900

---

## Firewall Rules

    sudo ufw status
    22/tcp    SSH
    27015/udp CS 1.6
    5900/tcp  VNC

---

## Troubleshooting

Port in use:

    sudo fuser -k 27015/udp

Bad surface extents error:
Use ReHLDS 3.13, NOT 3.15. ReHLDS is only compatible with steam_legacy HLDS.

Sprite/consistency errors:
Add mp_consistency 0 to server launch parameters.

Server IP shows 127.0.1.1:
Always pass -ip 192.168.1.140 explicitly.
