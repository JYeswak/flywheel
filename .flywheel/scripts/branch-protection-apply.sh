#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="branch_protection_apply.v1"
GH_BIN="${GH_BIN:-gh}"
REPO=""
BRANCH="main"
MODE=""
JSON_OUT=0
CHECK_NAMES=""
REPO_PATH="${PWD}"
OVERRIDES_FILE=".flywheel/state/branch-protection-overrides.json"

usage() {
  cat <<'EOF'
usage: branch-protection-apply.sh --repo OWNER/REPO --branch main (--dry-run|--apply|--verify-parity) [--json]

Options:
  --repo OWNER/REPO          GitHub repository name.
  --branch NAME             Branch to protect (default: main).
  --dry-run                 Compute payload and diff without mutating GitHub.
  --apply                   Apply payload with gh api PUT. Use only after Joshua gate.
  --verify-parity           Compare dry-run and apply pre-mutation required checks; no mutation.
  --json                    Emit one JSON envelope.
  --check-names A,B,C       Explicit required status-check contexts.
  --repo-path PATH          Local checkout used for workflow discovery.
  --overrides-file PATH     Override config JSON.
EOF
}

die() {
  printf 'branch-protection-apply: %s\n' "$1" >&2
  exit "${2:-2}"
}

json_string_array() {
  python3 - "$1" <<'PY'
import json, sys
items = [x.strip() for x in sys.argv[1].split(",") if x.strip()]
print(json.dumps(items))
PY
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) [[ $# -ge 2 ]] || die "--repo requires OWNER/REPO"; REPO="$2"; shift 2 ;;
    --repo=*) REPO="${1#*=}"; shift ;;
    --branch) [[ $# -ge 2 ]] || die "--branch requires NAME"; BRANCH="$2"; shift 2 ;;
    --branch=*) BRANCH="${1#*=}"; shift ;;
    --dry-run) MODE="dry-run"; shift ;;
    --apply) MODE="apply"; shift ;;
    --verify-parity) MODE="verify-parity"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --check-names) [[ $# -ge 2 ]] || die "--check-names requires CSV"; CHECK_NAMES="$2"; shift 2 ;;
    --check-names=*) CHECK_NAMES="${1#*=}"; shift ;;
    --repo-path) [[ $# -ge 2 ]] || die "--repo-path requires PATH"; REPO_PATH="$2"; shift 2 ;;
    --repo-path=*) REPO_PATH="${1#*=}"; shift ;;
    --overrides-file) [[ $# -ge 2 ]] || die "--overrides-file requires PATH"; OVERRIDES_FILE="$2"; shift 2 ;;
    --overrides-file=*) OVERRIDES_FILE="${1#*=}"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ "$REPO" =~ ^[^/]+/[^/]+$ ]] || die "--repo must be OWNER/REPO"
[[ -n "$MODE" ]] || die "choose exactly one of --dry-run, --apply, or --verify-parity"

discover_local_workflow_checks() {
  local repo_path="$1"
  python3 - "$repo_path" <<'PY'
from pathlib import Path
import json
import re
import sys

root = Path(sys.argv[1])
workflow_dir = root / ".github" / "workflows"
checks = []
if workflow_dir.is_dir():
    for path in sorted(list(workflow_dir.glob("*.yml")) + list(workflow_dir.glob("*.yaml"))):
        workflow_name = ""
        current_job = None
        in_jobs = False
        job_names = {}
        for raw in path.read_text(errors="replace").splitlines():
            line = raw.rstrip()
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            if re.match(r"^name:\s*", line):
                workflow_name = re.sub(r"^name:\s*", "", line).strip().strip("'\"")
                continue
            if line.startswith("jobs:"):
                in_jobs = True
                current_job = None
                continue
            if in_jobs:
                job = re.match(r"^  ([A-Za-z0-9_.-]+):\s*$", line)
                if job:
                    current_job = job.group(1)
                    job_names[current_job] = current_job
                    continue
                named = re.match(r"^    name:\s*(.+?)\s*$", line)
                if current_job and named:
                    job_names[current_job] = named.group(1).strip().strip("'\"")
        checks.extend(job_names.values() or ([workflow_name] if workflow_name else []))
seen = []
for check in checks:
    if check and check not in seen:
        seen.append(check)
print(json.dumps(seen))
PY
}

