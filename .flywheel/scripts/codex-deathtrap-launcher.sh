#!/usr/bin/env bash
# codex-deathtrap-launcher.sh — instrument a codex worker launch so a clean
# exit-to-bash leaves forensics behind. Closes flywheel-delp's "Required next
# step 1": "Relaunch one codex worker with stderr captured separately, wait for
# it to die, read exit reason."
#
# Usage from a worker pane (replaces the bare `codex --dangerously-...` line):
#   /Users/josh/Developer/flywheel/.flywheel/scripts/codex-deathtrap-launcher.sh
#
# Effect:
#   - Stderr is teed to ~/.local/state/flywheel/codex-death-evidence/stderr-<pid>-<ts>.log
#     while still flowing to the parent terminal.
#   - On codex exit (any cause), an exit_evidence-<pid>-<ts>.json receipt is
#     written: ts, pid, codex_exit_code, last_stderr_lines (50), last_zsh_history
#     command, parent_pane_id (if tmux), label, host.
#   - When the symptom is "clean exit, zero stderr", the receipt's
#     stderr_byte_count=0 + non-zero or zero exit_code locks the H1/H2 evidence.
#
# Doctor / health / info / schema available as canonical-cli-scoping triad.
set -euo pipefail

SCHEMA_VERSION="codex-deathtrap-launcher.v1"
EVIDENCE_DIR="${CODEX_DEATHTRAP_DIR:-$HOME/.local/state/flywheel/codex-death-evidence}"
CODEX_BIN="${CODEX_DEATHTRAP_CODEX_BIN:-$(command -v codex 2>/dev/null || echo /Users/josh/.cargo/bin/codex)}"
CODEX_ARGS_DEFAULT=(--dangerously-bypass-approvals-and-sandbox)
LABEL="${CODEX_DEATHTRAP_LABEL:-untagged}"

MODE=launch

usage() {
  cat <<'USAGE'
usage: codex-deathtrap-launcher.sh [--label TAG] [--evidence-dir PATH] [-- ARG ...]
       codex-deathtrap-launcher.sh --doctor|--health|--info|--schema [--json]

Wraps `codex --dangerously-bypass-approvals-and-sandbox` (or any args after --)
so a clean exit to bash leaves forensic evidence behind:

  1. stderr teed to evidence-dir/stderr-<pid>-<ts>.log
  2. on EXIT, exit_evidence-<pid>-<ts>.json written with
     {ts, pid, codex_exit_code, stderr_byte_count, last_stderr_lines,
      last_zsh_history_cmd, label, parent_pane_id, host}

Default args invoke `codex --dangerously-bypass-approvals-and-sandbox`. Pass
`--` followed by your own arg list to override.
USAGE
}

doctor() {
  jq -nc --arg schema "$SCHEMA_VERSION" --arg bin "$CODEX_BIN" --arg dir "$EVIDENCE_DIR" \
    '{schema_version:$schema, success:true, mode:"doctor",
      codex_bin:$bin, codex_bin_present:($bin | test("^/")),
      evidence_dir:$dir,
      captures:["stderr_tee","exit_code","last_history_cmd","parent_pane_id"]}'
}

info() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema, success:true, mode:"info",
      hypotheses_supported:["H1_voluntary_turn_complete_exit","H2_mcp_fatal_error","H3_tmux_misreport"],
      symptom_to_evidence:[
        "clean exit zero stderr -> stderr_byte_count==0",
        "non-zero exit code with stderr -> H2 candidate",
        "exit code 0 with empty stderr -> H1 candidate"
      ]}'
}

schema() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema,
      properties:{
        ts:{type:"string"},
        pid:{type:"integer"},
        codex_exit_code:{type:"integer"},
        stderr_byte_count:{type:"integer"},
        last_stderr_lines:{type:"array"},
        last_zsh_history_cmd:{type:["string","null"]},
        label:{type:"string"},
        parent_pane_id:{type:["string","null"]},
        host:{type:"string"},
        evidence_paths:{type:"object"}}}'
}

