#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$REPO/.flywheel/scripts/apply-tmux-tuning.sh"

TMP="$(mktemp -d -t apply-tmux-tuning-test.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

TMX="$TMP/tmux.conf"
LEDGER="$TMP/tmux-tuning.jsonl"
STUB="$TMP/bin"
STUB_LOG="$TMP/tmux-stub.log"
mkdir -p "$STUB"

cat >"$STUB/tmux" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
log="${TMUX_STUB_LOG:?}"
case "${1:-}" in
  -V)
    printf 'tmux %s\n' "${TMUX_STUB_VERSION:-3.6a}"
    ;;
  source-file)
    shift
    if [[ "${1:-}" == "-n" ]]; then shift; fi
    printf 'source-file %s\n' "${1:-}" >>"$log"
    [[ "${TMUX_STUB_SOURCE_FAIL:-0}" == "1" ]] && exit 1
    exit 0
    ;;
  show-options)
    opt="${@: -1}"
    case "$opt" in
      history-limit) echo "100000" ;;
      escape-time) echo "0" ;;
      set-clipboard) echo "external" ;;
      default-terminal) echo "tmux-256color" ;;
      aggressive-resize) echo "off" ;;
      focus-events) echo "on" ;;
      extended-keys) echo "on" ;;
      mouse) echo "on" ;;
      allow-passthrough) echo "on" ;;
      *) echo "unknown" ;;
    esac
    ;;
  display-message)
    echo "client_termname=xterm-256color"
    ;;
  *)
    printf 'stub tmux unsupported: %s\n' "$*" >&2
    exit 1
    ;;
esac
SH
chmod +x "$STUB/tmux"

cat >"$TMX" <<'TMUX'
# NTM Fleet Configuration
set-option -g history-limit 50000
set -s escape-time 0
set -g mouse on
set -g pane-border-status top
set -g pane-border-format " #{pane_title} "
set -g terminal-overrides "xterm*:smcup@:rmcup@"
setw -g xterm-keys on
bind-key -n F6 display-popup -E -w 90% -h 90% "ntm palette"
set-environment -g PATH "$HOME/.opencode/bin:$HOME/.local/bin:$HOME/.cargo/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
bind-key -n F12 display-popup -E -w 95% -h 95% "NTM_POPUP=1 ntm dashboard --popup #{session_name}"

# BEGIN apply-substrate-tuning (flywheel-3099j) -----------------------------
set-option -g history-limit 100000
set-option -g status-interval 5
set-option -g focus-events on
# END apply-substrate-tuning (flywheel-3099j) -------------------------------
TMUX

export TMUX_TUNING_CONFIG="$TMX"
export TMUX_TUNING_LEDGER="$LEDGER"
export TMUX_TUNING_TMUX_BIN="$STUB/tmux"
export TMUX_TUNING_NOW="2026-05-05T06:30:00Z"
export TMUX_STUB_LOG="$STUB_LOG"
export APPROVE=yes

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1" >&2; }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" >&2 || true; fi
}

sha() { shasum -a 256 "$1" | awk '{print $1}'; }

ORIG_SHA="$(sha "$TMX")"

"$SCRIPT" --json >"$TMP/dry.json"
if [[ "$(sha "$TMX")" == "$ORIG_SHA" ]]; then pass "dry-run-no-mutate"; else fail "dry-run-no-mutate"; fi
assert_jq "$TMP/dry.json" '.action == "dry-run" and .outcome == "planned"' "dry-run-receipt-shape"

"$SCRIPT" --apply --idempotency-key test-apply-1 --json >"$TMP/apply.json"
if grep -qF "BEGIN apply-tmux-tuning" "$TMX"; then pass "apply-mutates-and-adds-block"; else fail "apply-mutates-and-adds-block"; fi
backup_path="$(jq -r '.backup_path' "$TMP/apply.json")"
if [[ -f "$backup_path" ]]; then pass "apply-mutates-and-backs-up"; else fail "apply-mutates-and-backs-up"; fi
assert_jq "$TMP/apply.json" '.action == "apply" and .outcome == "ok" and .source_file_exit == 0' "apply-creates-receipt"

APPLY_SHA="$(sha "$TMX")"
"$SCRIPT" --apply --idempotency-key test-apply-2 --json >"$TMP/reapply.json"
if [[ "$(sha "$TMX")" == "$APPLY_SHA" && "$(grep -cF "BEGIN apply-tmux-tuning" "$TMX")" == "1" ]]; then
  pass "idempotent-re-apply"
else
  fail "idempotent-re-apply"
fi

