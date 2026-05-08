#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d -t doctor-pws.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/doctor_pws_common.sh"

"$HOME/.cargo/bin/br" dep cycles >"$TMP/cycles.out"
assert_jq <(jq -nc --arg out "$(cat "$TMP/cycles.out")" '{out:$out}') '.out | test("No dependency cycles detected")' "br_dep_cycles_empty"

doctor_pws_finish 1
