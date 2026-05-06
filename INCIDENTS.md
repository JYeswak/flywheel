# Flywheel Incidents

Promoted trauma classes from `~/.local/state/flywheel/fuckup-log.jsonl`.

## Wired canonical-cli-at-dispatch as pre-dispatch validator (2026-05-05)

Date: 2026-05-05

Promotion Action: NEW

Class: `canonical-cli-at-dispatch`

Event Count: 1 structural gate promotion

Severity: high

Cost: The canonical CLI dispatch rule already existed as a forever-rule under
`cli-spec-without-canonical-cli-scoping-gate`, but it still depended on the
orchestrator remembering to paste the acceptance criteria into each CLI
dispatch. Under dispatch pressure that advisory rule can decay, letting a new
script, flag, or subcommand reach workers without `--info|--help|--examples`,
`--json`, stable exit codes, and an explicit
`canonical-cli-scoping` skill citation.

Root Cause: `/flywheel:dispatch` had mission-anchor and two-truth pre-send
validators, but no sibling structural gate for canonical CLI acceptance. The
stock at risk was CLI-surface drift; the missing flow was pre-send packet
validation before Joshua-visible or worker-visible dispatch.

Forever-Rule: Any dispatch packet that introduces a CLI surface must pass the
canonical CLI precheck before send. If the packet mentions a repo script path,
CLI/command/flag/subcommand surface, or proposed `--info|--help|--examples` /
`--json` shape, it must include all four acceptance elements: self-documenting
flags, JSON output, stable exit-code semantics, and an explicit
`canonical-cli-scoping` skill citation. Missing elements refuse dispatch with
`dispatch_packet_missing_canonical_cli_acceptance`; malformed packets fail open
with a ledgered warning.

Fix Applied/Status: `flywheel-wire-canonical-cli-at-dispatc-cdcb` added
`.flywheel/scripts/dispatch-canonical-cli-validator.sh`, wrapper
`~/.claude/commands/flywheel/_shared/dispatch-canonical-cli-precheck.sh`,
`.flywheel/validation-schema/v1/dispatch-canonical-cli-decision.schema.json`,
and `.flywheel/tests/test-dispatch-canonical-cli-validator.sh`. The dispatch
command now has additive Step 3b between wrapping and send.

Recurrence Prevention: This is Donella #5 rules as a sibling pre-dispatch
validator, plus #6 information flow through the append-only ledger
`~/.local/state/flywheel/dispatch-canonical-cli-validator-ledger.jsonl`.

Evidence:
- Bead: `flywheel-wire-canonical-cli-at-dispatc-cdcb`.
- Prior incident: `cli-spec-without-canonical-cli-scoping-gate`.
- Skill: `~/.claude/skills/canonical-cli-scoping/SKILL.md`.
- Validator: `.flywheel/scripts/dispatch-canonical-cli-validator.sh`.
- Wrapper: `~/.claude/commands/flywheel/_shared/dispatch-canonical-cli-precheck.sh`.
- Schema: `.flywheel/validation-schema/v1/dispatch-canonical-cli-decision.schema.json`.
- Test: `.flywheel/tests/test-dispatch-canonical-cli-validator.sh`.

## Wired dispatch-delivery-validation as post-send gate (2026-05-05)

Date: 2026-05-05

Class: `dispatch-delivery-validation-gap`

Event Count: 1 structural gate promotion

Severity: high

Cost: `ntm send` success is a transport acknowledgement, not proof that a
worker pane visibly received the dispatch. Without a post-send structural gate,
the orchestrator can log a task as in-flight while the prompt is missing,
queued, or only reflected in a side substrate. This repeats the CASS FTS5
false-positive precedent where dispatch intent existed but delivery evidence
was not a pane-visible receipt.

Root Cause: `/flywheel:dispatch` had a transport gate before send and callback
validation at close, but no sibling post-send gate between them. The control
loop trusted the act of sending instead of observing the target pane buffer for
the specific `task_id`.

Fix Applied/Status: Added
`.flywheel/scripts/dispatch-delivery-verify.sh`,
`~/.claude/commands/flywheel/_shared/dispatch-delivery-postcheck.sh`,
`.flywheel/validation-schema/v1/dispatch-delivery-verify.schema.json`, and
`.flywheel/tests/test-dispatch-delivery-verify.sh`. The dispatch command now
has additive Step 5b after `ntm send` and before dispatch-log in-flight
logging. Verification polls `ntm --robot-tail`, requires the `task_id` in the
target pane buffer, appends
`~/.local/state/flywheel/dispatch-delivery-verify-ledger.jsonl`, and fails
closed on timeout, pane unhealthy, capture failure, or invalid capture JSON.

Recurrence Prevention: Dispatch delivery now follows the same sibling shape as
transport-gate and close-validator: pre-send transport rule, post-send pane
visibility proof, then close-time callback validation. Donella leverage point
#6 (information flows) is moved upstream of Joshua eyeballs by making prompt
visibility a machine-readable receipt rather than a human inference.

Evidence:
- Bead: `flywheel-wire-dispatch-delivery-valida-f29a`
- Verifier: `.flywheel/scripts/dispatch-delivery-verify.sh`
- Test: `.flywheel/tests/test-dispatch-delivery-verify.sh`
- Schema: `.flywheel/validation-schema/v1/dispatch-delivery-verify.schema.json`
- Dispatch wrapper: `~/.claude/commands/flywheel/_shared/dispatch-delivery-postcheck.sh`
- Dispatch surface: `~/.claude/commands/flywheel/dispatch.md` Step 5b

## br-db wedge repair — JSONL-fallback eliminated on close (2026-05-05)

Date: 2026-05-05

Class: `br-db-wedge`

Event Count: recurring during Phase 2 EXECUTION cycle

Severity: high

Symptoms: Every close paid the `bead_db_writes=2_jsonl_fallback_br_db_malformed`
tax. Recent affected beads included `flywheel-2h3vs` and `flywheel-p2-11`.

Root Cause: The live `.beads/beads.db` had page-class B-tree corruption on
pages 3364-3372 plus index count mismatches. The live WAL was also zero bytes,
so `br` reported WAL rebuild errors until sidecars were moved aside. JSONL
fallback rows preserved work, but some fallback rows used string priorities
like `"p0"` and one close fallback appended a duplicate id row, so direct import
required temporary normalization rather than editing `.beads/issues.jsonl`.

Fix Applied/Status: Rebuilt `.beads/beads.db` from the current JSONL truth via
a temporary normalized import, ran `VACUUM` and `REINDEX`, marked metadata to
the current raw JSONL hash, and moved stale WAL/SHM sidecars aside with
timestamped forensic names. Probe and test landed at
`.flywheel/scripts/verify-br-db-close-path-active.sh` and
`.flywheel/tests/test-br-db-close-path.sh`. Task bead: `flywheel-e8lft`.

Recurrence Prevention: `verify-br-db-close-path-active.sh` performs a DB-only
create-close-show round trip with `--no-auto-flush` and confirms JSONL hash and
logical issue count are unchanged. The test covers integrity, quick check,
schema introspection, round trip, logical JSONL/DB count parity, and recovery
dry-run idempotency. Doctor/fuckup-log should route future `br-db-wedge` rows
to this probe before allowing JSONL fallback to become permanent substrate.

Evidence:
- Diagnosis: `/tmp/br-db-wedge-diagnosis-2026-05-05.md`
- Family snapshot: `/tmp/br-db-wedge-family-snapshot-2026-05-05/`
- Probe: `.flywheel/scripts/verify-br-db-close-path-active.sh`
- Test: `.flywheel/tests/test-br-db-close-path.sh`
- Bead: `flywheel-e8lft`

## corpus-dispatches-must-include-consumability-gate

Date: 2026-05-04

Class: `dispatch-acceptance-gate-incomplete-corpus`

Event Count: 1 structural event

Severity: high

Cost: Jeff corpus clone work consumed 5h+ and produced 177 repos on disk, but
the original "clone + index for watchtower" mission was not consumable until a
follow-up P0 indexed the corpus into Socraticode. Without semantic index proof,
watchtower and issue-triage agents still had to grep/read manually.

Root Cause: The dispatch acceptance gates stopped at data acquisition and did
not require the downstream consumption substrate to prove searchability,
progress receipts, storage impact, and smoke-query results.

Forever-Rule: Any corpus, mirror, or bulk-ingest dispatch must include a
consumability gate in the same bead: indexed/searchable substrate proof,
per-source progress ledger, cross-corpus smoke query, storage impact snapshot,
and downstream consumer wiring. "Cloned" is not "usable."

Fix Applied/Status: `flywheel-wtdd` indexed 177/177 repos under
`/Users/josh/Developer/jeff-corpus/*` with progress rows in
`/Users/josh/Developer/jeff-corpus/.socraticode-progress.jsonl`; Socraticode
project listing reports 177 paths with the jeff-corpus prefix, and smoke search
against `/Users/josh/Developer/jeff-corpus` returns results from multiple
corpus repos.

Evidence:
- Bead: `flywheel-wtdd`
- Progress ledger: `/Users/josh/Developer/jeff-corpus/.socraticode-progress.jsonl`
- Aggregate corpus path: `/Users/josh/Developer/jeff-corpus`
- Downstream watchtower note:
  `~/.claude/skills/info-source-watchtower/references/INSTANCES.md`

## Codex CLI 0.125.0 kitty-keyboard+tmux Enter drop (#12645) -- 5+ strikes 2026-05-03

Date: 2026-05-03

Class: `frozen-codex-spinner-misclassified-as-thinking`

Event Count: 5+ strikes in one day

Severity: high

Cost: About 30 minutes lost plus Joshua frustration from repeated pane freezes
that looked like active Codex work but did not accept input.

Root Cause: Codex CLI panes can present a prompt/working state while the TUI no
longer accepts Enter after a turn. The local signature maps to upstream
`openai/codex#12645` until proven otherwise: `codex_chevron_prompt`,
`velocity=0`, and `state_since>5min` in the terminal multiplexer substrate.

Forever-Rule: When a Codex pane shows `codex_chevron_prompt + velocity=0 +
state_since>5min in tmux` with no queued input buffer evidence, it is #12645;
recovery is Ctrl-C-relaunch through frozen-pane-detector v2, NOT bare-Enter.
When scrollback shows a current `› <text>` queued prompt after the Codex
Working timer and robot activity reports WAITING / `codex_waiting_background`,
classify `codex_queued_not_submitted` separately and recover with bare Enter via
`ntm send <session> --pane=<N> ""`; this is the skillos:1 17:15Z reproducer.

Fix Applied/Status: `codex-cli-tracker` skill and watchtower daily ingest landed
under bead `flywheel-ezyf`. Tick Step 4t now reads Codex watchtower status and
cross-references frozen-pane-detector v2 strike counters. Detector v2 landed in
commit `e493cca` under bead `flywheel-mugq`; earlier detector work is bead
`flywheel-3pko`.

Evidence:
- Upstream: `https://github.com/openai/codex/issues/12645`
- Skill: `~/.claude/skills/codex-cli-tracker/`
- Recovery primitive: `/Users/josh/Developer/flywheel/.flywheel/scripts/frozen-pane-detector.sh`
- Upstream comment log: `~/.claude/skills/codex-cli-tracker/references/UPSTREAM-COMMENTS.md`
- Beads: `flywheel-ezyf`, `flywheel-3pko`, `flywheel-mugq`

## br dep add OpenRead after JSONL rebuild

Date: 2026-05-04

Class: `br-dep-add-fails-after-jsonl-rebuild`

Event Count: 2 same-day instances: v2a1/flywheel Beads DB corruption and the
skillos `root page 184 -> root page 121` post-rebuild `br dep add` failure.

Severity: high

Cost: Optional dependency graph work had to be skipped in skillos, and v2a1
Beads repair required backed-up Workaround D rebuilds plus follow-up evidence
work before implementation beads could proceed.

Root Cause: The fleet was still running installed `br 0.1.20` after upstream
`beads_rust#270` had landed the WAL/checkpoint fix in `br 0.2.4`. Fresh JSONL
import restored `PRAGMA integrity_check=ok`, but the old binary could still
fail the first blocking `dep add` with `OpenRead root page 121`.

Forever-Rule: When fresh JSONL rebuild restores Beads integrity but the next
`br dep add` fails with an `OpenRead root page`, apply L93 before filing
upstream: mine indexed Jeff sources, rank 5+ workarounds, copy-test the top two,
and prefer the newest upstream `br` plus a reversible fallback before a new
issue.

Fix Applied/Status: New upstream issue was deferred because the exact skillos
edge passed on disposable `br 0.2.4`. A second fallback, direct SQL dependency
insert followed by `br sync --flush-only` and `br sync --import-only --rebuild
--force`, also passed copy-test. Fleet residual risk is version drift: panes
using installed `br 0.1.20` can still reproduce the old failure.

