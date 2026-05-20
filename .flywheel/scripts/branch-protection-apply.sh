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
usage: branch-protection-apply.sh --repo OWNER/REPO --branch main (--dry-run|--apply) [--json]

Options:
  --repo OWNER/REPO          GitHub repository name.
  --branch NAME             Branch to protect (default: main).
  --dry-run                 Compute payload and diff without mutating GitHub.
  --apply                   Apply payload with gh api PUT. Use only after Joshua gate.
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
[[ -n "$MODE" ]] || die "choose exactly one of --dry-run or --apply"

discover_workflow_checks() {
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

fallback_recent_workflow_names() {
  local repo="$1"
  "$GH_BIN" api "repos/${repo}/actions/runs" --jq '.workflow_runs[0:5][].name' 2>/dev/null \
    | jq -Rsc 'split("\n") | map(select(length > 0)) | unique' 2>/dev/null || printf '[]\n'
}

checks_json="$(json_string_array "$CHECK_NAMES")"
if [[ "$(jq 'length' <<<"$checks_json")" -eq 0 ]]; then
  checks_json="$(discover_workflow_checks "$REPO_PATH")"
fi
if [[ "$(jq 'length' <<<"$checks_json")" -eq 0 ]]; then
  checks_json="$(fallback_recent_workflow_names "$REPO")"
fi

if [[ "$(jq 'length' <<<"$checks_json")" -eq 0 ]]; then
  checks_json='["ci"]'
fi

reviews_json="null"
if [[ -f "$OVERRIDES_FILE" ]]; then
  reviews_json="$(jq -c --arg repo "$REPO" '
    (.repos[$repo].required_pull_request_reviews // .default_substrate.required_pull_request_reviews // null)
  ' "$OVERRIDES_FILE")"
fi

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

outcome="dry-run"
error=""
if [[ "$MODE" == "apply" ]]; then
  tmp="$(mktemp "${TMPDIR:-/tmp}/branch-protection.XXXXXX.json")"
  printf '%s\n' "$payload" >"$tmp"
  if "$GH_BIN" api -X PUT "repos/${REPO}/branches/${BRANCH}/protection" --input "$tmp" >/dev/null; then
    outcome="applied"
  else
    outcome="error"
    error="gh_api_put_failed"
  fi
  rm -f "$tmp"
fi

envelope="$(jq -nc \
  --arg schema_version "$SCHEMA_VERSION" \
  --arg ts "$(now_iso)" \
  --arg repo "$REPO" \
  --arg branch "$BRANCH" \
  --arg outcome "$outcome" \
  --arg mode "$MODE" \
  --argjson required_checks "$checks_json" \
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
    required_checks:$required_checks,
    before:$before,
    desired:$desired,
    diff:$diff
  } + (if $error == "" then {} else {error:$error} end)')"

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$envelope"
else
  jq . <<<"$envelope"
fi

[[ "$outcome" != "error" ]]
