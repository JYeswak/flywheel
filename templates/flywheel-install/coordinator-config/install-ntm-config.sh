#!/usr/bin/env bash
# install-ntm-config.sh — sync the canonical [coordinator] block from the
# flywheel repo into ~/.config/ntm/config.toml.
#
# Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet
# Mission test:  wires substrate? YES  removes drift? YES  isomorphic? YES
#
# Canonical CLI scoping (per ~/.claude/skills/canonical-cli-scoping):
#   --dry-run (default), --apply, --json, --explain, --info, --examples,
#   --schema, --repo PATH, -h|--help
#
# Refusal envelope: --apply is REFUSED unless a --dry-run completed in the
# same login session (marker at /tmp/install-ntm-config-dryrun.<user>).
#
# Validation: after --apply we run `ntm coordinator status flywheel --json`;
# any non-zero exit reverts the config from the backup.

set -Eeuo pipefail

SCRIPT_VERSION="1.0.0"
SCHEMA_VERSION=1
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CANON_DEFAULT="${SCRIPT_DIR}/ntm-config.canonical.toml"
LIVE_DEFAULT="${HOME}/.config/ntm/config.toml"
DRYRUN_MARKER="/tmp/install-ntm-config-dryrun.${USER}"

# Canonical key/value pairs the script enforces. Order matters for diff output.
CANON_KEYS=(
    "idle_threshold=300"
    "poll_interval=\"30s\""
    "digest_interval=\"30m\""
    "assign_only_idle=true"
    "auto_assign=true"
)

usage() {
    cat <<EOF
install-ntm-config.sh v${SCRIPT_VERSION}
Sync the canonical NTM [coordinator] block into ~/.config/ntm/config.toml.

USAGE
    install-ntm-config.sh [--dry-run|--apply] [--json] [--repo PATH]
    install-ntm-config.sh --explain | --info | --examples | --schema | --help

MODES
    --dry-run           Show diff vs canonical, exit 0. (DEFAULT)
    --apply             Back up current and write canonical. Refused
                        unless a --dry-run ran in this login session.

OUTPUT
    --json              Emit diff/result as JSON (default: human-readable).

SOURCES
    --repo PATH         Path to flywheel repo root. Default: walk up from
                        \$PWD looking for templates/flywheel-install/.

INTROSPECTION
    --explain           Print purpose + mission tie-in.
    --info              Print version, paths, schema version.
    --examples          Print invocation examples.
    --schema            Print canonical key list.
    -h, --help          This help.
EOF
}

explain() {
    cat <<EOF
PURPOSE
    Pin the [coordinator] block of ~/.config/ntm/config.toml to a
    repo-tracked canonical so every machine in the fleet has identical
    coordinator behavior (idle threshold, poll interval, digest cadence,
    auto-assign gating, conflict notifications).

MISSION TIE-IN
    continuous-orchestrator-uptime-self-sustaining-fleet
    - wires substrate: NTM coordinator IS the substrate; this script
      removes the per-machine config drift that left it half-configured.
    - removes drift: 5 keys were drifted from declared values on
      josh@local 2026-05-07; this script makes drift detectable + fixable.
    - isomorphic: identical config across flywheel, {session}, {capability-control-plane},
      {proof-product}, vrtx, clutterfreespaces.
EOF
}

examples() {
    cat <<'EOF'
EXAMPLES
    # Preview drift (default, safe).
    install-ntm-config.sh

    # Same, machine-readable.
    install-ntm-config.sh --dry-run --json

    # Apply (only after a dry-run in this session).
    install-ntm-config.sh --apply

    # Explicit repo path (CI/cron usage).
    install-ntm-config.sh --repo <flywheel-repo> --apply
EOF
}

schema_dump() {
    printf '%s\n' "${CANON_KEYS[@]}"
}

info() {
    cat <<EOF
script_version    ${SCRIPT_VERSION}
schema_version    ${SCHEMA_VERSION}
canonical_path    ${CANON:-$CANON_DEFAULT}
live_path         ${LIVE:-$LIVE_DEFAULT}
dryrun_marker     ${DRYRUN_MARKER}
EOF
}

# --- arg parsing ---
MODE="dry-run"
JSON=0
CANON="${CANON:-$CANON_DEFAULT}"
LIVE="${LIVE:-$LIVE_DEFAULT}"
REPO=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) MODE="dry-run"; shift;;
        --apply) MODE="apply"; shift;;
        --json) JSON=1; shift;;
        --repo) REPO="$2"; shift 2;;
        --explain) explain; exit 0;;
        --info) info; exit 0;;
        --examples) examples; exit 0;;
        --schema) schema_dump; exit 0;;
        -h|--help) usage; exit 0;;
        *) echo "unknown flag: $1" >&2; usage >&2; exit 2;;
    esac