Evidence:
- L93 receipt: `/tmp/beads-rust-dep-add-corruption-jeff-issue-output.md`
- Exact failing fixture: `/tmp/beads-rust-dep-add-exact-edge-20260504T142440Z`
- Workaround tests: `/tmp/beads-rust-dep-add-workaround-tests-20260504T142516Z`
- `br 0.2.4` pass fixture: `/tmp/beads-rust-dep-add-v024-test-20260504T142741Z`
- skillos fuckup row: `/tmp/skillos-br-dep-openread-fuckup-2019.json`
- v2a1 repair receipt: `/tmp/v2a1-workaround-d-apply-output.md`
- Upstream: `https://github.com/Dicklesworthstone/beads_rust/issues/270`

## autoloop-skip-instead-of-fix

Date: 2026-05-01

Event Count: 1 structural event

Cost: Entire fleet remained effectively stuck at 1/6 ready, producing a monoculture on `alpsinsurance` while failing repos were skipped instead of diagnosed.

Root Cause: The negative-cache design treated repeated doctor failures as a reason to cool down repos. That inverted the flywheel loop: failures should create bounded repair work before any skip/cooldown path.

Forever-Rule: Loops diagnose and repair. Never skip a failing repo without first attempting bounded, idempotent repair. Negative cache is a last resort after repair fails, not a first response.

Fix Applied/Status: Bead 1, `autoloop-diagnose-repair`, rewrites autoloop behavior toward diagnose-then-repair before cache/skip decisions.

Evidence: `~/.local/state/flywheel/fuckup-log.jsonl#L57`.

## agent-fighting-gate

Date: 2026-05-01

Promotion Action: UPDATE

Class: `agent-fighting-gate`

Event Count: 5 events (as of 2026-05-01)

Severity: high

Cost: 5 repeat-retry events show agents still fight gate denials instead of changing command shape; line evidence includes 2, 7, 12, and 6 repeat counts around the same denial classes.

Root Cause: Agents treated hook denials as transient execution failures. They retried denied commands or equivalent command shapes instead of parsing the denial, reducing scope, or switching to the canonical transport/recovery path.

Forever-Rule: After one gate denial, parse the reason and change strategy before retrying. After two denials on the same class, stop and report the gate name, exact command shape, denial reason, and proposed repair. Never retry a denied command verbatim.

Fix Applied/Status: UPDATE draft from fuckup-log triage. Existing incident refreshed with current event count, line evidence, and a stricter two-denial stop rule.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L34`: readiness gate denied the same dispatch prompt twice.
- `~/.local/state/flywheel/fuckup-log.jsonl#L35`: dispatch transport gate denied the same canonical send shape twice because payload text included forbidden examples.
- `~/.local/state/flywheel/fuckup-log.jsonl#L36`: dispatch transport gate denied `ntm assign --auto --watch picoz` seven times.
- `~/.local/state/flywheel/fuckup-log.jsonl#L37-L38`: two additional high-severity repeat-denial clusters.

## repeat-gate-deny-dispatch_transport

Date: 2026-05-01

Promotion Action: UPDATE

Class: `repeat-gate-deny-dispatch_transport`

Event Count: 25 events (as of 2026-05-01)

Severity: low operational noise, high recurrence

Cost: 25 denials accumulated around the same transport class, repeatedly interrupting worker sends and gate validation instead of producing one bounded repair loop.

Root Cause: The dispatch transport gate matched forbidden transport tokens too broadly. It correctly caught raw dispatch attempts, but also matched compound commands and quoted payload text that merely described forbidden examples.

Forever-Rule: Dispatch transport enforcement must parse command segments and only deny raw pane-dispatch actions in the segment that performs dispatch. Canonical `ntm send` must be allowed even when the payload mentions forbidden examples.

Fix Applied/Status: UPDATE draft from fuckup-log triage. Existing incident refreshed to separate true-positive raw dispatch blocks from false-positive quoted-payload and compound-command blocks.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L5`: raw transport send pattern denied in a compound command.
- `~/.local/state/flywheel/fuckup-log.jsonl#L6`: gate triggered while command text was updating tick JSON before dispatch context.
- `~/.local/state/flywheel/fuckup-log.jsonl#L7`: compound command mixed control-mode cancel with canonical `ntm send` and was denied.
- `~/.local/state/flywheel/fuckup-log.jsonl#L8-L33`: 22 additional same-class dispatch transport denials.

## orchestrator-idle-with-actionable-work

Date: 2026-05-01

Promotion Action: UPDATE

Class: `orchestrator-idle-with-actionable-work`

Event Count: 4 events (as of 2026-05-01)

Severity: high

Cost: The loop halted or declared clean while safe work remained: 5 CI-debt beads, bead DB repair, queued deployment work, failing repos, idle panes, 7 open gaps, 2 dispatchable STATE actions, stalled WORK items, and test/bin cleanup surfaces.

Root Cause: The orchestrator treated a narrow checklist, one blocker, callback reap, or negative-cache state as permission to stop. It did not scan adjacent safe work surfaces before entering idle/clean posture.

Forever-Rule: When callbacks are available, blockers are reaped, repo health is failing, or worker panes are idle, route safe adjacent work immediately or file/update a bead. IDLE_CLEAN is only valid after GAPS-LIVE.md, WORK.md, STATE.md, tests, bin hygiene, templates, and known repo-health surfaces have been scanned and no agent-executable work exists.

Fix Applied/Status: UPDATE draft from fuckup-log triage. This broadens the existing `orch-idle-with-dispatchable-work` incident into the normalized class `orchestrator-idle-with-actionable-work`.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L45`: Wave-4 halted repeatedly on single-bead blockers despite adjacent OCP-eligible work.
- `~/.local/state/flywheel/fuckup-log.jsonl#L57`: negative cache skipped failing repos instead of diagnosing and repairing doctor failures.
- `~/.local/state/flywheel/fuckup-log.jsonl#L59`: ALPS callback reap left an idle worker waiting for the next 30-minute tick.
- `~/.local/state/flywheel/fuckup-log.jsonl#L64`: doctrine tick ran 20+ IDLE_CLEAN ticks with idle workers and open work surfaces.

## repeat-gate-deny-readiness

Date: 2026-05-01

Promotion Action: NEW

Class: `repeat-gate-deny-readiness`

Event Count: 4 events (as of 2026-05-01)

Severity: medium

Cost: 4 readiness denial events created retry churn across `polymarket-pico-z`, `flywheel`, and `zeststream-procurement` where a targeted repair receipt would have been cheaper.

Root Cause: Readiness gates denied repeated attempts, but the loop did not convert the denial into bounded recovery, a repair checklist, or dispatchable follow-up work.

Forever-Rule: A readiness gate denial must produce a bounded recovery attempt after the first denial. Three readiness denials in one class halt retries and route to a repair/checklist update before more execution attempts.

Fix Applied/Status: NEW draft from fuckup-log triage. Candidate for a gate recovery receipt/checklist rule.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L14`: readiness denied a known-bad dispatch prompt pattern.
- `~/.local/state/flywheel/fuckup-log.jsonl#L29`: readiness denied 5 commands in 14 minutes for `polymarket-pico-z`.
- `~/.local/state/flywheel/fuckup-log.jsonl#L31`: readiness denied 4 commands in 42 minutes for `flywheel`.
- `~/.local/state/flywheel/fuckup-log.jsonl#L32`: readiness denied 3 commands in 1 minute for `zeststream-procurement`.

## credential-substrate-truth-drift

Date: 2026-05-01

Promotion Action: NEW

Class: `credential-substrate-truth-drift`

Event Count: 4 events (as of 2026-05-01)

Severity: high

Cost: 4 medium/high ALPS/Railway/Infisical events kept work blocked on stale assumptions, including roughly 1 hour of human-latency idle and 3 wasted worker dispatches on a stale Infisical project ID.

Root Cause: Workers trusted stale documentation, guessed substrate discriminators, or used older shared credentials without enumerating live substrate truth and freshness before declaring a credential wall.

Forever-Rule: Before declaring a credential or substrate blocker, enumerate live substrate truth, compare freshness and project/service identity across available stores, and record provenance in the callback or closeout. Guessed environment names and stale documented IDs are not authoritative until live enumeration confirms them.

Fix Applied/Status: NEW draft from fuckup-log triage. Candidate to reinforce L48 substrate-exhaustion behavior with concrete credential freshness checks.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L42`: worker spent hours probing a stale ALPS Infisical project ID from documentation.
- `~/.local/state/flywheel/fuckup-log.jsonl#L43`: worker guessed `staging`/`prod` and missed the live `josh-dev` environment.
- `~/.local/state/flywheel/fuckup-log.jsonl#L44`: stale GitHub `RAILWAY_TOKEN` was trusted over a fresher Infisical token.
- `~/.local/state/flywheel/fuckup-log.jsonl#L46`: corrected Infisical enumeration found a Railway token that was not deploy-capable, requiring a deploy-capable token ask.

## orchestrator-observability-contract-bypass

Date: 2026-05-01

Promotion Action: NEW

Class: `orchestrator-observability-contract-bypass`

Event Count: 4 events (as of 2026-05-01)

Severity: medium

Cost: 4 events made worker state ambiguous or invisible, forcing orchestration to infer progress from side effects instead of durable pane state, dispatch logs, and callbacks.

Root Cause: Multi-agent work bypassed the visible NTM/callback contract through hidden agent forks, missing callback instructions, and incorrect interpretation of pane process state.

Forever-Rule: Worker-like execution must run through visible NTM pane dispatch with explicit callback instructions and pane-state verification. Hidden background forks require a recorded callback path before work starts. Pane `current_command` alone is not proof of active work.

Fix Applied/Status: NEW draft from fuckup-log triage. Candidate for dispatch-template and pane-health enforcement.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L50`: validation sweep used hidden agent forks instead of visible pane dispatch.
- `~/.local/state/flywheel/fuckup-log.jsonl#L51`: hidden forks lost visibility through `/flywheel:tail` and bypassed dispatch-log audit trail.
- `~/.local/state/flywheel/fuckup-log.jsonl#L52`: hand-written dispatch omitted callback instructions.
- `~/.local/state/flywheel/fuckup-log.jsonl#L53`: orchestrator misreported panes as working because `node` was running, though workers were idle.

## test-data-in-fuckup-log

Date: 2026-05-01

Promotion Action: NEW

Class: `test-data-in-fuckup-log`

Event Count: 3 events (as of 2026-05-01)

Severity: low hygiene, medium signal risk

Cost: 3 synthetic rows entered production triage, consumed manual classification effort, and could have distorted promotion metrics if left unnormalized.

Root Cause: Smoke/evidence tests wrote synthetic rows into the production fuckup log instead of an isolated temp file or fixture.

Forever-Rule: Tests for fuckup logging must write to isolated temp files or explicit fixtures. No test may append synthetic rows to `~/.local/state/flywheel/fuckup-log.jsonl`.

Fix Applied/Status: NEW draft from fuckup-log triage. Candidate for test harness isolation checks.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L1`: synthetic `test-class` smoke row.
- `~/.local/state/flywheel/fuckup-log.jsonl#L2`: synthetic `t2` evidence row.
- `~/.local/state/flywheel/fuckup-log.jsonl#L3`: synthetic `ancient` row.

## positive-event-misrouted-to-fuckup-log

Date: 2026-05-01

Promotion Action: NEW

Class: `positive-event-misrouted-to-fuckup-log`

Event Count: 3 events (as of 2026-05-01)

Severity: low

Cost: 3 positive doctrine/mission events polluted the trauma substrate and required manual reclassification; left untreated, these rows would distort incident promotion metrics.

Root Cause: Doctrine accretions and mission-positive state changes were logged as fuckups, collapsing positive learning signals into the trauma/failure substrate.

Forever-Rule: The fuckup log is for traumas, blockers, gaps, and failures. Positive doctrine accretions belong in incident history, receipts, closeout digests, or a positive outcome substrate, not in fuckup-log rows.

Fix Applied/Status: NEW draft from fuckup-log triage. Candidate for `/flywheel:learn` routing validation.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L40`: L50 canonization logged as a low-severity fuckup row.
- `~/.local/state/flywheel/fuckup-log.jsonl#L41`: L51-L55 dispatch-envelope canonization logged as a fuckup row.
- `~/.local/state/flywheel/fuckup-log.jsonl#L48`: skillos MISSION lock and positive design decisions logged as a fuckup row.

## skill-substrate-validation-drift

Date: 2026-05-01

Promotion Action: NEW

Class: `skill-substrate-validation-drift`

Event Count: 3 events (as of 2026-05-01)

Severity: medium

Cost: 3 validation events exposed 182 stale indexed chunk hashes, case-insensitive path false positives, and 164 invalid `SKILL.md` frontmatters that produced YAML parse errors in Codex panes.

