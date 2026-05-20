#!/usr/bin/env bash
set -u

RECIPES_FILE="${SLB_RECIPES_FILE:-$HOME/.flywheel/slb-recipes.json}"
AUDIT_LOG="${SLB_AUDIT_LOG:-$HOME/.local/state/flywheel/slb-execution-audit.jsonl}"
SNAPSHOT_DIR="${SLB_SNAPSHOT_DIR:-$HOME/.local/state/flywheel/slb-snapshots}"
EXISTING_DCG="${SLB_EXISTING_DCG:-dcg}"
INPUT_JSON="$(cat)"

passthrough_json() {
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse"}}'
}

run_existing_dcg() {
  if [ "${SLB_SKIP_EXISTING_DCG:-0}" = "1" ]; then
    passthrough_json
    return 0
  fi

  if [ -z "${SLB_EXISTING_DCG:-}" ] && [ "${SLB_DELEGATE_TO_DCG:-0}" != "1" ]; then
    passthrough_json
    return 0
  fi

  if command -v "$EXISTING_DCG" >/dev/null 2>&1; then
    printf '%s' "$INPUT_JSON" | "$EXISTING_DCG"
    return $?
  fi

  passthrough_json
  return 0
}

if ! DECISION_JSON="$(
  INPUT_JSON="$INPUT_JSON" \
  RECIPES_FILE="$RECIPES_FILE" \
  AUDIT_LOG="$AUDIT_LOG" \
  SNAPSHOT_DIR="$SNAPSHOT_DIR" \
  TMPDIR="${TMPDIR:-/tmp}" \
  python3 <<'PY'
import datetime as dt
import hashlib
import json
import os
import re
import shlex
import subprocess
import sys
from pathlib import Path

SCHEMA = "flywheel.slb.recipes.v1"
AUDIT_SCHEMA = "flywheel.slb.execution_audit.v1"


def emit(payload):
    print(json.dumps(payload, separators=(",", ":"), sort_keys=True))


def fall_through(reason, recipe=None, stage=None):
    payload = {"outcome": "fall_through", "reason": reason}
    if recipe:
        payload["recipe_id"] = recipe.get("id")
    if stage:
        payload["stage"] = stage
    emit(payload)
    sys.exit(0)


def hook_allow(recipe_id, replacement):
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "permissionDecisionReason": f"SLB safe execution verified: {recipe_id}",
            "updatedInput": {"command": replacement},
        }
    }


def load_input():
    raw = os.environ.get("INPUT_JSON", "")
    try:
        data = json.loads(raw or "{}")
    except json.JSONDecodeError:
        fall_through("invalid_hook_input")
    if data.get("tool_name") not in (None, "Bash"):
        fall_through("not_bash")
    command = ((data.get("tool_input") or {}).get("command") or "").strip()
    if not command:
        fall_through("empty_command")
    cwd = data.get("cwd") or os.getcwd()
    return data, command, cwd


def validate_recipe(recipe):
    if not isinstance(recipe, dict):
        return False
    for key in ("id", "command_pattern", "safe_execution_protocol", "fallback_to_prompt_if"):
        if key not in recipe:
            return False
    protocol = recipe.get("safe_execution_protocol")
    if not isinstance(protocol, dict):
        return False
    for key in ("pre_snapshot", "execute", "post_verify"):
        if not protocol.get(key):
            return False
    if not isinstance(recipe.get("fallback_to_prompt_if"), list) or not recipe["fallback_to_prompt_if"]:
        return False
    try:
        re.compile(recipe["command_pattern"])
    except re.error:
        return False
    return True


def load_recipes(path):
    try:
        with open(path, "r", encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, json.JSONDecodeError):
        fall_through("invalid_or_missing_recipes_file")
    if data.get("schema_version") != SCHEMA or not isinstance(data.get("recipes"), list):
        fall_through("unsupported_recipes_schema")
    if not all(validate_recipe(recipe) for recipe in data["recipes"]):
        fall_through("malformed_recipe_entry")
    return data["recipes"]


def shell_quote(value):
    return shlex.quote(str(value))


def split_command(command):
    return shlex.split(command)


def tmpdir_root():
    return Path(os.environ.get("TMPDIR") or "/tmp").expanduser().resolve()


