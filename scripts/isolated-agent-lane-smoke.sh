#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="flywheel.isolated_agent_lane_smoke.v0"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
LANES="claude,codex,gemini,openclaw"
RECEIPT_DIR=""
JSON_OUT=0
KEEP_TEMP=0
REQUIRE_RUNTIME=0
SKIP_ASSEMBLE=0
SOURCE="$ROOT"

usage() {
  cat <<'EOF'
usage: scripts/isolated-agent-lane-smoke.sh [--lanes claude,codex,gemini,openclaw] [--receipt-dir DIR] [--skip-assemble] [--require-runtime] --json

Creates an isolated HOME, XDG config/cache, install prefix, public export, and
target repo. It proves the public reduced path end to end, then writes one
runtime or blocker receipt per requested agent lane.

Without a lane-specific live adapter, installed CLIs are treated as setup
evidence only and the lane receives an isolated_runtime_receipt_missing blocker.
EOF
}

die_usage() {
  printf 'ERROR: %s\n' "$1" >&2
  usage >&2
  exit 64
}

need() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'ERROR: missing required isolated-agent-lane-smoke command: %s\n' "$1" >&2
    exit 30
  }
}

json_string_array() {
  jq -Rsc 'split("\n")[:-1]'
}

lane_display() {
  case "$1" in
    claude) printf 'Claude Code' ;;
    codex) printf 'Codex CLI' ;;
    gemini) printf 'Gemini CLI' ;;
    openclaw) printf 'OpenClaw' ;;
    *) return 1 ;;
  esac
}

lane_command() {
  case "$1" in
    claude) printf 'claude' ;;
    codex) printf 'codex' ;;
    gemini) printf 'gemini' ;;
    openclaw) printf 'openclaw' ;;
    *) return 1 ;;
  esac
}

run_capture() {
  local out="$1" err="$2"
  shift 2
  set +e
  "$@" >"$out" 2>"$err"
  RUN_CAPTURE_RC=$?
  set -e
  return 0
}

private_state_scan_json() {
  local dir="$1"
  local findings_file="$2"
  : >"$findings_file"
  if rg -n --glob '!assemble.json' '/Users/josh|/Users/[^/]+/\\.claude|\\.ntm|AGENT_MAIL_[A-Z_]*=|sk-[A-Za-z0-9_-]{12,}|ghp_[A-Za-z0-9_]{20,}' "$dir" \
    >"$findings_file" 2>/dev/null; then
    jq -nc --argjson findings "$(sed 's/^/finding: /' "$findings_file" | json_string_array)" '{
      status:"fail",
      findings:$findings
    }'
  else
    jq -nc '{status:"pass", findings:[]}'
  fi
}

stage_json() {
  local name="$1" status="$2" rc="$3" file="$4"
  jq -nc --arg name "$name" --arg status "$status" --argjson rc "$rc" --arg file "$file" '{
    name:$name,
    status:$status,
    exit_code:$rc,
    artifact:$file
  }'
}

