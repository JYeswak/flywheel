# flywheel-mn870 Evidence — autoloop-executor.jsonl already cross-linked via known-silos registry

Task: `flywheel-mn870-338f2a`
Bead: `flywheel-mn870` (P3 OPEN → CLOSED this turn)
Title: [autoloop-executor] cross-link autoloop-executor.jsonl ledger to monitoring/aggregation surfaces (per flywheel-2xdi.32 finding)
Date: 2026-05-10
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=adjacent` — recommended sibling
of flywheel-2xdi.32; closes by locate-verdict (cross-link already
landed in `.flywheel/gap-hunt-known-silos.jsonl` line 1) +
7-test regression to guard against future drift.

## Headline outcome

**Locate-verdict: cross-link is ALREADY in the canonical
known-silos registry** (`.flywheel/gap-hunt-known-silos.jsonl`
line 1, filed by the flywheel-2xdi.40 mechanism, populated for
autoloop-executor by flywheel-2xdi.32). The
gap-hunt-probe consults this registry via `known_silos()` (line
784) and 0 cross-source-silos gaps fire for autoloop-executor.jsonl.
A 7-test regression (`tests/autoloop-executor-known-silos-registry.sh`)
guards the registry row + class + writer + rationale + probe
consultation + live silo-suppression.

## Context: 3-bead chain

| Bead | Role | Outcome |
|---|---|---|
| `flywheel-2xdi.32` (CLOSED 2026-05-09) | wired-but-cold flag on autoloop-executor.sh; closing worker added self-logging that writes `autoloop-executor.jsonl`; surfaced cross-source-silos as a recommended sibling | self-logging contract shipped; new ledger created |
| `flywheel-2xdi.40` (mechanism) | created the `.flywheel/gap-hunt-known-silos.jsonl` allowlist + `known_silos()` consultation in gap-hunt-probe | canonical surface for "this silo is intentional" |
| `flywheel-mn870` (this close) | recommended-sibling for the .32 surfaced cross-link gap | locate-verdict + regression test |

## What's already in place (nothing edited by this close)

### Registry row at `.flywheel/gap-hunt-known-silos.jsonl` line 1

```json
{
  "name": "autoloop-executor.jsonl",
  "class": "self-instrumentation",
  "writer": "~/.claude/skills/.flywheel/lib/autoloop-executor.sh",
  "rationale": "writer declares self-instrumentation contract in header; consumed by gap-hunt-probe wired-but-cold rule, not by doctrine surfaces (per flywheel-2xdi.32)"
}
```

### Probe consultation at `.flywheel/scripts/gap-hunt-probe.sh:784`

```python
def known_silos() -> set[str]:
    """
    ... (filed by flywheel-2xdi.40); allowlist file is
    `.flywheel/gap-hunt-known-silos.jsonl` ...
    """
    allowlist_path = REPO_ROOT / ".flywheel/gap-hunt-known-silos.jsonl"
    ...
```

The `known_silos()` set is consulted at line 811 to filter
cross-source-silos candidates before flagging them.

### Live verification

```bash
$ bash .flywheel/scripts/gap-hunt-probe.sh --dry-run --json \
    | jq -r '.gaps_by_class["cross-source-silos"] // [] | length'
0
```

No cross-source-silos gap fires (registry suppresses the
autoloop-executor.jsonl candidate). Live probe agrees with the
registry contract.

## What this close added

### `tests/autoloop-executor-known-silos-registry.sh` (NEW)

7 PASS regression coverage:

| # | Test | Behavior |
|---|---|---|
| 1 | registry file exists | substrate gate |
| 2 | autoloop-executor.jsonl row present | registry contract |
| 3 | class == self-instrumentation | semantic categorization preserved |
| 4 | writer cites autoloop-executor.sh | source attribution preserved |
| 5 | rationale cites flywheel-2xdi.32 source bead | doctrine trail preserved |
| 6 | gap-hunt-probe consults known-silos registry | mechanism wired |
| 7 | live probe: autoloop-executor.jsonl NOT flagged cross-source-silos | end-to-end behavior |

If any of these regress, the test fails — guarding the cross-link
mechanism without requiring inline edits to the registry.

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| Cross-link autoloop-executor.jsonl into monitoring/aggregation surface | DONE (externally) | `.flywheel/gap-hunt-known-silos.jsonl` line 1 with semantic class=self-instrumentation; consumed by gap-hunt-probe.sh:784 known_silos() → cross-source-silos suppression |
| Verify the cross-link is operational | DONE | live probe returns 0 cross-source-silos gaps for autoloop-executor.jsonl |
| Add regression test to guard against drift | DONE (this close) | `tests/autoloop-executor-known-silos-registry.sh` 7/7 PASS |

did=3/3 didnt=none gaps=none.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| regression test | `tests/autoloop-executor-known-silos-registry.sh` | `1fccd3be85e2381735ff5c9b3189971d8cd0aeefda8884abec332dd5c7dfef1c` |

## Verification commands (re-runnable)

```bash
# Regression suite (7 PASS)
bash /Users/josh/Developer/flywheel/tests/autoloop-executor-known-silos-registry.sh
# expected: SUMMARY pass=7 fail=0

