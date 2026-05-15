#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="flywheel.preflight.v0"
FIXTURE_SCHEMA_VERSION="flywheel.preflight.fixture.v0"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
FIXTURE_DIR="$ROOT/fixtures/preflight"
MODE="run"
# Accepted for CLI compatibility; current preflight output is JSON in all
# machine-readable modes.
# shellcheck disable=SC2034
JSON_OUT=0
FIXTURE=""
SUBJECT=""
# --public: technical-reviewer-friendly mode. Maps reduced-mode-available (exit 20)
# → exit 0 so the public-page-documented invocation succeeds for fresh-clone
# reviewers. Substrate consumers keep the canonical 20=reduced semantic by not
# passing --public. P9 of substrate-compounding-v2.
PUBLIC_MODE=0

usage() {
  cat <<'EOF'
usage:
  scripts/preflight.sh --json
  scripts/preflight.sh --fixture fixtures/preflight/partial.json --json
  scripts/preflight.sh validate --fixture fixtures/preflight/partial.json --json
  scripts/preflight.sh doctor --json
  scripts/preflight.sh health --json
  scripts/preflight.sh --schema
  scripts/preflight.sh --examples --json
  scripts/preflight.sh quickstart
  scripts/preflight.sh help exit-codes
EOF
}

die_usage() {
  printf 'ERROR: %s\n' "$1" >&2
  usage >&2
  exit 64
}

need_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    cat >&2 <<'EOF'
ERROR: jq is required to run Flywheel preflight.
Suggested action: install jq with Homebrew, apt, or the ACFS package phase.
EOF
    exit 30
  fi
}

matrix_tsv() {
  cat <<'EOF'
git	runtime	required	git --version	system package, Xcode CLT, or Homebrew	block
shell	runtime	required	sh -c 'echo ok'	system shell	block
bash	runtime	required	bash --version	Homebrew bash on macOS or apt bash	block
jq	runtime	required	jq --version	Homebrew or apt	block
sqlite	runtime	full-mode	sqlite3 --version	system package or Homebrew	reduced CLI state uses repo-local files
br	substrate	full-mode	br --version	Beads CLI install path	dispatch simulation only if absent
validated-closeout-fixture	substrate	required	test -f fixtures/preflight/reduced.json	repo fixture support	block fixture closeout
python	runtime	full-mode	python3 --version	uv, pyenv, Homebrew, or apt	no Agent Mail server; single-agent only
node	runtime	full-mode	node --version	nvm, Homebrew, apt, or Bun installer	no docs dev server or Node-backed memory
cargo	runtime	full-mode	cargo --version	rustup	destructive command guard may be unavailable
tmux	substrate	full-mode	tmux -V	Homebrew or apt	simulated dispatch only
ntm	substrate	full-mode	ntm --version	ACFS phase 8 or manual NTM install	dispatch simulation only
agent-mail	substrate	full-mode	python3 -c 'import mcp_agent_mail'	Agent Mail Python package or service install	no reservations or cross-agent mail
dcg	substrate	full-mode	dcg --version	destructive_command_guard install or cargo build	manual caution required
socraticode	substrate	full-mode	socraticode --help	MCP setup docs	non-trivial edits need manual search
go	runtime	enhanced	go version	Homebrew, apt, tarball, or ACFS phase 5	skip Go build path
cass	substrate	enhanced	cass --help	CASS-style memory service	no cross-session memory claims
beads-viewer	substrate	enhanced	beads_viewer --version	go install or source build	CLI-only Beads inspection
claude	harness	compatibility-target	claude --version	ACFS phase 6 or official Claude Code install	label compatibility-target until receipt-proven
codex	harness	compatibility-target	codex --version	ACFS phase 6 or official Codex CLI install	label compatibility-target until receipt-proven
openclaw	harness	compatibility-target	openclaw --version	OpenClaw install docs after smoke proof	label compatibility-target until smoke-proven
gemini	harness	compatibility-target	gemini --version	ACFS phase 6 or official Gemini CLI install	label compatibility-target until smoke-proven
EOF
}

known_commands_json() {
  matrix_tsv | awk -F '\t' '{print $4}' | jq -Rsc 'split("\n")[:-1]'
}

schema_json() {
  jq -nc --arg sv "$SCHEMA_VERSION" --arg fsv "$FIXTURE_SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"schema",
    result:{
      required:["schema_version","command","mode","exit_code","host","summary","dependencies","harnesses","reduced_mode","next_action"],
      dependency_status:["present","missing","misconfigured","unknown"],
      modes:["full","reduced","blocked","docs-only"],
      fixture_schema_version:$fsv
    }
  }'
}

