#!/usr/bin/env python3
"""Presence pipeline — TRIGGER -> DRAFT -> BRAND-GATE -> REVIEW.

Turns a shipped piece of work into a brand-gated, publish-ready per-channel
queue for Joshua to review. This is the toil-automation half of the presence
pipeline (docs/runbooks/presence-pipeline-architecture.md): drafting,
brand-gating, per-channel formatting, link-back wiring, queueing. It does NOT
post anything — PUBLISH and the live-channel social review stay Joshua's, and
need channel handles this script never touches.

The honest boundary: DRAFT assembles a channel-shaped scaffold from *grounded*
inputs (a ship descriptor whose every claim already carries a receipt + a
source). BRAND-GATE is mechanical — banned words/phrases, first-person-singular
pronouns, Jeffrey Emanuel attribution, link-back presence, channel length, and
the arc-not-stats heuristic (doctrine II-2a). Editorial polish is the REVIEW
step, where the brand-voice skill or Joshua refines the prose. A draft that
fails the gate is queued as `blocked` with reasons, never silently dropped.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from pathlib import Path
from typing import Any

SCHEMA_VERSION = "zeststream.presence_queue.v0"

DEFAULT_VOICE_YAML = Path(
    "~/.claude/skills/zeststream-brand-voice/brands/zeststream/voice.yaml"
).expanduser()

# Jeffrey Emanuel's substrate — naming any of these in a draft requires the
# attribution (brand-voice hard rule 8). github.com/Dicklesworthstone or
# www.jeffreyemanuel.com satisfies the link half.
SUBSTRATE_TERMS = ("NTM", "Agent Mail", "mcp-agent-mail", "beads", "CASS")
ATTRIBUTION_NAME = "Jeffrey Emanuel"
ATTRIBUTION_LINK_RE = re.compile(
    r"(jeffreyemanuel\.com|github\.com/Dicklesworthstone)", re.IGNORECASE
)

# arc-not-stats (II-2a): a post tells the arc it advances, not a pile of
# numbers. More than this many numeric tokens trips a warning, not a block.
MAX_NUMERIC_TOKENS = 2
NUMERIC_TOKEN_RE = re.compile(r"\b\d[\d,]*(?:\.\d+)?%?\b|\$\d|\b\d+x\b|\d+×")

# Superlative backstop on top of voice.yaml banned_words.
SUPERLATIVE_RE = re.compile(
    r"\b(best|fastest|smartest|most advanced|world.?class|unmatched|unparalleled|"
    r"ultimate|revolutionary|leading)\b",
    re.IGNORECASE,
)

# First-person-singular posture: ZestStream is Joshua solo.
PRONOUN_BANNED_RE = re.compile(r"\b(we|we're|we've|our|ours|us)\b", re.IGNORECASE)

CHANNELS: dict[str, dict[str, Any]] = {
    "x": {
        "max_chars": 280,
        "register": "short, sharp — one receipt or one arc beat",
        "template": "{receipt}\n\n{link_back}",
    },
    "linkedin": {
        "max_chars": 1300,
        "register": "professional, longer-form — the arc",
        "template": (
            "{title}\n\n{arc_beat}\n\n"
            "The receipt: {receipt}\n\n"
            "More on how this fits the bigger picture: {link_back}"
        ),
    },
    "instagram": {
        "max_chars": 2200,
        "register": "visual-first caption — the artifact, the before/after",
        "template": (
            "{title}\n\n{arc_beat}\n\n{receipt}\n\n"
            "Full story: {link_back}"
        ),
    },
    "facebook": {
        "max_chars": 2000,
        "register": "plain-language, owner-facing — least jargon",
        "template": (
            "{title}\n\n{arc_beat}\n\n{receipt}\n\n"
            "I wrote up the whole thing here: {link_back}"
        ),
    },
}

REQUIRED_SHIP_FIELDS = ("title", "arc_beat", "receipt", "receipt_source", "link_back")


def load_voice(voice_path: Path) -> dict[str, Any]:
    """Load the brand-voice constants. Missing file is a hard error — the gate
    is meaningless without it (a gate you can't trust is back to square one)."""
    if not voice_path.exists():
        raise SystemExit(
            f"brand-voice constants not found: {voice_path}\n"
            "set ZS_VOICE_YAML or pass --voice-yaml"
        )
    import yaml  # local import: only the gate path needs it

    data = yaml.safe_load(voice_path.read_text(encoding="utf-8")) or {}
    banned_words = [str(w).lower() for w in data.get("banned_words", [])]
    banned_phrases = [str(p).lower() for p in data.get("banned_phrases", [])]
    return {"banned_words": banned_words, "banned_phrases": banned_phrases}


def load_ship(args: argparse.Namespace) -> dict[str, Any]:
    """TRIGGER input — a ship descriptor (JSON file or stdin)."""
    if args.ship:
        raw = Path(args.ship).read_text(encoding="utf-8")
    else:
        raw = sys.stdin.read()
    if not raw.strip():
        raise SystemExit("no ship descriptor provided (--ship FILE or stdin)")
    try:
        ship = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"ship descriptor is not valid JSON: {exc}") from exc
    if not isinstance(ship, dict):
        raise SystemExit("ship descriptor must be a JSON object")
    return ship


