#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCANNER="$ROOT/.flywheel/scripts/check-trauma-class-substrate.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/trauma-class-scan.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
    local file="$1" filter="$2" label="$3"
    if jq -e "$filter" "$file" >/dev/null; then
        pass "$label"
    else
        fail "$label"
        jq . "$file" >&2 || true
    fi
}

run_scan() {
    local name="$1" expected_rc="$2" root="$3" launchagents="$4" registry="$5"
    local out="$TMP/$name.json" before="$TMP/$name.before" after="$TMP/$name.after" rc=0
    RUN_OUT="$out"
    find "$root" -type f -exec shasum -a 256 {} + 2>/dev/null | sort >"$before"
    "$SCANNER" \
        --json \
        --root "$root" \
        --launchagents-dir "$launchagents" \
        --registry "$registry" \
        --local-bin-dir "$TMP/local-bin" \
        --ps-fixture "$TMP/empty-ps.txt" \
        >"$out" || rc=$?
    find "$root" -type f -exec shasum -a 256 {} + 2>/dev/null | sort >"$after"
    if [[ "$rc" == "$expected_rc" ]]; then
        pass "$name rc"
    else
        fail "$name rc expected=$expected_rc got=$rc"
    fi
    if cmp -s "$before" "$after"; then
        pass "$name no scanned-file mutation"
    else
        fail "$name mutated scanned files"
    fi
}

bash -n "$SCANNER" && pass "scanner syntax" || fail "scanner syntax"
test -x "$SCANNER" && pass "scanner executable" || fail "scanner executable"

mkdir -p "$TMP/local-bin"
: >"$TMP/empty-ps.txt"

silent_root="$TMP/silent-root"
silent_la="$TMP/silent-la"
silent_registry="$TMP/silent-registry.jsonl"
mkdir -p "$silent_root" "$silent_la"
cat >"$silent_root/silent.sh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$row" >>"$HOME/.local/state/flywheel/scratch.jsonl"
SH
run_scan silent 1 "$silent_root" "$silent_la" "$silent_registry"
assert_jq "$RUN_OUT" 'length == 1 and .[0].class == "silent-write" and .[0].line == 2 and .[0].severity == "high" and .[0].exempt_reason == null' "silent-write fixture"

destructive_root="$TMP/destructive-root"
destructive_la="$TMP/destructive-la"
destructive_registry="$TMP/destructive-registry.jsonl"
mkdir -p "$destructive_root" "$destructive_la"
cat >"$destructive_root/destructive.sh" <<'SH'
#!/usr/bin/env bash
docker image prune --force
SH
run_scan destructive 1 "$destructive_root" "$destructive_la" "$destructive_registry"
assert_jq "$RUN_OUT" 'length == 1 and .[0].class == "destructive-default" and (.[0].matched_pattern | test("docker prune"))' "destructive-default fixture"

unregistered_root="$TMP/unregistered-root"
unregistered_la="$TMP/unregistered-la"
unregistered_registry="$TMP/unregistered-registry.jsonl"
mkdir -p "$unregistered_root" "$unregistered_la"
cat >"$unregistered_root/clean.sh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "clean"
SH
cat >"$unregistered_la/ai.zeststream.fixture-unregistered.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict><key>Label</key><string>ai.zeststream.fixture-unregistered</string></dict></plist>
PLIST
run_scan unregistered 1 "$unregistered_root" "$unregistered_la" "$unregistered_registry"
assert_jq "$RUN_OUT" 'length == 1 and .[0].class == "unregistered-process" and (.[0].file | test("ai.zeststream.fixture-unregistered.plist$"))' "unregistered-process fixture"

clean_root="$TMP/clean-root"
clean_la="$TMP/clean-la"
clean_registry="$TMP/clean-registry.jsonl"
mkdir -p "$clean_root" "$clean_la"
cat >"$clean_root/clean.sh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "clean"
SH
run_scan clean 0 "$clean_root" "$clean_la" "$clean_registry"
assert_jq "$RUN_OUT" 'length == 0' "clean fixture"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
