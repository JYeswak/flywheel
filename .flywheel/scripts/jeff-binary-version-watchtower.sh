#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.10)
set -euo pipefail

VERSION="jeff-binary-version-watchtower.v3.1.0"
SCHEMA_VERSION="jeff-binary-version-watchtower.v3"
DEFAULT_STATE_DIR="$HOME/.local/state/flywheel"
LEDGER="${JEFF_BINARY_WATCHTOWER_LEDGER:-$DEFAULT_STATE_DIR/jeff-binary-version-watchtower.jsonl}"
IDEMPOTENCY_KEY=""

command="run"
json=0
apply=0
state_dir="${JEFF_BINARY_WATCHTOWER_STATE_DIR:-$DEFAULT_STATE_DIR}"
ntm_bin="${NTM_BIN:-ntm}"
br_bin="${BR_BIN:-br}"
frankenterm_fixture="${FRANKENTERM_RELEASE_FIXTURE:-}"
frankenterm_candidates="${FRANKENTERM_RELEASE_CANDIDATES:-frankenterm franken-term terminal}"

# ---------- canonical-cli emitters (added by flywheel-k8gcv.10) ----------

emit_info() {
  jq -nc --arg sv "$SCHEMA_VERSION" --arg version "$VERSION" --arg ledger "$LEDGER" \
    '{
      schema_version:$sv,
      command:"info",
      name:"jeff-binary-version-watchtower.sh",
      version:$version,
      ledger:$ledger,
      native:["ntm version --json","ntm upgrade --check","gh repo view"],
      mutates:["optional br beads with --apply --idempotency-key","ledger append with --apply --idempotency-key"],
      subcommands:["doctor","health","validate","audit","why","repair","quickstart","run"],
      canonical_flags:["--info","--schema","--examples","--json","--apply","--dry-run","--idempotency-key","--state-dir","--ntm-bin","--br-bin","--frankenterm-release-fixture","--codex-release-fixture"],
      capabilities:[
        "ntm-version-probe-via-native-cli",
        "ntm-upgrade-check-via-native-cli",
        "behind/current/ahead-relation-classification",
        "frankenterm-release-watch",
        "codex-release-canary-target-watch",
        "auto-file-substrate-drift-bead-on-behind",
        "idempotent-bead-dedupe-by-title",
        "ledger-append-on-apply"
      ],
      apply_supported:true,
      dry_run_supported:true,
      idempotency_key_required_for_apply:true,
      mutates_state:true,
      env_vars:["JEFF_BINARY_WATCHTOWER_STATE_DIR","JEFF_BINARY_WATCHTOWER_LEDGER","NTM_BIN","BR_BIN","FRANKENTERM_RELEASE_FIXTURE","FRANKENTERM_RELEASE_CANDIDATES","CODEX_RELEASE_FIXTURE","CODEX_REPO","CODEX_HOLD_VERSION","CODEX_TARGET_VERSION"],
      exit_codes:{"0":"pass","1":"behind-or-doctor-fail","2":"bad-args","3":"refused-apply-without-idempotency-key"}
    }'
}

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"schema",
    input_schema:{
      type:"object",
      properties:{
        json:{type:"boolean"},
        apply:{type:"boolean"},
        dry_run:{type:"boolean"},
        idempotency_key:{type:"string"},
        state_dir:{type:"string"},
        ntm_bin:{type:"string"},
        br_bin:{type:"string"},
        frankenterm_release_fixture:{type:"string"},
        codex_release_fixture:{type:"string"}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","checked_at","status","rows","watchlists"],
      properties:{
        schema_version:{type:"string"},
        checked_at:{type:"string",format:"date-time"},
        status:{enum:["pass","fail","warn"]},
        canonical_binary_count:{type:"integer"},
        release_watch_count:{type:"integer"},
        stale_count:{type:"integer"},
        rows:{type:"array"},
        watchlists:{type:"object"},
        promotions:{type:"array"}
      }
    },
    exit_codes:{"0":"pass","1":"behind-or-doctor-fail","2":"bad-args","3":"refused-apply-without-idempotency-key"}
  }'
}

