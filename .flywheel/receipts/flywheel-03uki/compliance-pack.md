# Compliance Pack: flywheel-03uki

## Scope

Bead: `flywheel-03uki`
Task: `flywheel-03uki-6bba97`
Mission fitness: adjacent to continuous orchestrator uptime through canonical
agent security doctrine, docs, skill draft, and path wiring.

## Acceptance Evidence

| Gate | Evidence | Status |
|---|---|---|
| AGENTS.md contains L74 | `rg -n "^## L74 — AGENT-SECURITY-DENY-RULES-CANONICAL" AGENTS.md` | pass |
| README and canonical paths mention security-control | `rg -n "agent-security-control/v1|security-control" README.md .flywheel/canonical-paths.txt` | pass |
| Skill draft exists | `.flywheel/PLANS/agent-security-controls-fleet-wide-2026-05-04/skill-draft-agent-security-control.md` | pass |
| Doctrine/memory wire test covers L74/canonical paths | `bash tests/doctrine-memory-wire.sh` | pass |
| Strict doctor does not fail on missing security docs after B09 receipt | `flywheel-loop doctor --strict --repo /Users/josh/Developer/flywheel --json` writes JSON with no missing-security-docs class | pass |

## Verification Commands

```bash
bash -n tests/doctrine-memory-wire.sh
bash tests/doctrine-memory-wire.sh
bash tests/security-control-conformance.sh
bash tests/security-control-fleet-smoke.sh --dry-run
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-03uki-6bba97.md
```

## Skill Routes

| Skill | Disposition |
|---|---|
| canonical-cli-scoping | n/a; no new CLI surface shipped |
| rust-best-practices | n/a; no Rust touched |
| python-best-practices | n/a; no Python touched |
| readme-writing | yes; README update is source-grounded, scannable, and command-backed |

## Four-Lens Self-Grade

| Lens | Score | Reason |
|---|---:|---|
| brand | 9 | Direct, operational doctrine with minimal prose and concrete paths |
| sniff | 9 | Acceptance gates map to executable checks and existing substrate |
| jeff | 8 | Schema/version markers, path registry, and 3-surface doctrine are explicit |
| public | 8 | Skeptical operator, maintainer, and future worker can rerun the checks |

## Residual Notes

`flywheel-98t5l` remains a separate open dependency in `br dep tree`; this pack
does not close or modify that bead.
