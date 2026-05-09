#!/usr/bin/env bash
set -euo pipefail

PICOZ_REPO="/Users/josh/Developer/polymarket-pico-z"
AUDIT="$PICOZ_REPO/.flywheel/PUBLISHABILITY-AUDIT.md"

rg -q 'Landing waiver receipt.*flywheel-lzw7\.4' "$AUDIT"
rg -q 'Missing public copy surface \| none; landing-page copy explicitly waived' "$AUDIT"

"$PICOZ_REPO/.flywheel/scripts/zeststream-public-prepublish-hook.sh" \
  public git@example.com:public.git \
  --repo "$PICOZ_REPO" \
  --json \
  | jq -e '.status == "pass" and .brand_voice.brand_voice_composite >= 95 and .brand_voice.banned_words_count == 0 and .brand_voice.ungrounded_claims_count == 0' >/dev/null

printf 'OK_landing_waiver_public_hook\n'
