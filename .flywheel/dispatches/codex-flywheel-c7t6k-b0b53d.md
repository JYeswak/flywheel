# DISPATCH PACKET (canonical)
# Task ID: flywheel-c7t6k-b0b53d
# Bead: flywheel-c7t6k (P0)
# Title: JSM ingest halt — coordinate 8-orch fleet block during substrate-replacement investigation
# Target: flywheel:0.2
# Callback pane: 1
# Identity: CloudyMill (status=active)
# Started: 2026-05-20T21:30:38Z
# worker_substrate=codex-pane
# agent_type=codex

## CALLBACK CONTRACT

When complete, send EXACTLY ONE of:

```bash
/Users/josh/.local/bin/ntm send flywheel --pane=1 --no-cass-check "DONE flywheel-c7t6k task_id=flywheel-c7t6k-b0b53d josh_request_id=null identity_name=CloudyMill did=<n>/<total> didnt=<bead-ids-or-none> gaps=<bead-ids-or-none> evidence=<path-or-command-ref> evidence_redacted=<yes|no|n/a> tests=PASS|FAIL|SKIPPED tmp_dir_released=true mission_fitness=direct|adjacent|infrastructure|drift mission_fitness_evidence=<bead-or-sentence> br_close_executed=yes git_committed=<yes|no_changes|skipped> callback_delivery_verified=true worker_substrate=codex-pane agent_type=codex socraticode_queries=<int> indexed_chunks_observed=<int> artifact_checks=<artifact-id:path:exists|missing|unknown,...> validation_notes=<short> files_reserved=<comma-list|NONE_READONLY|NONE_NO_EDITS|UNAVAILABLE:reason> files_released=<comma-list|NONE_READONLY|NONE_NO_EDITS|UNAVAILABLE:reason> beads_filed=<ids|none> beads_updated=<ids|none> no_bead_reason=<specific-or-none> fuckups_logged=<classes|none> next_phase=<id|none> chain_if_capacity=<done|not_applicable> chain_blocked_reason=<reason|none> blocker_type=<flywheel_class|peer_class|external|unknown|none> blocker_class=<class|none> flywheel_orch_action_required=<action|none> compliance_score=<N>/1000 compliance_pack_path=<audit-dir>/flywheel-c7t6k/ l112_probe_command=<command> l112_probe_expected=<jq:filter|grep:pattern|literal:text> l112_probe_timeout_sec=<seconds> skill_auto_routes_addressed=<canonical-cli-scoping=yes|no|n/a,rust-best-practices=yes|no|n/a,python-best-practices=yes|no|n/a,readme-writing=yes|no|n/a> skill_discoveries=<N> sd_ids=<ids|none> cli_canonical=<yes|no> rust_clean=<yes|no|n/a> python_clean=<yes|no|n/a> readme_quality=<yes|no|n/a> four_lens=brand:N,sniff:N,jeff:N,public:N"
```

If blocked: `BLOCKED flywheel-c7t6k-b0b53d reason=<short> need=<short> mission_fitness=<class> josh_request_id=null identity_name=CloudyMill did=<n>/<total> didnt=<bead-ids-or-none> gaps=<bead-ids-or-none> evidence=<path> evidence_redacted=<yes|no|n/a> worker_substrate=codex-pane agent_type=codex socraticode_queries=<int> indexed_chunks_observed=<int> files_reserved=<list-or-reason> files_released=<list-or-reason> beads_filed=<ids|none> beads_updated=<ids|none> no_bead_reason=<specific-or-none> fuckups_logged=<classes|refs> tmp_dir_released=true br_close_executed=not_applicable callback_delivery_verified=true`
If declining: `DECLINED flywheel-c7t6k-b0b53d reason=<scope-mismatch|capability|risk> mission_fitness=drift josh_request_id=null identity_name=CloudyMill evidence_redacted=n/a worker_substrate=codex-pane agent_type=codex br_close_executed=not_applicable callback_delivery_verified=true`

## MISSION FITNESS CLAIM BLOCK

```text
mission_anchor=continuous-orchestrator-uptime-self-sustaining-fleet
mission_fitness_claim=Bead flywheel-c7t6k advances substrate work supporting the mission anchor.
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

## PRE-FLIGHT BEAD PRESENCE BLOCK (Forever Rule: bead-missing-from-local-db)

Before any work, verify the bead is present in the worker's local Beads DB. Cross-worktree dispatches (orch repo A → worker mktemp checkout B) frequently miss beads created post-branch. Per `INCIDENTS.md#bead-missing-from-local-db` (filed by `flywheel-s2yd8`), the canonical sequence is verify-then-sync-or-surface:

