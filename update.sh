#!/bin/bash
# Pulls the latest config + addons from this repo into the live server, then
# reminds you to restart. Run on the Pi.

set -e

HLDS=~/Steam/steamapps/common/Half-Life/cstrike
REPO=~/cs16-server

cd "$REPO"
git pull

# server.cfg
if [ -f configs/server.cfg ]; then
    cp configs/server.cfg "$HLDS/server.cfg"
    echo "Updated server.cfg"
fi

# addons (plugins, configs, menus)
if [ -d addons ]; then
    cp -r addons/. "$HLDS/addons/"
    echo "Updated addons"
fi

echo ""
echo "Done. Restart the server to apply:"
echo "  - if running in tmux: reattach (tmux attach -t csserver) and run 'exec server.cfg' or restart the process"
echo "  - if running in Docker: docker restart cs16"