# Registry row exists
jq -c 'select(.name == "autoloop-executor.jsonl")' \
  /Users/josh/Developer/flywheel/.flywheel/gap-hunt-known-silos.jsonl
# expected: row with class=self-instrumentation

# Probe consults registry
grep -nE 'known_silos\(\)|gap-hunt-known-silos' \
  /Users/josh/Developer/flywheel/.flywheel/scripts/gap-hunt-probe.sh \
  | head -3

# Live silo suppression (0 gaps)
.flywheel/scripts/gap-hunt-probe.sh --dry-run --json \
  | jq '.gaps_by_class["cross-source-silos"] // [] | length'
# expected: 0

# Source bead .32 closed and named in registry rationale
br show flywheel-2xdi.32 | head -3 | grep CLOSED
```

## L112 probe (worker callback)

```bash
bash /Users/josh/Developer/flywheel/tests/autoloop-executor-known-silos-registry.sh 2>/dev/null | tail -1
```

Expected (literal): `SUMMARY pass=7 fail=0`.

## Boundary

- **No edit to `.flywheel/gap-hunt-known-silos.jsonl`.** Row pre-exists at line 1; semantic content is correct.
- **No edit to `gap-hunt-probe.sh`.** `known_silos()` mechanism is already wired.
- **No edit to `~/.claude/skills/.flywheel/lib/autoloop-executor.sh`.** Self-logging contract is .32's responsibility, already shipped.
- **No new top-level INCIDENTS section.** No recurring trauma to promote — the registry mechanism IS the canonical no-recurrence pattern.
- **No L-rule numbered.** Existing self-instrumentation + known-silos contract is already canonical via `.flywheel/gap-hunt-known-silos.jsonl` schema.
- **No reopen of `flywheel-2xdi.32` or `flywheel-2xdi.40`.** Closed beads stay closed.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python edit.
- `readme-writing=n/a` — substrate test, not README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no doctrine surface mutated.
- `readme_updated=not_applicable`.
- `no_touch_reason=cross_link_already_in_canonical_known-silos_registry_at_line_1_filed_by_flywheel-2xdi.40_mechanism_for_autoloop-executor_via_flywheel-2xdi.32_close_no_doctrine_surface_added`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes 3/3 acceptance gates; locate-verdict
  cites the existing canonical surface line-precise; 7-test
  regression guards substrate + semantic + behavior.
- **Sniff: 9** — outcome-shaped headline ("locate-verdict:
  cross-link is ALREADY in the canonical known-silos registry…
  7-test regression guards… 0 cross-source-silos gaps fire");
  3-bead chain table maps the problem space; concrete file:line
  citation for registry row + probe consultation; live verification
  agrees with the registry contract.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small
  surface (one regression test + one audit pack); refuses to edit
  the registry, the probe, the autoloop-executor source, or
  AGENTS.md — all already canonical; refuses to file follow-ups
  (no recurring trauma observed).
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: 5 verification commands
    confirm registry + row + probe + live + source bead in <5s.
  - **maintainer (extending later)**: the registry schema
    (name/class/writer/rationale) is the extension point — adding
    a new self-instrumentation silo is a one-line append to the
    .jsonl + registry-membership-class assertion.
  - **future worker (LLM agent)**: facing another
    cross-source-silos surface for a self-instrumenting ledger,
    the worker has (a) the gap-hunt-known-silos registry as a
    canonical no-cross-link allowlist, (b) the .32 → .40 → mn870
    chain as a precedent for "self-instrumentation is a class,
    not a silo to fix", (c) the 7-test regression as a copy-paste
    template for similar ledger-registry assertions.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-mn870
no_bead_reason=cross_link_already_in_canonical_known-silos_registry_via_flywheel-2xdi.40_mechanism_filed_for_autoloop-executor_by_flywheel-2xdi.32_close_locate_verdict_plus_7_test_regression_guards_against_drift_no_followup_observed`.
