# DISPATCH PACKET (canonical)
# Task ID: flywheel-kvt8v-proof
# Bead: flywheel-kvt8v (P1)
# Title: Propagate evidence_redacted into peer callbacks
# Target: flywheel:0.2
# Callback pane: 1
# Identity: CloudyMill (status=active)
# Started: 2026-05-09T05:30:00Z
# worker_substrate=codex-pane
# agent_type=codex

## CALLBACK CONTRACT

When complete, send EXACTLY ONE of:

```bash
/Users/josh/.local/bin/ntm send flywheel --pane=1 --no-cass-check "DONE flywheel-kvt8v task_id=flywheel-kvt8v-proof josh_request_id=null identity_name=CloudyMill did=<n>/<total> didnt=<bead-ids-or-none> gaps=<bead-ids-or-none> evidence=<path-or-command-ref> evidence_redacted=<yes|no|n/a> tests=PASS|FAIL|SKIPPED tmp_dir_released=true mission_fitness=direct|adjacent|infrastructure|drift mission_fitness_evidence=<bead-or-sentence> br_close_executed=yes git_committed=<yes|no_changes|skipped> callback_delivery_verified=true worker_substrate=codex-pane agent_type=codex socraticode_queries=<int> indexed_chunks_observed=<int> artifact_checks=<artifact-id:path:exists|missing|unknown,...> validation_notes=<short> files_reserved=<comma-list|NONE_READONLY|NONE_NO_EDITS|UNAVAILABLE:reason> files_released=<comma-list|NONE_READONLY|NONE_NO_EDITS|UNAVAILABLE:reason> beads_filed=<ids|none> beads_updated=<ids|none> no_bead_reason=<specific-or-none> fuckups_logged=<classes|none> next_phase=<id|none> chain_if_capacity=<done|not_applicable> chain_blocked_reason=<reason|none> blocker_type=<flywheel_class|peer_class|external|unknown|none> blocker_class=<class|none> flywheel_orch_action_required=<action|none> compliance_score=<N>/1000 compliance_pack_path=<audit-dir>/flywheel-kvt8v/ l112_probe_command=<command> l112_probe_expected=<jq:filter|grep:pattern|literal:text> l112_probe_timeout_sec=<seconds> skill_auto_routes_addressed=<canonical-cli-scoping=yes|no|n/a,rust-best-practices=yes|no|n/a,python-best-practices=yes|no|n/a,readme-writing=yes|no|n/a> skill_discoveries=<N> sd_ids=<ids|none> cli_canonical=<yes|no> rust_clean=<yes|no|n/a> python_clean=<yes|no|n/a> readme_quality=<yes|no|n/a> four_lens=brand:N,sniff:N,jeff:N,public:N"
```

If blocked: `BLOCKED flywheel-kvt8v-proof reason=<short> need=<short> mission_fitness=<class> josh_request_id=null identity_name=CloudyMill did=<n>/<total> didnt=<bead-ids-or-none> gaps=<bead-ids-or-none> evidence=<path> evidence_redacted=<yes|no|n/a> worker_substrate=codex-pane agent_type=codex socraticode_queries=<int> indexed_chunks_observed=<int> files_reserved=<list-or-reason> files_released=<list-or-reason> beads_filed=<ids|none> beads_updated=<ids|none> no_bead_reason=<specific-or-none> fuckups_logged=<classes|refs> tmp_dir_released=true br_close_executed=not_applicable callback_delivery_verified=true`
If declining: `DECLINED flywheel-kvt8v-proof reason=<scope-mismatch|capability|risk> mission_fitness=drift josh_request_id=null identity_name=CloudyMill evidence_redacted=n/a worker_substrate=codex-pane agent_type=codex br_close_executed=not_applicable callback_delivery_verified=true`

## MISSION FITNESS CLAIM BLOCK

```text
mission_anchor=continuous-orchestrator-uptime-self-sustaining-fleet
mission_fitness_claim=Bead flywheel-kvt8v advances substrate work supporting the mission anchor.
mission_fitness_class=adjacent
```

