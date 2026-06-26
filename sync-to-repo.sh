#!/bin/bash
# Literal copy of the live server's configs + addons into the repo.
# No filtering happens here -- .gitignore decides what actually gets tracked
# (text configs + .amxx plugins in; binaries, logs, users.ini out).
# Run on the Pi, then `git add . && git commit && git push`.

set -e

HLDS=~/Steam/steamapps/common/Half-Life/cstrike
REPO=~/cs16-server

mkdir -p "$REPO/configs" "$REPO/addons"

# Top-level server configs
cp "$HLDS"/*.cfg "$REPO/configs/" 2>/dev/null || true
cp "$HLDS"/*.ini "$REPO/configs/" 2>/dev/null || true
cp "$HLDS/mapcycle.txt" "$REPO/configs/" 2>/dev/null || true

# Whole addons tree, verbatim
cp -r "$HLDS/addons/." "$REPO/addons/"

echo "Copied live configs + addons into $REPO."
echo "git will filter via .gitignore -- verify before committing:"
echo "  cd $REPO && git status"
echo "  git check-ignore -v addons/amxmodx/configs/users.ini   # should print a match"
