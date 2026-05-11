#!/usr/bin/env bash
set -euo pipefail

OUTPUT_JSON=0
ROOTS=()
ROOTS_OVERRIDE=0

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/$(basename "${BASH_SOURCE[0]}")"
REPO_ROOT="${FLYWHEEL_TRAUMA_SCAN_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
SKILL_SCRIPTS_DIR="${FLYWHEEL_TRAUMA_SCAN_SKILL_SCRIPTS_DIR:-$HOME/.claude/skills/.flywheel/scripts}"
LOCAL_BIN_DIR="${FLYWHEEL_TRAUMA_SCAN_LOCAL_BIN:-$HOME/.local/bin}"
LAUNCHAGENTS_DIR="${FLYWHEEL_TRAUMA_SCAN_LAUNCHAGENTS_DIR:-$HOME/Library/LaunchAgents}"
REGISTRY="${FLYWHEEL_TRAUMA_SCAN_REGISTRY:-$HOME/.local/state/flywheel/plist-registry.jsonl}"
PS_FIXTURE="${FLYWHEEL_TRAUMA_SCAN_PS_FIXTURE:-}"
SCAN_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
FINDINGS='[]'

usage() {
    cat <<'USAGE'
Usage:
  check-trauma-class-substrate.sh [--json] [--root PATH ...]
  check-trauma-class-substrate.sh --repo PATH --json

Read-only B56 trauma-class scanner.

Exit:
  0 = no findings
  1 = findings emitted
  2 = usage error
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) OUTPUT_JSON=1; shift ;;
        --root) [[ $# -ge 2 ]] || { printf 'usage error: --root requires PATH\n' >&2; exit 2; }; ROOTS+=("$2"); ROOTS_OVERRIDE=1; shift 2 ;;
        --root=*) ROOTS+=("${1#*=}"); ROOTS_OVERRIDE=1; shift ;;
        --repo) [[ $# -ge 2 ]] || { printf 'usage error: --repo requires PATH\n' >&2; exit 2; }; REPO_ROOT="$2"; shift 2 ;;
        --repo=*) REPO_ROOT="${1#*=}"; shift ;;
        --skill-scripts-dir) [[ $# -ge 2 ]] || { printf 'usage error: --skill-scripts-dir requires PATH\n' >&2; exit 2; }; SKILL_SCRIPTS_DIR="$2"; shift 2 ;;
        --skill-scripts-dir=*) SKILL_SCRIPTS_DIR="${1#*=}"; shift ;;
        --local-bin-dir) [[ $# -ge 2 ]] || { printf 'usage error: --local-bin-dir requires PATH\n' >&2; exit 2; }; LOCAL_BIN_DIR="$2"; shift 2 ;;
        --local-bin-dir=*) LOCAL_BIN_DIR="${1#*=}"; shift ;;
        --launchagents-dir) [[ $# -ge 2 ]] || { printf 'usage error: --launchagents-dir requires PATH\n' >&2; exit 2; }; LAUNCHAGENTS_DIR="$2"; shift 2 ;;
        --launchagents-dir=*) LAUNCHAGENTS_DIR="${1#*=}"; shift ;;
        --registry) [[ $# -ge 2 ]] || { printf 'usage error: --registry requires PATH\n' >&2; exit 2; }; REGISTRY="$2"; shift 2 ;;
        --registry=*) REGISTRY="${1#*=}"; shift ;;
        --ps-fixture) [[ $# -ge 2 ]] || { printf 'usage error: --ps-fixture requires PATH\n' >&2; exit 2; }; PS_FIXTURE="$2"; shift 2 ;;
        --ps-fixture=*) PS_FIXTURE="${1#*=}"; shift ;;
        --help|-h) usage; exit 0 ;;
        --) shift; break ;;
        -*) printf 'usage error: unknown arg: %s\n' "$1" >&2; usage >&2; exit 2 ;;
        *) ROOTS+=("$1"); ROOTS_OVERRIDE=1; shift ;;
    esac
done

if [[ "$ROOTS_OVERRIDE" -eq 0 ]]; then
    ROOTS=("$REPO_ROOT" "$SKILL_SCRIPTS_DIR" "$LOCAL_BIN_DIR")
fi

