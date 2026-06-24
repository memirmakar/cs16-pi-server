# CS 1.6 Server on Raspberry Pi 5

A Counter-Strike 1.6 dedicated server running on Raspberry Pi 5 using native Linux HLDS via SteamCMD + Box86.

## Requirements
- Raspberry Pi 5
- Raspberry Pi OS 64-bit (Debian Trixie)
- Internet connection
- A Windows PC with CS 1.6 installed (for resource files)
- A playit.gg account (free) for public access behind CG-NAT

## Pre-requisite: Install Box86 via Pi-Apps
Box86 must be installed via Pi-Apps **before** running setup.sh. Pi-Apps handles the necessary kernel patches for Box86 to work correctly on Pi 5.

```bash
wget -qO- https://raw.githubusercontent.com/Botspot/pi-apps/master/install | bash
```

Then open Pi-Apps from the desktop, search for **Box86** and install it. Reboot after installation.

## Quick Setup
```bash
git clone git@github.com:memirmakar/cs16-pi-server.git
cd cs16-pi-server
./setup.sh
```

Then follow the manual steps printed at the end.

## Manual Steps (cannot be automated)

### 1. Playit.gg Tunnel
Required if your ISP uses CG-NAT (common in Turkey with TurkNet).
- Run `~/playit` and visit the URL it prints
- Create a new tunnel: UDP, port 27015, local port 27015
- Note your tunnel address (e.g. `147.x.x.x:31136`)
- After setup: `sudo systemctl enable playit && sudo systemctl start playit`

### 2. Windows CS 1.6 Resource Files
The Linux HLDS download is missing sprites, models, sounds and other resources. Copy them from a Windows CS 1.6 install:
```cmd
scp -r "C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\sprites" user@<PI-IP>:~/Steam/steamapps/common/Half-Life/cstrike/
scp -r "C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\models" user@<PI-IP>:~/Steam/steamapps/common/Half-Life/cstrike/
scp -r "C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\sound" user@<PI-IP>:~/Steam/steamapps/common/Half-Life/cstrike/
scp -r "C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\gfx" user@<PI-IP>:~/Steam/steamapps/common/Half-Life/cstrike/
scp -r "C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\resource" user@<PI-IP>:~/Steam/steamapps/common/Half-Life/cstrike/
```

## Managing the Server
```bash
sudo systemctl start cs16      # start
sudo systemctl stop cs16       # stop
sudo systemctl restart cs16    # restart
journalctl -u cs16 -f          # live logs
```

## Connecting
- **Local network:** `connect 192.168.1.140`
- **Public (via playit):** `connect <playit-tunnel-address>`

## Notes
- Box86 is only needed for SteamCMD (32-bit x86 binary). HLDS itself runs natively on ARM64.
- If your ISP uses CG-NAT, port forwarding alone won't work. Use playit.gg tunnel.
- server.cfg is in `configs/server.cfg` — edit before running setup.sh or copy manually after.
- VNC access via WayVNC on port 5900 (Wayland session).
