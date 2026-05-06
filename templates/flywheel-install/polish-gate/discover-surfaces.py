#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

MODES = ("bootstrap", "audit_only", "blocking")
SCOPES = ("new", "touched", "repo_local_flywheel", "all_declared")
LEGACY_BOOTSTRAP_POLICIES = ("warn_until_touched", "block_immediately")
BLOCKING_WHEN = ("new_surface", "touched_required_surface", "malformed_gate", "expired_waiver")
SKILL_LANES = ["ubs", "simplify", "extreme-opt", "readme", "canonical-cli"]
SCHEMA_VERSION = "polish-gate/discovery-output/v1"
EX_MANIFEST = 2
EX_MANIFEST_READ = 3
DEFAULT_MANIFEST = {
    "version": "1",
    "mode": "bootstrap",
    "scope": "repo_local_flywheel",
    "legacy_bootstrap_policy": "warn_until_touched",
    "blocking_when": ["malformed_gate"],
    "grade_storage": ".flywheel/polish-gate/grades.jsonl",
    "latest_summary": ".flywheel/polish-gate/latest.json",
}
REQUIRED_MANIFEST_FIELDS = tuple(DEFAULT_MANIFEST)
ALLOWED_MANIFEST_FIELDS = set(REQUIRED_MANIFEST_FIELDS)
SKIP_DIRS = {
    ".git",
    ".beads",
    ".pytest_cache",
    ".mypy_cache",
    ".ruff_cache",
    "__pycache__",
    "node_modules",
    ".venv",
    "venv",
    "dist",
    "build",
    "target",
}
DOMAIN_PREFIXES = (
    "src/",
    "app/",
    "apps/",
    "backend/",
    "frontend/",
    "knowledge/",
    ".planning/",
)
DECLARED_PREFIXES = (
    ".flywheel/",
    "templates/flywheel-install/",
    "bin/",
    "scripts/",
    "docs/",
)
OPERATOR_WORDS = (
    "doctor",
    "probe",
    "validator",
    "validate",
    "repair",
    "reconcile",
    "dispatch",
    "installer",
    "install",
    "generator",
    "generate",
    "watcher",
    "gate",
    "audit",
)
DOMAIN_SUFFIXES = {".py", ".sh", ".rs", ".ts", ".tsx", ".js", ".md", ".toml", ".json"}
Category = str


@dataclass(frozen=True)
class Candidate:
    path: str
    name: str
    category: Category | None


class DiscoveryError(RuntimeError):
    def __init__(self, exit_code: int, message: str) -> None:
        super().__init__(message)
        self.exit_code = exit_code


def iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def repo_relative(repo: Path, path: Path) -> str:
    return path.relative_to(repo).as_posix()


def manifest_error(path: Path, detail: str, action: str) -> DiscoveryError:
    return DiscoveryError(EX_MANIFEST, f"manifest error in {path}: {detail}. Suggested action: {action}")


def manifest_read_error(path: Path, detail: str) -> DiscoveryError:
    return DiscoveryError(
        EX_MANIFEST_READ,
        f"manifest read error in {path}: {detail}. Suggested action: verify the path exists and permissions allow reading.",
    )


