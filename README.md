# CS 1.6 Server on Raspberry Pi 5

Wanted to host a ReHLDS CS server on my Pi 5, but ran into some issues while setting it up so made a guide on how to do it again if I am forced to. 
TLDR: USE ReHLDS 3.13, not the latest version. Use the steam_legacy version of CS (command in setup.sh). Use mp_consistency 0 in server.

A Counter-Strike 1.6 dedicated server running on Raspberry Pi 5 using Linux HLDS (steam_legacy) + ReHLDS engine (3.13) + Metamod-R + AMX Mod X, running through Box86. Setup script is so that I don't have to start from scratch. 

## Note: You need to attach your Pi to a static IP in your modem + port forward 27015. If you're in a CG-NAT network you will also need an external VPS to route through if you want to make your server public. For LAN, port forwarding and a static ip on your Pi is enough.

## Hardware & OS
- Raspberry Pi 5 (4GB or 8GB)
- Raspberry Pi OS 64-bit (Debian Trixie)

## Plugins etc.
- **HLDS**: Linux steam_legacy branch via Box86
- **Engine**: ReHLDS 3.13 (replaces engine_i486.so)
- **Game DLL**: ReGameDLL_CS (replaces cs.so)
- **Metamod**: Metamod-R (1.3.0.149)
- **Plugins**: AMX Mod X 1.10
- **Firewall**: ufw

## Performance
- ~400-450 FPS server tick rate 
- ~8% CPU usage with players connected

---

## Pre-requisites

Install via Pi-Apps BEFORE running setup.sh:

    wget -qO- https://raw.githubusercontent.com/Botspot/pi-apps/master/install | bash

Then open Pi-Apps and install:
1. **Box86** — required to run x86 Linux binaries on ARM64. Make sure it adds the kernel parameter that fixes the memory issue (it will ask for a prompt). Reboot after.
2. **Steam** - Might be required to install this through Pi-apps though I'm not sure.

---

## Setup

    git clone git@github.com:memirmakar/cs16-pi-server.git
    cd cs16-pi-server
    ./setup.sh

### What setup.sh does
1. Updates the system
2. Installs dependencies (curl, tmux, ufw, unzip)
3. Downloads SteamCMD
4. Downloads steam_legacy HLDS via SteamCMD
5. Copies ReHLDS engine_i486.so
6. Sets up Metamod-R
7. Sets up AMX Mod X 1.10
8. Copies server.cfg
9. Configures ufw firewall

---

## Manual Steps

### 1. Download ReHLDS 3.13
Download from https://github.com/dreamstalker/rehlds/releases/download/3.13.0.788/rehlds-bin-3.13.0.788.zip

    unzip rehlds-bin-3.13.0.788.zip -d rehlds
    cp rehlds/bin/linux32/* ~/Steam/steamapps/common/Half-Life/ 
    
### 2. Metamod-R
Download from https://github.com/theAsmodai/metamod-r/releases/latest

    mkdir -p ~/Steam/steamapps/common/Half-Life/cstrike/addons/metamod/dlls
    cp addons/metamod/metamod_i386.so ~/Steam/steamapps/common/Half-Life/cstrike/addons/metamod/dlls/

Edit liblist.gam:

    sed -i 's|gamedll_linux "dlls/cs.so"|gamedll_linux "addons/metamod/dlls/metamod_i386.so"|' ~/Steam/steamapps/common/Half-Life/cstrike/liblist.gam

### 3. AMX Mod X 1.10
Download base + cstrike Linux packages from https://www.amxmodx.org/downloads-new.php

    tar zxvf amxmodx-*-base-linux.tar.gz -C ~/Steam/steamapps/common/Half-Life/cstrike/
    tar zxvf amxmodx-*-cstrike-linux.tar.gz -C ~/Steam/steamapps/common/Half-Life/cstrike/

### 4. Fix consistency check (if you don't do this you will get bad sprite error when players connect from post-anniversary clients)
Add to server launch or server.cfg:

    mp_consistency 0


## Running the Server

    tmux new -s csserver ~/start_cs.sh

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


## Connecting

- Local network: connect 192.168.1.140


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
Always pass -ip 192.168.1.140 explicitly. I noticed when running the Windows version of HLDS through Wine + Box86 the IP displays correctly. On Linux though, even though the IP isn't shown as your specified IP it still works so it's fine I guess.
