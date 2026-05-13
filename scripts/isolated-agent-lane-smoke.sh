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
LIVE_ADAPTERS=0
ADAPTER_TIMEOUT=45

usage() {
  cat <<'EOF'
usage: scripts/isolated-agent-lane-smoke.sh [--lanes claude,codex,gemini,openclaw] [--receipt-dir DIR] [--skip-assemble] [--live-adapters] [--adapter-timeout SECONDS] [--require-runtime] --json

Creates an isolated HOME, XDG config/cache, install prefix, public export, and
target repo. It proves the public reduced path end to end, then writes one
runtime or blocker receipt per requested agent lane.

Without a lane-specific live adapter, installed CLIs are treated as setup
evidence only and the lane receives an isolated_runtime_receipt_missing blocker.
With --live-adapters, each installed CLI must respond in the isolated repo before
the lane receives support-copy runtime proof.
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

run_capture_timeout() {
  local out="$1" err="$2" timeout_seconds="$3"
  shift 3
  set +e
  python3 - "$out" "$err" "$timeout_seconds" "$@" <<'PY'
import subprocess
import sys

out_path, err_path, timeout_text, *cmd = sys.argv[1:]
timeout = float(timeout_text)
try:
    completed = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        timeout=timeout,
        check=False,
    )
    with open(out_path, "w", encoding="utf-8") as out_file:
        out_file.write(completed.stdout)
    with open(err_path, "w", encoding="utf-8") as err_file:
        err_file.write(completed.stderr)
    sys.exit(completed.returncode)
except subprocess.TimeoutExpired as exc:
    with open(out_path, "w", encoding="utf-8") as out_file:
        out_file.write(exc.stdout or "")
    with open(err_path, "w", encoding="utf-8") as err_file:
        err_file.write((exc.stderr or "") + f"\nTIMEOUT after {timeout:g}s\n")
    sys.exit(124)
PY
  RUN_CAPTURE_RC=$?
  set -e
  return 0
}

safe_excerpt_file() {
  local file="$1"
  if [[ ! -s "$file" ]]; then
    printf ''
    return 0
  fi
  head -c 1200 "$file" \
    | tr '\n\r' '  ' \
    | sed -E 's#/Users/[^ ]+#<home>#g; s#sk-[A-Za-z0-9_-]{12,}#<secret>#g; s#ghp_[A-Za-z0-9_]{20,}#<secret>#g; s#AGENT_MAIL_[A-Z_]*=[^ ]+#AGENT_MAIL_<redacted>#g' \
    | cut -c 1-360
}

classify_adapter_blocker() {
  local lane="$1" rc="$2" out="$3" err="$4"
  local text
  text="$(cat "$out" "$err" 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
  if [[ "$text" =~ (auth|login|log\ in|api[[:space:]_-]*key|unauthorized|forbidden|not[[:space:]_-]*authenticated|credential|token) ]]; then
    printf 'auth_required'
  elif [[ "$text" =~ (unknown[[:space:]_-]*agent|agent[[:space:]_-]*id|configured[[:space:]_-]*agents|config|configuration) ]]; then
    printf 'adapter_config_required'
  elif [[ "$lane" == "openclaw" && "$text" =~ (daemon|gateway|connection[[:space:]_-]*refused|econnrefused|not[[:space:]_-]*running) ]]; then
    printf 'daemon_unavailable'
  elif [[ "$rc" -eq 124 ]]; then
    printf 'daemon_unavailable'
  else
    printf 'isolated_runtime_receipt_missing'
  fi
}

blocker_reason_for_class() {
  local lane="$1" blocker_class="$2" command_name="$3"
  local display
  display="$(lane_display "$lane")"
  case "$blocker_class" in
    install_required)
      printf "%s command '%s' is not installed in PATH for this isolated run." "$display" "$command_name"
      ;;
    auth_required)
      printf "%s live adapter was present, but the isolated environment did not have usable authentication." "$display"
      ;;
    adapter_config_required)
      printf "%s live adapter was present, but the isolated environment did not have the required agent/session configuration." "$display"
      ;;
    daemon_unavailable)
      printf "%s live adapter did not complete before timeout or its local daemon/gateway was unavailable." "$display"
      ;;
    *)
      printf "%s is installed, but Flywheel does not yet have an isolated live adapter receipt proving the full first-run journey through that lane." "$display"
      ;;
  esac
}

