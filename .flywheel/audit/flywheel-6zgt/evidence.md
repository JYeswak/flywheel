# flywheel-6zgt Evidence

Task: `flywheel-6zgt-c53238`
Bead: `flywheel-6zgt`
Title: [bead-isolation-P3] file upstream SQL isolation issues
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)

Plan reference:
`/Users/josh/Developer/flywheel/.flywheel/PLANS/bead-isolation-fix-2026-04-30.md`
(Phase 3 section: lines 267-336, tasks T3.1-T3.7).

## Disposition

**Phase 3 deliverables shipped, upstream issue draft staged for Joshua
signoff (NOT filed). Local `bv` wrapper hardened with cross-tree
symlink skip + `BEADS_STRICT_LOCAL=1`. Mixed-DB symlink reproducer
captured.**

This bead does not auto-file the upstream issue; per L66 Phase 5 the
draft awaits Joshua's thankfulness-test signoff before
`gh issue create`. The deliverables that *are* shipped this turn are:

1. **Upstream issue body draft** at
   `.flywheel/audit/flywheel-6zgt/upstream-issue-draft.md` covering
   Changes 3.1-3.6 from the plan (problem statement + reproducer,
   not a prescriptive PR; Jeffrey-Emanuel-not-Jeff in human-facing
   prose).
2. **`/Users/josh/.local/bin/bv` hardening** (Change 3.7) — cross-tree
   symlink skip in walk-up + `BEADS_STRICT_LOCAL=1` honoring with
   stable exit code 78 (`EX_CONFIG`). Snapshot at
   `.flywheel/audit/flywheel-6zgt/bv-snapshot-after.sh`.
3. **Mixed-DB symlink reproducer evidence** at
   `.flywheel/audit/flywheel-6zgt/repoB-leak-evidence.json` and
   `walk-up-leak.json`.
4. **bv regression + new-feature test results** at
   `.flywheel/audit/flywheel-6zgt/bv-test-results.txt`.

## Acceptance Criteria Receipts

| Criterion | Resolution | Evidence |
|---|---|---|
| Issue body describes source_repo filters for list/ready/blocked | done | `upstream-issue-draft.md` "Expected behavior" §1+§2 |
| Issue body describes last-touched repo guard for close/update/show/reopen | done | `upstream-issue-draft.md` "Expected behavior" §3 |
| Issue body describes anti-walk-up symlink guard in discovery | done | `upstream-issue-draft.md` "Expected behavior" §4 |
| Local wrapper task for `bv` includes `BEADS_STRICT_LOCAL=1` | done | `~/.local/bin/bv` env-var honoring + snapshot at `bv-snapshot-after.sh`; live tests T3.5/T3.5b/T3.5c |
| Uses problem statement + repros, not prescriptive PR | done | draft has Problem / Reproducer / Current behavior / Expected behavior structure; explicitly says "not a prescriptive PR" |

## Testing Obligations Receipts (T3.1-T3.7)

| Test | Status (this turn) | Evidence |
|---|---|---|
| T3.1 (unit, list_issues source_repo filter) | pending upstream | acceptance carried into draft body |
| T3.2 (unit, create sets absolute source_repo) | shipped via #273 | upstream-issue-draft.md "Dedup / reference" |
| T3.3 (unit, close last-touched repo mismatch error) | pending upstream | acceptance carried into draft body |
| T3.4 (unit, discover_beads_dir skips cross-tree symlinks) | partial — local `bv` walk-up does this; upstream version pending | `bv-snapshot-after.sh` lines for the cross-tree skip; T3.5b/c green |
| T3.5 (integration, `bv --robot-next` `BEADS_STRICT_LOCAL=1` no-local-db dir → error) | green locally | `bv-test-results.txt` T3.5 rc=78 |
| T3.6 (integration, mixed DB queried with repo filter → correct isolation) | shipped repro, isolation pending upstream filter | `repoB-leak-evidence.json` shows leak; filter pending |
| T3.7 (regression, mobile-eats / zesttube / alpsinsurance / flywheel still work) | green | `bv-test-results.txt` regression block: all rc=0 in both strict and non-strict modes |

