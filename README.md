# CS 1.6 Server on Raspberry Pi 5

A Counter-Strike 1.6 dedicated server running on Raspberry Pi 5 using Windows HLDS via Wine+Box64, with Metamod-R and AMX Mod X support.

## Hardware & OS
- Raspberry Pi 5 (4GB or 8GB)
- Raspberry Pi OS 64-bit (Debian Trixie)

## Stack
- **HLDS**: Windows version via Wine 11.4 + Box64
- **Metamod**: Metamod-P v1.21p109
- **Plugins**: AMX Mod X 1.10
- **Tunnel**: playit.gg (CG-NAT workaround)
- **Firewall**: ufw

---

## Pre-requisites

These must be installed via Pi-Apps BEFORE running setup.sh.

**Install Pi-Apps:**

    wget -qO- https://raw.githubusercontent.com/Botspot/pi-apps/master/install | bash

Then open Pi-Apps and install:
1. **Box86** — required for SteamCMD (32-bit x86 binary). Reboot after.
2. **Box64** — required for Wine to run Windows binaries on ARM64.
3. **Wine** — must be installed via Pi-Apps, NOT via apt. The apt version cannot run x86 Windows binaries.

---

## Setup

    git clone git@github.com:memirmakar/cs16-pi-server.git
    cd cs16-pi-server
    ./setup.sh

### What setup.sh does
1. Updates the system
2. Installs dependencies (curl, tmux, ufw, unzip)
3. Downloads SteamCMD
4. Downloads Windows HLDS + CS 1.6 via SteamCMD
5. Copies server.cfg
6. Configures ufw firewall rules
7. Downloads playit.gg binary
8. Installs and enables playit systemd service
9. Creates ~/start_cs.sh

---

## Manual Steps

### 1. Metamod-R
Download the Windows binary from [https://github.com/rehlds/metamod-r]

    unzip metamod-p-*-windows.zip -d ~/hlds_windows/cstrike/addons/metamod/
    cp ~/hlds_windows/cstrike/addons/metamod/dlls/metamod.dll ~/hlds_windows/cstrike/dlls/

Edit ~/hlds_windows/cstrike/liblist.gam and change the gamedll line to:

    gamedll "dlls\metamod.dll"

### 2. AMX Mod X
Download base + cstrike Windows packages from https://www.amxmodx.org/downloads-new.php. Goes to cstrike/addon

    unzip amxmodx-*-base-windows.zip -d ~/hlds_windows/cstrike/
    unzip amxmodx-*-cstrike-windows.zip -d ~/hlds_windows/cstrike/

Create ~/hlds_windows/cstrike/addons/metamod/plugins.ini with:

    win32 addons/amxmodx/dlls/amxmodx_mm.dll

### 3. Copy Windows CS 1.6 Resource Files
The HLDS download is missing sprites, models, sounds. Copy from a Windows CS 1.6 install (run on your Windows PC): (Probably not necessary)

    scp -r "C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\sprites" raspmemco@<PI-IP>:~/hlds_windows/cstrike/
    scp -r "C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\models" raspmemco@<PI-IP>:~/hlds_windows/cstrike/
    scp -r "C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\sound" raspmemco@<PI-IP>:~/hlds_windows/cstrike/
    scp -r "C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\gfx" raspmemco@<PI-IP>:~/hlds_windows/cstrike/
    scp -r "C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\resource" raspmemco@<PI-IP>:~/hlds_windows/cstrike/

### 4. Playit.gg Tunnel
Temp workaround.

    ~/playit

Visit the URL it prints in your browser. Create a new tunnel:
- Type: UDP
- Local port: 27015
- External port: 27015

After setup:

    sudo systemctl start playit

---

## Running the Server

The server runs in a tmux session for live console access.

**Start:**

    tmux new -s csserver ~/start_cs.sh

**Detach** (server keeps running in background): Ctrl+B then D

**Reattach:**

    tmux attach -t csserver

---

## Live Console Commands

Type directly in the HLDS console window:

    changelevel de_inferno       # change map
    map de_nuke                  # change map, restart round
    maxplayers 16                # change player limit
    sv_password mypassword       # password protect
    exec server.cfg              # reload config
    meta list                    # list Metamod plugins
    amxx plugins                 # list AMX Mod X plugins

---

## Adding Plugins

1. Drop .amxx file into ~/hlds_windows/cstrike/addons/amxmodx/plugins/
2. Add plugin name to ~/hlds_windows/cstrike/addons/amxmodx/configs/plugins.ini
3. Restart the server

To sync plugins to the repo:

    cp -r ~/hlds_windows/cstrike/addons ~/cs16-server/
    cd ~/cs16-server && git add . && git commit -m "Add plugin" && git push

---

## Updating Config

Edit configs/server.cfg on any machine, push to GitHub, then on the Pi:

    ~/cs16-server/update.sh

---

## Services

Only playit runs as a systemd service (auto-starts on boot):

    sudo systemctl status playit
    sudo systemctl restart playit
    sudo systemctl stop playit

---

## Connecting

- **Local network:** connect 192.168.1.140
- **Public via playit:** connect 147.185.221.27:31136

---

## Network Notes

- With CG-NAT — port forwarding alone does not work for external connections
- playit.gg tunnel is used as a CG-NAT workaround (Romania routing, ~250ms for distant players)
- Port 27015 UDP is forwarded on the Huawei LG8245X6-50 router for potential future use
- VNC access via WayVNC on port 5900 — connect with TigerVNC Viewer to 192.168.1.140:5900

---

## Firewall Rules

    sudo ufw status
    22/tcp    SSH (local only)
    27015/udp CS 1.6
    5900/tcp  VNC

---

## Troubleshooting

**Port already in use:**

    sudo fuser -k 27015/udp

**playit tunnel offline:**

    sudo systemctl restart playit

**VNC not connecting:**

    sudo systemctl status wayvnc
    sudo ufw allow 5900/tcp

**Wine crashes on player connect:**
Usually caused by an incompatible AMX Mod X plugin. Disable plugins one by one in plugins.ini to isolate.

**Server IP shows 127.0.1.1 instead of local IP:**
Always pass -ip 192.168.1.140 explicitly in the start command.