done

if [[ -n "$REPO" ]]; then
    CANON="${REPO}/templates/flywheel-install/coordinator-config/ntm-config.canonical.toml"
fi

[[ -r "$CANON" ]] || { echo "canonical missing: $CANON" >&2; exit 3; }

# --- read current values from live config ---
read_live_value() {
    local key="$1"
    [[ -r "$LIVE" ]] || { echo ""; return; }
    awk -v k="$key" '
        /^\[coordinator\]/ {in_block=1; next}
        /^\[/ && in_block {in_block=0}
        in_block && $0 ~ "^[[:space:]]*"k"[[:space:]]*=" {
            sub(/^[^=]*=[[:space:]]*/, "")
            sub(/[[:space:]]*#.*$/, "")
            sub(/[[:space:]]*$/, "")
            print
            exit
        }
    ' "$LIVE"
}

# --- compute diff ---
declare -a DRIFTS=()
declare -a MATCHES=()
declare -a STRUCTURAL_DRIFTS=()

coordinator_block_count() {
    [[ -r "$LIVE" ]] || { echo 0; return; }
    awk '/^\[coordinator\][[:space:]]*$/ {count++} END{print count+0}' "$LIVE"
}

nested_coordinator_block_count() {
    [[ -r "$LIVE" ]] || { echo 0; return; }
    awk '/^\[coordinator\./ {count++} END{print count+0}' "$LIVE"
}

coordinator_schema_version_count() {
    [[ -r "$LIVE" ]] || { echo 0; return; }
    awk '
        /^\[coordinator\][[:space:]]*$/ {in_block=1; next}
        /^\[/ && in_block {in_block=0}
        in_block && /^[[:space:]]*schema_version[[:space:]]*=/ {count++}
        END{print count+0}
    ' "$LIVE"
}

COORDINATOR_BLOCK_COUNT="$(coordinator_block_count)"
if [[ "$COORDINATOR_BLOCK_COUNT" != "1" ]]; then
    STRUCTURAL_DRIFTS+=("coordinator_block_count|$COORDINATOR_BLOCK_COUNT|1")
fi
NESTED_COORDINATOR_BLOCK_COUNT="$(nested_coordinator_block_count)"
if [[ "$NESTED_COORDINATOR_BLOCK_COUNT" != "0" ]]; then
    STRUCTURAL_DRIFTS+=("nested_coordinator_block_count|$NESTED_COORDINATOR_BLOCK_COUNT|0")
fi
COORDINATOR_SCHEMA_VERSION_COUNT="$(coordinator_schema_version_count)"
if [[ "$COORDINATOR_SCHEMA_VERSION_COUNT" != "0" ]]; then
    STRUCTURAL_DRIFTS+=("coordinator_schema_version_count|$COORDINATOR_SCHEMA_VERSION_COUNT|0")
fi

for kv in "${CANON_KEYS[@]}"; do
    key="${kv%%=*}"
    want="${kv#*=}"
    got="$(read_live_value "$key")"
    if [[ "$got" == "$want" ]]; then
        MATCHES+=("$key")
    else
        DRIFTS+=("${key}|${got:-<missing>}|${want}")
    fi
done

# --- output ---
emit_diff_human() {
    echo "canonical : $CANON"
    echo "live      : $LIVE"
    echo "matches   : ${#MATCHES[@]}"
    echo "drifts    : ${#DRIFTS[@]}"
    echo "structural: ${#STRUCTURAL_DRIFTS[@]}"
    if [[ ${#DRIFTS[@]} -gt 0 ]]; then
        echo
        printf '  %-22s %-22s %-22s\n' KEY LIVE CANONICAL
        for d in "${DRIFTS[@]}"; do
            IFS='|' read -r k g w <<<"$d"
            printf '  %-22s %-22s %-22s\n' "$k" "$g" "$w"
        done
    fi
    if [[ ${#STRUCTURAL_DRIFTS[@]} -gt 0 ]]; then
        echo
        printf '  %-22s %-22s %-22s\n' STRUCTURE LIVE CANONICAL
        for d in "${STRUCTURAL_DRIFTS[@]}"; do
            IFS='|' read -r k g w <<<"$d"
            printf '  %-22s %-22s %-22s\n' "$k" "$g" "$w"
        done
    fi
}

emit_diff_json() {
    printf '{"canonical":"%s","live":"%s","matches":%d,"coordinator_block_count":%s,"nested_coordinator_block_count":%s,"coordinator_schema_version_count":%s,"drifts":[' "$CANON" "$LIVE" "${#MATCHES[@]}" "$COORDINATOR_BLOCK_COUNT" "$NESTED_COORDINATOR_BLOCK_COUNT" "$COORDINATOR_SCHEMA_VERSION_COUNT"
    local first=1
    for d in "${DRIFTS[@]}"; do
        IFS='|' read -r k g w <<<"$d"
        [[ $first -eq 1 ]] || printf ','
        first=0
        printf '{"key":"%s","live":%s,"canonical":%s}' \
            "$k" "$(printf '%s' "$g" | jq -R .)" "$(printf '%s' "$w" | jq -R .)"
    done
    printf '],"structural_drifts":['
    first=1
    for d in "${STRUCTURAL_DRIFTS[@]}"; do
        IFS='|' read -r k g w <<<"$d"
        [[ $first -eq 1 ]] || printf ','
        first=0
        printf '{"key":"%s","live":%s,"canonical":%s}' \
            "$k" "$(printf '%s' "$g" | jq -R .)" "$(printf '%s' "$w" | jq -R .)"
    done
    printf ']}\n'
}

if [[ "$MODE" == "dry-run" ]]; then
    if [[ $JSON -eq 1 ]]; then emit_diff_json; else emit_diff_human; fi
    : > "$DRYRUN_MARKER"
    exit 0
fi

# --- apply ---
[[ -f "$DRYRUN_MARKER" ]] || {
    echo "REFUSE: run --dry-run first (marker $DRYRUN_MARKER missing)" >&2
    exit 4
}

[[ -r "$LIVE" ]] || { echo "live config missing: $LIVE" >&2; exit 5; }

ts="$(date -u +%Y%m%dT%H%M%SZ)"
backup="${LIVE}.bak.${ts}"
cp "$LIVE" "$backup"

canon_block_file="$(mktemp)"
awk '
    BEGIN{grab=0}
    /^\[coordinator\][[:space:]]*$/ {grab=1; print; next}
    /^\[/ && grab {grab=0}
    grab {print}
' "$CANON" > "$canon_block_file"

tmp="$(mktemp)"
awk -v repl_file="$canon_block_file" '
    function print_repl() {
        while ((getline line < repl_file) > 0) print line
        close(repl_file)
    }
    BEGIN{skipping=0; printed=0}
    /^\[coordinator\][[:space:]]*$/ {
        if (!printed) {print_repl(); printed=1}
        skipping=1; next
    }
    /^\[/ && skipping && !/^\[coordinator\./ {skipping=0}
    !skipping {print}
    END{ if (!printed) print_repl() }
' "$LIVE" > "$tmp"
rm -f "$canon_block_file"
mv "$tmp" "$LIVE"

validate_runtime_config() {
    local status_json runtime_config jq_rc
    runtime_config="$(mktemp)"
    awk '
        BEGIN{grab=0}
        /^\[coordinator\][[:space:]]*$/ {grab=1; print; next}
        /^\[/ && grab {grab=0}
        grab {print}
    ' "$LIVE" > "$runtime_config"
    if ! grep -q '^\[coordinator\][[:space:]]*$' "$runtime_config"; then
        rm -f "$runtime_config"
        return 1
    fi
    status_json="$(ntm coordinator status flywheel --config "$runtime_config" --json 2>/dev/null)" || {
        rm -f "$runtime_config"
        return 1
    }
    jq -e '
      .config.auto_assign == true
      and .config.assign_only_idle == true
      and .config.idle_threshold == 300
      and (.config.poll_interval == "30s" or .config.poll_interval == "30s0ms")
      and (.config.digest_interval == "30m" or .config.digest_interval == "30m0s")
    ' >/dev/null <<<"$status_json"
    jq_rc=$?
    rm -f "$runtime_config"
    return "$jq_rc"
}

# Validate actual runtime semantics, not just command shape.
if ! validate_runtime_config; then
    echo "VALIDATION FAILED — restoring backup $backup" >&2
    cp "$backup" "$LIVE"
    exit 6
fi

if [[ $JSON -eq 1 ]]; then
    printf '{"applied":true,"backup":"%s","schema_version":%d}\n' "$backup" "$SCHEMA_VERSION"
else
    echo "applied. backup=$backup schema_version=$SCHEMA_VERSION"
fi
rm -f "$DRYRUN_MARKER"