"$SCRIPT" --revert --apply --idempotency-key test-revert-1 --json >"$TMP/revert.json"
if [[ "$(sha "$TMX")" == "$ORIG_SHA" ]]; then pass "revert-byte-exact"; else fail "revert-byte-exact"; fi

export TMUX_STUB_VERSION="3.4"
PRE_INCOMPAT_SHA="$(sha "$TMX")"
set +e
"$SCRIPT" --apply --idempotency-key test-incompat-1 --json >"$TMP/incompat.json" 2>/dev/null
rc=$?
set -e
unset TMUX_STUB_VERSION
if [[ "$rc" == "4" && "$(sha "$TMX")" == "$PRE_INCOMPAT_SHA" ]]; then pass "version-incompat-refuse"; else fail "version-incompat-refuse rc=$rc"; fi

"$SCRIPT" doctor --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" 'has("drift") and has("current_block_sha") and has("expected_block_sha") and has("ledger_rows_valid") and has("ledger_rows_invalid") and .version_compatible == true' "doctor-shape"

"$SCRIPT" validate ledger --json >"$TMP/validate.json"
assert_jq "$TMP/validate.json" '.ledger_rows_invalid == 0 and .ledger_rows_valid >= 1' "validate-ledger"

"$SCRIPT" --apply --idempotency-key test-apply-3 --json >"$TMP/apply2.json"
if grep -qF "bind-key -n F6 display-popup" "$TMX" && grep -qF "bind-key -n F12 display-popup" "$TMX"; then pass "ntm-bindings-preserved"; else fail "ntm-bindings-preserved"; fi
if grep -qF "set-environment -g PATH" "$TMX"; then pass "PATH-block-preserved"; else fail "PATH-block-preserved"; fi
if grep -qF "BEGIN apply-substrate-tuning (flywheel-3099j)" "$TMX"; then pass "existing-3099j-block-preserved"; else fail "existing-3099j-block-preserved"; fi
if grep -q "source-file" "$STUB_LOG"; then pass "tmux-source-file-loads-cleanly"; else fail "tmux-source-file-loads-cleanly"; fi
if ! grep -qF "aggressive-resize on" "$TMX" && ! grep -qF "set-clipboard on" "$TMX"; then pass "dangerous-knobs-not-enabled"; else fail "dangerous-knobs-not-enabled"; fi

"$SCRIPT" schema config --json >"$TMP/schema-config.json"
"$SCRIPT" schema backup --json >"$TMP/schema-backup.json"
"$SCRIPT" schema ledger --json >"$TMP/schema-ledger.json"
assert_jq "$TMP/schema-config.json" '.schema_version | contains("schema.config")' "schema-config"
assert_jq "$TMP/schema-backup.json" '.byte_exact == true' "schema-backup"
assert_jq "$TMP/schema-ledger.json" '.row_schema == "tmux-tuning.ledger.v1"' "schema-ledger"

"$SCRIPT" why allow-passthrough --json >"$TMP/why.json"
assert_jq "$TMP/why.json" '.key == "allow-passthrough" and (.explanation | contains("OSC 52"))' "why-key"

"$SCRIPT" completion zsh >"$TMP/completion.zsh"
if grep -q "#compdef apply-tmux-tuning.sh" "$TMP/completion.zsh"; then pass "completion-zsh"; else fail "completion-zsh"; fi

if grep -qF 'trap cleanup_temp_files EXIT ERR' "$SCRIPT" \
  && grep -qF "register_temp_file \"\$candidate\"" "$SCRIPT"; then
  pass "temp-cleanup-trap-wired"
else
  fail "temp-cleanup-trap-wired"
fi

FAIL_TMP="$TMP/fail-tmp"
mkdir -p "$FAIL_TMP"
BEFORE_TEMP_COUNT=$(find "$FAIL_TMP" -maxdepth 1 -type f -name 'apply-tmux-tuning.*' | wc -l | tr -d ' ')
set +e
TMPDIR="$FAIL_TMP" TMUX_STUB_SOURCE_FAIL=1 "$SCRIPT" --apply --idempotency-key test-parse-fail --json >"$TMP/parse-fail.json" 2>/dev/null
rc=$?
set -e
AFTER_TEMP_COUNT=$(find "$FAIL_TMP" -maxdepth 1 -type f -name 'apply-tmux-tuning.*' | wc -l | tr -d ' ')
if [[ "$rc" -eq 1 && "$BEFORE_TEMP_COUNT" == "$AFTER_TEMP_COUNT" ]]; then
  pass "parse-failure-cleans-candidate-temp"
else
  fail "parse-failure-cleans-candidate-temp rc=$rc before=$BEFORE_TEMP_COUNT after=$AFTER_TEMP_COUNT"
fi

printf 'RESULTS: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
