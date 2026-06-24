# CS 1.6 Server on Raspberry Pi 5

A Counter-Strike 1.6 dedicated server running on Raspberry Pi 5 using native Linux HLDS via SteamCMD + Box86.

## Requirements
- Raspberry Pi 5
- Raspberry Pi OS 64-bit (Debian Trixie)
- Internet connection

## Setup
1. Clone this repo: `git clone <repo-url>`
2. Run `./setup.sh`
3. Configure playit.gg tunnel: `~/playit`
4. Copy `configs/server.cfg` to `~/Steam/steamapps/common/Half-Life/cstrike/`
5. Install services: `sudo cp services/*.service /etc/systemd/system/`
6. Enable services: `sudo systemctl daemon-reload && sudo systemctl enable playit cs16 && sudo systemctl start playit cs16`

## Notes
- Native Linux HLDS is used instead of Windows HLDS + Box86/Wine
- Box86 is only needed for SteamCMD (which is 32-bit x86)
- CG-NAT workaround via playit.gg tunnel
- Server runs headless, managed via systemd

## Connecting
- Local: `connect 192.168.1.140`
- Public: `connect <playit-tunnel-address>`

## Managing the server
```bash
sudo systemctl start cs16
sudo systemctl stop cs16
sudo systemctl restart cs16
journalctl -u cs16 -f
```
