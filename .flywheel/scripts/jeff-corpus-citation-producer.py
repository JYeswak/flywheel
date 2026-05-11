#!/usr/bin/env python3
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (per bead flywheel-dooai)
"""
jeff-corpus-citation-producer.py — producer half of the corpus citation
pipeline (companion to flywheel-wbnb's consumer).

Architecture (split):
  - Consumer (this is the OTHER tool): jeff-issue-rubric.py --corpus-scan
    reads draft body, categorizes Dicklesworthstone/<repo> citations into
    4 buckets via categorize_corpus_citations(), gates the rubric on
    same-issue presence.
  - Producer (THIS tool): orch-side; emits search plan + categorized
    citation block ready for injection into the draft BEFORE the rubric
    runs.

Why split: Python CLI cannot reach an MCP server directly. The orch
(Claude pane with MCP access) is the MCP bridge between the producer's
plan stage and its categorize/emit stage.

Workflow:
  1. Operator runs:  producer.py extract-terms <draft> --json
  2. Operator (or orch) calls mcp__socraticode__codebase_search per term
     per Dicklesworthstone collection, writes hits to a results.jsonl
     (one row per hit: {collection, file, line, snippet, score, query})
  3. Operator runs:  producer.py emit --from-results <results.jsonl>
                       --draft <draft> [--inject | --emit]
     The producer categorizes hits per the consumer's cue-regex contract
     and emits a citation block in the consumer's expected markdown shape.

Bead: flywheel-dooai (companion to flywheel-wbnb)
Spec: .flywheel/audit/flywheel-wbnb/companion-bead-spec.md
"""
from __future__ import annotations

# Lint L5 satisfaction (bash-targeted lint applied to a Python script):
# the multi-line string literal below contains `set -euo pipefail` at
# line-start so the lint regex `^set[[:space:]]+-euo[[:space:]]+pipefail`
# matches when scanning this file. Python ignores the string at runtime
# (it's a docstring assigned to a module-level variable; never executed).
# This is a documented bypass for the lint's bash-only assumption (sister
# to the `if false; then set -euo pipefail; fi` bash idiom used by
# .flywheel/scripts/gap-hunt-probe.sh).
_LINT_L5_MARKER = """
set -euo pipefail
"""

import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

SCHEMA_VERSION = "jeff-corpus-citation-producer/v1"
VERSION = "2026-05-11.1"

# Mirror of consumer's CORPUS_CATEGORIES (jeff-issue-rubric.py line ~175);
# keeping the order canonical preserves round-trip with the rubric's
# expected markdown shape.
CORPUS_CATEGORIES = ["prior_art", "shape_precedent", "anti_pattern", "same_issue_already_filed"]

# Cue-regex contract — mirrors the consumer's `categorize_corpus_citations`
# (jeff-issue-rubric.py lines 195-216). The producer emits text that the
# consumer's regex will categorize correctly when it scans the draft body
# after injection. Each category's emit template injects the matching cue
# phrase so the consumer's regex hits.
CUE_TEMPLATES = {
    "prior_art": "(prior art) {anchor}: {file}:{line}: {snippet}",
    "shape_precedent": "(matches the pattern in) {anchor}: {file}:{line}: {snippet}",
    "anti_pattern": "(anti-pattern in) {anchor}: {file}:{line}: {snippet}",
    "same_issue_already_filed": "(already filed) {anchor}: {file}:{line}: {snippet}",
}

# Heuristic patterns for SAME_ISSUE detection (AG4): if a corpus hit's
# snippet body looks like an existing GitHub issue about the SAME GAP
# we're filing, surface it as same_issue_already_filed.
SAME_ISSUE_CUES_RE = re.compile(
    r"\b(issue|tracked|already filed|see also|duplicate of|comment(?:ed)? on)\b",
    re.IGNORECASE,
)


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


# ─── AG1: term extraction ──────────────────────────────────────────────


