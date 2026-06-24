#!/bin/bash
# CS 1.6 Server Setup Script for Raspberry Pi 5
# Raspberry Pi OS 64-bit (Debian Trixie)
# Uses Windows HLDS via Wine+Box64

set -e

echo "=== CS 1.6 Server Setup ==="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v box86 &> /dev/null; then
    echo "ERROR: Box86 not found. Install via Pi-Apps first."
    exit 1
fi

if ! command -v box64 &> /dev/null; then
    echo "ERROR: Box64 not found. Install via Pi-Apps first."
    exit 1
fi

if [ ! -f /usr/local/bin/wine ]; then
    echo "ERROR: Wine (Pi-Apps version) not found. Install Wine via Pi-Apps first."
    echo "Do NOT install Wine via apt."
    exit 1
fi

echo "All prerequisites found."
echo ""

# System update
echo "[1/8] Updating system..."
sudo apt update && sudo apt upgrade -y

# Dependencies
echo "[2/8] Installing dependencies..."
sudo apt install curl tmux ufw unzip -y

# Fix memory map for Box86
echo "[3/8] Fixing memory map for Box86..."
sudo sysctl -w vm.mmap_min_addr=0
echo "vm.mmap_min_addr=0" | sudo tee /etc/sysctl.d/box86.conf

# SteamCMD
echo "[4/8] Downloading SteamCMD..."
cd ~
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# Download Windows HLDS
echo "[5/8] Downloading Windows HLDS + CS 1.6 (this will take a while)..."
mkdir -p ~/hlds_windows
box86 ~/linux32/steamcmd +@sSteamCmdForcePlatformType windows +login anonymous +force_install_dir ~/hlds_windows +app_set_config 90 mod cstrike +app_update 90 validate +quit

# Copy server.cfg
echo "[6/8] Copying server.cfg..."
cp ~/cs16-server/configs/server.cfg ~/hlds_windows/cstrike/server.cfg

# UFW
echo "[7/8] Configuring firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 27015/udp
sudo ufw allow 5900/tcp
sudo ufw enable

# Playit
echo "[8/8] Downloading playit..."
curl -SsL https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-aarch64 -o ~/playit
chmod +x ~/playit
mkdir -p ~/.config/playit_gg

# Install playit systemd service
echo "Installing playit systemd service..."
sudo cp ~/cs16-server/services/playit.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable playit

# Create start script
cat > ~/start_cs.sh << 'SCRIPT'
#!/bin/bash
cd ~/hlds_windows
/usr/local/bin/wine hlds.exe -game cstrike -ip 192.168.1.140 -port 27015 +maxplayers 12 +map de_dust2 -console -noipx -nojoy +sys_ticrate 100
SCRIPT
chmod +x ~/start_cs.sh

echo ""
echo "=== Setup complete ==="
echo ""
echo "MANUAL STEPS REQUIRED:"
echo ""
echo "1. METAMOD-P:"
echo "   Download: https://github.com/Bots-United/metamod-p/releases/latest"
echo "   unzip metamod-p-*-windows.zip -d ~/hlds_windows/cstrike/addons/metamod/"
echo "   cp ~/hlds_windows/cstrike/addons/metamod/dlls/metamod.dll ~/hlds_windows/cstrike/dlls/"
echo "   Edit ~/hlds_windows/cstrike/liblist.gam: gamedll \"dlls\metamod.dll\""
echo ""
echo "2. AMX MOD X:"
echo "   Download base + cstrike: https://www.amxmodx.org/downloads-new.php"
echo "   unzip amxmodx-*-base-windows.zip -d ~/hlds_windows/cstrike/"
echo "   unzip amxmodx-*-cstrike-windows.zip -d ~/hlds_windows/cstrike/"
echo "   Create ~/hlds_windows/cstrike/addons/metamod/plugins.ini:"
echo "   win32 addons/amxmodx/dlls/amxmodx_mm.dll"
echo ""
echo "3. COPY WINDOWS CS 1.6 FILES (from your Windows PC):"
echo "   scp -r \"C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\sprites\" raspmemco@<PI-IP>:~/hlds_windows/cstrike/"
echo "   scp -r \"C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\models\" raspmemco@<PI-IP>:~/hlds_windows/cstrike/"
echo "   scp -r \"C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\sound\" raspmemco@<PI-IP>:~/hlds_windows/cstrike/"
echo "   scp -r \"C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\gfx\" raspmemco@<PI-IP>:~/hlds_windows/cstrike/"
echo "   scp -r \"C:\Program Files (x86)\Steam\steamapps\common\Half-Life\cstrike\resource\" raspmemco@<PI-IP>:~/hlds_windows/cstrike/"
echo ""
echo "4. PLAYIT TUNNEL:"
echo "   ~/playit"
echo "   Visit the URL → Create tunnel → UDP → port 27015 → local 27015"
echo "   sudo systemctl start playit"
echo ""
echo "5. START THE SERVER:"
echo "   tmux new -s csserver ~/start_cs.sh"
