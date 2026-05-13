#!/usr/bin/env python3
"""Check Flywheel publication readiness without hiding remote blockers."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import subprocess
import sys
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


SKILLOS_BOUNDARY_DOC = "docs/concepts/" + "skil" + "los-boundary.md"

REQUIRED_LOCAL_FILES = [
    "README.md",
    "LICENSE",
    "CHARTER.md",
    "CHANGELOG.md",
    "CODE_OF_CONDUCT.md",
    "CONTRIBUTING.md",
    "SECURITY.md",
    "SUPPORT.md",
    "ARCHITECTURE.md",
    "install.sh",
    "uninstall.sh",
    "scripts/preflight.sh",
    "scripts/local-actions-preflight.sh",
    "scripts/journey-smoke.sh",
    "scripts/agent-lane-probe.sh",
    ".github/workflows/ci.yml",
    ".github/workflows/installer-smoke.yml",
    ".github/workflows/release.yml",
    ".github/workflows/site.yml",
    "docs/concepts/loops.md",
    "docs/concepts/beads.md",
    "docs/concepts/agent-mail.md",
    "docs/concepts/socraticode.md",
    SKILLOS_BOUNDARY_DOC,
    "docs/concepts/evidence-contracts.md",
    "docs/evidence/publication-evidence.md",
    "docs/evidence/publication-blocker-coverage.md",
    "docs/evidence/asupersync-gated-adoption.md",
    "docs/evidence/asupersync-poc-receipt.template.json",
    "docs/evidence/asupersync-poc-receipt.local.json",
    "docs/evidence/external-review-log.jsonl",
    "docs/getting-started/first-run.md",
    "docs/runbooks/public-release-runbook.md",
    "docs/runbooks/release-cutover-authorization.md",
    "docs/runbooks/agent-lane-compatibility.md",
    "docs/runbooks/context-and-model-routing.md",
    "docs/runbooks/local-actions-preflight.md",
    "docs/runbooks/upstream-substrate-adoption.md",
    "docs/runbooks/public-user-journey-pack.md",
    "docs/reference/commands.md",
    "docs/reference/files.md",
    "docs/reference/troubleshooting.md",
    "receipts/agent-lanes/claude.json",
    "receipts/agent-lanes/codex.json",
    "receipts/agent-lanes/gemini.json",
    "receipts/agent-lanes/openclaw.json",
    "scripts/assemble.py",
    "scripts/classify.py",
    "scripts/check_links.py",
    "scripts/depersonalize.py",
    "scripts/review_queue.py",
    "scripts/validate_external_review.py",
    "scripts/validate_cutover_receipts.py",
    "scripts/validate_user_journey_pack.py",
    "scripts/live_site_probe.py",
    "scripts/website_accessibility.py",
    "scripts/contact_route_probe.py",
    ".flywheel/scripts/public-surface-gap-scanner.py",
    ".flywheel/scripts/true-publication-registry-validate.py",
    "tests/public-top-level-files.sh",
    "tests/public-surface-gap-scanner.sh",
    "tests/changelog.sh",
    "tests/github-workflows.sh",
    "tests/naming-conventions.sh",
    "tests/context-routing-discipline.sh",
    "tests/cutover-receipts.sh",
    "tests/external-review-gate.sh",
    "tests/public-docs.sh",
    "tests/public-links.sh",
    "tests/publication-readiness.sh",
    "tests/public-user-journey-pack.sh",
    "tests/installer-smoke.sh",
    "tests/journey-smoke.sh",
    "tests/agent-lane-probe.sh",
    "tests/preflight-fixtures.sh",
    "tests/true-publication-registry-validate.sh",
    "tests/website-static.sh",
    "tests/website-accessibility.sh",
    "tests/live-site-probe.sh",
    "tests/contact-routing.sh",
    "tests/upstream-substrate-adoption.sh",
    "tests/release-assets.sh",
    "site/index.html",
    "site/what-is/index.html",
    "site/for-developers/index.html",
    "site/methodology/index.html",
    "site/about/index.html",
    "site/contact/index.html",
    "site/styles.css",
    "site/assets/loop-map.svg",
]
REQUIRED_WORKFLOWS = {"CI", "Installer Smoke", "Release", "Site Deploy"}
SUCCESS_CONCLUSIONS = {"success"}
SIGNOFF_PATH = ".flywheel/PLANS/public-share-readiness-2026-05-12/release-signoff.json"
REVIEW_LOG_PATH = "docs/evidence/external-review-log.jsonl"
WEBSITE_URL = "https://flywheel.zeststream.ai/"
INSTALL_URL = "https://flywheel.zeststream.ai/install.sh"
INSTALL_SHA256_URL = "https://flywheel.zeststream.ai/install.sh.sha256"


def load_json(path: str | None) -> Any:
    if not path:
        return None
    return json.loads(Path(path).read_text())


def load_json_for_repo(repo: Path, path: str | None) -> Any:
    if not path:
        return None
    candidate = Path(path)
    if not candidate.is_absolute():
        candidate = repo / candidate
    if not candidate.exists():
        return None
    return json.loads(candidate.read_text())


def run_json(command: list[str]) -> tuple[Any | None, str | None]:
    try:
        proc = subprocess.run(command, check=False, capture_output=True, text=True)
    except FileNotFoundError as exc:
        return None, f"missing_command:{exc.filename}"
    if proc.returncode != 0:
        detail = (proc.stderr or proc.stdout).strip()
        return None, f"command_failed:{' '.join(command)}:{detail}"
    try:
        return json.loads(proc.stdout or "null"), None
    except json.JSONDecodeError as exc:
        return None, f"invalid_json:{' '.join(command)}:{exc}"


def run_json_any_exit(command: list[str]) -> tuple[Any | None, str | None, int]:
    try:
        proc = subprocess.run(command, check=False, capture_output=True, text=True)
    except FileNotFoundError as exc:
        return None, f"missing_command:{exc.filename}", 127
    try:
        return json.loads(proc.stdout or "null"), None, proc.returncode
    except json.JSONDecodeError as exc:
        detail = (proc.stderr or proc.stdout).strip()
        return None, f"invalid_json:{' '.join(command)}:{exc}:{detail}", proc.returncode


def gh_repo(remote: str) -> tuple[Any | None, str | None]:
    return run_json(["gh", "repo", "view", remote, "--json", "nameWithOwner,url,visibility,defaultBranchRef,isPrivate"])


def gh_workflows(remote: str) -> tuple[Any | None, str | None]:
    return run_json(["gh", "api", f"repos/{remote}/actions/workflows", "--jq", ".workflows"])


def gh_runs(remote: str) -> tuple[Any | None, str | None]:
    return run_json(
        [
            "gh",
            "run",
            "list",
            "--repo",
            remote,
            "--limit",
            "20",
            "--json",
            "databaseId,status,conclusion,workflowName,headBranch,createdAt",
        ]
    )


def gh_release(remote: str, tag: str) -> tuple[Any | None, str | None]:
    return run_json(
        [
            "gh",
            "release",
            "view",
            tag,
            "--repo",
            remote,
            "--json",
            "tagName,isDraft,isPrerelease,url,assets",
        ]
    )


def local_checks(repo: Path) -> tuple[list[dict[str, str]], list[dict[str, str]]]:
    checks: list[dict[str, str]] = []
    blockers: list[dict[str, str]] = []
    for rel in REQUIRED_LOCAL_FILES:
        path = repo / rel
        status = "pass" if path.exists() and path.stat().st_size > 0 else "blocked"
        checks.append({"id": f"local_file:{rel}", "status": status})
        if status != "pass":
            blockers.append({"code": "local_required_file_missing", "path": rel})
    return checks, blockers


def workflow_names(workflows: Any) -> set[str]:
    if not isinstance(workflows, list):
        return set()
    return {str(row.get("name") or "") for row in workflows if isinstance(row, dict)}


def repo_default_branch(repo_view: Any) -> str:
    if not isinstance(repo_view, dict):
        return ""
    default_branch = repo_view.get("defaultBranchRef")
    if isinstance(default_branch, dict):
        return str(default_branch.get("name") or "")
    return ""


def successful_run_names(runs: Any, branch: str = "") -> set[str]:
    if not isinstance(runs, list):
        return set()
    return {
        str(row.get("workflowName") or "")
        for row in runs
        if isinstance(row, dict)
        and row.get("conclusion") in SUCCESS_CONCLUSIONS
        and (not branch or row.get("headBranch") == branch)
    }


def release_asset_names(release: Any) -> set[str]:
    if not isinstance(release, dict) or not isinstance(release.get("assets"), list):
        return set()
    return {
        str(row.get("name") or "")
        for row in release["assets"]
        if isinstance(row, dict)
    }


def invalid_release_assets(release: Any, required_assets: set[str]) -> list[str]:
    if not isinstance(release, dict) or not isinstance(release.get("assets"), list):
        return sorted(required_assets)
    rows_by_name: dict[str, list[dict[str, Any]]] = {}
    for row in release["assets"]:
        if isinstance(row, dict):
            rows_by_name.setdefault(str(row.get("name") or ""), []).append(row)
    invalid = []
    for name in sorted(required_assets):
        rows = rows_by_name.get(name, [])
        if len(rows) != 1:
            invalid.append(name)
            continue
        row = rows[0]
        if row.get("state") != "uploaded":
            invalid.append(name)
            continue
        size = row.get("size")
        if not isinstance(size, int) or size <= 0:
            invalid.append(name)
            continue
        digest = str(row.get("digest") or "")
        if not valid_sha256_digest(digest):
            invalid.append(name)
    return invalid


def valid_sha256_digest(value: str) -> bool:
    prefix = "sha256:"
    if not value.startswith(prefix):
        return False
    digest = value[len(prefix) :]
    return len(digest) == 64 and all(ch in "0123456789abcdefABCDEF" for ch in digest)


def required_release_assets(tag: str) -> set[str]:
    return {
        "install.sh",
        "install.sh.sha256",
        "SHA256SUMS",
        f"flywheel-{tag}.tar.gz",
        f"flywheel-{tag}.tar.gz.sha256",
    }


def probe_url(url: str, timeout: float = 8.0) -> tuple[dict[str, Any] | None, str | None]:
    request = Request(url, headers={"User-Agent": "flywheel-publication-readiness/0.1"})
    try:
        with urlopen(request, timeout=timeout) as response:
            body = response.read(2_000_000)
            status_code = int(getattr(response, "status", 0) or response.getcode())
            headers = dict(response.headers.items())
    except HTTPError as exc:
        return {"url": url, "status_code": exc.code, "body_sha256": "", "body_text": ""}, None
    except URLError as exc:
        return None, f"url_probe_failed:{url}:{exc.reason}"
    except TimeoutError:
        return None, f"url_probe_failed:{url}:timeout"

    text = body.decode("utf-8", errors="replace")
    return {
        "url": url,
        "status_code": status_code,
        "content_type": headers.get("Content-Type", ""),
        "body_sha256": hashlib.sha256(body).hexdigest(),
        "body_text": text[:2000],
    }, None


def load_or_probe(path: str | None, url: str, probe_errors: list[str]) -> Any:
    loaded = load_json(path)
    if loaded is not None:
        return loaded
    probed, err = probe_url(url)
    if err:
        probe_errors.append(err)
    return probed


def ok_status(probe: Any) -> bool:
    return isinstance(probe, dict) and 200 <= int(probe.get("status_code") or 0) < 400


def sha256_from_probe(probe: Any) -> str:
    if not isinstance(probe, dict):
        return ""
    return str(probe.get("body_sha256") or "")


def expected_sha_from_probe(probe: Any) -> str:
    if not isinstance(probe, dict):
        return ""
    text = str(probe.get("body_text") or "").strip()
    first = text.split()[0] if text else ""
    if len(first) == 64 and all(ch in "0123456789abcdefABCDEF" for ch in first):
        return first.lower()
    return ""


def signoff_ok(signoff: Any, tag: str, remote: str) -> bool:
    if not isinstance(signoff, dict):
        return False
    if signoff.get("schema_version") != "flywheel.release_signoff.v0":
        return False
    if signoff.get("status") != "approved":
        return False
    if signoff.get("tag") != tag or signoff.get("remote") != remote:
        return False
    approver = str(signoff.get("approver") or "").strip()
    if approver != "Joshua Nowak":
        return False
    signed_at = str(signoff.get("signed_at") or "").strip()
    if not signed_at.endswith("Z"):
        return False
    try:
        dt.datetime.fromisoformat(signed_at.removesuffix("Z") + "+00:00")
    except ValueError:
        return False
    return True


def external_review_gate(repo: Path, review_log: str) -> tuple[Any | None, str | None, int]:
    path = Path(review_log)
    if not path.is_absolute():
        path = repo / path
    script = repo / "scripts" / "validate_external_review.py"
    return run_json_any_exit([sys.executable, str(script), "--log", str(path), "--release", "--json"])


ACTION_BY_CODE = {
    "local_required_file_missing": {
        "owner": "Flywheel",
        "action": "Restore or generate the required local file, then rerun publication readiness.",
        "command": "python3 scripts/publication_readiness.py --json",
    },
    "remote_probe_skipped": {
        "owner": "Flywheel",
        "action": "Run the gate without --skip-remote so live publication truth is checked.",
        "command": "python3 scripts/publication_readiness.py --release --json",
    },
    "remote_repo_unavailable": {
        "owner": "Joshua",
        "action": "Make sure gh is authenticated and the target repository exists.",
        "command": "gh repo view JYeswak/flywheel --json nameWithOwner,visibility,isPrivate",
    },
    "remote_repo_private": {
        "owner": "Joshua",
        "action": "Make the approved repository or export path public after reviewing the public surface.",
        "command": "gh repo edit JYeswak/flywheel --visibility public",
    },
    "remote_workflows_missing": {
        "owner": "Flywheel",
        "action": "Push the workflow files to the public default branch and confirm Actions sees them.",
        "command": "gh api repos/JYeswak/flywheel/actions/workflows --jq '.workflows[].name'",
    },
    "remote_green_runs_missing": {
        "owner": "Flywheel",
        "action": "Run CI and Installer Smoke on the public repository until both conclude success.",
        "command": "gh run list --repo JYeswak/flywheel --limit 20 --json workflowName,status,conclusion,headBranch",
    },
    "github_release_missing_or_draft": {
        "owner": "Flywheel",
        "action": "Create or publish the final v0.2.0 GitHub release only after all release gates pass.",
        "command": "git tag v0.2.0 && git push origin v0.2.0",
    },
    "github_release_assets_missing": {
        "owner": "Flywheel",
        "action": "Run the release workflow and verify all required release assets are attached.",
        "command": "gh release view v0.2.0 --repo JYeswak/flywheel --json tagName,isDraft,isPrerelease,assets",
    },
    "website_unavailable": {
        "owner": "Flywheel",
        "action": "Deploy the GitHub Pages site and verify the custom domain resolves.",
        "command": "curl -fsSI https://flywheel.zeststream.ai/",
    },
    "install_proxy_checksum_mismatch": {
        "owner": "Flywheel",
        "action": "Publish install.sh and install.sh.sha256 from the same release artifact set.",
        "command": "actual=\"$(curl -fsSL https://flywheel.zeststream.ai/install.sh | shasum -a 256 | awk '{print $1}')\"; expected=\"$(curl -fsSL https://flywheel.zeststream.ai/install.sh.sha256 | awk '{print $1}')\"; test \"$actual\" = \"$expected\"",
    },
    "joshua_release_signoff_missing": {
        "owner": "Joshua",
        "action": "Create release-signoff.json from the template only after all real checks pass.",
        "command": "cp .flywheel/PLANS/public-share-readiness-2026-05-12/release-signoff.template.json .flywheel/PLANS/public-share-readiness-2026-05-12/release-signoff.json",
    },
    "external_review_gate_blocked": {
        "owner": "Flywheel",
        "action": "Collect two distinct non-Joshua external review rows with approved or approved_with_followups verdicts.",
        "command": "python3 scripts/validate_external_review.py --release --json",
    },
}


def next_actions(blockers: list[dict[str, str]]) -> list[dict[str, str]]:
    actions = []
    seen: set[str] = set()
    for blocker in blockers:
        code = blocker.get("code", "")
        if not code or code in seen:
            continue
        seen.add(code)
        template = ACTION_BY_CODE.get(
            code,
            {
                "owner": "Flywheel",
                "action": "Inspect the blocker and add an explicit runbook action.",
                "command": "python3 scripts/publication_readiness.py --json",
            },
        )
        actions.append({"code": code, "blocker_code": code, **template})
    return actions


def enrich_blockers(blockers: list[dict[str, str]]) -> list[dict[str, str]]:
    enriched = []
    for blocker in blockers:
        code = blocker.get("code", "")
        template = ACTION_BY_CODE.get(
            code,
            {
                "owner": "Flywheel",
                "action": "Inspect the blocker and add an explicit runbook action.",
                "command": "python3 scripts/publication_readiness.py --json",
            },
        )
        enriched.append(
            {
                **blocker,
                "owner": template["owner"],
                "summary": template["action"],
                "next_action": template["action"],
                "command": template["command"],
            }
        )
    return enriched


def payload(args: argparse.Namespace) -> dict[str, Any]:
    repo = Path(args.repo).resolve()
    blockers: list[dict[str, str]] = []
    checks, local_blockers = local_checks(repo)
    blockers.extend(local_blockers)

    repo_view = load_json(args.repo_view_json)
    workflows = load_json(args.workflows_json)
    runs = load_json(args.runs_json)
    release = load_json(args.release_json)
    signoff = load_json_for_repo(repo, args.signoff_json)
    review_result = load_json(args.review_json)
    probe_errors: list[str] = []
    website_probe = None
    install_probe = None
    install_sha_probe = None

    if not args.skip_remote:
        if repo_view is None:
            repo_view, err = gh_repo(args.remote)
            if err:
                probe_errors.append(err)
        if workflows is None:
            workflows, err = gh_workflows(args.remote)
            if err:
                probe_errors.append(err)
        if runs is None:
            runs, err = gh_runs(args.remote)
            if err:
                probe_errors.append(err)
        if release is None:
            release, err = gh_release(args.remote, args.tag)
            if err:
                probe_errors.append(err)
        if review_result is None:
            review_result, err, _ = external_review_gate(repo, args.review_log)
            if err:
                probe_errors.append(err)
        website_probe = load_or_probe(args.website_probe_json, args.website_url, probe_errors)
        install_probe = load_or_probe(args.install_probe_json, args.install_url, probe_errors)
        install_sha_probe = load_or_probe(args.install_sha256_probe_json, args.install_sha256_url, probe_errors)

    if args.skip_remote:
        checks.append({"id": "remote_probe", "status": "skipped"})
        blockers.append({"code": "remote_probe_skipped", "reason": "remote publication truth not checked"})
    else:
        if not isinstance(repo_view, dict):
            blockers.append({"code": "remote_repo_unavailable", "remote": args.remote})
        elif repo_view.get("isPrivate") is True or str(repo_view.get("visibility", "")).upper() != "PUBLIC":
            blockers.append({"code": "remote_repo_private", "remote": args.remote})
        else:
            checks.append({"id": "remote_repo_public", "status": "pass"})

        names = workflow_names(workflows)
        missing_workflows = sorted(REQUIRED_WORKFLOWS - names)
        if missing_workflows:
            blockers.append({"code": "remote_workflows_missing", "missing": ",".join(missing_workflows)})
        else:
            checks.append({"id": "remote_workflows_present", "status": "pass"})

        green_runs = successful_run_names(runs, repo_default_branch(repo_view))
        missing_green = sorted({"CI", "Installer Smoke"} - green_runs)
        if missing_green:
            blockers.append({"code": "remote_green_runs_missing", "missing": ",".join(missing_green)})
        else:
            checks.append({"id": "remote_green_runs_present", "status": "pass"})

        if (
            not isinstance(release, dict)
            or release.get("tagName") != args.tag
            or release.get("isDraft") is True
            or release.get("isPrerelease") is True
        ):
            blockers.append({"code": "github_release_missing_or_draft", "tag": args.tag})
        else:
            checks.append({"id": "github_release_published", "status": "pass"})

        required_assets = required_release_assets(args.tag)
        missing_assets = sorted(required_assets - release_asset_names(release))
        invalid_assets = invalid_release_assets(release, required_assets)
        if missing_assets:
            blockers.append({"code": "github_release_assets_missing", "missing": ",".join(missing_assets)})
        elif invalid_assets:
            blockers.append({"code": "github_release_assets_missing", "invalid": ",".join(invalid_assets)})
        else:
            checks.append({"id": "github_release_assets_present", "status": "pass"})

        if ok_status(website_probe):
            checks.append({"id": "website_reachable", "status": "pass"})
        else:
            blockers.append({"code": "website_unavailable", "url": args.website_url})

        install_hash = sha256_from_probe(install_probe)
        expected_install_hash = expected_sha_from_probe(install_sha_probe)
        if ok_status(install_probe) and ok_status(install_sha_probe) and install_hash and install_hash == expected_install_hash:
            checks.append({"id": "install_proxy_checksum_match", "status": "pass"})
        else:
            blockers.append({"code": "install_proxy_checksum_mismatch", "url": args.install_url})

        if signoff_ok(signoff, args.tag, args.remote):
            checks.append({"id": "joshua_release_signoff", "status": "pass"})
        else:
            signoff_path = Path(args.signoff_json)
            if not signoff_path.is_absolute():
                signoff_path = repo / signoff_path
            blockers.append({"code": "joshua_release_signoff_missing", "path": str(signoff_path)})

        if isinstance(review_result, dict) and review_result.get("status") == "pass":
            checks.append({"id": "external_review_gate", "status": "pass"})
        else:
            blockers.append({"code": "external_review_gate_blocked", "path": args.review_log})

    status = "pass" if not blockers else "blocked"
    return {
        "schema_version": "flywheel.publication_readiness.v0",
        "status": status,
        "repo": str(repo),
        "remote": args.remote,
        "tag": args.tag,
        "checks": checks,
        "blockers": enrich_blockers(blockers),
        "next_actions": next_actions(blockers),
        "probe_errors": probe_errors,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", default=".")
    parser.add_argument("--remote", default="JYeswak/flywheel")
    parser.add_argument("--tag", default="v0.2.0")
    parser.add_argument("--repo-view-json")
    parser.add_argument("--workflows-json")
    parser.add_argument("--runs-json")
    parser.add_argument("--release-json")
    parser.add_argument("--signoff-json", default=SIGNOFF_PATH)
    parser.add_argument("--review-log", default=REVIEW_LOG_PATH)
    parser.add_argument("--review-json")
    parser.add_argument("--website-url", default=WEBSITE_URL)
    parser.add_argument("--install-url", default=INSTALL_URL)
    parser.add_argument("--install-sha256-url", default=INSTALL_SHA256_URL)
    parser.add_argument("--website-probe-json")
    parser.add_argument("--install-probe-json")
    parser.add_argument("--install-sha256-probe-json")
    parser.add_argument("--skip-remote", action="store_true")
    parser.add_argument("--release", action="store_true", help="exit non-zero when blocked")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    result = payload(args)
    if args.json:
        print(json.dumps(result, separators=(",", ":")))
    else:
        print(f"{result['status']} blockers={len(result['blockers'])}")

    if result["status"] == "pass":
        return 0
    return 1 if args.release else 20


if __name__ == "__main__":
    raise SystemExit(main())
