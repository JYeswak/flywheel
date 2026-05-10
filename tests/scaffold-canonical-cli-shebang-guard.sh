#!/usr/bin/env bash
# tests/scaffold-canonical-cli-shebang-guard.sh — regression for flywheel-e4lfb.
#
# Asserts:
#   1. Python (.sh extension) → rc=66, status=refused, reason=non_bash_shebang,
#      interpreter=python3, suggested_extension=py.
#   2. Python2 → interpreter=python.
#   3. Perl → interpreter=perl, suggested_extension=pl.
#   4. Node → interpreter=node, suggested_extension=js.
#   5. Ruby → interpreter=ruby, suggested_extension=rb.
#   6. Bash with `#!/bin/bash` → still scaffolds (rc=0, status=apply_ok|already_scaffolded).
#   7. Bash with `#!/usr/bin/env bash` → still scaffolds.
#   8. POSIX sh `#!/bin/sh` → still scaffolds (sh is a bash-compatible variant).
#   9. Empty file (no shebang) → still scaffolds (no false-positive refusal).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCAFFOLD="${SCAFFOLD:-$ROOT/.flywheel/scripts/scaffold-canonical-cli.sh}"
[[ -x "$SCAFFOLD" ]] || { echo "FAIL: scaffolder missing: $SCAFFOLD" >&2; exit 1; }

TMP="$(mktemp -d -t scaffold-shebang-guard.XXXXXX)"
trap 'find "$TMP" -mindepth 1 -delete 2>/dev/null; rmdir "$TMP" 2>/dev/null || true' EXIT

fail=0
report_fail() { echo "FAIL[$1]: $2" >&2; fail=$((fail+1)); }
pass()        { echo "PASS[$1]: $2"; }

# Helper: write a fixture, run scaffolder, capture output + rc.
probe() {
  local name="$1" shebang="$2" body="$3"
  local fix="$TMP/$name.sh"
  printf '%s\n%s\n' "$shebang" "$body" > "$fix"
  chmod +x "$fix"
  set +e
  local out rc
  out="$("$SCAFFOLD" "$fix" --apply --idempotency-key "guard-${name}-$$" --allow-uninventoried --json 2>&1 | tail -1)"
  rc=$?
  set -e
  printf '%s\t%s' "$rc" "$out"
}

# (1) python3 .sh → rc=66 + reason=non_bash_shebang + interpreter=python3
result="$(probe py3 "#!/usr/bin/env python3" 'import sys; sys.exit(0)')"
rc="${result%%	*}"
out="${result#*	}"
[[ "$rc" -eq 66 ]] || report_fail 1 "python3 expected rc=66 got $rc"
echo "$out" | jq -e '.status == "refused" and .reason == "non_bash_shebang" and .interpreter == "python3" and .suggested_extension == "py"' >/dev/null \
  || report_fail 1 "python3 envelope shape: $out"
pass 1 "python3 .sh refused rc=66 with envelope"

# (2) python (no version) → interpreter=python
result="$(probe py "#!/usr/bin/python" 'print "hi"')"
rc="${result%%	*}"
out="${result#*	}"
[[ "$rc" -eq 66 ]] || report_fail 2 "python expected rc=66 got $rc"
echo "$out" | jq -e '.interpreter == "python"' >/dev/null \
  || report_fail 2 "python interpreter shape: $out"
pass 2 "python .sh refused rc=66"

# (3) perl
result="$(probe perl "#!/usr/bin/perl" 'print "hi";')"
rc="${result%%	*}"
out="${result#*	}"
[[ "$rc" -eq 66 ]] || report_fail 3 "perl expected rc=66 got $rc"
echo "$out" | jq -e '.interpreter == "perl" and .suggested_extension == "pl"' >/dev/null \
  || report_fail 3 "perl shape: $out"
pass 3 "perl .sh refused with .pl ext hint"

# (4) node
result="$(probe node "#!/usr/bin/env node" 'console.log("hi");')"
rc="${result%%	*}"
out="${result#*	}"
[[ "$rc" -eq 66 ]] || report_fail 4 "node expected rc=66 got $rc"
echo "$out" | jq -e '.interpreter == "node" and .suggested_extension == "js"' >/dev/null \
  || report_fail 4 "node shape: $out"
pass 4 "node .sh refused with .js ext hint"

# (5) ruby
result="$(probe ruby "#!/usr/bin/env ruby" 'puts "hi"')"
rc="${result%%	*}"
out="${result#*	}"
[[ "$rc" -eq 66 ]] || report_fail 5 "ruby expected rc=66 got $rc"
echo "$out" | jq -e '.interpreter == "ruby" and .suggested_extension == "rb"' >/dev/null \
  || report_fail 5 "ruby shape: $out"
pass 5 "ruby .sh refused with .rb ext hint"

# (6) bash via #!/bin/bash → scaffolds (rc=0)
result="$(probe bash_abs "#!/bin/bash" 'echo hi')"
rc="${result%%	*}"
out="${result#*	}"
[[ "$rc" -eq 0 ]] || report_fail 6 "bash /bin/bash expected rc=0 got $rc; out=$out"
echo "$out" | jq -e '.status == "apply_ok" or .status == "already_scaffolded"' >/dev/null \
  || report_fail 6 "bash /bin/bash status not apply_ok/already: $out"
pass 6 "bash /bin/bash still scaffolds"

# (7) bash via env → scaffolds
result="$(probe bash_env "#!/usr/bin/env bash" 'echo hi')"
rc="${result%%	*}"
[[ "$rc" -eq 0 ]] || report_fail 7 "bash env expected rc=0 got $rc"
pass 7 "bash env still scaffolds"

# (8) sh via /bin/sh → scaffolds
result="$(probe sh_posix "#!/bin/sh" 'echo hi')"
rc="${result%%	*}"
[[ "$rc" -eq 0 ]] || report_fail 8 "/bin/sh expected rc=0 got $rc"
pass 8 "/bin/sh still scaffolds"

# (9) empty / no shebang → scaffolds (no false-positive refusal)
empty_fix="$TMP/empty.sh"
echo 'echo hi' > "$empty_fix"
chmod +x "$empty_fix"
set +e
empty_out="$("$SCAFFOLD" "$empty_fix" --apply --idempotency-key "guard-empty-$$" --allow-uninventoried --json 2>&1 | tail -1)"
empty_rc=$?
set -e
[[ "$empty_rc" -eq 0 ]] || report_fail 9 "no-shebang expected rc=0 got $empty_rc"
pass 9 "no-shebang file still scaffolds (no false positive)"

if [[ "$fail" -gt 0 ]]; then
  echo "FAIL: $fail assertion(s) failed" >&2
  exit 1
fi
echo "PASS scaffold-canonical-cli-shebang-guard (9 assertions)"
exit 0
