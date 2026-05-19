#!/usr/bin/env bash
# repo-discipline-check.sh
# Authority: .flywheel/doctrine/git-repo-discipline.md (joshua-direct-ask 2026-05-14T16:54Z)
#
# Read-only dirty-worktree classifier. It reports the cleanup class and the
# responsible next action; it never mutates the repo.

set -euo pipefail

VERSION="repo-discipline-check/v1"
SCHEMA_VERSION="$VERSION"
REPO=""
JSON_OUT=0
APPEND_SNAPSHOT=1
UPDATE_STATE_MD=""
T_UNTRACKED_JANITOR=5
T_TOTAL_JANITOR=10
T_UNTRACKED_HALT=20
T_TRACKED_HALT=100
T_TOTAL_HALT=100
SNAPSHOT_LOG="${REPO_DISCIPLINE_SNAPSHOT_LOG:-$HOME/.local/state/flywheel/repo-discipline-snapshots.jsonl}"

usage() {
  cat <<'USAGE'
usage:
  repo-discipline-check.sh [--repo PATH] [--json] [--no-append]
                           [--update-state-md PATH]
                           [--threshold-untracked-janitor N]
                           [--threshold-total-janitor N]
                           [--threshold-untracked-halt N]
                           [--threshold-tracked-halt N]
                           [--threshold-total-halt N]
  repo-discipline-check.sh --info|--help|--examples [--json]

Classifies dirty working-tree state and emits the responsible handling action.
Defaults to --repo "$PWD". Snapshots append to
~/.local/state/flywheel/repo-discipline-snapshots.jsonl unless --no-append.
Optional --update-state-md replaces a tagged block in STATE.md.

Exit codes: 0=clean|notable|janitor-triage, 1=halt, 2=usage, 3=not-a-git-repo.
USAGE
}

examples() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc '{examples:[
      "repo-discipline-check.sh --json",
      "repo-discipline-check.sh --repo /Users/josh/Developer/flywheel --json",
      "repo-discipline-check.sh --update-state-md .flywheel/STATE.md --json",
      "repo-discipline-check.sh --threshold-untracked-halt 10 --json"
    ]}'
  else
    cat <<'EX'
repo-discipline-check.sh --json
repo-discipline-check.sh --repo /Users/josh/Developer/flywheel --json
repo-discipline-check.sh --update-state-md .flywheel/STATE.md --json
repo-discipline-check.sh --threshold-untracked-halt 10 --json
EX
  fi
}

info() {
  jq -nc \
    --arg name "repo-discipline-check.sh" \
    --arg version "$VERSION" \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg log "$SNAPSHOT_LOG" \
    --argjson tuj "$T_UNTRACKED_JANITOR" \
    --argjson ttj "$T_TOTAL_JANITOR" \
    --argjson tuh "$T_UNTRACKED_HALT" \
    --argjson tth "$T_TRACKED_HALT" \
    --argjson ttoh "$T_TOTAL_HALT" \
    '{
      name:$name,
      version:$version,
      schema_version:$schema_version,
      mutates:false,
      doctrine:".flywheel/doctrine/git-repo-discipline.md",
      authority:"joshua-direct-ask 2026-05-14T16:54Z",
      thresholds:{
        untracked_janitor:$tuj,total_janitor:$ttj,
        untracked_halt:$tuh,tracked_halt:$tth,total_halt:$ttoh
      },
      classes:["clean","notable","janitor_triage_class","halt"],
      snapshot_log:$log,
      exit_codes:{"0":"clean|notable|janitor_triage_class","1":"halt","2":"usage","3":"not_a_git_repo"}
    }'
}

die_usage() { printf 'ERR: %s\n' "$1" >&2; usage >&2; exit 2; }

for a in "$@"; do
  [[ "$a" == "--json" ]] && JSON_OUT=1
