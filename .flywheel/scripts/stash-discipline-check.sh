#!/usr/bin/env bash
# stash-discipline-check.sh
# Authority: .flywheel/doctrine/git-stash-discipline.md (joshua-direct-ask 2026-05-10T19:25Z)
#
# Single-purpose gate that probes `git stash list | wc -l` for a repo and
# emits a threshold class:
#   N==0           clean        (no signal)
#   1<=N<=4        notable      (signal in tick output, no block)
#   5<=N<=9        bead-class   (file flywheel-stash-cleanup bead, no block)
#   N>=10          halt         (refuse close, halt current lane)
#
# Used as:
#   - L120 worker close gate extension (via mission-fitness-callback-validator)
#   - flywheel-loop doctor stash subsurface
#   - cron / per-tick orch probe
#
# Snapshot rows append to ~/.local/state/flywheel/stash-discipline-snapshots.jsonl
# unless --no-append is passed.
#
# Exit codes:
#   0   clean | notable | bead-class
#   1   halt threshold crossed (N>=halt-threshold)
#   2   usage error
#   3   not in a git repo / git unavailable

set -euo pipefail

VERSION="stash-discipline-check/v1"
SCHEMA_VERSION="$VERSION"
REPO=""
JSON_OUT=0
APPEND_SNAPSHOT=1
UPDATE_STATE_MD=""
T_NOTABLE=1
T_BEAD=5
T_HALT=10
SNAPSHOT_LOG="${STASH_DISCIPLINE_SNAPSHOT_LOG:-$HOME/.local/state/flywheel/stash-discipline-snapshots.jsonl}"

usage() {
  cat <<'USAGE'
usage:
  stash-discipline-check.sh [--repo PATH] [--json] [--no-append]
                            [--update-state-md PATH]
                            [--threshold-notable N] [--threshold-bead N] [--threshold-halt N]
  stash-discipline-check.sh --info|--help|--examples [--json]

Probes git stash count vs git-stash-discipline thresholds. Defaults: notable=1,
bead=5, halt=10. Defaults to --repo "$PWD". Snapshots append to
~/.local/state/flywheel/stash-discipline-snapshots.jsonl unless --no-append.
Optional --update-state-md replaces a tagged block in STATE.md (idempotent).

Exit codes: 0=clean|notable|bead-class, 1=halt, 2=usage, 3=not-a-git-repo.
USAGE
}

examples() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc '{examples:[
      "stash-discipline-check.sh --json",
      "stash-discipline-check.sh --repo /Users/josh/Developer/flywheel --json",
      "stash-discipline-check.sh --update-state-md .flywheel/STATE.md --json",
      "stash-discipline-check.sh --threshold-halt 8 --json"
    ]}'
  else
    cat <<'EX'
stash-discipline-check.sh --json
stash-discipline-check.sh --repo /Users/josh/Developer/flywheel --json
stash-discipline-check.sh --update-state-md .flywheel/STATE.md --json
stash-discipline-check.sh --threshold-halt 8 --json
EX
  fi
}

info() {
  jq -nc \
    --arg name "stash-discipline-check.sh" \
    --arg version "$VERSION" \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg log "$SNAPSHOT_LOG" \
    --argjson tn "$T_NOTABLE" \
    --argjson tb "$T_BEAD" \
    --argjson th "$T_HALT" \
    '{
      name:$name,
      version:$version,
      schema_version:$schema_version,
      mutates:false,
      doctrine:".flywheel/doctrine/git-stash-discipline.md",
      authority:"joshua-direct-ask 2026-05-10T19:25Z",
      thresholds:{notable:$tn,bead:$tb,halt:$th},
      classes:["clean","notable","bead_filing_class","halt"],
      snapshot_log:$log,
      exit_codes:{"0":"clean|notable|bead_filing_class","1":"halt","2":"usage","3":"not_a_git_repo"}
    }'
}

die_usage() { printf 'ERR: %s\n' "$1" >&2; usage >&2; exit 2; }

# First pass: pick up --json before action flags so `--examples --json`
# (any order) emits JSON correctly.
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
    --threshold-notable) T_NOTABLE="${2:-1}"; shift 2 ;;
    --threshold-bead) T_BEAD="${2:-5}"; shift 2 ;;
    --threshold-halt) T_HALT="${2:-10}"; shift 2 ;;
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

# Probe stash count. Run in subshell so we don't change CWD.
STASH_COUNT="$(
  cd "$REPO" 2>/dev/null || exit 3
  if ! command -v git >/dev/null 2>&1; then exit 3; fi
  if ! git rev-parse --git-dir >/dev/null 2>&1; then exit 3; fi
  git stash list 2>/dev/null | wc -l | tr -d ' '
)"
probe_rc=$?
if [[ "$probe_rc" -ne 0 || -z "${STASH_COUNT:-}" ]]; then
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg repo "$REPO" \
      '{schema_version:$sv,command:"check",status:"not_a_git_repo",repo:$repo}'
  else
    printf 'status=not_a_git_repo repo=%s\n' "$REPO" >&2
  fi
  exit 3