Root Cause: Skill validation relied on incomplete substrate checks: macOS case-insensitive existence checks, catalog counts without payload hash freshness, and frontmatter parsing that allowed invalid YAML to persist downstream.

Forever-Rule: Skill validation must verify exact-case path identity, content hash freshness, and YAML/frontmatter parseability at the substrate boundary before indexing, publishing, or claiming catalog health.

Fix Applied/Status: NEW draft from fuckup-log triage. Likely skillos-owned follow-up for catalog/index validation hardening.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L61`: case-normalized audits on macOS APFS falsely classified lowercase `skill.md` as uppercase `SKILL.md`.
- `~/.local/state/flywheel/fuckup-log.jsonl#L63`: Qdrant payload SHA drift affected 182 of 422 skill files despite zero count drift.
- `~/.local/state/flywheel/fuckup-log.jsonl#L66`: 164 skill files had frontmatter descriptions that produced YAML mapping parse errors.

## meat-puppet-orchestrator-decision-on-partial-state

Date: 2026-05-01

Promotion Action: NEW (cluster of 5 sub-classes)

Class: `meat-puppet-orchestrator-decision-on-partial-state`

Event Count: 5 events (as of 2026-05-01) across 5 sub-classes:
- `use-data-not-meat-puppet` (n=2, max=high) — direct violation of L66
- `stdout-truncation-misread-led-to-false-completion` (n=1, medium)
- `ledger-write-without-reading-current-state` (n=1, medium)
- `meat-puppet-pane-state-misread` (n=1, medium)
- `tmux-capture-bypasses-ntm-health` (n=1, medium)

Severity: high (max across cluster)

Cost: Multiple false-completion claims this session — orchestrator reported "L48 sent" when 13 of 17 had already shipped; orchestrator added 16 false handshake-ack rows on top of real sends; orchestrator misread tmux pane mid-tool-call output as "idle" via `ntm health` while tmux capture showed Working state. Each misread triggered a wrong dispatch decision that Joshua had to manually correct, costing 3+ dispatch cycles and one cluster of duplicated state rows requiring filter cleanup.

Root Cause: Orchestrator reads first available state surface (stdout tail, single ntm health snapshot, ledger length without diff) and acts on it without cross-checking. The substrate has multiple truth sources (`ntm health` + `tmux capture-pane` + dispatch-log + topology file + actual file mtimes); decisions made on a single surface are guesses dressed as data.

Forever-Rule: BEFORE any dispatch, refill, ledger-append, or callback-reap decision: cross-check at least TWO truth sources. If they disagree, READ the disagreement aloud in the receipt and trust the more-conservative source. Specific gates:
- Pane state: `ntm health` AND `tmux capture-pane` last 30 lines — disagreement is a SOFT violation, not a tiebreaker.
- Ledger appends: `tail -1 <ledger>` BEFORE write to confirm current state, never blind append.
- Output completion: `test -e <expected_output>` AND read first/last 5 lines, not stdout tail of the spawning command.
- Dispatch decisions: callback file on disk OR explicit Callback message in this session — never both inferred from prose summary.

Fix Applied/Status: NEW. Reinforces L66 (USE-DATA-NOT-MEAT-PUPPET) with concrete gate procedures. Candidate for L66 sub-rules promotion at next AGENTS.md edit window.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L94-L95`: two use-data-not-meat-puppet strikes processed into this incident.
- `~/.local/state/flywheel/fuckup-log.jsonl#L115`: pane-state misread event processed into this incident.
- `~/.local/state/flywheel/fuckup-log.jsonl#L121-L122`: stdout truncation and ledger write events processed into this incident.
- This session: orchestrator misread tmux capture as "ntm health says idle" then dispatched against active workers — corrected after Joshua flagged
- This session: orchestrator wrote partial 04-SYNTHESIS.md before all 3 lanes shipped — caught + corrected by holding pending slots open per L66

## bypass-canonical-substrate-cluster

Date: 2026-05-01

Promotion Action: NEW (cluster of 3 sub-classes)

Class: `bypass-canonical-substrate-cluster`

Event Count: 3 events (as of 2026-05-01):
- `dispatch-bypasses-flywheel-dispatch-skill` (n=1, high)
- `tmux-capture-bypasses-ntm-health` (n=1, medium)
- `callback-pane-wrong-no-topology-read` (n=1, high)

Severity: high (max across cluster)

Cost: Three different paths around canonical substrate this session. Each bypass costs a wrong-pane delivery, a stale state read, or a dispatch outside the gate-protected transport. Pattern crystallized over a single session — high-tempo work increases bypass temptation, and L48 (substrate-exhaustion-before-escalation) is most violated when the orchestrator is moving fast.

Root Cause: Canonical substrates (`/flywheel:dispatch` skill, `ntm health`, `session-topology.jsonl`) have higher ceremony than ad-hoc bash commands. When orchestrator is in flow, it reaches for `tmux capture-pane`, hardcoded `--pane=N`, or raw `ntm send` without the dispatch-template wrapper. Each one works individually; collectively they erase the substrate's value because the substrate only protects the path it owns.

Forever-Rule: Every dispatch action transits the canonical surface. NO ad-hoc shortcuts during high-tempo work. Specifically:
- Dispatch ALWAYS through `/flywheel:dispatch` skill OR equivalent template that includes dispatch-log.jsonl entry + callback contract + topology lookup.
- Pane state ALWAYS via `ntm health` (primary). `tmux capture-pane` is supplementary truth, not substitute.
- Callback target ALWAYS resolved via `session-topology.jsonl` — never hardcode `--pane=1`.
- If a substrate has a learning curve, the answer is to invest in the curve once, not bypass per-task.

Fix Applied/Status: NEW. Reinforces L48 + L66 + L67. Concrete gates added to `/flywheel:dispatch` and `/flywheel:tick` skill bodies during this session. Candidate for canonical promotion if cluster recurs.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl` rows for the 3 classes (all 2026-05-01)
- `/Users/josh/Developer/flywheel/AGENTS.md` L66/L67/L68 already encode the meta-pattern; these are the operational sub-rules

## cli-spec-without-canonical-cli-scoping-gate

Date: 2026-05-01

Promotion Action: NEW

Class: `cli-spec-without-canonical-cli-scoping-gate`

Event Count: 1 event (mid-flight injection on xpane_cli pane 3, 2026-05-01)

Severity: medium (caught in flight; would have been high if shipped)

Cost: Lane 2 of cross-pane-protocol planning was dispatched to pane 3 with an 8-command spec for `flywheel-readme`. Joshua then declared canonical-cli-scoping is the standard for all CLI surfaces. Audit of original packet revealed: NO doctor/health/repair triad, NO --info/--examples/quickstart/help <topic>/completion, NO validate/audit/why subsidiary, custom non-canonical exit code map (1/2/3/4/5/6/64/70 instead of canonical universal 0/1/2/3/4/5+), NO --dry-run/--explain/--idempotency-key on mutating commands, NO schema emission, NO metrics/logs/trace observability. Mid-flight overlay packet `/tmp/dispatch_xpane_cli_OVERLAY_canonical.md` injected to pane 3 to integrate canonical before final write. If shipped without overlay, the resulting CLI would have failed `~/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh` and required full rewrite at v0.2 — a multi-hour redo cost.

Root Cause: Dispatch packet author (orchestrator) treated CLI design as ad-hoc spec rather than as an instance of the canonical-cli-scoping standard. The skill exists in the catalog (`~/.claude/skills/canonical-cli-scoping/`) but was not consulted at dispatch time. The CLI's specific domain (cross-pane README review) felt distinct enough to spec from scratch, ignoring that EVERY CLI Joshua ships follows the standard.

Forever-Rule: Any CLI/command/flag/subcommand dispatch MUST cite `~/.claude/skills/canonical-cli-scoping/SKILL.md` and embed its Implementation Checklist as the bead acceptance gate AT DISPATCH TIME, not after callback. Specifically:
- If the dispatch task body contains the words "CLI", "command", "flag", "subcommand", or names a binary file → orchestrator MUST embed the canonical Implementation Checklist verbatim in the dispatch packet.
- Worker callback MUST report PASS/FAIL for every gate in the checklist.
- Dispatch packets that fail this pre-flight check are themselves a SOFT violation `dispatch_missing_canonical_gate` — orchestrator self-reports.

Fix Applied/Status: Mid-flight overlay packet shipped to pane 3 (xpane_cli_OVERLAY_canonical.md). All future CLI dispatches gated. Filed: flywheel-1wd (memory entry pinning the rule), flywheel-jbe (wire canonical into flywheel-loop init template), flywheel-ntf (epic for fleet-wide canonical compliance).

Evidence:
- `/tmp/dispatch_xpane_cli.md` (original Lane 2 packet, missing canonical) vs `/tmp/dispatch_xpane_cli_OVERLAY_canonical.md` (correction)
- `~/.claude/skills/canonical-cli-scoping/SKILL.md` (the standard)
- `~/Developer/flywheel/.flywheel/dispatch-log.jsonl` row `task_id=xpane_cli_OVERLAY` (the correction event)

## jeff-watcher-false-positive-on-gh-auth-fail

Date: 2026-05-02

Promotion Action: NEW (N=3 in 2 minutes, threshold met)

Class: `jeff-watcher-false-positive-on-gh-auth-fail`

Event Count: 3 events (2026-05-02T01:26:45Z..01:29:10Z) all triggered by single root cause within ~2 min window.

Severity: medium per event; cumulative noise spiral elevates to substrate-rot risk if unfixed.

Cost: Each false-positive interrupts orchestrator focus and forces verification round-trip (~30s human attention + 1 unauthed REST verification call). Cried-wolf pattern depletes attention budget for real Jeff responses; in this case a real ntm#111 confirmation from Jeff at 17:26Z would have been mis-prioritized against future false alerts. 3 watchers polling 3 issues × N polls/hour means continuous noise until token fixed.

Root Cause: GITHUB_TOKEN env var invalid (40 chars, gh rejects with HTTP 401). Watchers built on `gh issue view` or `gh api` cannot distinguish "state changed" from "auth/network failure" — both produce UNKNOWN return state. Watchers fire `state changed: <X> -> UNKNOWN` notifications without sanity-checking whether UNKNOWN is the result of a successful poll (real change) vs a failed poll (auth/network).

Forever-Rule: Watchers polling external APIs MUST distinguish 3 states, not 2:
1. **CONFIRMED CHANGED** — successful poll, content differs from prior poll
2. **CONFIRMED UNCHANGED** — successful poll, content matches prior
3. **UNKNOWN/UNHEALTHY** — poll failed (HTTP 4xx/5xx, network error, timeout, parse error)

State 3 must NOT fire `state_changed` notifications. It must fire `watcher_unhealthy` notifications, with auto-suppress of duplicate state-3 alerts within a 1-hour window. Watchers must include a self-health check (e.g. `gh auth status` returns 0) before each poll.

Trigger condition: any watcher script that wraps `gh` and emits notifications without distinguishing API-success from API-error.

Fix Applied/Status: 3 fuckup-log rows captured (01:26:45, 01:27:33, 01:29:10). Permanent fix needs (a) refresh GITHUB_TOKEN via Infisical/keyring OR `unset GITHUB_TOKEN` to fall back to keyring auth, (b) patch watcher to detect HTTP 401/403 and switch to UNHEALTHY notification class.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L159-L160`: first two jeff-watcher false-positive auth-fail rows.
- `~/.local/state/flywheel/fuckup-log.jsonl#L162`: third jeff-watcher false-positive auth-fail row.
- `gh auth status` shows `GITHUB_TOKEN` is invalid, keyring auth still valid but inactive
- `curl https://api.github.com/repos/Dicklesworthstone/ntm/issues/111` (unauthed) returns state=open, comments=1, no change since 17:26:54Z

## orchestrator-substrate-blindness

Date: 2026-05-02

Promotion Action: NEW META-CLASS (consolidates 3 distinct events from this conversation into single pattern)

Class: `orchestrator-substrate-blindness`

Event Count: 3 events in 18 minutes
1. `orchestrator-checked-wrong-project-path` (01:32:42Z) — alps Desktop vs Developer path mismatch hid 3 active beads.db files
2. `orchestrator-built-research-on-wrong-substrate-assumption` (01:32:42Z) — dispatched 3 fleet-idle research lanes on premise "no orchestration exists" while autoloop + 6 internal-monitors + 5 watcher locks were actually running
3. Earlier in conversation: `orchestrator-tmux-scope-limited-to-current-session` (implicit) — `ntm health` from this pane only sees `flywheel` session, not the other 7

Severity: high (cost waste of ~21 worker-minutes on partially-wrong framing; ALPS bead beads-discovery was 25h+ delayed because orchestrator framed "fleet idle" as "no orchestration" when actual root was "observe-only autoloop")

Cost: ~21 worker-minutes across 3 dispatched lanes × ladder-passed but partially-wrong-framed output. Multiple dispatch packets need synthesis-pass correction. Joshua-interrupt to correct framing 3 times in single conversation.

