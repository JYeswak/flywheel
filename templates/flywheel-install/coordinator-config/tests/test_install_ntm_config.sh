#!/usr/bin/env bash
# test_install_ntm_config.sh — exercise four cases for install-ntm-config.sh.
#
# Cases:
#   1. clean install (no [coordinator] block) — diff shows all canonical keys missing
#   2. drift detection (mismatched values) — diff lists drift keys
#   3. no-op when matching — diff shows zero drifts
#   4. refuse-apply-without-dryrun — exit 4
#   5. apply after dryrun rewrites the coordinator block

set -Eeuo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTALLER="${SCRIPT_DIR}/../install-ntm-config.sh"
CANON="${SCRIPT_DIR}/../ntm-config.canonical.toml"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0; fail=0
ok() { echo "PASS  $1"; pass=$((pass+1)); }
ko() { echo "FAIL  $1"; fail=$((fail+1)); }

run() {
    # run installer with a synthetic LIVE path
    local live="$1"; shift
    HOME="$WORK/home" \
    USER="testuser" \
    bash -c '
        export DRYRUN_MARKER="/tmp/install-ntm-config-dryrun.testuser"
        rm -f "$DRYRUN_MARKER"
        true
    '
    LIVE_OVERRIDE="$live" "$INSTALLER" "$@" 2>&1
}

# Case 1: clean install
case1() {
    local live="$WORK/clean.toml"
    cat > "$live" <<'EOF'
projects_base = "/tmp"

[tmux]
default_panes = 4
EOF
    out="$(LIVE="$live" "$INSTALLER" --dry-run 2>&1)" || true
    if echo "$out" | grep -q 'drifts    : 6'; then
        ok "case1_clean_install_detects_all_keys_missing"
    else
        ko "case1_clean_install_detects_all_keys_missing"
        echo "$out"
    fi
}

# Case 2: drift detection
case2() {
    local live="$WORK/drift.toml"
    cat > "$live" <<'EOF'
[coordinator]
schema_version = 1
idle_threshold = 30
poll_interval = "5s"
digest_interval = "5m"
assign_only_idle = true
auto_assign = true
EOF
    out="$(LIVE="$live" "$INSTALLER" --dry-run --json 2>&1)" || true
    drifts=$(echo "$out" | jq '.drifts | length')
    if [[ "$drifts" == "3" ]]; then
        ok "case2_drift_detection_finds_3_keys"
    else
        ko "case2_drift_detection_finds_3_keys (got $drifts)"
        echo "$out"
    fi
}

# Case 3: no-op when matching
case3() {
    local live="$WORK/match.toml"
    cat > "$live" <<'EOF'
[coordinator]
schema_version = 1
idle_threshold = 300
poll_interval = "30s"
digest_interval = "30m"
assign_only_idle = true
auto_assign = true
EOF
    out="$(LIVE="$live" "$INSTALLER" --dry-run --json 2>&1)" || true
    drifts=$(echo "$out" | jq '.drifts | length')
    if [[ "$drifts" == "0" ]]; then
        ok "case3_noop_when_matching"
    else
        ko "case3_noop_when_matching (got $drifts)"
        echo "$out"
    fi
}

# Case 4: refuse apply without dryrun
case4() {
    local live="$WORK/apply.toml"
    cat > "$live" <<'EOF'
[coordinator]
auto_assign = false
EOF
    rm -f "/tmp/install-ntm-config-dryrun.${USER}"
    set +e
    LIVE="$live" "$INSTALLER" --apply >/dev/null 2>&1
    rc=$?
    set -e
    if [[ "$rc" == "4" ]]; then
        ok "case4_refuse_apply_without_dryrun"
    else
        ko "case4_refuse_apply_without_dryrun (exit $rc)"
    fi
}

case5() {
    local live="$WORK/apply_after_dryrun.toml"
    cat > "$live" <<'EOF'
projects_base = "/tmp"

[coordinator]
auto_assign = false
idle_threshold = 30

[after]
kept = true
EOF
    LIVE="$live" "$INSTALLER" --dry-run >/dev/null
    LIVE="$live" "$INSTALLER" --apply >/dev/null
    out="$(LIVE="$live" "$INSTALLER" --dry-run --json 2>&1)" || true
    drifts=$(echo "$out" | jq '.drifts | length')
    if [[ "$drifts" == "0" ]] && grep -q 'auto_assign = true' "$live" && grep -q 'kept = true' "$live"; then
        ok "case5_apply_after_dryrun_rewrites_block"
    else
        ko "case5_apply_after_dryrun_rewrites_block"
        echo "$out"
        cat "$live"
    fi
}

case1
case2
case3
case4
case5

echo
echo "results: $pass pass, $fail fail"
[[ $fail -eq 0 ]]