Workers MUST echo `mission_fitness=<direct|adjacent|infrastructure|drift>` in the DONE callback.

## JOSH REQUEST LINKAGE BLOCK

```text
josh_request_id=null
```

DONE/BLOCKED/DECLINED callbacks MUST include the same field and value verbatim.

## LOCKED WORKER IDENTITY BLOCK

```text
identity_name=CloudyMill
identity_source=/Users/josh/.local/state/flywheel/orch-worker-identity/flywheel.json
worker_identity=CloudyMill
worker_identity_status=active
```

If `worker_identity_status=needs_registration`, dispatch wrapper triggered registration before this packet was sent.

## SHARED-SURFACE RESERVATION BLOCK (L107)

Agent Mail and shared-surface reservation are both part of the dispatch contract for edit tasks. Before staging shared paths (commit-touched files), reserve:
```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/shared-surface-reservation-check.sh --reserve <path> --pane=2 --session flywheel --task-id=flywheel-kvt8v-proof --json
```
Release after commit or before BLOCKED/DECLINED:
```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/shared-surface-reservation-check.sh --release <path> --pane=2 --session flywheel --task-id=flywheel-kvt8v-proof --json
```
Worker callback MUST include `shared_surface_reservations_checked=yes shared_surface_reservations_released=yes files_reserved=<comma-list|NONE_READONLY|NONE_NO_EDITS|UNAVAILABLE:reason> files_released=<comma-list|NONE_READONLY|NONE_NO_EDITS|UNAVAILABLE:reason>`.

## TMP LIFECYCLE BLOCK

At dispatch start create one scratch directory: `WORK_TMP="$(mktemp -d -t flywheel-kvt8v.XXXXXX)"`. Copy durable evidence out before close, remove the directory, and callback with `tmp_dir_released=true`.

## FILE DISCIPLINE (PICOZ_WORKER_FILES)

Edit ONLY files named in this packet TASK BODY or files explicitly named in the bead body. Other edits require an in-band ntm message asking for scope expansion BEFORE the edit. If you edit files, set `PICOZ_WORKER_FILES` to those paths before commit and use pathspec staging only.

## VERIFICATION (pre-DONE)

Run verification commands from the bead acceptance section. If none are explicit, run:
```bash
bash -n <any-edited-shell-script>
br show flywheel-kvt8v  # confirm bead state
```
The packet must remain auditable through `.flywheel/validation-schema/v1/schema.json`, `.flywheel/validation-schema/v1/parse.sh`, and orchestrator `validate-callback` before closeout.

## DID / DIDNT / GAPS BLOCK (L80 / L52)

Worker DONE callback MUST include:
- `did=<count>/<total-bead-acceptance-criteria>`
- `didnt=<bead-ids-skipped-or-none>`
- `gaps=<bead-ids-newly-discovered-or-none>`
- one L52 bead receipt: `beads_filed=<ids>`, `beads_updated=<ids>`, or `no_bead_reason=<specific reason>`

## SKILL DISCOVERY DUTY

If a reusable pattern, skill gap, broken skill, or incomplete skill appears, append a `skill-discovery/v1` row and callback with `skill_discoveries=<N> sd_ids=<ids|none>`. Clean dispatches may use `skill_discoveries=0 sd_ids=none` with a concrete no-discovery reason in evidence.

## VERIFY-CALLBACK BLOCK

After sending DONE/BLOCKED/DECLINED, verify delivery to `flywheel:1` and include `callback_delivery_verified=true`. The clean success value is true; false or unknown is non-pass.

## AUTO-L112 CALLBACK GATE BLOCK

Callback must include `l112_probe_command=<re-runnable shell command>`, `l112_probe_expected=<jq:<filter>|grep:<pattern>|literal:<text>>`, and `l112_probe_timeout_sec=<positive-int>` so the orchestrator can run the worker acceptance proof.

## SKILL AUTO-ROUTES BLOCK