def validate_manifest_shape(manifest: dict[str, object], manifest_path: Path) -> None:
    missing = [field for field in REQUIRED_MANIFEST_FIELDS if field not in manifest]
    if missing:
        raise manifest_error(
            manifest_path,
            f"missing required field(s): {', '.join(missing)}",
            "regenerate the polish-gate manifest from the template or add the missing field(s).",
        )

    extra = sorted(set(manifest) - ALLOWED_MANIFEST_FIELDS)
    if extra:
        raise manifest_error(
            manifest_path,
            f"unsupported field(s): {', '.join(extra)}",
            "remove unsupported keys or update the manifest schema before using them.",
        )

    if manifest["version"] != "1":
        raise manifest_error(manifest_path, "version must be \"1\"", "regenerate the manifest with the current template.")

    mode = manifest["mode"]
    if mode not in MODES:
        raise manifest_error(
            manifest_path,
            f"unsupported mode: {mode!r}",
            f"use one of: {', '.join(MODES)}.",
        )

    scope = manifest["scope"]
    if scope not in SCOPES:
        raise manifest_error(
            manifest_path,
            f"unsupported scope: {scope!r}",
            f"use one of: {', '.join(SCOPES)}.",
        )

    legacy_policy = manifest["legacy_bootstrap_policy"]
    if legacy_policy not in LEGACY_BOOTSTRAP_POLICIES:
        raise manifest_error(
            manifest_path,
            f"unsupported legacy_bootstrap_policy: {legacy_policy!r}",
            f"use one of: {', '.join(LEGACY_BOOTSTRAP_POLICIES)}.",
        )

    blocking_when = manifest["blocking_when"]
    if not isinstance(blocking_when, list):
        raise manifest_error(
            manifest_path,
            "blocking_when must be an array",
            "replace blocking_when with an array of polish-gate blocking reasons.",
        )
    invalid_blockers = [item for item in blocking_when if item not in BLOCKING_WHEN]
    if invalid_blockers:
        raise manifest_error(
            manifest_path,
            f"unsupported blocking_when value(s): {', '.join(repr(item) for item in invalid_blockers)}",
            f"use only: {', '.join(BLOCKING_WHEN)}.",
        )
    seen_blockers: list[object] = []
    has_duplicate_blockers = False
    for item in blocking_when:
        if item in seen_blockers:
            has_duplicate_blockers = True
            break
        seen_blockers.append(item)
    if has_duplicate_blockers:
        raise manifest_error(
            manifest_path,
            "blocking_when values must be unique",
            "deduplicate the blocking_when array.",
        )

    for field in ("grade_storage", "latest_summary"):
        value = manifest[field]
        if not isinstance(value, str) or not value:
            raise manifest_error(
                manifest_path,
                f"{field} must be a non-empty string",
                f"set {field} to a repo-local polish-gate path.",
            )


def load_manifest(repo: Path, manifest_arg: str) -> tuple[dict[str, object], Path]:
    manifest_path = Path(manifest_arg)
    if not manifest_path.is_absolute():
        manifest_path = repo / manifest_path
    manifest = dict(DEFAULT_MANIFEST)
    try:
        manifest_exists = manifest_path.exists()
    except OSError as exc:
        raise manifest_read_error(manifest_path, str(exc)) from exc
    if manifest_exists:
        try:
            with manifest_path.open(encoding="utf-8") as handle:
                data = json.load(handle)
        except json.JSONDecodeError as exc:
            raise manifest_error(
                manifest_path,
                f"malformed JSON ({exc.msg} at line {exc.lineno} column {exc.colno})",
                "fix the JSON syntax or regenerate the manifest from the polish-gate template.",
            ) from exc
        except UnicodeDecodeError as exc:
            raise manifest_error(
                manifest_path,
                f"invalid UTF-8 ({exc.reason} at byte {exc.start})",
                "rewrite the manifest as UTF-8 JSON or regenerate it from the polish-gate template.",
            ) from exc
        except OSError as exc:
            raise manifest_read_error(manifest_path, str(exc)) from exc
        if not isinstance(data, dict):
            raise manifest_error(
                manifest_path,
                "JSON document must be an object",
                "replace the manifest with a JSON object matching polish-gate/v1/manifest.schema.json.",
            )
        manifest = data
    validate_manifest_shape(manifest, manifest_path)
    return manifest, manifest_path


def is_backup_or_generated(rel: str) -> bool:
    name = Path(rel).name
    return (
        ".bak." in name
        or name.endswith(".bak")
        or name.endswith(".tmp")
        or rel.endswith(".log")
        or rel.endswith("grades.jsonl")
        or rel.endswith("latest.json")
        or "scrollback" in rel
        or "/tmp/" in rel
        or "dispatch_" in name
    )