blocker_next_action_for_class() {
  local lane="$1" blocker_class="$2"
  local display
  display="$(lane_display "$lane")"
  case "$blocker_class" in
    install_required)
      printf "Install %s, re-run this isolated lane smoke with --live-adapters, then replace this blocker only if every runtime stage passes." "$display"
      ;;
    auth_required)
      printf "Provide %s credentials to the isolated environment, re-run with --live-adapters, and keep this blocker until the live adapter returns a passing runtime receipt." "$display"
      ;;
    adapter_config_required)
      printf "Configure the %s agent/session in the isolated environment, re-run with --live-adapters, and keep this blocker until the live adapter returns a passing runtime receipt." "$display"
      ;;
    daemon_unavailable)
      printf "Start or configure the %s local gateway/daemon, re-run with --live-adapters, and keep this blocker until the live adapter returns a passing runtime receipt." "$display"
      ;;
    *)
      printf "Run the %s lane in an isolated public export with --live-adapters and replace this blocker only if preflight, init, doctor, tick, dispatch_or_simulate, closeout, inspect_next_action, and private_state_scan all pass." "$display"
      ;;
  esac
}

adapter_prompt() {
  printf 'You are running a Flywheel isolated lane smoke test. Reply exactly FLYWHEEL_LANE_OK and do not modify files.'
}

run_live_adapter() {
  local lane="$1" out="$2" err="$3"
  local prompt codex_last openclaw_state
  prompt="$(adapter_prompt)"
  case "$lane" in
    claude)
      run_capture_timeout "$out" "$err" "$ADAPTER_TIMEOUT" \
        env HOME="$home" XDG_CONFIG_HOME="$xdg_config" XDG_CACHE_HOME="$xdg_cache" \
        claude --bare --print --no-session-persistence --permission-mode plan --tools "" \
          --output-format json --max-budget-usd 0.05 "$prompt"
      ;;
    codex)
      codex_last="$artifacts/codex-last-message.txt"
      mkdir -p "$home/.codex"
      run_capture_timeout "$out" "$err" "$ADAPTER_TIMEOUT" \
        env HOME="$home" XDG_CONFIG_HOME="$xdg_config" XDG_CACHE_HOME="$xdg_cache" CODEX_HOME="$home/.codex" \
        codex exec --ignore-user-config --ignore-rules --ephemeral --sandbox read-only --cd "$repo" \
          --output-last-message "$codex_last" "$prompt"
      if [[ -s "$codex_last" ]]; then
        printf '\n%s\n' "$(safe_excerpt_file "$codex_last")" >>"$out"
      fi
      ;;
    gemini)
      run_capture_timeout "$out" "$err" "$ADAPTER_TIMEOUT" \
        env HOME="$home" XDG_CONFIG_HOME="$xdg_config" XDG_CACHE_HOME="$xdg_cache" \
        gemini --prompt "$prompt" --approval-mode plan --output-format json --include-directories "$repo"
      ;;
    openclaw)
      openclaw_state="$home/.openclaw-isolated"
      mkdir -p "$openclaw_state"
      run_capture_timeout "$out" "$err" "$ADAPTER_TIMEOUT" \
        env HOME="$home" XDG_CONFIG_HOME="$xdg_config" XDG_CACHE_HOME="$xdg_cache" \
          OPENCLAW_STATE_DIR="$openclaw_state" OPENCLAW_CONFIG_PATH="$openclaw_state/config.json" \
        openclaw agent --local --agent flywheel-lane-smoke --message "$prompt" --json --timeout "$ADAPTER_TIMEOUT"
      ;;
    *)
      RUN_CAPTURE_RC=64
      printf 'unknown lane: %s\n' "$lane" >"$err"
      : >"$out"
      ;;
  esac
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
  local class_override="${7:-}"
  local display blocker_class reason next_action scan_status
  display="$(lane_display "$lane")"
  blocker_class="${class_override:-isolated_runtime_receipt_missing}"
  if [[ "$cli_present" != "true" && -z "$class_override" ]]; then
    blocker_class="install_required"
  fi
  reason="$(blocker_reason_for_class "$lane" "$blocker_class" "$command_name")"
  next_action="$(blocker_next_action_for_class "$lane" "$blocker_class")"
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

