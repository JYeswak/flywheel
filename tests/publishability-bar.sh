#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/publishability-bar.sh"
LOOP="/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

make_repo() {
    local dir="$1" yes_count="$2" public="$3" score="${4:-96}" exemption="${5:-}" i verdict
    mkdir -p "$dir/.flywheel"
    printf '%s\n' "# Bar" > "$dir/.flywheel/PUBLISHABILITY-BAR.md"
    {
        printf '%s\n' "# Audit" "Public repo: $public"
        if [[ -n "$exemption" ]]; then
            printf 'Exemption: %s\n' "$exemption"
        fi
        printf '%s\n' "" "| facet_id | facet | verdict | evidence |" "|---|---|---|---|"
        for i in 1 2 3 4 5 6 7; do
            verdict=NO
            if [[ "$i" -le "$yes_count" ]]; then
                verdict=YES
            fi
            printf '| F%s | Facet %s | %s | fixture |\n' "$i" "$i" "$verdict"
        done
        if [[ -n "$score" ]]; then
            printf '\n## ZestStream Voice Gate\n\n'
            printf '%s\n' "| field | value |" "|---|---|"
            printf '| ZestStream voice score | %s |\n' "$score"
            printf '| Banned words count | 0 |\n'
            printf '| Ungrounded claims count | 0 |\n'
            printf '| Scorecard log | `.planning/scorecard-log.jsonl` |\n'
        fi
    } > "$dir/.flywheel/PUBLISHABILITY-AUDIT.md"
    {
        printf '%s\n' "plain README"
        printf '%s\n' 'Inline command names such as `artifact`, `.flywheel/handoffs/`, and `agent-orchestration` are not public prose.'
    } > "$dir/README.md"
}

bash -n "$SCRIPT"
bash -n "$LOOP"
"$SCRIPT" --help >/dev/null
"$SCRIPT" --examples >/dev/null
"$SCRIPT" --schema --json | jq -e '.title == "publishability-bar/v1"' >/dev/null

make_repo "$TMPDIR/pass" 5 no 96
"$SCRIPT" --doctor --json --repo "$TMPDIR/pass" | jq -e '.status == "pass" and .publishability_bar_score.score == 5 and .publishability_bar_score.brand_voice_composite == 96 and .brand_voice.public_ready_default == true and .brand_voice.exempt == false' >/dev/null

make_repo "$TMPDIR/warn" 4 no 96
"$SCRIPT" --doctor --json --repo "$TMPDIR/warn" | jq -e '.status == "warn" and .publishability_bar_score.score == 4 and (.warnings | length) >= 1' >/dev/null

make_repo "$TMPDIR/fail" 2 no 96
if "$SCRIPT" --doctor --json --repo "$TMPDIR/fail" > "$TMPDIR/fail.json"; then
    printf 'expected fail repo to exit nonzero\n' >&2
    exit 1
fi
jq -e '.status == "fail" and .publishability_bar_score.score == 2 and (.errors | length) == 1' "$TMPDIR/fail.json" >/dev/null

make_repo "$TMPDIR/private-low-voice" 7 no 89
if "$SCRIPT" --doctor --json --repo "$TMPDIR/private-low-voice" > "$TMPDIR/private-low-voice.json"; then
    printf 'expected private low voice repo to exit nonzero\n' >&2
    exit 1
fi
jq -e '.status == "fail" and (.errors[]?.code == "brand_voice_composite_low")' "$TMPDIR/private-low-voice.json" >/dev/null

make_repo "$TMPDIR/client-exempt" 7 no "" EXEMPT_CLIENT_OWNED
"$SCRIPT" --doctor --json --repo "$TMPDIR/client-exempt" | jq -e '.status == "pass" and .brand_voice.exempt == true and .brand_voice.exemption_class == "EXEMPT_CLIENT_OWNED"' >/dev/null

bash -c "source '$HOME/.claude/skills/.flywheel/lib/portable/core.sh' && type publishability_bar_doctor_json" >/dev/null
"$SCRIPT" --doctor --json --repo "$ROOT" > "$TMPDIR/doctor.json"
jq -e '.schema_version == "publishability-bar/v1" and (.publishability_bar_score.score | type == "number")' "$TMPDIR/doctor.json" >/dev/null

printf '%s\n' "PASS publishability-bar"
