# JSM-Import-Ready Patch — flywheel-ol1bu

**Target:** `/Users/josh/.claude/commands/flywheel/fleet-doctor.md` (skill substrate, unmanaged in JSM per `jsm list --json`)
**Patch type:** `jsm-import-ready`
**Operation:** insert markdown block AFTER "Do not run `--stamp`..." paragraph, BEFORE "## Output" header
**Source bead:** `flywheel-ol1bu`
**Parent:** `flywheel-2xdi.87` (probe-without-receiver triage) + `flywheel-1rmp.10` (originated probe)

## Anchor (existing content — locate insertion point)

```markdown
Do not run `--stamp`, `--sync`, or `--upgrade` from this command. Those are
Joshua-approved mutation paths only.

## Output
```

## Insertion block (to be added BETWEEN those two)

```markdown
## Fleet-canonical-rule-freshness check (bead `flywheel-ol1bu`)

Per the probe's own header TODO ("Skeleton — NOT yet wired into doctor.
Follow-up bead: wire into /flywheel:fleet-doctor.") and per L-rule
`L056-L102-meta-rule-cache-must-refresh-on-tick.md` + skill onboard.md
canonical citation. Originating bead `flywheel-1rmp.10` companion path
(doctrine cites probe but no orchestrator fired it until this wire-in).

Run the canonical fleet-canonical-rule-freshness probe to surface
per-session META-RULE-CACHE.md staleness vs canonical INDEX.md
(reports `lag_seconds` + `status` per session: fresh|stale|missing):

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh --json
```

Output is read-only stdout JSON. Per Step 4o anti-pattern guardrail
mirrored from /flywheel:tick: SURFACES findings only — does NOT
auto-file beads, does NOT auto-dispatch, does NOT mutate cache. The
orchestrator (or Joshua) decides whether to trigger a fleet-wide refresh
via the L-rule L056-L102 fleet-canonical-meta-rules-sync path.

Optional orch-side append (parallels /flywheel:tick Dim-9 pattern from
`flywheel-myfak.1`) — captures probe output to ledger for retention:

```bash
.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh --json | \
  jq -c '{ts: now | todateiso8601, source: "fleet-doctor", probe: "fleet-canonical-rule-freshness-probe", output: .}' \
  >> "$HOME/.local/state/flywheel/fleet-canonical-rule-freshness-probe-runs.jsonl"
```
```

## Rationale

Per `flywheel-2xdi.87` evidence pack, the probe was filed TRUE POSITIVE probe-without-receiver: doctrinally canonical (L-rule cites it, onboard.md cites it) but no orchestrator fires it. The probe's own header docstring explicitly names `/flywheel:fleet-doctor` as the target receiver.

Pattern mirror: this is the same shape as `flywheel-myfak.1` (which wired `adversarial-orch-self-audit-probe.sh` into `/flywheel:tick` Step 4o Dimension-9). Both:
- Probe shipped read-only, doesn't self-log internally
- Doctrine cites the probe as canonical
- Wire-in receives stdout JSON and optionally appends to ledger for retention

## Verification post-import

```bash
# 1. Confirm subsection present
grep -nE 'Fleet-canonical-rule-freshness check|flywheel-ol1bu' /Users/josh/.claude/commands/flywheel/fleet-doctor.md

# 2. Run /flywheel:fleet-doctor; ledger should accrue rows
/flywheel:fleet-doctor
ls -la ~/.local/state/flywheel/fleet-canonical-rule-freshness-probe-runs.jsonl
# Expected: file exists with >=1 JSON row from this session
```

## Boundary

Per `feedback_no_push_ntm_br.md` + `project_skillos_separated.md`: this patch targets `.claude/commands/` (skill substrate, separate repo from flywheel.git). Direct mutation already applied in `flywheel-ol1bu` dispatch from flywheel pane because `commands/flywheel` is unmanaged in JSM. This artifact exists for future JSM import if/when the skill becomes managed.

## Consistency observation

The probe is read-only and doesn't self-log to its declared `SCAFFOLD_AUDIT_LOG` path on `--json` invocation. The Optional orch-side append block in the insertion (mirrored from `/flywheel:tick` Step 4o Dim-9 doctrine) is the canonical pattern for capturing read-only probe output to ledger. This is the SAME pattern as the adversarial-orch-self-audit-probe wire-in (`flywheel-myfak.1` consistency observation) — orch-side append is responsibility-of-tick/responsibility-of-fleet-doctor.

Future-candidate enhancement: add `--audit-log` mode to the probe so it self-logs internally, eliminating the orch-side append requirement. Would require probe-side edit (out of scope for this wire-in; covered by `flywheel-myfak.1` evidence pack's same observation).