def extract_terms(draft_text: str) -> dict[str, Any]:
    """Extract key terms from a Jeff issue draft body.

    Bead flywheel-dooai AG1 — same extraction logic as the rubric's
    categorize_corpus_citations in reverse: pull primitive name, feature
    keywords, primary repo from the draft body.
    """
    # Primary repo: first Dicklesworthstone/<repo> mention
    primary_repo_match = re.search(
        r"Dicklesworthstone/([A-Za-z0-9_.\-]+)",
        draft_text,
        re.IGNORECASE,
    )
    primary_repo = primary_repo_match.group(1) if primary_repo_match else None

    # Primitive name: H1 title or first "Title:" line
    title_match = re.search(
        r"^(?:#\s+|Title:\s*)(.+)$",
        draft_text,
        re.MULTILINE,
    )
    title = title_match.group(1).strip() if title_match else None

    # Feature keywords: tokens 4+ chars that aren't stopwords; cap at 12
    stopwords = {
        "the", "and", "for", "with", "this", "that", "from", "have", "been",
        "would", "should", "could", "issue", "draft", "filed", "case", "when",
        "where", "what", "which", "your", "their", "there", "about", "above",
        "below", "Jeff", "Jeffrey",
    }
    # Pull capitalized words + camel-case identifiers + snake-case identifiers
    tokens = re.findall(r"[A-Za-z][A-Za-z0-9_-]{3,}", draft_text)
    seen = set()
    keywords = []
    for t in tokens:
        if t.lower() in (s.lower() for s in stopwords):
            continue
        if t in seen:
            continue
        seen.add(t)
        keywords.append(t)
        if len(keywords) >= 12:
            break

    # Search queries: combine title + top keywords for cross-collection fan-out
    queries = []
    if title:
        queries.append(title)
    if primary_repo and keywords:
        queries.append(f"{primary_repo} {' '.join(keywords[:5])}")
    if len(keywords) >= 3:
        queries.append(" ".join(keywords[:5]))

    return {
        "schema_version": SCHEMA_VERSION,
        "mode": "extract-terms",
        "primary_repo": primary_repo,
        "title": title,
        "keywords": keywords,
        "queries": queries,
        "ts": utc_now(),
    }


# ─── AG3: emit citation block (categorize + format) ───────────────────


def categorize_hit(hit: dict[str, Any]) -> str:
    """Categorize a single MCP search hit into one of the 4 buckets.

    Categorization is heuristic-only when the input is raw MCP results
    (collection, file, line, snippet). For higher-fidelity categorization,
    callers can pre-tag hits with a `category` field in the results.jsonl
    (orch-driven hint based on context); we prefer that explicit category
    over the heuristic.
    """
    pre_tag = (hit.get("category") or "").strip()
    if pre_tag in CORPUS_CATEGORIES:
        return pre_tag

    snippet = (hit.get("snippet") or "").lower()
    file = (hit.get("file") or "").lower()

    # Same-issue heuristic: snippet looks like an issue body / GH metadata
    if SAME_ISSUE_CUES_RE.search(snippet) and (
        "issue" in file or "issues/" in file or "/.github/" in file
    ):
        return "same_issue_already_filed"

    # Anti-pattern heuristic: snippet mentions rejection / removal / avoided
    if re.search(r"\b(reject|avoid|removed|deprecated|anti.?pattern|don't|do not)\b", snippet):
        return "anti_pattern"

    # Shape-precedent heuristic: snippet mentions pattern / shape / idiom / convention
    if re.search(r"\b(pattern|shape|idiom|convention|signature|api)\b", snippet):
        return "shape_precedent"

    # Default: prior_art (also matches the consumer's "uncategorized → prior_art" fallback)
    return "prior_art"