```bash
# Step 1 — fast-path check
if ! br show flywheel-c7t6k --json >/dev/null 2>&1; then
  # Step 2 — recovery fallback (pull JSONL → DB; does not disturb other rows)
  br sync --import-only 2>/dev/null || true
  if ! br show flywheel-c7t6k --json >/dev/null 2>&1; then
    # Step 3 — SURFACE, do NOT silently treat missing bead as success.
    # Send BLOCKED callback with blocker_class=bead_missing_from_local_db
    # so orch can reconcile via `br sync --flush-only` on its side.
    /Users/josh/.local/bin/ntm send flywheel --pane=1 --no-cass-check "BLOCKED flywheel-c7t6k-b0b53d reason=bead_missing_from_local_db need=orch_br_sync_flush_only mission_fitness=adjacent josh_request_id=null identity_name=CloudyMill blocker_type=flywheel_class blocker_class=bead_missing_from_local_db tmp_dir_released=true br_close_executed=not_applicable callback_delivery_verified=true"
    exit 0
  fi
fi
```

Forever-Rule discipline:
- Workers MUST NOT silently treat a missing bead as success.
- Workers MUST NOT fabricate a `br close` outcome by writing directly to `.beads/issues.jsonl` (canonical write path is `br close`).
- The `br sync --import-only` fallback is non-disturbing: it pulls JSONL → DB without touching other rows.

## SHARED-SURFACE RESERVATION BLOCK (L107)

Agent Mail and shared-surface reservation are both part of the dispatch contract for edit tasks. Before staging shared paths (commit-touched files), reserve:
```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/shared-surface-reservation-check.sh --reserve <path> --pane=2 --session flywheel --task-id=flywheel-c7t6k-b0b53d --json
```
Release after commit or before BLOCKED/DECLINED:
```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/shared-surface-reservation-check.sh --release <path> --pane=2 --session flywheel --task-id=flywheel-c7t6k-b0b53d --json
```
Worker callback MUST include `shared_surface_reservations_checked=yes shared_surface_reservations_released=yes files_reserved=<comma-list|NONE_READONLY|NONE_NO_EDITS|UNAVAILABLE:reason> files_released=<comma-list|NONE_READONLY|NONE_NO_EDITS|UNAVAILABLE:reason>`.

## TMP LIFECYCLE BLOCK

At dispatch start create one scratch directory using the safe two-line idiom (per `INCIDENTS.md#clobbered_doctrine_docs`, `flywheel-tpprm`):
```bash
WORK_TMP="$(mktemp -d -t flywheel-c7t6k.XXXXXX)" || { echo "ERR: mktemp failed" >&2; exit 1; }
cd "$WORK_TMP" || { echo "ERR: cd failed: $WORK_TMP" >&2; exit 1; }
```
For any subsequent `cd` into worker-supplied paths in fixture-setup blocks (e.g., user-supplied scratch dirs, special-char paths), use the Layer-1 prevention primitive: `.flywheel/scripts/cd-realpath-wrapper.sh` (resolves + verifies sandbox membership before `cd`; refuses outside-sandbox or realpath-fail with explicit rc=2/3). Sister recovery primitive on clobber: `.flywheel/scripts/clobber-recovery.sh`. Copy durable evidence out before close, remove the directory, and callback with `tmp_dir_released=true`.

## FILE DISCIPLINE (PICOZ_WORKER_FILES)

Edit ONLY files named in this packet TASK BODY or files explicitly named in the bead body. Other edits require an in-band ntm message asking for scope expansion BEFORE the edit. If you edit files, set `PICOZ_WORKER_FILES` to those paths before commit and use pathspec staging only.

## VERIFICATION (pre-DONE)

Run verification commands from the bead acceptance section. If none are explicit, run:
```bash
bash -n <any-edited-shell-script>
br show flywheel-c7t6k  # confirm bead state
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
`yes` requires `br close flywheel-c7t6k` exited 0 BEFORE the ntm send DONE.

## TASK BODY (bead context)

### Title
JSM ingest halt — coordinate 8-orch fleet block during substrate-replacement investigation

### Description
Wire ingest block across 8 orchs until substrate rebuilt + integrity-gated. PreToolUse-on-Bash hook on jsm create/validate/push/ingest. Ship after skillos:1 ACK + Joshua approval.

### Dependencies
```json
[{"id":"flywheel-c7t6k","title":"JSM ingest halt — coordinate 8-orch fleet block during substrate-replacement investigation","depth":0,"parent_id":null,"priority":0,"status":"open","truncated":false}]
```

### Priority
P0

### Acceptance
Acceptance criteria are sourced from the bead body above. Callback `did=<n>/<total>` must count those gates.

### Verification Command
Use the bead acceptance verification if present; otherwise: `bash -n <edited-shell> && .flywheel/validation-schema/v1/dispatch-template-audit.sh <packet>`.

### NTM Context And Template
```text
ntm_context_source=context build --json
ntm_context_repo_rev=98504cbb3c3cb624fcf43ed74040055a52509a8c
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

