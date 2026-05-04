#!/usr/bin/env python3
import argparse
import datetime as dt
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


SCHEMA_VERSION = "codex-hook-parity/v1"
DEFAULT_STATE_DIR = Path.home() / ".local/state/flywheel/codex-hook-parity"
DEFAULT_CLAUDE_SETTINGS = Path.home() / ".claude/settings.json"
DEFAULT_CODEX_CONFIG = Path.home() / ".codex/config.toml"
DEFAULT_CODEX_HOOKS = Path.home() / ".codex/hooks.json"


def utc_now():
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0)


def parse_ts(value):
    if not value:
        return None
    if value.endswith("Z"):
        value = value[:-1] + "+00:00"
    parsed = dt.datetime.fromisoformat(value)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=dt.timezone.utc)
    return parsed.astimezone(dt.timezone.utc)


def iso(value):
    return value.astimezone(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def read_json(path, default):
    try:
        with open(path, "r", encoding="utf-8") as handle:
            return json.load(handle)
    except FileNotFoundError:
        return default
    except json.JSONDecodeError as exc:
        raise SystemExit(f"invalid JSON at {path}: {exc}")


def atomic_write_json(path, payload):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(f".{path.name}.tmp.{os.getpid()}")
    with open(tmp, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, sort_keys=False)
        handle.write("\n")
    os.replace(tmp, path)


def command_basename(command):
    stripped = command.strip()
    if not stripped:
        return ""
    first = stripped.split()[0]
    return Path(first.replace("~", str(Path.home()))).name


def is_bash_matcher(matcher):
    return matcher in ("Bash", "^Bash$", ".*Bash.*")


def find_dcg_pretool_hooks(settings):
    rows = []
    for idx, group in enumerate(settings.get("hooks", {}).get("PreToolUse", []) or []):
        matcher = group.get("matcher", "")
        if not is_bash_matcher(matcher):
            continue
        for hook_idx, hook in enumerate(group.get("hooks", []) or []):
            command = hook.get("command", "")
            if command_basename(command) == "dcg":
                rows.append(
                    {
                        "event": "PreToolUse",
                        "matcher": matcher,
                        "group_index": idx,
                        "hook_index": hook_idx,
                        "command": command,
                        "timeout": hook.get("timeout"),
                    }
                )
    return rows


def feature_enabled_from_config(path):
    in_features = False
    enabled = None
    try:
        lines = Path(path).read_text(encoding="utf-8").splitlines()
    except FileNotFoundError:
        return None
    for raw in lines:
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        if line.startswith("[") and line.endswith("]"):
            in_features = line == "[features]"
            continue
        if not in_features or "=" not in line:
            continue
        key, value = [part.strip() for part in line.split("=", 1)]
        if key in ("codex_hooks", "hooks"):
            enabled = value.lower() == "true"
    return enabled


def codex_feature_from_cli():
    try:
        proc = subprocess.run(
            ["codex", "features", "list"],
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=10,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        return {"available": False, "enabled": None, "error": str(exc)}
    if proc.returncode != 0:
        return {"available": False, "enabled": None, "error": proc.stderr.strip()}
    for line in proc.stdout.splitlines():
        parts = line.split()
        if len(parts) >= 3 and parts[0] in ("codex_hooks", "hooks"):
            return {
                "available": True,
                "enabled": parts[-1].lower() == "true",
                "line": line.strip(),
            }
    return {"available": False, "enabled": None, "error": "codex_hooks feature not listed"}


def codex_version():
    try:
        proc = subprocess.run(
            ["codex", "--version"],
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=10,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        return {"ok": False, "value": None, "error": str(exc)}
    return {"ok": proc.returncode == 0, "value": proc.stdout.strip(), "error": proc.stderr.strip()}


def desired_dcg_hook():
    return {
        "type": "command",
        "command": "dcg",
        "timeout": 3,
        "statusMessage": "checking destructive command guard",
    }


def normalize_hooks_file(payload):
    if not isinstance(payload, dict):
        return {"hooks": {}}
    hooks = payload.get("hooks")
    if not isinstance(hooks, dict):
        payload["hooks"] = {}
    return payload


def merge_dcg_codex_hook(payload):
    payload = normalize_hooks_file(dict(payload))
    hooks = payload.setdefault("hooks", {})
    groups = hooks.setdefault("PreToolUse", [])
    if not isinstance(groups, list):
        groups = []
        hooks["PreToolUse"] = groups

    target_group = None
    for group in groups:
        if isinstance(group, dict) and is_bash_matcher(group.get("matcher", "")):
            target_group = group
            break
    if target_group is None:
        target_group = {"matcher": "^Bash$", "hooks": []}
        groups.append(target_group)

    hook_list = target_group.setdefault("hooks", [])
    if not isinstance(hook_list, list):
        hook_list = []
        target_group["hooks"] = hook_list

    for hook in hook_list:
        if isinstance(hook, dict) and command_basename(hook.get("command", "")) == "dcg":
            return payload, False

    hook_list.append(desired_dcg_hook())
    return payload, True


def find_codex_dcg_hooks(payload):
    rows = []
    payload = normalize_hooks_file(payload)
    for idx, group in enumerate(payload.get("hooks", {}).get("PreToolUse", []) or []):
        if not isinstance(group, dict) or not is_bash_matcher(group.get("matcher", "")):
            continue
        for hook_idx, hook in enumerate(group.get("hooks", []) or []):
            if isinstance(hook, dict) and command_basename(hook.get("command", "")) == "dcg":
                rows.append(
                    {
                        "event": "PreToolUse",
                        "matcher": group.get("matcher"),
                        "group_index": idx,
                        "hook_index": hook_idx,
                        "command": hook.get("command"),
                        "timeout": hook.get("timeout"),
                    }
                )
    return rows


def backup_existing(path, now):
    path = Path(path)
    if not path.exists():
        return None
    backup = path.with_name(f"{path.name}.bak.{iso(now).replace(':', '').replace('-', '')}")
    shutil.copy2(path, backup)
    if not backup.exists() or backup.read_bytes() != path.read_bytes():
        raise SystemExit(f"backup verification failed for {path}")
    return str(backup)


def append_receipt(state_dir, receipt):
    state_dir = Path(state_dir)
    state_dir.mkdir(parents=True, exist_ok=True)
    path = state_dir / "receipts.jsonl"
    with open(path, "a", encoding="utf-8") as handle:
        handle.write(json.dumps(receipt, sort_keys=True) + "\n")
    return str(path)


def render_issue_draft(path, result):
    if not path:
        return None
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    needed = result["upstream_issue"]["needed"]
    body = [
        "# Codex PreToolUse Hook Parity",
        "",
        f"- needed: {str(needed).lower()}",
        f"- codex_version: {result['codex']['version'].get('value')}",
        f"- codex_hooks_feature: {result['codex']['feature']}",
        f"- local_hooks_file: {result['codex']['hooks_path']}",
        "",
    ]
    if needed:
        body.extend(
            [
                "## Gap",
                "",
                "Flywheel needs a Codex pre-exec hook equivalent to Claude Code `PreToolUse` for `dcg`.",
                "Local probe could not confirm a supported Codex hook surface.",
                "",
            ]
        )
    else:
        body.extend(
            [
                "## Resolution",
                "",
                "No upstream issue filed: current official `openai/codex` source exposes `codex_hooks` and `PreToolUse`, and local `codex features list` reports `codex_hooks ... true`.",
                "",
            ]
        )
    body.append("## Probe JSON")
    body.append("")
    body.append("```json")
    body.append(json.dumps(result, indent=2))
    body.append("```")
    path.write_text("\n".join(body) + "\n", encoding="utf-8")
    return str(path)


def build_result(args):
    now = parse_ts(args.now) if args.now else utc_now()
    claude_settings = read_json(args.claude_settings, {})
    codex_hooks = read_json(args.codex_hooks, {"hooks": {}})
    desired_hooks, changed = merge_dcg_codex_hook(codex_hooks)

    feature_cli = codex_feature_from_cli()
    config_feature = feature_enabled_from_config(args.codex_config)
    support_enabled = bool(feature_cli.get("enabled") or config_feature is True)
    version = codex_version()

    hook_change = None
    failure_classes = []
    if args.hook_change_source:
        changed_at = parse_ts(args.hook_change_ts) if args.hook_change_ts else now
        lag = int((now - changed_at).total_seconds())
        deadline = changed_at + dt.timedelta(seconds=60)
        within = 0 <= lag <= 60
        hook_change = {
            "source_runtime": args.hook_change_source,
            "changed_path": args.hook_change_path,
            "changed_at": iso(changed_at),
            "parity_probe_deadline": iso(deadline),
            "parity_probe_lag_seconds": lag,
            "within_60s": within,
        }
        if not within:
            failure_classes.append("parity_probe_late")

    claude_rows = find_dcg_pretool_hooks(claude_settings)
    codex_rows = find_codex_dcg_hooks(codex_hooks)
    parity_after_desired = bool(find_codex_dcg_hooks(desired_hooks))

    if not claude_rows:
        failure_classes.append("claude_dcg_hook_missing")
    if not support_enabled:
        failure_classes.append("codex_hooks_feature_disabled")
    if args.strict and not codex_rows:
        failure_classes.append("codex_dcg_hook_missing")

    status = "pass" if not failure_classes and support_enabled and bool(claude_rows) else "fail"
    if not support_enabled:
        status = "unsupported"

    result = {
        "schema_version": SCHEMA_VERSION,
        "status": status,
        "failure_classes": failure_classes,
        "generated_at": iso(now),
        "parity_probe_required_within_seconds": 60,
        "hook_change": hook_change,
        "claude": {
            "settings_path": str(args.claude_settings),
            "dcg_pretooluse_count": len(claude_rows),
            "dcg_pretooluse_hooks": claude_rows,
        },
        "codex": {
            "config_path": str(args.codex_config),
            "hooks_path": str(args.codex_hooks),
            "version": version,
            "feature": feature_cli,
            "config_feature_enabled": config_feature,
            "dcg_pretooluse_count": len(codex_rows),
            "dcg_pretooluse_hooks": codex_rows,
            "desired_dcg_pretooluse_count": len(find_codex_dcg_hooks(desired_hooks)),
        },
        "desired_hooks": desired_hooks,
        "actions": {
            "apply_requested": args.apply,
            "would_write": changed,
            "wrote": False,
            "backup_path": None,
            "receipt_path": None,
            "issue_draft_path": None,
        },
        "upstream_issue": {
            "needed": not support_enabled,
            "reason": "codex PreToolUse hooks unsupported or disabled" if not support_enabled else "codex_hooks feature and PreToolUse support confirmed",
        },
        "three_q": {
            "validated": "probe validates Claude/Codex DCG hook parity and 60s hook-change lag",
            "documented": "canonical paths entry plus JSON schema_version identify the surface",
            "surfaced": "receipt JSONL records apply/probe events for doctor ingestion",
        },
    }
    return result, desired_hooks, now, changed, parity_after_desired


def main(argv=None):
    parser = argparse.ArgumentParser(description="Probe and sync Claude/Codex DCG hook parity.")
    parser.add_argument("--claude-settings", type=Path, default=DEFAULT_CLAUDE_SETTINGS)
    parser.add_argument("--codex-config", type=Path, default=DEFAULT_CODEX_CONFIG)
    parser.add_argument("--codex-hooks", type=Path, default=DEFAULT_CODEX_HOOKS)
    parser.add_argument("--state-dir", type=Path, default=DEFAULT_STATE_DIR)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--strict", action="store_true", help="Fail if Codex hooks file is not already wired.")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--now")
    parser.add_argument("--hook-change-source", choices=["claude", "codex"])
    parser.add_argument("--hook-change-path")
    parser.add_argument("--hook-change-ts")
    parser.add_argument("--issue-draft", type=Path)
    args = parser.parse_args(argv)

    result, desired_hooks, now, changed, _ = build_result(args)

    if args.apply:
        if result["status"] == "unsupported":
            print(json.dumps(result, indent=2), file=sys.stderr)
            return 4
        backup_path = backup_existing(args.codex_hooks, now)
        if changed:
            atomic_write_json(args.codex_hooks, desired_hooks)
        receipt = {
            "schema_version": SCHEMA_VERSION,
            "event": "apply" if changed else "probe",
            "ts": iso(now),
            "codex_hooks": str(args.codex_hooks),
            "backup_path": backup_path,
            "hook_change": result["hook_change"],
            "parity_probe_required_within_seconds": 60,
            "status": "pass",
        }
        result["actions"]["wrote"] = changed
        result["actions"]["backup_path"] = backup_path
        result["actions"]["receipt_path"] = append_receipt(args.state_dir, receipt)
        updated = read_json(args.codex_hooks, {"hooks": {}})
        result["codex"]["dcg_pretooluse_count"] = len(find_codex_dcg_hooks(updated))
        result["codex"]["dcg_pretooluse_hooks"] = find_codex_dcg_hooks(updated)
        if result["status"] == "fail" and result["failure_classes"] == ["codex_dcg_hook_missing"]:
            result["status"] = "pass"
            result["failure_classes"] = []

    result["actions"]["issue_draft_path"] = render_issue_draft(args.issue_draft, result)

    if args.json:
        print(json.dumps(result, indent=2, sort_keys=False))
    else:
        print(f"{result['status']} codex_dcg_hooks={result['codex']['dcg_pretooluse_count']} claude_dcg_hooks={result['claude']['dcg_pretooluse_count']}")

    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
