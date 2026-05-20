#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
VALIDATOR_DIR="$ROOT/.flywheel/scripts/mp-validators"
SCHEMA_VERSION="mp-validator-framework.scorecard/v1"

usage() {
  cat <<'EOF'
usage: .flywheel/scripts/mp-validator-framework.sh [--json] <MP-XX|all> <target-path>

Runs executable meta-pattern validators against a target file or directory.
Validator exit codes: 0 PASS, 1 FAIL, 2 SKIP-NA.
EOF
}

json=0
case "${1:-}" in
  --json) json=1; shift ;;
  -h|--help|"") usage; exit 0 ;;
esac

mp_id="${1:-}"
target="${2:-}"
if [[ -z "$mp_id" || -z "$target" ]]; then
  usage >&2
  exit 64
fi

if [[ ! -e "$target" ]]; then
  if [[ "$json" -eq 1 ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg target "$target" \
      '{schema_version:$sv,target:$target,status:"FAIL",summary:{pass:0,fail:1,skip:0,applicable:1,coverage_ratio:0},rows:[{mp_id:null,status:"FAIL",reason:"target path does not exist"}]}'
  else
    printf 'FAIL target path does not exist: %s\n' "$target" >&2
  fi
  exit 1
fi

validators=()
if [[ "$mp_id" == "all" ]]; then
  while IFS= read -r file; do validators+=("$file"); done < <(find "$VALIDATOR_DIR" -maxdepth 1 -type f -name 'MP-*-validator.sh' | sort)
else
  while IFS= read -r file; do validators+=("$file"); done < <(find "$VALIDATOR_DIR" -maxdepth 1 -type f -name "${mp_id}-*-validator.sh" | sort)
fi

if [[ "${#validators[@]}" -eq 0 ]]; then
  if [[ "$json" -eq 1 ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg target "$target" --arg mp "$mp_id" \
      '{schema_version:$sv,target:$target,status:"FAIL",summary:{pass:0,fail:1,skip:0,applicable:1,coverage_ratio:0},rows:[{mp_id:$mp,status:"FAIL",reason:"validator not found"}]}'
  else
    printf 'FAIL validator not found for %s\n' "$mp_id" >&2
  fi
  exit 1
fi

tmp="$(mktemp "${TMPDIR:-/tmp}/mp-validator.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
fail=0
skip=0

for validator in "${validators[@]}"; do
  set +e
  row="$("$validator" --json "$target" 2>/dev/null)"
  rc=$?
  set -e
  if ! jq -e . >/dev/null 2>&1 <<<"$row"; then
    base="$(basename "$validator")"
    row="$(jq -nc --arg v "$base" --arg target "$target" \
      '{schema_version:"mp-validator.row/v1",mp_id:($v|capture("(?<id>MP-[0-9]+)").id),validator:$v,target:$target,status:"FAIL",reason:"validator emitted invalid JSON"}')"
    rc=1
  fi
  printf '%s\n' "$row" >>"$tmp"
  case "$rc" in
    0) ;;
    1) fail=$((fail + 1)) ;;
    2) skip=$((skip + 1)) ;;
    *) fail=$((fail + 1)) ;;
  esac
  if [[ "$json" -eq 0 ]]; then
    jq -r '"\(.status) \(.mp_id) \(.target): \(.reason)"' <<<"$row"
  fi
done

if [[ "$json" -eq 1 ]]; then
  jq -s --arg sv "$SCHEMA_VERSION" --arg target "$target" '
    def count_status($s): map(select(.status == $s)) | length;
    . as $rows
    | ($rows | count_status("PASS")) as $pass
    | ($rows | count_status("FAIL")) as $fail
    | ($rows | count_status("SKIP")) as $skip
    | ($pass + $fail) as $applicable
    | {
        schema_version:$sv,
        target:$target,
        status:(if $fail > 0 then "FAIL" else "PASS" end),
        summary:{
          pass:$pass,
          fail:$fail,
          skip:$skip,
          applicable:$applicable,
          coverage_ratio:(if $applicable == 0 then null else (($pass / $applicable) * 10000 | round / 10000) end)
        },
        rows:$rows
      }
  ' "$tmp"
fi

if [[ "$fail" -gt 0 ]]; then
  exit 1
fi
if [[ "${#validators[@]}" -eq "$skip" && "$mp_id" != "all" ]]; then
  exit 2
fi
exit 0
