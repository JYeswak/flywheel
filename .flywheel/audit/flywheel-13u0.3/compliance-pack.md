# flywheel-13u0.3 compliance pack

Task: `flywheel-13u0.3-047a1b`
Bead: `flywheel-13u0.3`
Identity: `CloudyMill`
Date: 2026-05-09

## Scope

Triage for `[incidents-followup] stale flywheel tick command protocol from flywheel-38o`.

This worker did not edit `INCIDENTS.md`. The dispatch explicitly required no INCIDENTS mutation without Joshua or orchestrator approval, so this pack records the decision and proposed incident text only.

## Decision

Recommendation: promote a new INCIDENTS class, `stale-command-protocol-drift`, rather than closing under an existing command/drift incident.

Reason: existing entries cover adjacent patterns, but not this specific failure mode:

- `bypass-canonical-substrate-cluster` covers bypassing canonical surfaces during high-tempo work. It does not cover a canonical visible command being stale.
- `three-surface-drift-detected` covers canonical doctrine convergence across three surfaces. It does not cover operator-facing slash-command/runbook protocol freshness.
- `tick-driver-primitive-failed` covers runtime primitive failures in the tick driver. It does not cover stale human/agent command instructions.

The incident belongs in `INCIDENTS.md` because a visible command surface caused agents to follow yesterday's protocol until Joshua flagged it. This is doctrine delivery failure, not only a one-off stale file.

## Required Citation

- Bead: `flywheel-38o`, title `tick-md-skill-update-with-new-protocol`, closed 2026-05-01T14:38:16Z.
- Updated command file: `/Users/josh/.claude/commands/flywheel/tick.md`.
- Dispatch log: `.flywheel/dispatch-log.jsonl` records `flywheel-38o` dispatched as `tick_md_update_v2` and later reaped `done`.

## Evidence

| Claim | Evidence |
|---|---|
| `flywheel-38o` is the source bead | `br show flywheel-38o --json` returns `status=closed` and describes Joshua's stale `/flywheel:tick` report. |
| The visible command file now carries version/freshness markers | `/Users/josh/.claude/commands/flywheel/tick.md:6-7` has `skill_version: 2` and a validator note. |
| Current `/flywheel:tick` command file names Codex-equivalent current tick commands | `/Users/josh/.claude/commands/flywheel/tick.md:40-47`. |
| Current `/flywheel:tick` command file contains the added awareness step | `/Users/josh/.claude/commands/flywheel/tick.md:100-120`. |
| Current `/flywheel:tick` command file contains inbox/fuckup/PageRank/L61 additions | `/Users/josh/.claude/commands/flywheel/tick.md:188-209`, `270-318`, `511-541`. |
| Current `/flywheel:tick` command file carries receipt schema v2-style fields | `/Users/josh/.claude/commands/flywheel/tick.md:1118-1201` includes `awareness_check`, `inbox_messages_handled`, `fuckups_to_beads`, `pagerank_top_5_blockers`, and `dual_channel_pct`. |
| Existing incident candidates are adjacent but not exact | `INCIDENTS.md:548-573` and `INCIDENTS.md:5238-5284`. |

## Proposed Incident Entry

Class: `stale-command-protocol-drift`

Severity: medium/high. A visible command/runbook had fallen behind canonical procedure and caused repeated operator/agent execution of stale `/flywheel:tick` behavior until Joshua intervened.

Root Cause: The `/flywheel:tick` operator surface was manually maintained and did not have a freshness/protocol-version check against the canonical tick design and receipt schema. Agents trusted the visible command file as canonical.

Forever-Rule: Command/runbook surfaces must either be generated from canonical doctrine or carry a freshness/protocol-version check. If a command surface names an operational protocol, it must expose the protocol version, canonical source reference, and a validator or audit command that refuses stale loaded content before execution.

Fix Applied/Status: Proposed only. `flywheel-38o` already updated `/Users/josh/.claude/commands/flywheel/tick.md` to include current tick steps and receipt fields. INCIDENTS promotion is pending Joshua/orchestrator approval.

Evidence:

- `flywheel-38o`.
- `/Users/josh/.claude/commands/flywheel/tick.md`.
- `.flywheel/dispatch-log.jsonl` rows for `tick_md_update_v2`.
- This audit pack.

## Acceptance Gates

AG1: Pass. Determined that this should become a new `stale-command-protocol-drift` INCIDENTS class, not be merged into an existing adjacent incident.

AG2: Pass. Cited `flywheel-38o` and `/Users/josh/.claude/commands/flywheel/tick.md`.

AG3: Pass. Included the Forever-Rule text required if promoted.

AG4: Pass. Did not edit `INCIDENTS.md`; approval remains pending.

## Verification Commands

```bash
br show flywheel-13u0.3 --json
br dep tree flywheel-13u0.3
br show flywheel-38o --json
rg -n "skill_version: 2|tick-skill-version-check|awareness_check|inbox_messages_handled|fuckups_to_beads|pagerank_top_5_blockers|dual_channel_pct" /Users/josh/.claude/commands/flywheel/tick.md
rg -n "bypass-canonical-substrate-cluster|three-surface-drift-detected|tick-driver-primitive-failed" INCIDENTS.md
bash .flywheel/receipts/flywheel-13u0.3/l112-probe.sh
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-13u0.3-047a1b.md
```

## Skill Auto-Routes

`canonical-cli-scoping=n/a`: no CLI implementation changed; this is command-surface incident triage only.

`rust-best-practices=n/a`: no Rust files changed.

`python-best-practices=n/a`: no Python files changed.

`readme-writing=n/a`: no README changed.

## L61 Surface

This task touches incident/doctrine triage but does not mutate `INCIDENTS.md`, AGENTS, README, canonical L-rules, or skill files. `agents_md_updated=not_applicable`, `readme_updated=not_applicable`, `no_touch_reason=triage_evidence_only_incidents_mutation_requires_approval`.

## L52 / L53

No new bead was filed. This bead itself is the follow-up vehicle for the gap and closes with explicit promotion recommendation. INCIDENTS mutation requires approval, so no downstream implementation bead was created by this worker.

No fuckup row was logged.

## Four-Lens Self-Grade

`four_lens=brand:7,sniff:8,jeff:8,public:8`

Brand: makes the doctrine delivery failure explicit without mutating unapproved incident surfaces.

Sniff: cites the source bead, command file, dispatch log, and adjacent incident entries.

Jeff: keeps the reusable rule concrete: generated command surfaces or freshness/protocol-version checks.

Public: a skeptical operator, maintainer, and future worker can rerun the probe and see why this is not merely three-surface drift.

## Compliance Score

`780/1000`

The score clears the 700 DONE bar. It is capped because the INCIDENTS promotion remains proposed, not applied.
