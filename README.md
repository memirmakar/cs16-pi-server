# CS 1.6 Server on Raspberry Pi 5

A Counter-Strike 1.6 dedicated server running on a Raspberry Pi 5: **steam_legacy HLDS + ReHLDS 3.13 + Metamod-R + AMX Mod X**, all running through **ExaGear** (x86-on-ARM64).

I built this after hitting a wall of version-mismatch and emulation issues, so this repo is mostly a note to myself for rebuilding from scratch. If you're attempting the same thing, the three things that cost me the most time are up top. You don't need to use the scripts in the repo. Following the README manually is enough.

## TL;DR — the three gotchas

1. **Use ReHLDS 3.13, not the latest.** Newer builds reject standard maps with a `CalcSurfaceExtents: Bad surface extents` error.
2. **Use the `steam_legacy` branch of HLDS.** ReHLDS is only compatible with the pre-anniversary engine (`<= 8684`). The SteamCMD command in `setup.sh` already does this.
3. **Set `mp_consistency 0`.** Without it, post-anniversary clients get kicked with a `Bad file sprites/...` error on connect.
4. **Use Exagear, not Box86. AMX-Mod-X crashes the server on Box86.

---

## Stack

| Component | Version / Notes |
|-----------|-----------------|
| HLDS | Linux `steam_legacy` branch, run via ExaGear |
| Engine | ReHLDS 3.13 (replaces `engine_i486.so`) |
| Game DLL | ReGameDLL_CS (replaces `cs.so`) |
| Metamod | Metamod-R 1.3.0.149 |
| Plugins | AMX Mod X 1.10 |
| Firewall | ufw |

**Performance:** ~400–450 FPS server tick rate, ~8% CPU with players connected.

## Hardware & OS

- Raspberry Pi 5 (4GB or 8GB)
- Raspberry Pi OS 64-bit (Debian Trixie)

---

## Networking

For **LAN play**: assign the Pi a static IP in your modem (this is so that your Pi IP does not change inside your LAN network) and port-forward UDP `27015`. That's all you need.

For a **public server**: you also need to handle reachability from the internet.
- If you have a normal public IP, port-forwarding is enough.
- If you're behind **CG-NAT** , port-forwarding alone won't work — route through an external machine with a public IP (e.g. an FRP relay on a friend's connection or a VPS).

---

## Prerequisites

Install these before running `setup.sh`:

- **ExaGear** — runs the x86 Linux binaries on ARM64. Follow https://github.com/ryanfortner/exagear-rpi. **You run the server from inside the `sudo exagear` shell.**
- **Steam** — may need to be installed via Pi-Apps (unconfirmed, install if SteamCMD complains about missing client libraries).

---

## Setup

```
git clone git@github.com:memirmakar/cs16-pi-server.git
cd cs16-pi-server
./setup.sh
```

### What `setup.sh` does

1. Updates the system
2. Installs dependencies (`curl`, `tmux`, `ufw`, `unzip`)
3. Downloads SteamCMD
4. Downloads `steam_legacy` HLDS via SteamCMD
5. Copies in the ReHLDS `engine_i486.so`
6. Sets up Metamod-R
7. Sets up AMX Mod X 1.10
8. Copies `server.cfg` into place
9. Configures the ufw firewall

After `setup.sh`, complete the manual steps below.

---

## Manual steps

### 1. ReHLDS 3.13

```
unzip rehlds-bin-3.13.0.788.zip -d rehlds
cp rehlds/bin/linux32/* ~/Steam/steamapps/common/Half-Life/
```

Download: https://github.com/dreamstalker/rehlds/releases/download/3.13.0.788/rehlds-bin-3.13.0.788.zip

### 2. Metamod-R

```
mkdir -p ~/Steam/steamapps/common/Half-Life/cstrike/addons/metamod/dlls
cp addons/metamod/metamod_i386.so ~/Steam/steamapps/common/Half-Life/cstrike/addons/metamod/dlls/
```

Point HLDS at Metamod by editing `liblist.gam`:

```
sed -i 's|gamedll_linux "dlls/cs.so"|gamedll_linux "addons/metamod/dlls/metamod_i386.so"|' ~/Steam/steamapps/common/Half-Life/cstrike/liblist.gam
```

Download: https://github.com/theAsmodai/metamod-r/releases/latest

### 3. AMX Mod X 1.10

Download the base + cstrike Linux packages from https://www.amxmodx.org/downloads-new.php, then:

```
tar zxvf amxmodx-*-base-linux.tar.gz -C ~/Steam/steamapps/common/Half-Life/cstrike/
tar zxvf amxmodx-*-cstrike-linux.tar.gz -C ~/Steam/steamapps/common/Half-Life/cstrike/
```

If `plugins.ini` for Metamod is missing, create `~/Steam/steamapps/common/Half-Life/cstrike/addons/metamod/plugins.ini` with:

```
linux addons/amxmodx/dlls/amxmodx_mm_i386.so
```

### 4. Disable the consistency check

Add to `server.cfg` (or the launch command). Without it, post-anniversary clients get a bad-sprite kick on connect:

```
mp_consistency 0
```

---

## Running the server

```
tmux new -s csserver ~/start_cs.sh
```

Detach with `Ctrl+B` then `D`. Reattach with `tmux attach -t csserver`.

### Live console commands

```
changelevel de_inferno     # change map
map de_nuke                # change map (restarts round)
maxplayers 16
sv_password mypassword
exec server.cfg            # reload config
meta list                  # list Metamod plugins
amxx plugins               # list AMX Mod X plugins
```

---

## Adding plugins

1. Drop the `.amxx` file into `~/Steam/steamapps/common/Half-Life/cstrike/addons/amxmodx/plugins/`
2. Add the plugin name to `~/Steam/steamapps/common/Half-Life/cstrike/addons/amxmodx/configs/plugins.ini`
3. Restart the server

## Admin setup

Edit `~/Steam/steamapps/common/Half-Life/cstrike/addons/amxmodx/configs/users.ini`:

```
"STEAM_0:0:XXXXXXX" "" "abcdefghijklmnopqrstu" "ce"
```

Find your Steam ID at https://steamidfinder.com.

## Updating config

Edit `configs/server.cfg`, push to GitHub, then on the Pi:

```
~/cs16-server/update.sh
```

---

## Connecting

- **LAN:** `connect 192.168.1.140`

## Firewall rules

```
sudo ufw status
# 22/tcp     SSH
# 27015/udp  CS 1.6
# 5900/tcp   VNC
```

---

## Troubleshooting

**Port already in use**

```
sudo fuser -k 27015/udp
```

**`Bad surface extents` error** — you're on a too-new ReHLDS. Use 3.13. ReHLDS only supports the `steam_legacy` HLDS.

**Sprite / consistency errors on connect** — add `mp_consistency 0`.

**Server IP shows `127.0.1.1`** — pass `-ip 192.168.1.140` explicitly. On the Windows HLDS (Wine) the IP displays correctly; on Linux it shows the loopback alias even though the server still binds and works fine, so it's cosmetic.
