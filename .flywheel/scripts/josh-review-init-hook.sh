#!/usr/bin/env bash
# josh-review-init-hook.sh — wire Josh-Review into a newly-adopted repo.
#
# Invoked by /flywheel:adopt and /flywheel:init.
#
# What it does:
#   1. Drops a copy of josh-review-poll.sh into <target-repo>/.flywheel/scripts/
#   2. Appends the per-tick poll line to <target-repo>/.flywheel/config/tick-recipe.txt
#      (idempotent — only appends if not already present)
#   3. Drops a stub README at <target-repo>/.flywheel/doctrine/josh-review-pointer.md
#      pointing back to the canonical doctrine in the flywheel repo
#   4. Creates ~/.local/state/flywheel/josh-review/ if missing
#
# Usage:
#   josh-review-init-hook.sh <target-repo-path>
#   josh-review-init-hook.sh --dry-run <target-repo-path>

set -euo pipefail

CANONICAL_REPO="/Users/josh/Developer/flywheel"
CANONICAL_POLL="$CANONICAL_REPO/.flywheel/scripts/josh-review-poll.sh"
CANONICAL_DOCTRINE="$CANONICAL_REPO/.flywheel/doctrine/meta-learnings/josh-review-canonical-decision-surface.md"

DRY=0
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --help|-h) sed -n '1,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//' | sed '$d'; exit 0 ;;
    -*) printf 'unknown flag: %s\n' "$1" >&2; exit 2 ;;
    *) TARGET="$1"; shift ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  printf 'usage: %s [--dry-run] <target-repo-path>\n' "$(basename "$0")" >&2
  exit 2
fi

if [[ ! -d "$TARGET/.flywheel" ]]; then
  printf 'target repo is not flywheel-initialized (no .flywheel/): %s\n' "$TARGET" >&2
  exit 1
fi

if [[ ! -f "$CANONICAL_POLL" ]]; then
  printf 'canonical poll script missing: %s\n' "$CANONICAL_POLL" >&2
  exit 1
fi

run() {
  if [[ $DRY -eq 1 ]]; then
    printf 'DRY: %s\n' "$*"
  else
    eval "$@"
  fi
}

scripts_dir="$TARGET/.flywheel/scripts"
config_dir="$TARGET/.flywheel/config"
doctrine_dir="$TARGET/.flywheel/doctrine"
recipe="$config_dir/tick-recipe.txt"
poll_dest="$scripts_dir/josh-review-poll.sh"
pointer="$doctrine_dir/josh-review-pointer.md"
state_dir="$HOME/.local/state/flywheel/josh-review"

run "mkdir -p '$scripts_dir' '$config_dir' '$doctrine_dir' '$state_dir'"

# 1. Copy poll script (overwrite — canonical wins). Skip self-copy.
if [[ "$(cd "$(dirname "$CANONICAL_POLL")" && pwd)/$(basename "$CANONICAL_POLL")" \
     != "$(cd "$(dirname "$poll_dest")" 2>/dev/null && pwd)/$(basename "$poll_dest")" ]]; then
  run "cp '$CANONICAL_POLL' '$poll_dest'"
else
  printf 'self-copy detected — skip (target is canonical repo)\n'
fi
run "chmod +x '$poll_dest'"

# 2. Append poll line to tick-recipe.txt if missing.
poll_line='[ -x .flywheel/scripts/josh-review-poll.sh ] && .flywheel/scripts/josh-review-poll.sh --quiet'
if [[ ! -f "$recipe" ]]; then
  run "printf '# Auto-managed by josh-review-init-hook.sh\n# Per-tick steps for this repo.\n\n%s\n' '$poll_line' > '$recipe'"
elif ! grep -Fq 'josh-review-poll.sh' "$recipe" 2>/dev/null; then
  run "printf '\n# josh-review poll (added by josh-review-init-hook.sh)\n%s\n' '$poll_line' >> '$recipe'"
else
  printf 'tick-recipe.txt already references josh-review-poll.sh — skip append\n'
fi

# 3. Write pointer doc.
if [[ $DRY -eq 0 ]]; then
  cat > "$pointer" <<EOF
# Josh-Review pointer

This repo participates in the fleet-wide Josh-Review approve/deny surface.

**Canonical doctrine (source of truth):**
\`$CANONICAL_DOCTRINE\`

**Folder README (folder shape):**
\`~/Josh-Review/_README.md\`

**Skill:**
\`~/.claude/skills/josh-review-discipline/SKILL.md\`

**Poll script (local copy):**
\`.flywheel/scripts/josh-review-poll.sh\`

The per-tick poll is wired into \`.flywheel/config/tick-recipe.txt\`.

To file a Tier-3 decision for Joshua, read the skill above and drop a file in
\`~/Josh-Review/pending/\` per the format template. Do NOT xpane Joshua's user pane.
EOF
else
  printf 'DRY: would write %s\n' "$pointer"
fi

printf 'josh-review-init-hook: OK for %s\n' "$TARGET"
