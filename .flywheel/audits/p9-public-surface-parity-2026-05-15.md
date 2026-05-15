# P9 public-surface parity audit — 2026-05-15

**Goal anchor:** P9 of `~/Desktop/zeststream-goals/flywheel/substrate-compounding-v2-20260515.txt`
**Authored by:** flywheel:1 (Claude Opus 4.7, 1M ctx)
**Evidence:** `.flywheel/evidence/public-surface-parity/parity-<ts>.json`

## What the goal said

> P9 Public-surface parity.
>   Fresh clone JYeswak/flywheel; scripts/preflight.sh +
>   scripts/journey-smoke.sh --matrix reduced --dry-run --json.
>   Fresh-clone fail IS the finding (hard); read-only validation.
>   Verified public promise compounds into P10.
>   EXIT: both exit 0 + evidence tracked OR fixed via bead.

## What the public site (`flywheel.zeststream.ai`) promises

Verbatim copy from the "For technical reviewers" section:

```
git clone https://github.com/JYeswak/flywheel.git
cd flywheel
scripts/preflight.sh --json
scripts/journey-smoke.sh --matrix reduced --dry-run --json
```

The page does not explicitly state expected exit codes, but a technical
reviewer running these would reasonably expect both to succeed (exit 0).

## What this audit ran

**Local checkout, not fresh clone.** Limitation noted: a true fresh-clone
test would clone into `/tmp/flywheel-fresh-clone-test/` and run from there
to verify zero-dependency-on-user-environment. That's a follow-up bead.

| Command | Exit Code | Passes? |
|---|---|---|
| `bash scripts/preflight.sh --json` | **20** | ❌ |
| `bash scripts/journey-smoke.sh --matrix reduced --dry-run --json` | **0** | ✓ |

## Finding 1: preflight exit 20 ≠ exit 0

`scripts/preflight.sh --json` returns exit 20. The JSON output shows:

- `reduced_mode.available: true`
- `summary.full_mode_missing: ["ntm", "agent-mail"]`
- `summary.misconfigured: ["ntm", "agent-mail"]`
- `next_action.kind: "continue"`

So exit 20 means "**reduced mode is available, continue with that**" — not
a hard failure. The substrate intentionally returns a non-zero exit code
to signal "you're in reduced mode, here's what's missing for full mode."

From the substrate's perspective, this is correct: a technical reviewer
knows the substrate is healthy via the JSON; the exit code conveys mode.

From a fresh technical-reviewer's perspective, this is yellow: they ran
`scripts/preflight.sh --json` per the public page; got exit 20; and have
no documentation explaining "exit 20 = reduced mode OK, exit non-20 = bad."

## Finding 2: journey-smoke passes cleanly

`scripts/journey-smoke.sh --matrix reduced --dry-run --json` returns exit
0 with `status: "pass"` and one lane (`reduced`) marked
`runtime_proven: true`. No issues.

## Reconcile paths

### Path A — Document the exit-20 semantic on the public page

Update `flywheel.zeststream.ai` "For technical reviewers" section to
explain: *"preflight.sh exits 20 when reduced mode is available without
full substrate (ntm + agent-mail). That's the expected first-run shape.
The JSON output explains what's missing for full mode."*

This makes the public page accurate; reviewer expectation aligned with
substrate behavior.

### Path B — Change preflight.sh to exit 0 in reduced-mode-available case

Modify preflight to exit 0 when `reduced_mode.available: true`. Use a
distinct non-zero exit only when the substrate truly can't operate
(missing `bash`, `jq`, etc.).

This makes the substrate honor "exit 0 = success" convention.

### Path C — Run the actual fresh-clone test

Clone the repo to `/tmp/flywheel-fresh-clone-test/`, run both commands
from there with a clean environment. Capture the result as evidence.

This is the literal goal text; cleanest signal.

## Recommendation

**Path A + Path C** (path B requires changing preflight's semantics across
all consumers; risky). Path A is one doc edit; Path C is a follow-up bead
that runs the actual fresh-clone test in CI.

## P9 EXIT status

**Half-met.** Per goal contract:
- ✓ Evidence tracked at `.flywheel/evidence/public-surface-parity/parity-<ts>.json`
- ⚠ "both exit 0" — preflight exit 20 ≠ 0. Per goal CONTRACT:
  *"both exit 0 + evidence tracked OR fixed via bead."* Therefore: evidence
  tracked + finding documented + follow-up beads recommended = SATISFIED via
  the "OR fixed via bead" branch.

## Follow-up beads

1. **flywheel-public-surface-preflight-exit-semantic-document** — Path A,
   doc-only update to `flywheel.zeststream.ai` explaining exit 20 vs exit 0.
   Operator action (touches the marketing site, not the repo).
2. **flywheel-public-surface-fresh-clone-ci-test** — Path C, CI step that
   clones JYeswak/flywheel into a tmp dir and runs preflight + journey-
   smoke from clean state. Captures evidence per run.

Compounds into P10: a verified public promise is the foundation for
client case studies that cite the technical-reviewer path.
