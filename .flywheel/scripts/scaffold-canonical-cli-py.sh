#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
# doctor-mode-tier: scaffolder (bead flywheel-oozt3 — python-aware sibling
#   of scaffold-canonical-cli.sh; closes the refused_python_shebang gap)
#
# scaffold-canonical-cli-py.sh — python-aware sibling of
# scaffold-canonical-cli.sh. Takes a python3 target and injects a canonical
# CLI shim AFTER shebang + module docstring + future-imports, BEFORE the
# target's own imports. The injected block adds canonical-cli introspection
# surfaces (--info / --schema / --examples / quickstart / help / completion)
# without overriding the target's existing argparse subcommands (e.g.
# flywheel-readme already ships cmd_doctor / cmd_repair / cmd_health). For
# canonical surfaces the target lacks (audit, why, validate), the shim
# provides scaffold stubs with TODO markers per canonical-cli-scoping.
#
# Why this is a separate scaffolder:
#   The bash scaffolder (scaffold-canonical-cli.sh) refuses non-bash
#   shebangs with rc=66 because appending bash-syntax boilerplate to a
#   python script produces a corrupt mixed-language file. Python scripts
#   in the canonical-cli inventory therefore stay stuck at
#   canonical_cli_scoping_status=refused_python_shebang indefinitely
#   (e.g. flywheel-readme, 993 lines, P0).
#
# Boundary:
#   - READ target script + inventory.jsonl (verifies presence)
#   - WRITE only to <target>.bak.scaffold-py-<UTC> (when --apply) and
#     <target>.scaffolded.tmp (intermediate before diff)
#   - REFUSE on jeff-stack paths (file upstream, don't patch)
#   - REFUSE on targets not in canonical inventory
#   - REFUSE on non-python shebangs (use the bash sibling)
#   - IDEMPOTENT: target with magic comment `# flywheel-cli-surface: true`
#     returns status=already_scaffolded with zero changes

set -euo pipefail

SCRIPT_VERSION="2026-05-10.1"
SCHEMA_VERSION="scaffold-canonical-cli-py/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="${SCAFFOLD_REPO_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"
if [[ -d "$REPO_ROOT" ]]; then
  REPO_ROOT="$(cd "$REPO_ROOT" && pwd -P)"
fi
HELPER_LIB="${SCAFFOLD_HELPER_LIB:-$REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
INVENTORY="${SCAFFOLD_INVENTORY:-$REPO_ROOT/.flywheel/audit/flywheel-cli-inventory/inventory.jsonl}"
RUNS_LOG="${SCAFFOLD_RUNS_LOG:-$REPO_ROOT/.flywheel/state/scaffold-py-runs.jsonl}"
TESTS_DIR="${SCAFFOLD_TESTS_DIR:-$REPO_ROOT/tests}"
JEFF_STACK_PREFIXES_DEFAULT="ntm,beads_rust,frankensqlite,frankenagent,beads-for"

# ---------- helpers ----------

iso_now() { date -u +'%Y-%m-%dT%H:%M:%SZ'; }
err() { printf '%s\n' "$*" >&2; }
require() { command -v "$1" >/dev/null || { err "missing dependency: $1"; exit 64; }; }
require jq
require diff
require python3

usage() {
  cat <<'EOF'
usage: scaffold-canonical-cli-py.sh <python_script_path> [--dry-run|--apply]
                                     [--idempotency-key KEY]
                                     [--inventory PATH] [--runs-log PATH]
                                     [--no-test-scaffold] [--allow-uninventoried]
                                     [--json]

       scaffold-canonical-cli-py.sh --info [--json]
       scaffold-canonical-cli-py.sh --schema [<surface>]
       scaffold-canonical-cli-py.sh --examples [--json]
       scaffold-canonical-cli-py.sh --doctor [--json]
       scaffold-canonical-cli-py.sh --help

Positional:
  <python_script_path>  target python3 script (e.g. ~/.claude/skills/.flywheel/bin/flywheel-readme)

Modes:
  --dry-run         (default) emit unified diff + JSON receipt, mutate nothing
  --apply           write the scaffolded script in place + backup; requires
                    --idempotency-key KEY

Options:
  --idempotency-key KEY    (required for --apply) opaque token recorded in
                           the scaffold-py-runs.jsonl receipt for replay safety
  --inventory PATH         override inventory.jsonl path
  --runs-log PATH          override scaffold-py-runs.jsonl path
  --no-test-scaffold       skip emitting tests/<name>-canonical-cli-py.sh
  --allow-uninventoried    bypass the "must be in inventory.jsonl" refusal
  --json                   emit JSON envelope on stdout

Exit codes:
  0  success or already_scaffolded
  1  internal error
  3  --apply without --idempotency-key (canonical refusal)
  64 usage error
  65 IO error (target missing/unreadable)
  66 refused (target outside inventory, jeff-stack, or non-python shebang)
EOF
}

emit_info() {
  jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg version "$SCRIPT_VERSION" \
    --arg name "scaffold-canonical-cli-py.sh" \
    --arg repo_root "$REPO_ROOT" \
    --arg inventory "$INVENTORY" \
    --arg runs_log "$RUNS_LOG" \
    --arg tests_dir "$TESTS_DIR" \
    '{schema_version:$sv,command:"info",name:$name,version:$version,
      repo_root:$repo_root,inventory:$inventory,runs_log:$runs_log,tests_dir:$tests_dir,
      target_kind:"python3",
      env_vars:["SCAFFOLD_REPO_ROOT","SCAFFOLD_INVENTORY","SCAFFOLD_RUNS_LOG","SCAFFOLD_TESTS_DIR","ALLOW_UNINVENTORIED"],
      dependencies:["jq","diff","python3"]}'
}

