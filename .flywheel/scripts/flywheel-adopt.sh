#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
FLYWHEEL_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
SCHEMA_VERSION="flywheel-adopt/v1"

repo_arg="$PWD"
json=0
apply=0
dry_run=1
reconcile=0
first_run_audit=0
start_loop=0
idempotency_key=""
apply_fs_rag=0

usage() {
  cat <<'USAGE'
flywheel-adopt.sh [--repo <path>] [--json] [--dry-run] [--apply]
                  [--reconcile] [--first-run-audit] [--start-loop]
                  [--apply-fs-rag] [--idempotency-key <key>]

Dry-run is the default. Durable writes require --apply.

--apply-fs-rag: Install/update the fs-rag-discipline substrate (linter,
                scaffolder, pre-commit hook, doctrine, test) from
                templates/flywheel-install/. Runs baseline scan; idempotent
                via .flywheel/audit/fs-rag-backfill-applied.json receipt.
                Requires --apply.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      repo_arg="${2:?--repo requires a path}"
      shift 2
      ;;
    --json)
      json=1
      shift
      ;;
    --dry-run)
      dry_run=1
      apply=0
      shift
      ;;
    --apply)
      apply=1
      dry_run=0
      shift
      ;;
    --reconcile)
      reconcile=1
      shift
      ;;
    --first-run-audit)
      first_run_audit=1
      shift
      ;;
    --start-loop)
      start_loop=1
      shift
      ;;
    --idempotency-key)
      idempotency_key="${2:?--idempotency-key requires a value}"
      shift 2
      ;;
    --apply-fs-rag)
      apply_fs_rag=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      if [ "$repo_arg" = "$PWD" ] && [ -d "$1" ]; then
        repo_arg="$1"
        shift
      else
        echo "unknown argument: $1" >&2
        usage >&2
        exit 2
      fi
      ;;
  esac
done

if [ "$apply" -eq 1 ] && [ -z "$idempotency_key" ]; then
  echo "adopt_apply_requires_idempotency_key" >&2
  exit 2
fi

if [ ! -d "$repo_arg" ]; then
  echo "repo_not_found: $repo_arg" >&2
  exit 2
fi

repo="$(cd "$repo_arg" && pwd -P)"
if ! git -C "$repo" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "not_a_git_repo: $repo" >&2
  exit 2
fi

ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
session="${NTM_SESSION:-${FLYWHEEL_SESSION:-unknown}}"

ready=()
missing=()
drifted=()
fixed=()
registered=()

check_path() {
  local label="$1"
  local path="$2"
  if [ -e "$path" ]; then
    ready+=("$label")
  else
    missing+=("$label")
  fi
}

check_path ".flywheel/" "$repo/.flywheel"
check_path ".flywheel/MISSION.md" "$repo/.flywheel/MISSION.md"
check_path ".flywheel/GOAL.md" "$repo/.flywheel/GOAL.md"
check_path ".flywheel/STATE.md" "$repo/.flywheel/STATE.md"
check_path ".flywheel/AGENTS-CANONICAL.md" "$repo/.flywheel/AGENTS-CANONICAL.md"
check_path "INCIDENTS.md" "$repo/INCIDENTS.md"
check_path ".beads/beads.db" "$repo/.beads/beads.db"
check_path ".git/hooks/pre-commit" "$repo/.git/hooks/pre-commit"

registry="${FLYWHEEL_SUBSTRATE_REGISTRY:-$HOME/.local/state/flywheel/substrate-registry.jsonl}"
if [ -f "$registry" ] && grep -F "\"repo_path\":\"$repo\"" "$registry" >/dev/null 2>&1; then
  ready+=("substrate-registry")
else
  missing+=("substrate-registry")
fi

if command -v jsm >/dev/null 2>&1; then
  ready+=("skill catalog")
else
  drifted+=("skill catalog: jsm unavailable")
fi