write_blocker_receipt() {
  local lane="$1" receipt="$2" generated="$3" command_name="$4" cli_present="$5" private_scan="$6"
  local display blocker_class reason next_action scan_status
  display="$(lane_display "$lane")"
  blocker_class="isolated_runtime_receipt_missing"
  if [[ "$cli_present" != "true" ]]; then
    blocker_class="install_required"
  fi
  if [[ "$blocker_class" == "install_required" ]]; then
    reason="$display command '$command_name' is not installed in PATH for this isolated run."
    next_action="Install $display, re-run this isolated lane smoke, then replace this blocker only if every runtime stage passes."
  else
    reason="$display is installed, but Flywheel does not yet have an isolated live adapter receipt proving the full first-run journey through that lane."
    next_action="Run the $display lane in an isolated public export with a live adapter and replace this blocker only if preflight, init, doctor, tick, dispatch_or_simulate, closeout, inspect_next_action, and private_state_scan all pass."
  fi
  scan_status="$(jq -r '.status' <<<"$private_scan")"
  if [[ "$scan_status" == "pass" ]]; then
    scan_status="not_run"
  else
    scan_status="blocked"
  fi
  jq -nc \
    --arg id "$lane" --arg agent "$display" --arg generated_at "$generated" \
    --arg blocker_class "$blocker_class" --arg blocker_reason "$reason" \
    --arg next_action "$next_action" --arg scan_status "$scan_status" '{
      schema_version:"flywheel.agent_lane_blocker_receipt.v0",
      id:$id,
      agent:$agent,
      generated_at:$generated_at,
      status:"blocked",
      runtime_proven:false,
      support_copy_allowed:false,
      support_scope:"blocked",
      command:"scripts/agent-lane-probe.sh --receipt-dir receipts/agent-lanes --json",
      blocker_class:$blocker_class,
      blocker_reason:$blocker_reason,
      next_action:$next_action,
      private_state_scan:{status:$scan_status}
    }' >"$receipt"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lanes) [[ $# -ge 2 ]] || die_usage "--lanes requires comma-separated lanes"; LANES="$2"; shift 2 ;;
    --lanes=*) LANES="${1#*=}"; shift ;;
    --receipt-dir) [[ $# -ge 2 ]] || die_usage "--receipt-dir requires DIR"; RECEIPT_DIR="$2"; shift 2 ;;
    --receipt-dir=*) RECEIPT_DIR="${1#*=}"; shift ;;
    --source) [[ $# -ge 2 ]] || die_usage "--source requires DIR"; SOURCE="$2"; shift 2 ;;
    --source=*) SOURCE="${1#*=}"; shift ;;
    --skip-assemble) SKIP_ASSEMBLE=1; shift ;;
    --require-runtime) REQUIRE_RUNTIME=1; shift ;;
    --keep-temp) KEEP_TEMP=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die_usage "unknown argument: $1" ;;
  esac
done

[[ "$JSON_OUT" -eq 1 ]] || die_usage "--json is required"
need git
need jq
need rg

tmp="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-isolated-agent-lane.XXXXXX")"
if [[ "$KEEP_TEMP" -eq 0 ]]; then
  trap 'rm -rf "$tmp"' EXIT
else
  trap 'printf "kept temp: %s\n" "$tmp" >&2' EXIT
fi

generated="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
run_id="isolated-agent-lane-$(date -u +"%Y%m%dT%H%M%SZ")"
home="$tmp/home"
xdg_config="$tmp/xdg-config"
xdg_cache="$tmp/xdg-cache"
prefix="$tmp/engine"
repo="$tmp/target-repo"
artifacts="$tmp/artifacts"
receipts="${RECEIPT_DIR:-$tmp/agent-lane-receipts}"
mkdir -p "$home" "$xdg_config" "$xdg_cache" "$repo" "$artifacts" "$receipts"
git -C "$repo" init -q

source_root="$(cd "$SOURCE" && pwd -P)"
public_root="$source_root"
assemble_status="skipped"
assemble_json="null"
if [[ "$SKIP_ASSEMBLE" -eq 0 ]]; then
  public_root="$tmp/public-export"
  run_capture "$artifacts/assemble.json" "$artifacts/assemble.err" \
    python3 "$source_root/scripts/assemble.py" \
      --source "$source_root" \
      --staging "$public_root" \
      --run-root "$tmp/extraction" \
      --run-id "$run_id" \
      --clean \
      --json
  assemble_rc=$RUN_CAPTURE_RC
  if [[ "$assemble_rc" -eq 0 ]]; then
    assemble_status="pass"
    assemble_json="$(jq -c '{status, run_id, copied_count, denylist_excluded_count, manual_review_count, source_git_status_unchanged}' "$artifacts/assemble.json")"
  else
    assemble_status="fail"
    assemble_json="$(jq -nc --argjson rc "$assemble_rc" --rawfile err "$artifacts/assemble.err" '{status:"fail", exit_code:$rc, stderr:$err}')"
  fi
fi

PATH="$PATH" \
HOME="$home" \
XDG_CONFIG_HOME="$xdg_config" \
XDG_CACHE_HOME="$xdg_cache" \
run_capture "$artifacts/install.json" "$artifacts/install.err" \
  "$public_root/install.sh" --prefix "$prefix" --json
install_rc=$RUN_CAPTURE_RC