examples_json() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"examples",
    examples:[
      {name:"full", invocation:"scripts/preflight.sh --fixture fixtures/preflight/existing.json --json", expected_exit:0},
      {name:"reduced", invocation:"scripts/preflight.sh --fixture fixtures/preflight/partial.json --json", expected_exit:20},
      {name:"blocked", invocation:"scripts/preflight.sh --fixture fixtures/preflight/fresh.json --json", expected_exit:30},
      {name:"docs-only", invocation:"scripts/preflight.sh --fixture fixtures/preflight/misconfigured.json --json", expected_exit:30}
    ],
    exit_codes:{"0":"full mode","10":"full mode with enhanced warnings","20":"reduced mode","30":"blocked or docs-only","40":"fixture or internal error","64":"usage error"}
  }'
}

exit_codes_help() {
  cat <<'EOF'
Exit codes:
  0   full-mode preflight passes
  10  full-mode passes with enhanced/optional warnings
  20  reduced mode selected and first-run tutorial remains runnable
  30  blocked or docs-only
  40  malformed fixture, unsupported fixture, or internal preflight error
  64  usage error
EOF
}

quickstart() {
  cat <<'EOF'
1. Run: scripts/preflight.sh --json
2. If mode is reduced, continue with the reduced-mode first-run tutorial.
3. If mode is blocked, install the required dependencies named in summary.required_missing.
4. Re-run preflight before doctor/tick/dispatch-or-simulate.
EOF
}

validate_fixture() {
  local fixture="$1"
  local label="${fixture#"$ROOT"/}"
  [[ -f "$fixture" ]] || {
    printf 'ERROR: fixture not found: %s\nSuggested action: pass --fixture fixtures/preflight/<name>.json\n' "$label" >&2
    return 40
  }
  jq empty "$fixture" >/dev/null 2>&1 || {
    printf 'ERROR: malformed fixture JSON: %s\nSuggested action: repair JSON syntax before running preflight.\n' "$label" >&2
    return 40
  }
  jq -e --arg sv "$FIXTURE_SCHEMA_VERSION" '
    .schema_version == $sv
    and (.name | type == "string")
    and (.host | type == "object")
    and (.commands | type == "object")
    and ([.commands[] | has("exit_code") and (.exit_code|type=="number") and (.stdout|type=="string") and (.stderr|type=="string")] | all)
  ' "$fixture" >/dev/null || {
    printf 'ERROR: fixture schema invalid: %s\nSuggested action: use schema_version=%s and object command results with exit_code/stdout/stderr.\n' "$label" "$FIXTURE_SCHEMA_VERSION" >&2
    return 40
  }
  local known
  known="$(known_commands_json)"
  jq -e --argjson known "$known" '
    (.commands | keys) as $keys
    | all($keys[]; . as $k | $known | index($k) != null)
  ' "$fixture" >/dev/null || {
    printf 'ERROR: fixture names an unknown command: %s\nSuggested action: align fixture commands with the dependency matrix.\n' "$label" >&2
    return 40
  }
  if rg -n '/Users/[^/]+|sk-[A-Za-z0-9_-]{12,}|ghp_[A-Za-z0-9_]{20,}' "$fixture" >/dev/null 2>&1; then
    printf 'ERROR: fixture contains private path or secret-shaped material: %s\nSuggested action: replace with synthetic fixture values.\n' "$label" >&2
    return 40
  fi
  return 0
}

fixture_result_json() {
  local fixture="$1" cmd="$2"
  jq -nc --argjson row "$(jq -c --arg cmd "$cmd" '.commands[$cmd] // {"exit_code":127,"stdout":"","stderr":"fixture command missing"}' "$fixture")" '
    {source:"fixture", exit_code:$row.exit_code, stdout_excerpt:($row.stdout|split("\n")[0]|.[0:160]), stderr_excerpt:($row.stderr|split("\n")[0]|.[0:160]), version:(if $row.exit_code == 0 then ($row.stdout|split("\n")[0]|.[0:80]) else null end)}
  '
}

live_result_json() {
  local cmd="$1" tmp_out tmp_err rc
  tmp_out="$(mktemp -t flywheel-preflight-out.XXXXXX)"
  tmp_err="$(mktemp -t flywheel-preflight-err.XXXXXX)"
  set +e
  (cd "$ROOT" && sh -c "$cmd") >"$tmp_out" 2>"$tmp_err"
  rc=$?
  set -e
  jq -Rs --argjson rc "$rc" --rawfile err "$tmp_err" '
    {source:"live", exit_code:$rc, stdout_excerpt:(split("\n")[0]|.[0:160]), stderr_excerpt:($err|split("\n")[0]|.[0:160]), version:(if $rc == 0 then (split("\n")[0]|.[0:80]) else null end)}
  ' "$tmp_out"
  rm -f "$tmp_out" "$tmp_err"
}

