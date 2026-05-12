#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
POLICY="$ROOT/beads_compliance_audit/audit-policy.yaml"

python3 - "$POLICY" <<'PY'
import re
import sys
from pathlib import Path

import yaml

policy = yaml.safe_load(Path(sys.argv[1]).read_text(encoding="utf-8"))
env = policy["phase_4_environment"]
gate = env["dry_run_gate"]

assert env["kind"] == "native"
assert env["escalation_path"] == "docker_once_native_harness_proven"
assert env["network_policy"] == "localhost-only"
assert env["allow_real_services"] == []
assert env["resource_caps"] == {
    "memory": "4G",
    "cpus": 4,
    "pids": 1024,
    "command_timeout_seconds": 600,
}
assert gate["enabled"] is True
assert gate["mode"] == "list_commands"
assert gate["required_before_real_execution"] is True
assert gate["output_schema"] == "phase-4-command-inventory/v1"

required = {
    "bead_id",
    "command",
    "cwd",
    "env",
    "resource_classes",
    "network_hosts",
    "service_dependencies",
    "fixture_paths",
    "shared_resources",
    "expected_outputs",
}
assert required.issubset(set(gate["inventory_required_fields"]))
assert gate["refusal_policy"]["external_network"] == "refuse_unless_host_in_allow_real_services"
assert gate["refusal_policy"]["service_calls"] == "refuse_unless_service_in_allow_real_services"

classes = {row["id"]: row for row in gate["shared_resource_collision_classes"]}
for expected in ("db_port", "fixture_dir", "sqlite_db", "repo_state"):
    assert expected in classes, expected

fixture_commands = [
    {
        "bead_id": "ok-local",
        "command": "bash tests/unit.sh",
        "cwd": str(Path(sys.argv[1]).parents[1]),
        "env": {},
        "resource_classes": [],
        "network_hosts": ["localhost"],
        "service_dependencies": [],
        "fixture_paths": ["tests/unit/case-a"],
        "shared_resources": [],
        "expected_outputs": ["raw/unit.stdout"],
    },
    {
        "bead_id": "external-network",
        "command": "curl https://api.example.com",
        "cwd": str(Path(sys.argv[1]).parents[1]),
        "env": {},
        "resource_classes": [],
        "network_hosts": ["api.example.com"],
        "service_dependencies": [],
        "fixture_paths": [],
        "shared_resources": [],
        "expected_outputs": ["raw/e2e.stdout"],
    },
    {
        "bead_id": "db-collision",
        "command": "pytest tests/db",
        "cwd": str(Path(sys.argv[1]).parents[1]),
        "env": {},
        "resource_classes": [],
        "network_hosts": ["localhost"],
        "service_dependencies": [],
        "fixture_paths": ["tests/fixtures/db"],
        "shared_resources": ["localhost:5432"],
        "expected_outputs": ["raw/db.stdout"],
    },
]


def classify(command):
    missing = required.difference(command)
    if missing:
        return {"status": "refuse", "reason": f"missing:{','.join(sorted(missing))}"}
    for host in command["network_hosts"]:
        if host not in ("localhost", "127.0.0.1", "::1") and host not in env["allow_real_services"]:
            return {"status": "refuse", "reason": "external_network_not_allowlisted", "host": host}
    collisions = []
    for value in command["shared_resources"] + command["fixture_paths"]:
        for row in gate["shared_resource_collision_classes"]:
            if re.search(row["match"], value):
                collisions.append({"class": row["id"], "value": value, "action": row["action"]})
    if collisions:
        return {"status": "classify", "collisions": collisions}
    return {"status": "allow"}


results = {row["bead_id"]: classify(row) for row in fixture_commands}
assert results["ok-local"]["status"] == "allow"
assert results["external-network"]["status"] == "refuse"
assert results["external-network"]["reason"] == "external_network_not_allowlisted"
assert results["db-collision"]["status"] == "classify"
assert any(row["class"] == "db_port" for row in results["db-collision"]["collisions"])
assert any(row["class"] == "fixture_dir" for row in results["db-collision"]["collisions"])

print("PASS beads compliance Phase 4 audit-policy dry-run gate")
PY