wedge_count=0
if [ -d "$repo/.beads" ]; then
  wedge_count="$(find "$repo/.beads" -name '*.wedged' -type f 2>/dev/null | wc -l | tr -d ' ')"
fi
repair_needed=false
if [ "${wedge_count:-0}" -gt 0 ]; then
  repair_needed=true
  drifted+=("beads DB health: wedge marker count=$wedge_count")
fi

loop_command=""
if [ "$start_loop" -eq 1 ]; then
  if [ "$apply" -eq 1 ]; then
    loop_command="/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop start --repo \"$repo\" --apply --json"
  else
    loop_command="/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop start --repo \"$repo\" --dry-run --json"
  fi
fi

audit_command=""
if [ "$first_run_audit" -eq 1 ]; then
  audit_command="dispatch UBS sweep and codebase-audit for \"$repo\""
fi

if [ "$apply" -eq 1 ]; then
  mkdir -p "$repo/.flywheel"
  fixed+=(".flywheel/")

  for doc in MISSION GOAL STATE; do
    target="$repo/.flywheel/$doc.md"
    if [ ! -f "$target" ]; then
      printf '# %s\n\nstatus: adopted\nrepo: %s\n' "$doc" "$repo" > "$target"
      fixed+=(".flywheel/$doc.md")
    fi
  done

  canonical_source="$FLYWHEEL_ROOT/AGENTS.md"
  canonical_target="$repo/.flywheel/AGENTS-CANONICAL.md"
  if [ -f "$canonical_source" ]; then
    {
      echo "---"
      echo "canonical_source: $canonical_source"
      echo "canonical_synced_at: $ts"
      echo "---"
      cat "$canonical_source"
    } > "$canonical_target"
    fixed+=(".flywheel/AGENTS-CANONICAL.md")
  fi

  if [ ! -f "$repo/INCIDENTS.md" ]; then
    cat > "$repo/INCIDENTS.md" <<'INCIDENTS'
# INCIDENTS

Repo-local incident doctrine.

Entries promote from real evidence per L56:
- trauma_class
- evidence linkage
- recurrence threshold or cost citation
- prevention rule

Do not seed incidents without observed evidence.
INCIDENTS
    fixed+=("INCIDENTS.md")
  fi

  mkdir -p "$(dirname "$registry")"
  printf '{"ts":"%s","kind":"managed_repo","lifecycle_state":"adopted_phase0","repo_path":"%s","registered_by":"flywheel:adopt"}\n' "$ts" "$repo" >> "$registry"
  registered+=("substrate-registry")

  if [ "$repair_needed" = true ]; then
    if [ -x "$repo/scripts/bead_db_repair.sh" ]; then
      "$repo/scripts/bead_db_repair.sh" --apply >/dev/null
      fixed+=("beads DB repair")
    else
      drifted+=("beads DB health: repair script missing")
    fi
  fi

  receipt="$repo/.flywheel/install-log.jsonl"
  python3 - "$receipt" "$ts" "$repo" "$session" "$first_run_audit" "$loop_command" <<'PY'
import json, sys
receipt, ts, repo, session, audited, loop_command = sys.argv[1:]
row = {
    "ts": ts,
    "action": "adopt",
    "findings": ["legacy_repo_adoption"],
    "fixed": [],
    "registered": ["substrate-registry"],
    "audited": audited == "1",
    "orchestrator_session": session,
    "next_operator_action": "run /flywheel:loop start when ready",
}
if loop_command:
    row["planned_loop_start"] = loop_command
with open(receipt, "a", encoding="utf-8") as f:
    f.write(json.dumps(row, sort_keys=True) + "\n")
PY
  fixed+=(".flywheel/install-log.jsonl")
fi