status_from_exit() {
  local rc="$1"
  if [[ "$rc" -eq 0 ]]; then
    printf 'present'
  elif [[ "$rc" -eq 127 ]]; then
    printf 'missing'
  else
    printf 'misconfigured'
  fi
}

emit_rows_jsonl() {
  local deps_jsonl="$1"
  while IFS=$'\t' read -r id kind tier cmd hint consequence; do
    local evidence rc status effect
    if [[ -n "$FIXTURE" ]]; then
      evidence="$(fixture_result_json "$FIXTURE" "$cmd")"
    else
      evidence="$(live_result_json "$cmd")"
    fi
    rc="$(jq -r '.exit_code' <<<"$evidence")"
    status="$(status_from_exit "$rc")"
    effect="full"
    if [[ "$tier" == "required" && "$status" != "present" ]]; then
      effect="blocked"
    elif [[ "$tier" == "full-mode" && "$status" != "present" ]]; then
      effect="reduced"
    elif [[ "$kind" == "harness" && "$status" != "present" ]]; then
      effect="docs-only"
    fi
    jq -nc \
      --arg id "$id" --arg kind "$kind" --arg tier "$tier" --arg status "$status" \
      --arg effect "$effect" --arg cmd "$cmd" --arg hint "$hint" --arg consequence "$consequence" \
      --argjson evidence "$evidence" \
      '{id:$id,kind:$kind,tier:$tier,status:$status,mode_effect:$effect,detect_command:$cmd,evidence:$evidence,install_hint:$hint,reduced_mode_consequence:$consequence}' \
      >>"$deps_jsonl"
  done < <(matrix_tsv)
}

result_envelope() {
  local deps_jsonl deps_json required_missing full_missing enhanced_missing misconfigured mode exit_code next_kind next_cmd fixture_flag host_os host_arch
  deps_jsonl="$(mktemp -t flywheel-preflight-deps.XXXXXX)"
  trap 'rm -f "$deps_jsonl"' RETURN
  emit_rows_jsonl "$deps_jsonl"
  deps_json="$(jq -s '.' "$deps_jsonl")"

  required_missing="$(jq '[.[] | select(.tier=="required" and .status!="present") | .id]' <<<"$deps_json")"
  full_missing="$(jq '[.[] | select(.tier=="full-mode" and .status!="present") | .id]' <<<"$deps_json")"
  enhanced_missing="$(jq '[.[] | select(.tier=="enhanced" and .status!="present") | .id]' <<<"$deps_json")"
  misconfigured="$(jq '[.[] | select(.status=="misconfigured") | .id]' <<<"$deps_json")"

  if [[ "$(jq 'length' <<<"$required_missing")" -gt 0 ]]; then
    mode="blocked"; exit_code=30; next_kind="blocked"; next_cmd="install required dependencies from summary.required_missing"
  elif [[ "$(jq 'length' <<<"$full_missing")" -eq 0 ]]; then
    mode="full"; next_kind="continue"; next_cmd="docs/getting-started/first-run.md#full-mode"
    if [[ "$(jq 'length' <<<"$enhanced_missing")" -gt 0 ]]; then exit_code=10; else exit_code=0; fi
  else
    mode="reduced"; exit_code=20; next_kind="continue"; next_cmd="docs/getting-started/first-run.md#reduced-mode"
  fi

  fixture_flag=false
  [[ -n "$FIXTURE" ]] && fixture_flag=true
  host_os="$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]' || printf unknown)"
  host_arch="$(uname -m 2>/dev/null || printf unknown)"

  jq -nc \
    --arg sv "$SCHEMA_VERSION" --arg mode "$mode" --arg generated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg os "$host_os" --arg arch "$host_arch" --argjson fixture "$fixture_flag" \
    --argjson exit_code "$exit_code" --argjson deps "$deps_json" \
    --argjson required_missing "$required_missing" --argjson full_missing "$full_missing" \
    --argjson enhanced_missing "$enhanced_missing" --argjson misconfigured "$misconfigured" \
    --arg next_kind "$next_kind" --arg next_cmd "$next_cmd" \
    '{
      schema_version:$sv,
      command:"preflight",
      mode:$mode,
      exit_code:$exit_code,
      generated_at:$generated,
      host:{os:$os, arch:$arch, fixture:$fixture},
      summary:{
        required_missing:$required_missing,
        full_mode_missing:$full_missing,
        enhanced_missing:$enhanced_missing,
        misconfigured:$misconfigured,
        warnings:(if ($enhanced_missing|length)>0 then ["enhanced dependencies missing"] else [] end)
      },
      dependencies:($deps | map(select(.kind!="harness"))),
      harnesses:($deps | map(select(.kind=="harness"))),
      reduced_mode:{
        available:($mode=="reduced"),
        reason:(if $mode=="reduced" then "full-mode substrate missing but first-run simulator remains runnable" else "" end),
        unavailable_claims:(if $mode=="reduced" then ["multi-agent coordination","shared inboxes","cross-session memory"] else [] end)
      },
      next_action:{kind:$next_kind, command:$next_cmd}
    }'
  # --public mode: technical-reviewer-friendly. Map reduced-mode-available
  # (exit 20) → exit 0. Other exit codes unchanged. Preserves substrate
  # semantics for non-public consumers.
  if [[ "$PUBLIC_MODE" -eq 1 && "$exit_code" -eq 20 ]]; then
    exit_code=0
  fi
  return "$exit_code"
}

