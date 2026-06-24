#!/bin/bash
cd ~/cs16-server
git pull
cp configs/server.cfg ~/Steam/steamapps/common/Half-Life/cstrike/server.cfg
sudo systemctl restart cs16
echo "Server updated and restarted."
