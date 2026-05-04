#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/jeff-binary-version-watchtower.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jeff-binary-watch.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'PASS %s\n' "$1"
}

fail() {
  fail_count=$((fail_count + 1))
  printf 'FAIL %s\n' "$1" >&2
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

write_bin() {
  local name="$1" body="$2"
  printf '#!/usr/bin/env bash\n%s\n' "$body" >"$TMP/bin/$name"
  chmod +x "$TMP/bin/$name"
}

mkdir -p "$TMP/bin" "$TMP/dev" "$TMP/repo" "$TMP/state"
for repo in destructive_command_guard ntm beads_rust coding_agent_session_search mcp_agent_mail frankensqlite meta_skill; do
  mkdir -p "$TMP/dev/$repo"
done
mkdir -p "$TMP/dev/frankensqlite/crates/fsqlite"
printf 'version = "1.0.0"\n' >"$TMP/dev/frankensqlite/crates/fsqlite/Cargo.toml"

write_bin dcg 'printf "1.0.0\n"'
write_bin ntm 'printf "ntm version v1.0.0\n"'
write_bin br 'printf "br 1.0.0\n"'
write_bin cm 'printf "1.0.0\n"'
write_bin agent-mail 'printf "1.0.0\n"'
write_bin jsm 'printf "jsm 1.0.0\n"'
write_bin br-fake '
case "$1" in
  list) printf "[]\n" ;;
  create) printf "{\"id\":\"flywheel-auto-cm\"}\n" ;;
  *) exit 2 ;;
esac
'

jq -n '{
  dcg:{latest_version:"1.0.0",published_at:"2026-05-04T00:00:00Z"},
  ntm:{latest_version:"1.0.0",published_at:"2026-05-04T00:00:00Z"},
  br:{latest_version:"1.0.0",published_at:"2026-05-04T00:00:00Z"},
  cm:{latest_version:"1.2.0",published_at:"2026-05-02T00:00:00Z"},
  "mcp-agent-mail":{latest_version:"1.0.0",published_at:"2026-05-04T00:00:00Z"},
  frankensqlite:{latest_version:"1.0.0",published_at:"2026-05-04T00:00:00Z"},
  jsm:{latest_version:"1.0.0",published_at:"2026-05-04T00:00:00Z"}
}' >"$TMP/latest.json"

bash -n "$SCRIPT" && pass "script syntax" || fail "script syntax"

PATH="$TMP/bin:$PATH" "$SCRIPT" --dry-run --json --fixture "$TMP/latest.json" --developer-root "$TMP/dev" --repo-root "$TMP/repo" --state-dir "$TMP/state" --br-bin "$TMP/bin/br-fake" --no-fetch >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '.schema_version == "jeff-binary-version-watchtower.v1" and .cadence == "hourly" and .canonical_binary_count == 7' "schema and hourly surface"
assert_jq "$TMP/dry.json" '.status == "fail" and .stale_count == 1 and .stale[0].name == "cm" and .promotions[0].action == "planned" and .promotions[0].priority == "P0"' "dry-run detects stale cm and plans P0 bead"

PATH="$TMP/bin:$PATH" "$SCRIPT" --apply --json --fixture "$TMP/latest.json" --developer-root "$TMP/dev" --repo-root "$TMP/repo" --state-dir "$TMP/state" --br-bin "$TMP/bin/br-fake" --no-fetch >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.promotions[0].action == "created" and .promotions[0].bead_id == "flywheel-auto-cm" and (.ledger | endswith("jeff-binary-version-watchtower.jsonl"))' "apply creates idempotent-shaped bead and ledger"
test -s "$TMP/state/jeff-binary-version-watchtower.jsonl" && pass "ledger row written" || fail "ledger row written"

if [ "$fail_count" -gt 0 ]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