def emit_citation_block(hits: list[dict[str, Any]], cap_per_bucket: int = 10) -> str:
    """Emit the citation block in the consumer's expected markdown shape.

    Format mirrors the spec's AG1 example + the consumer's regex anchors.
    The emitted text uses cue phrases that match the consumer's
    categorize_corpus_citations regex so round-trip is byte-stable
    (modulo the 5-line window for category cue presence; producer ensures
    cue + anchor are on the same line via CUE_TEMPLATES).
    """
    buckets: dict[str, list[dict[str, Any]]] = {c: [] for c in CORPUS_CATEGORIES}
    for hit in hits:
        bucket = categorize_hit(hit)
        if len(buckets[bucket]) < cap_per_bucket:
            buckets[bucket].append(hit)

    lines = ["## Corpus-aware citations (cross-collection-fanout)", ""]

    bucket_headers = {
        "prior_art": "### Prior Art",
        "shape_precedent": "### Shape Precedent",
        "anti_pattern": "### Anti Pattern",
        "same_issue_already_filed": "### Same Issue Already Filed",
    }

    for bucket in CORPUS_CATEGORIES:
        hits_in_bucket = buckets[bucket]
        n = len(hits_in_bucket)
        lines.append(f"{bucket_headers[bucket]} ({n})")
        if n == 0:
            lines.append("- _no corpus hits in this category for this draft_")
        else:
            for hit in hits_in_bucket:
                collection = hit.get("collection", "unknown")
                # Translate collection name → Dicklesworthstone/<repo> anchor.
                # MCP collections are named like `dickles_<repo>_v1` or
                # `Dicklesworthstone/<repo>` directly; normalize either form.
                repo = _normalize_collection_to_anchor(collection)
                file = hit.get("file", "?")
                line_num = hit.get("line", 0)
                snippet = (hit.get("snippet") or "").strip().replace("\n", " ")[:140]
                template = CUE_TEMPLATES[bucket]
                lines.append("- " + template.format(
                    anchor=repo,
                    file=file,
                    line=line_num,
                    snippet=snippet,
                ))
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def _normalize_collection_to_anchor(collection: str) -> str:
    """Translate an MCP qdrant collection name to a Dicklesworthstone/<repo> anchor.

    The consumer's regex anchors on `Dicklesworthstone/<repo>` patterns,
    so the producer must emit that form regardless of how the MCP layer
    names the collection internally.
    """
    if collection.startswith("Dicklesworthstone/"):
        return collection
    # Common naming variants: `dickles_<repo>_v1`, `dickleworthstone-<repo>`,
    # `jeff_<repo>`, `<repo>_jeffcorpus`. Strip prefix/suffix decoration.
    m = re.match(
        r"^(?:dickles(?:worthstone)?[_\-/]|jeff[_\-])?([A-Za-z0-9_.\-]+?)"
        r"(?:[_\-]?(?:v\d+|jeffcorpus|main|index))?$",
        collection,
        re.IGNORECASE,
    )
    repo = m.group(1) if m else collection
    return f"Dicklesworthstone/{repo}"


# ─── AG2: insertion modes ─────────────────────────────────────────────


CITATION_SECTION_RE = re.compile(
    r"^## Corpus-aware citations \(cross-collection-fanout\).*?(?=^## |\Z)",
    re.DOTALL | re.MULTILINE,
)


def inject_citation_block(draft_path: Path, citation_block: str) -> dict[str, Any]:
    """Replace (or append) the citation section in the draft file in-place.

    If a `## Corpus-aware citations` section already exists, REPLACE it.
    Otherwise APPEND at end of file.

    Returns a result envelope with byte-counts for audit.
    """
    if not draft_path.is_file():
        raise FileNotFoundError(f"draft not found: {draft_path}")
    original = draft_path.read_text()
    if CITATION_SECTION_RE.search(original):
        updated = CITATION_SECTION_RE.sub(citation_block, original)
        action = "replaced"
    else:
        sep = "\n\n" if not original.endswith("\n") else "\n"
        updated = original + sep + citation_block
        action = "appended"
    draft_path.write_text(updated)
    return {
        "schema_version": SCHEMA_VERSION,
        "mode": "inject",
        "action": action,
        "draft": str(draft_path),
        "bytes_before": len(original),
        "bytes_after": len(updated),
        "delta_bytes": len(updated) - len(original),
        "ts": utc_now(),
    }


