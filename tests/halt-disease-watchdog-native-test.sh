#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/halt-disease-watchdog.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/halt-disease-watchdog-native.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/repo/.beads" "$TMP/repo/.flywheel" "$TMP/bin"
printf '%s\n' '{"id":"fixture-ready","status":"open","priority":0,"dependencies":[]}' >"$TMP/repo/.beads/issues.jsonl"
: >"$TMP/repo/.flywheel/dispatch-log.jsonl"

cat >"$TMP/bin/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_NTM_ARGV:?}"
case "${1:-}" in
  --robot-activity=fixture)
    jq -nc '{agents:[{pane_idx:2,pane:2,state:"WAITING",activity:"WAITING",state_since:"2026-05-08T16:00:00Z"}]}'
    ;;
  watch)
    jq -nc '{success:true,session:"fixture",events:[]}'
    ;;
  grep)
    jq -nc '{pattern:"HALT",session:"fixture",matches:[{pane:"fixture__cod_2",content:"HALT fixture"}],match_count:1}'
    ;;
  *)
    printf 'unexpected fake ntm call: %s\n' "$*" >&2
    exit 2
    ;;
esac
SH
chmod +x "$TMP/bin/ntm"

cat >"$TMP/bin/flywheel-loop" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  doctor)
    jq -nc '{status:"warn",halt_contract:{schema_version:"halt-contract/v1",severity:"yellow",blocked_actions:["corpus.ingest"],permitted_actions:["docs.plan","read.audit"],repair_actions:["storage.report"],reason:"yellow fixture still permits safe work"}}'
    ;;
  *)
    exit 2
    ;;
esac
SH
chmod +x "$TMP/bin/flywheel-loop"

out="$TMP/out.json"
set +e
FAKE_NTM_ARGV="$TMP/ntm.argv" \
NTM_BIN="$TMP/bin/ntm" \
FLYWHEEL_LOOP="$TMP/bin/flywheel-loop" \
FLYWHEEL_HALT_DISEASE_WATCHDOG_LEDGER="$TMP/ledger.jsonl" \
FLYWHEEL_HALT_WATCHDOG_NOW_EPOCH=1778259600 \
FLYWHEEL_HALT_WATCHDOG_NOW_ISO=2026-05-08T17:00:00Z \
TIMEOUT_BIN="" \
"$SCRIPT" --sessions fixture --repo-map "fixture=$TMP/repo" --window-minutes 30 --json >"$out"
rc=$?
set -e

[[ "$rc" -eq 2 ]]
jq -e '
  .schema_version == "halt-disease-watchdog/v1"
  and .status == "critical"
  and .fleet_idle_with_ready_work_count == 1
  and .yellow_without_permitted_work_count == 1
  and .red_ignored_count == 0
  and (.native_surfaces | index("ntm watch") != null)
  and (.native_surfaces | index("ntm grep --json") != null)
  and .session_rows.fixture.native_grep.match_count == 1
  and (.session_rows.fixture.contracts[0].permitted_actions | index("docs.plan") != null)
' "$out" >/dev/null
grep -q '^watch fixture --json --tail=1 --interval=1s$' "$TMP/ntm.argv"
grep -q '^grep HALT|halt|blocked|stopped fixture --json -i -n 200$' "$TMP/ntm.argv"
printf 'PASS halt-disease watchdog native ntm watch+grep fixture preserves scoped halt decisions\n'