emit_examples_text() {
  printf '%s\n' \
    ".flywheel/scripts/jeff-binary-version-watchtower.sh --dry-run --json" \
    ".flywheel/scripts/jeff-binary-version-watchtower.sh --apply --idempotency-key jbvw-2026-05-11 --json" \
    ".flywheel/scripts/jeff-binary-version-watchtower.sh doctor --json" \
    ".flywheel/scripts/jeff-binary-version-watchtower.sh audit --json"
}

emit_examples_json() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"examples",
    examples:[
      {name:"dry-run-probe",invocation:"jeff-binary-version-watchtower.sh --dry-run --json",purpose:"probe ntm + frankenterm + codex without writing ledger or filing beads"},
      {name:"apply-with-idem-key",invocation:"jeff-binary-version-watchtower.sh --apply --idempotency-key jbvw-2026-05-11 --json",purpose:"apply mode: write ledger + auto-file drift bead if behind"},
      {name:"doctor",invocation:"jeff-binary-version-watchtower.sh doctor --json",purpose:"canonical doctor envelope (jq + ntm + br + ledger writable)"},
      {name:"audit",invocation:"jeff-binary-version-watchtower.sh audit --json",purpose:"tail recent watchtower ledger rows"},
      {name:"fixture-driven-test",invocation:"FRANKENTERM_RELEASE_FIXTURE=/tmp/ft.json jeff-binary-version-watchtower.sh --dry-run --json",purpose:"override frankenterm probe with fixture (for tests)"}
    ]
  }'
}

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

emit_canonical_doctor() {
  local ts; ts="$(now_iso)"
  local jq_status="pass"; command -v jq >/dev/null 2>&1 || jq_status="fail"
  local ntm_status="pass"; [[ -n "$(command -v "$ntm_bin" 2>/dev/null || true)" ]] || ntm_status="warn"
  local br_status="pass"; [[ -n "$(command -v "$br_bin" 2>/dev/null || true)" ]] || br_status="warn"
  local gh_status="pass"; command -v gh >/dev/null 2>&1 || gh_status="warn"
  local ledger_dir; ledger_dir="$(dirname "$LEDGER")"
  local ledger_status="pass"
  if [[ -e "$LEDGER" ]]; then
    [[ -w "$LEDGER" ]] || ledger_status="fail"
  else
    [[ -d "$ledger_dir" ]] || ledger_status="warn"
  fi
  local overall="pass"
  for s in "$jq_status" "$ntm_status" "$br_status" "$gh_status" "$ledger_status"; do
    case "$s" in
      fail) overall="fail" ;;
      warn) [[ "$overall" == "pass" ]] && overall="warn" ;;
    esac
  done
  jq -nc --arg sv "$SCHEMA_VERSION.doctor" --arg ts "$ts" --arg overall "$overall" \
    --arg jq_s "$jq_status" --arg ntm_s "$ntm_status" --arg ntm_path "$(command -v "$ntm_bin" 2>/dev/null || printf '')" \
    --arg br_s "$br_status" --arg br_path "$(command -v "$br_bin" 2>/dev/null || printf '')" \
    --arg gh_s "$gh_status" \
    --arg ledger_s "$ledger_status" --arg ledger "$LEDGER" \
    '{
      schema_version:$sv,
      command:"doctor",
      ts:$ts,
      status:$overall,
      checks:[
        {name:"jq",status:$jq_s,detail:"jq required for envelope emission"},
        {name:"ntm_bin",status:$ntm_s,path:$ntm_path,detail:"ntm binary for `ntm version --json` + `ntm upgrade --check`"},
        {name:"br_bin",status:$br_s,path:$br_path,detail:"br binary for auto-filing drift bead in --apply mode"},
        {name:"gh_cli",status:$gh_s,detail:"gh CLI for frankenterm/codex release watch (warn if missing — fixtures still work)"},
        {name:"ledger_writable",status:$ledger_s,path:$ledger,detail:"append-only watchtower ledger"}
      ]
    }'
}

emit_health() {
  local ts; ts="$(now_iso)"
  local row_count=0
  local last_status=""
  if [[ -r "$LEDGER" ]]; then
    row_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$row_count" ]] && row_count=0
    if [[ "$row_count" -gt 0 ]]; then
      last_status="$(tail -n 1 "$LEDGER" 2>/dev/null | jq -r '.status // empty' 2>/dev/null || true)"
    fi
  fi
  local status="pass"
  [[ "$last_status" == "fail" ]] && status="warn"
  jq -nc --arg sv "$SCHEMA_VERSION.health" --arg ts "$ts" --arg status "$status" \
    --arg ledger "$LEDGER" --argjson row_count "${row_count:-0}" --arg last_status "${last_status:-}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,ledger:$ledger,ledger_row_count:$row_count,last_run_status:$last_status}'
}

