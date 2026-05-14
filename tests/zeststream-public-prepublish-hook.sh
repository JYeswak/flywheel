#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
HOOK="$ROOT/.flywheel/scripts/zeststream-public-prepublish-hook.sh"
PROBE="$ROOT/.flywheel/scripts/publishability-bar.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/zeststream-prepublish.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
brand_company="Zest""Stream"

make_repo() {
    local dir="$1" public="$2" score="$3" banned="$4" ungrounded="$5"
    mkdir -p "$dir/.flywheel/scripts" "$dir/.planning"
    cp "$PROBE" "$dir/.flywheel/scripts/publishability-bar.sh"
    chmod +x "$dir/.flywheel/scripts/publishability-bar.sh"
    printf '%s\n' "# Bar" > "$dir/.flywheel/PUBLISHABILITY-BAR.md"
    {
        printf 'Repo: fixture\nReviewed: 2026-05-04\nPublic repo: %s\n\n' "$public"
        printf '%s\n' "## Facets" "" "| facet_id | facet | verdict | evidence |" "|---|---|---|---|"
        for i in 1 2 3 4 5 6 7; do
            printf '| F%s | Facet %s | YES | fixture |\n' "$i" "$i"
        done
        printf '\n## %s Voice Gate\n\n' "$brand_company"
        printf '%s\n' "| field | value |" "|---|---|"
        printf '| %s voice score | %s |\n' "$brand_company" "$score"
        printf '| Banned words count | %s |\n' "$banned"
        printf '| Ungrounded claims count | %s |\n' "$ungrounded"
        printf '| Scorecard log | `.planning/scorecard-log.jsonl` |\n'
    } > "$dir/.flywheel/PUBLISHABILITY-AUDIT.md"
    printf '%s\n' "plain README" > "$dir/README.md"
    printf '{"composite":%s}\n' "$score" > "$dir/.planning/scorecard-log.jsonl"
}

bash -n "$HOOK"
"$HOOK" --help >/dev/null

make_repo "$TMP/private-origin" no 100 0 0
"$HOOK" origin git@example.com:repo.git --repo "$TMP/private-origin" --json | jq -e '.status == "pass" and .skipped == true' >/dev/null

make_repo "$TMP/private-public" no 96 0 0
"$HOOK" public git@example.com:public.git --repo "$TMP/private-public" --json | jq -e '.status == "pass" and .brand_voice.public_ready_default == true and .brand_voice.exempt == false and .brand_voice.public_repo == false' >/dev/null

make_repo "$TMP/private-low-score" no 89 0 0
if "$HOOK" public git@example.com:public.git --repo "$TMP/private-low-score" --json > "$TMP/private-low-score.json"; then
    printf 'expected private low-score public push to fail\n' >&2
    exit 1
fi
jq -e '.status == "fail" and (.errors[]?.code == "brand_voice_composite_low") and .brand_voice.public_repo == false' "$TMP/private-low-score.json" >/dev/null

make_repo "$TMP/client-exempt" no 0 0 0
printf 'Exemption: EXEMPT_CLIENT_OWNED\n' >> "$TMP/client-exempt/.flywheel/PUBLISHABILITY-AUDIT.md"
"$HOOK" public git@example.com:public.git --repo "$TMP/client-exempt" --json | jq -e '.status == "pass" and .brand_voice.exempt == true and .brand_voice.exemption_class == "EXEMPT_CLIENT_OWNED"' >/dev/null

make_repo "$TMP/pass" yes 96 0 0
"$HOOK" public git@example.com:public.git --repo "$TMP/pass" --json | jq -e '.status == "pass" and .publishability_bar_score.brand_voice_composite == 96' >/dev/null

make_repo "$TMP/fail" yes 89 0 0
if "$HOOK" public git@example.com:public.git --repo "$TMP/fail" --json > "$TMP/fail.json"; then
    printf 'expected public low score to fail\n' >&2
    exit 1
fi
jq -e '.status == "fail" and (.errors[]?.code == "brand_voice_composite_low")' "$TMP/fail.json" >/dev/null

printf '%s\n' "PASS zeststream-public-prepublish-hook"
