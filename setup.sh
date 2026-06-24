#!/bin/bash
# CS 1.6 Server Setup Script for Raspberry Pi 5
# Raspberry Pi OS 64-bit (Debian Trixie)

set -e

echo "=== CS 1.6 Server Setup ==="

# System update
sudo apt update && sudo apt upgrade -y

# Dependencies
sudo apt install curl tmux ufw -y

# Box86 for SteamCMD
sudo dpkg --add-architecture armhf
wget https://ryanfortner.github.io/box86-debs/box86.list -O /etc/apt/sources.list.d/box86.list
wget -qO- https://ryanfortner.github.io/box86-debs/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/box86.gpg
sudo apt update
sudo apt install box86-rpi4arm64 libc6:armhf -y

# Fix memory map for Box86
sudo sysctl -w vm.mmap_min_addr=0
echo "vm.mmap_min_addr=0" | sudo tee /etc/sysctl.d/box86.conf

# SteamCMD
cd ~
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# Download HLDS
box86 ~/linux32/steamcmd +login anonymous +app_set_config 90 mod cstrike +app_update 90 validate +quit

# steamclient.so symlink
mkdir -p ~/.steam/sdk32
ln -sf ~/Steam/steamapps/common/Half-Life/steamclient.so ~/.steam/sdk32/steamclient.so

# UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 27015/udp
sudo ufw allow 5900/tcp
sudo ufw enable

# Playit
curl -SsL https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-aarch64 -o ~/playit
chmod +x ~/playit
mkdir -p ~/.config/playit_gg

echo "=== Setup complete ==="
echo "1. Copy server.cfg to ~/Steam/steamapps/common/Half-Life/cstrike/"
echo "2. Install systemd services with: sudo cp services/*.service /etc/systemd/system/"
echo "3. Run: sudo systemctl daemon-reload && sudo systemctl enable playit cs16"
