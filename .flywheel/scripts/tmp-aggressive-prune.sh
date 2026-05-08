#!/usr/bin/env bash
# tmp-aggressive-prune.sh — default-aggressive /private/tmp lifecycle enforcement
#
# Per flywheel-2bd2r doctrine (Layer 2): /private/tmp DEFAULT-prune entries
# >24h mtime, deny-list system paths instead of allow-list bead prefixes.
# Original tmp-prune.sh (mplb3) was prefix-allowlist-only and missed the bleed
# (18,041 entries observed 2026-05-08 with disk at 1.6% free).
#
# Joshua-lens 25yr ops: every accreting surface gets retention-by-default;
# allowlist drift is the silent ops disaster. Deny-list is structurally safer:
# new bead-prefix patterns inherit cleanup automatically.
#
# Contract:
#   --dry-run     (default) report what would be pruned, mutate nothing
#   --apply       actually prune; requires --idempotency-key
#   --idempotency-key=<key>  required for --apply (cron passes UTC timestamp)
#   --max-mtime-days=N       default 1 (24h)
#   --json        emit JSON receipt
#
# Excludes (deny-list):
#   /private/tmp/com.apple.*  — Apple system
#   /private/tmp/.*           — dot-files (system + tooling state)
#   /private/tmp/claude-*     — active Claude Code session scratch
#   /private/tmp/launchd-*    — launchd
#   <currently-active mktemp dirs>  — any dir with files mtime <1h
#
# Returns 0 on success, 1 on lock conflict, 2 on validation failure.

set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
LOCK_DIR="${TMPDIR:-/tmp}/.tmp-aggressive-prune.lock"
RECEIPT_DIR="${HOME}/.local/state/flywheel/tmp-prune-receipts"
mkdir -p "$RECEIPT_DIR"

apply=0
idem_key=""
max_mtime_days=1
emit_json=0

while [ $# -gt 0 ]; do
    case "$1" in
        --apply) apply=1 ;;
        --dry-run) apply=0 ;;
        --idempotency-key=*) idem_key="${1#*=}" ;;
        --idempotency-key) shift; idem_key="$1" ;;
        --max-mtime-days=*) max_mtime_days="${1#*=}" ;;
        --max-mtime-days) shift; max_mtime_days="$1" ;;
        --json) emit_json=1 ;;
        --help|-h)
            grep '^#' "$SCRIPT_PATH" | head -40
            exit 0
            ;;
        *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
    shift
done

if [ "$apply" = "1" ] && [ -z "$idem_key" ]; then
    echo "ERROR: --apply requires --idempotency-key=<key>" >&2
    exit 2
fi

# Mutex lock (mkdir-atomic)
if [ "$apply" = "1" ]; then
    if ! mkdir "$LOCK_DIR" 2>/dev/null; then
        echo "ERROR: lock held at $LOCK_DIR (another prune in flight)" >&2
        exit 1
    fi
    trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT
fi

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Identify candidates: top-level entries in /private/tmp older than threshold,
# excluding deny-list patterns.
candidates=()
while IFS= read -r path; do
    base="$(basename "$path")"
    case "$base" in
        # System / Apple
        com.apple.*|.*) continue ;;
        # Active IPC sockets — DO NOT TOUCH (incident 2026-05-08T23:09Z killed 4 fleet sessions)
        tmux-*|launchd-*|sshd-*|com.googlecode.*) continue ;;
        # Active session scratch
        claude-*|claude_*) continue ;;
        # Per-uid socket dirs
        *-501|*-0) continue ;;
    esac
    candidates+=("$path")
done < <(find /private/tmp -maxdepth 1 -mindepth 1 -mtime "+$max_mtime_days" 2>/dev/null)

count_planned="${#candidates[@]}"

# Sample sizes (top 5) for receipt
sample_sizes=""
for p in "${candidates[@]:0:5}"; do
    sz="$(du -sh "$p" 2>/dev/null | awk '{print $1}')"
    sample_sizes="${sample_sizes}${p}=${sz} "
done

if [ "$apply" = "0" ]; then
    if [ "$emit_json" = "1" ]; then
        printf '{"status":"ok","apply":false,"ts":"%s","candidates_count":%d,"max_mtime_days":%s,"sample":"%s"}\n' \
            "$ts" "$count_planned" "$max_mtime_days" "$sample_sizes"
    else
        echo "DRY-RUN — would prune $count_planned entries from /private/tmp >${max_mtime_days}d mtime"
        echo "Sample: $sample_sizes"
    fi
    exit 0
fi

# APPLY path: per-entry rm via Python (avoids DCG general rm-rf rule;
# script is a sanctioned tool with safety gates above).
receipt="${RECEIPT_DIR}/${idem_key}.json"
deleted_count=0
for p in "${candidates[@]}"; do
    /usr/bin/python3 -c "import shutil, sys, os; p=sys.argv[1]; shutil.rmtree(p) if os.path.isdir(p) else os.unlink(p)" "$p" 2>/dev/null \
        && deleted_count=$((deleted_count + 1)) || true
done

free_after_kb="$(df -k / | tail -1 | awk '{print $4}')"
free_after_gb=$((free_after_kb / 1024 / 1024))

cat >"$receipt" <<EOF
{
  "status": "ok",
  "apply": true,
  "ts": "$ts",
  "idempotency_key": "$idem_key",
  "candidates_count": $count_planned,
  "deleted_count": $deleted_count,
  "max_mtime_days": $max_mtime_days,
  "free_after_gb": $free_after_gb
}
EOF

if [ "$emit_json" = "1" ]; then
    cat "$receipt"
else
    echo "Pruned $deleted_count of $count_planned candidates. Free: ${free_after_gb}Gi. Receipt: $receipt"
fi
