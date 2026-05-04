#!/usr/bin/env bash
# Save a fleet-mail registration token to the vault.
# Usage: fleet-mail-token-save.sh <agent-name> <token>
set -euo pipefail

NAME="${1:?agent-name required}"
TOKEN="${2:?token required}"
VAULT="$HOME/.local/state/flywheel/fleet-mail-tokens"

mkdir -p "$VAULT"
chmod 700 "$VAULT"

F="$VAULT/${NAME}.token"
printf '%s' "$TOKEN" > "$F"
chmod 600 "$F"

echo "Saved: $F"