emit_canonical_validate() {
  local ts; ts="$(now_iso)"
  local rows=0 invalid=0
  if [[ -r "$LEDGER" ]]; then
    rows="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$rows" ]] && rows=0
    if [[ "$rows" -gt 0 ]]; then
      invalid="$(jq -c 'select((.schema_version // "") == "" or (.status // "") == "")' "$LEDGER" 2>/dev/null | wc -l | tr -d ' ')"
      [[ -z "$invalid" ]] && invalid=0
    fi
  fi
  local status="pass"
  [[ "$invalid" -gt 0 ]] && status="violations"
  jq -nc --arg sv "$SCHEMA_VERSION.validate" --arg ts "$ts" --arg status "$status" \
    --argjson rows "${rows:-0}" --argjson invalid "${invalid:-0}" --arg ledger "$LEDGER" \
    '{schema_version:$sv,command:"validate",ts:$ts,status:$status,ledger:$ledger,row_count:$rows,invalid_row_count:$invalid,check:"every run row has non-empty schema_version + status"}'
}

emit_audit() {
  local limit="${1:-20}"
  local ts; ts="$(now_iso)"
  if [[ ! -r "$LEDGER" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION.audit" --arg ts "$ts" --arg ledger "$LEDGER" \
      '{schema_version:$sv,command:"audit",ts:$ts,status:"missing",ledger:$ledger,row_count:0,recent:[]}'
    return 0
  fi
  local row_count
  row_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
  [[ -z "$row_count" ]] && row_count=0
  local recent='[]'
  if [[ "$row_count" -gt 0 ]]; then
    recent="$(tail -n "$limit" "$LEDGER" 2>/dev/null | jq -cs '.' 2>/dev/null || printf '%s' '[]')"
    [[ -z "$recent" ]] && recent='[]'
  fi
  local status="pass"
  [[ "$row_count" -eq 0 ]] && status="empty"
  jq -nc --arg sv "$SCHEMA_VERSION.audit" --arg ts "$ts" --arg status "$status" \
    --arg ledger "$LEDGER" --argjson row_count "$row_count" --argjson recent "$recent" \
    '{schema_version:$sv,command:"audit",ts:$ts,status:$status,ledger:$ledger,row_count:$row_count,recent:$recent}'
}

emit_why() {
  local topic="${1:-}"
  local body=""
  case "$topic" in
    ""|substrate-drift)
      body='Jeff binaries (ntm, beads_rust/br, dcg, etc.) drift between fleet rollouts. The watchtower probes installed version vs upstream release (via gh CLI), classifies as current/behind/ahead, and (in --apply mode) auto-files a P1 drift bead with idempotent dedupe-by-title so the orchestrator can prioritize the upgrade.'
      ;;
    canary-pattern)
      body='Codex 0.129 canary on flywheel-x2okl proved unstable (background-terminal wedge class — 2 freezes in one session). Fleet rollout was halted; watchtower polls openai/codex for the next stable cut (0.130+) so the orchestrator can re-canary when the target lands.'
      ;;
    frankenterm-watch)
      body='Jeff frankenterm public release watch. Polls Dicklesworthstone/{frankenterm,franken-term,terminal} via gh repo view for first public release. Currently public_no_release (description filed, no release tag yet).'
      ;;
    *)
      body="unknown topic: $topic. known: substrate-drift, canary-pattern, frankenterm-watch"
      ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION" --arg topic "${topic:-substrate-drift}" --arg body "$body" \
    '{schema_version:$sv,command:"why",topic:$topic,body:$body}'
}

emit_quickstart() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"quickstart",
    status:"ok",
    steps:[
      {step:1,action:"check-doctor",command:"jeff-binary-version-watchtower.sh doctor --json"},
      {step:2,action:"dry-run-probe",command:"jeff-binary-version-watchtower.sh --dry-run --json"},
      {step:3,action:"apply-with-idem-key",command:"jeff-binary-version-watchtower.sh --apply --idempotency-key jbvw-$(date +%Y%m%d) --json"},
      {step:4,action:"tail-recent-runs",command:"jeff-binary-version-watchtower.sh audit --json"}
    ],
    next_actions:["wire-to-hourly-cron","escalate-on-behind-status-P1-bead"]
  }'
}

