#!/bin/bash
# Copies the *tracked* parts of the live server (configs, plugins, menus) into
# the repo, so you can commit them. Large assets (maps/sounds/models/sprites)
# are intentionally NOT copied -- they're gitignored and re-fetched on setup.
# Run on the Pi.

set -e

HLDS=~/Steam/steamapps/common/Half-Life/cstrike
REPO=~/cs16-server

mkdir -p "$REPO/configs"
mkdir -p "$REPO/addons/amxmodx/configs"
mkdir -p "$REPO/addons/amxmodx/plugins"
mkdir -p "$REPO/addons/metamod"

# Core server config
cp "$HLDS/server.cfg"            "$REPO/configs/server.cfg"            2>/dev/null || true
cp "$HLDS/mapcycle.txt"          "$REPO/configs/mapcycle.txt"          2>/dev/null || true
cp "$HLDS/maps.ini"              "$REPO/configs/maps.ini"              2>/dev/null || true

# AMX Mod X configs (admins kept as a sample, not the real users.ini)
cp "$HLDS/addons/amxmodx/configs/plugins.ini" "$REPO/addons/amxmodx/configs/plugins.ini" 2>/dev/null || true
cp "$HLDS/addons/amxmodx/configs/amxx.cfg"    "$REPO/addons/amxmodx/configs/amxx.cfg"    2>/dev/null || true
cp "$HLDS/addons/amxmodx/configs/maps.ini"    "$REPO/addons/amxmodx/configs/maps.ini"    2>/dev/null || true
if [ -f "$HLDS/addons/amxmodx/configs/users.ini" ]; then
    cp "$HLDS/addons/amxmodx/configs/users.ini" "$REPO/addons/amxmodx/configs/users.ini.sample"
fi

# Compiled plugins (.amxx are small and cross-platform -- safe to track)
cp "$HLDS"/addons/amxmodx/plugins/*.amxx "$REPO/addons/amxmodx/plugins/" 2>/dev/null || true

# Metamod plugin list
cp "$HLDS/addons/metamod/plugins.ini" "$REPO/addons/metamod/plugins.ini" 2>/dev/null || true

echo "Synced tracked server files into $REPO."
echo "Review with: cd $REPO && git status"