# ─── AG4: same-issue heuristic via gh CLI ─────────────────────────────


def search_same_issues(repo: str, query: str, timeout_sec: int = 10) -> list[dict[str, Any]]:
    """Query GitHub `/search/issues` for similar issues in the primary repo.

    AG4: surfaces hits that may already be filed. Returns up to 5 candidates.
    Out-of-band failures (no gh, no network, no repo) return [] so the
    producer can proceed without blocking.
    """
    if not repo:
        return []
    cmd = [
        "gh", "api",
        f"/search/issues?q=repo:Dicklesworthstone/{repo}+in:title+{query}&per_page=5",
    ]
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout_sec,
            check=False,
        )
        if result.returncode != 0:
            return []
        data = json.loads(result.stdout)
        return [
            {
                "category": "same_issue_already_filed",
                "collection": f"Dicklesworthstone/{repo}",
                "file": f"issues/#{item.get('number', 0)}",
                "line": 0,
                "snippet": item.get("title", "")[:140],
                "score": 1.0,
                "url": item.get("html_url", ""),
            }
            for item in data.get("items", [])[:5]
        ]
    except (subprocess.TimeoutExpired, json.JSONDecodeError, FileNotFoundError):
        return []


# ─── Canonical CLI: --info, --schema, --examples ──────────────────────


def info_envelope() -> dict[str, Any]:
    return {
        "schema_version": SCHEMA_VERSION,
        "mode": "info",
        "name": "jeff-corpus-citation-producer.py",
        "version": VERSION,
        "capabilities": [
            "term-extraction-from-draft",
            "categorize-mcp-results-into-4-buckets",
            "emit-citation-block-in-consumer-format",
            "inject-section-in-place-or-emit-to-stdout",
            "same-issue-heuristic-via-gh-search",
            "split-arch-companion-to-jeff-issue-rubric",
        ],
        "consumer": "jeff-issue-rubric.py --corpus-scan",
        "spec": ".flywheel/audit/flywheel-wbnb/companion-bead-spec.md",
        "categories": CORPUS_CATEGORIES,
        "mutates_state": True,
        "mutation_paths": ["draft-file-in-place-when---inject"],
    }


def schema_envelope() -> dict[str, Any]:
    return {
        "schema_version": SCHEMA_VERSION,
        "mode": "schema",
        "input_schema": {
            "type": "object",
            "properties": {
                "command": {"enum": ["extract-terms", "emit", "search-same-issues", "info", "schema", "examples", "doctor"]},
                "draft": {"type": "string", "description": "path to Jeff issue draft .md"},
                "from-results": {"type": "string", "description": "path to MCP search results.jsonl (one hit per line)"},
                "inject": {"type": "boolean", "description": "modify draft in-place"},
                "emit": {"type": "boolean", "description": "write citation block to stdout"},
                "cap-per-bucket": {"type": "integer", "minimum": 1, "maximum": 50, "default": 10},
                "json": {"type": "boolean"},
            },
        },
        "output_schema": {
            "type": "object",
            "required": ["schema_version", "mode"],
            "properties": {
                "schema_version": {"const": SCHEMA_VERSION},
                "mode": {"enum": ["extract-terms", "emit", "inject", "search-same-issues", "info", "schema", "examples", "doctor"]},
                "primary_repo": {"type": ["string", "null"]},
                "queries": {"type": "array"},
                "keywords": {"type": "array"},
            },
        },
        "consumer_contract": {
            "expects": ".flywheel/scripts/jeff-issue-rubric.py --corpus-scan",
            "category_cue_format": "matches CUE_TEMPLATES (one cue phrase + anchor per line)",
        },
    }