def trigger_check(ship: dict[str, Any]) -> list[str]:
    """Is this a *meaningful ship* — curated, not firehose? Every required
    field present and non-empty, and the receipt is grounded by a source."""
    errors: list[str] = []
    for field in REQUIRED_SHIP_FIELDS:
        value = ship.get(field)
        if not value or not str(value).strip():
            errors.append(f"missing or empty required field: {field}")
    link_back = str(ship.get("link_back", ""))
    if link_back and not link_back.startswith(("http://", "https://")):
        errors.append("link_back must be an absolute URL (the canonical surface)")
    return errors


def slugify(text: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return (slug[:50] or "ship").rstrip("-")


def draft_channel(spec: dict[str, Any], ship: dict[str, Any]) -> str:
    """DRAFT — assemble a channel-shaped scaffold from the grounded descriptor."""
    return spec["template"].format(
        title=str(ship["title"]).strip(),
        arc_beat=str(ship["arc_beat"]).strip(),
        receipt=str(ship["receipt"]).strip(),
        link_back=str(ship["link_back"]).strip(),
    )


def brand_gate(
    channel: str,
    spec: dict[str, Any],
    text: str,
    ship: dict[str, Any],
    voice: dict[str, Any],
) -> dict[str, Any]:
    """BRAND-GATE — mechanical brand checks. Blocks on hard rules, warns on
    the arc-not-stats heuristic."""
    blockers: list[str] = []
    warnings: list[str] = []
    lowered = text.lower()

    for word in voice["banned_words"]:
        if re.search(rf"\b{re.escape(word)}\b", lowered):
            blockers.append(f"banned word: {word!r}")
    for phrase in voice["banned_phrases"]:
        if phrase in lowered:
            blockers.append(f"banned phrase: {phrase!r}")

    sup = SUPERLATIVE_RE.search(text)
    if sup:
        blockers.append(f"superlative: {sup.group(0)!r}")

    pron = PRONOUN_BANNED_RE.search(text)
    if pron:
        blockers.append(
            f"first-person-singular violation: {pron.group(0)!r} "
            "(ZestStream is Joshua solo — use 'I'/'my')"
        )

    link_back = str(ship["link_back"]).strip()
    if link_back not in text:
        blockers.append("link-back missing (every post links to the canonical surface)")

    declared = [str(t) for t in ship.get("substrate_credit", []) if str(t).strip()]
    named = sorted(
        {term for term in SUBSTRATE_TERMS if re.search(rf"\b{re.escape(term)}\b", text)}
        | set(declared)
    )
    if named:
        if ATTRIBUTION_NAME not in text:
            blockers.append(
                f"substrate named {named} but Jeffrey Emanuel not credited "
                "(brand-voice hard rule)"
            )
        if not ATTRIBUTION_LINK_RE.search(text):
            blockers.append(
                f"substrate named {named} but no link to jeffreyemanuel.com / "
                "github.com/Dicklesworthstone"
            )

    if len(text) > spec["max_chars"]:
        blockers.append(
            f"over {channel} length limit: {len(text)} > {spec['max_chars']} chars"
        )

    numeric = NUMERIC_TOKEN_RE.findall(text)
    if len(numeric) > MAX_NUMERIC_TOKENS:
        warnings.append(
            f"arc-not-stats (II-2a): {len(numeric)} numeric tokens — tell the arc, "
            "not a pile of numbers"
        )

    return {
        "status": "blocked" if blockers else "ready",
        "blockers": blockers,
        "warnings": warnings,
        "char_count": len(text),
    }


def build_queue(ship: dict[str, Any], voice: dict[str, Any]) -> dict[str, Any]:
    now = dt.datetime.now(dt.timezone.utc)
    drafts: list[dict[str, Any]] = []
    for channel, spec in CHANNELS.items():
        text = draft_channel(spec, ship)
        gate = brand_gate(channel, spec, text, ship, voice)
        drafts.append(
            {
                "channel": channel,
                "register": spec["register"],
                "text": text,
                "status": gate["status"],
                "blockers": gate["blockers"],
                "warnings": gate["warnings"],
                "char_count": gate["char_count"],
                "char_limit": spec["max_chars"],
            }
        )
    blocked = [d for d in drafts if d["status"] == "blocked"]
    return {
        "schema_version": SCHEMA_VERSION,
        "generated_at": now.isoformat(),
        "status": "awaiting-review",
        "gate_status": "blocked" if blocked else "ready",
        "ship": {
            "title": ship["title"],
            "arc_beat": ship["arc_beat"],
            "receipt": ship["receipt"],
            "receipt_source": ship["receipt_source"],
            "link_back": ship["link_back"],
            "substrate_credit": ship.get("substrate_credit", []),
        },
        "review_note": (
            "Joshua approves the publish. DRAFT is a brand-gated scaffold from "
            "grounded inputs; editorial polish happens here. PUBLISH + the live "
            "social review need channel handles this pipeline does not touch."
        ),
        "drafts": drafts,
    }


def render_markdown(queue: dict[str, Any]) -> str:
    ship = queue["ship"]
    lines = [
        f"# Presence queue — {ship['title']}",
        "",
        f"- Generated: `{queue['generated_at']}`",
        f"- Status: `{queue['status']}` · gate: `{queue['gate_status']}`",
        f"- Arc beat: {ship['arc_beat']}",
        f"- Receipt: {ship['receipt']}",
        f"- Receipt source: `{ship['receipt_source']}`",
        f"- Link-back: {ship['link_back']}",
        "",
        f"> {queue['review_note']}",
        "",
    ]
    for draft in queue["drafts"]:
        lines.append(
            f"## {draft['channel']} — `{draft['status']}` "
            f"({draft['char_count']}/{draft['char_limit']} chars)"
        )
        lines.append(f"_{draft['register']}_")
        lines.append("")
        lines.append("```")
        lines.append(draft["text"])
        lines.append("```")
        if draft["blockers"]:
            lines.append("")
            lines.append("**Blockers:**")
            lines.extend(f"- {b}" for b in draft["blockers"])
        if draft["warnings"]:
            lines.append("")
            lines.append("**Warnings:**")
            lines.extend(f"- {w}" for w in draft["warnings"])
        lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ship", help="ship descriptor JSON file (default: stdin)")
    parser.add_argument(
        "--voice-yaml",
        default=None,
        help="brand-voice voice.yaml (default: ZS_VOICE_YAML or the skill path)",
    )
    parser.add_argument(
        "--queue-dir",
        default=None,
        help="write JSON + MD queue files into this directory",
    )
    parser.add_argument("--json", action="store_true", help="print queue JSON to stdout")
    args = parser.parse_args()

    import os

    voice_path = Path(
        args.voice_yaml or os.environ.get("ZS_VOICE_YAML") or DEFAULT_VOICE_YAML
    ).expanduser()
    voice = load_voice(voice_path)

    ship = load_ship(args)
    trigger_errors = trigger_check(ship)
    if trigger_errors:
        for err in trigger_errors:
            print(f"TRIGGER reject: {err}", file=sys.stderr)
        print(
            "not a meaningful ship — curated descriptors only, not firehose",
            file=sys.stderr,
        )
        return 2

    queue = build_queue(ship, voice)

    if args.queue_dir:
        queue_dir = Path(args.queue_dir)
        queue_dir.mkdir(parents=True, exist_ok=True)
        stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        base = f"{stamp}-{slugify(str(ship['title']))}"
        (queue_dir / f"{base}.json").write_text(
            json.dumps(queue, indent=2) + "\n", encoding="utf-8"
        )
        (queue_dir / f"{base}.md").write_text(
            render_markdown(queue), encoding="utf-8"
        )
        print(f"queued: {queue_dir / base}.json (+ .md)", file=sys.stderr)

    if args.json or not args.queue_dir:
        print(json.dumps(queue, indent=2))

    return 1 if queue["gate_status"] == "blocked" else 0


if __name__ == "__main__":
    raise SystemExit(main())