Root Cause: Orchestrator drew "X is missing/broken" conclusions before doing breadth-first substrate inventory. Specifically failed to inspect:
- live processes (`ps aux | grep ntm`) — would have shown 6 internal-monitor procs
- launchd state (`launchctl list`) — would have shown autoloop active
- state directory (`~/.local/state/flywheel-autoloop/`) — would have shown idle-spiral-alert.json with explicit `recommendation=dispatch_work_or_teardown`
- per-session config truth source (`tmux display -t <s>:0.0 -p '#{pane_current_path}'` rather than ntm config.toml session_paths) — would have shown alps cwd

Forever-Rule: Before any "X is missing/broken" framing in a dispatch packet OR research lane prompt, orchestrator MUST run breadth-first substrate inventory and cite findings:
1. **Config files** — every `~/.config/<tool>/`, `~/.<tool>rc`, project `.toml`/`.json`
2. **State files** — every `~/.local/state/<tool>/`, `~/.<tool>/state*`
3. **Live processes** — `ps aux | grep -i <tool>` for daemons/monitors
4. **launchd plists** — `launchctl list | grep <tool>` AND `~/Library/LaunchAgents/*<tool>*`
5. **Lock files** — `~/.local/state/<tool>/*.lock`
6. **Recent jsonl writes** — files modified in last 30 min that name the system
7. **Per-tmux-session truth** — when reasoning about session N, use `tmux display -t N:0.0 -p '#{pane_current_path}'` not config.toml

If ANY produce evidence of the system being investigated, frame the dispatch as "X is partially working but has Y gap" not "X is missing".

Trigger condition: Any orchestrator dispatch whose prompt contains phrases like "no orchestration", "missing X", "X doesn't exist", "fleet idle" without first citing inventory results from at least items 1-5 above.

Fix Applied/Status: 3 fuckup-log rows captured. Mitigation underway via in-flight Lane synthesis pass that will reframe findings against actual autoloop substrate. Permanent fix is NEW SKILL: `/flywheel:substrate-inventory <system-name>` that runs the breadth-first sweep automatically; require it in `/flywheel:plan` Phase 1 dispatch packet contract.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl` rows `orchestrator-checked-wrong-project-path`, `orchestrator-built-research-on-wrong-substrate-assumption`, `orchestrator-pane-token-saturated-then-wedged` (01:32:42Z)
- `~/.local/state/flywheel-autoloop/last_run.json` (autoloop ticking, missed by orchestrator)
- `~/.local/state/flywheel-autoloop/idle-spiral-alert.json` (system was telling us 19 ticks ago what was wrong)
- `ps aux | grep ntm` returns 6 alive `internal-monitor` processes, missed by orchestrator inventory

## documented-bug-not-actioned-self-recursion

Date: 2026-05-02

Promotion Action: NEW (candidate for L-rule promotion to AGENTS.md)

Class: `documented-bug-not-actioned-self-recursion`

Event Count: 3 ALPS beads filed 2026-05-01T00:38Z–00:41Z, still OPEN at 2026-05-02T01:32Z (25h+ unactioned, ALPS in idle-spiral 19 ticks)
1. `josh-1eo8p` (P1, bug) — Restore ALPS worker-tick command surface for pane loop
2. `josh-1s3ie` (P1, bug) — Fix /flywheel:loop start repo-local ALPS state writes
3. `josh-35h17` (P1, bug) — ALPS session topology pane assignment mismatch

Severity: high (these beads describe the EXACT flywheel-doctrine failures preventing the autoloop from dispatching; un-dispatching them creates recursive failure where the autoloop bug prevents fixing the autoloop bug)

Cost: alpsinsurance idle-spiral 19 ticks × 10 min = ~190 minutes of client-impacting idle. Per memory rule "ALPS = canonical reference impl; its fuckups become flywheel doctrine, no idle days" — this is direct doctrine violation that should never have lasted >50 min.

Root Cause: Self-bug beads (beads describing flywheel infrastructure failures) get caught in the same logic they describe. If the autoloop tick selector fails on a particular condition, and a bead describes that exact selector failure, the autoloop will never select THAT bead because the bead's own existence requires the selector to work. Recursive failure: the selector blocks the fix to the selector.

Forever-Rule (CANDIDATE L-RULE — surface for L-rule promotion to AGENTS.md): Self-bug beads must escape normal selector logic. A self-bug bead is one whose title/description matches `/flywheel:|autoloop|loop start|worker-tick|tick fails|orchestrator|dispatch|callback|substrate/` AND `(fail|broken|missing|drift|regression|stuck)`. When such a bead is older than `[autoloop_tick_cadence × 5]` (50 min for active_normal, 60 hours for doctrine), it must be:
1. Force-promoted to a Joshua-disposes inbox (visible at next `/flywheel:status`)
2. Escape the autoloop's normal negative-cache + selection logic
3. Trigger a doctor `self_bug_recursion_count >= 1` → status=fail signal

Trigger condition: bead matches self-bug regex + status=open + age > 5×tick_cadence + last_dispatch_attempt is null OR > 5×tick_cadence ago.

Fix Applied/Status: 3 ALPS beads identified. Need Joshua-disposes triage to dispatch within next session. Permanent fix is doctor check + autoloop selector special-case for self-bug class.

Evidence:
- `/Users/josh/Developer/alpsinsurance/.beads/beads.db` rows for josh-1eo8p, josh-1s3ie, josh-35h17 (status=open, updated_at=2026-05-01T00:38..00:41Z)
- `~/.local/state/flywheel-autoloop/idle-spiral-alert.json` shows alpsinsurance consecutive_idle_clean=19 with recommendation=dispatch_work_or_teardown — system detects spiral but doesn't act on the recommendation
- Memory rule `project_alps_quintessential_member_2026_05_01.md`: "ALPS = canonical reference impl; its fuckups become flywheel doctrine, no idle days; CoralRaven=alps-orch"
- Per same memory: alps-orch CoralRaven should be the consumer of these beads but is wedged at 854.3k tokens with 💀 marker

## mission-lock-drift-no-audit-trail

Date: 2026-05-03

Promotion Action: NEW

Class: `mission-lock-drift-no-audit-trail`

Event Count: 1 structural event

Severity: medium

Cost: `flywheel-loop init --reconcile --apply` changed `MISSION.md` lock evidence, but left no comparable top-level `lock_hash` row in `.flywheel/lock-log.jsonl`. The gap stayed invisible until `flywheel-2xmq.1` shipped the `mission_lock_age` doctor probe and immediately found `lock_hash_matches_lock_log=false`.

Root Cause: Reconcile apply treated `MISSION.md` as a template migration artifact and logged nested `hash_per_file.MISSION` content evidence, not a mission-lock audit row. The file frontmatter changed from the template backfill hash to the reconcile hash without the same lock-log contract that `/flywheel:mission-lock` requires.

Forever-Rule: Any command that writes a locked `.flywheel/MISSION.md` must append a lock-log row with the exact current frontmatter `lock_hash` as a top-level field. Content hashes, diff paths, or nested hash maps are not substitutes for mission-lock audit evidence.

Fix Applied/Status: Backfilled `.flywheel/lock-log.jsonl` via `flywheel-6kna` with action `lock-log-backfill`, then appended a probe-compatible `mission-lock-log-backfill` row with `file=".flywheel/MISSION.md"`, reason `lock-log-drift-repair-via-flywheel-6kna`, and the current MISSION hash `96a94d27d0d11efe4be133d46dda4b9518df93646879e9f3c1bd83cc362277eb`.

Evidence:
- `/tmp/flywheel-2xmq.1_findings.md`: newly shipped probe reported `lock_hash_matches_lock_log=false` for flywheel while `lock_hash_matches_body=true`.
- `.flywheel/.reconcile-20260501T052023Z.diff`: reconcile changed MISSION lock hash from `b7c93e0631d4ab78fbecdf2e4298b4cdb59fc8c193c1bd8fa6261ea45e4c8e18` to `96a94d27d0d11efe4be133d46dda4b9518df93646879e9f3c1bd83cc362277eb`.
- `.flywheel/lock-log.jsonl`: line 11 recorded `action=reconcile-apply` with `hash_per_file.MISSION=53d7a80b...`, but no top-level `lock_hash` matching the current mission until the `flywheel-6kna` backfill row.

## Lacking surveillance pattern caused 6hr blackout 2026-05-03 + 5+ #12645 strikes

Date: 2026-05-03

Promotion Action: NEW

Class: `info-source-watchtower-missing`

Event Count: 1 structural event plus 5+ repeated Codex issue #12645 strikes

Severity: high

Cost: ~30 minutes lost today to repeated Codex stuck-pane recovery, plus ~6
hours earlier where the same class of source-specific upstream signal was not
converted into durable surveillance.

Root Cause: First-class information sources were treated as things to check
manually during incidents instead of as durable watchtowers with daily ingest,
state gates, strike evidence, extraction, and archive discipline. The Jeff repo
surveillance pattern existed in `dicklesworthstone-stack`, but the reusable
meta-skill did not, so new source watchtowers risked re-inventing the pattern
or omitting gates.

Forever-Rule: Any first-class info source MUST have a watchtower; otherwise
it's a discovery latency bomb.

Fix Applied/Status: `flywheel-1ndw` created
`~/.claude/skills/info-source-watchtower/` as the reusable parent meta-skill.
`flywheel-ezyf` is the first child, covering codex-watchtower for OpenAI Codex
CLI issue/release surveillance. `dicklesworthstone-stack` remains the attributed
pattern source and special-cased parent doctrine.

Evidence:
- Bead `flywheel-1ndw`: info-source-watchtower meta-skill build.
- Bead `flywheel-ezyf`: codex-watchtower first child.
- Pattern source: `~/.claude/skills/dicklesworthstone-stack/`.
- Observed Codex issue pressure: openai/codex#12645 fired 5+ times in the active
  environment on 2026-05-03.

## robot-mode-classification-disagreement

Date: 2026-05-04

Promotion Action: NEW

Class: `robot-mode-classification-disagreement`

Event Count: 1 high-severity dispatch-blocking incident plus related robot-mode
classification drift in `flywheel-3pko`.

Severity: high

Cost: A mobile-eats worker had completed implementation and validation, but the
next dispatch was blocked because `ntm --robot-activity` classified the pane as
`ERROR` while `ntm --robot-agent-health --no-caut` reported
`local_state.is_idle=true`, `health_score=100`, and `recommendation=HEALTHY`.
That disagreement stalled integration despite an available idle worker.

Root Cause: The dispatch capacity gate treated one robot-mode surface as
authoritative even when another robot-mode health surface provided stronger
idle evidence. This matched the broader robot-state drift family tracked in
`flywheel-3pko` and upstream `ntm#114`: different robot surfaces can disagree
when parser hints, cached scrollback, or error patterns are not reconciled.

Forever-Rule: Capacity gates must reconcile robot-mode surfaces before denying
dispatch. `activity=ERROR` plus `agent_health.is_idle=true` and
`recommendation=HEALTHY` is `override_available` with a warning, not a hard
block. Real `ERROR`, `STALLED`, or `UNKNOWN` states still block when the health
override is absent.

Fix Applied/Status: `flywheel-susm` implemented
`.flywheel/scripts/dispatch-capacity-gate.sh`, which returns
`override_available` for the ERROR+HEALTHY+idle disagreement case, blocks real
errors without a health override, and is wired into the tick/template dispatch
path. This entry closes the missing INCIDENTS doctrine gate for `flywheel-susm`.

Evidence:
- Bead `flywheel-susm`: parent implementation and close reason.
- Script: `.flywheel/scripts/dispatch-capacity-gate.sh`.
- Sibling/cross-link: `flywheel-3pko` (Codex queued-not-submitted / robot state
  drift family).
- Sibling/cross-link: `flywheel-snf8` (canonical-driver tick fix).
- Upstream: `ntm#114`, closed 2026-05-03T01:32Z after Jeff fixed robot parser
  hint drift.

## launchd domain predicate convention (2026-05-05)

Date: 2026-05-05

Promotion Action: NEW

Class: `launchd-domain-predicate-mismatch`

Event Count: 1 L112 close-gate mismatch

Severity: medium

Cost: `flywheel-2jvz2` was functionally shipped and the watchdog was active, but
the close gate stayed blocked because it asserted the `user/<uid>` domain while
the repo's LaunchAgent substrate is loaded and probed under `gui/<uid>`.

Root Cause: The L112 predicate encoded a domain string that did not match the
host LaunchAgent convention. The active watcher was loaded in the GUI/Aqua
launchd context; direct user-domain checks fail in this environment even when
the service is healthy.

Forever-Rule: Flywheel launchd beads that install per-user LaunchAgents should
default verification predicates to `gui/$(id -u)/<label>` unless a headless
context is explicit. Do not treat `launchctl print user/$(id -u)/<label>` as the
canonical health probe for these watchers.