emit_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scope) scope="${2:-}"; shift 2 ;;
      --dry-run) mode="dry_run"; shift ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="${1#--idempotency-key=}"; shift ;;
      --json) shift ;;
      --help|-h) printf 'repair --scope <ledger-prime> [--dry-run|--apply --idempotency-key KEY]\n'; exit 0 ;;
      "") shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; exit 2 ;;
    esac
  done
  if [[ -z "$scope" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","reason":"--scope required (ledger-prime)","exit_code":2}\n' "$SCHEMA_VERSION"
    exit 2
  fi
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","mode":"apply","scope":"%s","reason":"--apply requires --idempotency-key","exit_code":3}\n' "$SCHEMA_VERSION" "$scope"
    exit 3
  fi
  local ts; ts="$(now_iso)"
  case "$scope" in
    ledger-prime)
      local ledger_dir present_before present_after
      ledger_dir="$(dirname "$LEDGER")"
      present_before="$([[ -f "$LEDGER" ]] && printf true || printf false)"
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$ledger_dir" 2>/dev/null || true
        [[ -f "$LEDGER" ]] || : > "$LEDGER"
      fi
      present_after="$([[ -f "$LEDGER" ]] && printf true || printf false)"
      jq -nc --arg sv "$SCHEMA_VERSION.repair" --arg ts "$ts" --arg scope "$scope" --arg mode "$mode" \
        --arg ledger "$LEDGER" --arg key "$idem_key" \
        --argjson before "$present_before" --argjson after "$present_after" \
        '{schema_version:$sv,command:"repair",ts:$ts,status:"pass",scope:$scope,mode:$mode,idempotency_key:$key,ledger:$ledger,ledger_present_before:$before,ledger_present_after:$after}'
      ;;
    *)
      printf '{"schema_version":"%s.repair","status":"refused","scope":"%s","reason":"unknown scope; known: ledger-prime","exit_code":2}\n' "$SCHEMA_VERSION" "$scope"
      exit 2
      ;;
  esac
}

# Canonical no-dash subcommand intercept BEFORE main arg parser.
case "${1:-}" in
  --schema) emit_schema; exit 0 ;;
  doctor)
    shift
    if [[ "${1:-}" == "--json" ]]; then
      emit_canonical_doctor; exit 0
    fi
    # Fall back to existing 'doctor' command path (full watchtower run with rc=1 on fail)
    set -- doctor "$@"
    ;;
  health)
    shift
    if [[ "${1:-}" == "--json" ]]; then
      emit_health; exit 0
    fi
    set -- health "$@"
    ;;
  validate) shift; emit_canonical_validate; exit 0 ;;
  audit)
    shift
    LIMIT=20
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --limit) LIMIT="${2:-20}"; shift 2 ;;
        --json) shift ;;
        "") shift ;;
        *) shift ;;
      esac
    done
    emit_audit "$LIMIT"
    exit 0
    ;;
  why)
    shift
    TOPIC=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --json) shift ;;
        "") shift ;;
        *) [[ -z "$TOPIC" ]] && TOPIC="$1"; shift ;;
      esac
    done
    emit_why "$TOPIC"
    exit 0
    ;;
  quickstart) shift; emit_quickstart; exit 0 ;;
  repair) shift; emit_repair "$@"; exit 0 ;;
esac
# flywheel-mspmr (AG5): extend watchtower to track openai/codex
# releases. The 0.129 canary on flywheel-x2okl proved unstable
# (background-terminal wedge class — 2 freezes in one session) and
# fleet rollout was halted. The watchtower now polls the codex repo
# for the next stable cut (0.130+) so the orchestrator can re-canary
# at that signal. Fixture path supports test isolation.
codex_fixture="${CODEX_RELEASE_FIXTURE:-}"
codex_repo="${CODEX_REPO:-openai/codex}"
codex_hold_version="${CODEX_HOLD_VERSION:-0.129}"
codex_target_version="${CODEX_TARGET_VERSION:-0.130}"

