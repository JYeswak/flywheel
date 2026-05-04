#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/publishability-bar.sh"
LOOP="/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

make_repo() {
    local dir="$1" yes_count="$2" i verdict
    mkdir -p "$dir/.flywheel"
    printf '%s\n' "# Bar" > "$dir/.flywheel/PUBLISHABILITY-BAR.md"
    {
        printf '%s\n' "# Audit" "Public repo: no" "" "| facet_id | facet | verdict | evidence |" "|---|---|---|---|"
        for i in 1 2 3 4 5 6 7; do
            verdict=NO
            if [[ "$i" -le "$yes_count" ]]; then
                verdict=YES
            fi
            printf '| F%s | Facet %s | %s | fixture |\n' "$i" "$i" "$verdict"
        done
    } > "$dir/.flywheel/PUBLISHABILITY-AUDIT.md"
}

bash -n "$SCRIPT"
bash -n "$LOOP"
"$SCRIPT" --help >/dev/null
"$SCRIPT" --examples >/dev/null
"$SCRIPT" --schema --json | jq -e '.title == "publishability-bar/v1"' >/dev/null

make_repo "$TMPDIR/pass" 5
"$SCRIPT" --doctor --json --repo "$TMPDIR/pass" | jq -e '.status == "pass" and .publishability_bar_score.score == 5 and .publishability_bar_score.brand_voice_composite == 100' >/dev/null

make_repo "$TMPDIR/warn" 4
"$SCRIPT" --doctor --json --repo "$TMPDIR/warn" | jq -e '.status == "warn" and .publishability_bar_score.score == 4 and (.warnings | length) >= 1' >/dev/null

make_repo "$TMPDIR/fail" 2
if "$SCRIPT" --doctor --json --repo "$TMPDIR/fail" > "$TMPDIR/fail.json"; then
    printf 'expected fail repo to exit nonzero\n' >&2
    exit 1
fi
jq -e '.status == "fail" and .publishability_bar_score.score == 2 and (.errors | length) == 1' "$TMPDIR/fail.json" >/dev/null

FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 "$LOOP" doctor --repo "$ROOT" --json > "$TMPDIR/doctor.json" || true
jq -e '.publishability_bar.schema_version == "publishability-bar/v1" and (.publishability_bar_score.score | type == "number")' "$TMPDIR/doctor.json" >/dev/null

printf '%s\n' "PASS publishability-bar"