Fix Applied/Status: The `flywheel-2jvz2` close predicate was amended to the GUI
domain. `.flywheel/scripts/verify-watcher-launchd-active.sh` already defaults
`WATCHER_LAUNCHD_DOMAIN` to `gui/$(id -u)`, so no verifier code change was
needed.

Evidence:
- Bead `flywheel-2jvz2`: watcher-launchd-enable close.
- Probe script: `.flywheel/scripts/verify-watcher-launchd-active.sh`.
- Verified command: `launchctl print gui/$(id -u)/ai.zeststream.codex-stuck-detector-watchdog`.
- Counterexample observed: `launchctl print user/$(id -u)/ai.zeststream.codex-stuck-detector-watchdog` returned nonzero on this host.

## Advisory-vs-structural gap audit (2026-05-05)

Date: 2026-05-05

Promotion Action: NEW

Class: `advisory-rule-decay-under-load`

Event Count: 1 socraticode-backed audit

Severity: high

Cost: Substrate-transport gates ship reliably because they are pre-action,
hook-backed, test-backed, and ledgered. Orchestrator behavioral rules too often
ship as memory or skill prose and then decay under cognitive load.

Forever-Rule: Every memory rule that begins with `META-RULE` must have a wired
structural gate, or a bead that explicitly tracks the missing gate. If the gate
is not universal, mark it PARTIAL and name the missing adoption surface.

Fix Applied/Status: Audit-only inventory shipped. No gate wiring was performed.
UNWIRED rows are linked to existing gap beads; PARTIAL rows name the missing
adoption surface.

Evidence:
- Audit MD: `/tmp/advisory-rules-gap-audit-2026-05-05.md`.
- Audit JSON: `/tmp/advisory-rules-gap-audit-2026-05-05.json`.
- Existing gap beads: `flywheel-orch-no-punt-gate-e69d`,
  `flywheel-wire-data-decides-not-meatpup-bd33`,
  `flywheel-wire-donella-first-no-stop-to-36d7`,
  `flywheel-wire-two-truth-sources-before-f814`,
  `flywheel-wire-dispatch-delivery-valida-f29a`,
  `flywheel-wire-two-blocker-ticks-escala-bee8`,
  `flywheel-wire-low-bead-threshold-work--2ae1`,
  `flywheel-wire-canonical-cli-at-dispatc-cdcb`,
  `flywheel-wire-publishability-bar-three-97f7`.

## Wired data-decides-not-meatpuppet as pre-output gate (2026-05-05)

Date: 2026-05-05

Promotion Action: NEW

Class: `data-decides-not-meatpuppet`

Event Count: recurring same-day advisory drift

Severity: high

Cost: Orchestrator output was still able to ask Joshua to choose among options
when the data already named the next action, workers were available, and ready
beads existed. Post-hoc counters saw the punt only after Joshua had already
seen it.

Root Cause: The data-decides rule lived as advisory memory and downstream
ledger checks, not as a pre-output rule. That put the information flow after
the human-visible failure.

Forever-Rule: Data-decides-not-meatpuppet must run as a Stop hook before
orchestrator output is accepted. If proposed text matches punt language while
worker capacity and ready beads exist, the hook forces re-authoring as a
dispatch/action instead of asking Joshua.

Fix Applied/Status: `flywheel-wire-data-decides-not-meatpup-bd33` added
`.flywheel/scripts/orch-no-punt-output-gate.sh`, a Stop hook wrapper at
`~/.claude/hooks/flywheel-orch-no-punt-output-gate.sh`, additive
`~/.claude/settings.json` registration, a v1 decision schema, fixture tests, and
an append-only gate ledger.

Evidence:
- Gate: `.flywheel/scripts/orch-no-punt-output-gate.sh`.
- Hook: `~/.claude/hooks/flywheel-orch-no-punt-output-gate.sh`.
- Schema: `.flywheel/validation-schema/v1/orch-no-punt-decision.schema.json`.
- Test: `.flywheel/tests/test-orch-no-punt-output-gate.sh`.
- Sibling precedents: `~/.claude/hooks/flywheel-loop-dispatch-transport-gate.sh`,
  `~/.claude/commands/flywheel/_shared/mission-anchor-dispatch-preflight.sh`,
  and `templates/flywheel-install/validate-callback-before-close.sh.tmpl`.
- Donella read: #5 rules plus #6 information flow upstream of Joshua eyeballs.

## Wired donella-first-no-stop-to-ask as Stop hook gate (2026-05-05)

Date: 2026-05-05

Promotion Action: NEW

Class: `donella-first-no-stop-to-ask`

Event Count: recurring same-day advisory drift

Severity: high

Cost: Orchestrator output could still ask Joshua to dispose of a decision or
propose substrate action without first showing the system boundary, stock,
flow, feedback loop, leverage point, intervention, and measurement read that
justifies the ask. That left a paradigm-class rule as prose instead of a
pre-output constraint.

Root Cause: `feedback_donella_first_no_stop_to_ask` was advisory memory. It
could be remembered during calm planning and skipped under dispatch pressure
because no Stop hook checked the assistant output before Joshua saw it.

Forever-Rule: Donella-first-no-stop-to-ask must run as a Stop hook before
orchestrator output is accepted. If proposed text contains a Joshua-disposes
pattern or a substrate-action proposal, it must include a same-response Donella
trace with at least five of: boundary, stock, flow, loop, leverage,
intervention, measurement. True blocker classes remain allowed.

Fix Applied/Status: `flywheel-wire-donella-first-no-stop-to-36d7` added
`.flywheel/scripts/orch-donella-trace-gate.sh`, a Stop hook wrapper at
`~/.claude/hooks/flywheel-orch-donella-trace-gate.sh`, additive
`~/.claude/settings.json` registration after the no-punt hook, a v1 decision
schema, an eight-case fixture test, and an append-only gate ledger.

Evidence:
- Gate: `.flywheel/scripts/orch-donella-trace-gate.sh`.
- Hook: `~/.claude/hooks/flywheel-orch-donella-trace-gate.sh`.
- Schema: `.flywheel/validation-schema/v1/orch-donella-trace-decision.schema.json`.
- Test: `.flywheel/tests/test-orch-donella-trace-gate.sh`.
- Sibling precedent: `.flywheel/scripts/orch-no-punt-output-gate.sh` and
  `~/.claude/hooks/flywheel-loop-dispatch-transport-gate.sh`.
- Donella read: #2 paradigm class, implemented as a #5 rules gate with #6
  information flow before Joshua-visible output.

## Wired two-truth-sources-before-decide as pre-dispatch validator (2026-05-05)

Date: 2026-05-05

Promotion Action: NEW

Class: `two-truth-sources-before-decide`

Event Count: sibling same-day dispatch capacity drift

Severity: high

Cost: Dispatch capacity could still depend on a single pane truth source even
when live robot-activity and live tail evidence disagreed. That made stale
captures, reminder templates, or source-specific parser errors capable of
greenlighting a worker send before the contradiction was visible.

Root Cause: The mission-anchor preflight and robot-activity capacity check were
structural, but the second source remained an operator habit instead of a
pre-send validator. Donella #6 information flow was present in analysis but not
wired before `ntm send`.

Forever-Rule: Dispatch must fail closed unless at least two live truth sources
agree that the target pane is ready. A single source, stale provenance, reminder
template, parser disagreement, or probe failure aborts before wrapped packet
generation or send.

Fix Applied/Status: `flywheel-wire-two-truth-sources-before-f814` added
`.flywheel/scripts/two-truth-sources-validator.sh`, the shared pre-send wrapper
at `~/.claude/commands/flywheel/_shared/dispatch-pre-send-validator.sh`,
additive Step 1b in `/Users/josh/.claude/commands/flywheel/dispatch.md`, a v1
decision schema, fixture tests, and an append-only validator ledger.

Evidence:
- Gate: `.flywheel/scripts/two-truth-sources-validator.sh`.
- Wrapper: `~/.claude/commands/flywheel/_shared/dispatch-pre-send-validator.sh`.
- Dispatch skill: `~/.claude/commands/flywheel/dispatch.md` Step 1b.
- Schema: `.flywheel/validation-schema/v1/two-truth-sources-decision.schema.json`.
- Test: `.flywheel/tests/test-two-truth-sources-validator.sh`.
- Ledger: `~/.local/state/flywheel/two-truth-sources-validator-ledger.jsonl`.
- Survey: `/tmp/wire-two-truth-sources-gate-research-survey.md`.
- Donella read: #6 information flows before dispatch, sibling to
  mission-anchor-preflight.

## br-db wedge recurrence root-cause + mitigation (2026-05-05)

Date: 2026-05-05

Promotion Action: NEW

Class: `br-db wedge recurrence`

Event Count: recurring Beads SQLite corruption after same-day recovery attempts

Severity: high

Cost: `br close` and related Beads mutations kept falling back to JSONL truth
line writes. The live DB looked superficially clean to `br sync --status`
(`dirty_count=0`) while direct SQLite integrity showed hard freelist
corruption, allowing workers to keep rediscovering the same wedge at closeout.

Root Cause: The active flywheel Beads runtime is still `br 0.1.20` while
current upstream/package surfaces are `beads_rust 0.2.4` / GitHub `v0.2.4+`,
and the repo is under high concurrent worker write pressure. After repeated
JSONL rebuilds, the live DB recurred with `Freelist: freelist leaf count too
big on page 765` and `page 766`; active WAL was only 32 bytes, so the damage is
in the main DB freelist rather than a recoverable large WAL backlog.

Forever-Rule: Beads DB health must be measured by `PRAGMA integrity_check`, not
by `br sync --status`. When integrity is not `ok`, DB-backed create/close/update
paths are RED; workers may continue read-only diagnosis and JSONL-truth
closeout, but live DB rebuild or binary upgrade requires an explicit recovery
window.

Fix Applied/Status: `br-db-wedge-recurrent-rca` shipped a monitor at
`.flywheel/scripts/br-db-corruption-monitor.sh`, a regression test at
`tests/br-db-corruption-monitor.sh`, and doctor integration in
`~/.claude/skills/.flywheel/bin/flywheel-loop` so every doctor invocation
appends `~/.local/state/flywheel/br-db-corruption-monitor-ledger.jsonl` and
exposes `.beads_db_health.br_db_corruption_monitor`. Chosen mitigation is
`workaround_1_jsonl_truth_line_plus_monitor`; upgrade to `beads_rust 0.2.4`
and serialized mutation locks both passed disposable copy-tests but were not
applied to the live repo in this dispatch.

Evidence:
- RCA: `/tmp/br-db-wedge-recurrent-rca-2026-05-05.md`.
- Jeff draft, not filed: `/tmp/jeff-issue-beads-rust-freelist-corruption-2026-05-05.md`.
- Monitor: `.flywheel/scripts/br-db-corruption-monitor.sh`.
- Test: `tests/br-db-corruption-monitor.sh`.
- Live integrity: `Freelist: freelist leaf count too big on page 765` and
  `Freelist: freelist leaf count too big on page 766`.
- Workaround copy-tests:
  `/tmp/br-db-jsonl-truth-test-2026-05-05.0OFMDw/receipt.json`,
  `/tmp/br024-clean-copy-test-2026-05-05.otGvXv/receipt.json`, and
  `/tmp/br-db-fcntl-copy-test-2026-05-05.pgDf2q/receipt.json`.

## Wired validate-and-redispatch as post-callback structural validator (2026-05-05)

Date: 2026-05-05

Promotion Action: NEW

Class: `validate-and-redispatch-callback-gate`

Event Count: foundational L71 gap, sibling same-day structural gate rollout

Severity: high

Cost: Orchestrator summaries could still treat worker DONE callbacks as truth
before rerunning the dispatch L112 verify command. A worker could report
`l112_observed=OK...` while the actual repo-local command failed or emitted a
different token, leaving the trust loop downstream of Joshua-visible summary.

Root Cause: Validate-and-redispatch lived as L71 doctrine and close-handler
habit, but no post-callback wrapper ran before summary. The information flow
arrived after the orchestrator had already accepted the callback claim.

Forever-Rule: Every worker DONE callback must be treated as a claim until
`callback-receipt-validator.sh` reruns the dispatch `## L112 verify` command.
L112 verify failures and `l112_observed` mismatches fail closed and open a fix
bead; malformed callbacks fail open only as `unverifiable`.

Fix Applied/Status: `flywheel-wire-validate-and-redispatch--f094` added
`.flywheel/scripts/callback-receipt-validator.sh`,
`.flywheel/scripts/callback-fix-bead-opener.sh`, shared wrapper
`~/.claude/commands/flywheel/_shared/callback-receipt-validator-wrapper.sh`,
additive Step 0 in `close-handler.md`, a v1 decision schema, fixture tests,
and an append-only validator ledger.