done

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) [[ $# -ge 2 ]] || die_usage "--repo requires path"; REPO="$2"; shift 2 ;;
    --repo=*) REPO="${1#--repo=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --no-append) APPEND_SNAPSHOT=0; shift ;;
    --update-state-md) [[ $# -ge 2 ]] || die_usage "--update-state-md requires path"; UPDATE_STATE_MD="$2"; shift 2 ;;
    --update-state-md=*) UPDATE_STATE_MD="${1#--update-state-md=}"; shift ;;
    --threshold-untracked-janitor) T_UNTRACKED_JANITOR="${2:-5}"; shift 2 ;;
    --threshold-total-janitor) T_TOTAL_JANITOR="${2:-10}"; shift 2 ;;
    --threshold-untracked-halt) T_UNTRACKED_HALT="${2:-20}"; shift 2 ;;
    --threshold-tracked-halt) T_TRACKED_HALT="${2:-100}"; shift 2 ;;
    --threshold-total-halt) T_TOTAL_HALT="${2:-100}"; shift 2 ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    --) shift; break ;;
    *) die_usage "unknown argument: $1" ;;
  esac
done

REPO="${REPO:-$PWD}"
if [[ ! -d "$REPO" ]]; then
  die_usage "repo path not a directory: $REPO"
fi

STATUS_SHORT="$(
  cd "$REPO" 2>/dev/null || exit 3
  if ! command -v git >/dev/null 2>&1; then exit 3; fi
  if ! git rev-parse --git-dir >/dev/null 2>&1; then exit 3; fi
  git status --short 2>/dev/null
)"
probe_rc=$?
if [[ "$probe_rc" -ne 0 ]]; then
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg repo "$REPO" \
      '{schema_version:$sv,command:"check",status:"not_a_git_repo",repo:$repo}'
  else
    printf 'status=not_a_git_repo repo=%s\n' "$REPO" >&2
  fi
  exit 3
fi

tracked_count="$(printf '%s\n' "$STATUS_SHORT" | grep -cE '^(.[MADRCU]|[MADRCU].)' || true)"
untracked_count="$(printf '%s\n' "$STATUS_SHORT" | grep -cE '^\?\?' || true)"
total_count=$((tracked_count + untracked_count))
ahead_count="$(git -C "$REPO" rev-list --count '@{u}..HEAD' 2>/dev/null || printf '0')"
behind_count="$(git -C "$REPO" rev-list --count 'HEAD..@{u}' 2>/dev/null || printf '0')"
TS="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

if [[ "$untracked_count" -ge "$T_UNTRACKED_HALT" || "$tracked_count" -ge "$T_TRACKED_HALT" || "$total_count" -ge "$T_TOTAL_HALT" ]]; then
  klass="halt"
  action="halt_new_dispatch_until_repo_janitor_plan_or_cleanup_commit"
  rc=1
elif [[ "$untracked_count" -ge "$T_UNTRACKED_JANITOR" || "$total_count" -ge "$T_TOTAL_JANITOR" ]]; then
  klass="janitor_triage_class"
  action="route_git_repo_janitor_triage_only"
  rc=0
elif [[ "$total_count" -gt 0 ]]; then
  klass="notable"
  action="commit_restore_gitignore_or_file_bead_before_close"
  rc=0
else
  klass="clean"
  action="none"
  rc=0
fi

sample_json="$(
  printf '%s\n' "$STATUS_SHORT" | head -20 | jq -R . | jq -sc '.' 2>/dev/null || printf '[]'
)"
[[ -z "$sample_json" ]] && sample_json="[]"