def resolve_token_path(token):
    raw = token
    tmp = os.environ.get("TMPDIR") or "/tmp"
    if raw == "$TMPDIR":
        raw = tmp
    elif raw.startswith("$TMPDIR/"):
        raw = str(Path(tmp) / raw[len("$TMPDIR/"):])
    return str(Path(raw).expanduser().resolve())


def is_under(path, root):
    try:
        Path(path).resolve().relative_to(Path(root).resolve())
        return True
    except ValueError:
        return False


def parse_values(recipe_id, command, cwd):
    parts = split_command(command)
    values = {"cwd": cwd, "command": command}
    if recipe_id == "git-branch-delete-with-sha-suffix" and len(parts) >= 4:
        values["branch"] = parts[3]
    elif recipe_id == "git-worktree-remove-tmp":
        target = parts[-1]
        values["target"] = resolve_token_path(target)
    elif recipe_id in {"rm-rf-tmpdir", "rm-rf-stale-mktemp-dirs"} and len(parts) >= 3:
        values["target"] = resolve_token_path(parts[-1])
    elif recipe_id == "gh-api-delete-branch-protection":
        path = parts[-1].strip("\"'")
        match = re.fullmatch(r"repos/([^/]+)/([^/]+)/branches/([^/]+)/protection", path)
        if match:
            values.update({"owner": match.group(1), "repo": match.group(2), "branch": match.group(3)})
    elif recipe_id == "git-stash-drop-older-than-30d" and len(parts) >= 4:
        values["stash_ref"] = parts[3]
    elif recipe_id == "git-reset-hard-to-origin" and len(parts) >= 4:
        target = parts[3]
        values["target_ref"] = target
        if target.startswith("origin/"):
            values["branch"] = target.split("/", 1)[1]
    elif recipe_id == "find-delete-stale-temp" and len(parts) >= 2:
        values["target"] = resolve_token_path(parts[1])
    return values


def preconditions_ok(recipe, command, cwd, values):
    recipe_id = recipe["id"]
    if recipe_id in {"rm-rf-tmpdir", "rm-rf-stale-mktemp-dirs", "find-delete-stale-temp"}:
        target = values.get("target", "")
        if not target or not is_under(target, tmpdir_root()):
            return False, "target_resolves_outside_TMPDIR"
    if recipe_id == "git-worktree-remove-tmp":
        target = values.get("target", "")
        if not target:
            return False, "missing_worktree_target"
        allowed = is_under(target, tmpdir_root()) or re.match(r"^/var/folders/.+/T/", target)
        if not allowed:
            return False, "target_resolves_outside_temp"
    if recipe_id == "git-reset-hard-to-origin":
        branch = values.get("branch")
        if not branch:
            return False, "missing_origin_branch"
        current = subprocess.run(
            ["git", "branch", "--show-current"],
            cwd=cwd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=False,
        ).stdout.strip()
        if current != branch:
            return False, "own_branch_scope_check_failed"
    if recipe_id == "git-stash-drop-older-than-30d":
        stash_ref = values.get("stash_ref")
        if not stash_ref:
            return False, "missing_stash_ref"
        age = subprocess.run(
            ["git", "log", "-g", "-1", "--format=%ct", stash_ref],
            cwd=cwd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        if age.returncode != 0:
            return False, "pre_snapshot_fails"
        try:
            created = int(age.stdout.strip())
        except (IndexError, ValueError):
            return False, "stash_age_unknown"
        now = int(dt.datetime.now(dt.timezone.utc).timestamp())
        if now - created < 30 * 24 * 60 * 60:
            return False, "stash_younger_than_30d"
        stash_sha = subprocess.run(
            ["git", "rev-parse", "--verify", stash_ref],
            cwd=cwd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        if stash_sha.returncode != 0:
            return False, "pre_snapshot_fails"
        values["stash_sha"] = stash_sha.stdout.strip()
    return True, ""


def command_sha(command):
    return hashlib.sha256(command.encode("utf-8")).hexdigest()


def idempotency_key(recipe_id, command, cwd):
    return hashlib.sha256(f"{recipe_id}\0{cwd}\0{command}".encode("utf-8")).hexdigest()


def already_successful(audit_log, key):
    try:
        with open(audit_log, "r", encoding="utf-8") as handle:
            for line in handle:
                try:
                    row = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if row.get("idempotency_key") == key and row.get("outcome") == "success":
                    return True
    except OSError:
        return False
    return False


def substitute(template, values):
    rendered = str(template)
    for key, value in values.items():
        rendered = rendered.replace(f"<{key}>", shell_quote(value))
    return rendered


def append_audit(audit_log, row):
    if not audit_log:
        return
    path = Path(audit_log)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, separators=(",", ":"), sort_keys=True) + "\n")


