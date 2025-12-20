#!/usr/bin/env bash
# Quick launcher for TinyMMO (master + gateway + world + two clients).
# Uses GODOT_BIN if set, otherwise tries `godot`.

set -euo pipefail

BIN="${GODOT_BIN:-godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

launch() {
  local name="$1"; shift
  (
    cd "$PROJECT_DIR"
    echo "Starting $name..."
    "$BIN" --path . "$@"
  ) &
}

# Servers
launch "master-server" --headless --feature master-server
launch "gateway-server" --headless --feature gateway-server
launch "world-server" --headless --feature world-server

# Clients (with net diagnostics enabled)
CLIFFWALD_NET_DEBUG=1 launch "client-1" --feature client
CLIFFWALD_NET_DEBUG=1 launch "client-2" --feature client

echo "Launched master, gateway, world, and two clients. Use 'jobs' to see them, 'fg %N' to bring one forward."
