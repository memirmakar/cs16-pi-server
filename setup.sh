#!/bin/bash
# CS 1.6 Server Setup Script for Raspberry Pi 5
# Raspberry Pi OS 64-bit (Debian Trixie)
# Stack: steam_legacy HLDS + ReHLDS 3.13 + Metamod-R + AMX Mod X, run via ExaGear.
#
# Prerequisite: ExaGear must already be installed (https://github.com/ryanfortner/exagear-rpi).
# SteamCMD and HLDS are x86, so the download steps below run under ExaGear.

set -e

echo "=== CS 1.6 Server Setup ==="
echo ""

# --- Prerequisite check -----------------------------------------------------
if ! command -v exagear &> /dev/null; then
    echo "ERROR: ExaGear not found."
    echo "Install it first: https://github.com/ryanfortner/exagear-rpi"
    exit 1
fi
echo "ExaGear found, continuing..."
echo ""

# --- System ------------------------------------------------------------------
echo "[1/6] Updating system..."
sudo apt-get update && sudo apt-get upgrade -y

echo "[2/6] Installing dependencies..."
sudo apt-get install -y curl tmux ufw unzip

# --- SteamCMD ----------------------------------------------------------------
echo "[3/6] Downloading SteamCMD..."
cd ~
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# --- HLDS (steam_legacy) -----------------------------------------------------
# steamcmd is x86, so run it inside ExaGear.
echo "[4/6] Downloading steam_legacy HLDS (this takes a while)..."
exagear -- ~/linux32/steamcmd \
    +login anonymous \
    +app_set_config 90 mod cstrike \
    +app_update 90 -beta steam_legacy validate \
    +quit

# steamclient.so symlink (silences a harmless dlopen warning)
mkdir -p ~/.steam/sdk32
ln -sf ~/Steam/steamapps/common/Half-Life/steamclient.so ~/.steam/sdk32/steamclient.so

# --- server.cfg --------------------------------------------------------------
echo "[5/6] Copying server.cfg..."
cp ~/cs16-pi-server/configs/server.cfg ~/Steam/steamapps/common/Half-Life/cstrike/server.cfg

# --- Firewall ----------------------------------------------------------------
echo "[6/6] Configuring firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 27015/udp
sudo ufw allow 5900/tcp
sudo ufw --force enable

# --- start script ------------------------------------------------------------
cat > ~/start_cs.sh << 'SCRIPT'
#!/bin/bash
cd ~/Steam/steamapps/common/Half-Life
./hlds_run -game cstrike -ip 192.168.1.140 -port 27015 +maxplayers 12 +map de_dust2 +sys_ticrate 1000 +mp_consistency 0
SCRIPT
chmod +x ~/start_cs.sh

cat << 'EOF'

=== Setup complete ===

MANUAL STEPS REMAINING (see README for details):

1. ReHLDS 3.13:
   Download https://github.com/dreamstalker/rehlds/releases/download/3.13.0.788/rehlds-bin-3.13.0.788.zip
   unzip rehlds-bin-3.13.0.788.zip -d rehlds
   cp rehlds/bin/linux32/* ~/Steam/steamapps/common/Half-Life/

2. Metamod-R:
   Download https://github.com/theAsmodai/metamod-r/releases/latest
   mkdir -p ~/Steam/steamapps/common/Half-Life/cstrike/addons/metamod/dlls
   cp addons/metamod/metamod_i386.so ~/Steam/steamapps/common/Half-Life/cstrike/addons/metamod/dlls/
   sed -i 's|gamedll_linux "dlls/cs.so"|gamedll_linux "addons/metamod/dlls/metamod_i386.so"|' \
       ~/Steam/steamapps/common/Half-Life/cstrike/liblist.gam

3. AMX Mod X 1.10 (https://www.amxmodx.org/downloads-new.php):
   tar zxvf amxmodx-*-base-linux.tar.gz    -C ~/Steam/steamapps/common/Half-Life/cstrike/
   tar zxvf amxmodx-*-cstrike-linux.tar.gz -C ~/Steam/steamapps/common/Half-Life/cstrike/
   Ensure addons/metamod/plugins.ini contains:
       linux addons/amxmodx/dlls/amxmodx_mm_i386.so

4. Start the server (from inside an ExaGear shell):
   sudo exagear
   tmux new -s csserver ~/start_cs.sh
EOF