add_finding() {
    local class="$1" file="$2" line="$3" severity="$4" suggested="$5" matched="$6"
    local line_json
    if [[ "$line" == "null" ]]; then
        line_json="null"
    else
        line_json="$line"
    fi
    FINDINGS="$(jq \
        --arg scan_ts "$SCAN_TS" \
        --arg class "$class" \
        --arg file "$file" \
        --arg severity "$severity" \
        --arg suggested_bead "$suggested" \
        --arg matched_pattern "$matched" \
        --argjson line "$line_json" \
        '. + [{
          scan_ts:$scan_ts,
          class:$class,
          file:$file,
          line:$line,
          severity:$severity,
          suggested_bead:$suggested_bead,
          matched_pattern:$matched_pattern,
          exempt_reason:null
        }]' <<<"$FINDINGS")"
}

is_probable_source_file() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    [[ "$file" == "$SCRIPT_PATH" ]] && return 1
    case "$file" in
        "$REPO_ROOT/.git/"*|"$REPO_ROOT/.beads/"*|"$REPO_ROOT/.socraticode/"*|"$REPO_ROOT/.flywheel/jeff-corpus/"*) return 1 ;;
        "$REPO_ROOT/tests/"*) return 1 ;;
        "$REPO_ROOT/.flywheel/PLANS/"*|"$REPO_ROOT/.flywheel/archive/"*) return 1 ;;
    esac
    case "$file" in
        *.sh|*.bash|*.zsh|*.command) return 0 ;;
    esac
    [[ -x "$file" ]] && return 0
    return 1
}

context_for_line() {
    local file="$1" line="$2" span="${3:-12}" start end
    start=$((line - span))
    [[ "$start" -lt 1 ]] && start=1
    end=$((line + span))
    sed -n "${start},${end}p" "$file" 2>/dev/null || true
}

silent_write_exempt() {
    local file="$1" line="$2"
    case "$file" in
        */lib/jsonl-append.sh|*/flywheel-watchers/lib/jsonl-append.sh) return 0 ;;
    esac
    context_for_line "$file" "$line" 8 | grep -Eq 'fw_jsonl_append_validated|source .*(jsonl-append\.sh)' && return 0
    return 1
}

has_nearby_apply_or_dry_run_gate() {
    local file="$1" line="$2"
    context_for_line "$file" "$line" 16 | grep -Eq -- '--apply|--dry-run|FW_APPLY|FW_DRY_RUN|DRY_RUN|dry_run|fw_effective_dry_run|apply_required|preview|planned_actions'
}

