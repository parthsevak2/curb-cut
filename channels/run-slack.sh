#!/bin/bash
cd "$(dirname "$0")/.." || exit 1   # runs from ~/Library/Application Support/curbcut, outside macOS-protected folders
set -a; source channels/.env; set +a
exec caffeinate -dims node channels/slack-app.mjs
