#!/bin/bash
# CS 1.6 Server Setup Script for Raspberry Pi 5
# Raspberry Pi OS 64-bit (Debian Trixie)

set -e

echo "=== CS 1.6 Server Setup ==="
echo ""

# Check Box86 is installed
if ! command -v box86 &> /dev/null; then
    echo "ERROR: Box86 is not installed."
    echo "Please install Box86 via Pi-Apps before running this script:"
    echo "  1. Install Pi-Apps: wget -qO- https://raw.githubusercontent.com/Botspot/pi-apps/master/install | bash"
    echo "  2. Open Pi-Apps GUI"
    echo "  3. Search for Box86 and install it"
    echo "  4. Rerun this script"
    exit 1
fi

echo "Box86 found, continuing..."
echo ""

# System update
echo "[1/7] Updating system..."
sudo apt update && sudo apt upgrade -y

# Dependencies
echo "[2/7] Installing dependencies..."
sudo apt install curl tmux ufw -y

# Fix memory map for Box86
echo "[3/7] Fixing memory map for Box86..."
sudo sysctl -w vm.mmap_min_addr=0
echo "vm.mmap_min_addr=0" | sudo tee /etc/sysctl.d/box86.conf

# SteamCMD
echo "[4/7] Downloading SteamCMD..."
cd ~
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# Download HLDS
echo "[5/7] Downloading HLDS + CS 1.6 (this will take a while)..."
box86 ~/linux32/steamcmd +login anonymous +app_set_config 90 mod cstrike +app_update 90 validate +quit

# steamclient.so symlink
echo "[6/7] Setting up steamclient.so..."
mkdir -p ~/.steam/sdk32
ln -sf ~/Steam/steamapps/common/Half-Life/steamclient.so ~/.steam/sdk32/steamclient.so

# Copy server.cfg
cp ~/cs16-server/configs/server.cfg ~/Steam/steamapps/common/Half-Life/cstrike/server.cfg

# UFW
echo "[7/7] Configuring firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 27015/udp
sudo ufw allow 5900/tcp
sudo ufw enable

# Playit
echo "Downloading playit..."
curl -SsL https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-aarch64 -o ~/playit
chmod +x ~/playit
mkdir -p ~/.config/playit_gg

# Install systemd services
echo "Installing systemd services..."
sudo cp ~/cs16-server/services/playit.service /etc/systemd/system/
sudo cp ~/cs16-server/services/cs16.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable cs16

echo ""
echo "=== Setup complete ==="
echo ""
echo "MANUAL STEPS REQUIRED:"
echo ""
echo "1. PLAYIT TUNNEL:"
echo "   Run: ~/playit"
echo "   Visit the URL it prints in your browser"
echo "   Create a new tunnel: UDP, port 27015, local port 27015"
echo "   After claiming: sudo systemctl enable playit && sudo systemctl start playit"
echo ""
echo "2. COPY WINDOWS CS 1.6 FILES:"
echo "   On your Windows PC run:"
echo "   scp -r \"C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\sprites\" $USER@<PI-IP>:~/Steam/steamapps/common/Half-Life/cstrike/"
echo "   scp -r \"C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\models\" $USER@<PI-IP>:~/Steam/steamapps/common/Half-Life/cstrike/"
echo "   scp -r \"C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\sound\" $USER@<PI-IP>:~/Steam/steamapps/common/Half-Life/cstrike/"
echo "   scp -r \"C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\gfx\" $USER@<PI-IP>:~/Steam/steamapps/common/Half-Life/cstrike/"
echo "   scp -r \"C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\resource\" $USER@<PI-IP>:~/Steam/steamapps/common/Half-Life/cstrike/"
echo ""
echo "3. START THE SERVER:"
echo "   sudo systemctl start cs16"
echo ""
echo "4. CONNECT:"
echo "   Local: connect <PI-IP>"
echo "   Public: connect <playit-tunnel-address>"