adapter_json() {
  local lane="$1" mode="$2" rc="$3" out="$4" err="$5" blocker_class="$6"
  local stdout_excerpt stderr_excerpt
  stdout_excerpt="$(safe_excerpt_file "$out")"
  stderr_excerpt="$(safe_excerpt_file "$err")"
  jq -nc \
    --arg lane "$lane" --arg mode "$mode" --argjson rc "$rc" \
    --arg stdout_excerpt "$stdout_excerpt" --arg stderr_excerpt "$stderr_excerpt" \
    --arg blocker_class "$blocker_class" '{
      lane:$lane,
      mode:$mode,
      exit_code:$rc,
      expected_marker:"FLYWHEEL_LANE_OK",
      stdout_excerpt:$stdout_excerpt,
      stderr_excerpt:$stderr_excerpt,
      blocker_class:(if $blocker_class == "" then null else $blocker_class end)
    }'
}

write_runtime_receipt() {
  local lane="$1" receipt="$2" generated="$3" private_scan="$4" adapter="$5"
  local display
  display="$(lane_display "$lane")"
  jq -nc \
    --arg id "$lane" --arg agent "$display" --arg generated_at "$generated" \
    --argjson stages "$stage_rows" --argjson private_scan "$private_scan" --argjson adapter "$adapter" '{
      schema_version:"flywheel.agent_lane_runtime_receipt.v0",
      id:$id,
      agent:$agent,
      generated_at:$generated_at,
      status:"pass",
      runtime_proven:true,
      support_copy_allowed:true,
      support_scope:"isolated",
      command:"scripts/journey-smoke.sh --reduced --live-adapters --json",
      adapter:$adapter,
      journey_stages:$stages,
      private_state_scan:$private_scan
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
    --live-adapters) LIVE_ADAPTERS=1; shift ;;
    --adapter-timeout) [[ $# -ge 2 ]] || die_usage "--adapter-timeout requires SECONDS"; ADAPTER_TIMEOUT="$2"; shift 2 ;;
    --adapter-timeout=*) ADAPTER_TIMEOUT="${1#*=}"; shift ;;
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
if [[ "$LIVE_ADAPTERS" -eq 1 ]]; then
  need python3
fi

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
  runtime_proven=false
  evidence="blocker_receipt"
  adapter="null"
  blocker_class=""
  adapter_rc=0
  adapter_out="$artifacts/${lane}-adapter.out"
  adapter_err="$artifacts/${lane}-adapter.err"
  if [[ "$cli_present" == "true" && "$LIVE_ADAPTERS" -eq 1 && "$reduced_pass" == "true" ]]; then
    run_live_adapter "$lane" "$adapter_out" "$adapter_err"
    adapter_rc=$RUN_CAPTURE_RC
    if [[ "$adapter_rc" -eq 0 ]] && rg -q 'FLYWHEEL_LANE_OK' "$adapter_out" "$adapter_err"; then
      adapter="$(adapter_json "$lane" "live_adapter" "$adapter_rc" "$adapter_out" "$adapter_err" "")"
      write_runtime_receipt "$lane" "$receipt" "$generated" "$private_scan" "$adapter"
      runtime_proven=true
      evidence="runtime_receipt"
    else
      blocker_class="$(classify_adapter_blocker "$lane" "$adapter_rc" "$adapter_out" "$adapter_err")"
      adapter="$(adapter_json "$lane" "live_adapter" "$adapter_rc" "$adapter_out" "$adapter_err" "$blocker_class")"
      write_blocker_receipt "$lane" "$receipt" "$generated" "$command_name" "$cli_present" "$private_scan" "$blocker_class"
    fi
  else
    write_blocker_receipt "$lane" "$receipt" "$generated" "$command_name" "$cli_present" "$private_scan"
  fi
  jq -nc \
    --arg id "$lane" --arg display "$display" --arg command "$command_name" \
    --arg command_path "$command_path" --arg receipt "$receipt" --arg version_excerpt "$version_excerpt" \
    --arg evidence "$evidence" --argjson cli_present "$cli_present" --argjson version_rc "$version_rc" \
    --argjson runtime_proven "$runtime_proven" --argjson adapter "$adapter" '{
      id:$id,
      display_name:$display,
      command:$command,
      command_path:(if $command_path == "" then null else "present" end),
      cli_present:$cli_present,
      version_exit_code:$version_rc,
      version_excerpt:$version_excerpt,
      runtime_proven:$runtime_proven,
      receipt:$receipt,
      evidence:$evidence,
      adapter:$adapter
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
      blockers:(($lanes | map(.id)) as $requested_lane_ids
        | $probe.rows // []
        | map(select(.id as $id | $requested_lane_ids | index($id))
          | select(.support_copy_allowed == false)
          | {id, evidence, blocker_class:.blocker.blocker_class, blocker_reason:.blocker.blocker_reason, next_action:.blocker.next_action}))
    }'
)"

printf '%s\n' "$payload"
exit "$exit_code"