fs_rag_action="not_requested"
fs_rag_baseline_path=""
fs_rag_violations_total=0
if [ "$apply_fs_rag" -eq 1 ]; then
  fs_rag_action="dry_run"
  fs_rag_template_dir="$FLYWHEEL_ROOT/templates/flywheel-install"
  fs_rag_files=(
    "scripts/file-rag-discipline-lint.sh"
    "scripts/scaffold-doc-frontmatter.sh"
    "hooks/file-rag-discipline-pre-commit.sh"
    "doctrine/filesystem-as-rag.md"
    "tests/file-rag-discipline-lint.sh"
  )
  fs_rag_targets=(
    ".flywheel/scripts/file-rag-discipline-lint.sh"
    ".flywheel/scripts/scaffold-doc-frontmatter.sh"
    ".flywheel/hooks/file-rag-discipline-pre-commit.sh"
    ".flywheel/doctrine/filesystem-as-rag.md"
    "tests/file-rag-discipline-lint.sh"
  )
  fs_rag_planned=()
  fs_rag_applied=()
  fs_rag_skipped=()

  for i in "${!fs_rag_files[@]}"; do
    src="$fs_rag_template_dir/${fs_rag_files[$i]}"
    dst="$repo/${fs_rag_targets[$i]}"
    if [ ! -r "$src" ]; then
      fs_rag_skipped+=("template_missing:$src")
      continue
    fi
    if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
      fs_rag_skipped+=("in_sync:${fs_rag_targets[$i]}")
    else
      fs_rag_planned+=("${fs_rag_targets[$i]}")
      if [ "$apply" -eq 1 ]; then
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        if [[ "$src" == *.sh ]]; then chmod +x "$dst"; fi
        fs_rag_applied+=("${fs_rag_targets[$i]}")
      fi
    fi
  done

  pre_commit_target="$repo/.git/hooks/pre-commit"
  pre_commit_marker="# fs-rag-discipline-pre-commit BEGIN"
  pre_commit_block=$(cat <<'BLOCK'
# fs-rag-discipline-pre-commit BEGIN
if [ -x "$(git rev-parse --show-toplevel)/.flywheel/hooks/file-rag-discipline-pre-commit.sh" ]; then
  "$(git rev-parse --show-toplevel)/.flywheel/hooks/file-rag-discipline-pre-commit.sh" || exit $?
fi
# fs-rag-discipline-pre-commit END
BLOCK
)
  if [ "$apply" -eq 1 ]; then
    if [ ! -f "$pre_commit_target" ]; then
      mkdir -p "$(dirname "$pre_commit_target")"
      printf '#!/usr/bin/env bash\nset -e\n%s\n' "$pre_commit_block" > "$pre_commit_target"
      chmod +x "$pre_commit_target"
      fs_rag_applied+=(".git/hooks/pre-commit:created")
    elif ! grep -q "$pre_commit_marker" "$pre_commit_target"; then
      printf '\n%s\n' "$pre_commit_block" >> "$pre_commit_target"
      fs_rag_applied+=(".git/hooks/pre-commit:appended")
    else
      fs_rag_skipped+=(".git/hooks/pre-commit:already_chained")
    fi
  fi

  baseline_dir="$repo/.flywheel/audit"
  baseline_date="$(date -u +%Y-%m-%d)"
  fs_rag_baseline_path="$baseline_dir/fs-rag-baseline-$baseline_date.json"
  backfill_receipt="$baseline_dir/fs-rag-backfill-applied.json"
  linter="$repo/.flywheel/scripts/file-rag-discipline-lint.sh"
  if [ "$apply" -eq 1 ]; then
    mkdir -p "$baseline_dir"
    if [ -x "$linter" ]; then
      "$linter" --scan-all --root "$repo" --json >"$fs_rag_baseline_path" 2>/dev/null || true
      if [ -s "$fs_rag_baseline_path" ]; then
        fs_rag_violations_total="$(jq -r '.violations_total // (.violations | length) // 0' "$fs_rag_baseline_path" 2>/dev/null || echo 0)"
        fs_rag_applied+=(".flywheel/audit/fs-rag-baseline-$baseline_date.json")
      fi
    else
      fs_rag_skipped+=("baseline:linter_not_executable")
    fi
    if [ ! -f "$backfill_receipt" ]; then
      jq -nc --arg ts "$ts" --arg key "$idempotency_key" --arg baseline "$fs_rag_baseline_path" \
        '{ts:$ts,idempotency_key:$key,baseline_path:$baseline,backfill_status:"baseline_only_no_content_backfill_in_v1"}' \
        > "$backfill_receipt"
      fs_rag_applied+=(".flywheel/audit/fs-rag-backfill-applied.json")
    else
      fs_rag_skipped+=(".flywheel/audit/fs-rag-backfill-applied.json:already_present")
    fi
    fs_rag_action="applied"
  fi