run_capture "$artifacts/preflight.json" "$artifacts/preflight.err" "$prefix/bin/flywheel" preflight --json
preflight_rc=$RUN_CAPTURE_RC
run_capture "$artifacts/init.json" "$artifacts/init.err" "$prefix/bin/flywheel" init --repo "$repo" --json
init_rc=$RUN_CAPTURE_RC
run_capture "$artifacts/doctor.json" "$artifacts/doctor.err" "$prefix/bin/flywheel" doctor --repo "$repo" --json
doctor_rc=$RUN_CAPTURE_RC
run_capture "$artifacts/tick.json" "$artifacts/tick.err" "$prefix/bin/flywheel" tick --repo "$repo" --dry-run --json
tick_rc=$RUN_CAPTURE_RC
run_capture "$artifacts/dispatch.json" "$artifacts/dispatch.err" "$prefix/bin/flywheel" dispatch --repo "$repo" --simulate --json
dispatch_rc=$RUN_CAPTURE_RC
run_capture "$artifacts/closeout.json" "$artifacts/closeout.err" "$prefix/bin/flywheel" validate-receipt --repo "$repo" --file .flywheel/last_closeout_receipt.json --json
closeout_rc=$RUN_CAPTURE_RC
run_capture "$artifacts/inspect.json" "$artifacts/inspect.err" "$prefix/bin/flywheel" inspect --repo "$repo" --json
inspect_rc=$RUN_CAPTURE_RC

private_scan="$(private_state_scan_json "$artifacts" "$artifacts/private-state-findings.txt")"

stage_rows="$(
  {
    stage_json preflight "$([[ "$preflight_rc" -le 20 ]] && printf pass || printf fail)" "$preflight_rc" "$artifacts/preflight.json"
    stage_json init "$([[ "$init_rc" -eq 0 ]] && printf pass || printf fail)" "$init_rc" "$artifacts/init.json"
    stage_json doctor "$([[ "$doctor_rc" -eq 0 ]] && printf pass || printf fail)" "$doctor_rc" "$artifacts/doctor.json"
    stage_json tick "$([[ "$tick_rc" -eq 0 ]] && printf pass || printf fail)" "$tick_rc" "$artifacts/tick.json"
    stage_json dispatch_or_simulate "$([[ "$dispatch_rc" -eq 0 ]] && printf pass || printf fail)" "$dispatch_rc" "$artifacts/dispatch.json"
    stage_json closeout "$([[ "$closeout_rc" -eq 0 ]] && printf pass || printf fail)" "$closeout_rc" "$artifacts/closeout.json"
    stage_json inspect_next_action "$([[ "$inspect_rc" -eq 0 ]] && printf pass || printf fail)" "$inspect_rc" "$artifacts/inspect.json"
  } | jq -s '.'
)"

reduced_pass=false
if jq -e 'all(.[]; .status == "pass")' <<<"$stage_rows" >/dev/null \
  && jq -e '.status == "pass"' <<<"$private_scan" >/dev/null; then
  reduced_pass=true
fi

lane_rows_file="$tmp/lane-rows.jsonl"
: >"$lane_rows_file"
IFS=',' read -r -a lane_array <<<"$LANES"
for raw_lane in "${lane_array[@]}"; do
  lane="${raw_lane//[[:space:]]/}"
  [[ -n "$lane" ]] || continue
  display="$(lane_display "$lane")" || die_usage "unknown lane: $lane"
  command_name="$(lane_command "$lane")"
  cli_present=false
  command_path=""
  version_rc=127
  version_excerpt=""
  if command_path="$(command -v "$command_name" 2>/dev/null)"; then
    cli_present=true
    run_capture "$artifacts/${lane}-version.out" "$artifacts/${lane}-version.err" "$command_name" --version
    version_rc=$RUN_CAPTURE_RC
    version_excerpt="$(head -n 1 "$artifacts/${lane}-version.out" 2>/dev/null | cut -c 1-160 || true)"
    if [[ -z "$version_excerpt" ]]; then
      version_excerpt="$(head -n 1 "$artifacts/${lane}-version.err" 2>/dev/null | cut -c 1-160 || true)"
    fi
  fi
  receipt="$receipts/$lane.json"
  write_blocker_receipt "$lane" "$receipt" "$generated" "$command_name" "$cli_present" "$private_scan"
  jq -nc \
    --arg id "$lane" --arg display "$display" --arg command "$command_name" \
    --arg command_path "$command_path" --arg receipt "$receipt" --arg version_excerpt "$version_excerpt" \
    --argjson cli_present "$cli_present" --argjson version_rc "$version_rc" '{
      id:$id,
      display_name:$display,
      command:$command,
      command_path:(if $command_path == "" then null else "present" end),
      cli_present:$cli_present,
      version_exit_code:$version_rc,
      version_excerpt:$version_excerpt,
      runtime_proven:false,
      receipt:$receipt,
      evidence:"blocker_receipt"
    }' >>"$lane_rows_file"