fi

# Threshold classification.
TS="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
if [[ "$STASH_COUNT" -ge "$T_HALT" ]]; then
  klass="halt"
  rc=1
elif [[ "$STASH_COUNT" -ge "$T_BEAD" ]]; then
  klass="bead_filing_class"
  rc=0
elif [[ "$STASH_COUNT" -ge "$T_NOTABLE" ]]; then
  klass="notable"
  rc=0
else
  klass="clean"
  rc=0
fi

# Sample first 5 stash subjects (for context, not full stash dump).
STASH_SAMPLE_JSON="$(
  cd "$REPO" 2>/dev/null
  git stash list --max-count=5 --format='%gd %s' 2>/dev/null \
    | jq -R . | jq -sc '.' 2>/dev/null || printf '[]'
)"
[[ -z "$STASH_SAMPLE_JSON" ]] && STASH_SAMPLE_JSON='[]'

# Build envelope.
ENVELOPE="$(jq -nc \
  --arg sv "$SCHEMA_VERSION" \
  --arg ts "$TS" \
  --arg repo "$REPO" \
  --argjson stash_count "$STASH_COUNT" \
  --arg klass "$klass" \
  --argjson tn "$T_NOTABLE" \
  --argjson tb "$T_BEAD" \
  --argjson th "$T_HALT" \
  --argjson sample "$STASH_SAMPLE_JSON" \
  '{
    schema_version:$sv,
    command:"check",
    ts:$ts,
    repo:$repo,
    stash_count:$stash_count,
    class:$klass,
    thresholds:{notable:$tn,bead:$tb,halt:$th},
    halt:($klass == "halt"),
    bead_filing_required:($klass == "bead_filing_class"),
    sample_first_5:$sample,
    doctrine:".flywheel/doctrine/git-stash-discipline.md"
  }')"

# Snapshot append.
if [[ "$APPEND_SNAPSHOT" -eq 1 ]]; then
  mkdir -p "$(dirname "$SNAPSHOT_LOG")" 2>/dev/null || true
  printf '%s\n' "$ENVELOPE" >>"$SNAPSHOT_LOG" 2>/dev/null || true
fi

# STATE.md tagged-block update.
if [[ -n "$UPDATE_STATE_MD" ]]; then
  if [[ -f "$UPDATE_STATE_MD" && -w "$UPDATE_STATE_MD" ]]; then
    BLOCK_BODY="$(jq -nc \
      --arg ts "$TS" \
      --argjson n "$STASH_COUNT" \
      --arg klass "$klass" \
      --argjson tn "$T_NOTABLE" \
      --argjson tb "$T_BEAD" \
      --argjson th "$T_HALT" \
      --arg log "$SNAPSHOT_LOG" \
      '"\n## Stash Snapshot\n\n<!-- stash-snapshot:begin -->\n- ts: \($ts)\n- stash_count: \($n)\n- class: \($klass)\n- thresholds: notable=\($tn) bead=\($tb) halt=\($th)\n- doctrine: .flywheel/doctrine/git-stash-discipline.md\n- snapshot_log: \($log)\n<!-- stash-snapshot:end -->\n"' \
      | jq -r .)"
    # Replace existing block if present, else append.
    python3 - "$UPDATE_STATE_MD" "$BLOCK_BODY" <<'PY' || true
import re, sys, pathlib
path = pathlib.Path(sys.argv[1])
new_block = sys.argv[2]
# Bash $(...) strips trailing newlines; restore one so the substitution
# preserves the canonical block-ending newline (regex below requires it).
if not new_block.endswith("\n"):
    new_block = new_block + "\n"
text = path.read_text(encoding="utf-8")
# Match the entire "## Stash Snapshot\n\n<!-- stash-snapshot:begin -->...<!-- stash-snapshot:end -->" block,
# tolerating absent / present trailing newline.
pattern = re.compile(r"\n## Stash Snapshot\n\n<!-- stash-snapshot:begin -->.*?<!-- stash-snapshot:end -->\n?", re.DOTALL)
if pattern.search(text):
    out = pattern.sub(new_block, text)
else:
    out = text.rstrip() + "\n" + new_block
path.write_text(out, encoding="utf-8")
PY
  fi
fi

# Emit.
if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$ENVELOPE"
else
  printf 'stash_count=%d class=%s repo=%s thresholds=notable:%d,bead:%d,halt:%d\n' \
    "$STASH_COUNT" "$klass" "$REPO" "$T_NOTABLE" "$T_BEAD" "$T_HALT"
  if [[ "$rc" -eq 1 ]]; then
    printf 'BLOCKED: stash count %d >= halt threshold %d per git-stash-discipline doctrine\n' "$STASH_COUNT" "$T_HALT" >&2
  elif [[ "$klass" == "bead_filing_class" ]]; then
    printf 'WARN: stash count %d >= bead threshold %d; file flywheel-stash-cleanup bead\n' "$STASH_COUNT" "$T_BEAD" >&2
  fi
fi

exit "$rc"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
