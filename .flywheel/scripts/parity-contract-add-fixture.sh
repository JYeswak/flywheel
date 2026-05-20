#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT_PATH=""
FIXTURE_PATH=""
TESTS_DIR=""
CREATE=0

usage() {
  cat <<'EOF'
usage: parity-contract-add-fixture.sh --script PATH [--fixture PATH] [--tests-dir PATH] [--create]

Adds an idempotent parity_assertion block to the smoke fixture for a dual-mode
script. Existing fixtures are preferred; --create creates tests/<script>-smoke.sh
when no fixture exists.
EOF
}

die() {
  printf 'parity-contract-add-fixture: %s\n' "$1" >&2
  exit "${2:-2}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --script) SCRIPT_PATH="${2:-}"; shift 2 ;;
    --script=*) SCRIPT_PATH="${1#*=}"; shift ;;
    --fixture) FIXTURE_PATH="${2:-}"; shift 2 ;;
    --fixture=*) FIXTURE_PATH="${1#*=}"; shift ;;
    --tests-dir) TESTS_DIR="${2:-}"; shift 2 ;;
    --tests-dir=*) TESTS_DIR="${1#*=}"; shift ;;
    --create) CREATE=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ -n "$SCRIPT_PATH" ]] || die "--script is required"
[[ "$SCRIPT_PATH" = /* ]] || SCRIPT_PATH="$ROOT/$SCRIPT_PATH"
[[ -f "$SCRIPT_PATH" ]] || die "script not found: $SCRIPT_PATH"

TESTS_DIR="${TESTS_DIR:-$ROOT/tests}"
[[ "$TESTS_DIR" = /* ]] || TESTS_DIR="$ROOT/$TESTS_DIR"

script_name="$(basename "$SCRIPT_PATH")"
stem="${script_name%.sh}"

if [[ -z "$FIXTURE_PATH" ]]; then
  for candidate in \
    "$TESTS_DIR/$stem-smoke.sh" \
    "$TESTS_DIR/$stem.sh" \
    "$TESTS_DIR/$stem-canonical-cli.sh" \
    "$TESTS_DIR/test-$stem.sh" \
    "$TESTS_DIR/test_$stem.sh"; do
    if [[ -f "$candidate" ]]; then
      FIXTURE_PATH="$candidate"
      break
    fi
  done
fi

if [[ -z "$FIXTURE_PATH" ]]; then
  if [[ "$CREATE" -eq 1 ]]; then
    mkdir -p "$TESTS_DIR"
    FIXTURE_PATH="$TESTS_DIR/$stem-smoke.sh"
    {
      printf '#!/usr/bin/env bash\n'
      printf 'set -euo pipefail\n\n'
      # shellcheck disable=SC2016
      printf 'ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"\n'
      # shellcheck disable=SC2016
      printf 'SCRIPT="$ROOT/%s"\n\n' "${SCRIPT_PATH#"$ROOT/"}"
    } >"$FIXTURE_PATH"
    chmod +x "$FIXTURE_PATH"
  else
    die "no smoke fixture found for $script_name; pass --fixture or --create"
  fi
fi

[[ "$FIXTURE_PATH" = /* ]] || FIXTURE_PATH="$ROOT/$FIXTURE_PATH"
[[ -f "$FIXTURE_PATH" ]] || die "fixture not found: $FIXTURE_PATH"

if grep -q 'parity_assertion' "$FIXTURE_PATH"; then
  printf 'unchanged %s\n' "${FIXTURE_PATH#"$ROOT/"}"
  exit 0
fi

script_rel="${SCRIPT_PATH#"$ROOT/"}"

cat >>"$FIXTURE_PATH" <<EOF

# parity_assertion: dry-run/apply must share the same pre-mutation computation.
test_parity_dry_run_apply_envelope() {
  local dry_envelope apply_envelope
  dry_envelope="\$("\$ROOT/$script_rel" --dry-run --json | jq -S 'del(.ts, .outcome) | (.computation // .desired // .plan // .)')"
  apply_envelope="\$("\$ROOT/$script_rel" --apply --json --no-mutate-side-effects | jq -S 'del(.ts, .outcome) | (.computation // .desired // .plan // .)')"
  if ! diff <(printf '%s\n' "\$dry_envelope") <(printf '%s\n' "\$apply_envelope"); then
    echo "FAIL: dry-run and apply diverge on pre-mutation computation"
    return 1
  fi
  echo "ok parity_dry_run_apply_envelope"
}

test_parity_dry_run_apply_envelope
EOF

printf 'updated %s\n' "${FIXTURE_PATH#"$ROOT/"}"