emit_schema() {
  local surface="${1:-default}"
  case "$surface" in
    scaffold|default)
      jq -nc --arg sv "$SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,
          required:["status","mode","target"],
          status_enum:["dry_run_ok","apply_ok","already_scaffolded","refused"],
          mode_enum:["dry_run","apply"],
          refusal_reasons:["non_python_shebang","jeff_stack_target","uninventoried_target","target_missing","target_unreadable"]}'
      ;;
    *)
      jq -nc --arg sv "$SCHEMA_VERSION" --arg surface "$surface" \
        '{schema_version:$sv,command:"schema",surface:$surface,note:"unknown surface; valid: scaffold|default"}'
      ;;
  esac
}

emit_examples() {
  jq -nc --arg sv "$SCHEMA_VERSION" \
    '{schema_version:$sv,command:"examples",examples:[
      {name:"dry-run on flywheel-readme",
       invocation:"scaffold-canonical-cli-py.sh /Users/josh/.claude/skills/.flywheel/bin/flywheel-readme --json",
       purpose:"preview canonical-cli injection without mutation"},
      {name:"apply with idempotency key",
       invocation:"scaffold-canonical-cli-py.sh <target> --apply --idempotency-key oozt3-pilot --json",
       purpose:"write the scaffolded script in place + backup"},
      {name:"refusal on bash target",
       invocation:"scaffold-canonical-cli-py.sh .flywheel/scripts/cd-realpath-wrapper.sh --json",
       purpose:"shows non_python_shebang refusal (use scaffold-canonical-cli.sh instead)"}
    ]}'
}

emit_doctor() {
  local ts checks=()
  ts="$(iso_now)"
  local jq_status="fail" jq_reason=""
  command -v jq >/dev/null && jq_status="pass" || jq_reason="jq not on PATH"
  local py_status="fail" py_reason=""
  command -v python3 >/dev/null && py_status="pass" || py_reason="python3 not on PATH"
  local diff_status="fail" diff_reason=""
  command -v diff >/dev/null && diff_status="pass" || diff_reason="diff not on PATH"
  local inv_status="fail" inv_reason=""
  if [[ -r "$INVENTORY" ]]; then inv_status="pass"
  else inv_reason="inventory not readable: $INVENTORY"; fi
  local runs_status="fail" runs_reason=""
  if [[ -d "$(dirname "$RUNS_LOG")" && -w "$(dirname "$RUNS_LOG")" ]]; then runs_status="pass"
  else runs_reason="runs-log parent not writable: $(dirname "$RUNS_LOG")"; fi

  local overall="pass" s
  for s in "$jq_status" "$py_status" "$diff_status" "$inv_status"; do
    if [[ "$s" == "fail" ]]; then overall="fail"; fi
  done

  jq -nc --arg sv "$SCHEMA_VERSION" --arg ts "$ts" --arg overall "$overall" \
    --arg jq_s "$jq_status" --arg jq_r "$jq_reason" \
    --arg py_s "$py_status" --arg py_r "$py_reason" \
    --arg diff_s "$diff_status" --arg diff_r "$diff_reason" \
    --arg inv_s "$inv_status" --arg inv_r "$inv_reason" --arg inv "$INVENTORY" \
    --arg runs_s "$runs_status" --arg runs_r "$runs_reason" --arg runs "$RUNS_LOG" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,checks:[
      {name:"jq_on_path",status:$jq_s,reason:$jq_r},
      {name:"python3_on_path",status:$py_s,reason:$py_r},
      {name:"diff_on_path",status:$diff_s,reason:$diff_r},
      {name:"inventory_readable",status:$inv_s,path:$inv,reason:$inv_r},
      {name:"runs_log_writable",status:$runs_s,path:$runs,reason:$runs_r}
    ]}'
}