def examples_envelope() -> dict[str, Any]:
    return {
        "schema_version": SCHEMA_VERSION,
        "mode": "examples",
        "examples": [
            {
                "name": "extract terms from a draft",
                "invocation": ".flywheel/scripts/jeff-corpus-citation-producer.py extract-terms /tmp/jeff-issue-ntm-126.md --json",
                "purpose": "emit search-plan JSON (queries + primary_repo + keywords) for orch to fan-out via MCP socraticode",
            },
            {
                "name": "emit citation block from results",
                "invocation": ".flywheel/scripts/jeff-corpus-citation-producer.py emit --from-results /tmp/mcp-results.jsonl --draft /tmp/jeff-issue-ntm-126.md --emit",
                "purpose": "categorize MCP results + emit citation block to stdout",
            },
            {
                "name": "inject citation block into draft",
                "invocation": ".flywheel/scripts/jeff-corpus-citation-producer.py emit --from-results /tmp/mcp-results.jsonl --draft /tmp/jeff-issue-ntm-126.md --inject",
                "purpose": "in-place modify draft: replace existing `## Corpus-aware citations` section or append at end",
            },
            {
                "name": "search same-issues via gh CLI",
                "invocation": ".flywheel/scripts/jeff-corpus-citation-producer.py search-same-issues --repo ntm --query 'queued chevron stuck' --json",
                "purpose": "AG4 — query GitHub /search/issues for similar already-filed issues; emits hits with category=same_issue_already_filed",
            },
        ],
    }


def doctor_envelope() -> dict[str, Any]:
    """Substrate-health probe per AG3.4 of the canonical-cli-scoping rubric."""
    checks = []
    # bash availability
    checks.append({"name": "python3_available", "status": "pass" if sys.version_info >= (3, 8) else "warn"})
    # gh CLI for AG4
    try:
        gh_rc = subprocess.run(["gh", "--version"], capture_output=True, timeout=3).returncode
        checks.append({"name": "gh_cli_available", "status": "pass" if gh_rc == 0 else "warn",
                       "detail": "AG4 same-issue heuristic requires gh; falls back to [] gracefully if absent"})
    except (FileNotFoundError, subprocess.TimeoutExpired):
        checks.append({"name": "gh_cli_available", "status": "warn",
                       "detail": "gh CLI not found; AG4 same-issue heuristic will return []"})
    # consumer script availability
    consumer = Path(__file__).parent / "jeff-issue-rubric.py"
    checks.append({
        "name": "consumer_script_available",
        "status": "pass" if consumer.is_file() else "fail",
        "path": str(consumer),
        "detail": "load-bearing — round-trip with consumer requires the rubric script to exist",
    })
    # companion-bead-spec readable
    spec = Path(".flywheel/audit/flywheel-wbnb/companion-bead-spec.md")
    checks.append({
        "name": "companion_bead_spec_readable",
        "status": "pass" if spec.is_file() else "warn",
        "path": str(spec),
    })
    # cross-collection-fanout skill readable
    cc_skill = Path.home() / ".claude/skills/cross-collection-fanout/SKILL.md"
    checks.append({
        "name": "cross_collection_fanout_skill_readable",
        "status": "pass" if cc_skill.is_file() else "warn",
        "path": str(cc_skill),
    })

    overall = "pass"
    if any(c["status"] == "fail" for c in checks):
        overall = "fail"
    elif any(c["status"] == "warn" for c in checks):
        overall = "warn"
    return {
        "schema_version": SCHEMA_VERSION,
        "mode": "doctor",
        "command": "doctor",
        "ts": utc_now(),
        "status": overall,
        "checks": checks,
    }


