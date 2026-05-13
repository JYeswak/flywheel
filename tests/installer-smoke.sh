#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-installer-smoke.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0
ARTIFACT_DIR="${FLYWHEEL_INSTALLER_SMOKE_ARTIFACT_DIR:-}"
pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1" >&2; }

run_capture() {
  local out="$1" err="$2"
  shift 2
  set +e
  "$@" >"$out" 2>"$err"
  local rc=$?
  set +e
  return "$rc"
}

write_artifacts() {
  local status="$1"
  [[ -n "$ARTIFACT_DIR" ]] || return 0
  mkdir -p "$ARTIFACT_DIR"
  local file
  for file in "$TMP"/*.json "$TMP"/*.out "$TMP"/*.err "$TMP"/*.txt; do
    [[ -e "$file" ]] && cp "$file" "$ARTIFACT_DIR/"
  done
  jq -n \
    --arg schema_version "flywheel.installer_smoke_receipt.v0" \
    --arg status "$status" \
    --arg runner_os "${RUNNER_OS:-local}" \
    --arg prefix "$PREFIX" \
    --argjson pass_count "$PASS" \
    --argjson fail_count "$FAIL" \
    '{
      schema_version: $schema_version,
      status: $status,
      runner_os: $runner_os,
      prefix: $prefix,
      pass_count: $pass_count,
      fail_count: $fail_count,
      artifacts: [
        "install-dry-run.json",
        "install.json",
        "partial.out",
        "doctor.json",
        "init.json",
        "tick.json",
        "dispatch.json",
        "closeout.json",
        "inspect.json",
        "reinstall.json",
        "uninstall.json",
        "remaining-files.txt",
        "reduced-closeout-receipt.json"
      ]
    }' >"$ARTIFACT_DIR/installer-smoke-receipt.json"
}

PREFIX="$TMP/engine"

if bash -n "$ROOT/install.sh" && bash -n "$ROOT/uninstall.sh" && bash -n "$ROOT/bin/flywheel"; then
  pass "syntax"
else
  fail "syntax"
fi

if "$ROOT/install.sh" --prefix "$PREFIX" --dry-run --json >"$TMP/install-dry-run.json" \
  && jq -e '.dry_run == true and (.planned_files | length >= 8)' "$TMP/install-dry-run.json" >/dev/null; then
  pass "install dry-run"
else
  fail "install dry-run"
fi

if "$ROOT/install.sh" --prefix "$PREFIX" --json >"$TMP/install.json"; then
  if jq -e '.status == "installed" and .installed_files >= 8 and .preflight.exit_code <= 20' "$TMP/install.json" >/dev/null; then
    pass "install"
  else
    fail "install envelope"
  fi
else
  fail "install"
fi

if [[ -x "$PREFIX/bin/flywheel" && -f "$PREFIX/install-receipt.json" ]]; then
  pass "installed files"
else
  fail "installed files"
fi

run_capture "$TMP/partial.out" "$TMP/partial.err" "$PREFIX/bin/flywheel" preflight --fixture "$PREFIX/fixtures/preflight/partial.json" --json
partial_rc=$?
if [[ "$partial_rc" -eq 20 ]] && jq -e '.mode == "reduced" and .exit_code == 20' "$TMP/partial.out" >/dev/null; then
  pass "installed preflight reduced"
else
  fail "installed preflight reduced rc=${partial_rc}"
fi

if "$PREFIX/bin/flywheel" doctor --json >"$TMP/doctor.json" \
  && jq -e '.command == "doctor" and .status == "pass"' "$TMP/doctor.json" >/dev/null; then
  pass "installed doctor"
else
  fail "installed doctor"
fi

repo="$TMP/repo"
mkdir -p "$repo"
git -C "$repo" init -q
if "$PREFIX/bin/flywheel" init --repo "$repo" --json >"$TMP/init.json" \
  && "$PREFIX/bin/flywheel" tick --repo "$repo" --dry-run --json >"$TMP/tick.json" \
  && "$PREFIX/bin/flywheel" dispatch --repo "$repo" --simulate --json >"$TMP/dispatch.json" \
  && "$PREFIX/bin/flywheel" validate-receipt --repo "$repo" --file .flywheel/last_closeout_receipt.json --json >"$TMP/closeout.json" \
  && "$PREFIX/bin/flywheel" inspect --repo "$repo" --json >"$TMP/inspect.json" \
  && jq -e '.status == "pass"' "$TMP/inspect.json" >/dev/null; then
  cp "$repo/.flywheel/last_closeout_receipt.json" "$TMP/reduced-closeout-receipt.json"
  pass "installed reduced first-run"
else
  fail "installed reduced first-run"
fi

if "$ROOT/install.sh" --prefix "$PREFIX" --json >"$TMP/reinstall.json" \
  && jq -e '.status == "installed"' "$TMP/reinstall.json" >/dev/null; then
  pass "idempotent reinstall"
else
  fail "idempotent reinstall"
fi

if "$ROOT/uninstall.sh" --prefix "$PREFIX" --confirm --json >"$TMP/uninstall.json"; then
  if jq -e '.status == "removed" and (.removed_files | length >= 8)' "$TMP/uninstall.json" >/dev/null; then
    pass "uninstall"
  else
    fail "uninstall envelope"
  fi
else
  fail "uninstall"
fi

if [[ ! -e "$PREFIX" ]]; then
  pass "byte equality empty prefix"
else
  find "$PREFIX" -print >&2
  fail "byte equality empty prefix"
fi
find "$PREFIX" -type f -print >"$TMP/remaining-files.txt" 2>/dev/null || true

if [[ "$FAIL" -gt 0 ]]; then
  write_artifacts "fail"
  printf 'SUMMARY pass=%d fail=%d\n' "$PASS" "$FAIL" >&2
  exit 1
fi
write_artifacts "pass"
printf 'SUMMARY pass=%d fail=0\n' "$PASS"
