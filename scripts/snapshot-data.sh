#!/usr/bin/env bash
set -euo pipefail

SRC="$HOME/agent"
DST="$HOME/agent-data"

cp "$SRC/state.json" "$SRC/today.md" "$DST/" 2>/dev/null || true
rsync -a --delete "$SRC/archive/" "$DST/archive/"

cd "$DST"
git add -A
git diff --cached --quiet || git commit -m "snapshot $(date +%F)"
git push origin main
