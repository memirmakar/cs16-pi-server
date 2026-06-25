#!/bin/bash
HLDS=~/Steam/steamapps/common/Half-Life/cstrike

cd ~/cs16-server
git pull

# server.cfg
cp configs/server.cfg $HLDS/server.cfg

# addons (plugins, configs)
if [ -d addons ]; then
    cp -r addons/ $HLDS/
fi

echo "Server updated."
