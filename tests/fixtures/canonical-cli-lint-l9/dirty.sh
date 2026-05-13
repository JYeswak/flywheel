#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail

# Synthetic dirty surface — mimics hoqq8 pre-fix shape:
# apply-block opens, side-effect (mkdir, cp, sed -i) fires, THEN gate.
# L9 must flag the side-effects.
mode="${1:-dry-run}"
idem_key="${2:-}"
target="<flywheel-repo>/.flywheel/state/foo"

if [[ "$mode" == "apply" ]]; then
  # SIDE EFFECT 1 — mkdir to user-state path
  mkdir -p "$HOME/.local/state/dirty-fixture"
  # SIDE EFFECT 2 — cp to non-tmp dest
  cp "$target" "$HOME/.local/state/dirty-fixture/copy"
  # SIDE EFFECT 3 — sed -i in place
  sed -i '' 's/foo/bar/' "$target"

  # GATE FIRES TOO LATE — after the side-effects above
  if [[ -z "$idem_key" ]]; then
    cli_refuse_apply_without_idem_key "schema/v1" "scaffold" "$target"
    exit 3
  fi
fi
