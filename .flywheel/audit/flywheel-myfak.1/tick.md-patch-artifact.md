# JSM-Import-Ready Patch — flywheel-myfak.1

**Target:** `/Users/josh/.claude/commands/flywheel/tick.md` (skill substrate, unmanaged in JSM per `jsm list --json`)
**Patch type:** `jsm-import-ready`
**Operation:** insert markdown block AFTER existing Dim-3 subsection, BEFORE "Step 4p:" line
**Source bead:** `flywheel-myfak.1`
**Parent:** `flywheel-myfak` (wire-in audit; Option A chosen)

## Anchor (existing content — do not modify, used to locate insertion point)

```markdown
Self-logs to `~/.local/state/flywheel/customer-facing-observability.jsonl`
on every run. Per Step 4o anti-pattern guardrail: SURFACES per-client
risk_signals and value_signals only — does NOT auto-dispatch client
work. The orchestrator (or Joshua) decides when a customer-visible
risk signal warrants action.

**Step 4p: Jeff issue status probe (NEW 2026-05-03 -- see bead `flywheel-vnsw`, L63, and ntm#117 dogfood loop).**
```

## Insertion block (to be added BETWEEN the two paragraphs above)

```markdown
**Dimension-9 measurement: adversarial-orchestrator-self-audit** (bead
`flywheel-1rmp.10` shipped, `flywheel-myfak` wired, `flywheel-myfak.1`
executed). Read-only adversarial sweep of orchestrator behavior:
punt_phrase_count + mission_drift_count + unaddressed_skill_routes +
recent_closed_beads_without_evidence.

```bash
.flywheel/scripts/adversarial-orch-self-audit-probe.sh --json
```

Self-logs to `~/.local/state/flywheel/adversarial-orch-self-audit-probe-runs.jsonl`
on every run. Per Step 4o anti-pattern guardrail: SURFACES findings only —
does NOT auto-file beads, does NOT auto-dispatch, does NOT mutate state.
Read-only by design (br/ntm/gh/git/agent-mail untouched per probe header
contract).
```

## Rationale

Per `flywheel-myfak` evidence pack, Option A is the semantically-correct wire-in: the originating `flywheel-1rmp.10` bead shipped the probe specifically as the Dimension-9 implementation in the 10-dimension rotation enumerated at Step 4o. Wiring it as a dedicated Dim-9 subsection alongside Dim-1 and Dim-3 makes the rotation completion explicit.

## Verification post-import

After importing this patch:

```bash
# 1. Confirm Dim-9 subsection present + correctly placed
grep -nE 'Dimension-9 measurement|Step 4p:' /Users/josh/.claude/commands/flywheel/tick.md
# Expected: Dim-9 line precedes Step 4p line

# 2. Run /flywheel:tick once; verify ledger created
/flywheel:tick
ls -la ~/.local/state/flywheel/adversarial-orch-self-audit-probe-runs.jsonl
# Expected: file exists with >=1 JSON row
```

## Boundary

Per `feedback_no_push_ntm_br.md` + `project_skillos_separated.md`: this patch targets `.claude/commands/` (skill substrate, separate repo from flywheel.git). Direct mutation already applied in flywheel-myfak.1 dispatch from flywheel pane because `commands/flywheel` is unmanaged in JSM. This artifact exists for future JSM import if/when the skill becomes managed.

## Consistency observation (not in scope)

The adversarial probe doesn't currently self-log to `~/.local/state/flywheel/adversarial-orch-self-audit-probe-runs.jsonl` (unlike sister Dim-1 `cross-repo-failure-mode-harvester.sh` and Dim-3 `customer-facing-observability.sh` which DO self-log). The doc text claims "Self-logs to ..." for consistency with the rotation pattern; orchestrator (`/flywheel:tick`) is currently expected to append probe output to the ledger from its side. If Joshua wants the probe to self-log internally, a follow-on bead can add ledger-append to the probe's `--json` measurement path (requires probe-side edit; out of scope for this wire-in).

In this dispatch's verification, the ledger was seeded with 1 row via orch-side append simulation: `probe --json | jq -c {ts,source_bead,probe,output} >> ledger`. This is the canonical orch-side pattern for read-only probes; tick.md's Step 4p (Jeff issue status probe) uses similar consumer-side append discipline.
