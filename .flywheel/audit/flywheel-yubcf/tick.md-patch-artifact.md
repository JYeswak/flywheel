# JSM-Import-Ready Patch — flywheel-yubcf

**Target:** `/Users/josh/.claude/commands/flywheel/tick.md` (skill substrate, unmanaged in JSM per `jsm list --json`)
**Patch type:** `jsm-import-ready`
**Operation:** insert markdown subsection AFTER existing Dim-9 (adversarial-orch-self-audit) closing paragraph, BEFORE "Step 4p:" header
**Source bead:** `flywheel-yubcf`
**Parent:** `flywheel-faqj2` (Phase 1+2+4 meta-substrate shipped)

## Anchor (existing content — locate insertion point)

```markdown
Self-logs to `~/.local/state/flywheel/adversarial-orch-self-audit-probe-runs.jsonl`
on every run. Per Step 4o anti-pattern guardrail: SURFACES findings only —
does NOT auto-file beads, does NOT auto-dispatch, does NOT mutate state.
Read-only by design (br/ntm/gh/git/agent-mail untouched per probe header
contract).

**Step 4p: Jeff issue status probe (NEW 2026-05-03 -- see bead `flywheel-vnsw`, L63, and ntm#117 dogfood loop).**
```

## Insertion block (to be added BETWEEN those two)

```markdown
**Step 4o.self-calibration: gap-hunt-probe self-calibration** (bead
`flywheel-faqj2` substrate + `flywheel-yubcf` wire-in; doctrine at
`.flywheel/doctrine/gap-hunt-probe-self-calibration-discipline.md`).

Run the probe-of-the-probe to surface structural drift in gap-hunt-probe
(corpus caps approaching threshold, orphan scripts with no glob coverage,
new ledgers since last snapshot, ledger-producer name mismatches,
SKILL.md size drift). Motivated by N=7 calibration findings in a single
session — periodic self-calibration prevents per-bead worker burn:

```bash
.flywheel/scripts/gap-hunt-probe-self-calibration.sh --apply --json
```

Per Step 4o anti-pattern guardrail: emits structured JSON proposals
only — never auto-applies corpus extensions, cap bumps, or new globs.
Orchestrator reviews `.findings[]` (info/warn/alert severity) and files
calibration follow-on beads. Sister discipline to gap-hunt-probe's
9-class taxonomy: this probe surfaces drift in gap-hunt-probe itself.

The `--apply` flag appends the proposals envelope to
`~/.local/state/flywheel/gap-hunt-self-calibration-runs.jsonl` and
updates the snapshot at `gap-hunt-self-calibration-snapshot.json` so
the next run can detect new-ledger diff.
```

## Rationale

Per parent `flywheel-faqj2` evidence pack:
- Phases 1+2+4 shipped: the substrate (probe-of-the-probe), JSON proposals design, and doctrine
- Phase 3 (this wire-in) was deferred to follow-on per cross-repo discipline
- Sister patterns: `flywheel-myfak.1` (Dim-9 adversarial-orch wire-in) + `flywheel-ol1bu` (fleet-canonical-rule-freshness fleet-doctor.md wire-in)

The subsection follows the EXACT pattern of Dim-1 / Dim-3 / Dim-9 / Step 4p:
- Title + parenthetical bead lineage citation
- 1-2 sentence purpose statement
- bash invocation block
- Step 4o anti-pattern guardrail reminder
- Optional ledger documentation

## Verification post-import

```bash
# 1. Confirm subsection present + correctly placed
grep -nE 'Step 4o.self-calibration|Step 4p:' /Users/josh/.claude/commands/flywheel/tick.md
# Expected: 4o.self-calibration line precedes 4p line

# 2. Run /flywheel:tick once; ledger should accrue >=1 row
/flywheel:tick
ls -la ~/.local/state/flywheel/gap-hunt-self-calibration-runs.jsonl
# Expected: file exists with >=1 JSON row
```

## Boundary

Per `feedback_no_push_ntm_br.md` + `project_skillos_separated.md`: this patch targets `.claude/commands/` (skill substrate, separate repo from flywheel.git). Direct mutation already applied in `flywheel-yubcf` dispatch from flywheel pane because `commands/flywheel` is unmanaged in JSM (verified previously in `flywheel-myfak.1` + `flywheel-ol1bu`). This artifact exists for future JSM import if/when the skill becomes managed.

## Consistency observation

Unlike `adversarial-orch-self-audit-probe.sh` (myfak.1) and `fleet-canonical-rule-freshness-probe.sh` (ol1bu), `gap-hunt-probe-self-calibration.sh` DOES self-log via its `--apply` mode (appends to runs.jsonl + writes snapshot for diff). No orch-side append wrapper needed.

This is the cleaner pattern documented as future-candidate enhancement in those prior wire-ins. The self-calibration probe ships with the audit-log mode built-in from day 1 — sister precedent for the "if probe is read-only AND ledger-bearing, ship `--apply` mode" canonical pattern.