This packet is augmented by `_shared/inject-skill-auto-routes.sh`. Workers MUST address every route in `skill_auto_routes_addressed=canonical-cli-scoping=yes|no|n/a,rust-best-practices=yes|no|n/a,python-best-practices=yes|no|n/a,readme-writing=yes|no|n/a`.

## FOUR-LENS SELF-GRADE BLOCK

Before callback, add a report section named `Four-Lens Self-Grade`. Score 1-10 each and include the bar names exactly: `four_lens=brand:N,sniff:N,jeff:N,public:N`. Public lens must include the Three Judges check: would the artifact pass a skeptical operator, maintainer, and future worker?

## L61 ECOSYSTEM-TOUCH BLOCK

If this work touches doctrine|INCIDENTS|canonical|L-rule|skill, callback MUST include:
- `agents_md_updated=yes|no|not_applicable`
- `readme_updated=yes|no|not_applicable`
- `no_touch_reason=<reason>` (when either is `no`)

## L120 BR-CLOSE-EXECUTED BLOCK

DONE callback MUST include `br_close_executed=yes|failed|not_applicable`.
`yes` requires `br close flywheel-kvt8v` exited 0 BEFORE the ntm send DONE.

## TASK BODY (bead context)

### Title
Propagate evidence_redacted into peer callbacks

### Description
## Goal
Make mobile-eats, alpsinsurance, and skillos worker DONE/BLOCKED callback templates emit evidence_redacted=yes|no|n/a, then rerun the 24h adoption probe.

## Context
PHASE: evidence_redacted fleet adoption follow-up
CRITERION: callback-contract
flywheel-cg0mr verified that doctrine sync reached peer repos (rules/doctrine mention evidence_redacted), but observed worker callbacks after flywheel-dwavb closed at 2026-05-09T03:46:43Z still omit the field. Sessions checked: mobile-eats, alpsinsurance, skillos. This means doctrine text propagated, but callback authoring templates/prompts have not fully adopted the field.

## Dependencies
None.

## Inputs / Outputs
INPUTS: ntm history --session mobile-eats/alpsinsurance/skillos --limit 200 --json; peer repo .flywheel doctrine/rules search for evidence_redacted.
OUTPUTS: updated peer callback template or dispatch wrapper surface, plus a fresh 24h adoption evidence pack showing field presence in worker callbacks and evidence-class paths using evidence_redacted=yes.

## Acceptance Criteria
- Each target session has at least one worker callback after the fix containing evidence_redacted=yes|no|n/a.
- Evidence-class paths in callback/reservation fields validate only with evidence_redacted=yes.
- No broad sync-canonical-doctrine apply is run unless a scoped drift receipt names the managed drift.
- Evidence pack cites exact ntm history probes and validator output.

## Testing Obligations
- Run ntm history probes for mobile-eats, alpsinsurance, and skillos.
- Run validate-callback fixture proving evidence-class paths require yes.
- SKILLS: canonical-cli-scoping, readme-writing.

## Definition of Done
COMMIT: chore(callback): record evidence_redacted peer adoption
- Peer callbacks include evidence_redacted
- Validation gate proves evidence-class path requirement
- AUTONOMY: autonomous

### Dependencies
```json
[{"id":"flywheel-kvt8v","title":"Propagate evidence_redacted into peer callbacks","depth":0,"parent_id":null,"priority":1,"status":"open","truncated":false}]
```

### Priority
P1

### Acceptance
Acceptance criteria are sourced from the bead body above. Callback `did=<n>/<total>` must count those gates.

### Verification Command
Use the bead acceptance verification if present; otherwise: `bash -n <edited-shell> && .flywheel/validation-schema/v1/dispatch-template-audit.sh <packet>`.

### NTM Context And Template
```text
ntm_context_source=context build --json
ntm_context_repo_rev=3744c38e17da0058abc3ed00ad9d04622cf7feb6
ntm_template_name=marching_orders
ntm_template_source=builtin
```

## VALIDATION BLOCK

Every worker dispatch MUST leave structured evidence for the orchestrator to run `validate-callback` before summary, integration, bead closeout, reopen decisions, or `/flywheel:learn` routing.

