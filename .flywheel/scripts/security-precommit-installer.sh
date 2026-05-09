#!/usr/bin/env bash
set -euo pipefail

VERSION="security-precommit-installer.v1.0.0"

usage() {
  cat <<'EOF'
usage: security-precommit-installer.sh <command> [--repo PATH] [--json] [--dry-run|--apply]

Commands:
  install       Install the committed githooks/pre-commit dispatcher.
  scan-staged  Scan staged files for synthetic secret canaries.
  run-hook     Run scan-staged, then the preserved local hook if configured.
  doctor       Report install state.
  health       Lightweight install status.
  repair       Alias for install; requires --dry-run or --apply.
  validate     Validate repository hook configuration.
  audit        Show local hook-chain config.
  why          Explain the configured hook path.
  schema       Emit JSON schema summary for command output.
  quickstart   Emit copy-pasteable setup steps.
  examples     Emit usage examples.
  completion   Emit shell completions for bash or zsh.
  help         Show command help.

Mutating commands default to --dry-run. Use --apply to write config.

Exit codes:
  0  success or no staged secret findings
  1  staged secret findings or validation failure
  2  usage error
  4  mutation refused by mode gate
EOF
}

REPO=""
JSON_OUT=0
MODE="dry-run"
COMMAND=""
TOPIC=""

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

emit_json() {
  printf '%s\n' "$1"
}

repo_root() {
  if [[ -n "$REPO" ]]; then
    (cd "$REPO" && pwd -P)
  else
    git rev-parse --show-toplevel
  fi
}

git_get() {
  local repo="$1" key="$2"
  git -C "$repo" config --local --get "$key" 2>/dev/null || true
}