discover_remote_workflow_checks() {
  local repo="$1"
  local tmp paths path dest
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/branch-protection-workflows.XXXXXX")"
  paths="$("$GH_BIN" api "repos/${repo}/contents/.github/workflows" --jq '.[] | select(.type == "file" and (.name | test("\\.ya?ml$"))) | .path' 2>/dev/null || true)"
  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    dest="$tmp/$(basename "$path")"
    if "$GH_BIN" api "repos/${repo}/contents/${path}" --jq '.content' 2>/dev/null \
      | python3 -c 'import base64, sys; sys.stdout.write(base64.b64decode("".join(sys.stdin.read().split())).decode("utf-8", "replace"))' >"$dest"; then
      :
    else
      rm -f "$dest"
    fi
  done <<<"$paths"
  discover_local_workflow_checks "$tmp"
  rm -rf "$tmp"
}

discover_workflow_checks() {
  local repo_path="$1" repo="$2" checks
  checks="$(discover_local_workflow_checks "$repo_path")"
  if [[ "$(jq 'length' <<<"$checks")" -eq 0 ]]; then
    checks="$(discover_remote_workflow_checks "$repo")"
  fi
  printf '%s\n' "$checks"
}

recent_workflow_names() {
  local repo="$1"
  "$GH_BIN" api "repos/${repo}/actions/runs" --jq '.workflow_runs[0:20] | unique_by(.name) | .[].name' 2>/dev/null \
    | jq -Rsc 'split("\n") | map(select(length > 0)) | unique' 2>/dev/null || printf '[]\n'
}

override_checks_json() {
  local repo="$1" overrides_file="$2"
  if [[ -f "$overrides_file" ]]; then
    jq -c --arg repo "$repo" '
      (.repos[$repo].required_checks
        // .repos[$repo].required_status_checks.contexts
        // .repos[$repo].contexts
        // null)
      | if type == "array" then map(tostring) else null end
    ' "$overrides_file"
  else
    printf 'null\n'
  fi
}

resolve_checks() {
  local explicit_csv="$1" repo="$2" repo_path="$3" overrides_file="$4"
  local explicit_json override_json workflow_json recent_json
  explicit_json="$(json_string_array "$explicit_csv")"
  override_json="$(override_checks_json "$repo" "$overrides_file")"
  workflow_json="$(discover_workflow_checks "$repo_path" "$repo")"
  recent_json="$(recent_workflow_names "$repo")"

  jq -nc \
    --argjson explicit "$explicit_json" \
    --argjson override "$override_json" \
    --argjson workflow "$workflow_json" \
    --argjson recent "$recent_json" '
    def uniq_stable: reduce .[] as $x ([]; if index($x) then . else . + [$x] end);
    def intersection($a; $b): [$a[] as $x | select($b | index($x))] | uniq_stable;
    def union($a; $b): ($a + $b) | uniq_stable;

    (intersection($workflow; $recent)) as $intersect
    | if ($explicit | length) > 0 then {
        required_checks: ($explicit | uniq_stable),
        discovery_source: "override",
        discovery_decision: "explicit_check_names_flag",
        workflow_yml_checks: $workflow,
        recent_run_names: $recent,
        override_checks: $override
      }
      elif ($override != null and ($override | length) > 0) then {
        required_checks: ($override | uniq_stable),
        discovery_source: "override",
        discovery_decision: "repo_override_required_checks",
        workflow_yml_checks: $workflow,
        recent_run_names: $recent,
        override_checks: $override
      }
      elif ($intersect | length) > 0 then {
        required_checks: $intersect,
        discovery_source: "workflow_yml",
        discovery_decision: "workflow_yml_recent_runs_intersection",
        workflow_yml_checks: $workflow,
        recent_run_names: $recent,
        override_checks: $override
      }
      elif ($workflow | length) > 0 then {
        required_checks: ($workflow | uniq_stable),
        discovery_source: "workflow_yml",
        discovery_decision: (if ($recent | length) > 0 then "workflow_yml_preferred_recent_runs_no_exact_overlap" else "workflow_yml_only" end),
        workflow_yml_checks: $workflow,
        recent_run_names: $recent,
        override_checks: $override
      }
      elif ($recent | length) > 0 then {
        required_checks: ($recent | uniq_stable),
        discovery_source: "recent_runs",
        discovery_decision: "recent_runs_only",
        workflow_yml_checks: $workflow,
        recent_run_names: $recent,
        override_checks: $override
      }
      else {
        required_checks: ["ci"],
        discovery_source: "union",
        discovery_decision: "fallback_ci_no_workflows_or_recent_runs",
        workflow_yml_checks: $workflow,
        recent_run_names: $recent,
        override_checks: $override
      }
      end'
}

reviews_json="null"
if [[ -f "$OVERRIDES_FILE" ]]; then
  reviews_json="$(jq -c --arg repo "$REPO" '
    (.repos[$repo].required_pull_request_reviews // .default_substrate.required_pull_request_reviews // null)
  ' "$OVERRIDES_FILE")"
fi

build_envelope() {
  local requested_mode="$1" outcome="$2" error="$3"
  local discovery checks_json payload before before_norm after_norm diff_text
  discovery="$(resolve_checks "$CHECK_NAMES" "$REPO" "$REPO_PATH" "$OVERRIDES_FILE")"
  checks_json="$(jq -c '.required_checks' <<<"$discovery")"

  payload="$(jq -nc \
    --argjson contexts "$checks_json" \
    --argjson reviews "$reviews_json" \
    '{
      required_status_checks: {strict: true, contexts: $contexts},
      required_pull_request_reviews: $reviews,
      enforce_admins: false,
      restrictions: null,
      required_linear_history: true,
      allow_force_pushes: false,
      allow_deletions: false
    }')"

  if ! before="$("$GH_BIN" api "repos/${REPO}/branches/${BRANCH}/protection" 2>/dev/null)"; then
    before="{}"
  fi
  before_norm="$(jq -S . <<<"$before" 2>/dev/null || printf '{}\n')"
  after_norm="$(jq -S . <<<"$payload")"
  diff_text="$(diff -u <(printf '%s\n' "$before_norm") <(printf '%s\n' "$after_norm") || true)"

  jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ts "$(now_iso)" \
    --arg repo "$REPO" \
    --arg branch "$BRANCH" \
    --arg outcome "$outcome" \
    --arg mode "$requested_mode" \
    --argjson discovery "$discovery" \
    --argjson before "$before_norm" \
    --argjson desired "$payload" \
    --arg diff "$diff_text" \
    --arg error "$error" \
    '{
      schema_version:$schema_version,
      ts:$ts,
      repo:$repo,
      branch:$branch,
      outcome:$outcome,
      mode:$mode,
      required_checks:$discovery.required_checks,
      discovery_source:$discovery.discovery_source,
      discovery_decision:$discovery.discovery_decision,
      workflow_yml_checks:$discovery.workflow_yml_checks,
      recent_run_names:$discovery.recent_run_names,
      override_checks:$discovery.override_checks,
      before:$before,
      desired:$desired,
      diff:$diff
    } + (if $error == "" then {} else {error:$error} end)'
}

