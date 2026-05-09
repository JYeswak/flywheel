#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
TMP="$(mktemp -d -t ljrjw-l112.XXXXXX)"
trap 'chmod -R u+w "$TMP" 2>/dev/null || true; find "$TMP" -mindepth 1 -type f -delete 2>/dev/null || true; find "$TMP" -mindepth 1 -type d -delete 2>/dev/null || true; rmdir "$TMP" 2>/dev/null || true' EXIT

cd "$ROOT"

bash -n .flywheel/scripts/skill-enhance-jsm-discipline.sh
bash -n .flywheel/scripts/build-dispatch-packet.sh
bash tests/skill-enhance-jsm-discipline.sh >/dev/null

cat >"$TMP/jsm-list.json" <<'JSON'
{
  "skills": [
    {"name": "brenner", "version": 1, "is_saved": true, "is_jeffreys": true, "installed_at": "2026-05-08"},
    {"name": "cass", "version": 6, "is_saved": true, "is_jeffreys": true, "installed_at": "2026-05-08"},
    {"name": "beads-workflow", "version": 3, "is_saved": true, "is_jeffreys": true, "installed_at": "2026-05-08"}
  ]
}
JSON

packet_json="$(FLYWHEEL_PACKET_BUILT_AT=2026-05-08T00:00:00Z .flywheel/scripts/build-dispatch-packet.sh --bead-id flywheel-ljrjw --target-pane 2 --target-session flywheel --output-dir "$TMP" --apply --json)"
packet_path="$(jq -r '.packet_path' <<<"$packet_json")"

jq -e '.validation_status == "pass" and (.validation_blocks_present | index("SKILL-ENHANCE JSM DISCIPLINE BLOCK"))' <<<"$packet_json" >/dev/null
grep -q '^## SKILL-ENHANCE JSM DISCIPLINE BLOCK$' "$packet_path"
.flywheel/scripts/skill-enhance-jsm-discipline.sh --validate-packet "$packet_path" --jsm-list-json "$TMP/jsm-list.json" --json | jq -e '.status == "pass"' >/dev/null

printf 'OK_skill_enhance_jsm_discipline\n'