def should_skip_dir(rel_dir: str) -> bool:
    parts = [part for part in rel_dir.split("/") if part]
    return any(part in SKIP_DIRS for part in parts)


def is_executable_or_shebang(path: Path) -> bool:
    if os.access(path, os.X_OK):
        return True
    try:
        with path.open("rb") as handle:
            return handle.read(2) == b"#!"
    except OSError:
        return False


def command_like(rel: str) -> bool:
    stem = Path(rel).stem.lower()
    return any(word in stem for word in OPERATOR_WORDS)


def classify(rel: str, path: Path) -> Category | None:
    name = Path(rel).name
    suffix = Path(rel).suffix
    if rel.endswith(".schema.json"):
        return "schema"
    if name == "README.md":
        return "readme"
    if name in {"AGENTS.md", "MISSION.md", "GOAL.md", "STATE.md"} or rel.endswith(".md.tmpl"):
        return "doctrine-doc"
    if "/fixtures/" in rel and suffix in {".json", ".jsonl", ".yaml", ".yml"}:
        return "test-fixture"
    if (
        is_executable_or_shebang(path)
        or rel.startswith(("bin/", "scripts/", ".flywheel/scripts/", ".local/bin/"))
        or command_like(rel)
    ) and suffix in {".py", ".sh", ".rs", ".ts", ".tsx", ".js", ""}:
        return "cli-script"
    return None


def is_domain_candidate(rel: str) -> bool:
    path = Path(rel)
    return path.name == "Makefile" or path.suffix in DOMAIN_SUFFIXES


def declared_by_scope(rel: str, scope: str, category: Category | None) -> tuple[bool, str]:
    in_flywheel = rel == ".flywheel" or rel.startswith(".flywheel/")
    in_template = rel.startswith("templates/flywheel-install/")
    in_declared = rel.startswith(DECLARED_PREFIXES) or rel in {
        "README.md",
        "AGENTS.md",
        "MISSION.md",
        "GOAL.md",
        "STATE.md",
    }
    in_domain = rel.startswith(DOMAIN_PREFIXES)

    if scope == "repo_local_flywheel":
        if in_flywheel:
            return True, "repo-local-flywheel-allowlist"
        return False, "root-domain-not-substrate"
    if scope in {"new", "touched"}:
        if in_flywheel or in_template:
            return True, f"{scope}-substrate-allowlist"
        return False, "root-domain-not-substrate"
    if scope == "all_declared":
        if category and in_declared and not in_domain:
            return True, "declared-operational-surface"
        return False, "root-domain-not-substrate" if in_domain else "not-declared-operational-substrate"
    return False, "unsupported-scope"


def display_name(rel: str) -> str:
    path = Path(rel)
    if rel.endswith(".schema.json"):
        return path.name.removesuffix(".schema.json")
    return path.stem if path.suffix else path.name


def iter_candidates(repo: Path) -> list[Candidate]:
    candidates: list[Candidate] = []
    for root, dirs, files in os.walk(repo):
        root_path = Path(root)
        rel_dir = "." if root_path == repo else repo_relative(repo, root_path)
        dirs[:] = sorted(
            dirname
            for dirname in dirs
            if not should_skip_dir(f"{'' if rel_dir == '.' else rel_dir + '/'}{dirname}")
        )
        for filename in sorted(files):
            path = root_path / filename
            rel = repo_relative(repo, path)
            if is_backup_or_generated(rel):
                continue
            category = classify(rel, path)
            if category or is_domain_candidate(rel):
                candidates.append(Candidate(path=rel, name=display_name(rel), category=category))
    return candidates


