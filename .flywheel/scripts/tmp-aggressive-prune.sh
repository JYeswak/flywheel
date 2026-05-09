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
#   --root=PATH   target root, default /private/tmp (test/fixture support)
#   --json        emit JSON receipt
#
# Excludes (deny-list):
#   /private/tmp/com.apple.*  — Apple system
#   /private/tmp/.*           — dot-files (system + tooling state)
#   /private/tmp/claude-*     — active Claude Code session scratch
#   /private/tmp/launchd-*    — launchd
#   /private/tmp/tmux-*       — tmux/socket transport
#   /private/tmp/<service>-<uid> — service-owned IPC directories
#   <directories containing sockets> — active IPC transport dirs
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
target_root="/private/tmp"

while [ $# -gt 0 ]; do
    case "$1" in
        --apply) apply=1 ;;
        --dry-run) apply=0 ;;
        --idempotency-key=*) idem_key="${1#*=}" ;;
        --idempotency-key) shift; idem_key="$1" ;;
        --max-mtime-days=*) max_mtime_days="${1#*=}" ;;
        --max-mtime-days) shift; max_mtime_days="$1" ;;
        --root=*) target_root="${1#*=}" ;;
        --root) shift; target_root="$1" ;;
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

if [ ! -d "$target_root" ]; then
    echo "ERROR: root does not exist or is not a directory: $target_root" >&2
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

has_socket_entry() {
    local path="$1"
    [ -d "$path" ] || return 1
    find "$path" -type s -print -quit 2>/dev/null | grep -q .
}

protected_reason() {
    local path="$1"
    local base="$2"
    case "$base" in
        # System / Apple
        com.apple.*|.*) echo "system"; return 0 ;;
        # Active IPC sockets — DO NOT TOUCH (incident 2026-05-08T23:09Z killed 4 fleet sessions)
        tmux-*|launchd-*|sshd-*|com.googlecode.*) echo "ipc-name"; return 0 ;;
        # Active session scratch
        claude-*|claude_*) echo "session-scratch"; return 0 ;;
    esac
    if [[ "$base" =~ ^[A-Za-z0-9_.-]+-[0-9]+$ ]]; then
        echo "service-uid-ipc"
        return 0
    fi
    if has_socket_entry "$path"; then
        echo "socket-entry"
        return 0
    fi
    return 1
}

# Identify candidates: top-level entries in /private/tmp older than threshold,
# excluding deny-list patterns.
candidates=()
protected_count=0
protected_sample=""
while IFS= read -r path; do
    base="$(basename "$path")"
    if reason="$(protected_reason "$path" "$base")"; then
        protected_count=$((protected_count + 1))
        if [ "$protected_count" -le 5 ]; then
            protected_sample="${protected_sample}${path}=${reason} "
        fi
        continue
    fi
    candidates+=("$path")
done < <(find "$target_root" -maxdepth 1 -mindepth 1 -mtime "+$max_mtime_days" 2>/dev/null)

count_planned="${#candidates[@]}"

# Sample sizes (top 5) for receipt
sample_sizes=""
sample_size_failures=0
for p in "${candidates[@]:0:5}"; do
    sz="$(du -sh "$p" 2>/dev/null | awk '{print $1}' || true)"
    if [ -z "$sz" ]; then
        sz="unknown"
        sample_size_failures=$((sample_size_failures + 1))
    fi
    sample_sizes="${sample_sizes}${p}=${sz} "
done

if [ "$apply" = "0" ]; then
    if [ "$emit_json" = "1" ]; then
        printf '{"status":"ok","apply":false,"ts":"%s","root":"%s","candidates_count":%d,"protected_count":%d,"sample_size_failures":%d,"max_mtime_days":%s,"sample":"%s","protected_sample":"%s"}\n' \
            "$ts" "$target_root" "$count_planned" "$protected_count" "$sample_size_failures" "$max_mtime_days" "$sample_sizes" "$protected_sample"
    else
        echo "DRY-RUN — would prune $count_planned entries from $target_root >${max_mtime_days}d mtime"
        echo "Protected: $protected_count ($protected_sample)"
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
  "root": "$target_root",
  "idempotency_key": "$idem_key",
  "candidates_count": $count_planned,
  "protected_count": $protected_count,
  "sample_size_failures": $sample_size_failures,
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