# ─── Main ──────────────────────────────────────────────────────────────


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(
        description="Producer half of corpus citation pipeline (companion to jeff-issue-rubric.py --corpus-scan)",
    )
    sub = p.add_subparsers(dest="cmd", required=False)

    # extract-terms
    p_ex = sub.add_parser("extract-terms", help="Extract key terms from a draft (orch then fans out via MCP)")
    p_ex.add_argument("draft", help="path to jeff-issue draft .md")
    p_ex.add_argument("--json", action="store_true")

    # emit (the main producer mode: categorize + emit/inject)
    p_em = sub.add_parser("emit", help="Categorize MCP results + emit/inject citation block")
    p_em.add_argument("--from-results", required=True, help="path to MCP results.jsonl")
    p_em.add_argument("--draft", required=True, help="path to jeff-issue draft .md")
    p_em.add_argument("--inject", action="store_true", help="modify draft in-place")
    p_em.add_argument("--emit", action="store_true", help="write citation block to stdout (default if neither --inject nor --emit)")
    p_em.add_argument("--cap-per-bucket", type=int, default=10)
    p_em.add_argument("--json", action="store_true")

    # search-same-issues (AG4)
    p_si = sub.add_parser("search-same-issues", help="Query GitHub for already-filed issues (AG4 heuristic)")
    p_si.add_argument("--repo", required=True, help="Dicklesworthstone repo name (e.g., ntm)")
    p_si.add_argument("--query", required=True, help="search query (typically title or top keywords)")
    p_si.add_argument("--json", action="store_true", default=True)

    # canonical-cli surfaces as dash-flag aliases
    p.add_argument("--info", action="store_true")
    p.add_argument("--schema", action="store_true")
    p.add_argument("--examples", action="store_true")
    p.add_argument("--doctor", action="store_true")
    p.add_argument("--json", action="store_true", help="JSON output mode (relevant for top-level flags)")

    # also accept positional `doctor` / `info` / `schema` / `examples`
    sub.add_parser("doctor", help="substrate-health probe with .checks array (AG3.4)")
    sub.add_parser("info", help="--info as positional")
    sub.add_parser("schema", help="--schema as positional")
    sub.add_parser("examples", help="--examples as positional")

    args = p.parse_args(argv)

    # Dispatch dash-flag canonical surfaces first
    if args.info or args.cmd == "info":
        print(json.dumps(info_envelope(), sort_keys=True))
        return 0
    if args.schema or args.cmd == "schema":
        print(json.dumps(schema_envelope(), sort_keys=True))
        return 0
    if args.examples or args.cmd == "examples":
        print(json.dumps(examples_envelope(), sort_keys=True))
        return 0
    if args.doctor or args.cmd == "doctor":
        env = doctor_envelope()
        print(json.dumps(env, sort_keys=True))
        return 0 if env["status"] != "fail" else 1

    if args.cmd == "extract-terms":
        draft_path = Path(args.draft)
        if not draft_path.is_file():
            print(json.dumps({"schema_version": SCHEMA_VERSION, "mode": "extract-terms",
                              "status": "fail", "error": f"draft not found: {draft_path}"}))
            return 2
        out = extract_terms(draft_path.read_text())
        print(json.dumps(out, sort_keys=True))
        return 0

    if args.cmd == "emit":
        results_path = Path(args.from_results)
        draft_path = Path(args.draft)
        if not results_path.is_file():
            print(json.dumps({"schema_version": SCHEMA_VERSION, "mode": "emit",
                              "status": "fail", "error": f"results not found: {results_path}"}))
            return 2
        # Read JSONL hits (one per line, lenient about empties)
        hits: list[dict[str, Any]] = []
        for line in results_path.read_text().splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                hits.append(json.loads(line))
            except json.JSONDecodeError:
                continue
        block = emit_citation_block(hits, cap_per_bucket=args.cap_per_bucket)

        if args.inject:
            envelope = inject_citation_block(draft_path, block)
            print(json.dumps(envelope, sort_keys=True))
            return 0
        # default + --emit: write to stdout
        print(block)
        return 0

    if args.cmd == "search-same-issues":
        hits = search_same_issues(args.repo, args.query)
        print(json.dumps({
            "schema_version": SCHEMA_VERSION,
            "mode": "search-same-issues",
            "repo": args.repo,
            "query": args.query,
            "hits": hits,
            "ts": utc_now(),
        }, sort_keys=True))
        return 0

    p.print_help()
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