Evidence:
- Validator: `.flywheel/scripts/callback-receipt-validator.sh`.
- Fix-bead opener: `.flywheel/scripts/callback-fix-bead-opener.sh`.
- Wrapper: `~/.claude/commands/flywheel/_shared/callback-receipt-validator-wrapper.sh`.
- Close handler: `~/.claude/commands/flywheel/_shared/close-handler.md` Step 0.
- Schema: `.flywheel/validation-schema/v1/callback-receipt-decision.schema.json`.
- Test: `.flywheel/tests/test-callback-receipt-validator.sh`.
- Ledger: `~/.local/state/flywheel/callback-receipt-validator-ledger.jsonl`.
- Survey: `/tmp/wire-validate-and-redispatch-gate-research-survey.md`.
- Donella read: #5 rules plus #6 information flow before orchestrator summary,
  sibling to close-validator and no-punt gates.

## Wired orchestrator-validates-callbacks as post-callback artifact validator (2026-05-05)

Date: 2026-05-05

Promotion Action: NEW

Class: `orchestrator-validates-callbacks-artifact-gate`

Event Count: foundational acceptance-artifact gap, sibling to
validate-and-redispatch

Severity: high

Cost: Orchestrator closeout could rerun L112 and still miss whether the
dispatch's declared acceptance artifacts actually existed in the expected
paths and shapes. That let a DONE callback claim completion while required
scripts, schemas, wrappers, tests, or incident entries were absent,
subthreshold, non-executable, or malformed.

Root Cause: L112 validated a worker-declared command result, while the
dispatch packet's `## Required artifacts` section remained prose. The
orchestrator lacked a structural information flow from dispatch contract to
artifact filesystem truth before summary.

Forever-Rule: Every worker DONE callback must pass an artifact-fulfillment gate
before summary. The gate reads the dispatch `## Required artifacts` section,
checks each declared path for existence, minimum byte threshold, and shape, and
cross-checks callback `evidence=` paths against that list. Missing,
subthreshold, malformed, or evidence-mismatched artifacts fail closed and open
a fix bead. Malformed dispatch artifact sections fail open only with
`unverifiable_artifact_check=true`.

Fix Applied/Status: `flywheel-wire-orchestrator-validates-c-3a51` added
`.flywheel/scripts/orchestrator-callback-artifact-validator.sh`,
`.flywheel/scripts/orchestrator-callback-artifact-fix-bead.sh`, shared wrapper
`~/.claude/commands/flywheel/_shared/orch-callback-artifact-wrapper.sh`,
additive Step 0a in `close-handler.md`, a v1 decision schema, fixture tests,
and an append-only validator ledger.

Evidence:
- Validator: `.flywheel/scripts/orchestrator-callback-artifact-validator.sh`.
- Fix-bead opener: `.flywheel/scripts/orchestrator-callback-artifact-fix-bead.sh`.
- Wrapper: `~/.claude/commands/flywheel/_shared/orch-callback-artifact-wrapper.sh`.
- Close handler: `~/.claude/commands/flywheel/_shared/close-handler.md` Step 0a.
- Schema: `.flywheel/validation-schema/v1/orchestrator-callback-artifact-decision.schema.json`.
- Test: `.flywheel/tests/test-orchestrator-callback-artifact-validator.sh`.
- Ledger: `~/.local/state/flywheel/orchestrator-callback-artifact-validator-ledger.jsonl`.
- Dispatch: `/tmp/dispatch_wire-orchestrator-validates-callbacks.md`.
- Donella read: #5 rules plus #6 information flow before orchestrator summary,
  complementary to validate-and-redispatch and dispatch-delivery verification.

## Wired memory-rule-gate-parity as umbrella drift detector (2026-05-05)

Date: 2026-05-05

Promotion Action: NEW

Class: `memory-rule-gate-parity`

Event Count: umbrella advisory-to-structural detector

Severity: high

Cost: META-RULE memory files were being added faster than structural gates could
be wired by hand. Without an upstream detector, each new rule could silently
fall back to prose until Joshua noticed the same advisory drift again.

Root Cause: The system had many memory-rule inflows but no doctor stock that
measured whether a META-RULE had script, hook/settings, test, and INCIDENTS
evidence. Advisory rules could therefore look learned while remaining
non-operational.

Forever-Rule: Every `feedback_*.md` memory file marked `META-RULE` must have
structural gate parity. `memory-rule-gate-parity-detector.sh` classifies each
rule as WIRED, PARTIAL, or UNWIRED; doctor exposes `.memory_rule_gate_parity`;
YELLOW/RED signals route repair work, and RED with `--auto-bead` files one
idempotent `wire-<rule>-as-structural-gate` repair bead per unwired rule.

Fix Applied/Status: `flywheel-wire-memory-rule-gate-parity-27d5` added
`.flywheel/scripts/memory-rule-gate-parity-detector.sh`, doctor scope
`memory-rule-gate-parity`, a top-level doctor field, a v1 decision schema,
fixture tests, and an append-only ledger at
`~/.local/state/flywheel/memory-rule-gate-parity-ledger.jsonl`.

Donella read: #5 rules converts the reminder into an executable constraint;
#2 paradigm shifts META-RULEs from "remember this" notes into substrate that
must prove its own operating gate.

Evidence:
- Detector: `.flywheel/scripts/memory-rule-gate-parity-detector.sh`.
- Test: `.flywheel/tests/test-memory-rule-gate-parity-detector.sh`.
- Schema: `.flywheel/validation-schema/v1/memory-rule-gate-parity-decision.schema.json`.
- Doctor integration: `~/.claude/skills/.flywheel/bin/flywheel-loop`.
- Live smoke: `/tmp/memory-rule-gate-parity-live-smoke.json`.

## Detector silent exit-2 regression on live panes — fixed (2026-05-05)

Date: 2026-05-05

Promotion Action: NEW

Class: `detector_silent_exit2`

Event Count: 3+ live watcher-prove regressions observed 2026-05-05

Severity: P0

Cost: Live Codex panes matching the post-callback reminder template plus stale
background spinner signature exited detector recovery silently instead of
recovering. Joshua manually respawned panes repeatedly while the golden replay
test stayed green.

Root Cause: The live detector path used `ntm copy` in clipboard mode and read
the confirmation text as pane text. It also returned `{}` for live
`fixture_payload`, so the auto-recovery branch treated live panes as fixture
captures and skipped `recovery-escape-then-reprompt.sh`. The shared classifier
also missed the live `esc…` truncated spinner and `Run /review on my current
changes` reminder shapes.

Forever-Rule: Frozen-pane detectors must prove fixture/live parity at the
capture boundary. A golden artifact replay is insufficient unless a live-path
synthetic test drives the same classifier and recovery primitive used by the
watcher.

Fix Applied/Status: `flywheel-detector-silent-exit2-166f` patched
`.flywheel/scripts/codex-template-stuck-detector.sh` to read actual pane text
via `ntm copy --output`, preserve `fixture_payload=None` for live captures,
classify truncated post-callback spinner shapes, emit JSON on rc=2
`unknown_stable`, return rc=3 for probe failures, and invoke the 3-stage
recovery primitive for live post-callback subclass matches. Added
`.flywheel/tests/test-detector-live-pane-regression.sh` and extended
`.flywheel/tests/test-detector-pattern-bank-replay.sh` with real 2026-05-05
live snapshots.

Donella read: #5 rules and #6 information flows. The structural gap was a
test rule that validated fixture replay but not live capture parity; the fix
changes the rule and wires the missing information flow before watcher close.

Evidence:
- RCA: `/tmp/detector-silent-exit2-rca-2026-05-05.md`.
- Detector: `.flywheel/scripts/codex-template-stuck-detector.sh`.
- Pattern replay: `.flywheel/tests/test-detector-pattern-bank-replay.sh`.
- Live regression: `.flywheel/tests/test-detector-live-pane-regression.sh`.
- Recovery primitive regression: `.flywheel/tests/test-recovery-escape-then-reprompt.sh`.
- Live snapshots:
  `/tmp/flywheel-pane2-snapshot.20260505T235808Z.json`,
  `/tmp/flywheel-pane3-snapshot.20260505T205900Z.json`.

## Wired publishability-bar-three-judges as close-time structural gate (advisory default) (2026-05-05)

Date: 2026-05-05

Promotion Action: NEW

Class: `publishability-bar-three-judges-close-gate`

Event Count: 1 structural gate promotion

Severity: high

Cost: `feedback_publishability_bar_three_judges.md` set the goal that every
flywheel-touched repo should pass the Jeff/Donella/Joshua fork-and-star bar,
but that bar only fired inside `/flywheel:plan` Phase 3 audits. Bead closeout
could therefore ship a changed flywheel surface without a close-time
publishability receipt, leaving quality debt to be found by later polish rounds.

Root Cause: The three-judges bar was a goal and audit pattern, not a close-path
rule. The close handler validated callback shape, artifact existence, and L112
reruns, but did not measure whether the repo still cleared the seven-facet
publishability bar before closing the bead.

Forever-Rule: Every flywheel close attempt must run the three-judges
publishability precheck. Default mode is advisory during stamp-in-flywheel-first
rollout; strict mode is opt-in via `.flywheel/three-judges-mode=strict`.
Advisory REFUSE records a ledger row and opens idempotent rework beads without
blocking close. Strict REFUSE blocks close until the failed facets have repair
evidence.

Fix Applied/Status: `flywheel-wire-publishability-bar-three-97f7` added
`.flywheel/scripts/three-judges-publishability-validator.sh`,
`.flywheel/scripts/three-judges-rework-bead-opener.sh`,
`~/.claude/commands/flywheel/_shared/three-judges-publishability-precheck.sh`,
`.flywheel/validation-schema/v1/three-judges-publishability-decision.schema.json`,
`.flywheel/tests/test-three-judges-publishability-validator.sh`, and additive
Step 0b in `~/.claude/commands/flywheel/_shared/close-handler.md`.

Donella read: #3 goals makes the close path optimize for first-look public
trust, not just task completion. #5 rules turns that goal into an executable
constraint with advisory rollout and strict opt-in.

Evidence:
- Validator: `.flywheel/scripts/three-judges-publishability-validator.sh`.
- Rework opener: `.flywheel/scripts/three-judges-rework-bead-opener.sh`.
- Wrapper: `~/.claude/commands/flywheel/_shared/three-judges-publishability-precheck.sh`.
- Schema: `.flywheel/validation-schema/v1/three-judges-publishability-decision.schema.json`.
- Test: `.flywheel/tests/test-three-judges-publishability-validator.sh`.
- Live smoke: `/tmp/three-judges-publishability-live-smoke.json`.

## Detector classifier hash-stable gap fixed (2026-05-06)

Date: 2026-05-06

Promotion Action: FIX

Class: `detector-classifier-hash-stable-gap`

Event Count: 7+ post-callback freezes in same operating window

Severity: P0

Cost: Post-callback frozen panes with visible Codex reminder prompts and stale
spinners were missed when pane hashes differed by a cosmetic spinner tick. The
detector classified those panes as `alive`, delaying recovery and allowing
workers to remain frozen after callbacks.

Root Cause: `classify_text()` made `hash_stable=true` a prerequisite for every
subclass by returning `alive` before specialized classifier branches could run.
That rule was correct for generic stable-buffer classes, but wrong for
post-callback reminder + stale-spinner evidence. Current Codex reminder prompts
also included `Summarize recent commits`, `Find and fix a bug in @filename`, and
`Write tests for @filename`, which were absent from the reminder bank.

Forever-Rule: Specialized post-callback recovery classifiers run on their own
signal first. `hash_stable` remains a generic stability gate, not a global
subclass prerequisite. Cosmetic spinner hash drift must not suppress
`post_callback_reminder_template_with_stale_spinner` when reminder prompt and
spinner age evidence are present.

Fix Applied/Status: `flywheel-detector-classifier-hash-stable-gap-d9a5`
patched `.flywheel/scripts/codex-template-stuck-detector.sh` so the
post-callback signal is evaluated before the `hash_stable=false` alive branch.
The stale-spinner matcher now covers both `Waiting for background terminal (...)`
and `Working (...)`, applies the `>90s` threshold, and includes current Codex
reminder prompt templates. Added
`.flywheel/tests/test-detector-classifier-hash-stable-regression.sh` and updated
`.flywheel/tests/test-detector-pattern-bank-replay.sh` to replay current
2026-05-06 live snapshots when available.

Donella read: #5 rules and #6 information flows. The detector rule now routes
the strongest recovery signal before generic hash-stability information can
mask it.

