#!/usr/bin/env bash
# test_install_ntm_config.sh — exercise four cases for install-ntm-config.sh.
#
# Cases:
#   1. clean install (no [coordinator] block) — diff shows all canonical keys missing
#   2. drift detection (mismatched values) — diff lists drift keys
#   3. no-op when matching — diff shows zero drifts
#   4. refuse-apply-without-dryrun — exit 4
#   5. apply after dryrun rewrites the coordinator block
#   6. duplicate [coordinator] blocks are structural drift and apply collapses them
#   7. runtime-incompatible coordinator schema/nested tables are structural drift

set -Eeuo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTALLER="${SCRIPT_DIR}/../install-ntm-config.sh"

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
    if echo "$out" | grep -q 'drifts    : 5'; then
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
idle_threshold = 300
poll_interval = "30s"
digest_interval = "30m"
assign_only_idle = true
auto_assign = true
EOF
    out="$(LIVE="$live" "$INSTALLER" --dry-run --json 2>&1)" || true
    drifts=$(echo "$out" | jq '.drifts | length')
    structural=$(echo "$out" | jq '.structural_drifts | length')
    if [[ "$drifts" == "0" && "$structural" == "0" ]]; then
        ok "case3_noop_when_matching"
    else
        ko "case3_noop_when_matching (got drifts=$drifts structural=$structural)"
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

case6() {
    local live="$WORK/duplicate_blocks.toml"
    cat > "$live" <<'EOF'
projects_base = "/tmp"

[coordinator]
idle_threshold = 300
poll_interval = "30s"
digest_interval = "30m"
assign_only_idle = true
auto_assign = true

[session_paths]
flywheel = "/tmp/flywheel"

[coordinator]
idle_threshold = 300
poll_interval = "30s"
digest_interval = "30m"
assign_only_idle = true
auto_assign = true
EOF
    out="$(LIVE="$live" "$INSTALLER" --dry-run --json 2>&1)" || true
    structural=$(echo "$out" | jq '.structural_drifts | length')
    block_count=$(echo "$out" | jq '.coordinator_block_count')
    if [[ "$structural" == "1" && "$block_count" == "2" ]]; then
        ok "case6_duplicate_blocks_detected"
    else
        ko "case6_duplicate_blocks_detected (structural=$structural block_count=$block_count)"
        echo "$out"
        return
    fi
    LIVE="$live" "$INSTALLER" --dry-run >/dev/null
    # Stub runtime validation for fixture config; live ntm does not have /tmp/flywheel session state.
    PATH="$WORK/bin:$PATH" LIVE="$live" "$INSTALLER" --apply >/dev/null
    after_count="$(awk '/^\[coordinator\][[:space:]]*$/ {count++} END{print count+0}' "$live")"
    if [[ "$after_count" == "1" ]] && grep -q '\[session_paths\]' "$live"; then
        ok "case6_apply_collapses_duplicate_blocks"
    else
        ko "case6_apply_collapses_duplicate_blocks (after_count=$after_count)"
        cat "$live"
    fi
}

case7() {
    local live="$WORK/runtime_incompatible.toml"
    cat > "$live" <<'EOF'
[coordinator]
schema_version = 1
idle_threshold = 300
poll_interval = "30s"
digest_interval = "30m"
assign_only_idle = true
auto_assign = true

[coordinator.session_default]
auto_assign = true
EOF
    out="$(LIVE="$live" "$INSTALLER" --dry-run --json 2>&1)" || true
    structural=$(echo "$out" | jq '.structural_drifts | length')
    nested=$(echo "$out" | jq '.nested_coordinator_block_count')
    schema=$(echo "$out" | jq '.coordinator_schema_version_count')
    if [[ "$structural" == "2" && "$nested" == "1" && "$schema" == "1" ]]; then
        ok "case7_runtime_incompatible_shapes_detected"
    else
        ko "case7_runtime_incompatible_shapes_detected (structural=$structural nested=$nested schema=$schema)"
        echo "$out"
        return
    fi

    LIVE="$live" "$INSTALLER" --dry-run >/dev/null
    PATH="$WORK/bin:$PATH" LIVE="$live" "$INSTALLER" --apply >/dev/null
    out="$(LIVE="$live" "$INSTALLER" --dry-run --json 2>&1)" || true
    structural_after=$(echo "$out" | jq '.structural_drifts | length')
    if [[ "$structural_after" == "0" ]] && ! grep -q 'schema_version' "$live" && ! grep -q '^\[coordinator\.' "$live"; then
        ok "case7_apply_removes_runtime_incompatible_shapes"
    else
        ko "case7_apply_removes_runtime_incompatible_shapes (structural_after=$structural_after)"
        cat "$live"
    fi
}

mkdir -p "$WORK/bin"
cat > "$WORK/bin/ntm" <<'EOF'
#!/usr/bin/env bash
cat <<'JSON'
{"config":{"auto_assign":true,"assign_only_idle":true,"idle_threshold":300,"poll_interval":"30s","digest_interval":"30m0s"}}
JSON
EOF
chmod +x "$WORK/bin/ntm"

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
    PATH="$WORK/bin:$PATH" LIVE="$live" "$INSTALLER" --apply >/dev/null
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
case6
case7

echo
echo "results: $pass pass, $fail fail"
[[ $fail -eq 0 ]]
