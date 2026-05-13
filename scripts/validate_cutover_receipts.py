#!/usr/bin/env python3
"""Validate a saved Flywheel release cutover receipt bundle."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from types import SimpleNamespace
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import publication_readiness  # noqa: E402


SCHEMA_VERSION = "flywheel.cutover_receipts.v0"
REQUIRED_FILES = {
    "publication-readiness.json": "json",
    "publication-readiness-release.json": "json",
    "user-journey-pack-validation.json": "json",
    "repo-view.json": "json",
    "remote-workflows.json": "json",
    "remote-runs.json": "json",
    "release-view.json": "json",
    "external-review-release.json": "json",
    "release-signoff.receipt.json": "json",
    "website-head.txt": "text",
    "live-site-probe.json": "json",
    "website-probe.json": "json",
    "install-probe.json": "json",
    "install-sha256-probe.json": "json",
    "install-sha256.actual": "text",
    "install-sha256.expected": "text",
    "publication-readiness-replay.json": "json",
}


def read_json(path: Path) -> tuple[Any | None, dict[str, Any] | None]:
    try:
        return json.loads(path.read_text()), None
    except FileNotFoundError:
        return None, {"code": "missing_receipt_file", "path": str(path)}
    except json.JSONDecodeError as exc:
        return None, {"code": "invalid_json", "path": str(path), "detail": str(exc)}


def first_token(path: Path) -> str:
    try:
        text = path.read_text().strip()
    except FileNotFoundError:
        return ""
    return text.split()[0].lower() if text else ""


def http_status_from_head(path: Path) -> int | None:
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except FileNotFoundError:
        return None
    for line in lines:
        parts = line.strip().split()
        if len(parts) >= 2 and parts[0].upper().startswith("HTTP/"):
            try:
                return int(parts[1])
            except ValueError:
                return None
    return None


def validate(receipt_dir: Path, repo: Path, remote: str, tag: str) -> dict[str, Any]:
    receipt_dir = receipt_dir.resolve()
    repo = repo.resolve()
    checks: list[dict[str, str]] = []
    errors: list[dict[str, Any]] = []
    receipt_file_errors = False

    for name, kind in REQUIRED_FILES.items():
        path = receipt_dir / name
        if not path.exists():
            checks.append({"id": f"receipt_file:{name}", "status": "blocked"})
            errors.append({"code": "missing_receipt_file", "path": str(path)})
            receipt_file_errors = True
            continue
        if path.stat().st_size <= 0:
            checks.append({"id": f"receipt_file:{name}", "status": "blocked"})
            errors.append({"code": "empty_receipt_file", "path": str(path)})
            receipt_file_errors = True
            continue
        if kind == "json":
            _payload, error = read_json(path)
            if error:
                checks.append({"id": f"receipt_file:{name}", "status": "blocked"})
                errors.append(error)
                receipt_file_errors = True
                continue
        checks.append({"id": f"receipt_file:{name}", "status": "pass"})

    publication_readiness_receipt, publication_readiness_error = read_json(receipt_dir / "publication-readiness.json")
    if (
        publication_readiness_error is None
        and isinstance(publication_readiness_receipt, dict)
        and publication_readiness_receipt.get("status") == "pass"
        and not publication_readiness_receipt.get("blockers", [])
    ):
        checks.append({"id": "publication_readiness_receipt", "status": "pass"})
    elif publication_readiness_error is None:
        checks.append({"id": "publication_readiness_receipt", "status": "blocked"})
        errors.append(
            {
                "code": "publication_readiness_not_pass",
                "status": publication_readiness_receipt.get("status")
                if isinstance(publication_readiness_receipt, dict)
                else None,
                "blocker_count": len(publication_readiness_receipt.get("blockers", []))
                if isinstance(publication_readiness_receipt, dict)
                else None,
            }
        )

    release_readiness, release_readiness_error = read_json(receipt_dir / "publication-readiness-release.json")
    if (
        release_readiness_error is None
        and isinstance(release_readiness, dict)
        and release_readiness.get("status") == "pass"
        and not release_readiness.get("blockers", [])
    ):
        checks.append({"id": "publication_readiness_release_receipt", "status": "pass"})
    elif release_readiness_error is None:
        checks.append({"id": "publication_readiness_release_receipt", "status": "blocked"})
        errors.append(
            {
                "code": "publication_readiness_release_not_pass",
                "status": release_readiness.get("status") if isinstance(release_readiness, dict) else None,
                "blocker_count": len(release_readiness.get("blockers", [])) if isinstance(release_readiness, dict) else None,
            }
        )

    website_head_status = http_status_from_head(receipt_dir / "website-head.txt")
    if website_head_status is not None and 200 <= website_head_status < 400:
        checks.append({"id": "website_head_status", "status": "pass"})
    else:
        checks.append({"id": "website_head_status", "status": "blocked"})
        errors.append({"code": "website_head_status_not_success", "status_code": website_head_status})

    live_site_probe, live_site_probe_error = read_json(receipt_dir / "live-site-probe.json")
    if live_site_probe_error is None and (
        isinstance(live_site_probe, dict)
        and live_site_probe.get("schema_version") == "flywheel.live_site_probe.v0"
        and live_site_probe.get("status") == "pass"
        and live_site_probe.get("failure_count") == 0
    ):
        checks.append({"id": "live_site_probe_receipt", "status": "pass"})
    elif live_site_probe_error is None:
        checks.append({"id": "live_site_probe_receipt", "status": "blocked"})
        errors.append(
            {
                "code": "live_site_probe_not_pass",
                "status": live_site_probe.get("status") if isinstance(live_site_probe, dict) else None,
                "failure_count": live_site_probe.get("failure_count") if isinstance(live_site_probe, dict) else None,
            }
        )

    journey_validation, journey_validation_error = read_json(receipt_dir / "user-journey-pack-validation.json")
    if journey_validation_error is None and (
        isinstance(journey_validation, dict)
        and journey_validation.get("schema_version") == "flywheel.public_user_journey_pack.v0"
        and journey_validation.get("status") == "pass"
        and journey_validation.get("row_count", 0) > 0
        and not journey_validation.get("errors", [])
    ):
        checks.append({"id": "user_journey_pack_validation_receipt", "status": "pass"})
    elif journey_validation_error is None:
        checks.append({"id": "user_journey_pack_validation_receipt", "status": "blocked"})
        errors.append(
            {
                "code": "user_journey_pack_validation_not_pass",
                "status": journey_validation.get("status") if isinstance(journey_validation, dict) else None,
                "row_count": journey_validation.get("row_count") if isinstance(journey_validation, dict) else None,
                "error_count": len(journey_validation.get("errors", [])) if isinstance(journey_validation, dict) else None,
            }
        )

    actual = first_token(receipt_dir / "install-sha256.actual")
    expected = first_token(receipt_dir / "install-sha256.expected")
    if actual and expected and actual == expected:
        checks.append({"id": "install_sha256_text_match", "status": "pass"})
    else:
        checks.append({"id": "install_sha256_text_match", "status": "blocked"})
        errors.append({"code": "install_sha256_text_mismatch", "actual": actual, "expected": expected})

    replay: dict[str, Any] | None = None
    if receipt_file_errors:
        checks.append({"id": "publication_readiness_replay", "status": "blocked"})
        errors.append({"code": "publication_readiness_replay_not_run", "reason": "receipt_file_errors"})
    else:
        saved_replay, saved_replay_error = read_json(receipt_dir / "publication-readiness-replay.json")
        if (
            saved_replay_error is None
            and isinstance(saved_replay, dict)
            and saved_replay.get("status") == "pass"
            and not saved_replay.get("blockers", [])
        ):
            checks.append({"id": "publication_readiness_saved_replay_receipt", "status": "pass"})
        elif saved_replay_error is None:
            checks.append({"id": "publication_readiness_saved_replay_receipt", "status": "blocked"})
            errors.append(
                {
                    "code": "publication_readiness_saved_replay_not_pass",
                    "status": saved_replay.get("status") if isinstance(saved_replay, dict) else None,
                    "blocker_count": len(saved_replay.get("blockers", [])) if isinstance(saved_replay, dict) else None,
                }
            )

        replay_args = SimpleNamespace(
            repo=str(repo),
            remote=remote,
            tag=tag,
            repo_view_json=str(receipt_dir / "repo-view.json"),
            workflows_json=str(receipt_dir / "remote-workflows.json"),
            runs_json=str(receipt_dir / "remote-runs.json"),
            release_json=str(receipt_dir / "release-view.json"),
            signoff_json=str(receipt_dir / "release-signoff.receipt.json"),
            review_log=publication_readiness.REVIEW_LOG_PATH,
            review_json=str(receipt_dir / "external-review-release.json"),
            website_url=publication_readiness.WEBSITE_URL,
            install_url=publication_readiness.INSTALL_URL,
            install_sha256_url=publication_readiness.INSTALL_SHA256_URL,
            website_probe_json=str(receipt_dir / "website-probe.json"),
            install_probe_json=str(receipt_dir / "install-probe.json"),
            install_sha256_probe_json=str(receipt_dir / "install-sha256-probe.json"),
            skip_remote=False,
            release=True,
            json=True,
        )
        replay = publication_readiness.payload(replay_args)
        if replay.get("status") == "pass":
            checks.append({"id": "publication_readiness_replay", "status": "pass"})
        else:
            checks.append({"id": "publication_readiness_replay", "status": "blocked"})
            errors.append({"code": "publication_readiness_replay_blocked", "blockers": replay.get("blockers", [])})

    status = "pass" if not errors else "blocked"
    return {
        "schema_version": SCHEMA_VERSION,
        "status": status,
        "receipt_dir": str(receipt_dir),
        "repo": str(repo),
        "remote": remote,
        "tag": tag,
        "checks": checks,
        "errors": errors,
        "publication_readiness_replay": replay,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--receipt-dir", default=".")
    parser.add_argument("--repo", default=".")
    parser.add_argument("--remote", default="JYeswak/flywheel")
    parser.add_argument("--tag", default="v0.2.0")
    parser.add_argument("--release", action="store_true", help="exit non-zero when blocked")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    result = validate(Path(args.receipt_dir), Path(args.repo), args.remote, args.tag)
    if args.json:
        print(json.dumps(result, separators=(",", ":")))
    else:
        print(f"{result['status']} checks={len(result['checks'])} errors={len(result['errors'])}")

    if result["status"] == "pass":
        return 0
    return 1 if args.release else 20


if __name__ == "__main__":
    raise SystemExit(main())