Evidence:
- RCA: `/tmp/detector-classifier-hash-stable-rca-2026-05-06.md`.
- Detector: `.flywheel/scripts/codex-template-stuck-detector.sh`.
- Regression: `.flywheel/tests/test-detector-classifier-hash-stable-regression.sh`.
- Pattern replay: `.flywheel/tests/test-detector-pattern-bank-replay.sh`.
- Live regression: `.flywheel/tests/test-detector-live-pane-regression.sh`.
- Live snapshots:
  `/tmp/flywheel-pane2-snapshot.20260506T001424Z.json`,
  `/tmp/flywheel-pane2-snapshot.20260506T002515Z.json`,
  `/tmp/flywheel-pane2-snapshot.20260506T011611Z.json`,
  `/tmp/mobile-eats-pane2-snapshot.20260506T011620Z.json`.

## Wired low-bead-threshold-work-hunt as doctor signal (2026-05-06)

Date: 2026-05-06

Promotion Action: NEW

Class: `low-bead-threshold-work-hunt`

Event Count: advisory memory promoted to structural doctor stock

Severity: high

Cost: `feedback_low_bead_threshold_work_hunt.md` required flywheel:1 to hunt
MISSION, environment, and skills work when ready beads fall below 10, or notify
Joshua only for a true blocker. As advisory memory, the queue could become
light without producing a machine-visible work-hunt bead.

Root Cause: Ready-bead stock was visible in local Beads state, but no doctor
field consumed the JSONL truth source and no idempotent repair bead was opened
when the stock went RED.

Forever-Rule: `low-bead-threshold-detector.sh` reads `.beads/issues.jsonl`,
reduces to latest rows by id, counts ready open/unblocked/unclaimed beads and
assigned `in_progress` beads, and emits GREEN/YELLOW/RED. RED with
`--auto-bead` opens one idempotent `hunt-work-MISSION-env-skills` P0 bead that
names `.flywheel/MISSION.md`, `.flywheel/GOAL.md`, `.flywheel/STATE.md`,
environment signals, `~/.claude/skills/`, and `~/.codex/skills/`.

Fix Applied/Status: `flywheel-wire-low-bead-threshold-work--2ae1` added
`.flywheel/scripts/low-bead-threshold-detector.sh`, doctor scope
`low-bead-threshold`, top-level doctor field `.low_bead_threshold`, a v1
decision schema, fixture tests, and an append-only ledger at
`~/.local/state/flywheel/low-bead-threshold-detector-ledger.jsonl`.

Donella read: #4 self-organization is the leverage point. The detector turns a
low work stock into autonomous work generation instead of a silent idle state.

Evidence:
- Detector: `.flywheel/scripts/low-bead-threshold-detector.sh`.
- Test: `.flywheel/tests/test-low-bead-threshold-detector.sh`.
- Schema: `.flywheel/validation-schema/v1/low-bead-threshold-decision.schema.json`.
- Doctor: `~/.claude/skills/.flywheel/bin/flywheel-loop doctor --scope low-bead-threshold --json`.
- Live smoke: `/tmp/low-bead-threshold-live-smoke.json`.

## Watchdog cross-session scope extended (2026-05-06)

Date: 2026-05-06

Promotion Action: NEW

Class: `watchdog-cross-session-scope-gap`

Event Count: 1 live scope gap

Severity: high

Cost: `mobile-eats:2` was frozen behind a stale Codex prompt while the stuck
detector launchd surface only had flywheel-oriented coverage. Sister sessions
had idle-pane-watch sibling shape, but no per-session stuck-detector labels.

Root Cause: The information flow stopped at the flywheel session. The detector
could classify stale worker panes, but launchd did not schedule GUI-domain
per-session probes for `mobile-eats`, `skillos`, `alpsinsurance`, and `vrtx`.

Forever-Rule: Every live NTM worker-pane session in the current topology set
must have GUI-domain stuck-detector launchd coverage or an explicit
no-coverage receipt. Fixed fleet scope uses sibling per-session plists; probes
must validate `gui/$(id -u)/<label>`, not `user/<uid>`.

Fix Applied/Status: Added four per-session stuck-detector plists for
`mobile-eats`, `skillos`, `alps`, and `vrtx`; the `alps` launchd label maps to
the `alpsinsurance` NTM session. The installer now installs and reloads all
five labels idempotently. The verifier and test assert GUI-domain load,
session-scoped detector arguments, recent per-session launchd fire evidence,
and no duplicate target plists.

Donella read: #6 information flows and #5 rules. The fix gives each sister
session its own detector signal path instead of relying on a flywheel-only
information channel.

Evidence:
- Bead: `flywheel-watchdog-cross-session-scope-gap-6036`.
- Options memo: `/tmp/watchdog-cross-session-scope-2026-05-06.md`.
- Plists:
  `.flywheel/launchd/ai.zeststream.mobile-eats-codex-stuck-detector.plist`,
  `.flywheel/launchd/ai.zeststream.skillos-codex-stuck-detector.plist`,
  `.flywheel/launchd/ai.zeststream.alps-codex-stuck-detector.plist`,
  `.flywheel/launchd/ai.zeststream.vrtx-codex-stuck-detector.plist`.
- Installer: `.flywheel/scripts/install-stuck-detector-watchdog.sh`.
- Verifier: `.flywheel/scripts/verify-watcher-launchd-active.sh`.
- Test: `.flywheel/tests/test-watcher-launchd-active.sh`.

## Wired two-blocker-ticks-escalate as auto-escalator (2026-05-06)

Date: 2026-05-06

Promotion Action: NEW

Class: `two-blocker-ticks-escalate`

Event Count: advisory memory promoted to structural doctor signal

Severity: high

Cost: `feedback_two_blocker_ticks_escalate_to_flywheel_plan.md` said a blocker
surviving two consecutive ticks must escalate to flywheel:1 for `/flywheel:plan`
work. As an advisory, the orchestrator could still sit on repeated overdue
callbacks without a fleet-mail capsule, a P0 repair bead, or a doctor-visible
RED stock.

Root Cause: `.flywheel/dispatch-log.jsonl` carried callback deadlines, but no
stateful detector measured whether the same open callback stayed overdue across
ticks. Cross-orch coordination and bead filing therefore depended on manual
operator notice.

Forever-Rule: `two-blocker-ticks-escalator.sh` reads current absolute
`callback_expected_by` rows from `.flywheel/dispatch-log.jsonl`, tracks
per-bead consecutive overdue ticks in
`~/.local/state/flywheel/two-blocker-ticks-state.json`, emits
GREEN/YELLOW/RED, and appends every decision to
`~/.local/state/flywheel/two-blocker-ticks-escalator-ledger.jsonl`. RED with
`--auto-escalate` appends one idempotent `blocker_escalation` fleet-mail
capsule to `~/.local/state/flywheel/cross-orch-coordination.jsonl` and one
idempotent `escalate-blocker-<bead-id>-via-flywheel-plan` P0 bead via JSONL
fallback. The detector does not auto-trigger `/flywheel:plan`.

Fix Applied/Status: `flywheel-wire-two-blocker-ticks-escala-bee8` added
`.flywheel/scripts/two-blocker-ticks-escalator.sh`, doctor scope
`two-blocker-ticks`, top-level doctor field `.two_blocker_ticks`, a v1 decision
schema, fixture tests, atomic state writes, and append-only coordination/bead
outputs.

Donella read: #4 self-organization and #6 information flows. The fix turns a
stuck callback stock into an autonomous escalation path instead of an
orchestrator memory burden.

Evidence:
- Detector: `.flywheel/scripts/two-blocker-ticks-escalator.sh`.
- Test: `.flywheel/tests/test-two-blocker-ticks-escalator.sh`.
- Schema: `.flywheel/validation-schema/v1/two-blocker-ticks-decision.schema.json`.
- Doctor: `~/.claude/skills/.flywheel/bin/flywheel-loop doctor --scope two-blocker-ticks --json`.
- Live smoke: `signal=RED blocked_count=4 max_consecutive_tick_count=2`;
  second run reused existing escalation beads/capsules idempotently.

## Phase 3 fleet broadcast fired (2026-05-06)

Date: 2026-05-06

Promotion Action: BROADCAST

Class: `phase3-polish-gate-fleet-broadcast`

Event Count: 5 peer repositories targeted

Severity: medium

Cost: The polish-gate template had passed Phase 2 audit in flywheel, but without
a fleet broadcast the gate would remain local knowledge. Peer repos would keep
deciding publishability without the new five-skill measured surface contract.

Root Cause: The information flow from flywheel's proven template to sister
orchestrators was intentionally staged behind the Phase 2 green-light. Phase 3
needed a durable cross-orch capsule broadcast rather than another local README
or advisory memory.

Forever-Rule: Phase-gated template propagation uses a single coordination
surface. Peer repos receive advisory capsules with explicit allowlists,
blocklists, callback contracts, and owner routes; each peer orchestrator decides
adoption pace inside its local mission.

Fix Applied/Status: Fired the pre-staged Phase 3 dispatcher with
`PHASE2_QUORUM_STATE=/tmp/phase3-fleet-broadcast-quorum-2026-05-06.json` and
`PHASE3_BROADCAST_ID=phase3-fleet-broadcast-2026-05-06`. The dispatcher
appended five capsule rows plus one summary row to
`~/.local/state/flywheel/cross-orch-coordination.jsonl`; follow-up
dispatch-state rows recorded `kind=phase3_broadcast` and NTM delivery status
for all five owner routes. READY flag moved to COMPLETE and receipt JSON landed.

Targets:
- `alps` -> `alpsinsurance:1` (`audit-only`, `.flywheel/` only)
- `mobile-eats` -> `mobile-eats:1` (`audit-only`)
- `skillos` -> `skillos:1` (`audit-only`)
- `swarm-daemon` -> `flywheel:1` (`full-grade`)
- `vrtx` -> `vrtx:1` (`audit-only`)

Donella read: #6 information flows. The fix makes polish-gate propagation an
ecosystem-wide signal in the cross-orch ledger, while #5 rules preserve per-repo
scope boundaries through allowlists and callback contracts.

Evidence:
- Capsule directory: `/tmp/phase3-fleet-broadcast-capsules-2026-05-05/`.
- Dispatcher stdout: `/tmp/phase3-fleet-broadcast-apply-2026-05-06.out`.
- Dispatch-state rows: `/tmp/phase3-fleet-broadcast-dispatch-state-2026-05-06.jsonl`.
- Receipt: `templates/flywheel-install/polish-gate/PHASE-3-BROADCAST-RECEIPT.json`.
- Complete flag: `templates/flywheel-install/polish-gate/PHASE-3-BROADCAST-COMPLETE.flag`.
- Coordination rows:
  `~/.local/state/flywheel/cross-orch-coordination.jsonl#L117-L127`.

## Detector classifier fix INCOMPLETE - live-pane code path bypassed classifier signal (2026-05-06)

Date: 2026-05-06

Promotion Action: UPDATE

Class: `detector-classifier-live-path-bypass`

Event Count: 1 production live-probe regression after fixture tests passed

Severity: high

Cost: A real frozen Codex worker pane at 2026-05-06T01:50Z returned
`subclass=alive`, `recommended_recovery=none`, and `recovery_attempted=none`,
so the watcher would leave a recoverable frozen pane in service despite the
prior hash-stable fixture suite passing.

Root Cause: The fixture-path tests did not exercise the exact production
`--session --pane` capture shape for `Implement {feature}` with a drifting stale
spinner. The live path did call the same classifier, but `Implement {feature}`
was only in `PLACEHOLDER_RE`, not the post-callback reminder bank. When the live
spinner timer changed between samples, `hash_stable=false` and `classify_text`
fell through to the generic `alive` branch before the stale-spinner subclass
could fire.

Forever-Rule: Detector regressions must exercise the production capture path,
not only convenient fixture replay. Any post-callback reminder template added to
the generic placeholder bank must either be deliberately excluded with a test or
included in the stale-spinner reminder bank with a live `--session --pane`
regression.

Fix Applied/Status: `flywheel-detector-classifier-fix-incomplete-be72` patched
`.flywheel/scripts/codex-template-stuck-detector.sh` so `Implement {feature}` is
recognized by the post-callback stale-spinner classifier. Added
`.flywheel/tests/test-detector-live-probe-regression.sh`, which drives the
detector through `--session flywheel --pane 2` using a synthetic live NTM copy
provider with spinner hash drift and asserts `subclass != alive` plus staged
recovery. Updated
`.flywheel/tests/test-detector-classifier-hash-stable-regression.sh` with both
fixture and `--session --pane` hash-drift cases for the same template.

Donella read: #5 rules and #6 information flows. The test rule now routes the
same signal path production uses into regression coverage instead of validating
only the lower-friction fixture flow.

Evidence:
- Bead: `flywheel-detector-classifier-fix-incomplete-be72`.
- RCA: `/tmp/detector-classifier-fix-incomplete-rca-2026-05-06.md`.
- Detector: `.flywheel/scripts/codex-template-stuck-detector.sh`.
- Live-probe regression:
  `.flywheel/tests/test-detector-live-probe-regression.sh`.
- Updated regression:
  `.flywheel/tests/test-detector-classifier-hash-stable-regression.sh`.
