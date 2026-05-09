#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/client-tentacle-version-audit.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/client-tentacle-version-audit.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    printf '  filter=%s file=%s\n' "$filter" "$file" >&2
    jq . "$file" >&2 || true
  fi
}

make_repo() {
  local path="$1"
  git init -q -b main "$path"
  git -C "$path" config user.email test@example.com
  git -C "$path" config user.name "Client Tentacle Test"
  printf 'fixture\n' >"$path/README.md"
  git -C "$path" add README.md
  git -C "$path" commit -qm init
}

make_repo "$TMP/alpha"
make_repo "$TMP/beta"

cat >"$TMP/br" <<'BR'
#!/usr/bin/env bash
case "$(basename "$PWD")" in
  alpha) printf 'br 0.2.5\n' ;;
  beta) printf 'br 0.4.0\n' ;;
  *) printf 'br 0.2.5\n' ;;
esac
BR
chmod +x "$TMP/br"

cat >"$TMP/bv" <<'BV'
#!/usr/bin/env bash
printf 'bv v0.13.0\n'
BV
chmod +x "$TMP/bv"

roster="$TMP/fleet-roster.json"
jq -n \
  --arg alpha "$TMP/alpha" \
  --arg beta "$TMP/beta" \
  '{members:[{name:"alpha",repo_realpath:$alpha,tier:"client"},{name:"beta",repo_realpath:$beta,tier:"client"}]}' >"$roster"

alpha_status_before="$(git -C "$TMP/alpha" status --porcelain=v1)"
beta_status_before="$(git -C "$TMP/beta" status --porcelain=v1)"

python3 -m py_compile "$SCRIPT" && pass "python compiles" || fail "python compiles"

"$SCRIPT" schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.required_row_fields == ["repo","tool","version","status"] and (.modes | index("doctor")) and (.modes | index("repair")) and (.mutation_policy | contains("read-only"))' "schema documents row fields and read-only modes"

"$SCRIPT" audit --roster "$roster" --tools br,bv,ntm --tool-bin "br=$TMP/br" --tool-bin "bv=$TMP/bv" --tool-bin "ntm=$TMP/missing-ntm" --json >"$TMP/audit.json"
assert_jq "$TMP/audit.json" '.schema_version == "client-tentacle-version-audit/v1" and .status == "warn" and .repo_count == 5 and .tool_count == 3 and .row_count == 15' "audit emits matrix for roster plus default repos"
assert_jq "$TMP/audit.json" 'all(.rows[]; has("repo") and has("tool") and has("version") and has("status"))' "every matrix row has required fields"
assert_jq "$TMP/audit.json" '.warnings[] | select(.code == "minor_drift_gt_one" and .tool == "br" and .minor_span == 2)' "audit warns on drift greater than one minor"
assert_jq "$TMP/audit.json" '.warnings[] | select(.code == "missing" and .tool == "ntm")' "audit warns on missing required tool"
assert_jq "$TMP/audit.json" '.rows[] | select(.repo == "alpha" and .tool == "br" and .version == "0.2.5" and .status == "drift")' "matrix includes alpha br drift row"
assert_jq "$TMP/audit.json" '.rows[] | select(.repo == "beta" and .tool == "bv" and .version == "0.13.0" and .status == "ok")' "matrix includes beta bv ok row"

"$SCRIPT" doctor --roster "$roster" --tools br,bv --tool-bin "br=$TMP/br" --tool-bin "bv=$TMP/bv" --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.mode == "doctor" and (.rows | length) == 10 and (.required_fields == ["repo","tool","version","status"])' "doctor emits the same JSON matrix shape"

"$SCRIPT" repair --roster "$roster" --tools br --tool-bin "br=$TMP/br" --json >"$TMP/repair.json"
assert_jq "$TMP/repair.json" '.mode == "repair" and .repair.applied == false and (.mutation_policy | contains("does not write"))' "repair surface remains read-only"

alpha_status_after="$(git -C "$TMP/alpha" status --porcelain=v1)"
beta_status_after="$(git -C "$TMP/beta" status --porcelain=v1)"
if [[ "$alpha_status_before" == "$alpha_status_after" && "$beta_status_before" == "$beta_status_after" ]]; then
  pass "audit does not mutate target repos"
else
  fail "audit does not mutate target repos"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAIL client-tentacle-version-audit tests pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'PASS client-tentacle-version-audit tests pass=%s fail=0\n' "$pass_count"