def run_shell(command, cwd, capture_path=None):
    result = subprocess.run(
        command,
        cwd=cwd,
        shell=True,
        executable="/bin/bash",
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if capture_path:
        Path(capture_path).write_text(result.stdout, encoding="utf-8")
        Path(str(capture_path) + ".stderr").write_text(result.stderr, encoding="utf-8")
    return result


input_data, command_text, cwd = load_input()
recipes = load_recipes(os.environ.get("RECIPES_FILE", ""))
matched = None
for candidate in recipes:
    if re.search(candidate["command_pattern"], command_text):
        matched = candidate
        break
if not matched:
    fall_through("no_recipe_match")

recipe_id = matched["id"]
values = parse_values(recipe_id, command_text, cwd)
if "branch" not in values and recipe_id == "git-branch-delete-with-sha-suffix":
    fall_through("missing_branch", matched, "precondition")

ok, precondition_reason = preconditions_ok(matched, command_text, cwd, values)
if not ok:
    fall_through(precondition_reason, matched, "precondition")

audit_log = os.environ.get("AUDIT_LOG", "")
key = idempotency_key(recipe_id, command_text, cwd)
if already_successful(audit_log, key):
    replacement = f"printf '%s\\n' {shell_quote('SLB already executed: ' + recipe_id)}"
    emit({"outcome": "already_executed", "hook": hook_allow(recipe_id, replacement)})
    sys.exit(0)

snapshot_dir = Path(os.environ.get("SNAPSHOT_DIR", ""))
snapshot_dir.mkdir(parents=True, exist_ok=True)
ts = dt.datetime.now(dt.timezone.utc).replace(microsecond=0).strftime("%Y%m%dT%H%M%SZ")
snapshot_path = snapshot_dir / f"{recipe_id}-{ts}-{command_sha(command_text)[:12]}.snapshot"
values.update({"ts": ts, "snapshot_path": str(snapshot_path), "command_sha256": command_sha(command_text)})
protocol = matched["safe_execution_protocol"]

base_audit = {
    "schema_version": AUDIT_SCHEMA,
    "ts": dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "recipe_id": recipe_id,
    "command_sha256": command_sha(command_text),
    "command_pattern": matched["command_pattern"],
    "cwd": cwd,
    "snapshot_path": str(snapshot_path),
    "idempotency_key": key,
}

pre_cmd = substitute(protocol["pre_snapshot"], values)
pre = run_shell(pre_cmd, cwd, snapshot_path)
if pre.returncode != 0:
    row = dict(base_audit, outcome="snapshot_failed", stage="pre_snapshot", rc=pre.returncode)
    append_audit(audit_log, row)
    fall_through("pre_snapshot_fails", matched, "pre_snapshot")

exec_cmd = substitute(protocol["execute"], values)
executed = run_shell(exec_cmd, cwd)
if executed.returncode != 0:
    row = dict(base_audit, outcome="execute_failed", stage="execute", rc=executed.returncode)
    append_audit(audit_log, row)
    fall_through("execute_returns_nonzero", matched, "execute")

verify_cmd = substitute(protocol["post_verify"], values)
verify = run_shell(verify_cmd, cwd)
if verify.returncode != 0:
    row = dict(base_audit, outcome="verify_failed", stage="post_verify", rc=verify.returncode)
    append_audit(audit_log, row)
    fall_through("post_verify_fails", matched, "post_verify")

row = dict(base_audit, outcome="success", stage="complete", rc=0)
append_audit(audit_log, row)
replacement = f"printf '%s\\n' {shell_quote('SLB already executed and verified: ' + recipe_id)}"
emit({"outcome": "success", "hook": hook_allow(recipe_id, replacement)})
PY
)"; then
  run_existing_dcg
  exit $?
fi

OUTCOME="$(printf '%s' "$DECISION_JSON" | jq -r '.outcome // "fall_through"' 2>/dev/null || printf 'fall_through')"
case "$OUTCOME" in
  success|already_executed)
    printf '%s\n' "$DECISION_JSON" | jq -c '.hook'
    exit 0
    ;;
  *)
    run_existing_dcg
    exit $?
    ;;
esac