done
lane_rows="$(jq -s '.' "$lane_rows_file")"

run_capture "$artifacts/agent-lanes-with-receipts.json" "$artifacts/agent-lanes-with-receipts.err" \
  "$public_root/scripts/agent-lane-probe.sh" --receipt-dir "$receipts" --json
probe_rc=$RUN_CAPTURE_RC
probe_json="$(if [[ -s "$artifacts/agent-lanes-with-receipts.json" ]]; then cat "$artifacts/agent-lanes-with-receipts.json"; else jq -nc '{}'; fi)"

runtime_count="$(jq '[.[] | select(.runtime_proven == true)] | length' <<<"$lane_rows")"
status="pass"
exit_code=0
if [[ "$assemble_status" == "fail" || "$install_rc" -ne 0 || "$reduced_pass" != "true" || "$probe_rc" -ne 0 ]]; then
  status="fail"
  exit_code=1
elif [[ "$REQUIRE_RUNTIME" -eq 1 && "$runtime_count" -lt "${#lane_array[@]}" ]]; then
  status="blocked"
  exit_code=20
fi

payload="$(
  jq -nc \
    --arg sv "$SCHEMA_VERSION" --arg generated_at "$generated" --arg status "$status" \
    --arg run_id "$run_id" --arg tmp "$tmp" --arg source "source-repo" --arg public_root "$([[ "$SKIP_ASSEMBLE" -eq 1 ]] && printf source-repo || printf public-export)" \
    --arg prefix "$prefix" --arg target_repo "$repo" --arg receipt_dir "$receipts" \
    --arg assemble_status "$assemble_status" --argjson assemble "$assemble_json" \
    --argjson install_rc "$install_rc" --argjson preflight_rc "$preflight_rc" \
    --argjson reduced_pass "$reduced_pass" --argjson stages "$stage_rows" \
    --argjson private_scan "$private_scan" --argjson lanes "$lane_rows" \
    --argjson probe_rc "$probe_rc" --argjson probe "$probe_json" '{
      schema_version:$sv,
      generated_at:$generated_at,
      status:$status,
      run_id:$run_id,
      isolation:{
        temp_root:$tmp,
        source:$source,
        public_root:$public_root,
        prefix:$prefix,
        target_repo:$target_repo,
        receipt_dir:$receipt_dir,
        home_isolated:true,
        xdg_isolated:true
      },
      assemble:{status:$assemble_status, receipt:$assemble},
      install:{exit_code:$install_rc},
      preflight:{exit_code:$preflight_rc},
      reduced_journey:{runtime_proven:$reduced_pass, stages:$stages},
      private_state_scan:$private_scan,
      lanes:$lanes,
      agent_lane_probe:{exit_code:$probe_rc, receipt:$probe},
      support_copy_gate:{
        reduced_supported:$reduced_pass,
        claude_supported:($probe.rows[]? | select(.id == "claude") | .support_copy_allowed) // false,
        codex_supported:($probe.rows[]? | select(.id == "codex") | .support_copy_allowed) // false,
        gemini_supported:($probe.rows[]? | select(.id == "gemini") | .support_copy_allowed) // false,
        openclaw_supported:($probe.rows[]? | select(.id == "openclaw") | .support_copy_allowed) // false
      },
      blockers:($probe.rows // [] | map(select(.support_copy_allowed == false) | {id, evidence, blocker_class:.blocker.blocker_class, blocker_reason:.blocker.blocker_reason, next_action:.blocker.next_action}))
    }'
)"

printf '%s\n' "$payload"
exit "$exit_code"
