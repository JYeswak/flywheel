#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/idle-pane-auto-dispatch.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/idle-pane-work-started.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_NTM_ARGV:?}"
case "${1:-}" in
  wait)
    jq -nc '{success:false,condition:"idle",matched:false,reason:"timeout"}'
    exit 1
    ;;
  assign)
    printf 'assign must not run after wait timeout\n' >&2
    exit 8
    ;;
  *)
    exit 2
    ;;
esac
SH
chmod +x "$TMP/ntm"

mkdir -p "$TMP/repo"
FAKE_NTM_ARGV="$TMP/argv" "$SCRIPT" --session fixture --repo "$TMP/repo" --ntm-bin "$TMP/ntm" --dry-run --json \
  >"$TMP/out.json"

jq -e '
  .status == "no_idle_wait_timeout"
  and .wait.exit_code == 1
  and .assign == null
' "$TMP/out.json" >/dev/null

grep -q '^wait fixture --until=idle --any --timeout=1s --json$' "$TMP/argv"
if grep -q '^assign ' "$TMP/argv"; then
  printf 'FAIL assign ran after wait timeout\n' >&2
  exit 1
fi

printf 'PASS wait timeout prevents native assign\n'