def discover(repo: Path, manifest_path: Path, scope: str) -> dict[str, object]:
    surfaces: list[dict[str, object]] = []
    excluded: dict[str, str] = {}

    for candidate in iter_candidates(repo):
        allowed, reason = declared_by_scope(candidate.path, scope, candidate.category)
        if allowed and candidate.category:
            surfaces.append(
                {
                    "path": candidate.path,
                    "name": candidate.name,
                    "category": candidate.category,
                    "in_scope": True,
                    "scope_reason": reason,
                    "skill_lanes_applicable": SKILL_LANES,
                }
            )
        else:
            excluded.setdefault(candidate.path, reason)

    surfaces.sort(key=lambda row: str(row["path"]))
    scope_excluded = [{"path": path, "reason": excluded[path]} for path in sorted(excluded)]
    by_category: dict[str, int] = {}
    for surface in surfaces:
        category = str(surface["category"])
        by_category[category] = by_category.get(category, 0) + 1

    return {
        "schema_version": SCHEMA_VERSION,
        "ts": iso_now(),
        "repo_path": str(repo),
        "scope_mode": scope,
        "manifest_path": str(manifest_path),
        "surfaces": surfaces,
        "scope_excluded": scope_excluded,
        "totals": {
            "in_scope": len(surfaces),
            "excluded": len(scope_excluded),
            "by_category": dict(sorted(by_category.items())),
        },
    }


def output_schema() -> dict[str, object]:
    schema_path = Path(__file__).resolve().parent / "v1" / "discovery-output.schema.json"
    with schema_path.open(encoding="utf-8") as handle:
        schema = json.load(handle)
    if not isinstance(schema, dict):
        raise SystemExit(f"schema must be a JSON object: {schema_path}")
    return schema


def print_explain(result: dict[str, object]) -> None:
    print(f"repo={result['repo_path']} scope={result['scope_mode']} manifest={result['manifest_path']}")
    for surface in result["surfaces"]:
        row = dict(surface)
        print(f"IN  {row['path']} category={row['category']} reason={row['scope_reason']}")
    for item in result["scope_excluded"]:
        row = dict(item)
        print(f"OUT {row['path']} reason={row['reason']}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Discover polish-gate-eligible flywheel substrate surfaces without sweeping domain code.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""examples:
  discover-surfaces.py --repo . --manifest .flywheel/polish-gate/manifest.json --json
  discover-surfaces.py --repo /path/to/repo --scope repo_local_flywheel --explain
  discover-surfaces.py --schema

exit codes:
  0 success
  2 usage, malformed manifest, or unsupported manifest value
  3 manifest read error""",
    )
    parser.add_argument("--repo", default=".", help="target repo path (default: current directory)")
    parser.add_argument(
        "--manifest",
        default=".flywheel/polish-gate/manifest.json",
        help="manifest.json path, relative to --repo unless absolute",
    )
    parser.add_argument("--mode", choices=MODES, help="override manifest mode")
    parser.add_argument("--scope", choices=SCOPES, help="override manifest scope")
    parser.add_argument("--json", action="store_true", help="emit JSON output (default unless --explain is used)")
    parser.add_argument("--schema", action="store_true", help="emit the discovery output JSON Schema and exit")
    parser.add_argument("--dry-run", action="store_true", default=True, help="no side effects; default behavior")
    parser.add_argument("--explain", action="store_true", help="emit human-readable per-surface decision trace")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        if args.schema:
            print(json.dumps(output_schema(), indent=2, sort_keys=True))
            return 0

        repo = Path(args.repo).expanduser().resolve()
        if not repo.is_dir():
            raise DiscoveryError(EX_MANIFEST, f"--repo is not a directory: {repo}")
        manifest, manifest_path = load_manifest(repo, args.manifest)
        if args.mode:
            manifest["mode"] = args.mode
        if args.scope:
            manifest["scope"] = args.scope
        validate_manifest_shape(manifest, manifest_path)
        scope = str(manifest["scope"])

        result = discover(repo, manifest_path, scope)
        if args.explain and not args.json:
            print_explain(result)
        else:
            print(json.dumps(result, indent=2, sort_keys=True))
        return 0
    except DiscoveryError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return exc.exit_code


if __name__ == "__main__":
    raise SystemExit(main())