# Parse our own flags up to `--` then forward the rest.
codex_args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --label) LABEL="${2:?--label requires TAG}"; shift 2;;
    --evidence-dir) EVIDENCE_DIR="${2:?--evidence-dir requires PATH}"; shift 2;;
    --doctor|--health) MODE=doctor; shift;;
    --info) MODE=info; shift;;
    --schema) MODE=schema; shift;;
    --json) shift;;  # accepted but no-op for non-launch modes
    -h|--help) usage; exit 0;;
    --) shift; codex_args+=("$@"); break;;
    *) codex_args+=("$1"); shift;;
  esac
done

case "$MODE" in
  doctor) doctor; exit 0;;
  info) info; exit 0;;
  schema) schema; exit 0;;
esac

[[ -x "$CODEX_BIN" ]] || { echo "ERR: codex not executable: $CODEX_BIN" >&2; exit 2; }
mkdir -p "$EVIDENCE_DIR"
[[ "${#codex_args[@]}" -eq 0 ]] && codex_args=("${CODEX_ARGS_DEFAULT[@]}")

LAUNCH_TS="$(date -u +%Y%m%dT%H%M%SZ)"
LAUNCH_PID="$$"
STDERR_LOG="$EVIDENCE_DIR/stderr-${LAUNCH_PID}-${LAUNCH_TS}.log"
EXIT_RECEIPT="$EVIDENCE_DIR/exit_evidence-${LAUNCH_PID}-${LAUNCH_TS}.json"
ARGS_LOG="$EVIDENCE_DIR/args-${LAUNCH_PID}-${LAUNCH_TS}.txt"

printf '%s\n' "${codex_args[@]}" >"$ARGS_LOG"

emit_exit_evidence() {
  local exit_code="$1"
  local stderr_bytes=0
  local last_stderr_lines='[]'
  local last_history_cmd=null
  local parent_pane_id=null

  if [[ -f "$STDERR_LOG" ]]; then
    stderr_bytes="$(wc -c <"$STDERR_LOG" | tr -d ' ')"
    last_stderr_lines="$(tail -50 "$STDERR_LOG" | jq -R -s 'split("\n") | map(select(length > 0))')"
  fi

  if [[ -n "${HISTFILE:-}" && -f "$HISTFILE" ]]; then
    last_history_cmd="$(tail -1 "$HISTFILE" 2>/dev/null | jq -R '.')"
  elif [[ -f "$HOME/.zsh_history" ]]; then
    last_history_cmd="$(tail -1 "$HOME/.zsh_history" 2>/dev/null | jq -R '.')"
  fi

  if [[ -n "${TMUX_PANE:-}" ]]; then
    parent_pane_id="$(jq -nc --arg p "$TMUX_PANE" '$p')"
  fi

  jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg label "$LABEL" \
    --arg host "$(hostname -s)" \
    --arg stderr_log "$STDERR_LOG" \
    --arg exit_receipt "$EXIT_RECEIPT" \
    --arg args_log "$ARGS_LOG" \
    --argjson pid "$LAUNCH_PID" \
    --argjson exit_code "$exit_code" \
    --argjson stderr_bytes "$stderr_bytes" \
    --argjson last_stderr "$last_stderr_lines" \
    --argjson last_history "$last_history_cmd" \
    --argjson parent_pane "$parent_pane_id" \
    '{schema_version:$schema, ts:$ts, label:$label, host:$host,
      pid:$pid, codex_exit_code:$exit_code,
      stderr_byte_count:$stderr_bytes,
      last_stderr_lines:$last_stderr,
      last_zsh_history_cmd:$last_history,
      parent_pane_id:$parent_pane,
      evidence_paths:{stderr_log:$stderr_log, exit_receipt:$exit_receipt, args_log:$args_log}}' \
    >"$EXIT_RECEIPT"
}

# Spawn codex; capture stderr via process substitution while preserving live
# output to our parent stderr. macOS bash 3.2 supports process subs.
EXIT_CODE=0
"$CODEX_BIN" "${codex_args[@]}" 2> >(tee "$STDERR_LOG" >&2) || EXIT_CODE=$?

emit_exit_evidence "$EXIT_CODE"

printf 'codex-deathtrap: exit_code=%s stderr_log=%s exit_receipt=%s\n' \
  "$EXIT_CODE" "$STDERR_LOG" "$EXIT_RECEIPT" >&2

exit "$EXIT_CODE"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-03-agent-ergonomics-rubric.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-58-agent-tool-theory-of-mind.md`
