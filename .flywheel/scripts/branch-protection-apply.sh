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

discover_local_workflow_details() {
  local repo_path="$1" branch="$2"
  python3 - "$repo_path" "$branch" <<'PY'
from pathlib import Path
from itertools import product
import fnmatch
import json
import sys

root = Path(sys.argv[1])
branch = sys.argv[2]
workflow_dir = root / ".github" / "workflows"
details = []

try:
    import yaml
except Exception as exc:
    print(json.dumps({"checks": [], "details": [], "error": f"pyyaml_unavailable:{exc}"}))
    raise SystemExit(0)


def workflow_on(data):
    return data.get("on", data.get(True))


def event_config(on_value, event):
    if isinstance(on_value, str):
        return {} if on_value == event else None
    if isinstance(on_value, list):
        return {} if event in on_value else None
    if isinstance(on_value, dict):
        if event in on_value:
            return on_value[event] if on_value[event] is not None else {}
    return None


def branch_matches(patterns, value):
    if not patterns:
        return True
    if isinstance(patterns, str):
        patterns = [patterns]
    included = False
    has_positive = False
    for pattern in patterns:
        pattern = str(pattern)
        negated = pattern.startswith("!")
        raw = pattern[1:] if negated else pattern
        if not negated:
            has_positive = True
        if fnmatch.fnmatchcase(value, raw):
            included = not negated
    return included if has_positive else True


def pull_request_trigger_reason(on_value):
    cfg = event_config(on_value, "pull_request")
    if cfg is None:
        return False, "excluded:no_pull_request_trigger"
    if not isinstance(cfg, dict):
        cfg = {}
    if cfg.get("paths") or cfg.get("paths-ignore"):
        return False, "excluded:pull_request_path_filter_present"
    branches = cfg.get("branches")
    branches_ignore = cfg.get("branches-ignore")
    if branches is not None and not branch_matches(branches, branch):
        return False, f"excluded:pull_request_branches_filter_misses_{branch}"
    if branches_ignore is not None and branch_matches(branches_ignore, branch):
        return False, f"excluded:pull_request_branches_ignore_matches_{branch}"
    if branches is None and branches_ignore is None:
        return True, "included:pull_request_all_branches"
    return True, f"included:pull_request_matches_{branch}"


def matrix_rows(matrix):
    if not isinstance(matrix, dict):
        return []
    axes = []
    for key, value in matrix.items():
        if key in {"include", "exclude"}:
            continue
        values = value if isinstance(value, list) else [value]
        axes.append((str(key), [str(v) for v in values]))
    if not axes:
        return []
    rows = []
    for combo in product(*[axis_values for _, axis_values in axes]):
        row = dict(zip([axis_name for axis_name, _ in axes], combo))
        rows.append(row)
    for exclude in matrix.get("exclude") or []:
        if isinstance(exclude, dict):
            rows = [
                row for row in rows
                if not all(str(row.get(str(k))) == str(v) for k, v in exclude.items())
            ]
    for include in matrix.get("include") or []:
        if isinstance(include, dict):
            row = {str(k): str(v) for k, v in include.items()}
            if row and row not in rows:
                rows.append(row)
    return rows


def expand_job_name(name, rows):
    if not rows:
        return [(name, None)]
    expanded = []
    for row in rows:
        check = name
        had_matrix_expr = "${{ matrix." in check
        for key, value in row.items():
            check = check.replace("${{ matrix." + key + " }}", value)
        if not had_matrix_expr or "${{ matrix." in check:
            suffix = ", ".join(row.values())
            check = f"{check} ({suffix})"
        expanded.append((check, row))
    return expanded

if workflow_dir.is_dir():
    for path in sorted(list(workflow_dir.glob("*.yml")) + list(workflow_dir.glob("*.yaml"))):
        try:
            data = yaml.safe_load(path.read_text(errors="replace")) or {}
        except Exception as exc:
            details.append({
                "workflow": path.name,
                "check": None,
                "included": False,
                "trigger_reason": f"excluded:yaml_parse_error:{exc}",
                "matrix": None,
            })
            continue
        include, trigger_reason = pull_request_trigger_reason(workflow_on(data))
        workflow_name = str(data.get("name") or path.stem)
        jobs = data.get("jobs") or {}
        if not isinstance(jobs, dict):
            jobs = {}
        if not jobs:
            details.append({
                "workflow": path.name,
                "check": workflow_name if include else None,
                "included": include,
                "trigger_reason": trigger_reason,
                "matrix": None,
            })
            continue
        for job_id, job in jobs.items():
            job = job if isinstance(job, dict) else {}
            job_name = str(job.get("name") or job_id)
            rows = matrix_rows(((job.get("strategy") or {}).get("matrix") or {}))
            for check, row in expand_job_name(job_name, rows):
                details.append({
                    "workflow": path.name,
                    "job": str(job_id),
                    "check": check,
                    "included": include,
                    "trigger_reason": trigger_reason,
                    "matrix": row,
                })
seen = []
for check in [row["check"] for row in details if row.get("included") and row.get("check")]:
    if check and check not in seen:
        seen.append(check)
print(json.dumps({"checks": seen, "details": details}))
PY
}