Validation receipt contract:
- Schema: `/Users/josh/Developer/flywheel/.flywheel/validation-schema/v1/schema.json`
- Parser: `bash /Users/josh/Developer/flywheel/.flywheel/validation-schema/v1/parse.sh <receipt.json>`
- Orchestrator step: `validate-callback`
- `status=unknown` is non-pass.

Before callback, collect `evidence[]`, `artifact_checks[]`, runtime_context from the agent execution context, L52 bead actions, L53 `fuckups_logged=`, and L70 `chain_if_capacity` / `chain_blocked_reason=` fields. Callback must include `artifact_checks=`, `validation_notes=`, `files_released=`, `fuckups_logged=`, `next_phase=`, `chain_if_capacity`, `chain_blocked_reason=`, `beads_filed=`, `beads_updated=`, and `no_bead_reason=`.

## QUALITY BAR (MANDATORY)

Before DONE, produce or cite a compliance evidence pack. Callback must include `compliance_score=<N>/1000`, `compliance_pack_path=<audit-dir>/flywheel-kvt8v/`, `cli_canonical=<yes|no>`, `rust_clean=<yes|no|n/a>`, `python_clean=<yes|no|n/a>`, and `readme_quality=<yes|no|n/a>`. If the score is below 700/1000, return BLOCKED instead of DONE.

## DISPATCH CAPACITY GATE

`chain_if_capacity`: if a concrete `next_phase` remains and capacity exists, run it in the same turn; otherwise callback with `chain_blocked_reason=<concrete cause>`. Missing chain and missing blocker are non-pass.

## EXECUTION

1. Read this entire packet
2. Run `br show flywheel-kvt8v` to confirm context
3. Run `br dep tree flywheel-kvt8v` to see dependencies
4. Apply socraticode K>=10 if non-trivial code claim involved
5. Reserve any shared paths via L107 script before edits
6. Execute the bead acceptance criteria
7. Run verification and dispatch-template audit when this packet is the artifact
8. `br close flywheel-kvt8v` (BEFORE callback per L120)
9. Send DONE callback per CALLBACK CONTRACT above

## METADATA

```text
schema_version=dispatch-packet.v1
packet_built_by=build-dispatch-packet.sh@0.3.1
packet_built_at=2026-05-09T05:30:00Z
ntm_context_source=context build --json
ntm_template_source=template show marching_orders --body --json
```

## MEMORY HITS

5 relevant memory entries found by `mem memory search "DISPATCH PACKET canonical class none adjacent flywheel"`:

- `feedback_canonical_cli_at_dispatch.md` (-Users-josh-Developer-flywheel, feedback) - Any CLI/command/flag/subcommand dispatch MUST cite canonical-cli-scoping skill and embed its Implementation Checklist as the bead accepta...
- `feedback-A3-single-source-of-truth-worker-reflexive-2026-04-27.md` (-Users-josh, feedback) - Workers now reflexively choose single-source-of-truth refactor when dispatch packet offers multiple fix paths — A3 pattern internalized
- `feedback-pane-dispatch-must-include-callback-route.md` (-Users-josh, feedback) - When dispatching to tmux panes (vs bg-agents), the worker has no native callback channel. Dispatch packets must end with an explicit `ntm...
- `feedback_canonical_scope_doctrine_2026_04_29.md` (-Users-josh-Developer-vrtx, feedback) - For any signed engagement, paste the deal-closing email VERBATIM into a docs/SIGNED-SCOPE-<source>-<date>.md file marked canonical, point...
- `project-2026-04-27-wave-a-complete-ntm-callback-proven.md` (-Users-josh-Developer-zesttube, project) - Best operational round of zesttube to date (9.7/10). Wave A foundation 8/8 complete (A1 Pydantic schema, A1+ cross_brand_export_policy pa...

(Logged 5 reads via mem memory telemetry. Run `mem memory why <FILE>` for context on any entry.)

## SKILL AUTO-ROUTES

skill_auto_routes=4
skill_auto_routes_task_id=flywheel-kvt8v-proof
skill_auto_routes_catalog=canonical-cli-scoping,rust-best-practices,python-best-practices,readme-writing
skill_auto_routes_matched=canonical-cli-scoping,rust-best-practices,python-best-practices,readme-writing
skill_auto_routes_addressed=canonical-cli-scoping=n/a,rust-best-practices=n/a,python-best-practices=n/a,readme-writing=n/a

Worker callback MUST include `skill_auto_routes_addressed=` with each catalog skill set to `yes`, `no`, or `n/a`, plus file:line evidence or a re-runnable command for every non-`n/a` route.

### canonical-cli-scoping
source=/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:324
triggered_by=\bCLI\b, \bcommand\b, \bsubcommand\b, \bflag\b, --[A-Za-z0-9][A-Za-z0-9_-]*
acceptance_gates:
[ ] doctor / health / repair triad addressed or explicitly n/a
[ ] validate / audit / why subsidiary triad addressed or explicitly n/a
[ ] --json, schema output, and stable exit-code behavior addressed
[ ] --dry-run / --apply or --explain mutation discipline addressed
[ ] file-length threshold respected or allowed-large receipt cited

### rust-best-practices
source=/Users/josh/.claude/skills/rust-best-practices/SKILL.md:425
triggered_by=\bRust\b
acceptance_gates:
[ ] cargo fmt -- --check passes or n/a reason cited
[ ] cargo clippy -- -D warnings passes or n/a reason cited
[ ] cargo test passes or n/a reason cited
[ ] typed errors avoid library unwraps
[ ] Rust module/file shape stays under 500 lines or receipt cited

### python-best-practices
source=/Users/josh/.claude/skills/python-best-practices/SKILL.md:25
triggered_by=\bPython\b
acceptance_gates:
[ ] public function signatures have type hints or n/a reason cited
[ ] pyproject / ruff / pytest config expectations addressed
[ ] tests mirror touched modules or n/a reason cited
[ ] file operations use fixtures/tmp paths in tests
[ ] Python module/file shape stays under 400 lines or receipt cited

### readme-writing
source=/Users/josh/.claude/skills/readme-writing/SKILL.md:120
triggered_by=\bREADME\b
acceptance_gates:
[ ] Quick Start stays copy-pasteable and <=5 core commands
[ ] when-to-use / when-not-to-use or limitations are explicit
[ ] anti-patterns or troubleshooting table included when public-facing
[ ] every feature claim has a concrete example or evidence
[ ] README/public-doc prose is scannable and source-grounded

## L-RULE HINTS

l_rule_hints=3
l_rule_hints_task_id=flywheel-kvt8v-proof
l_rule_hints_source=/Users/josh/Developer/flywheel/.flywheel/rules
l_rule_hints_matched=L52,L107,L70

Relevant canonical doctrine hints for this dispatch. Treat these as pointers, not new acceptance gates.

### L52 — ISSUES-TO-BEADS-OR-EXPLICIT-NO-BEAD-RECEIPT (no observed gap is absorbed sile...
source=/Users/josh/Developer/flywheel/.flywheel/rules/L006-L52-issues-to-beads-or-explicit-no-bead-receipt-no-observed-gap-is-absorbe.md
score=127
why=L52,audit,bead,behavior,callbacks,explicit

### L107 — SHARED-SURFACE-WRITES-MUST-RESERVE-ACROSS-PANES
source=/Users/josh/Developer/flywheel/.flywheel/rules/L061-L107-shared-surface-writes-must-reserve-across-panes.md
score=122
why=L107,active,callbacks,doctor,panes,readme

### L70 — ORCH-NO-PUNT (next actionable runs same tick, not next tick)
source=/Users/josh/Developer/flywheel/.flywheel/rules/L024-L70-orch-no-punt-next-actionable-runs-same-tick-not-next-tick.md
score=122
why=L70,callbacks,chain_blocked_reason,concrete,next_phase,phase