ENVELOPE="$(jq -nc \
  --arg sv "$SCHEMA_VERSION" \
  --arg ts "$TS" \
  --arg repo "$REPO" \
  --arg klass "$klass" \
  --arg action "$action" \
  --argjson tracked "$tracked_count" \
  --argjson untracked "$untracked_count" \
  --argjson total "$total_count" \
  --argjson ahead "${ahead_count:-0}" \
  --argjson behind "${behind_count:-0}" \
  --argjson tuj "$T_UNTRACKED_JANITOR" \
  --argjson ttj "$T_TOTAL_JANITOR" \
  --argjson tuh "$T_UNTRACKED_HALT" \
  --argjson tth "$T_TRACKED_HALT" \
  --argjson ttoh "$T_TOTAL_HALT" \
  --argjson sample "$sample_json" \
  '{
    schema_version:$sv,
    command:"check",
    ts:$ts,
    repo:$repo,
    tracked_dirty_count:$tracked,
    untracked_count:$untracked,
    dirty_total:$total,
    commits_ahead:$ahead,
    commits_behind:$behind,
    class:$klass,
    halt:($klass == "halt"),
    janitor_triage_required:($klass == "janitor_triage_class" or $klass == "halt"),
    action:$action,
    thresholds:{
      untracked_janitor:$tuj,total_janitor:$ttj,
      untracked_halt:$tuh,tracked_halt:$tth,total_halt:$ttoh
    },
    sample_first_20:$sample,
    doctrine:".flywheel/doctrine/git-repo-discipline.md",
    handler:"/git-repo-janitor"
  }')"

if [[ "$APPEND_SNAPSHOT" -eq 1 ]]; then
  mkdir -p "$(dirname "$SNAPSHOT_LOG")" 2>/dev/null || true
  printf '%s\n' "$ENVELOPE" >>"$SNAPSHOT_LOG" 2>/dev/null || true
fi

if [[ -n "$UPDATE_STATE_MD" && -f "$UPDATE_STATE_MD" && -w "$UPDATE_STATE_MD" ]]; then
  BLOCK_BODY="$(jq -nc \
    --arg ts "$TS" \
    --argjson tracked "$tracked_count" \
    --argjson untracked "$untracked_count" \
    --argjson total "$total_count" \
    --arg klass "$klass" \
    --arg action "$action" \
    --arg log "$SNAPSHOT_LOG" \
    '"\n## Repo Hygiene Snapshot\n\n<!-- repo-hygiene-snapshot:begin -->\n- ts: \($ts)\n- tracked_dirty_count: \($tracked)\n- untracked_count: \($untracked)\n- dirty_total: \($total)\n- class: \($klass)\n- action: \($action)\n- doctrine: .flywheel/doctrine/git-repo-discipline.md\n- handler: /git-repo-janitor\n- snapshot_log: \($log)\n<!-- repo-hygiene-snapshot:end -->\n"' | jq -r .)"
  python3 - "$UPDATE_STATE_MD" "$BLOCK_BODY" <<'PY' || true
import re, sys, pathlib
path = pathlib.Path(sys.argv[1])
new_block = sys.argv[2]
if not new_block.endswith("\n"):
    new_block += "\n"
text = path.read_text(encoding="utf-8")
pattern = re.compile(r"\n## Repo Hygiene Snapshot\n\n<!-- repo-hygiene-snapshot:begin -->.*?<!-- repo-hygiene-snapshot:end -->\n?", re.DOTALL)
if pattern.search(text):
    out = pattern.sub(new_block, text)
else:
    out = text.rstrip() + "\n" + new_block
path.write_text(out, encoding="utf-8")
PY
fi

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$ENVELOPE"
else
  printf 'tracked_dirty=%d untracked=%d dirty_total=%d class=%s action=%s repo=%s\n' \
    "$tracked_count" "$untracked_count" "$total_count" "$klass" "$action" "$REPO"
  if [[ "$rc" -eq 1 ]]; then
    printf 'BLOCKED: dirty repo crossed halt threshold; run /git-repo-janitor triage or land cleanup commit\n' >&2
  elif [[ "$klass" == "janitor_triage_class" ]]; then
    printf 'WARN: dirty repo crossed janitor threshold; route /git-repo-janitor triage-only\n' >&2
  elif [[ "$klass" == "notable" ]]; then
    printf 'NOTE: dirty repo requires commit, restore, gitignore, or bead before close\n' >&2
  fi
fi

exit "$rc"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