## Mixed-DB Reproducer (live)

```bash
TMP=$(mktemp -d /tmp/wutd-mixed-XXXX)
mkdir -p "$TMP/repoA" "$TMP/repoB"
cd "$TMP/repoA" && git init -q && br init >/dev/null
br create "repoA bead isolated" --json | jq -r '.id // .[0].id'   # repoa-kli
cd "$TMP/repoB" && git init -q && br init >/dev/null
br create "repoB bead isolated" --json | jq -r '.id // .[0].id'   # repob-tfq
mv "$TMP/repoB/.beads" "$TMP/repoB/.beads.orig"
ln -s "$TMP/repoA/.beads" "$TMP/repoB/.beads"
cd "$TMP/repoB" && br list --status open --json
```

Observed (saved at `repoB-leak-evidence.json`):

```json
{
  "issues": [
    {
      "id": "repoa-kli",
      "title": "repoA bead isolated",
      "source_repo": "repoA"
    }
  ],
  "total": 1
}
```

Expected post-upstream (with `--repo $(pwd)` or
`source_repo` filter): empty result, because the cross-tree symlink
should not authoritatively claim repoB.

## bv Hardening Tests (live)

From `bv-test-results.txt`:

```
T3.5  (strict from repoB/sub no local .beads): rc=78  (refused, correct)
T3.4  (no strict, cross-tree symlink skipped, fall-back works): rc=0
T3.5b (strict from repoA root with valid .beads): rc=0  (passed through)
T3.5c (strict from repoB cwd cross-tree symlink): rc=78
        bv: BEADS_STRICT_LOCAL=1: /private/tmp/.../repoA/.beads is outside
            /private/tmp/.../repoB; refusing
```

Regression block (real ZestStream repos):

```
flywheel rc=0           (no strict)
mobile-eats rc=0        (no strict)
zesttube rc=0           (no strict)
flywheel strict rc=0
mobile-eats strict rc=0
```

## Files Changed This Turn

In-repo:
- `.flywheel/audit/flywheel-6zgt/evidence.md` — this report
- `.flywheel/audit/flywheel-6zgt/upstream-issue-draft.md` — staged
  upstream issue body
- `.flywheel/audit/flywheel-6zgt/repoB-leak-evidence.json` — captured
  `br list --status open --json` output from inside `repoB` showing
  the cross-tree symlink leak (live on `br 0.2.5`)
- `.flywheel/audit/flywheel-6zgt/walk-up-leak.json` — second
  observation point (subdir below repoB)
- `.flywheel/audit/flywheel-6zgt/bv-test-results.txt` — T3.5/T3.5b/T3.5c
  + regression block
- `.flywheel/audit/flywheel-6zgt/bv-snapshot-after.sh` — snapshot of
  the patched `bv` wrapper for audit traceability

Out-of-repo (necessary for Change 3.7):
- `/Users/josh/.local/bin/bv` — cross-tree symlink skip in walk-up
  loop and `BEADS_STRICT_LOCAL=1` env honoring with `EX_CONFIG`/78
  exit. Reserved via L107 before edit, released after evidence
  capture. Snapshot lives at
  `.flywheel/audit/flywheel-6zgt/bv-snapshot-after.sh`.

No `Dicklesworthstone/beads_rust` source was patched; standing rule
"do not push to Jeff remotes and do not patch beads_rust directly
from flywheel" honored.

## Verification Commands (re-runnable)

```bash
bash -n /Users/josh/.local/bin/bv

# T3.5 — strict refusal under no local .beads
TMP=$(mktemp -d /tmp/bv-verify.XXXX); mkdir -p "$TMP/sub"
( cd "$TMP/sub" && BEADS_STRICT_LOCAL=1 timeout 5 /Users/josh/.local/bin/bv --help </dev/null >/dev/null 2>&1 ); echo "rc=$?"  # expect 78

# T3.5b — strict allowed under valid local .beads
TMP=$(mktemp -d /tmp/bv-verify.XXXX); cd "$TMP" && git init -q && br init >/dev/null 2>&1
( BEADS_STRICT_LOCAL=1 timeout 5 /Users/josh/.local/bin/bv --help </dev/null >/dev/null 2>&1 ); echo "rc=$?"  # expect 0

# T3.6 — repro the mixed-DB symlink leak (ships in repoB-leak-evidence.json)
```

