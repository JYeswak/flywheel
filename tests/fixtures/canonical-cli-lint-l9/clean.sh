#!/usr/bin/env bash
# flywheel-cli-surface: true
set -euo pipefail

# Synthetic clean surface — mimics hoqq8 post-fix shape: gate fires
# BEFORE all side-effects. L9 must NOT flag this.
mode="${1:-dry-run}"
idem_key="${2:-}"
target="/Users/josh/Developer/flywheel/.flywheel/state/foo"

if [[ "$mode" == "apply" ]]; then
  # GATE FIRES FIRST — apply-key check before any side-effect
  if [[ -z "$idem_key" ]]; then
    cli_refuse_apply_without_idem_key "schema/v1" "scaffold" "$target"
    exit 3
  fi

  # Side-effects only after gate passed
  mkdir -p "$HOME/.local/state/clean-fixture"
  cp "$target" "$HOME/.local/state/clean-fixture/copy"
  sed -i '' 's/foo/bar/' "$target"
fi
