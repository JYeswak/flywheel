# flywheel-ucdw Compliance Pack

Task: `flywheel-ucdw-cbf618`
Bead: `flywheel-ucdw` (rework of `flywheel-7dkw` evidence)
Decision: DONE
Compliance score: 880/1000

## Finding

`flywheel-7dkw` close was BLOCK_CLOSE'd by the validator on 2026-05-04
with the receipt-quality reasons:

- `jeff_lens=FAIL` (`contract_without_version`)
- `public_lens=FAIL` (`too_thin 18<20`,
  `no_acceptance_gates_addressed`, `no_bar_self_grade`)

The original receipt at `/tmp/codex-20925-evidence.md` was both
under-evidenced AND ephemeral (macOS aged out `/tmp` before the
validator's reasons could be addressed in-place).

This bead (`flywheel-ucdw`) is the rework: rebuild the evidence file
durably with version-pins, explicit AG addressing, named bar/three-
judges + publishability + brand-voice + Jeff + Donella lens
discussion, and the `flywheel-2b0n` linkage explanation.

## Repair

Wrote a 205-line durable evidence file at
`.flywheel/audit/flywheel-7dkw/evidence.md` covering the four
corrective requirements named in the bead body verbatim:

1. **Version-pin contract claims**: 11-row table — codex-cli
   0.125.0, OS macOS 26.3 arm64, upstream issue + comment URL +
   comment id + comment-created-at, flywheel-7dkw body sha256
   (`a529dfad43845871677f010c4d9c2edddbb1e9451ee75a34e595afb547245fd0`),
   flywheel-2b0n body sha256
   (`568f0fab07d14408730429c0e4b683ecafb4e3bf581bc52270d6cf640a2e4734`),
   flywheel-2b0n status pin (`closed 2026-05-08, score 9/10`),
   evidence artifact path.

2. **Explicit acceptance-gate addressing**: per-AG sections (AG1
   posted comment, AG2 capture-coverage analysis, AG3 gap-bead
   shipped, AG4 receipt migrated). Each AG cites concrete status +
   evidence + the contract property it satisfies.

3. **Named bar self-grade**: explicit "Three Judges check" subsection
   (skeptical operator / maintainer / future worker), publishability
   subsection (jeff-issue-chain v1.1 anonymization on upstream
   comment + ZestStream brand voice on internal evidence), Jeff
   lens (peer-engineer norms — observe contract, don't prescribe),
   Donella Meadows lens (Meadows #6 information-flows leverage
   point — gap-bead pattern as canonical doctrine).
   Self-grade `brand:9 sniff:9 jeff:9 public:9` per the four-lens
   contract — 4/4 PASS expected from the validator.

4. **flywheel-2b0n linkage explanation**: dedicated AG3 subsection
   walks the gap-bead's full lifecycle (filed 2026-05-04 → shipped
   producer + doctor wiring + fixture tests + canonical-paths +
   promotion route → closed 2026-05-08 score 9/10). Explains the
   linkage as: 7dkw's AG3 clause "if not covered, file gap-bead"
   was satisfied by filing 2b0n; 2b0n's full lifecycle is the
   durable proof.

## Acceptance Gate Map

The bead body's four corrective items map 1:1 to evidence-file
sections:

| # | Bead corrective | Evidence-file section | Status |
|---|------|---------|--------|
| 1 | Version-pin contract claims | "Version-pin contract claims" 11-row table | ✓ |
| 2 | Explicitly address acceptance gates | "Acceptance gate map" with AG1-AG4 subsections | ✓ |
| 3 | Name bar (Three Judges/publishability/brand-voice/Jeff/Donella) | "Bar self-grade" subsection with all 5 lenses + numerical four_lens | ✓ |
| 4 | Describe gap_bead=flywheel-2b0n linkage | AG3 subsection explains the full lifecycle linkage | ✓ |

did=4/4. Evidence file is 205 lines (well above the 20-line
threshold the validator BLOCK_CLOSE'd at 18<20).

## Evidence

```text
$ wc -l /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-7dkw/evidence.md
205

$ # Version-pin proof:
$ codex --version
codex-cli 0.125.0

$ # Upstream comment durability proof:
$ gh issue view 20925 --repo openai/codex --json comments \
  | jq '.comments[] | select(.author.login == "JYeswak") | .id, .createdAt'
"IC_kwDOOYsS4c8AAAABBICrQA"
"2026-05-04T11:04:02Z"

$ # Bead-body sha pins for version control:
$ br show flywheel-7dkw | shasum -a 256 | head -1
a529dfad43845871677f010c4d9c2edddbb1e9451ee75a34e595afb547245fd0  -

$ br show flywheel-2b0n | shasum -a 256 | head -1
568f0fab07d14408730429c0e4b683ecafb4e3bf581bc52270d6cf640a2e4734  -

$ # gap-bead lifecycle proof:
$ br show flywheel-2b0n | head -3
✓ flywheel-2b0n · add orphaned_mcp_tool_call_count doctor signal   [● P1 · CLOSED]
Owner: josh · Type: task
Created: 2026-05-04 · Updated: 2026-05-08
```

## Scope

- Edits: 2 new files
  - `.flywheel/audit/flywheel-7dkw/evidence.md` (the rebuilt
    durable evidence; 205 lines)
  - `.flywheel/audit/flywheel-ucdw/compliance-pack.md` (this file)
- Files reserved/released: NONE_NO_EDITS for shared surfaces
  (audit dirs are this dispatch's own output, not contended)
- Out of scope: closing flywheel-7dkw (validator runs as a separate
  step on the new evidence file; this rework dispatch ships the
  evidence, the close motion is orchestrator-side); modifying
  flywheel-2b0n (already closed); reposting upstream codex#20925
  comment (already durable at issuecomment-4370508608)

## L52 / L80 / L120 / L61

- DIDNT: none (4/4 corrective items satisfied)
- GAPS: none new
- beads_filed: none
- beads_updated: none (flywheel-7dkw stays in_progress until
  validator re-runs against the new evidence file; that's an
  orchestrator-side validator-rerun, not a worker-tick action)
- no_bead_reason: rework-of-existing-bead-no-followup-needed
- br_close_executed: yes (THIS bead, flywheel-ucdw; flywheel-7dkw
  is the parent and stays in_progress per the orch-side
  validator-rerun separation)
- agents_md_updated: not_applicable
- readme_updated: not_applicable

## Four Lens (this rework's own self-grade)

- Brand: 9 (rebuilt evidence preserves the audit chain via durable
  repo-owned path, restoring the chain that the original /tmp
  ephemeral path lost)
- Sniff: 9 (every claim in the evidence file pins to a concrete
  signal: codex --version output, comment URL + id + ts, bead body
  shas, bead lifecycle status with score and date)
- Jeff: 9 (the rebuilt evidence honors jeff-issue-chain v1.1 on
  the upstream-comment side by referencing it without modifying it,
  and uses ZestStream brand voice on the internal-evidence side
  where flywheel-substrate names are appropriate)
- Public: 9 (the Three Judges section anticipates skeptical
  operator + maintainer + future worker, each with concrete
  evidence to verify; the audit chain is fully traversable
  without the lost /tmp file)

## Skill Auto-Routes

- canonical-cli-scoping: n/a — no CLI added
- rust-best-practices: n/a — no Rust touched
- python-best-practices: n/a — no Python touched
- readme-writing: n/a — no README touched

## L112 Probe

```
wc -l /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-7dkw/evidence.md
```
Expected: `literal:>=20` (validator's BLOCK_CLOSE was at 18<20;
this rebuild is 205 lines — generous safety margin).

A more complete probe verifies the four corrective items are
addressed:

```
grep -cE "Version-pin|Acceptance gate map|Bar self-grade|flywheel-2b0n" \
  /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-7dkw/evidence.md
```
Expected: `literal:>=4` (one match per corrective item).
