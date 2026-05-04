#!/usr/bin/env bash
# Load a fleet-mail registration token from the vault.
# Usage: fleet-mail-token-load.sh <agent-name>
# Prints the token; empty if not found.
set -euo pipefail

NAME="${1:?agent-name required}"
F="$HOME/.local/state/flywheel/fleet-mail-tokens/${NAME}.token"

if [ -f "$F" ]; then
    cat "$F"
else
    echo ""
fi