usage() { printf '%s\n' "Usage: jeff-binary-version-watchtower.sh [doctor|health|run] [--json] [--dry-run|--apply]" "       jeff-binary-version-watchtower.sh [--frankenterm-release-fixture PATH]" "       jeff-binary-version-watchtower.sh --info|--examples|completion"; }

normalize_version() { sed -E 's/\x1b\[[0-9;]*m//g; s/^[^0-9v]*v?//; s/[-+][A-Za-z0-9._-]+.*$//' <<<"${1:-}" | sed -E 's/[^0-9.].*$//' | awk 'NF{print; exit}'; }

version_key() { awk -F. '{printf "%06d%06d%06d\n", $1+0, $2+0, $3+0}' <<<"$(normalize_version "$1")"; }

relation() {
  local current latest c l
  current="$(normalize_version "$1")"
  latest="$(normalize_version "$2")"
  [[ -n "$current" && -n "$latest" ]] || { echo unknown; return; }
  c="$(version_key "$current")"
  l="$(version_key "$latest")"
  [[ "$c" < "$l" ]] && { echo behind; return; }
  [[ "$c" > "$l" ]] && { echo ahead; return; }
  echo current
}

ntm_version_json() { NO_COLOR=1 "$ntm_bin" version --json 2>&1 || true; }

ntm_upgrade_check() { NO_COLOR=1 "$ntm_bin" upgrade --check 2>&1 || true; }

installed_version() { local raw="$1"; jq -er '.version // empty' <<<"$raw" 2>/dev/null || normalize_version "$raw"; }

latest_version() {
  local raw="$1" found
  found="$(awk '/Latest version:/ {print $NF; found=1; exit} /New version available:/ {print $NF; found=1; exit} END{if(!found) exit 1}' <<<"$raw")" || return 1
  normalize_version "$found"
}

existing_bead() { local title="$1"; "$br_bin" list --json 2>/dev/null | jq -er --arg title "$title" '.[]? | select(.status != "closed" and .title == $title) | .id' 2>/dev/null | head -1 || true; }

promote() {
  local rel="$1" installed="$2" latest="$3"
  [[ "$rel" == "behind" ]] || { jq -nc '[]'; return; }
  local title existing desc
  title="[jeff-substrate-version-drift] ntm installed ${installed:-unknown} latest ${latest:-unknown}"
  existing="$(existing_bead "$title")"
  if [[ -n "$existing" ]]; then
    jq -nc --arg id "$existing" --arg title "$title" '[{action:"skipped",reason:"existing_bead",bead_id:$id,title:$title}]'
    return
  fi
  if [[ "$apply" != "1" ]]; then
    jq -nc --arg title "$title" '[{action:"planned",priority:"P1",title:$title}]'
    return
  fi
  desc="Auto-filed by jeff-binary-version-watchtower.sh via ntm version + ntm upgrade --check.\n\nTool: ntm\nInstalled: ${installed:-unknown}\nLatest: ${latest:-unknown}\nRelation: behind\nRecommended command: ntm upgrade --yes\n\nAcceptance gates:\n- Upgrade or intentionally pin this substrate version with a receipt.\n- Re-run .flywheel/scripts/jeff-binary-version-watchtower.sh --json and verify relation is no longer behind.\n- Record installed version evidence and any behavior-breaking follow-up bead."
  local out id
  out="$("$br_bin" create "$title" --type bug --priority P1 --description "$desc" --json 2>&1)" || {
    jq -nc --arg title "$title" --arg raw "$out" '[{action:"error",reason:"br_create_failed",priority:"P1",title:$title,raw:$raw}]'
    return
  }
  id="$(jq -er '.id // .issue.id // empty' <<<"$out" 2>/dev/null || true)"
  jq -nc --arg title "$title" --arg id "$id" '[{action:"created",priority:"P1",title:$title,bead_id:$id}]'
}