discover_local_workflow_checks() {
  local repo_path="$1" branch="${2:-main}"
  discover_local_workflow_details "$repo_path" "$branch" | jq -c '.checks'
}

discover_remote_workflow_details() {
  local repo="$1" branch="$2"
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
  discover_local_workflow_details "$tmp" "$branch"
  rm -rf "$tmp"
}

discover_workflow_details() {
  local repo_path="$1" repo="$2" branch="$3" details
  details="$(discover_local_workflow_details "$repo_path" "$branch")"
  if [[ "$(jq '.checks | length' <<<"$details")" -eq 0 ]]; then
    details="$(discover_remote_workflow_details "$repo" "$branch")"
  fi
  printf '%s\n' "$details"
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
  local explicit_csv="$1" repo="$2" repo_path="$3" overrides_file="$4" branch="$5"
  local explicit_json override_json workflow_details workflow_json recent_json
  explicit_json="$(json_string_array "$explicit_csv")"
  override_json="$(override_checks_json "$repo" "$overrides_file")"
  workflow_details="$(discover_workflow_details "$repo_path" "$repo" "$branch")"
  workflow_json="$(jq -c '.checks' <<<"$workflow_details")"
  recent_json="$(recent_workflow_names "$repo")"

  jq -nc \
	    --argjson explicit "$explicit_json" \
	    --argjson override "$override_json" \
	    --argjson workflow "$workflow_json" \
	    --argjson workflow_details "$workflow_details" \
	    --argjson recent "$recent_json" '
    def uniq_stable: reduce .[] as $x ([]; if index($x) then . else . + [$x] end);
	    def union($a; $b): ($a + $b) | uniq_stable;
	
	    if ($explicit | length) > 0 then {
        required_checks: ($explicit | uniq_stable),
        discovery_source: "override",
        discovery_decision: "explicit_check_names_flag",
	        workflow_yml_checks: $workflow,
	        discovery_details: $workflow_details.details,
	        recent_run_names: $recent,
	        override_checks: $override
      }
      elif ($override != null and ($override | length) > 0) then {
        required_checks: ($override | uniq_stable),
        discovery_source: "override",
        discovery_decision: "repo_override_required_checks",
	        workflow_yml_checks: $workflow,
	        discovery_details: $workflow_details.details,
	        recent_run_names: $recent,
	        override_checks: $override
      }
	      elif ($workflow | length) > 0 then {
	        required_checks: ($workflow | uniq_stable),
	        discovery_source: "workflow_yml",
	        discovery_decision: (if ($recent | length) > 0 then "workflow_yml_pr_trigger_filtered_recent_runs_metadata_only" else "workflow_yml_pr_trigger_filtered" end),
	        workflow_yml_checks: $workflow,
	        discovery_details: $workflow_details.details,
	        recent_run_names: $recent,
	        override_checks: $override
      }
	      elif ($recent | length) > 0 then {
	        required_checks: ($recent | uniq_stable),
	        discovery_source: "recent_runs",
	        discovery_decision: "recent_runs_only",
	        workflow_yml_checks: $workflow,
	        discovery_details: [($recent | uniq_stable)[] | {workflow:null, job:null, check:., included:true, trigger_reason:"included:recent_runs_only", matrix:null}],
	        recent_run_names: $recent,
	        override_checks: $override
	      }
	      else {
	        required_checks: ["ci"],
	        discovery_source: "union",
	        discovery_decision: "fallback_ci_no_workflows_or_recent_runs",
	        workflow_yml_checks: $workflow,
	        discovery_details: [{workflow:null, job:null, check:"ci", included:true, trigger_reason:"included:fallback_ci_no_workflows_or_recent_runs", matrix:null}],
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
	  discovery="$(resolve_checks "$CHECK_NAMES" "$REPO" "$REPO_PATH" "$OVERRIDES_FILE" "$BRANCH")"
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
	      discovery_details:$discovery.discovery_details,
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
