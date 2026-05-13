#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 -c '
import fnmatch
import json
import re
import sys
from pathlib import Path

import jsonschema
from jsonschema import Draft202012Validator

root = Path(sys.argv[1])
schema_path = root / "polish-gate" / "v1" / "scope-allowlist.schema.json"
fixture_dir = root / "polish-gate" / "fixtures" / "scope-allowlist"

with schema_path.open(encoding="utf-8") as handle:
    schema = json.load(handle)
Draft202012Validator.check_schema(schema)
validator = Draft202012Validator(schema)

valid_names = ["strict-client", "capability-control-plane", "swarm-daemon", "proof-product", "vrtx", "default"]
fixtures = {}
for name in valid_names:
    path = fixture_dir / f"{name}.json"
    with path.open(encoding="utf-8") as handle:
        payload = json.load(handle)
    validator.validate(payload)
    fixtures[name] = payload

with (fixture_dir / "malformed-no-allowlist.json").open(encoding="utf-8") as handle:
    malformed = json.load(handle)
try:
    validator.validate(malformed)
except jsonschema.ValidationError:
    pass
else:
    raise AssertionError("malformed scope allowlist fixture without allowlist_paths validated")

def match(pattern, rel):
    if pattern == "**/*":
        return True
    if pattern.endswith("/"):
        return rel == pattern[:-1] or rel.startswith(pattern)
    if pattern.endswith("/**"):
        prefix = pattern[:-3]
        return rel == prefix or rel.startswith(prefix + "/")
    return fnmatch.fnmatchcase(rel, pattern)

def blocked(profile, rel):
    return any(match(pattern, rel) for pattern in profile["blocklist_paths"])

def allowed(profile, rel):
    if blocked(profile, rel):
        return False
    return any(match(pattern, rel) for pattern in profile["allowlist_paths"])

strict_client = fixtures["strict-client"]
assert strict_client["allowlist_paths"] == [".flywheel/"], strict_client["allowlist_paths"]
assert len(strict_client["blocklist_paths"]) >= 10

required_terms = {"doctor", "ledger", "worker", "dispatch", "tick", "router"}
terms = set(strict_client["domain_collision_terms"])
assert required_terms <= terms, terms
assert len(strict_client["domain_collision_terms"]) >= 6
assert strict_client["requires_word_boundary"] is True

strict_client_root_samples = [
    "AGENTS.md",
    "README.md",
    "backend/audit_middleware.py",
    "frontend/src/router.tsx",
    "src/insurance-policies/policy_model.py",
    "apps/claims-api/router.ts",
    "infrastructure/terraform/main.tf",
    "integrations/workato/recipe.json",
    "knowledge/workato-live-surface-2026-04-21.md",
    "raw_dumps/ledger.csv",
    "docs/compliance/glba.md",
    "supabase/migrations/001_ledger.sql",
]
for rel in strict_client_root_samples:
    assert blocked(strict_client, rel), rel
    assert not allowed(strict_client, rel), rel
assert allowed(strict_client, ".flywheel/STATE.md")
assert allowed(strict_client, ".flywheel/wire-or-explain-ledger/writer.py")

for term in required_terms:
    regex = re.compile(rf"\b{re.escape(term)}\b")
    domain_text = f"Strict-client root domain mentions {term} in a customer workflow."
    assert regex.search(domain_text), term
    assert not regex.search(f"strictclient{term}domain"), term
    assert not allowed(strict_client, f"src/insurance-policies/{term}_fixture.py"), term

swarm = fixtures["swarm-daemon"]
assert swarm["allowlist_paths"] == ["**/*"]
assert swarm["blocklist_paths"] == []
for rel in ["src/daemon/tick.rs", "tests/cli_dispatch_status.rs", "README.md"]:
    assert allowed(swarm, rel), rel

for name, root_sample in [
    ("capability-control-plane", "src/domain_model.py"),
    ("proof-product", "next-app/app/page.tsx"),
    ("vrtx", "workflows/client-router.json"),
]:
    profile = fixtures[name]
    assert allowed(profile, ".flywheel/STATE.md"), name
    assert not allowed(profile, root_sample), (name, root_sample)

assert allowed(fixtures["capability-control-plane"], "scripts/validate_skill.py")
assert allowed(fixtures["capability-control-plane"], "tests/test_skill.py")
assert not allowed(fixtures["proof-product"], "app/router.ts")
assert not allowed(fixtures["vrtx"], "workers/dispatch.ts")

print("PASS: polish gate scope allowlist schema and fixtures")
' "$ROOT"