scan_silent_writes() {
    local file="$1" lineno text
    while IFS=: read -r lineno text; do
        [[ -n "$lineno" ]] || continue
        [[ "$text" =~ ^[[:space:]]*# ]] && continue
        if grep -Eq '(^|[^[:alnum:]_])(printf|echo)([[:space:]]|$).*>>' <<<"$text" \
            && grep -Eq '(\.(jsonl|json|log)([^[:alnum:]_]|$)|LEDGER|REGISTRY|LOG|STATE|DISPATCH|HISTORY)' <<<"$text"; then
            if ! silent_write_exempt "$file" "$lineno"; then
                add_finding "silent-write" "$file" "$lineno" "high" "B56-FIX-02 or new" "printf/echo append without validated readback"
            fi
        fi
    done < <(grep -nE '(^|[^[:alnum:]_])(printf|echo)([[:space:]]|$).*>>' "$file" 2>/dev/null || true)
}

scan_destructive_defaults() {
    local file="$1" lineno text label regex
    local labels=(
        "launchctl bootout"
        "launchctl unload"
        "kill -9"
        "rm -rf"
        "docker prune --force"
        "git reset --hard"
    )
    local regexes=(
        '(^|[^[:alnum:]_-])launchctl[[:space:]]+bootout([[:space:]]|$)'
        '(^|[^[:alnum:]_-])launchctl[[:space:]]+unload([[:space:]]|$)'
        '(^|[^[:alnum:]_-])kill[[:space:]]+-9([[:space:]]|$)'
        '(^|[^[:alnum:]_-])rm[[:space:]]+-[^[:space:]]*r[^[:space:]]*f|(^|[^[:alnum:]_-])rm[[:space:]]+-[^[:space:]]*f[^[:space:]]*r'
        '(^|[^[:alnum:]_-])docker([[:space:]]|$).*prune([[:space:]]|$).*--force'
        '(^|[^[:alnum:]_-])git[[:space:]]+reset[[:space:]]+--hard([[:space:]]|$)'
    )
    for idx in "${!labels[@]}"; do
        label="${labels[$idx]}"
        regex="${regexes[$idx]}"
        while IFS=: read -r lineno text; do
            [[ -n "$lineno" ]] || continue
            [[ "$text" =~ ^[[:space:]]*# ]] && continue
            if ! has_nearby_apply_or_dry_run_gate "$file" "$lineno"; then
                case "$label" in
                    "docker prune --force"|"rm -rf") severity="critical" ;;
                    *) severity="high" ;;
                esac
                add_finding "destructive-default" "$file" "$lineno" "$severity" "B56-FIX-05/B56-FIX-06/B56-FIX-10 or new" "$label without nearby apply/dry-run gate"
            fi
        done < <(grep -nE "$regex" "$file" 2>/dev/null || true)
    done
}

scan_script_file() {
    local file="$1"
    is_probable_source_file "$file" || return 0
    grep -Iq . "$file" 2>/dev/null || return 0
    scan_silent_writes "$file"
    scan_destructive_defaults "$file"
}

registry_active_labels() {
    if [[ ! -s "$REGISTRY" ]]; then
        printf '[]\n'
        return 0
    fi
    jq -s 'map(select(type == "object" and (.label? | type == "string")))
      | sort_by(.label, (.ts // ""))
      | group_by(.label)
      | map(last | select((.action // "register") != "unregister") | .label)' "$REGISTRY" 2>/dev/null || printf '[]\n'
}

is_registered_label() {
    local label="$1" labels="$2"
    jq -e --arg label "$label" 'index($label)' <<<"$labels" >/dev/null
}

plist_label() {
    local plist="$1" label
    label="$(/usr/libexec/PlistBuddy -c 'Print :Label' "$plist" 2>/dev/null || true)"
    [[ -n "$label" ]] || label="$(basename "$plist" .plist)"
    printf '%s\n' "$label"
}

scan_unregistered_plists() {
    local labels plist label
    labels="$(registry_active_labels)"
    [[ -d "$LAUNCHAGENTS_DIR" ]] || return 0
    while IFS= read -r plist; do
        [[ -n "$plist" ]] || continue
        label="$(plist_label "$plist")"
        case "$label" in
            ai.zeststream.*) ;;
            *) continue ;;
        esac
        if ! is_registered_label "$label" "$labels"; then
            add_finding "unregistered-process" "$plist" "null" "high" "B56-FIX-07/B56-FIX-08 or new" "ai.zeststream LaunchAgent absent from plist registry"
        fi
    done < <(find "$LAUNCHAGENTS_DIR" -maxdepth 1 -type f -name 'ai.zeststream.*.plist' -print 2>/dev/null | sort)
}

process_rows() {
    if [[ -n "$PS_FIXTURE" ]]; then
        cat "$PS_FIXTURE"
    else
        ps -eo pid=,args= 2>/dev/null || true
    fi
}

scan_unregistered_processes() {
    local labels line path base
    labels="$(registry_active_labels)"
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        [[ "$line" == *"check-trauma-class-substrate.sh"* ]] && continue
        [[ "$line" =~ (watcher|auto-dispatch|auto-act|fleet-watch|flywheel-loop|idle-pane) ]] || continue
        path="$(grep -Eo "(/tmp/[^[:space:]]+|${LOCAL_BIN_DIR//\//\\/}/[^[:space:]]+)" <<<"$line" | head -n 1 || true)"
        [[ -n "$path" ]] || continue
        base="$(basename "$path")"
        if ! is_registered_label "$base" "$labels"; then
            add_finding "unregistered-process" "$path" "null" "medium" "B56-FIX-08 or new" "watcher-like background script absent from plist registry"
        fi
    done < <(process_rows)
}

for root in "${ROOTS[@]}"; do
    if [[ -f "$root" ]]; then
        scan_script_file "$root"
    elif [[ -d "$root" ]]; then
        while IFS= read -r file; do
            scan_script_file "$file"
        done < <(find "$root" -type f -print 2>/dev/null | sort)
    fi
done

scan_unregistered_plists
scan_unregistered_processes

if [[ "$OUTPUT_JSON" -eq 1 ]]; then
    jq '.' <<<"$FINDINGS"
else
    count="$(jq 'length' <<<"$FINDINGS")"
    if [[ "$count" -eq 0 ]]; then
        printf 'trauma-class-scan findings=0\n'
    else
        printf 'trauma-class-scan findings=%s\n' "$count"
        jq -r '.[] | [.class, .severity, (.file + ":" + ((.line // "null")|tostring)), .matched_pattern, .suggested_bead] | @tsv' <<<"$FINDINGS"
    fi
fi

[[ "$(jq 'length' <<<"$FINDINGS")" -eq 0 ]]