Before DONE, produce or cite a compliance evidence pack. Callback must include `compliance_score=<N>/1000`, `compliance_pack_path=<audit-dir>/flywheel-c7t6k/`, `cli_canonical=<yes|no>`, `rust_clean=<yes|no|n/a>`, `python_clean=<yes|no|n/a>`, and `readme_quality=<yes|no|n/a>`. If the score is below 700/1000, return BLOCKED instead of DONE.

## DISPATCH CAPACITY GATE

`chain_if_capacity`: if a concrete `next_phase` remains and capacity exists, run it in the same turn; otherwise callback with `chain_blocked_reason=<concrete cause>`. Missing chain and missing blocker are non-pass.

## EXECUTION

1. Read this entire packet
2. Run `br show flywheel-c7t6k` to confirm context
3. Run `br dep tree flywheel-c7t6k` to see dependencies
4. Apply socraticode K>=10 if non-trivial code claim involved
5. Reserve any shared paths via L107 script before edits
6. Execute the bead acceptance criteria
7. Run verification and dispatch-template audit when this packet is the artifact
8. `br close flywheel-c7t6k` (BEFORE callback per L120)
9. Send DONE callback per CALLBACK CONTRACT above

## METADATA

```text
schema_version=dispatch-packet.v1
packet_built_by=build-dispatch-packet.sh@0.3.2
packet_built_at=2026-05-20T21:30:38Z
ntm_context_source=context build --json
ntm_template_source=template show marching_orders --body --json
```

## MEMORY HITS

5 relevant memory entries found by `mem memory search "DISPATCH PACKET canonical class none adjacent bead_missing_from_local_db"`:

- `project_vrtx_session_2026_04_29_k16_restructure.md` (-Users-josh-Developer-vrtx, project) - Component library built (typst shadcn-aesthetic), K.14 9-commit scope+voice pass landed clean, Joshua surfaced structural feedback (truth...
- `feedback_canonical_scope_doctrine_2026_04_29.md` (-Users-josh-Developer-vrtx, feedback) - For any signed engagement, paste the deal-closing email VERBATIM into a docs/SIGNED-SCOPE-<source>-<date>.md file marked canonical, point...
- `project_vrtx_session_2026_04_29_peel_report_build.md` (-Users-josh-Developer-vrtx, project) - Massive plan-space accretion (K.7→K.11 reaped, K.12 in flight); peel-report Pages 1-6 reframed; questionnaire 31→41; architecture diagram...
- `project_vrtx_teams_bot_activation_2026_05_18.md` (-Users-josh-Developer-vrtx, project) - VRTX OS Teams app moved from \"Invalid Bot\" rejection to fully installed by creating Azure Bot resource + enabling Teams channel via ARM...
- `project_vrtx_session_2026_04_29_trauma_recovery.md` (-Users-josh-Developer-vrtx, project) - Strike-2 of e5c939d-class no-op heartbeat trauma. Caught and recovered via petal-1 reframe. Voice.yaml ParserError fixed at canonical, La...

(Logged 5 reads via mem memory telemetry. Run `mem memory why <FILE>` for context on any entry.)

## SKILL AUTO-ROUTES

skill_auto_routes=4
skill_auto_routes_task_id=flywheel-c7t6k-b0b53d
skill_auto_routes_catalog=canonical-cli-scoping,rust-best-practices,python-best-practices,readme-writing
skill_auto_routes_matched=canonical-cli-scoping,rust-best-practices,python-best-practices,readme-writing
skill_auto_routes_addressed=canonical-cli-scoping=n/a,rust-best-practices=n/a,python-best-practices=n/a,readme-writing=n/a

Worker callback MUST include `skill_auto_routes_addressed=` with each catalog skill set to `yes`, `no`, or `n/a`, plus file:line evidence or a re-runnable command for every non-`n/a` route.

### canonical-cli-scoping
source=/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md:324
triggered_by=\bCLI\b, \bcommand\b, --[A-Za-z0-9][A-Za-z0-9_-]*
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
l_rule_hints_task_id=flywheel-c7t6k-b0b53d
l_rule_hints_source=/Users/josh/Developer/flywheel/.flywheel/rules
l_rule_hints_matched=L107,L112,L107

Relevant canonical doctrine hints for this dispatch. Treat these as pointers, not new acceptance gates.

### L107 — Every orchestrator heartbeat tick MUST start with an inbox check (0th step) b...
source=/Users/josh/Developer/flywheel/.flywheel/rules/L107-L156-inbox-discipline-0th-probe.md
score=184
why=L107,check,context,fleet,heartbeat,orchestrator

### L112 — Skill creation requires SkillOS handoff
source=/Users/josh/Developer/flywheel/.flywheel/rules/L112-L171-skill-creation-requires-skillos-handoff.md
score=153
why=L112,explicitly,fleet,requires,skill,skillos

### L107 — SHARED-SURFACE-WRITES-MUST-RESERVE-ACROSS-PANES
source=/Users/josh/Developer/flywheel/.flywheel/rules/L061-L107-shared-surface-writes-must-reserve-across-panes.md
score=132
why=L107,across,fleet,include,readme,receipt