hook_path_for_hooks_path() {
  local repo="$1" hooks_path="$2"
  if [[ -z "$hooks_path" ]]; then
    printf '%s/.git/hooks/pre-commit\n' "$repo"
  elif [[ "$hooks_path" = /* ]]; then
    printf '%s/pre-commit\n' "$hooks_path"
  else
    printf '%s/%s/pre-commit\n' "$repo" "$hooks_path"
  fi
}

scan_staged() {
  local repo="$1"
  local corpus="$repo/.flywheel/security/v1/secret-patterns.json"
  if [[ ! -f "$corpus" ]]; then
    printf '{"schema_version":"security-precommit-scan/v1","status":"error","reason":"missing_corpus","findings":[]}\n'
    return 2
  fi

  python3 - "$repo" "$corpus" <<'PY'
from __future__ import annotations

import json
import re
import subprocess
import sys

repo, corpus_path = sys.argv[1:3]

with open(corpus_path, encoding="utf-8") as handle:
    corpus = json.load(handle)

patterns = []
for row in corpus.get("patterns", []):
    try:
        patterns.append((row["id"], row["class"], re.compile(row["regex"], re.MULTILINE | re.DOTALL)))
    except Exception:
        continue

diff = subprocess.run(
    ["git", "-C", repo, "diff", "--cached", "--name-only", "--diff-filter=ACMR"],
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
)
if diff.returncode != 0:
    print(json.dumps({
        "schema_version": "security-precommit-scan/v1",
        "status": "error",
        "reason": "git_diff_cached_failed",
        "findings": [],
    }, sort_keys=True))
    sys.exit(2)

paths = [line for line in diff.stdout.splitlines() if line]
findings = []
skipped = []

protected_generated = {"AGENTS.md", "templates/flywheel-install/AGENTS.md"}
generated_paths = sorted(protected_generated.intersection(paths))
has_canonical_source_change = any(
    path.startswith(".flywheel/rules/")
    or path == ".flywheel/scripts/agents-md-shard-extract.sh"
    or path == ".flywheel/scripts/sync-canonical-doctrine.sh"
    for path in paths
)
if generated_paths and not has_canonical_source_change:
    for path in generated_paths:
        findings.append({
            "path": path,
            "line": 1,
            "class": "generated_doctrine_direct_edit",
            "pattern": "generated-doctrine-mirror",
            "redaction": "[REDACTED:generated_doctrine_direct_edit]",
        })

for path in paths:
    blob = subprocess.run(
        ["git", "-C", repo, "show", f":{path}"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if blob.returncode != 0:
        skipped.append({"path": path, "reason": "staged_blob_unavailable"})
        continue
    data = blob.stdout
    if b"\x00" in data:
        skipped.append({"path": path, "reason": "binary_skipped"})
        continue
    text = data.decode("utf-8", errors="replace")
    for line_no, line in enumerate(text.splitlines(), start=1):
        for pattern_id, klass, regex in patterns:
            if regex.search(line):
                findings.append({
                    "path": path,
                    "line": line_no,
                    "class": klass,
                    "pattern": pattern_id,
                    "redaction": f"[REDACTED:{klass}]",
                })

payload = {
    "schema_version": "security-precommit-scan/v1",
    "status": "fail" if findings else "pass",
    "staged_paths": len(paths),
    "findings_count": len(findings),
    "findings": findings,
    "classes": sorted({item["class"] for item in findings}),
    "paths": sorted({item["path"] for item in findings}),
    "skipped": skipped,
    "emit_values": False,
    "corpus_path": ".flywheel/security/v1/secret-patterns.json",
}
print(json.dumps(payload, sort_keys=True))
sys.exit(1 if findings else 0)
PY
}

install_hook() {
  local repo="$1"
  local current_hooks_path current_hook backup_dir backup_path action_json
  current_hooks_path="$(git_get "$repo" core.hooksPath)"
  current_hook="$(hook_path_for_hooks_path "$repo" "$current_hooks_path")"
  backup_dir="$repo/.git/flywheel-security-hook-backups"
  backup_path=""

  if [[ "$MODE" != "apply" ]]; then
    jq -nc \
      --arg schema "security-precommit-install/v1" \
      --arg status "dry_run" \
      --arg current_hooks_path "$current_hooks_path" \
      --arg planned_hooks_path "githooks" \
      --arg current_hook "$current_hook" \
      '{schema_version:$schema,status:$status,dry_run:true,current_hooks_path:$current_hooks_path,planned_hooks_path:$planned_hooks_path,current_hook:$current_hook,would_set_hooks_path:true,would_backup_existing_hook:($current_hook != "" and ($current_hook | test("/githooks/pre-commit$") | not))}'
    return 0
  fi

  mkdir -p "$repo/githooks" "$backup_dir"
  chmod +x "$repo/githooks/pre-commit"

  if [[ -x "$current_hook" && "$current_hook" != "$repo/githooks/pre-commit" ]]; then
    backup_path="$backup_dir/pre-commit.$(date -u +%Y%m%dT%H%M%SZ)"
    cp "$current_hook" "$backup_path"
    chmod +x "$backup_path"
    git -C "$repo" config --local flywheel.securityPrecommitChain "$backup_path"
  fi

  git -C "$repo" config --local core.hooksPath githooks
  action_json="$(jq -nc \
    --arg schema "security-precommit-install/v1" \
    --arg status "applied" \
    --arg backup_path "$backup_path" \
    '{schema_version:$schema,status:$status,dry_run:false,hooks_path:"githooks",backup_path:(if $backup_path == "" then null else $backup_path end),chain_configured:($backup_path | length > 0)}')"
  emit_json "$action_json"
}

run_hook() {
  local repo="$1" scan_out scan_rc chain
  set +e
  scan_out="$(scan_staged "$repo")"
  scan_rc=$?
  set -e
  if [[ "$scan_rc" -ne 0 ]]; then
    printf '%s\n' "$scan_out" >&2
    return "$scan_rc"
  fi

  chain="$(git_get "$repo" flywheel.securityPrecommitChain)"
  if [[ -n "$chain" && -x "$chain" ]]; then
    "$chain"
  fi
  return 0
}

emit_static_json() {
  local command="$1" repo="$2"
  case "$command" in
    doctor|health|validate)
      local hooks_path hook_exists chain
      hooks_path="$(git_get "$repo" core.hooksPath)"
      chain="$(git_get "$repo" flywheel.securityPrecommitChain)"
      hook_exists=false
      [[ -x "$repo/githooks/pre-commit" ]] && hook_exists=true
      jq -nc --arg command "$command" --arg hooks_path "$hooks_path" --arg chain "$chain" --argjson hook_exists "$hook_exists" \
        '{schema_version:"security-precommit-state/v1",command:$command,status:(if $hooks_path == "githooks" and $hook_exists then "pass" else "fail" end),hooks_path:$hooks_path,committed_hook_executable:$hook_exists,chain_configured:($chain | length > 0)}'
      ;;
    audit|why)
      jq -nc --arg command "$command" --arg hooks_path "$(git_get "$repo" core.hooksPath)" --arg chain "$(git_get "$repo" flywheel.securityPrecommitChain)" \
        '{schema_version:"security-precommit-audit/v1",command:$command,hooks_path:$hooks_path,chain_path:$chain,why:"core.hooksPath points Git at the committed githooks dispatcher; chain_path preserves the prior hook when one existed."}'
      ;;
    schema|--schema)
      jq -nc '{schema_version:"security-precommit-cli-schema/v1",commands:["install","scan-staged","run-hook","doctor","health","repair","validate","audit","why"],mutating_commands:["install","repair"],default_mode:"dry-run",json_outputs:true,exit_codes:{success:0,findings_or_validation_failure:1,usage:2,blocked_by_gate:4}}'
      ;;
    quickstart)
      jq -nc '{schema_version:"security-precommit-quickstart/v1",steps:["bash .flywheel/scripts/security-precommit-installer.sh install --dry-run --json","bash .flywheel/scripts/security-precommit-installer.sh install --apply --json","git add <files>","git commit -m <message>"],limit:"synthetic canary corpus in v1"}'
      ;;
    examples|--examples)
      jq -nc '{schema_version:"security-precommit-examples/v1",examples:["security-precommit-installer.sh install --dry-run --json","security-precommit-installer.sh install --apply --json","security-precommit-installer.sh scan-staged --json","security-precommit-installer.sh doctor --json"]}'
      ;;
    completion)
      case "$TOPIC" in
        zsh) printf '#compdef security-precommit-installer.sh\ncompadd install scan-staged run-hook doctor health repair validate audit why schema quickstart examples completion help\n' ;;
        bash|"") printf 'complete -W "install scan-staged run-hook doctor health repair validate audit why schema quickstart examples completion help --repo --json --dry-run --apply" security-precommit-installer.sh\n' ;;
        *) printf 'unsupported shell: %s\n' "$TOPIC" >&2; return 2 ;;
      esac
      ;;
    *)
      usage
      ;;
  esac
}

if [[ "$#" -eq 0 ]]; then
  usage >&2
  exit 2
fi

COMMAND="$1"
shift

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="${2:?missing repo path}"
      shift 2
      ;;
    --json)
      JSON_OUT=1
      shift
      ;;
    --dry-run)
      MODE="dry-run"
      shift
      ;;
    --apply)
      MODE="apply"
      shift
      ;;
    --schema)
      COMMAND="schema"
      shift
      ;;
    --examples)
      COMMAND="examples"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ "$COMMAND" == "completion" || "$COMMAND" == "help" ]]; then
        TOPIC="$1"
        shift
      else
        printf 'ERR: unknown argument: %s\n' "$1" >&2
        usage >&2
        exit 2
      fi
      ;;
  esac
done

ROOT="$(repo_root)"

case "$COMMAND" in
  install)
    install_hook "$ROOT"
    ;;
  repair)
    install_hook "$ROOT"
    ;;
  scan-staged)
    scan_staged "$ROOT"
    ;;
  run-hook)
    run_hook "$ROOT"
    ;;
  doctor|health|validate|audit|why|schema|quickstart|examples|completion|help)
    emit_static_json "$COMMAND" "$ROOT"
    ;;
  --info)
    jq -nc --arg version "$VERSION" --arg repo "$ROOT" '{name:"security-precommit-installer",version:$version,repo:$repo,mutates_only_with:"install --apply",default_mode:"dry-run"}'
    ;;
  *)
    printf 'ERR: unknown command: %s\n' "$COMMAND" >&2
    usage >&2
    exit 2
    ;;
esac