doctor_json() {
  local fixture_count invalid_count malformed_present
  fixture_count=0
  invalid_count=0
  malformed_present=false
  if [[ -d "$FIXTURE_DIR" ]]; then
    fixture_count="$(find "$FIXTURE_DIR" -maxdepth 1 -name '*.json' -type f | wc -l | tr -d ' ')"
    while IFS= read -r f; do
      if [[ "$(basename "$f")" == "malformed.json" ]]; then
        malformed_present=true
        continue
      fi
      validate_fixture "$f" >/dev/null 2>&1 || invalid_count=$((invalid_count + 1))
    done < <(find "$FIXTURE_DIR" -maxdepth 1 -name '*.json' -type f | sort)
  fi
  jq -nc --arg sv "$SCHEMA_VERSION" --argjson fixtures "$fixture_count" --argjson invalid "$invalid_count" --argjson malformed_present "$malformed_present" --arg jq_status "$(command -v jq >/dev/null 2>&1 && printf present || printf missing)" '{
    schema_version:$sv,
    command:"doctor",
    status:(if $invalid == 0 and $fixtures >= 6 and $malformed_present and $jq_status == "present" then "pass" else "fail" end),
    checks:[
      {name:"jq",status:$jq_status},
      {name:"fixture_dir",status:(if $fixtures >= 6 then "present" else "missing" end),fixture_count:$fixtures},
      {name:"valid_fixtures",status:(if $invalid == 0 then "pass" else "fail" end),invalid_count:$invalid},
      {name:"malformed_negative_fixture",status:(if $malformed_present then "present" else "missing" end)}
    ]
  }'
}

health_json() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{schema_version:$sv,command:"health",status:"ok",surfaces:["preflight","fixtures","schema","examples"]}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --public) PUBLIC_MODE=1; shift ;;
    --fixture) [[ $# -ge 2 ]] || die_usage "--fixture requires path"; FIXTURE="$2"; shift 2 ;;
    --fixture=*) FIXTURE="${1#*=}"; shift ;;
    --schema) MODE="schema"; shift ;;
    --examples) MODE="examples"; shift ;;
    --info) MODE="info"; shift ;;
    validate) MODE="validate"; shift ;;
    doctor) MODE="doctor"; shift ;;
    health) MODE="health"; shift ;;
    quickstart) MODE="quickstart"; shift ;;
    help)
      MODE="help"
      SUBJECT="${2:-}"
      shift
      if [[ $# -gt 0 ]]; then
        shift
      fi
      ;;
    -h|--help) MODE="usage"; shift ;;
    *) die_usage "unknown argument: $1" ;;
  esac
done

: "$JSON_OUT"

case "$MODE" in
  usage) usage; exit 0 ;;
  quickstart) quickstart; exit 0 ;;
  help)
    [[ "$SUBJECT" == "exit-codes" ]] || die_usage "unknown help topic: ${SUBJECT:-}"
    exit_codes_help; exit 0 ;;
esac

need_jq

if [[ -n "$FIXTURE" && "$FIXTURE" != /* ]]; then
  FIXTURE="$ROOT/$FIXTURE"
fi

case "$MODE" in
  schema) schema_json; exit 0 ;;
  examples) examples_json; exit 0 ;;
  info)
    jq -nc --arg sv "$SCHEMA_VERSION" '{schema_version:$sv,command:"info",name:"scripts/preflight.sh",mutates:false}'
    exit 0 ;;
  validate)
    [[ -n "$FIXTURE" ]] || die_usage "validate requires --fixture"
    validate_fixture "$FIXTURE" || exit 40
    jq -nc --arg sv "$SCHEMA_VERSION" --arg fixture "$(basename "$FIXTURE")" '{schema_version:$sv,command:"validate",status:"pass",fixture:$fixture}'
    exit 0 ;;
  doctor) doctor_json; exit 0 ;;
  health) health_json; exit 0 ;;
  run)
    if [[ -n "$FIXTURE" ]]; then
      validate_fixture "$FIXTURE" || exit 40
    fi
    result_envelope
    exit $? ;;
  *) die_usage "unsupported mode: $MODE" ;;
esac