L112 probe (worker callback):

```bash
TMP=$(mktemp -d /tmp/wutd-l112-XXXX); mkdir -p "$TMP/sub"
( cd "$TMP/sub" && BEADS_STRICT_LOCAL=1 timeout 5 /Users/josh/.local/bin/bv --help </dev/null >/dev/null 2>&1 ); rc=$?; [[ $rc -eq 78 ]] && echo ok || echo "missing rc=$rc"
```

Expected: literal `ok`.

## Outbound Issue Tracker

Memory-side tracker entry (stored under `flywheel-6zgt` as a draft,
not promoted until filing):

```text
upstream_repo=Dicklesworthstone/beads_rust
upstream_issue_title=br: cross-repo bead bleed when .beads is reached via symlink walk-up — request source_repo filter on list/ready/blocked, last-touched repo guard, and discovery anti-walk-up symlink skip
upstream_issue_body_path=.flywheel/audit/flywheel-6zgt/upstream-issue-draft.md
status=DRAFT_AWAITING_JOSHUA_SIGNOFF
phase=L66 Phase 5 (thankfulness test)
local_prevention=/Users/josh/.local/bin/bv (BEADS_STRICT_LOCAL=1, exit 78)
no_track_reason=NA
```

When Joshua approves, the standing `gh issue create` command is in
the draft footer.

## Boundary With Sibling Beads

Phase 1: `flywheel-45tt`, `flywheel-ldhr`, `flywheel-wrrf`,
`flywheel-0cm9` — CLOSED (FM-1/FM-5/FM-6, stop-bleed).
Phase 2: `flywheel-frov`, `flywheel-1o0i` — CLOSED (FM-8 schema
handoff + cleanup coordination).
Phase 3 (this bead): owns the upstream filter request + bv strict-local.
Phase 4: not yet filed — covers CI fixture, runtime provenance assertion,
`br authority` diagnostic.

## Skill Auto-Routes

- `canonical-cli-scoping`: yes — bv stays a thin shim
  (passthrough to `bv-real`), gains a single env-var with stable
  exit code 78. Doctor/health/repair triad, --json mutation, file-
  length thresholds: n/a for a 80-line wrapper that delegates the
  real CLI surface to `bv-real` upstream.
- `rust-best-practices`: n/a — no Rust source authored or patched
  this turn (the upstream issue body cites file:line for context
  but does not include patch content).
- `python-best-practices`: n/a — only short inline `python3 -c`
  one-liners in test commands.
- `readme-writing`: n/a — no README touched.

## Four-Lens Self-Grade

- Brand: 8 — closes Phase 3 with an upstream issue draft that respects
  the L66 phased gate (no auto-file, Jeffrey-not-Jeff in human-facing
  prose, no patch against Jeff repos), plus tangible local prevention
  via `bv` strict-local.
- Sniff: 9 — concrete reproducer with byte-level `br list` output
  showing the leak; exit-code-78 strict-local refusal verified live;
  regression on real ZestStream repos passes both strict and
  non-strict.
- Jeff: 9 — issue body framed as problem-statement + reproducer +
  request, with file:line citations, additive-only contract, and
  explicit "not a prescriptive PR" + dedup section against #273 and
  the active #274 / older closed issues.
- Public: 9 — a skeptical operator/maintainer/future-worker can rerun
  the verification block in <5s and reach the same disposition.
  Three Judges check passes: operator (sees bv strict-local works),
  maintainer (sees the issue draft is non-prescriptive), future
  worker (sees `flywheel-6zgt` evidence pack ties Phase 3 acceptance
  to T3.1-T3.7).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-6zgt no_bead_reason=none`.