frankenterm_release_watch() {
  if [[ -n "$frankenterm_fixture" ]]; then
    jq -c . "$frankenterm_fixture"
    return 0
  fi

  local candidate raw
  for candidate in $frankenterm_candidates; do
    if command -v gh >/dev/null 2>&1 && raw="$(gh repo view "Dicklesworthstone/$candidate" --json name,url,isPrivate,latestRelease,pushedAt,description 2>/dev/null)"; then
      jq -nc --arg candidate "$candidate" --argjson raw "$raw" '
        {
          candidate:$candidate,
          repo:("Dicklesworthstone/" + ($raw.name // $candidate)),
          url:($raw.url // ("https://github.com/Dicklesworthstone/" + $candidate)),
          repo_public:(if $raw.isPrivate == true then false else true end),
          latest_release:($raw.latestRelease.tagName // null),
          pushed_at:($raw.pushedAt // null),
          description:($raw.description // null),
          status:(if ($raw.latestRelease.tagName // null) then "released" else "public_no_release" end)
        }'
    else
      jq -nc --arg candidate "$candidate" '{candidate:$candidate,repo:("Dicklesworthstone/" + $candidate),url:("https://github.com/Dicklesworthstone/" + $candidate),repo_public:false,latest_release:null,pushed_at:null,description:null,status:"not_found"}'
    fi
  done | jq -cs '.'
}

# flywheel-mspmr (AG5): codex release tracker. Polls openai/codex for
# the next stable cut so the orchestrator can re-canary 0.130 when it
# lands. Returns one row with status:
#   - hold_target_not_released: latest_release is the held version (0.129)
#     OR no release tag is reachable; canary remains suspended
#   - target_released: latest_release ≥ codex_target_version (0.130);
#     re-canary signal — operator should plan rollout
#   - newer_than_target: latest_release > target (e.g., 0.131);
#     same as target_released; the held version (0.129) is no longer
#     the latest cut
#   - unknown: gh unavailable or no fixture
codex_release_watch() {
  if [[ -n "$codex_fixture" ]]; then
    jq -c . "$codex_fixture"
    return 0
  fi
  local raw
  if command -v gh >/dev/null 2>&1 && raw="$(gh repo view "$codex_repo" --json name,url,isPrivate,latestRelease,pushedAt,description 2>/dev/null)"; then
    jq -nc \
      --arg repo "$codex_repo" \
      --arg hold "$codex_hold_version" \
      --arg target "$codex_target_version" \
      --argjson raw "$raw" '
      ($raw.latestRelease.tagName // null) as $tag |
      (if $tag then ($tag | gsub("^[^0-9v]*v?"; "") | gsub("[-+].*"; "")) else null end) as $tag_v |
      def vkey($v):
        if $v == null then null
        else ($v | split(".") | map(tonumber? // 0) + [0,0,0])[0:3] | reduce .[] as $n (0; . * 1000000 + $n)
        end;
      vkey($tag_v) as $tk |
      vkey($target) as $targetk |
      vkey($hold) as $holdk |
      {
        repo: $repo,
        url: ($raw.url // ("https://github.com/" + $repo)),
        repo_public: (if $raw.isPrivate == true then false else true end),
        latest_release: $tag,
        latest_release_normalized: $tag_v,
        pushed_at: ($raw.pushedAt // null),
        hold_version: $hold,
        target_version: $target,
        status: (
          if $tk == null then "unknown"
          elif $tk >= $targetk then
            (if $tk > $targetk then "newer_than_target" else "target_released" end)
          else "hold_target_not_released"
          end
        ),
        recanary_recommended: ($tk != null and $tk >= $targetk)
      }
    '
  else
    jq -nc \
      --arg repo "$codex_repo" \
      --arg hold "$codex_hold_version" \
      --arg target "$codex_target_version" \
      '{
        repo: $repo,
        url: ("https://github.com/" + $repo),
        repo_public: null,
        latest_release: null,
        latest_release_normalized: null,
        pushed_at: null,
        hold_version: $hold,
        target_version: $target,
        status: "unknown",
        recanary_recommended: false
      }'
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    doctor|health|run) command="$1" ;;
    --json) json=1 ;;
    --dry-run) ;;
    --apply) apply=1 ;;
    --state-dir) state_dir="$2"; shift ;;
    --repo-root|--fixture|--developer-root) shift ;;
    --frankenterm-release-fixture) frankenterm_fixture="$2"; shift ;;
    --codex-release-fixture) codex_fixture="$2"; shift ;;
    --br-bin) br_bin="$2"; shift ;;
    --ntm-bin) ntm_bin="$2"; shift ;;
    --now) shift ;;
    --no-fetch) ;;
    --help|-h|help) usage; exit 0 ;;
    --info) emit_info; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    --examples)
      shift
      if [[ "${1:-}" == "--json" ]]; then emit_examples_json; else emit_examples_text; fi
      exit 0
      ;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:-}"; shift ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#--idempotency-key=}" ;;
    completion) printf '%s\n' 'complete -W "doctor health run --json --dry-run --apply --fixture --info --examples completion --help" jeff-binary-version-watchtower.sh'; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