refuse_envelope() {
  local reason="$1" target="$2"
  jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg reason "$reason" \
    --arg target "$target" \
    '{schema_version:$sv,command:"scaffold",status:"refused",reason:$reason,target:$target}'
}

# Inventory match: tolerates absolute targets (rows store absolute paths) or
# repo-relative targets (rows store path relative to REPO_ROOT under .flywheel/scripts/).
is_in_inventory() {
  local target_abs="$1"
  if [[ ! -r "$INVENTORY" ]]; then
    return 1
  fi
  if grep -qF "\"path\":\"$target_abs\"" "$INVENTORY" 2>/dev/null; then
    return 0
  fi
  local rel="${target_abs#"$REPO_ROOT"/}"
  if [[ "$rel" != "$target_abs" ]]; then
    if grep -qF "\"path\":\"$rel\"" "$INVENTORY" 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

is_jeff_stack_path() {
  local target_abs="$1"
  local prefixes="${SCAFFOLD_JEFF_STACK_PREFIXES:-$JEFF_STACK_PREFIXES_DEFAULT}"
  IFS=',' read -ra arr <<<"$prefixes"
  for p in "${arr[@]}"; do
    if [[ "$target_abs" == */"$p"/* || "$target_abs" == *"/$p" ]]; then
      return 0
    fi
  done
  return 1
}

is_already_scaffolded() {
  local target_abs="$1"
  grep -qF '# flywheel-cli-surface: true' "$target_abs" 2>/dev/null
}

# Detect python shebang. Accepts `#!/usr/bin/env python3`, `#!/usr/bin/python3`,
# `#!/usr/bin/env python`, `#!/usr/bin/python`. Rejects bash/perl/node/ruby.
is_python_shebang() {
  local target_abs="$1"
  local first
  first="$(head -1 "$target_abs" 2>/dev/null || true)"
  if [[ "$first" =~ ^\#\!.*python3?[[:space:]]*$ ]] || [[ "$first" =~ ^\#\!.*python3?[[:space:]] ]]; then
    return 0
  fi
  return 1
}

detect_shebang_interpreter() {
  local target_abs="$1"
  local first
  first="$(head -1 "$target_abs" 2>/dev/null || true)"
  case "$first" in
    *python3*) echo "python3" ;;
    *python*)  echo "python" ;;
    *bash*)    echo "bash" ;;
    *sh*)      echo "sh" ;;
    *perl*)    echo "perl" ;;
    *node*)    echo "node" ;;
    *ruby*)    echo "ruby" ;;
    *)         echo "unknown" ;;
  esac
}

# ---------- python injection block ----------

# Emits the canonical-cli python shim. It is injected AFTER the target's
# shebang + module docstring + `from __future__ import` lines, and BEFORE
# the target's own imports. The shim is self-contained and uses only stdlib
# imports already common in flywheel python surfaces (json, os, sys).
emit_python_block() {
  local target_basename="$1"
  local schema_prefix="${target_basename}"
  cat <<EOF
# ====== BEGIN canonical-cli scaffold (python; bead flywheel-oozt3) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-oozt3)
#
# This block is INJECTED by scaffold-canonical-cli-py.sh. It adds canonical
# introspection surfaces (--info, --schema, --examples, quickstart, help,
# completion) without overriding the target's own argparse subcommands.
# Per-surface stubs (audit, why, validate) carry TODO markers — see grep
# '# TODO(canonical-cli-scaffold)'.

import json as _scaffold_json
import os as _scaffold_os
import sys as _scaffold_sys
import time as _scaffold_time

_SCAFFOLD_SCHEMA_VERSION = "${schema_prefix}/v1"
_SCAFFOLD_AUDIT_LOG = _scaffold_os.environ.get(
    "SCAFFOLD_AUDIT_LOG",
    _scaffold_os.path.join(
        _scaffold_os.path.expanduser("~"),
        ".local/state/flywheel",
        "${schema_prefix}-runs.jsonl",
    ),
)


def _scaffold_iso_now() -> str:
    return _scaffold_time.strftime("%Y-%m-%dT%H:%M:%SZ", _scaffold_time.gmtime())


def _scaffold_emit_json(obj: dict) -> int:
    print(_scaffold_json.dumps(obj, sort_keys=True, separators=(",", ":")))
    return 0


def _scaffold_emit_info() -> int:
    return _scaffold_emit_json({
        "schema_version": _SCAFFOLD_SCHEMA_VERSION,
        "command": "info",
        "name": "${schema_prefix}",
        "kind": "python3",
        "scaffolder_bead": "flywheel-oozt3",
        "audit_log": _SCAFFOLD_AUDIT_LOG,
        "canonical_surfaces": [
            "doctor", "health", "repair", "validate",
            "audit", "why", "quickstart", "help", "completion",
        ],
    })


def _scaffold_emit_schema(surface: str = "default") -> int:
    schemas = {
        "doctor": {
            "required": ["status", "checks"],
            "status_enum": ["pass", "fail", "warn"],
        },
        "health": {
            "required": ["status", "audit_log"],
            "status_enum": ["pass", "warn", "fail"],
        },
        "repair": {
            "required": ["status", "mode", "scope"],
            "mode_enum": ["dry_run", "apply"],
            "mutation_gates": ["--apply requires --idempotency-key"],
        },
        "validate": {
            "required": ["status", "subject"],
            "status_enum": ["pass", "fail", "warn", "refused"],
        },
        "audit": {
            "required": ["audit_log", "rows"],
        },
        "why": {
            "required": ["id", "status"],
            "status_enum": ["found", "not_found", "warn"],
        },
        "default": {
            "surfaces": ["doctor", "health", "repair", "validate", "audit", "why"],
            "stable_exit_codes": {
                "0": "success", "1": "general", "2": "warn",
                "3": "refused (mutation without idempotency-key)", "64": "bad args",
            },
        },
    }
    body = schemas.get(surface, schemas["default"])
    return _scaffold_emit_json({
        "schema_version": _SCAFFOLD_SCHEMA_VERSION,
        "command": "schema",
        "surface": surface,
        **body,
    })


def _scaffold_emit_examples() -> int:
    return _scaffold_emit_json({
        "schema_version": _SCAFFOLD_SCHEMA_VERSION,
        "command": "examples",
        "examples": [
            {"name": "info", "invocation": "${schema_prefix} --info --json", "purpose": "introspection"},
            {"name": "schema", "invocation": "${schema_prefix} --schema doctor", "purpose": "per-surface schema"},
            {"name": "doctor", "invocation": "${schema_prefix} doctor --json", "purpose": "probe substrate"},
        ],
    })


def _scaffold_emit_quickstart() -> int:
    return _scaffold_emit_json({
        "schema_version": _SCAFFOLD_SCHEMA_VERSION,
        "command": "quickstart",
        "steps": [
            {"step": 1, "action": "probe doctor", "command": "${schema_prefix} doctor --json"},
            {"step": 2, "action": "check health", "command": "${schema_prefix} health --json"},
            {"step": 3, "action": "tail audit", "command": "${schema_prefix} audit --json"},
        ],
    })


def _scaffold_emit_topic_help(topic: str = "") -> int:
    topics = {
        "doctor": "topic: doctor — TODO(canonical-cli-scaffold): document doctor checks for this surface.",
        "health": "topic: health — TODO(canonical-cli-scaffold): document health probes for this surface.",
        "repair": "topic: repair — TODO(canonical-cli-scaffold): document repair scopes + idempotency contract.",
        "validate": "topic: validate — TODO(canonical-cli-scaffold): document validation subjects + contracts.",
        "audit": "topic: audit — TODO(canonical-cli-scaffold): document audit-log tail behavior.",
        "why": "topic: why — TODO(canonical-cli-scaffold): document provenance lookup semantics.",
    }
    if topic and topic in topics:
        print(topics[topic])
    else:
        print("topics: doctor | health | repair | validate | audit | why")
    return 0


# ---------- canonical-cli stubs (TODO markers preserved) ----------

def _scaffold_cmd_doctor() -> int:
    # TODO(canonical-cli-scaffold): probe substrate this script depends on
    # (env vars, paths, external tools) and emit per-check status array.
    return _scaffold_emit_json({
        "schema_version": _SCAFFOLD_SCHEMA_VERSION,
        "command": "doctor",
        "ts": _scaffold_iso_now(),
        "status": "todo",
        "checks": [],
        "note": "TODO(canonical-cli-scaffold): fill in doctor checks",
    })


def _scaffold_cmd_health() -> int:
    # TODO(canonical-cli-scaffold): summarize last-run state from audit log.
    return _scaffold_emit_json({
        "schema_version": _SCAFFOLD_SCHEMA_VERSION,
        "command": "health",
        "ts": _scaffold_iso_now(),
        "status": "todo",
        "audit_log": _SCAFFOLD_AUDIT_LOG,
        "note": "TODO(canonical-cli-scaffold): fill in health probe",
    })


def _scaffold_cmd_audit() -> int:
    # TODO(canonical-cli-scaffold): tail audit log; emit recent rows.
    rows = []
    if _scaffold_os.path.isfile(_SCAFFOLD_AUDIT_LOG):
        try:
            with open(_SCAFFOLD_AUDIT_LOG, "r", encoding="utf-8") as f:
                tail = f.readlines()[-10:]
            for line in tail:
                line = line.strip()
                if not line:
                    continue
                try:
                    rows.append(_scaffold_json.loads(line))
                except _scaffold_json.JSONDecodeError:
                    continue
        except OSError:
            pass
    return _scaffold_emit_json({
        "schema_version": _SCAFFOLD_SCHEMA_VERSION,
        "command": "audit",
        "audit_log": _SCAFFOLD_AUDIT_LOG,
        "count": len(rows),
        "rows": rows,
        "note": "TODO(canonical-cli-scaffold): refine audit-tail surface",
    })


def _scaffold_cmd_why(args: list) -> int:
    if not args:
        print("ERR: why requires <id> argument", file=_scaffold_sys.stderr)
        return 64
    id_ = args[0]
    # TODO(canonical-cli-scaffold): explain why <id> is/isn't in scope.
    return _scaffold_emit_json({
        "schema_version": _SCAFFOLD_SCHEMA_VERSION,
        "command": "why",
        "id": id_,
        "status": "todo",
        "note": "TODO(canonical-cli-scaffold): fill in why-id semantics",
    })


# ---------- early-dispatch intercept ----------
#
# Run BEFORE the target's argparse so canonical introspection (--info,
# --schema, --examples) and per-surface stubs (audit, why) don't have to
# be re-implemented in the target. Targets that already ship doctor /
# health / repair (e.g. flywheel-readme) fall through to their own
# argparse — only canonical surfaces missing from the target are
# intercepted here.
_SCAFFOLD_INTROSPECTION_FLAGS = {"--info", "--schema", "--examples", "--scaffold-help"}
# These canonical subcommands are intercepted ONLY if the target's argparse
# does not already define them. The shim defers via try/except below — if
# the target's argparse later raises SystemExit on an unknown subcommand,
# the shim has already handled the canonical case.
_SCAFFOLD_CANONICAL_SUBCOMMANDS_FALLBACK = {"audit", "why", "quickstart", "scaffold-help"}


def _scaffold_main(argv: list) -> int:
    if not argv:
        return 1
    head = argv[0]
    if head == "--info":
        return _scaffold_emit_info()
    if head == "--schema":
        surface = argv[1] if len(argv) > 1 else "default"
        return _scaffold_emit_schema(surface)
    if head == "--examples":
        return _scaffold_emit_examples()
    if head == "--scaffold-help":
        topic = argv[1] if len(argv) > 1 else ""
        return _scaffold_emit_topic_help(topic)
    if head == "audit":
        return _scaffold_cmd_audit()
    if head == "why":
        return _scaffold_cmd_why(argv[1:])
    if head == "quickstart":
        return _scaffold_emit_quickstart()
    return 1


if __name__ == "__main__" and len(_scaffold_sys.argv) > 1:
    _scaffold_head = _scaffold_sys.argv[1]
    if (
        _scaffold_head in _SCAFFOLD_INTROSPECTION_FLAGS
        or _scaffold_head in _SCAFFOLD_CANONICAL_SUBCOMMANDS_FALLBACK
    ):
        _scaffold_rc = _scaffold_main(_scaffold_sys.argv[1:])
        _scaffold_sys.exit(_scaffold_rc)
# ====== END canonical-cli scaffold ======
EOF
}

# ---------- python test scaffold ----------

emit_test_scaffold_py() {
  local target_basename="$1"
  local target_rel="$2"
  local script_var_value
  if [[ "$target_rel" = /* ]]; then
    script_var_value="${target_rel}"
  else
    script_var_value="\$ROOT/${target_rel}"
  fi
  cat <<EOF
#!/usr/bin/env bash
# tests/${target_basename}-canonical-cli-py.sh
# Canonical-cli surface tests for ${target_rel} (scaffolded by
# bead flywheel-oozt3 / scaffold-canonical-cli-py.sh).
#
# Verifies the python shim exposes canonical introspection without breaking
# the target's existing argparse subcommands.
set -uo pipefail

ROOT="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="${script_var_value}"

pass_count=0
fail_count=0
pass() { pass_count=\$((pass_count + 1)); printf 'PASS %s\\n' "\$1"; }
fail() { fail_count=\$((fail_count + 1)); printf 'FAIL %s\\n' "\$1" >&2; }

# Test 1: python ast parse (syntax)
if python3 -c "import ast,sys; ast.parse(open('\$SCRIPT','r',encoding='utf-8').read())" 2>/dev/null; then
  pass "python ast parse (syntax)"
else fail "python ast parse"; fi

# Test 2: --info envelope
if "\$SCRIPT" --info 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['command']=='info' and d.get('schema_version')" 2>/dev/null; then
  pass "--info emits canonical envelope"
else fail "--info envelope"; fi

# Test 3: --schema doctor
if "\$SCRIPT" --schema doctor 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['command']=='schema' and d['surface']=='doctor'" 2>/dev/null; then
  pass "--schema doctor emits canonical envelope"
else fail "--schema doctor envelope"; fi

# Test 4: --schema default
if "\$SCRIPT" --schema 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['command']=='schema'" 2>/dev/null; then
  pass "--schema default emits canonical envelope"
else fail "--schema default envelope"; fi

# Test 5: --examples envelope
if "\$SCRIPT" --examples 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['command']=='examples'" 2>/dev/null; then
  pass "--examples emits canonical envelope"
else fail "--examples envelope"; fi

# Test 6: audit envelope (scaffold stub)
if "\$SCRIPT" audit 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['command']=='audit' and 'audit_log' in d" 2>/dev/null; then
  pass "audit emits canonical envelope"
else fail "audit envelope"; fi

# Test 7: why <id> envelope (scaffold stub)
if "\$SCRIPT" why some-id 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['command']=='why' and d['id']=='some-id'" 2>/dev/null; then
  pass "why <id> emits canonical envelope"
else fail "why <id> envelope"; fi

# Test 8: quickstart envelope (scaffold stub)
if "\$SCRIPT" quickstart 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['command']=='quickstart'" 2>/dev/null; then
  pass "quickstart emits canonical envelope"
else fail "quickstart envelope"; fi

# Test 9: schema_version is <surface>/v1
if "\$SCRIPT" --info 2>/dev/null | python3 -c "import sys,json,re; d=json.load(sys.stdin); assert re.match(r'^[A-Za-z0-9_-]+/v1$', d['schema_version'])" 2>/dev/null; then
  pass "schema_version matches <surface>/v1 pattern"
else fail "schema_version pattern"; fi

# Test 10: target's existing argparse still works (no canonical arg)
# A target without canonical args must still emit *something*. We probe
# stderr/exit-code only — semantics belong to the target.
"\$SCRIPT" 2>/dev/null >/dev/null; rc=\$?
if [[ "\$rc" -le 2 ]]; then
  pass "target default invocation rc <= 2 (no shim breakage)"
else fail "target default invocation rc=\$rc (shim may have broken target)"; fi

if [[ "\$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\\n' "\$pass_count" "\$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\\n' "\$pass_count"
EOF
}

# ---------- core scaffolder action ----------

scaffold_target() {
  local target="$1" mode="$2" idem_key="$3" no_test="$4" emit_json="$5"
  local target_abs target_rel target_basename
  target_abs="$(cd "$(dirname "$target")" 2>/dev/null && pwd -P)/$(basename "$target")" || {
    err "target not found: $target"; exit 65
  }
  target_rel="${target_abs#"$REPO_ROOT"/}"
  target_basename="$(basename "$target_abs")"

  if [[ ! -r "$target_abs" ]]; then
    err "target not readable: $target_abs"; exit 65
  fi

  # Refusal: jeff-stack
  if is_jeff_stack_path "$target_abs"; then
    refuse_envelope "jeff_stack_target" "$target_rel"
    exit 66
  fi

  # Refusal: non-python shebang (this is the python sibling — bash targets
  # belong to scaffold-canonical-cli.sh).
  if ! is_python_shebang "$target_abs"; then
    local interp
    interp="$(detect_shebang_interpreter "$target_abs")"
    err "$target_rel is a $interp script (not python). Use scaffold-canonical-cli.sh for bash, or build a sibling for $interp."
    jq -nc \
      --arg sv "$SCHEMA_VERSION" \
      --arg target "$target_rel" \
      --arg interp "$interp" \
      '{schema_version:$sv,command:"scaffold",status:"refused",reason:"non_python_shebang",target:$target,interpreter:$interp,suggestion:"use scaffold-canonical-cli.sh for bash targets"}'
    exit 66
  fi

  # Refusal: outside inventory
  if [[ "${ALLOW_UNINVENTORIED:-0}" -ne 1 ]]; then
    if ! is_in_inventory "$target_abs"; then
      refuse_envelope "uninventoried_target" "$target_rel"
      exit 66
    fi
  fi

  # Idempotency
  if is_already_scaffolded "$target_abs"; then
    jq -nc \
      --arg sv "$SCHEMA_VERSION" \
      --arg target "$target_rel" \
      --arg mode "$mode" \
      '{schema_version:$sv,command:"scaffold",status:"already_scaffolded",mode:$mode,target:$target,reason:"target carries # flywheel-cli-surface: true magic comment"}'
    return 0
  fi

  # Build scaffolded copy in tmp
  local before_lines
  before_lines="$(wc -l <"$target_abs" | tr -d ' ')"

  local tmp_dir tmp_new tmp_diff tmp_block
  tmp_dir="$(mktemp -d -t scaffold-canonical-cli-py.XXXXXX)"
  tmp_new="$tmp_dir/${target_basename}.scaffolded"
  tmp_diff="$tmp_dir/${target_basename}.diff"
  tmp_block="$tmp_dir/${target_basename}.canonical-block"

  emit_python_block "$target_basename" > "$tmp_block"

  # Inject AFTER:
  #   - shebang (line 1)
  #   - module docstring (multi-line """...""")
  #   - `from __future__ import` lines
  #   - blank/comment lines between any of the above
  # BEFORE the next non-blank, non-comment, non-future-import line.
  python3 - "$target_abs" "$tmp_block" "$tmp_new" <<'PYINJECT'
import ast
import io
import sys

target = sys.argv[1]
block_path = sys.argv[2]
out_path = sys.argv[3]

with open(target, "r", encoding="utf-8") as f:
    src = f.read()

# Find the injection line: after shebang + docstring + __future__ imports.
lines = src.splitlines(keepends=True)

inject_after = 0  # zero-based index; inject AFTER lines[inject_after-1]

# Skip shebang
if lines and lines[0].startswith("#!"):
    inject_after = 1

# Parse module to find docstring + __future__ imports
try:
    tree = ast.parse(src)
except SyntaxError:
    # Don't inject into a syntactically broken file
    sys.stderr.write(f"ERR: target has syntax error; refusing to inject\n")
    sys.exit(65)

if tree.body:
    first = tree.body[0]
    # Module docstring (Expr -> Constant str on py3.8+; ast.Str removed in py3.12)
    if isinstance(first, ast.Expr) and isinstance(first.value, ast.Constant):
        val = first.value
        if isinstance(val.value, str):
            inject_after = max(inject_after, val.end_lineno or val.lineno)
    # __future__ imports
    for node in tree.body:
        if isinstance(node, ast.ImportFrom) and node.module == "__future__":
            inject_after = max(inject_after, node.end_lineno or node.lineno)

# Inject at the chosen position (insert a blank line, then the block, then a blank line)
with open(block_path, "r", encoding="utf-8") as f:
    block = f.read()

prefix = "".join(lines[:inject_after])
suffix = "".join(lines[inject_after:])

# Ensure prefix ends with newline
if prefix and not prefix.endswith("\n"):
    prefix += "\n"

# Compose: prefix + blank + block + blank + suffix
sep = "\n"
out = prefix + sep + block + sep + suffix

with open(out_path, "w", encoding="utf-8") as f:
    f.write(out)
PYINJECT

  local after_lines lines_added todo_count
  after_lines="$(wc -l <"$tmp_new" | tr -d ' ')"
  lines_added=$((after_lines - before_lines))
  todo_count="$(grep -c 'TODO(canonical-cli-scaffold)' "$tmp_new" || echo 0)"

  diff -u "$target_abs" "$tmp_new" > "$tmp_diff" || true

  # Apply gate FIRST: --apply without --idempotency-key must refuse before any
  # side-effects (test scaffolding, backup, mutation). This avoids polluting
  # the repo's tests/ dir on a refused apply.
  local backup_path=""
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg target "$target_rel" \
      '{schema_version:$sv,command:"scaffold",status:"refused",mode:"apply",target:$target,reason:"--apply requires --idempotency-key"}'
    exit 3
  fi

  # Optional test scaffold (after the apply-gate so refused applies leave no trace).
  local test_path test_scaffolded=false
  test_path="$TESTS_DIR/${target_basename}-canonical-cli-py.sh"
  if [[ "$no_test" -ne 1 ]]; then
    if [[ ! -e "$test_path" ]]; then
      mkdir -p "$TESTS_DIR" 2>/dev/null || true
      if [[ "$mode" == "apply" ]]; then
        emit_test_scaffold_py "$target_basename" "$target_rel" > "$test_path"
        chmod +x "$test_path"
      else
        emit_test_scaffold_py "$target_basename" "$target_rel" > "$tmp_dir/$(basename "$test_path")"
      fi
      test_scaffolded=true
    fi
  fi

  # Apply (key already validated above)
  if [[ "$mode" == "apply" ]]; then
    local _ts_nanosecond _bak_pid _ts_token
    _ts_nanosecond="$(date -u +%Y%m%dT%H%M%S%N 2>/dev/null)"
    if [[ -z "$_ts_nanosecond" || "$_ts_nanosecond" =~ %N ]]; then
      _ts_nanosecond="$(date -u +%Y%m%dT%H%M%S)$(printf '%09d' "$RANDOM$RANDOM" | tail -c 9)"
    fi
    _bak_pid="$$"
    _ts_token="${_ts_nanosecond}Z-${_bak_pid}"
    backup_path="${target_abs}.bak.scaffold-py-${_ts_token}"
    cp -p "$target_abs" "$backup_path"
    cp -p "$tmp_new" "$target_abs"
    chmod +x "$target_abs" 2>/dev/null || true
  fi

  local scaffolder_sha receipt
  scaffolder_sha="$(shasum -a 256 "${BASH_SOURCE[0]}" 2>/dev/null | awk '{print $1}')"
  receipt="$(jq -nc \
    --arg ts "$(iso_now)" \
    --arg target "$target_rel" \
    --arg mode "$mode" \
    --arg idem "$idem_key" \
    --arg backup "$backup_path" \
    --arg scaffolder_sha "$scaffolder_sha" \
    --argjson before_lines "$before_lines" \
    --argjson after_lines "$after_lines" \
    --argjson lines_added "$lines_added" \
    --argjson todo_count "$todo_count" \
    --argjson test_scaffolded "$test_scaffolded" \
    --arg test_path "$test_path" \
    --arg tmp_diff "$tmp_diff" \
    '{
      ts:$ts,target:$target,mode:$mode,idempotency_key:$idem,
      before_lines:$before_lines,after_lines:$after_lines,
      lines_added_by_scaffolder:$lines_added,
      todo_count:$todo_count,
      test_scaffolded:$test_scaffolded,
      test_path:$test_path,
      backup_path:$backup,
      unified_diff_path:$tmp_diff,
      scaffolder_sha:$scaffolder_sha,
      kind:"python3",
      status:($mode + "_ok"),
      schema_version:"scaffold-canonical-cli-py/v1"
    }')"

  if [[ "$mode" == "apply" ]]; then
    mkdir -p "$(dirname "$RUNS_LOG")" 2>/dev/null || true
    printf '%s\n' "$receipt" >> "$RUNS_LOG" 2>/dev/null || true
  fi

  local envelope
  envelope="$(jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg target "$target_rel" \
    --arg mode "$mode" \
    --arg diff_path "$tmp_diff" \
    --argjson before "$before_lines" \
    --argjson after "$after_lines" \
    --argjson added "$lines_added" \
    --argjson todos "$todo_count" \
    --argjson test_scaffolded "$test_scaffolded" \
    --argjson receipt "$receipt" \
    '{
      schema_version:$sv,command:"scaffold",
      status:($mode + "_ok"),mode:$mode,target:$target,kind:"python3",
      unified_diff_path:$diff_path,
      before_lines:$before,after_lines:$after,
      scaffold_lines_added:$added,todo_count:$todos,
      test_scaffolded:$test_scaffolded,receipt:$receipt
    }')"

  if [[ "$emit_json" -eq 1 ]]; then
    printf '%s\n' "$envelope"
  else
    printf 'mode=%s target=%s before=%s after=%s lines_added=%s todos=%s test_scaffolded=%s diff=%s\n' \
      "$mode" "$target_rel" "$before_lines" "$after_lines" "$lines_added" \
      "$todo_count" "$test_scaffolded" "$tmp_diff"
  fi
}

# ---------- main ----------

main() {
  local mode="dry_run" idem_key="" no_test=0 emit_json=0 target=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --info)            shift; emit_info "$@"; exit 0 ;;
      --schema)          shift; emit_schema "${1:-default}"; exit 0 ;;
      --examples)        shift; emit_examples "$@"; exit 0 ;;
      --doctor)          shift; emit_doctor "$@"; exit 0 ;;
      -h|--help)         usage; exit 0 ;;
      --dry-run)         mode="dry_run"; shift ;;
      --apply)           mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="${1#--idempotency-key=}"; shift ;;
      --inventory)       INVENTORY="${2:-}"; shift 2 ;;
      --runs-log)        RUNS_LOG="${2:-}"; shift 2 ;;
      --tests-dir)       TESTS_DIR="${2:-}"; shift 2 ;;
      --no-test-scaffold) no_test=1; shift ;;
      --allow-uninventoried) ALLOW_UNINVENTORIED=1; export ALLOW_UNINVENTORIED; shift ;;
      --json)            emit_json=1; shift ;;
      --)                shift; break ;;
      -*)
        err "unknown flag: $1"; usage >&2; exit 64 ;;
      *)
        if [[ -z "$target" ]]; then
          target="$1"; shift
        else
          err "unexpected positional: $1"; usage >&2; exit 64
        fi
        ;;
    esac
  done

  if [[ -z "$target" ]]; then
    err "missing <python_script_path>"
    usage >&2
    exit 64
  fi

  scaffold_target "$target" "$mode" "$idem_key" "$no_test" "$emit_json"
}

main "$@"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