if [[ "$MODE" == "verify-parity" ]]; then
  dry_envelope="$(build_envelope "dry-run" "dry-run" "")"
  apply_plan_envelope="$(build_envelope "apply" "planned" "")"
  parity_diff="$(diff -u \
    <(jq -S '.required_checks' <<<"$dry_envelope") \
    <(jq -S '.required_checks' <<<"$apply_plan_envelope") || true)"
  parity_status="pass"
  [[ -z "$parity_diff" ]] || parity_status="fail"
  envelope="$(jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ts "$(now_iso)" \
    --arg repo "$REPO" \
    --arg branch "$BRANCH" \
    --arg parity_status "$parity_status" \
    --arg diff "$parity_diff" \
    --argjson dry_run "$dry_envelope" \
    --argjson apply_plan "$apply_plan_envelope" \
    '{
      schema_version:$schema_version,
      ts:$ts,
      repo:$repo,
      branch:$branch,
      mode:"verify-parity",
      outcome:$parity_status,
      required_checks:$dry_run.required_checks,
      discovery_source:$dry_run.discovery_source,
      dry_run_required_checks:$dry_run.required_checks,
      apply_required_checks:$apply_plan.required_checks,
      dry_run:$dry_run,
      apply_plan:$apply_plan,
      parity_diff:$diff
    }')"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$envelope"
  else
    jq . <<<"$envelope"
  fi
  [[ "$parity_status" == "pass" ]]
  exit $?
fi

outcome="dry-run"
error=""
envelope="$(build_envelope "$MODE" "$outcome" "$error")"
if [[ "$MODE" == "apply" ]]; then
  payload="$(jq -c '.desired' <<<"$envelope")"
  tmp="$(mktemp "${TMPDIR:-/tmp}/branch-protection.XXXXXX.json")"
  printf '%s\n' "$payload" >"$tmp"
  if "$GH_BIN" api -X PUT "repos/${REPO}/branches/${BRANCH}/protection" --input "$tmp" >/dev/null; then
    outcome="applied"
  else
    outcome="error"
    error="gh_api_put_failed"
  fi
  rm -f "$tmp"
  envelope="$(build_envelope "$MODE" "$outcome" "$error")"
fi

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$envelope"
else
  jq . <<<"$envelope"
fi

[[ "$outcome" != "error" ]]