# Canonical apply contract: --apply requires --idempotency-key.
if [[ "$apply" == "1" && -z "$IDEMPOTENCY_KEY" ]]; then
  printf '{"schema_version":"%s","status":"refused","mode":"apply","reason":"--apply requires --idempotency-key","exit_code":3}\n' "$SCHEMA_VERSION"
  exit 3
fi

checked_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
version_raw="$(ntm_version_json)"
upgrade_raw="$(ntm_upgrade_check)"
installed="$(installed_version "$version_raw")"
latest="$(latest_version "$upgrade_raw" || true)"
rel="$(relation "$installed" "$latest")"
status="$([[ "$rel" == behind ]] && echo fail || { [[ "$rel" == unknown ]] && echo warn || echo pass; })"
promotions="$(promote "$rel" "$installed" "$latest")"
frankenterm_watch="$(frankenterm_release_watch)"
codex_watch="$(codex_release_watch)"

result="$(jq -nc --arg schema "$VERSION" --arg checked_at "$checked_at" --arg status "$status" --arg installed "$installed" --arg latest "$latest" --arg relation "$rel" --arg state_dir "$state_dir" --arg binary_path "$(command -v "$ntm_bin" 2>/dev/null || true)" --argjson promotions "$promotions" --argjson frankenterm_watch "$frankenterm_watch" --argjson codex_watch "$codex_watch" '{schema_version:$schema,checked_at:$checked_at,status:$status,cadence:"hourly",canonical_binary_count:1,release_watch_count:(($frankenterm_watch | length) + 1),stale_count:(if $relation == "behind" then 1 else 0 end),unknown_count:(if $relation == "unknown" then 1 else 0 end),highest_priority:(if $relation == "behind" then "P1" else null end),rows:[{name:"ntm",repo:"ntm",binary_path:$binary_path,installed_version:$installed,latest_version:$latest,latest_source:"ntm upgrade --check",relation:$relation,status:(if $relation == "behind" then "stale" elif $relation == "unknown" then "unknown" else "ok" end),recommended_command:(if $relation == "behind" then "ntm upgrade --yes" else null end),upgrade_mutation_invoked:false}],watchlists:{frankenterm_release:{cadence:"daily",candidates:($frankenterm_watch | map(.candidate)),public_count:($frankenterm_watch | map(select(.repo_public == true)) | length),release_count:($frankenterm_watch | map(select(.latest_release != null)) | length),status:(if ($frankenterm_watch | map(select(.latest_release != null)) | length) > 0 then "released" elif ($frankenterm_watch | map(select(.repo_public == true)) | length) > 0 then "public_no_release" else "not_found" end),rows:$frankenterm_watch},codex_release:{cadence:"daily",repo:$codex_watch.repo,hold_version:$codex_watch.hold_version,target_version:$codex_watch.target_version,latest_release:$codex_watch.latest_release,status:$codex_watch.status,recanary_recommended:$codex_watch.recanary_recommended,source_bead:"flywheel-mspmr",row:$codex_watch}},stale:(if $relation == "behind" then [{name:"ntm",repo:"ntm",installed_version:$installed,latest_version:$latest,relation:$relation,status:"stale"}] else [] end),promotions:$promotions,warnings:[],state_dir:$state_dir}')"

if [[ "$apply" == "1" ]]; then
  mkdir -p "$state_dir"
  ledger="$state_dir/jeff-binary-version-watchtower.jsonl"
  printf '%s\n' "$result" >>"$ledger"
  result="$(jq -c --arg ledger "$ledger" '. + {ledger:$ledger}' <<<"$result")"
fi

if [[ "$json" == "1" || "$command" =~ ^(doctor|health|run)$ ]]; then
  printf '%s\n' "$result"
else
  jq -r '"jeff-binary-version-watchtower status=\(.status) stale=\(.stale_count)"' <<<"$result"
fi

[[ "$status" == fail && "$command" =~ ^(doctor|health)$ ]] && exit 1
exit 0