- Trace logs:
  `/tmp/detector-trace-live-path.log`,
  `/tmp/detector-trace-fixture-path.log`.

## Two-blocker-ticks-escalator JSONL-fallback regression (2026-05-06)

Date: 2026-05-06

Promotion Action: UPDATE

Class: `two-blocker-ticks-jsonl-fallback-regression`

Event Count: 1 production close-path regression after fixture tests passed

Severity: high

Cost: The first production run of `two-blocker-ticks-escalator.sh` filed four
false-positive P0 escalation beads for work that had already completed through
the JSONL fallback close path: `flywheel-escalate-6b11a41b`,
`flywheel-escalate-9beb9b99`, `flywheel-escalate-c3532d8f`, and
`flywheel-escalate-b962b284`.

Root Cause: The escalator treated `dispatch-log.callback_received_at` as the
only close signal. During the br-db wedge, real close receipts were appended to
`.beads/issues.jsonl` with `status=closed`, while the corresponding dispatch
rows kept `callback_received_at:null`. Fixture tests covered dispatch-log
callbacks but not the production JSONL fallback close path.

Forever-Rule: Any detector or validator that decides whether a dispatch is done
must test both close paths: dispatch-log callback receipts and
`.beads/issues.jsonl` latest-row `status=closed`. JSONL issue truth is a
load-bearing close source while br-db fallback is active.

Fix Applied/Status: `flywheel-two-blocker-ticks-jsonl-fallback-aware-cf3a`
patched `.flywheel/scripts/two-blocker-ticks-escalator.sh` to build a latest-row
issue index, match closed issue rows by id, explicit task fields, normalized
title, or escalation title, and treat those matches as callback-equivalent. The
four false-positive escalation beads were closed with explicit
`original_blocker_task_id` fields. Added
`.flywheel/tests/test-two-blocker-ticks-jsonl-fallback-regression.sh` and
extended the existing escalator test with JSONL fallback and mixed-close cases.

Donella read: #5 rules and #6 information flows. The rule now points the
detector at the durable production truth line, not only the adjacent dispatch
log.

Evidence:
- Bead: `flywheel-two-blocker-ticks-jsonl-fallback-aware-cf3a`.
- RCA: `/tmp/two-blocker-ticks-jsonl-fallback-rca-2026-05-06.md`.
- Detector: `.flywheel/scripts/two-blocker-ticks-escalator.sh`.
- Existing test: `.flywheel/tests/test-two-blocker-ticks-escalator.sh`.
- Regression: `.flywheel/tests/test-two-blocker-ticks-jsonl-fallback-regression.sh`.
- Memory:
  `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_regression_test_must_exercise_production_close_path.md`.

## P2-12 f2: polish-gate schema inventory parity wired (2026-05-06)

Date: 2026-05-06

Promotion Action: UPDATE

Class: `polish-gate-schema-inventory-drift`

Event Count: 1 Phase 2 audit finding

Severity: high

Cost: `templates/flywheel-install/schema.json` declared 7 polish-gate v1
schemas while 9 schema files were shipped on disk. Template consumers could
miss `discovery-output.schema.json` and `reconcile-output.schema.json` unless
they manually inspected the v1 directory.

Root Cause: Schema files were added by follow-on polish-gate beads, but the
template manifest had no bidirectional inventory parity test tying the declared
schema list to the on-disk `v1/*.schema.json` truth source.

Forever-Rule: The polish-gate template manifest must be inventory-complete.
Every `polish-gate/v1/*.schema.json` file must be declared in
`polish_gate.schemas`, and every declared schema must exist on disk.

Fix Applied/Status: `flywheel-p2-12-f2` added the missing discovery and
reconcile schema entries to `templates/flywheel-install/schema.json`, extended
`test_polish_gate_schemas.sh` with bidirectional parity assertions, and added
`test_polish_gate_schema_inventory_parity.sh` as a single-purpose regression
gate. The discovery doc records the 9-file on-disk truth set.

Donella read: #5 rules. The manifest is now a mechanically enforced contract
with on-disk reality instead of a manually maintained inventory.

Evidence:
- Discovery:
  `.flywheel/PLANS/phase2-flywheel-install-polish-gate-2026-05-05/P2-12-F2-SCHEMA-INVENTORY-DISCOVERY.md`.
- Manifest: `templates/flywheel-install/schema.json`.
- Existing test: `templates/flywheel-install/tests/test_polish_gate_schemas.sh`.
- Regression:
  `templates/flywheel-install/tests/test_polish_gate_schema_inventory_parity.sh`.

## Wired polish_gate doctor JSON fields (P2-12 f1) (2026-05-06)

Date: 2026-05-06

Promotion Action: UPDATE

Class: `polish-gate-doctor-information-flow`

Event Count: 1 Phase 2 audit finding

Severity: high

Cost: P2-07 shipped polish-gate runner and receipt substrate, but
`flywheel-loop doctor --json` had no `.polish_gate` field. Operators could not
see mode, receipt counts, failures, waivers, or schema state without manually
probing producer files.

Root Cause: The polish-gate producers wrote `manifest.json`, `grades.jsonl`,
and `latest.json`, but the doctor surface was never wired as the consumer. The
information flow stopped at local artifacts.

Forever-Rule: Any polish-gate installed repo must expose a stable
`.polish_gate` doctor object with `mode`, `summary_path`, `receipt_count`,
`failures_count`, `waiver_count`, `schema_status`, and `signal`. Missing
substrate is RED, malformed substrate is RED, receipts without an aggregate are
YELLOW, and probe errors fail open as GRAY instead of crashing doctor JSON.

Fix Applied/Status: `flywheel-p2-12-f1` added the additive
`polish_gate_doctor_json` doctor helper, top-level `.polish_gate` injection,
`doctor --scope polish-gate`, the v1 doctor-field schema, and
`.flywheel/tests/test-doctor-polish-gate-fields.sh` covering GREEN, YELLOW,
RED missing substrate, RED invalid schema, and stable JSON shape. The shape
matches the sibling doctor scopes for low-bead-threshold,
memory-rule-gate-parity, and two-blocker-ticks.

Donella read: #6 information flows and #5 rules. Polish-gate quality state now
flows into the operational doctor surface instead of remaining hidden in
producer artifacts.

Evidence:
- Bead: `flywheel-p2-12-f1`.
- Doctor helper: `~/.claude/skills/.flywheel/bin/flywheel-loop`.
- Test: `.flywheel/tests/test-doctor-polish-gate-fields.sh`.
- Schema: `.flywheel/validation-schema/v1/doctor-polish-gate-fields.schema.json`.

## P2-12 f3: discovery script malformed-manifest error handling hardened (2026-05-06)

Date: 2026-05-06

Promotion Action: UPDATE

Class: `polish-gate-discovery-malformed-manifest`

Event Count: 1 Phase 2 audit finding

Severity: high

Cost: A malformed polish-gate manifest could crash discovery with a Python
traceback and exit code 1. Operators lost the stable CLI contract needed to
distinguish malformed JSON, schema-like manifest errors, and filesystem read
failures.

Root Cause: `discover-surfaces.py` loaded manifest JSON directly and used
`SystemExit` for some manifest shape errors, so parse/read failures bypassed
the CLI error contract.

Forever-Rule: Polish-gate discovery must convert manifest parse, encoding,
shape, and read failures into explicit operator-facing stderr with stable
nonzero exit codes and no traceback.

Fix Applied/Status: `flywheel-p2-12-f3` added discovery-local
`DiscoveryError` handling, manifest shape validation, code 2 for malformed or
unsupported manifest values, code 3 for manifest read/OSError failures, and
fixture coverage for truncated JSON, invalid UTF-8, missing required fields,
wrong top-level shape, and permission-denied reads.

Donella read: #5 rules and #6 information flows. The discovery CLI now gives
operators a deterministic rule surface instead of leaking implementation
tracebacks into the dispatch path.

Evidence:
- Bead: `flywheel-p2-12-f3`.
- Discovery script:
  `templates/flywheel-install/polish-gate/discover-surfaces.py`.
- Regression test:
  `templates/flywheel-install/tests/test_polish_gate_discovery.sh`.
- Fixtures:
  `templates/flywheel-install/tests/fixtures/malformed-manifest/`.

## AGENTS.md doubling fleet-wide pattern triage (from skillos audit) (2026-05-06)

Date: 2026-05-06

Promotion Action: TRIAGE

Class: `agents-md-doubling-fleet-wide`

Event Count: 1 skillos Phase 3 audit cross-orch routing candidate plus 6-repo
flywheel sample

Severity: high

Cost: Full canonical doctrine and timestamped `AGENTS.md.bak.*` sidecars are
being copied into peer repo working trees. That inflates grep/Socraticode
results, creates local-vs-canonical split-brain risk, and turns every doctrine
sync into more in-tree historical debris.

Root Cause: `flywheel-doctrine-sync` compares peer root `AGENTS.md` and
`.flywheel/AGENTS-CANONICAL.md` against flywheel canonical `AGENTS.md`, then
backs up drifted files in place before copying the full canonical file into both
surfaces. `flywheel-loop init` also copies the canonical doctrine snapshot, and
the current fleet-propagator fixture models the same root/snapshot copy shape.

Forever-Rule: Peer repos should have one full canonical snapshot and one thin
local root `AGENTS.md` pointer plus repo-specific rules. Any exact peer
root/snapshot clone, or recurring in-tree `AGENTS.md.bak.*` sprawl, must surface
as a doctor signal and route to a remediation bead instead of being found by a
later polish audit.

Fix Applied/Status: Triage only. Scope sample and remediation plan were written
under `/tmp`; follow-up bead `wire-agents-md-doubling-prevention` was filed to
wire the detector, doctor fields, tests, and prevention changes. No
`AGENTS.md` files or peer repo files were mutated by this triage.

Scope sample:
- `/tmp/agents-doubling-flywheel-sample-2026-05-06.md`.
- Direct flywheel `AGENTS.md*` count: 12.
- Six-repo sample total: 109 `AGENTS.md*` matches.
- Repos with more than one match: 5 of 6.
- Exact current peer root/snapshot clones observed: `mobile-eats`, `vrtx`.

Remediation plan:
- `/tmp/agents-doubling-remediation-plan-2026-05-06.md`.

Donella read: #6 information flows and #5 rules. The next intervention should
make doubling visible in doctor JSON, then change the sync rule so the doubling
and backup-sprawl stock stops refilling.

Evidence:
- Bead: `flywheel-from-skillos-audit-725d`.
- Follow-up bead: `wire-agents-md-doubling-prevention`.
- Source report: `/tmp/phase3-audit-skillos-report-20260506T015536Z.md`.
- Scope sample: `/tmp/agents-doubling-flywheel-sample-2026-05-06.md`.
- Plan: `/tmp/agents-doubling-remediation-plan-2026-05-06.md`.

## P2-12 f4: Phase 2 bead closure receipts reconciled (2026-05-06)

Date: 2026-05-06

Promotion Action: UPDATE

Class: `phase2-bead-closure-receipt-drift`

Event Count: 2 Phase 2 audit drift findings

Severity: medium

Cost: Phase 2 had shipped artifacts and passing tests, but the bead inventory
was not fully machine-auditable. P2-07 closure truth lived under the canonical
follow-up bead `flywheel-p2-12-f1` without a discoverable `flywheel-p2-07`
compatibility receipt, and P2-11 had stale dispatch context despite its JSONL
fallback close row and live ledger adapter evidence.

Root Cause: Phase 2 closure state was spread across dispatch callbacks, JSONL
fallback close rows, and canonical follow-up beads. Readers relying on stable
Phase-step ids could miss the closure receipt even though the implementation
truth was present.

Forever-Rule: Phase audit inventories must be reconciled with append-only
latest-row receipts. If a Phase step uses a canonical follow-up bead id, append
a compatibility closure receipt that names the Phase step id and aliases the
canonical bead; never rewrite historical JSONL rows to repair audit shape.

Fix Applied/Status: `flywheel-p2-12-f4` appended reconciliation rows for
`flywheel-p2-07`, `flywheel-p2-12-f1`, `flywheel-p2-11`, and its own closeout;
added `.flywheel/tests/test-phase2-bead-inventory-parity.sh`; and wrote
`/tmp/p2-12-f4-bead-inventory-audit-2026-05-06.md`.

Donella read: #5 rules and #6 information flows. The bead inventory now has a
stable machine-readable rule for Phase closure truth rather than requiring
operators to infer state from stale dispatch context.

Evidence:
- Bead: `flywheel-p2-12-f4`.
- Audit: `/tmp/p2-12-f4-bead-inventory-audit-2026-05-06.md`.
- Regression test: `.flywheel/tests/test-phase2-bead-inventory-parity.sh`.
- State rows: `.beads/issues.jsonl` append-only close receipts tagged
  `closure_reconciliation_via=p2-12-f4`.