fi

status="dry_run"
[ "$apply" -eq 1 ] && status="applied"

if [ "$json" -eq 1 ]; then
  set +u
  python3 - "$SCHEMA_VERSION" "$status" "$repo" "$session" "$dry_run" "$apply" "$reconcile" "$first_run_audit" "$start_loop" "$repair_needed" "$loop_command" "$audit_command" "$apply_fs_rag" "$fs_rag_action" "$fs_rag_baseline_path" "$fs_rag_violations_total" "${ready[@]}" -- "${missing[@]}" -- "${drifted[@]}" -- "${fixed[@]}" -- "${registered[@]}" <<'PY'
import json, sys
args = sys.argv[1:]
schema, status, repo, session = args[:4]
dry_run, apply, reconcile, first_run_audit, start_loop = [x == "1" for x in args[4:9]]
repair_needed = args[9] == "true"
loop_command, audit_command = args[10:12]
apply_fs_rag = args[12] == "1"
fs_rag_action = args[13]
fs_rag_baseline_path = args[14]
try:
    fs_rag_violations_total = int(args[15] or "0")
except ValueError:
    fs_rag_violations_total = 0
rest = args[16:]
groups = [[]]
for item in rest:
    if item == "--":
        groups.append([])
    else:
        groups[-1].append(item)
while len(groups) < 5:
    groups.append([])
ready, missing, drifted, fixed, registered = groups[:5]
out = {
    "schema_version": schema,
    "command": "flywheel:adopt",
    "status": status,
    "repo": repo,
    "dry_run": dry_run,
    "apply": apply,
    "reconcile": reconcile,
    "first_run_audit": first_run_audit,
    "start_loop": start_loop,
    "counts": {
        "ready": len(ready),
        "missing": len(missing),
        "drifted": len(drifted),
    },
    "ready": ready,
    "missing": missing,
    "drifted": drifted,
    "beads_db_health": {
        "repair_needed": repair_needed,
        "repair_path_invoked": repair_needed and apply and "beads DB repair" in fixed,
    },
    "substrate_registry": {
        "kind": "managed_repo",
        "lifecycle_state": "adopted_phase0",
    },
    "skill_catalog": {
        "scan": "jsm scan",
        "auto_install": False,
    },
    "fixed": fixed,
    "registered": registered,
    "audited": first_run_audit and apply,
    "orchestrator_session": session,
    "planned_first_run_audit": audit_command,
    "planned_loop_start": loop_command,
    "fs_rag_discipline": {
        "requested": apply_fs_rag,
        "action": fs_rag_action,
        "baseline_path": fs_rag_baseline_path or None,
        "violations_total": fs_rag_violations_total,
    },
    "next_operator_action": "review delta report; rerun with --apply --idempotency-key <key> to mutate" if dry_run else "run /flywheel:loop start when ready",
}
print(json.dumps(out, indent=2, sort_keys=True))
PY
  set -u
else
  printf 'flywheel:adopt %s repo=%s ready=%s missing=%s drifted=%s\n' "$status" "$repo" "${#ready[@]}" "${#missing[@]}" "${#drifted[@]}"
  if [ "$dry_run" -eq 1 ]; then
    printf 'No files changed. Rerun with --apply --idempotency-key <key> for mutation.\n'
  fi
fi
