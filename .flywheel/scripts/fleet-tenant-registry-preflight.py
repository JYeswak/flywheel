#!/usr/bin/env python3
"""Preflight the L168 tenant registry before fleet bootstrap dispatch.

This is intentionally value-blind. It reads identifiers, repo declarations, and
optional tenant-doctor summaries, but never prints secret values.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

import yaml


DEFAULT_REGISTRY = (
    Path.home() / ".claude/skills/infisical-secrets/data/project-mappings.yaml"
)
UUID_RE = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-", re.I)
SUPABASE_REF_RE = re.compile(r"^[a-z0-9]{20}$")


def load_yaml(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def is_todo(value: Any) -> bool:
    if value is None:
        return True
    text = str(value).strip()
    return text == "" or text.upper().startswith("TODO")


def nested(mapping: dict[str, Any], dotted: str) -> Any:
    current: Any = mapping
    for part in dotted.split("."):
        if not isinstance(current, dict):
            return None
        current = current.get(part)
    return current


def check_registry_row(slug: str, row: dict[str, Any] | None) -> list[str]:
    failures: list[str] = []
    if row is None:
        return ["registry_row_missing"]

    required = [
        "infisical_project_id",
        "description",
        "supabase.project_ref",
        "supabase.project_url",
        "supabase.pooler_mode",
        "canonical_keys",
    ]
    for field in required:
        value = nested(row, field)
        if is_todo(value) or (field == "canonical_keys" and not value):
            failures.append(f"registry_field_missing:{field}")

    infisical_project_id = row.get("infisical_project_id")
    if not is_todo(infisical_project_id) and not UUID_RE.match(str(infisical_project_id)):
        failures.append("registry_field_invalid:infisical_project_id")

    ref = nested(row, "supabase.project_ref")
    url = nested(row, "supabase.project_url")
    if not is_todo(ref) and not SUPABASE_REF_RE.match(str(ref)):
        failures.append("registry_field_invalid:supabase.project_ref")
    if not is_todo(ref) and not is_todo(url) and str(ref) not in str(url):
        failures.append("registry_field_mismatch:supabase.project_url")

    vercel = row.get("vercel") if isinstance(row.get("vercel"), dict) else {}
    if vercel:
        project_id = vercel.get("project_id")
        if is_todo(project_id):
            failures.append("registry_field_missing:vercel.project_id")
        elif not str(project_id).startswith("prj_"):
            failures.append("registry_field_invalid:vercel.project_id")

    canonical_keys = row.get("canonical_keys")
    if isinstance(canonical_keys, dict):
        for key, spec in canonical_keys.items():
            if not isinstance(spec, dict):
                failures.append(f"canonical_key_invalid:{key}")
                continue
            validator = spec.get("validator")
            if is_todo(validator):
                failures.append(f"canonical_key_missing_validator:{key}")
                continue
            expected_fields = {
                "postgres_url_contains_supabase_ref": "expected_supabase_ref",
                "equals": "expected_value",
                "supabase_jwt_ref_claim_equals": "expected_ref_claim",
                "supabase_publishable_key_format": "expected_format",
            }
            expected = expected_fields.get(str(validator))
            if expected is None:
                failures.append(f"canonical_key_unknown_validator:{key}")
            elif is_todo(spec.get(expected)):
                failures.append(f"canonical_key_missing_expected:{key}:{expected}")

    return failures


def check_declaration(slug: str, repo: Path | None, row: dict[str, Any] | None) -> list[str]:
    if repo is None:
        return []
    if not repo.exists():
        return ["repo_path_missing"]

    declaration = repo / ".zs-tenant.yaml"
    if not declaration.exists():
        return ["repo_declaration_missing"]

    try:
        doc = load_yaml(declaration)
    except Exception:
        return ["repo_declaration_yaml_invalid"]
    if not isinstance(doc, dict):
        return ["repo_declaration_yaml_invalid"]

    failures: list[str] = []
    if doc.get("schema_version") != "skillos.tenant_routing_repo_declaration.v1":
        failures.append("repo_declaration_schema_mismatch")
    if doc.get("project_slug") != slug:
        failures.append("repo_declaration_slug_mismatch")

    if row is not None:
        if doc.get("infisical_project_id") != row.get("infisical_project_id"):
            failures.append("repo_declaration_infisical_mismatch")
        expected_ref = nested(row, "supabase.project_ref")
        if doc.get("expected_supabase_ref") != expected_ref:
            failures.append("repo_declaration_supabase_mismatch")
        expected_vercel = nested(row, "vercel.project_id")
        if not is_todo(expected_vercel) and doc.get("expected_vercel_project_id") != expected_vercel:
            failures.append("repo_declaration_vercel_mismatch")

    return failures


def run_doctor(slug: str, cwd: Path | None) -> dict[str, Any]:
    command = ["zs-tenant-doctor", "--json", "--no-journeys", slug]
    env = dict(os.environ)
    env["PATH"] = f"{Path.home() / '.local/bin'}:{env.get('PATH', '')}"
    try:
        proc = subprocess.run(
            command,
            cwd=str(cwd or Path.cwd()),
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=40,
            check=False,
        )
    except FileNotFoundError:
        return {"status": "not_run", "reason": "zs-tenant-doctor-not-found"}
    except subprocess.TimeoutExpired:
        return {"status": "fail", "reason": "zs-tenant-doctor-timeout"}

    if proc.returncode != 0 and not proc.stdout.strip():
        return {
            "status": "fail",
            "returncode": proc.returncode,
            "reason": "zs-tenant-doctor-no-json",
            "stderr_summary": proc.stderr.strip().splitlines()[:3],
        }
    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError:
        return {
            "status": "fail",
            "returncode": proc.returncode,
            "reason": "zs-tenant-doctor-json-invalid",
        }
    drift_count = int(payload.get("drift_count") or 0)
    warn_count = int(payload.get("warn_count") or 0)
    return {
        "status": "pass" if proc.returncode == 0 and drift_count == 0 and warn_count == 0 else "fail",
        "returncode": proc.returncode,
        "drift_count": drift_count,
        "warn_count": warn_count,
        "result_count": len(payload.get("results") or []),
    }


def parse_disposition(value: str) -> tuple[str, Path]:
    if "=" not in value:
        raise argparse.ArgumentTypeError("--disposition must be slug=/absolute/path.json")
    slug, path = value.split("=", 1)
    if not slug:
        raise argparse.ArgumentTypeError("--disposition slug cannot be empty")
    return slug, Path(path).expanduser()


def load_disposition(slug: str, path: Path | None) -> tuple[dict[str, Any] | None, list[str]]:
    if path is None:
        return None, []
    if not path.exists():
        return None, ["disposition_receipt_missing"]
    try:
        receipt = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None, ["disposition_receipt_invalid_json"]

    failures: list[str] = []
    if receipt.get("schema_version") != "flywheel.tenant_registry_disposition.v1":
        failures.append("disposition_receipt_schema_invalid")
    if receipt.get("slug") != slug:
        failures.append("disposition_receipt_slug_mismatch")
    if receipt.get("status") not in {"skip_with_reason", "adapter_required"}:
        failures.append("disposition_receipt_status_invalid")
    if is_todo(receipt.get("reason")):
        failures.append("disposition_receipt_reason_missing")
    if not receipt.get("evidence_refs"):
        failures.append("disposition_receipt_evidence_missing")
    return receipt, failures


def parse_repo(value: str) -> tuple[str, Path]:
    if "=" not in value:
        raise argparse.ArgumentTypeError("--repo must be slug=/absolute/path")
    slug, path = value.split("=", 1)
    if not slug:
        raise argparse.ArgumentTypeError("--repo slug cannot be empty")
    return slug, Path(path).expanduser()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", type=Path, default=DEFAULT_REGISTRY)
    parser.add_argument("--require", action="append", default=[], help="Required slug")
    parser.add_argument("--repo", action="append", default=[], type=parse_repo)
    parser.add_argument("--disposition", action="append", default=[], type=parse_disposition)
    parser.add_argument("--run-doctor", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    registry = load_yaml(args.registry)
    mappings = registry.get("mappings") if isinstance(registry, dict) else {}
    if not isinstance(mappings, dict):
        raise SystemExit("registry missing mappings")

    repos = dict(args.repo)
    dispositions = dict(args.disposition)
    slugs = list(dict.fromkeys([*args.require, *repos.keys()]))
    rows = []
    for slug in slugs:
        row = mappings.get(slug)
        repo = repos.get(slug)
        disposition, disposition_failures = load_disposition(slug, dispositions.get(slug))
        disposition_skips_registry = (
            disposition is not None
            and not disposition_failures
            and disposition.get("status") == "skip_with_reason"
            and disposition.get("registry_row_required") is False
        )
        disposition_skips_declaration = (
            disposition is not None
            and not disposition_failures
            and disposition.get("status") == "skip_with_reason"
            and disposition.get("repo_declaration_required") is False
        )

        registry_failures = [] if row is None and disposition_skips_registry else check_registry_row(slug, row)
        declaration_failures = [] if disposition_skips_declaration else check_declaration(slug, repo, row)
        doctor = (
            {"status": "skipped", "reason": "disposition_receipt"}
            if disposition_skips_registry
            else run_doctor(slug, repo) if args.run_doctor and row is not None else {"status": "not_run"}
        )
        failures = [*registry_failures, *declaration_failures]
        failures.extend(disposition_failures)
        if doctor.get("status") == "fail":
            failures.append("tenant_doctor_failed")
        rows.append(
            {
                "slug": slug,
                "repo": str(repo) if repo else None,
                "status": "pass" if not failures else "fail",
                "registry_status": "skipped" if disposition_skips_registry else ("pass" if not registry_failures else "fail"),
                "declaration_status": "skipped" if disposition_skips_declaration else ("pass" if repo and not declaration_failures else ("not_checked" if not repo else "fail")),
                "doctor_status": doctor.get("status"),
                "failures": failures,
                "disposition": {
                    "status": disposition.get("status"),
                    "reason": disposition.get("reason"),
                    "ref": str(dispositions.get(slug)),
                } if disposition else None,
                "doctor": doctor,
            }
        )

    payload = {
        "schema_version": "flywheel.fleet_tenant_registry_preflight.v1",
        "registry": str(args.registry),
        "run_doctor": bool(args.run_doctor),
        "status": "pass" if all(row["status"] == "pass" for row in rows) else "fail",
        "row_count": len(rows),
        "fail_count": sum(1 for row in rows if row["status"] != "pass"),
        "rows": rows,
    }
    if args.json:
        print(json.dumps(payload, indent=2))
    else:
        print(f"{payload['status']} rows={payload['row_count']} fail={payload['fail_count']}")
        for row in rows:
            print(f"{row['status']} {row['slug']} failures={','.join(row['failures']) or '-'}")
    return 0 if payload["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
