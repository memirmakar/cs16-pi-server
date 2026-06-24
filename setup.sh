#!/bin/bash
# CS 1.6 Server Setup Script for Raspberry Pi 5
# Raspberry Pi OS 64-bit (Debian Trixie)
# Uses Linux HLDS (steam_legacy) + ReHLDS + Metamod-R + AMX Mod X via Box86

set -e

echo "=== CS 1.6 Server Setup ==="
echo ""

# Check prerequisites
if ! command -v box86 &> /dev/null; then
    echo "ERROR: Box86 not found. Install via Pi-Apps first."
    exit 1
fi

echo "Box86 found, continuing..."
echo ""

# System update
echo "[1/6] Updating system..."
sudo apt update && sudo apt upgrade -y

# Dependencies
echo "[2/6] Installing dependencies..."
sudo apt install curl tmux ufw unzip -y

# SteamCMD
echo "[3/6] Downloading SteamCMD..."
cd ~
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# Download steam_legacy HLDS
echo "[4/6] Downloading steam_legacy HLDS (this will take a while)..."
box86 ~/linux32/steamcmd +login anonymous +app_set_config 90 mod cstrike +app_update 90 -beta steam_legacy validate +quit

# Copy server.cfg
echo "[5/6] Copying server.cfg..."
cp ~/cs16-server/configs/server.cfg ~/Steam/steamapps/common/Half-Life/cstrike/server.cfg

# UFW
echo "[6/6] Configuring firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 27015/udp
sudo ufw allow 5900/tcp
sudo ufw enable

# Create start script
cat > ~/start_cs.sh << 'SCRIPT'
#!/bin/bash
cd ~/Steam/steamapps/common/Half-Life
./hlds_run -game cstrike -ip 192.168.1.140 -port 27015 +maxplayers 12 +map de_dust2 +sys_ticrate 1000 +mp_consistency 0
SCRIPT
chmod +x ~/start_cs.sh

echo ""
echo "=== Setup complete ==="
echo ""
echo "MANUAL STEPS REQUIRED:"
echo ""
echo "1. REHLDS 3.13:"
echo "   Download: https://github.com/dreamstalker/rehlds/releases/download/3.13.0.788/rehlds-bin-3.13.0.788.zip"
echo "   unzip rehlds-bin-3.13.0.788.zip -d rehlds"
echo "   cp rehlds/bin/linux32/engine_i486.so ~/Steam/steamapps/common/Half-Life/"
echo ""
echo "2. METAMOD-R:"
echo "   Download: https://github.com/theAsmodai/metamod-r/releases/latest"
echo "   mkdir -p ~/Steam/steamapps/common/Half-Life/cstrike/addons/metamod/dlls"
echo "   cp addons/metamod/metamod_i386.so ~/Steam/steamapps/common/Half-Life/cstrike/addons/metamod/dlls/"
echo "   sed -i 's|gamedll_linux \"dlls/cs.so\"|gamedll_linux \"addons/metamod/dlls/metamod_i386.so\"|' ~/Steam/steamapps/common/Half-Life/cstrike/liblist.gam"
echo ""
echo "3. AMX MOD X 1.10:"
echo "   Download base + cstrike Linux: https://www.amxmodx.org/downloads-new.php"
echo "   tar zxvf amxmodx-*-base-linux.tar.gz -C ~/Steam/steamapps/common/Half-Life/cstrike/"
echo "   tar zxvf amxmodx-*-cstrike-linux.tar.gz -C ~/Steam/steamapps/common/Half-Life/cstrike/"
echo ""
echo "4. START THE SERVER:"
echo "   tmux new -s csserver ~/start_cs.sh"
