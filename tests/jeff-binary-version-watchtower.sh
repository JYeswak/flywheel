#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/jeff-binary-version-watchtower.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jeff-binary-watch.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" >&2 || true; fi
}

mkdir -p "$TMP/bin" "$TMP/repo" "$TMP/state"
cat >"$TMP/bin/ntm" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$NTM_CALL_LOG"
case "$1" in
  version)
    if [[ "${2:-}" == "--json" ]]; then
      printf '{"version":"v1.0.0","commit":"fixture","built_at":"2026-05-04T00:00:00Z"}\n'
    else
      printf 'ntm version v1.0.0\n'
    fi
    ;;
  upgrade)
    [[ "${2:-}" == "--check" ]] || exit 9
    printf 'NTM Upgrade\n\n  Current version: v1.0.0\n  Latest version:  1.2.0\n\n  New version available: v1.0.0 -> 1.2.0\n'
    ;;
  *) exit 2 ;;
esac
SH
chmod +x "$TMP/bin/ntm"

cat >"$TMP/bin/br-fake" <<'SH'
#!/usr/bin/env bash
case "$1" in
  list) printf '[]\n' ;;
  create) printf '{"id":"flywheel-auto-ntm"}\n' ;;
  *) exit 2 ;;
esac
SH
chmod +x "$TMP/bin/br-fake"

export NTM_CALL_LOG="$TMP/ntm.calls"
cat >"$TMP/frankenterm-release.json" <<'JSON'
[
  {
    "candidate": "frankenterm",
    "repo": "Dicklesworthstone/frankenterm",
    "url": "https://github.com/Dicklesworthstone/frankenterm",
    "repo_public": true,
    "latest_release": null,
    "pushed_at": "2026-05-08T20:06:25Z",
    "description": "Terminal hypervisor for AI agent swarms",
    "status": "public_no_release"
  },
  {
    "candidate": "franken-term",
    "repo": "Dicklesworthstone/franken-term",
    "url": "https://github.com/Dicklesworthstone/franken-term",
    "repo_public": false,
    "latest_release": null,
    "pushed_at": null,
    "description": null,
    "status": "not_found"
  },
  {
    "candidate": "terminal",
    "repo": "Dicklesworthstone/terminal",
    "url": "https://github.com/Dicklesworthstone/terminal",
    "repo_public": false,
    "latest_release": null,
    "pushed_at": null,
    "description": null,
    "status": "not_found"
  }
]
JSON
bash -n "$SCRIPT" && pass "script syntax" || fail "script syntax"

PATH="$TMP/bin:$PATH" "$SCRIPT" --dry-run --json --repo-root "$TMP/repo" --state-dir "$TMP/state" --br-bin "$TMP/bin/br-fake" --frankenterm-release-fixture "$TMP/frankenterm-release.json" >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '.schema_version == "jeff-binary-version-watchtower.v2" and .canonical_binary_count == 1 and .rows[0].name == "ntm"' "schema and ntm-only surface"
assert_jq "$TMP/dry.json" '.status == "fail" and .stale_count == 1 and .rows[0].installed_version == "v1.0.0" and .rows[0].latest_version == "1.2.0" and .promotions[0].action == "planned"' "dry-run parses native version and plans drift bead"
assert_jq "$TMP/dry.json" '.release_watch_count == 3 and .watchlists.frankenterm_release.status == "public_no_release" and .watchlists.frankenterm_release.public_count == 1 and .watchlists.frankenterm_release.release_count == 0 and (.watchlists.frankenterm_release.candidates | index("frankenterm"))' "dry-run watches FrankenTerm release candidates"
grep -qx 'version --json' "$NTM_CALL_LOG" && pass "dry-run calls ntm version json" || fail "dry-run calls ntm version json"
grep -qx 'upgrade --check' "$NTM_CALL_LOG" && pass "dry-run calls non-mutating upgrade check" || fail "dry-run calls non-mutating upgrade check"
! grep -q -- '--yes' "$NTM_CALL_LOG" && pass "dry-run never invokes mutating upgrade" || fail "dry-run never invokes mutating upgrade"

PATH="$TMP/bin:$PATH" "$SCRIPT" --apply --json --repo-root "$TMP/repo" --state-dir "$TMP/state" --br-bin "$TMP/bin/br-fake" --frankenterm-release-fixture "$TMP/frankenterm-release.json" >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.promotions[0].action == "created" and .promotions[0].bead_id == "flywheel-auto-ntm" and (.ledger | endswith("jeff-binary-version-watchtower.jsonl"))' "apply creates idempotent-shaped bead and ledger"
assert_jq "$TMP/apply.json" '.watchlists.frankenterm_release.rows[] | select(.candidate == "frankenterm" and .status == "public_no_release")' "apply ledger carries FrankenTerm release watch row"
test -s "$TMP/state/jeff-binary-version-watchtower.jsonl" && pass "ledger row written" || fail "ledger row written"
! grep -q -- '--yes' "$NTM_CALL_LOG" && pass "apply does not self-upgrade from scheduled watchtower" || fail "apply does not self-upgrade from scheduled watchtower"

if [ "$fail_count" -gt 0 ]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
