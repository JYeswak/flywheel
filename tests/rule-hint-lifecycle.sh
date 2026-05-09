#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/rule-hint-lifecycle.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/rule-hint-lifecycle.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" name="$3"
  if jq -e "$filter" "$file" >/dev/null; then pass "$name"; else fail "$name"; jq . "$file" >&2 || true; fi
}

repo="$TMP/repo"
mkdir -p "$repo/.flywheel/rules"
git -C "$repo" init -q
(cd "$repo" && br init --prefix fx >/dev/null)

cat >"$repo/.flywheel/rules/L010-low.md" <<'EOF'
## L10 — LOW-USAGE-FIXTURE

---
id: L10
title: Low usage fixture
status: long_term
shipped: 2026-05-09
trauma_class: low-usage-fixture
---

Low usage fixture rule.
EOF

cat >"$repo/.flywheel/rules/L020-high.md" <<'EOF'
## L20 — HIGH-USAGE-FIXTURE

---
id: L20
title: High usage fixture
status: long_term
shipped: 2026-05-09
trauma_class: high-usage-fixture
---

High usage fixture rule.
EOF

usage="$TMP/usage.jsonl"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
for i in 1 2 3 4; do
  jq -nc --arg ts "$ts" --argjson i "$i" '{schema_version:"rule-hint-usage/v1",ts:$ts,rule_id:"L10",dispatch_id:("low-"+($i|tostring)),bead_id:"fx-low"}' >>"$usage"
done
for i in $(seq 1 51); do
  jq -nc --arg ts "$ts" --argjson i "$i" '{schema_version:"rule-hint-usage/v1",ts:$ts,rule_id:"L20",dispatch_id:("high-"+($i|tostring)),bead_id:"fx-high"}' >>"$usage"
done

"$BIN" --repo "$repo" --usage-log "$usage" --json >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '.mode=="dry_run" and .usage_rows_seen==55 and .candidate_count==2' "dry-run finds two candidates"
assert_jq "$TMP/dry.json" '(.candidates[] | select(.rule_id=="L10" and .action=="demote" and .count==4))' "demote candidate traceable"
assert_jq "$TMP/dry.json" '(.candidates[] | select(.rule_id=="L20" and .action=="promote" and .count==51))' "promote candidate traceable"
assert_jq "$TMP/dry.json" '.joshua_approval_required_before_lifecycle_apply==true and .canonical_l_rule_mutation_performed==false' "joshua approval gate preserved"

"$BIN" --repo "$repo" --usage-log "$usage" --apply --json >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.action=="proposal_beads_created" and (.beads|length)==2' "apply creates proposal beads"
(cd "$repo" && br list --json --limit 0) >"$TMP/beads.json"
assert_jq "$TMP/beads.json" '(.issues // .)[] | select((.title // "") | contains("[rule-hint-lifecycle:demote:L10]"))' "demote bead filed"
assert_jq "$TMP/beads.json" '(.issues // .)[] | select((.title // "") | contains("[rule-hint-lifecycle:promote:L20]"))' "promote bead filed"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
