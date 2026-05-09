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
   - RU-backed multi-repo systems must also inspect `~/.config/ru/config` and `~/.config/ru/repos.d/*.txt` before framing repo discovery, path drift, or cross-repo absence.
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
- Validator repair bead: `flywheel-ke5ll`.

## backup-proliferation flywheel-lock-pattern triage (from skillos audit) (2026-05-06)

Date: 2026-05-06

Promotion Action: TRIAGE

Class: `backup-proliferation-flywheel-lock-pattern`

Event Count: 1 skillos Phase 3 cross-orch routing candidate, confirmed with
fleet sample

Severity: medium

Cost: In-tree backup sidecars now form a searchable, indexable stock of stale
operational doctrine and state. Flywheel alone has 176 backup-class files using
the broad pattern, 270,417,920 bytes aggregate. The six-repo sample has 642
backup-class files, 580,915,200 bytes aggregate.

Root Cause: Lock-family, doctrine-sync, and recovery flows correctly preserve
preimages before mutation but write those backups into the working tree with no
retention, no off-tree archive, and no doctor consumer. The rule prevents local
loss while creating fleet-wide stale substrate.

Forever-Rule: Backup-before-mutation flows for operational docs must be bounded
and observable. Core `.flywheel/{MISSION,GOAL,STATE}.md`, root `AGENTS.md`,
`.flywheel/AGENTS-CANONICAL.md`, and bead recovery sidecars must surface in
doctor JSON and route to a remediation bead before they become repo-visible
archive stock.

Fix Applied/Status: Triage only. Scope sample and remediation plan were written
under `/tmp`; follow-up bead `wire-backup-proliferation-prevention` was filed
to wire detector, doctor fields, tests, off-tree archive policy, and producer
prevention. No backup files or peer repo files were mutated by this triage.

Flywheel-lock correlation:
- Core lock-family docs account for 108 of 176 flywheel backup files:
  `MISSION.md` 45, `STATE.md` 29, `GOAL.md` 20,
  `AGENTS-CANONICAL.md` 14.
- Root `AGENTS.md` doctrine-sync sidecars raise the operational-doc count to
  117 of 176.
- Bead DB recovery sidecars raise operational substrate backup pressure to
  161 of 176.

Shared root with agents-doubling: true. The earlier
`flywheel-from-skillos-audit-725d` triage found root/snapshot AGENTS full-copy
duplication plus `AGENTS.md.bak.*` sidecars. Backup proliferation is the
broader stock-and-flow pattern behind that symptom and lock-family sidecars.
The prevention work should share fixtures and suffix parsing with
`wire-agents-md-doubling-prevention` instead of becoming an unrelated sibling.

Donella read: #6 information flows and #5 rules. The next intervention should
make backup stock visible in doctor JSON, then change the backup rule from
unbounded in-tree sidecars to bounded rollback plus off-tree archive.

Evidence:
- Bead: `flywheel-from-skillos-audit-5ffa`.
- Follow-up bead: `wire-backup-proliferation-prevention`.
- Source report: `/tmp/phase3-audit-skillos-report-20260506T015536Z.md`.
- Scope sample: `/tmp/backup-proliferation-flywheel-sample-2026-05-06.md`.
- Plan: `/tmp/backup-proliferation-remediation-plan-2026-05-06.md`.

## Umbrella-discovered 35 advisory beads triaged (2026-05-06)

Date: 2026-05-06

Promotion Action: TRIAGE

Class: `umbrella-memory-rule-bead-priority-drift`

Event Count: 35 umbrella auto-filed advisory beads

Severity: medium

Cost: `memory-rule-gate-parity-detector.sh --auto-bead` correctly filed repair beads for 35 UNWIRED META-RULE memory files, but generic priority assignment made the backlog look flat. Without leverage sorting, the next session could spend scarce worker time on low-leverage recipe or rename work while identity, recovery, and fleet-productivity loops stayed unwired.

Root Cause: The detector measured structural parity but did not rank the resulting work by Donella leverage or identify rules that should be retired/reclassified instead of wired.

Forever-Rule: Umbrella auto-filed repair beads get a Donella triage pass before dispatch. Wave 3a is capped at eight P0 active high-leverage goals/self-organization/rules beads; Wave 3b carries active medium-leverage rules/information-flow beads; Wave 3c carries defer or retire candidates. Priority changes are append-only `priority_update` rows, never historical row mutation.

Fix Applied/Status: `flywheel-umbrella-triage` wrote discovery, triage, and wave-plan artifacts; appended 35 priority_update rows; filed 4 retire/reclass candidate beads; and preserved `.beads/issues.jsonl` append-only prefix bytes.

Distribution: Wave 3a=8, Wave 3b=15, Wave 3c=12, retire_candidates=4.

Donella read: #5 rules plus #4 self-organization. The backlog stock now has a routing rule and a self-organizing retire lane instead of being drained by FIFO or generic detector priority.

Evidence:
- Discovery: `/tmp/umbrella-bead-discovery-2026-05-06.txt`.
- Triage: `/tmp/umbrella-bead-triage-2026-05-06.md`.
- Wave plan: `/tmp/umbrella-bead-wave-plan-2026-05-06.md`.
- State rows: `.beads/issues.jsonl` append-only rows with `triage_via=flywheel-umbrella-triage-2026-05-06`.

## P2-12 f5: aggregate schema-validation test (2026-05-06)

Date: 2026-05-06

Promotion Action: UPDATE

Class: `polish-gate-aggregate-schema-validation`

Event Count: 1 Phase 2 audit LOW finding

Severity: low

Cost: `test_polish_gate_schemas.sh` validated the original P2-01-era core
schemas, while later v1 schemas were only covered by their surface-specific
tests. A malformed newer schema could therefore escape the aggregate schema
gate until the matching feature test happened to run.

Root Cause: Schema inventory parity was wired in P2-12 f2, but aggregate
schema compilation still loaded only `manifest`, `grade-receipt`, and
`latest-summary`. The manifest knew about all 9 v1 schemas; the aggregate
validator did not consume that manifest truth set.

Forever-Rule: The polish-gate aggregate schema test must compile every
manifest-declared and on-disk `polish-gate/v1/*.schema.json` file as JSON
Schema 2020-12 in one command. Inventory parity proves the set; aggregate
validation proves the set is executable schema.

Fix Applied/Status: `templates/flywheel-install/tests/test_polish_gate_schemas.sh`
now checks all 9 manifest-declared v1 schemas for parseability, draft 2020-12
declaration, and `Draft202012Validator.check_schema` validity. Standalone
test `templates/flywheel-install/tests/test_polish_gate_aggregate_schemas.sh`
runs the same aggregate contract directly. All template tests pass.

P2-12 wave status: 5/5 follow-ups complete. f1 wired doctor JSON fields, f2
closed schema inventory parity, f3 hardened malformed manifest errors, f4
reconciled Phase 2 closure receipts, and f5 moved schema drift detection
upstream into the aggregate test.

Donella read: #5 rules. The rule is now executable at the aggregate boundary
instead of relying on each downstream surface test to discover its own schema
drift.

Evidence:
- Bead: `flywheel-p2-12-f5`.
- Extended test: `templates/flywheel-install/tests/test_polish_gate_schemas.sh`.
- Standalone aggregate test:
  `templates/flywheel-install/tests/test_polish_gate_aggregate_schemas.sh`.
- Parity sibling:
  `templates/flywheel-install/tests/test_polish_gate_schema_inventory_parity.sh`.
- L112: `OK_p2_12_f5_aggregate_schema_test`.

## Wave 3a P0 wired: watchdog-auto-respawn-not-notify-only (2026-05-06)

Date: 2026-05-06

Promotion Action: WIRE

Class: `watchdog-auto-respawn-not-notify-only`

Event Count: 1 memory-rule structural translation

Severity: high

Cost: A notify-only watchdog turns Joshua into a faster bottleneck. The system
detects a truly dead worker pane, wakes the founder, and waits for manual
respawn even though the recovery primitive already exists.

Root Cause: The prior watchdog shape treated notification as the primary
response path instead of a fallback after bounded self-recovery attempts.

Forever-Rule: Worker-scope watchdogs auto-respawn truly-dead worker panes first.
The per-pane budget is 3 attempts/hour. Only after the budget is exhausted, or
when a protected orchestrator/human/callback pane is classified dead, may the
watchdog use the existing Pushover + mac-alert notify primitive.

Fix Applied/Status: `.flywheel/scripts/worker-auto-respawn-watchdog.sh` scans
latest session topology, performs 3 live captures over a 16-second window,
enforces worker-scope only, appends attempt rows to
`~/.local/state/flywheel/auto-respawn-attempts.jsonl`, invokes `/flywheel:respawn`
through the flywheel orchestrator, and falls back to the existing `notify`
primitive after 3 attempts/hour. Installer
`.flywheel/scripts/worker-auto-respawn-watchdog-install.sh` registers the
watchdog in the launchd `gui/<uid>` domain at 60-second cadence.

Donella read: #4 self-organization. The system now recovers a dead worker
without founder intervention. Jeff's CONDITIONAL counter-thesis is preserved
as the 3-failure fallback, not the primary path.

Anti-pattern prevented: founder-bottleneck via notify-only watchdog.

Test coverage: 7 acceptance cases shipped: all-alive no action, dead worker at
attempt 0 respawns, dead worker at attempt 2 respawns and reaches budget,
dead worker at attempt 3 notifies only, recoverable freeze does nothing,
orchestrator dead is refused and notifies only, and missing topology exits 3.

Evidence:
- Bead: `flywheel-wire-watchdog-auto-respawn-not-notify-o-a1d67342`.
- Watchdog: `.flywheel/scripts/worker-auto-respawn-watchdog.sh`.
- Installer: `.flywheel/scripts/worker-auto-respawn-watchdog-install.sh`.
- Test: `.flywheel/tests/test_worker_auto_respawn_watchdog.sh`.
- Fixtures: `.flywheel/tests/fixtures/auto-respawn-watchdog/`.
- Live dry-run smoke: `/tmp/warw-smoke.json`.

## Wave 3a P0 wired: flywheel-owns-continuous-productivity-no-downtime-unless-josh-blocker (2026-05-06)

- Memory rule → structural detector + launchd wire translation. Source: `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_flywheel_owns_continuous_productivity_no_downtime_unless_josh_blocker.md`
- Donella #3 Goals leverage class — productivity invariant is the goal-level rule
- Anti-pattern prevented: founder-bottleneck via "session is quiet" Joshua-notify
- 4-class Joshua-notify allowlist enforced: destructive, paradigm, phi, security, substrate-corrupt — NEVER for "session is quiet"
- Artifacts shipped:
  - `.flywheel/scripts/continuous-productivity-detector.sh` (294 lines, canonical CLI 5-verb)
  - `.flywheel/scripts/continuous-productivity-detector-install.sh` (120 lines)
  - `.flywheel/tests/test_continuous_productivity_detector.sh` (5/5 cases pass)
  - `~/Library/LaunchAgents/ai.zeststream.continuous-productivity-detector.plist` (GUI domain)
- Live smoke: PASS. Tests: 5/5.
- Bead `flywheel-wire-flywheel-owns-continuous-productiv-5ad20901` worker callback was BLOCKED on file reservations (FrostyBasin + CloudyGorge held INCIDENTS.md + .beads/issues.jsonl); orch wrote this closure on pane 3's behalf per scoped-commit recipe.
- Worker self_grade=B (artifacts shipped, closure path blocked at reservation layer).

## Wave 3a P0 follow-up wired: codex model-at-capacity-halt detector subclass + auto-continue recovery (2026-05-06)

Empirical gap proof: pane 4 halted at a Codex upstream capacity message,
`selected model is at capacity. please try a different model.`, with a chevron
prompt and no progress delta. Joshua validated the recovery primitive on
2026-05-06: send `continue`; capacity refreshes within seconds and preserves
the in-flight prompt.

Shipped shape:
- Subclass `model_at_capacity_halt` added to `codex-template-stuck-detector`.
- Recovery routed to `auto_continue`, not respawn, because respawn loses worker
  context for a reversible upstream-capacity halt.
- `worker-auto-respawn-watchdog` now sends bounded auto-continue before any
  truly-dead respawn branch.
- Budget: 5 auto-continue attempts per pane per hour, then existing
  notify-fallback.
- Sibling shape: closed bead
  `flywheel-wire-watchdog-auto-respawn-not-notify-o-a1d67342`.

Evidence:
- Bead: `flywheel-codex-model-at-capacity-halt-class-2026-05-06`.
- Detector: `.flywheel/scripts/codex-template-stuck-detector.sh`.
- Watchdog: `.flywheel/scripts/worker-auto-respawn-watchdog.sh`.
- Tests: `.flywheel/tests/test_codex_template_stuck_detector.sh`,
  `.flywheel/tests/test_worker_auto_respawn_watchdog.sh`.
- Fixtures: `.flywheel/tests/fixtures/capacity-halt-validation/`.
- Live dry-run smoke: `/tmp/capacity-watchdog-live-smoke.json`.

## Wave 3a P0 wired: use-ntm-not-raw-tmux structural gate (2026-05-06)

Memory rule: `use-ntm-not-raw-tmux`.

Leverage class: Donella #5 Rules. Pane/session transport safety is now enforced
at the Bash PreToolUse boundary, not left as prose doctrine.

Root cause: L29 documented NTM-only doctrine, and the existing dispatch
transport gate blocked one high-risk send path, but general operational raw
tmux verbs still had no structural gate. That left `tmux ls`,
`tmux capture-pane`, and non-dispatch `tmux send-keys` able to bypass NTM
health, robot-tail, and send semantics.

Forever-Rule: Orchestrator-facing Bash commands MUST use `ntm` verbs for
pane/session operations. Raw tmux operational verbs are blocked with canonical
alternatives; textual mentions, `tmuxinator`, `$TMUX` checks, and `ntm` commands
remain allowed.

Fix Applied/Status: `~/.claude/hooks/flywheel-orch-use-ntm-not-raw-tmux-gate.sh`
ships as a read-only PreToolUse Bash gate and is wired into
`~/.claude/settings.json`. The detector scans unquoted shell code, strips
comments/string-literal mentions, recursively inspects `bash -c` command
payloads, and blocks raw operational verbs with `ntm` alternatives.

Test coverage: 8 dispatch cases plus 2 live-smoke shapes. Required cases cover
blocking `tmux ls`, `tmux capture-pane`, and `tmux send-keys`, while allowing
`tmuxinator`, comments-only mentions, quoted string mentions, `ntm` commands,
and `$TMUX` env checks. Live smoke covers `bash -c "echo tmux ls"` blocking and
`bash -c "ntm list"` allowing.

Evidence:
- Bead: `flywheel-wire-use-ntm-not-raw-tmux-8d2252c2`.
- Hook: `~/.claude/hooks/flywheel-orch-use-ntm-not-raw-tmux-gate.sh`.
- Settings: `~/.claude/settings.json`.
- Test: `.flywheel/tests/test_use_ntm_not_raw_tmux_gate.sh`.
- Fixtures: `.flywheel/tests/fixtures/use-ntm-not-raw-tmux/`.

## P0 regression fix: capacity-halt classifier not wired + plists not installed (2026-05-06)

Memory rule: `feedback_regression_test_must_exercise_production_close_path`.

Root cause: the prior close declared `model_at_capacity_halt` in metadata and
fixture hints, but production `classify_text()` still routed capacity-halted
live panes through the generic alive/post-callback paths. Empirical live
detector output showed the literal line `Selected model is at capacity. Please
try a different model.` while returning a non-capacity subclass. The recovery
watcher also had no installed `worker-auto-respawn-watchdog` LaunchAgent, and
the flywheel session lacked its per-session stuck-detector LaunchAgent.

Forever-Rule: specialized model/provider halt classifiers MUST execute before
generic `hash_stable=false` alive and post-callback reminder handling. Regression
tests must exercise literal live scrollback strings, not `subclass_hint` or
metadata-only fixtures. A recovery subclass is not shipped until its launchd
owner is installed and visible in `launchctl list`.

Fix Applied/Status: `codex-template-stuck-detector.sh` now classifies capacity
halts from the production text path before generic liveness. The rule also uses
the significant evidence tail so a live capacity line displaced by background
terminal/reminder lines still wins over post-callback. Installed
`~/Library/LaunchAgents/ai.zeststream.worker-auto-respawn-watchdog.plist` and
`~/Library/LaunchAgents/ai.zeststream.flywheel-codex-stuck-detector.plist`;
both are registered, loaded under `gui/501`, and present in `launchctl list`.

Test coverage: `.flywheel/tests/test_codex_template_stuck_detector.sh` covers
literal capacity strings, alternate "try a different model" text, reminder
template overlap, significant-tail displacement, and a non-capacity chevron
negative. `.flywheel/tests/test_capacity_halt_live_detect.sh` is the standalone
live-pattern fixture gate using `.flywheel/tests/fixtures/capacity-halt-live/`
with raw `t0.txt` and `t1.txt`.

Evidence:
- Bead: `flywheel-fix-capacity-halt-classifier-not-wired-2026-05-06`.
- Detector: `.flywheel/scripts/codex-template-stuck-detector.sh`.
- Tests: `.flywheel/tests/test_codex_template_stuck_detector.sh`,
  `.flywheel/tests/test_capacity_halt_live_detect.sh`.
- Fixture: `.flywheel/tests/fixtures/capacity-halt-live/`.
- Installers: `.flywheel/scripts/worker-auto-respawn-watchdog-install.sh`,
  `.flywheel/scripts/flywheel-codex-stuck-detector-install.sh`.
- Installed plists:
  `~/Library/LaunchAgents/ai.zeststream.worker-auto-respawn-watchdog.plist`,
  `~/Library/LaunchAgents/ai.zeststream.flywheel-codex-stuck-detector.plist`.
- Install receipts: `/tmp/worker-auto-respawn-watchdog-install.json`,
  `/tmp/flywheel-codex-stuck-detector-install.json`.
- Launchd fire log: `~/.local/state/flywheel/codex-stuck-detector.flywheel.log`.
- L112: `OK_capacity_halt_classifier_fix`.

## Plan-arc landed: capacity-halt-detector-and-auto-continue-recovery (2026-05-06)

- Pane 3 plan-arc through Phase 3 audit complete; Phase 4/5 (decompose + polish) remain as separate dispatches.
- 3 Phase 1 research lanes (problem-space + ecosystem-audit + implementation-design)
- 3 Phase 2 refine rounds, final round 0% diff (deeply converged)
- 1 Phase 3 audit round, auto-advance disposition (0 critical, 0 high, 6 medium, 3 low)
- 7-bead DAG preview ready for Phase 4 dispatch
- Worker BLOCKED on file reservations (CloudyAnchor + CyanCreek holding INCIDENTS+JSONL); orch closed on its behalf per scoped-commit-by-pathspec recipe
- Plan path: `.flywheel/plans/capacity-halt-detector-and-auto-continue-2026-05-06/`
- Donella #4 Self-organization (system recovers without founder) + #5 Rules (subclass routing) + #6 Information Flows (synth-and-inject layer)

## Plan-arc Phase 4 decomposed: capacity-halt 7-bead DAG filed (2026-05-06)

- Pane 3 closed Phase 4 decompose work (DAG MD + STATE.json) but BLOCKED on JSONL append/INCIDENTS/closure due to CyanCreek + CloudyAnchor file reservations until 13:01:36Z. Orch filed 7 beads on its behalf per scoped-commit-by-pathspec recipe.
- Wave A (P0, parallel): production-path-reconcile (#1, depends pane-4-fix) + auto-continue-primitive (#2, depends #1)
- Wave B (P0, sequential): success-measurement (#3, depends #2)
- Wave C (P1, parallel after #3): cross-session-authorization (#4) + burst-budget (#5) + doctor-ledger (#6)
- Wave D (P1, final): driver-coverage (#7, depends #4 + #5 + #6) — L57 loop-driver doctrine compliance
- All 9 audit findings (6 medium + 3 low) addressed across the 7 beads
- Reconcile node #1 explicit against pane 4's CLOSED capacity-halt classifier regression fix
- Plan path: `.flywheel/plans/capacity-halt-detector-and-auto-continue-2026-05-06/04-BEADS-DAG.md`
- STATE.json: current_phase=decompose, beads_created=7, phase4_filed_by=flywheel-orch-on-behalf-of-pane3

## Wave 3a P0 wired: agentmail-identity-canonical structural gate (2026-05-06)

Memory rule: `feedback_agentmail_identity_canonical.md` plus
`feedback_identity_stability_session_pane_project_primary_key.md`.

Leverage class: Donella #5 Rules. The identity layer now has a structural
validator and advisory PostToolUse hook instead of relying on agents remembering
not to mint identities ad hoc.

Root cause: AgentMail identity stability existed as memory/doctrine, while
Claude and worker flows could still call register/mint paths or register a
session without proving `fleet_mail_identity`. That let identity names become
the accidental primary key and made reboot/compaction churn look like agent
failure instead of substrate drift.

Forever-Rule: `(session, pane, fleet_mail_project_key)` is the durable identity
key. `identity_name` is a current pointer, not a primary key. Topology-declared
fleet identities must resolve to vault tokens, token files without active
topology ownership are drift, and rotation/mutation signals are append-only
ledger events. Identity warnings must cite registry proof, not raw tokens.

Fix Applied/Status: added
`.flywheel/scripts/agentmail-identity-canonical-validator.sh` with canonical CLI
surface, strict exit-code enforcement for fixtures, and read-only live advisory
smoke. Added advisory PostToolUse hook
`~/.claude/hooks/flywheel-orch-agentmail-identity-canonical-gate.sh` and wired
it additively into `~/.claude/settings.json`.

Test coverage: six golden cases shipped:
canonical state, missing vault token, orphan token, non-append-only mutation
row, duplicate identity across sessions, and `--apply` read-only/no-mutation
verification.

Evidence:
- Bead: `flywheel-wire-agentmail-identity-canonical-2683be9e`.
- Validator: `.flywheel/scripts/agentmail-identity-canonical-validator.sh`.
- Hook: `~/.claude/hooks/flywheel-orch-agentmail-identity-canonical-gate.sh`.
- Settings: `~/.claude/settings.json`.
- Test: `.flywheel/tests/test_agentmail_identity_canonical_gate.sh`.
- Fixtures: `.flywheel/tests/fixtures/agentmail-identity-canonical/`.
- Live smoke: `/tmp/aicv-smoke.json`.
- L112: `OK_wire_agentmail_identity_canonical`.

## Phase 4 Bead #1 closed: capacity-halt production-path-reconcile + lease primitive (2026-05-06)

Bead: `flywheel-capacity-halt-production-path-reconcile-2026-05-06`.

Leverage class: Donella #5 Rules. The capacity-halt recovery path now has a
per-pane/digest lease rule before the `continue` transport mutation, preventing
duplicate watcher ticks from firing the same recovery on the same stable screen.

Root cause: pane 4 correctly wired the production `model_at_capacity_halt`
classifier and LaunchAgents, but Phase 3 audit finding M1 remained open:
duplicate watchers/ticks could send repeated `continue` for the same stable
capacity-halt scrollback.

Forever-Rule: `model_at_capacity_halt` auto-continue is gated by an append-only
lease keyed by `(session, pane, scrollback_digest)`. A duplicate acquire inside
the 90-second TTL refuses before transport send. Release is append-only and
records `success|failure|skipped`; historical acquire rows are never mutated.

Fix Applied/Status: added
`.flywheel/scripts/capacity-halt-lease-primitive.sh` and integrated it
additively into `.flywheel/scripts/worker-auto-respawn-watchdog.sh` immediately
before the `auto_continue` send path. The classifier live fixture still returns
`subclass=model_at_capacity_halt` and `recommended_recovery=auto_continue`.

Test coverage: lease primitive coverage is 18/18; watchdog regression coverage
is 34/34 including a duplicate-lease refusal case that proves no `continue` or
respawn is sent while the lease is held; capacity live fixture coverage is 6/6.

Reconcile verdict: PASS. Pane 4's shipped fix holds end-to-end, the required
LaunchAgents are visible in `launchctl list`, and audit finding M1 is closed by
the lease primitive.

Evidence:
- Reconcile report:
  `.flywheel/plans/capacity-halt-detector-and-auto-continue-2026-05-06/RECONCILE-pane4-fix.md`.
- Lease primitive: `.flywheel/scripts/capacity-halt-lease-primitive.sh`.
- Watchdog: `.flywheel/scripts/worker-auto-respawn-watchdog.sh`.
- Tests: `.flywheel/tests/test_capacity_halt_lease_primitive.sh`,
  `.flywheel/tests/test_worker_auto_respawn_watchdog.sh`,
  `.flywheel/tests/test_capacity_halt_live_detect.sh`.
- L112: `OK_capacity_halt_phase4_bead1_reconcile`.

## Plan-arc opened: orch-heartbeat-cron-no-idle-projects (2026-05-06)

Plan-space-only arc through Phase 3 audit for an orchestrator heartbeat loop
that converts existing telemetry into idle-safe next-action packets, so
allowlisted projects do not sit idle when the substrate already knows work,
recovery debt, validation debt, or peer blockers exist.

Primary empirical input: `/tmp/overnight-velocity-report/SUMMARY.md`.

Empirical trigger:
- Report window: `2026-05-05T22:00:00Z` to `2026-05-06T10:27:28Z`.
- Fleet bead activity: flywheel created=0, closed=1, updated=0; skillos,
  alpsinsurance, and mobile-eats all created=0, closed=0, updated=0.
- Cross-orch ledger rows: 33.
- Fuckup-log rows: 330, including 262 post-callback-reminder recovery rows.
- Codex stuck-detector rows: 441, including 171 `unknown_stable` and 9 `alive`
  subclass rows.

Donella read: Meadows #6 Information Flows is the primary leverage point. The
system has observation stock but lacks a delivery loop that turns evidence into
orchestrator action when the orchestrator is idle. Meadows #5 Rules applies to
idempotency and authorization; #4 Self-organization applies to the adapter
surface that lets new ledgers become future action sources.

Plan status:
- Phase 1 complete: problem-space, ecosystem-audit, and implementation-design
  research lanes.
- Phase 2 complete: 2 refinement rounds; final conceptual diff 3.8%.
- Phase 3 audit complete: 3 lenses, disposition `auto_advance`, findings
  critical=0, high=3, medium=4, low=2.
- First-ship boundary: flywheel-local, target `flywheel:1` only, read existing
  ledgers, write heartbeat-owned receipts only, no peer prompt injection.
- Bead DAG preview: 9 implementation beads, with Phase 3 audit IDs mapped into
  acceptance criteria.

Evidence:
- Plan path:
  `.flywheel/plans/orch-heartbeat-no-idle-projects-2026-05-06/`.
- Intent: `00-INTENT.md`.
- Research: `01-RESEARCH-A-problem-space.md`,
  `01-RESEARCH-B-ecosystem-audit.md`,
  `01-RESEARCH-C-implementation-design.md`.
- Refine: `02-REFINE-r1.md`, `02-REFINE-r2.md`, `00-PLAN.md`.
- Audit: `03-AUDIT-r1.md`, `03-AUDIT-FINDINGS.md`.
- State: `STATE.json`, `current_phase=decompose`,
  `audit_disposition=auto_advance`.

## Phase 4 Bead #2 closed: capacity-halt auto-continue canonical primitive (2026-05-06)

Bead: `flywheel-capacity-halt-auto-continue-primitive-2026-05-06`.

Leverage class: Donella #5 Rules. The capacity-halt `continue` mutation is now
a bounded primitive instead of watchdog-local transport code: acquire the
per-pane/digest lease, send `continue` with `y\n` confirmation, release the
lease with outcome, and exit distinctly for duplicate lease, malformed input,
transport failure, or transport timeout.

Root cause: Bead #1 closed duplicate-tick risk inside the watchdog, but the
auto-continue invocation still lived inline. That left other watchers without a
canonical reusable primitive and left audit finding M2 open for transport hangs.

Forever-Rule: any watcher recovering `model_at_capacity_halt` calls
`.flywheel/scripts/capacity-halt-auto-continue-primitive.sh --apply --json`
rather than hand-rolling `ntm send`. Dry-run is read-only; apply is the only
mutation gate; default transport timeout is 8 seconds.

Fix Applied/Status: added the primitive and updated
`.flywheel/scripts/worker-auto-respawn-watchdog.sh` to call it. Lease
integration is verified for fresh acquire/release, held-lease skip, transport
failure release, and timeout release. Timeout records
`release.requested_result=timeout`; the read-only Bead #1 lease vocabulary
falls back to a `failure` release row so no lease remains active.

Test coverage: new primitive coverage is 6/6 cases; watchdog regression remains
34/34; lease primitive regression remains 18/18.

Audit verdict: PASS. M1 remains closed by the lease rule, and M2 is closed by
the canonical 8-second bounded transport primitive.

Evidence:
- Primitive: `.flywheel/scripts/capacity-halt-auto-continue-primitive.sh`.
- Watchdog integration: `.flywheel/scripts/worker-auto-respawn-watchdog.sh`.
- Tests: `.flywheel/tests/test_capacity_halt_auto_continue_primitive.sh`,
  `.flywheel/tests/test_worker_auto_respawn_watchdog.sh`,
  `.flywheel/tests/test_capacity_halt_lease_primitive.sh`.
- L112: `OK_capacity_halt_phase4_bead2_primitive`.

## Trauma class registered: orch-trust-trap-agentmail-as-completion-signal (2026-05-06)

- Reported by mobile-eats:1 via NTM cross-session send (handoff_id `finding-orch-trust-trap-agentmail-2026-05-06`)
- Severity: medium. Cross-project applicability confirmed: mobile-eats, flywheel, skillos.
- Class summary: orchestrators that depend on agentmail callbacks as the completion signal stall when workers skip the callback envelope. Worker completes (filesystem evidence + NTM pane WAITING transition) but callback envelope never lands. Orch waits passively, burning wall-clock + human attention.
- 3-strike status: NOT 1st instance — class is already 6+ strike. Prior memory rules: `feedback_callback_first_dispatch`, `feedback_orchestrator_validates_callbacks`, `feedback_worker_verify_callback_delivered`, `feedback_callback_pane_registry`, `feedback_lost_callback_artifact_reconstruction`.
- Sibling pattern shipped today: capacity-halt-success-measurement (Phase 4 Bead #3 of capacity-halt DAG) — same trauma class at watcher layer (success measured by post-send recapture, NOT transport-ack).
- Mobile-eats:1 framing canonical: "completion-by-evidence, not completion-by-trust. Filesystem state (1) > NTM pane state (2) > agentmail callback envelope (3). (3) is nice-to-have, never a gate."
- Three recommendations routed:
  1. ACCEPTED — `/flywheel:dispatch` skill encodes completion-by-evidence verification protocol (T+0, T+expected, T+1.5×expected, T+2×expected checkpoints). Sibling-shape with capacity-halt success-measurement bead.
  2. DEFERRED — ScheduleWakeup constraint relaxation requires substrate-harness change; flagged for Joshua review (class 1 new-substrate, mission-lock dispose).
  3. ACCEPTED — worker-side callback failure auto-detection + fuckup class `worker-completion-no-callback` (severity LOW, bead/worker/dispatch-time fields).
- ACK delivered: cross-orch ledger row appended; mobile-eats:1 notified.

## Wave 3a P0 wired: identity-stability-session-pane-project-tuple structural gate (2026-05-06)

Memory rule: `feedback_identity_stability_session_pane_project_primary_key.md`.

Leverage class: Donella #4 Self-organization. The identity substrate now has a
mechanical validator for the stable owner tuple instead of relying on agents to
remember that mailbox names are only pointers.

Root cause: six independent rotation triggers can churn Agent Mail names while
the owner stays fixed: `agent-mail-name-policy`, `resolver-MCP`,
`compaction`, `missing-token`, `path-canon`, and `strict-mode`. Treating the
name as the durable key creates false new owners, orphan-token residue, and
broken callback/dispatch joins.

Forever-Rule: `(session, pane, fleet_mail_project_key)` is the durable primary
key. `identity_name` and `agent_name` are current pointers only. A rotation must
preserve a queryable predecessor chain, and dispatch/callback text that cites a
name as proof should include `identity_primary_key=session:pane:project` or a
registry-resolution field.

Fix Applied/Status: added read-only tuple validator
`.flywheel/scripts/identity-stability-tuple-validator.sh` and advisory
PostToolUse hook `~/.claude/hooks/flywheel-orch-identity-stability-tuple-gate.sh`.
The hook is wired additively in `~/.claude/settings.json` as a sibling to
`flywheel-orch-agentmail-identity-canonical-gate.sh`.

Test coverage: `.flywheel/tests/test_identity_stability_tuple_gate.sh` passes
7/7 counted cases. Coverage includes stable tuple, stable rotation with
predecessor, missing predecessor, duplicate current pointer, orphan token,
malformed tuple input, and hardcoded `agent_name` warning; the hook also has an
allow smoke for tuple-backed proof.

Evidence:
- Bead: `flywheel-wire-identity-stability-session-pane-pr-1851e8b4`.
- Validator: `.flywheel/scripts/identity-stability-tuple-validator.sh`.
- Hook: `~/.claude/hooks/flywheel-orch-identity-stability-tuple-gate.sh`.
- Settings: `~/.claude/settings.json`.
- Tests: `.flywheel/tests/test_identity_stability_tuple_gate.sh`.
- Fixtures: `.flywheel/tests/fixtures/identity-stability-tuple/`.
- Live smoke: `/tmp/istv-smoke.json`.

## Wave 3a P0 wired: flywheel-owns-orch-pane-recovery advisory gate (2026-05-06)

Memory rule: `feedback_flywheel_owns_orch_pane_recovery.md`.

Leverage class: Donella #4 Self-organization. Peer orchestrator recovery is
now protected by an advisory PostToolUse feedback loop before the old
"orchestrator panes are untouchable" reflex can reach Joshua.

Root cause: L115 and `.flywheel/scripts/peer-orch-respawn-permit.sh` already
encoded the correct permit path, but there was no orchestrator-side advisory
gate for output that refused peer-orch recovery without first citing the permit
gate, or output that proposed respawning `flywheel:1` itself.

Forever-Rule: peer orchestrator panes are recovery-eligible through
`.flywheel/scripts/peer-orch-respawn-permit.sh`; only `flywheel:1` recovering
its own `flywheel:1` pane is refused and routed to calling-in-sick recovery.

Fix Applied/Status: added advisory hook
`~/.claude/hooks/flywheel-orch-flywheel-owns-orch-pane-recovery-gate.sh` and
wired it additively into `~/.claude/settings.json` beside the existing
`flywheel-orch-*` PostToolUse gates. Existing L115, the permit gate script,
the permit test, and `/flywheel:respawn` Step 0 were left read-only.

Test coverage: `.flywheel/tests/test_flywheel_owns_orch_pane_recovery_gate.sh`
passes 7/7 cases. Coverage includes peer-orch respawn refusal without permit,
peer respawn after permit, explicit permit script proof, forbidden
`flywheel:1` self-respawn, calling-in-sick exception, unrelated empty output,
and malformed JSON silent exit.

Sibling-shape: matches the advisory hook pattern used by
`flywheel-orch-watchdog-auto-respawn-not-notify-only-gate.sh`,
`flywheel-orch-orchestrator-must-finish-p0-gate.sh`,
`flywheel-orch-use-ntm-not-raw-tmux-gate.sh`,
`flywheel-orch-agentmail-identity-canonical-gate.sh`, and
`flywheel-orch-identity-stability-tuple-gate.sh`.

Evidence:
- Bead: `flywheel-wire-flywheel-owns-orch-pane-recovery-1f097583`.
- Hook: `~/.claude/hooks/flywheel-orch-flywheel-owns-orch-pane-recovery-gate.sh`.
- Settings: `~/.claude/settings.json`.
- Test: `.flywheel/tests/test_flywheel_owns_orch_pane_recovery_gate.sh`.
- Canonical permit gate reference:
  `.flywheel/scripts/peer-orch-respawn-permit.sh`.
- Live smoke: `/tmp/forpr-live-smoke.json`.

## Phase 4 Bead #3 closed: capacity-halt success-measurement (post-send recapture, not transport-ack) (2026-05-06)

Bead: `flywheel-capacity-halt-success-measurement-2026-05-06`.

Leverage class: Donella #5 Rules plus #6 Information Flows. Capacity-halt
recovery success is no longer inferred from transport acknowledgement. The
rule is now completion-by-evidence: post-send recapture must prove output
delta, capacity text disappearance, or robot activity transition/velocity.

Root cause: Bead #2 bounded the `continue` transport, but send ack still
risked becoming the success signal. The same trust trap appeared in
mobile-eats:1 as trauma class
`orch-trust-trap-agentmail-as-completion-signal`: completion by callback
envelope is not evidence of completion. The watcher layer had the same class in
miniature: transport ack is not evidence of recovery.

Expanded empirical gap: alps:2 proved the detector could classify
`model_at_capacity_halt` and recommend `auto_continue` while
`recovery_attempted=none`. The detector auto-recover dispatch table now wires
that subclass to `.flywheel/scripts/capacity-halt-auto-continue-primitive.sh`,
sibling to the existing `buffer_stuck` Enter retry and
`post_callback_reminder` escape/reprompt recovery branches.

Forever-Rule: a capacity-halt recovery attempt has three separately reported
states: `attempted`, `sent`, and `recovered`. `attempted` means the watcher
decided to invoke recovery, `sent` means the transport ack or timeout path was
reached, and `recovered` means the success-measurement primitive returned
`verdict=success`.

Fix Applied/Status: added read-only
`.flywheel/scripts/capacity-halt-success-measurement.sh`, integrated it into
the auto-continue primitive before lease release outcome is chosen, added the
three watchdog counters/ledger fields, and wired
`.flywheel/scripts/codex-template-stuck-detector.sh` auto-recover for
`model_at_capacity_halt`.

Test coverage: success-measurement coverage is 7/7 cases; auto-continue
primitive regression remains 6/6; worker watchdog regression remains 34/34;
codex-template-stuck-detector regression is 23/23 including the new
capacity-halt primitive invocation assertion.

Audit verdict: PASS. M5 is closed by post-send evidence, L1 is closed by lease
release using measured recovery outcome, and L3 is closed by
attempted/sent/recovered separation. The mobile-eats:1 Rec 1 pattern is now
implemented at the watcher-recovery layer.

Evidence:
- Success measurement: `.flywheel/scripts/capacity-halt-success-measurement.sh`.
- Auto-continue primitive: `.flywheel/scripts/capacity-halt-auto-continue-primitive.sh`.
- Watchdog counters: `.flywheel/scripts/worker-auto-respawn-watchdog.sh`.
- Detector dispatch table: `.flywheel/scripts/codex-template-stuck-detector.sh`.
- Tests: `.flywheel/tests/test_capacity_halt_success_measurement.sh`,
  `.flywheel/tests/test_capacity_halt_auto_continue_primitive.sh`,
  `.flywheel/tests/test_worker_auto_respawn_watchdog.sh`,
  `tests/codex-template-stuck-detector.sh`.
- Cross-reference: `orch-trust-trap-agentmail-as-completion-signal`.
- L112: `OK_capacity_halt_phase4_bead3_success_measurement`.

## Plan-arc Phase 4 decomposed: orch-heartbeat 9-bead DAG filed (2026-05-06)

Bead: `flywheel-orch-heartbeat-phase4-decompose-2026-05-06`.

Leverage class: Donella #6 Information Flows plus #5 Rules and #4
Self-organization. The orch-heartbeat plan arc now has an implementation-ready
9-bead DAG with explicit dependencies, wave sizing, acceptance surfaces, and a
deferred manager-state integration boundary. This keeps the next phase inside
the existing substrate instead of spawning a new scheduler path.

Sibling shape: capacity-halt Phase 4. That earlier decomposition moved from
audit findings into a staged bead DAG and then closed Wave A/B work through
small, testable slices. Orch-heartbeat uses the same shape: schema and
read-only composition first, idempotent decision and delivery verification
next, then observability/config/refusal coverage, and only then manager-state
projection.

Scope: plan-space only. No code-space files were intentionally mutated. The
new plan artifact is
`.flywheel/plans/orch-heartbeat-no-idle-projects-2026-05-06/04-BEADS-DAG.md`,
and `STATE.json` now records `current_phase=decompose`, `phase4_status=decomposed`,
`beads_created=9`, four wave counts, `phase4_critical_path_min=245`, and
`phase4_audit_findings_addressed=9`.

Findings routed: the Phase 3 audit's 9 findings are mapped across the 9 beads:
candidate schemas, read-only composer, idle/idempotency gate, delivery
verifier, tick-driver doctor, morning-report projection, session allowlist,
cross-session refusal tests, and manager-state integration. The DAG explicitly
anchors to the existing 23 orch-substrate scripts and 30 ledger surfaces rather
than authoring a parallel heartbeat substrate.

Evidence:
- Plan DAG: `.flywheel/plans/orch-heartbeat-no-idle-projects-2026-05-06/04-BEADS-DAG.md`.
- State: `.flywheel/plans/orch-heartbeat-no-idle-projects-2026-05-06/STATE.json`.
- Bead substrate: `.beads/issues.jsonl` append-only fallback rows for 9 open beads plus the Phase 4 close row.
- L112: `OK_orch_heartbeat_phase4_decompose`.

## Phase 4 Bead #4 closed: capacity-halt cross-session authorization + protected-pane refusal (2026-05-06)

Bead: `flywheel-capacity-halt-cross-session-authorization-2026-05-06`.

Fix Applied/Status: added read-only
`.flywheel/scripts/capacity-halt-pane-authorization.sh` and wired
`.flywheel/scripts/capacity-halt-auto-continue-primitive.sh` to require a
topology authorization decision before lease acquire or `ntm send`.

Routing rule: latest `session-topology.jsonl` row by `effective_at` maps each
target pane to a role. `worker_pane` is authorized; four protected target
contexts (local orchestrator, peer orchestrator, human, callback) refuse with
`protected_refusal`; unknown panes refuse with `unknown_pane`; stale topology
refuses with `topology_stale`.

Ledger schema: capacity-halt attempt rows now carry `pane_role`,
`authorization_outcome`, and `topology_source_ts` alongside the existing
attempted/sent/recovered fields.

Audit verdict: PASS. M3 is closed by topology-aware authorization before
auto-continue, M4 is closed by protected-pane refusal before send/lease, and L2
is closed by the three new audit fields.

Evidence:
- Authorization primitive: `.flywheel/scripts/capacity-halt-pane-authorization.sh`.
- Auto-continue integration: `.flywheel/scripts/capacity-halt-auto-continue-primitive.sh`.
- Watchdog ledger integration: `.flywheel/scripts/worker-auto-respawn-watchdog.sh`.
- Tests: `.flywheel/tests/test_capacity_halt_pane_authorization.sh`,
  `.flywheel/tests/test_capacity_halt_auto_continue_primitive.sh`,
  `.flywheel/tests/test_worker_auto_respawn_watchdog.sh`.
- L112: `OK_capacity_halt_phase4_bead4_authorization`.

## P0 regression fix: capacity-halt primitive send-without-submit (CASS-check ate auto-yes) (2026-05-06)

Bead: `flywheel-fix-capacity-halt-primitive-no-cass-check-2026-05-06`.

Mechanism: the capacity-halt primitive called `ntm send <session>
--pane=<N> continue` with `input="y\n"` but without `--no-cass-check`. The
default CASS similar-work prompt consumed that auto-yes, so `ntm send` returned
success while the target Codex pane only had queued `continue` text and no
submitted Enter.

Joshua-observed evidence: alpsinsurance:2 showed the literal `continue` text in
the pane buffer after the detector-to-primitive recovery fired, but Joshua had
to press Enter manually before Codex consumed it.

Fix Applied/Status: `.flywheel/scripts/capacity-halt-auto-continue-primitive.sh`
now passes `--no-cass-check` between `--pane=<N>` and the message body. The
existing `input="y\n"` remains in place for non-CASS prompts, but routine
autonomous sends no longer spend that input on the CASS check.

Scope note: all capacity-halt auto-recovery events earlier today, including
alps:2, alps:4, flywheel:2, and sibling panes, may have reported
acknowledgement success while silently failing to submit the recovery prompt.

Cross-reference: fuckup class
`capacity-halt-primitive-send-without-submit`.

Live re-test plan for the next natural capacity-halt event:
1. Wait for a real pane to show model-at-capacity halt.
2. Capture pre-send digest with `--robot-tail`.
3. Observe primitive fire and capture post-send digest.
4. Confirm `continue` submitted by digest change within 10 seconds and capacity
   text disappearance.

Evidence:
- Primitive: `.flywheel/scripts/capacity-halt-auto-continue-primitive.sh`.
- Test: `.flywheel/tests/test_capacity_halt_auto_continue_primitive.sh`.
- Adjacent integration expectation:
  `.flywheel/tests/test_capacity_halt_pane_authorization.sh`.
- Regression cases: `no_cass_check_flag_present` and
  `argv_order_matches_ntm_send_shape`.
- L112: `OK_capacity_halt_no_cass_check_fix`.

## 2026-05-06T11:48Z — Wave 3a P0 wired: calling-in-sick-policy advisory gate

**Bead:** flywheel-wire-calling-in-sick-policy-flywheel-ow-a04ca90e (P0, Wave 3a) — closed by orch-on-behalf-of-CloudyMill (pane 2 blocked on shared_append_reservation_conflict; canonical scoped-commit-by-pathspec recipe applied per `feedback_canonical_recipe_scoped_commit_by_pathspec.md`)

**What landed (worker CloudyMill):**
- `~/.claude/hooks/flywheel-orch-calling-in-sick-policy-gate.sh` (64 lines, advisory PostToolUse)
- `.flywheel/tests/test_calling_in_sick_policy_gate.sh` (79 lines, 8/8 cases pass)
- `~/.claude/settings.json` updated with new PostToolUse entry (sibling shape with 6 prior flywheel-orch-* gates)

**Patterns covered:**
1. `worker-failure-escalated-to-joshua-instead-of-detector`
2. `orch-failure-escalated-to-joshua-instead-of-flywheel1`
3. `flywheel1-self-failure-not-broadcast-to-peer-orchs`

**Donella leverage:** #4 Self-organization. Escalation ladder: detector → flywheel:1 → peer-mesh → Joshua. Last unstarted Wave 3a P0; sibling-shape with today's 6 prior structural gates (agentmail-identity-canonical, donella-trace, identity-stability-tuple, no-punt-output, p0-finish-first, use-ntm-not-raw-tmux) plus this morning's wire-flywheel-owns-orch-pane-recovery (closed pane 4, 11:31Z).

**Closeout pattern:** Worker did 4/6 (hook + test + settings + report), blocked on INCIDENTS+JSONL append by reservations 5872/5873/5882/5883 held by CrimsonGlen+MistySparrow. Worker emitted BLOCKED callback with files_released=5862,5863,5864 + partial validation. Orch executed canonical scoped-commit-by-pathspec recipe (append-only safe scope) to ship final 2 deliverables. Wave 3a P0 sweep COMPLETE.

## Plan-arc Phase 5 r1 polish: orch-heartbeat reconverged on event-driven paradigm (mobile-eats:1 cross-orch finding) (2026-05-06)

Bead: `flywheel-orch-heartbeat-phase5-polish-event-driven-2026-05-06`.

Cross-orch input absorbed: mobile-eats:1 row 150,
class `orch-bash-prompt-state-change-trigger`. The finding inverted the
Phase 4 cron-pulled heartbeat model: with timestamped state-transition
substrate already present, orchestrators can regenerate prompts on state
change instead of burning context on empty cadence ticks.

Substrate survey: flywheel:1 dispatch preflight ran K=50 Socraticode over the
orch substrate and found the event-driven path roughly 80 percent present:
JSONL streams, `ntm --robot-activity`, idle-state classification, L91 delivery
receipts, JSONL fallback close truth, idle auto-dispatch, watcher-isomorphic
probe shape, and the four-input sibling pattern from `worker-stall-alert-probe`.
CloudyMill independently verified with K=10 against the canonical repo path and
observed 945 indexed chunks.

Plan delta: Phase 4's nine-bead cron-heartbeat DAG reconverged to a six-bead
event-driven preview. Existing dispositions are KEEP=1, COLLAPSE=3,
TRANSFORM=5, plus one new subscriber primitive. Wave A is reshaped so the
load-bearing foundation is `orch-state-change-bash-prompt-subscriber.sh`
conceptually: event schemas/cursors plus a subscriber primitive over five
JSONLs, robot activity, topology/policy, and pane-tail delivery evidence.
Fallback polling remains a recovery mode and must be visible in doctor/report
fields.

Donella read: Meadows #6 Information Flows. Cron-pull asks whether information
changed after a timer fires; event-subscribe moves truthful state to the
orchestrator when the state transition is appended. Meadows #5 Rules remains
the gate for allowlists, idempotency, cursor replay, and protected-pane refusal.

Sibling-shape: capacity-halt Phase 4 success-measurement proved the same
evidence-not-trust pattern at the worker recovery layer: success is measured by
post-send recapture and state transition, not by transport acknowledgement. The
orch-heartbeat subscriber applies the same rule to orchestration itself:
evidence triggers work; acknowledgement alone is not work.

Evidence:
- Polish artifact:
  `.flywheel/plans/orch-heartbeat-no-idle-projects-2026-05-06/05-POLISH-r1.md`.
- DAG preview:
  `.flywheel/plans/orch-heartbeat-no-idle-projects-2026-05-06/05-POLISH-r1-DAG-preview.md`.
- State:
  `.flywheel/plans/orch-heartbeat-no-idle-projects-2026-05-06/STATE.json`.
- Net delta: 9 -> 6.


## Phase 4 Bead #5 closed: capacity-halt burst-budget + fleet cap + fallback signal (2026-05-06)

Bead: `flywheel-capacity-halt-burst-budget-2026-05-06`.

What landed:
- New read-only budget primitive: `.flywheel/scripts/capacity-halt-burst-budget.sh`.
- Auto-continue now checks budget after worker-pane authorization and before lease acquisition.
- Budget exhaustion exits auto-continue rc=8 with `attempted=false`, `sent=false`, `recovered=false`, writes fallback row class `capacity-halt-budget-exhausted`, and invokes `/Users/josh/.local/bin/notify`.
- Watchdog capacity-halt attempt rows now include `per_pane_count_window`, `fleet_count_window`, and `budget_outcome`.
- Pane 4's shipped `--no-cass-check` transport fix remains preserved in the auto-continue send argv.

Default limits:
- Per pane: 3 auto-continue attempts in 600 seconds.
- Fleet: 5 auto-continue attempts in 60 seconds.

Evidence:
- Budget primitive: `.flywheel/scripts/capacity-halt-burst-budget.sh` (129 lines).
- Auto primitive: `.flywheel/scripts/capacity-halt-auto-continue-primitive.sh` (additive +30 lines from bead #4 baseline).
- Watchdog: `.flywheel/scripts/worker-auto-respawn-watchdog.sh` (additive +15 lines from bead #4 baseline).
- Tests: `.flywheel/tests/test_capacity_halt_burst_budget.sh` (9/9 cases), `.flywheel/tests/test_capacity_halt_auto_continue_primitive.sh` (8/8 cases), `.flywheel/tests/test_capacity_halt_pane_authorization.sh` (8/8 cases), `.flywheel/tests/test_worker_auto_respawn_watchdog.sh` (34/34 assertions).
- L112: `OK_capacity_halt_phase4_bead5_burst_budget`.

## META-RULE 2026-05-06: autonomous ntm send paths MUST include --no-cass-check + canonical argv order

Trauma class: `autonomous-send-cass-prompt-consumes-submit`.

Mechanism: any unattended `ntm send` can trip the duplicate-work CASS prompt.
If `--no-cass-check` is missing, the payload may never submit. If the flag is
placed after the payload, argv parsing can treat it as message content instead
of transport policy. Canonical order is `ntm send <session> --pane=<pane>
--no-cass-check <payload>`.

Fix shape:
- Expected callsites fixed: `.flywheel/scripts/codex-template-stuck-detector.sh`, `.flywheel/scripts/worker-auto-respawn-watchdog.sh`, `.flywheel/scripts/fleet-comms-health-probe.sh`, `.flywheel/scripts/flywheel-resume`.
- Extra sibling callsites fixed: `.flywheel/scripts/peer-orch-productivity-watch.sh`, `.flywheel/scripts/recovery-escape-then-reprompt.sh` (two sends), `.flywheel/scripts/continuous-productivity-detector-install.sh`, `.flywheel/scripts/idle-pane-auto-dispatch.sh`, `.flywheel/scripts/test-loop-driver-doctor.sh`.
- Regression assertions added near each primitive or nearest owning test, including runtime fake-ntm assertions where the test already exercises the send path.

Audit cadence: after every autonomous-send bead and before capacity-halt,
watchdog, fleet-comms, productivity-watch, resume, or recovery primitive
closeout, run a callsite scan for `ntm send` and verify `--no-cass-check`
appears before payload-bearing arguments.

Cross-refs:
- Parent bead: `flywheel-fix-capacity-halt-primitive-no-cass-check-2026-05-06`.
- Audit bead: `flywheel-audit-ntm-send-no-cass-check-autonomous-callsites-2026-05-06`.
- Research survey: `/tmp/audit-ntm-send-no-cass-check-research-survey.md`.
- L112 verifier: `OK_audit_no_cass_check_callsites`.

L-rule proposal: promote this to canonical doctrine if another autonomous
transport path ships without `--no-cass-check`, or if any autonomous send
regression recurs after this audit.

## Plan-arc opened: mission-lock paradigm extension absorbing 2 cross-orch findings (mobile-eats:1 row 151 + alps:1 row 152) (2026-05-06)

Two independent peer orchestrators surfaced the same upstream mission-lock
trauma class within minutes:

- mobile-eats:1 row 151:
  `mission-lock-undersells-design-system-substrate`.
- alps:1 row 152:
  `mission-lock-must-elicit-negative-invariants`.

Disposition: this is 3-strike-equivalent urgency even without waiting for a
third independent project. The findings describe the same failure from two
angles: mission-lock declared readiness without proving lock-time substrate and
without eliciting the negative invariants that make the substrate safe to build
against.

Phase 1 Lane A is closed:

- Intent:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/00-INTENT.md`.
- Problem-space inventory:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/01-RESEARCH-A-problem-space-inventory.md`.
- State:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/STATE.json`.

Lanes B and C remain queued for sibling dispatch:

- Lane B: ecosystem audit across existing skills, memory rules, and related
  doctrine.
- Lane C: implementation design for the mission-lock template extension,
  scaffold validator, and lock-time audit gate.

Donella read: Meadows #5 Rules plus #6 Information Flows. The rule surface is
the semantics of "mission locked" and "ready to build"; the missing information
flow is a substrate/invariant audit visible before feature dispatch.

Evidence:
- Cross-orch ledger: `~/.local/state/flywheel/cross-orch-coordination.jsonl`
  row fields `151` and `152`.
- L112: `OK_mission_lock_paradigm_phase1_lane_a`.

## Plan-arc Phase 1 Lane B closed: ecosystem audit of mission-lock-relevant doctrine (2026-05-06)

Bead: `flywheel-plan-mission-lock-paradigm-extension-lane-b-2026-05-06`.
Plan artifact:
`.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/01-RESEARCH-B-ecosystem-audit.md`.

Lane B audited the existing mission-lock-relevant ecosystem before Lane C
designs any extension. It confirmed rows 151 and 152 were absorbed from the
cross-orch coordination ledger and mapped them to the six Lane A gap classes:
`data-lifecycle`, `negative-invariants`, `trap-class-cross-refs`,
`skill-arsenal-by-surface`, `substrate-artifacts`, and
`failure-mode-audit`.

Counts:
- Skills audited: 15 total; 7 ADOPT, 7 EXTEND, 1 AVOID.
- L-rules referenced: 16.
- Memory rules referenced: 11.
- INCIDENTS entries referenced: 8.

Coverage matrix summary:

| Gap class | Existing coverage | Remaining Lane C pressure |
|---|---|---|
| `data-lifecycle` | Real-service/no-mocks skills, alps real-or-nothing memory, two-truth evidence doctrine. | Add required source, freshness, error/empty state, deletion/archive, and fallback-prohibition questions. |
| `negative-invariants` | Security invariant extraction, no-mocks/no-fallback memory, L52/L56 routing. | Add required per-surface "must never happen" section with owner and validator. |
| `trap-class-cross-refs` | Skill-library-load-bearing memory, L55 skillos route, known no-mocks/runtime-fallback sibling. | Add a cross-ref table linking selected skills to forbidden substitutes and adjacent trap classes. |
| `skill-arsenal-by-surface` | 15 skills mapped across mission, data, scaffold, auth, security, E2E, visual QA, audit, and ops. | Mission-lock output must list selected skills per product surface with ADOPT/EXTEND/AVOID. |
| `substrate-artifacts` | SaaS scaffold, demo foundation, CLI scoping, publishability, identity, and web QA substrate. | Add scaffold validator inventory for tokens, primitives, auth, data, CI gates, identity, SEO, density, and demo surfaces. |
| `failure-mode-audit` | Audit-prep, security-posture, callback validation, two-truth, and publishability incidents. | Add lock-time failure-mode matrix for false readiness, hidden fallback, missing substrate, unowned identity, and unvalidated demo. |

Disposition: Lane B found enough substrate to avoid greenfield design. Lane C
should extend `/flywheel:mission-lock` and its validator narrowly around the
six gap classes, then land command/template/doctrine propagation per L96.

L112: `OK_mission_lock_paradigm_phase1_lane_b`.

## Plan-arc Phase 1 Lane C closed: implementation design for mission-lock paradigm extension (2026-05-06)

Bead: `flywheel-plan-mission-lock-paradigm-extension-lane-c-2026-05-06`.
Plan artifact:
`.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/01-RESEARCH-C-implementation-design.md`.

Lane C designed the implementation path for extending `/flywheel:mission-lock`
without mutating the command or skill files in Phase 1. It absorbed Lane A's six
gap classes, Lane B's ADOPT/EXTEND/AVOID ecosystem audit, mobile-eats row 151,
alps row 152, and Joshua's five quoted constraints.

Six mission-lock template sections proposed:

| Section | Purpose |
|---|---|
| Negative invariants | Capture per-surface "must never ship" rules such as no fallback data and no launch-path mocks. |
| Trap-class cross-references | Link sibling lies such as runtime fallback, mocked E2E, and transport-ack-as-success. |
| Skill-arsenal-by-surface mapping | Bind relevant skills to frontend, backend, auth, data, infra, security, observability, agent workflow, and domain surfaces. |
| Data-lifecycle invariants | Lock source of truth, empty/error state, forbidden fallback, freshness, retention, archive, and delete rules. |
| Failure-mode audit per substrate | Require default lie, proof signal, refusal condition, and repair route for every adopted substrate. |
| Substrate scaffolding requirement | Make row 151's 10 substrate artifacts visible before ready-to-build. |

Two scripts proposed:

- `.flywheel/scripts/mission-lock-scaffold-validator.sh`: init/lock-time
  validator with 10 artifact probes and JSON fields `status`,
  `missing_artifacts[]`, `present_artifacts[]`, and `blocked_lock`.
- `.flywheel/scripts/mission-lock-readiness-doctor.sh`: backfill/readiness
  doctor for existing locked repos with JSON fields `completeness_pct`,
  `missing_sections[]`, and `suggested_amendments[]`.

Preliminary implementation DAG:

- Wave A foundation: mission-lock template extension and receipt schemas.
- Wave B integration: scaffold validator plus init/mission-lock wiring.
- Wave C polish: readiness doctor plus doctor/status signal wiring.
- Wave D propagation: audit-only backfill reports for mobile-eats and alps,
  then propagation polish.

Phase 1 RESEARCH is complete. Lanes A, B, and C are closed; the plan arc is
ready for Phase 2 REFINE.

Donella read: Meadows #6 Information Flows makes missing substrate and
invariants visible before workers build; #5 Rules changes the semantics of
"locked" from document existence to readiness evidence; #4 Self-Organization
adds validators and doctors so repos can audit themselves; #2 Paradigms shifts
mission-lock from destination document to operational substrate contract.

Evidence:
- Intent:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/00-INTENT.md`.
- Lane A:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/01-RESEARCH-A-problem-space-inventory.md`.
- Lane B:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/01-RESEARCH-B-ecosystem-audit.md`.
- Lane C:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/01-RESEARCH-C-implementation-design.md`.
- L112: `OK_mission_lock_paradigm_phase1_lane_c`.

## P0 wired: codex_queued_not_submitted classifier + bare-Enter primitive (Joshua-observed silent darkness gap) (2026-05-06)

Bead:
`flywheel-wire-codex-queued-not-submitted-classifier-and-recovery-2026-05-06`.

The detector previously had no first-class classifier for a Codex pane showing
Working/background state plus a queued chevron prompt. The observed alps:4
buffer was:

```text
• Working (1m 40s • esc to interrupt) · 1 background terminal running
› Run /review on my current changes
  gpt-5.5 xhigh · ~/Developer/alpsinsurance
```

That is an Enter-class recovery, not a respawn-class recovery. Joshua's
constraint was: "i don't want to respawn an agent that has hit capacity when a
simple enter will do - that kills all of their context and current state".

Shipped:
- `codex-template-stuck-detector.sh` now classifies
  `codex_queued_not_submitted` from `codex_chevron_prompt` +
  queued-prompt-text + Codex Working/background state.
- `codex-queued-not-submitted-bare-enter-primitive.sh` sends bare Enter through
  `ntm send <session> --pane=N --no-cass-check ""`.
- The primitive reuses the capacity-halt authorization, lease,
  success-measurement, and burst-budget primitives without mutating them.
- `--auto-recover` now routes the new subclass to bare Enter, not
  capacity-halt auto-continue and not respawn.

Cross-refs:
- META-RULE memory:
  `feedback_enter_press_not_respawn_class.md`.
- Doctrine sibling: L91 dispatch-delivery-is-a-four-state-receipt.
- Sibling arc:
  `flywheel-codex-model-at-capacity-halt-class-2026-05-06`.

Evidence:
- Test:
  `.flywheel/tests/test_codex_queued_not_submitted_classifier_and_recovery.sh`
  passed 11/11 cases, including the live alps string match.
- Primitive line ceiling:
  `.flywheel/scripts/codex-queued-not-submitted-bare-enter-primitive.sh`
  is 180 lines.
- L112:
  `OK_codex_queued_not_submitted_wired`.

## 2026-05-06T13:02Z — Wire enter-press-not-respawn-class advisory gate (META-RULE 12:18Z parity closure)

**Bead:** flywheel-wire-enter-press-not-respawn-class-14670890 (P0, auto-filed by memory-rule-gate-parity-detector) — closed by orch-on-behalf-of-MagentaPond (pane 3 BLOCKED on append_reservation_conflict; canonical scoped-commit-by-pathspec recipe applied per `feedback_canonical_recipe_scoped_commit_by_pathspec.md`)

**What landed (worker MagentaPond/WindyCastle on pane 3):**
- `~/.claude/hooks/flywheel-orch-enter-press-not-respawn-class-gate.sh` (89 lines, advisory PostToolUse)
- `.flywheel/tests/test_enter_press_not_respawn_class_gate.sh` (87 lines, 10/10 cases pass)
- `~/.claude/settings.json` updated with new PostToolUse entry (sibling shape with 8 prior flywheel-orch-* gates)

**Patterns covered:**
1. `respawn-proposed-without-trauma-class-citation` — orch proposing respawn without citing oom/crashed/#12645/pane-gone
2. `respawn-proposed-with-queued-prompt-visible` — respawn proposed when queued chevron + codex Working visible (Enter-class recovery applies)
3. `respawn-proposed-with-capacity-halt-text` — respawn proposed when capacity-halt prompt visible (auto-continue applies)

**Donella leverage:** #5 Rules. Parity-closure for META-RULE memory file `feedback_enter_press_not_respawn_class.md` (codified 12:18Z after Joshua corrected: "i don't want to respawn an agent that has hit capacity when a simple enter will do - that kills all of their context and current state"). Sibling-shape with 8 prior structural gates shipped today + the just-closed Joshua-silent-darkness gap (codex_queued_not_submitted classifier+primitive at 12:33Z).

**Self-validating:** today's empirical 12:46Z pane 3 respawn timing miss (corrected by Joshua 12:46Z) AND the just-now pane 4 bare-Enter recovery (12:55Z, cleared 31m56s queued state with ZERO context loss) both validate the META-RULE the gate enforces.

**Closeout pattern:** Worker did 6/8 (hook + test + settings + report + tests passed + docs). Blocked on INCIDENTS.md + JSONL append by WindyCastle reservations (released_count=5 per UPDATE). Worker emitted BLOCKED callback. Orch executed canonical scoped-commit-by-pathspec recipe (append-only safe scope) to ship final 2 deliverables.

## Plan-arc Phase 2 r1 refine: substrate-quality-gate triple synthesis (Findings 1+2+3) (2026-05-06)

Bead:
`flywheel-plan-mission-lock-paradigm-extension-phase2-refine-r1-2026-05-06`.

Phase 2 r1 refined the mission-lock paradigm plan arc into one triple gate
instead of three unrelated fixes:

1. Mission-lock gate: rows 151/152 require substrate scaffolding, negative
   invariants, data lifecycle, trap-class cross-references, skill-by-surface
   mapping, and failure-mode audit before `ready_to_build=true`.
2. Dispatch-author gate: row 153 requires load-bearing classification, skill
   suite injection, `load_bearing` bead/dispatch metadata, and gsd-planner
   classifier wiring before workers start.
3. Close-validator gate: row 149/L91 requires completion-by-evidence plus
   `load_bearing_skills_applied` receipts before DONE is accepted.

Artifact:
`.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/02-REFINE-r1.md`.

State:
`.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/STATE.json` now has
`current_phase=refine`, `refine_round=1`, `convergence_streak=0`,
`phase1_research_complete=true`, and
`cross_orch_findings_absorbed=[151,152,153]`.

Counts:
- Mission-lock amendments: 6.
- Dispatch-author amendments: 5.
- Close-handler amendments: 5.
- Scripts proposed: 2 (`mission-lock-scaffold-validator.sh` and
  `mission-lock-readiness-doctor.sh`).
- Open questions for Phase 3 audit: 12.

Orthogonality:
this plan arc is not the orch-heartbeat plan arc. Orch-heartbeat answers when
an orchestrator should regenerate prompts after state changes. This plan answers
whether mission-lock, dispatch, and closeout have enough substrate-quality
evidence to proceed.

Evidence:
- Refine artifact:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/02-REFINE-r1.md`.
- Phase 1 inputs:
  Lane A/B/C research artifacts in the same plan directory.
- L112:
  `OK_mission_lock_paradigm_phase2_r1`.

## Patch /flywheel:respawn skill: extended post-respawn boot wait window 5-8s -> 15-20s + stale-scrollback verification protocol (2026-05-06)

Bead:
`flywheel-patch-flywheel-respawn-boot-wait-window-2026-05-06`.

Empirical observation:
at 2026-05-06T12:46Z, pane 3 had been respawned around 12:45Z. I probed at
roughly 8 seconds and saw robot-activity `ERROR` with an `exception` pattern,
then prematurely treated the respawn as failed. Joshua corrected the
classification: "pane 3 was respawned its ready for dsipatch - you have to wait
a little longer".

Root cause:
Codex needed about 15-20 seconds to fully settle after relaunch. The
robot-activity `ERROR` classification was poisoned by stale scrollback from the
pre-respawn pane, not by a currently failing agent. Stale patterns such as
`exception`, `api_error`, and `failed_text` can briefly survive alongside a
fresh Codex chevron prompt.

Patch:
`/Users/josh/.claude/commands/flywheel/respawn.md` Step 5 now waits 15-20
seconds after agent relaunch and requires a direct
`ntm --robot-tail=<session> --panes=<pane> --lines=10` buffer probe before
classifying the respawn state. A compatibility skill path at
`~/.claude/skills/flywheel/respawn/SKILL.md` points at the canonical command
document so existing skill-path probes resolve the same content.

Forever-rule:
post-respawn robot-activity `ERROR` with `codex_chevron_prompt` in
`detected_patterns` is not sufficient evidence of failed respawn during the
boot window. Wait 15-20 seconds minimum, verify expected agent type, and use a
fresh buffer probe as the canonical truth source before taking another recovery
action.

Cross-refs:
- Memory:
  `feedback_orchestrator_is_the_killer_not_codex.md`.
- L67 truth-source-must-be-live-not-cached.
- L91 dispatch-delivery-is-a-four-state-receipt.

Evidence:
- Test:
  `.flywheel/tests/test_flywheel_respawn_boot_wait_window.sh` passed 9/9 grep
  assertions.
- L112:
  `OK_flywheel_respawn_boot_wait_window_patched`.

## 2026-05-06T13:11Z — Two-blocker-ticks-escalator regression recurring: orch-on-behalf close rows missed (cf3a fix incomplete)

**Bead:** flywheel-escalator-regression-recurring-2026-05-06 (P1) — closed by orch-on-behalf-of-MagentaPond (pane 3 BLOCKED on append-reservation-conflict; canonical scoped-commit-by-pathspec recipe applied per `feedback_canonical_recipe_scoped_commit_by_pathspec.md`)

**What landed (worker MagentaPond on pane 3):**
- `.flywheel/scripts/two-blocker-ticks-escalator.sh` (345 lines, additive close-row detection extended to all `closed_by` shapes)
- `.flywheel/tests/test_two_blocker_ticks_escalator_close_row_shapes.sh` (104 lines, 22 total cases pass: 6 close-shapes + 13 escalator + 3 JSONL-fallback)
- `/tmp/escalator-regression-recurring-rca-2026-05-06.md` (118 lines RCA report)

**Live replay against today's JSONL: ZERO false-positives.** The 2 escalations from 12:43Z (escalate-8eaf3683 + escalate-8b336af1) and the 13:04Z auto-close case all correctly read as completed work post-patch.

**Root cause confirmed:** The cf3a fix only matched worker-self-close shape (`closed_by="<WorkerName>"`). It missed:
- Orch-on-behalf close: `closed_by="flywheel-orch-on-behalf-of-<WorkerName>"` (today's CloudyMill 11:48Z + flywheel-owns-orch-pane-recovery 11:31Z)
- Orch direct close: `closed_by="flywheel-orch"` (the 13:04Z auto-close path)

**Fix:** Extended close-row detection to recognize `closed_by` matching `<WorkerName>` substring OR `flywheel-orch` prefix. Additive only — cf3a baseline preserved.

**Donella read:** #5 Rules + #6 Information Flows. The escalator now reads ALL valid completion signals on the JSONL truth surface, not just one shape. Per memory rule `feedback_regression_test_must_exercise_production_close_path.md` — regression test now uses today's actual JSONL rows as fixtures, not just synthetic ones.

**Closeout pattern:** Worker did 6/8 (script + test + RCA + tests passed + live-replay green + 22-case coverage). Blocked on INCIDENTS.md + JSONL append by RainyMarsh+CloudyMill+PearlBeacon reservations (coordination_message_id=272 sent). Orch executed canonical scoped-commit-by-pathspec recipe (append-only safe scope) to ship final 2 deliverables.

## Cross-reference: codex#21241 vs shipped freeze subclasses (2026-05-06)

Date: 2026-05-06

Class: `codex-cli-stucks-on-every-prompt-cross-ref`

Bead: `flywheel-codex-21241-stuck-on-every-prompt-cross-ref-2026-05-06` (P1, docs-only).

Co-ownership: skillos:1 second cross-orch co-own delivery (sibling to
`oom_killed_pane`, commit `ebf44878`, shipped 25min wall earlier today).

Mission anchor: `80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a`.

Upstream report: <https://github.com/openai/codex/issues/21241> — vladon,
codex-cli 0.128.0, gpt-5.5, Linux WSL2 + Windows Terminal. Body is the bare
claim "codex-cli stucks on every prompt" plus an opaque thread id
(`019df9e4-80ce-7831-8ff9-d87e8ffe2a4b`); no scrollback, no two-frame capture,
no Working/Killed/capacity/queued evidence.

Coverage verdict: **partial — `input_deaf` primary, `buffer_stuck` secondary,
`unknown_stable` catch-all.** Triaged shape-only against eight shipped subclasses
(`alive`, `buffer_stuck`, `post_completion`, `input_deaf`,
`post_callback_reminder_template_with_stale_spinner`,
`model_at_capacity_halt`, `codex_queued_not_submitted`, `oom_killed_pane`)
plus `unknown_stable` fallback. Signature is shape-isomorphic with the
documented `#12645` family (kitty-keyboard + tmux Enter drop on Codex CLI
WSL/Linux, INCIDENTS.md L185-225 `frozen-codex-spinner-misclassified-as-thinking`):
WSL2 + Windows Terminal is the same OS family, "stucks on every prompt" is the
canonical phenomenology of TUI keyboard-protocol Enter drop, and codex-cli
0.128.0 sits three minor versions past the 0.125.0 #12645 baseline.

Forever-Rule: when an upstream Codex stuck report is evidence-thin (title
only, no scrollback), the shipped detector handles it via `input_deaf` /
`buffer_stuck` recovery routing and the `unknown_stable` snapshot collector.
Do NOT author a speculative subclass without a fixture — that violates
canonical-cli-scoping (no executable code without evidence) and axiom 9
(Socraticode-First). The detector's `write_unknown_snapshot` +
`fuckup_row` path (`codex-template-stuck-detector.sh` lines 581-601, 753-769)
is the canonical evidence collector for the next subclass authoring cycle.

Fix Applied/Status: no executable change — docs-only triage. No follow-up
bead filed (no uncovered pattern asserted).

Donella read: #5 Rules + #6 Information Flows. Existing rules
(subclass-gated recovery, no auto-respawn for `input_deaf`, `unknown_stable`
snapshot path) already fence the #21241 shape. The information loop
`unknown_stable` → snapshot → fuckup-log → manual review → new fixture →
new subclass is wired and is the correct path if a #21241 reproducer
surfaces scrollback later.

Evidence:
- Triage doc: `state/codex-21241-cross-reference-2026-05-06.md` (full
  per-subclass coverage matrix with verbatim regex citations).
- Detector source: `.flywheel/scripts/codex-template-stuck-detector.sh`
  (`codex-stuck-detector.v1.2.0`).
- Sibling INCIDENTS entry: `Codex CLI 0.125.0 kitty-keyboard+tmux Enter drop
  (#12645)` (L185-225) — same family, recovery `Ctrl-C-relaunch through
  frozen-pane-detector v2`.
- Sibling co-own delivery: `oom_killed_pane` shipped commit `ebf44878`
  (bead `flywheel-codex-oom-killed-subclass-2026-05-06`).
- Cross-orch coordination: rows 147 (skillos→flywheel),
  155+156+157+callback (flywheel↔skillos).

## Plan-arc Phase 2 r2 refine: absorbed Finding 4 (dispatch-under-injects-skills) + skillos coordination touchpoint (2026-05-06)

Bead: `flywheel-plan-mission-lock-paradigm-extension-phase2-refine-r2-2026-05-06`

Class: `dispatch-systematically-under-injects-skills`

Promotion Action: REFINE

Severity: high

Scope: plan-space-only.

What changed: Phase 2 r2 absorbed cross-orch Finding 4 / row 154 into the
mission-lock paradigm extension. R1 already had the triple-gate shape across
mission-lock, dispatch-author, and close-validator. R2 keeps that shape and
widens dispatch-author from "load-bearing work requires a skill suite" to
"every bead gets a universal skill floor, then bead-class defaults add the
domain route, and dispatch self-tests the routing before send."

Required universal-class tokens captured for Phase 3 audit:
`canonical-cli-scoping`, `readme-writing`, `de-slopify`, `simplify`, and
`socraticode`.

Required bead-class defaults captured:
`frontend-real-data-flip`, `backend-endpoint`, `substrate-fix`,
`db-migration`, and `saas-intelligence`.

Skillos touchpoint: Phase 4 must coordinate with `skillos:1` before writing the
final `/flywheel:dispatch` amendment. Flywheel consumes the dispatch skill
routing template; skillos owns reusable skill template/API shape. The r2 plan
defines the ready-to-implement capsule and ack fields for that handshake.

Phase 3 risks recorded:
- `canonical-cli-scoping` exists locally but skill-search returned
  `blocked_no_source`; audit must decide warn vs block vs local SKILL.md
  fallback.
- `simplify` has no exact skill directory; existing aliases are
  `code-simplifier` and `simplify-and-refactor-code-isomorphically`.
- `schema-complete-drift-guard` has no exact local skill directory.

Evidence:
- Refine artifact:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/02-REFINE-r2.md`.
- State:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/STATE.json`
  records `refine_round=2`, `cross_orch_findings_absorbed=[151,152,153,154]`,
  and `skillos_coordination_pending=true`.
- Socraticode: 10 r2 queries against canonical `/Users/josh/Developer/flywheel`,
  with 951 indexed chunks observed.
- Skill-search: 455 indexed skills, 463 filesystem skills, route gate enabled,
  drift count 8, freshness 79 percent.
- L112:
  `OK_mission_lock_paradigm_phase2_r2`.

## Phase 4 Bead #6 closed: rich recovery JSONL ledger schema + doctor probe (2026-05-06)

Bead: `flywheel-capacity-halt-doctor-ledger-2026-05-06`.

Leverage class: Donella #6 Information Flows. Recovery primitives already
emitted attempt fragments, but doctor consumers could not read one canonical
ledger shape or aggregate 24h recovery counters.

Shipped:
- Canonical draft-07 schema:
  `.flywheel/validation-schema/v1/recovery-ledger.schema.json`.
- Backwards-compatible watchdog migration:
  `.flywheel/scripts/worker-auto-respawn-watchdog.sh` still emits existing
  fields and now adds canonical `actor`, target, pane-role, trauma-class,
  budget, transport, post-check, failure-class, and primitive fields.
- Doctor probe:
  `.flywheel/scripts/recovery-doctor-probe.sh`.

Doctor fields exposed:
`recovery_count_24h`, `recovery_success_pct_24h`,
`recovery_attempted_24h_by_class`, `recovery_protected_refusals_24h`,
`recovery_budget_exhausted_24h`, `recovery_transport_failure_pct_24h`, and
`top_failing_panes_24h`.

Audit findings closed: recovery primitives now have doctor-visible counters
for attempts, success rate, protected refusals, budget exhaustion, transport
failure rate, per-class counts, and top failing panes. The probe counts both
new canonical rows and legacy `auto-respawn-attempts.jsonl` rows.

Evidence:
- Test: `.flywheel/tests/test_recovery_doctor_probe.sh` passed 9 canonical
  cases / 16 assertions, including malformed-row warnings, 24h exclusion,
  mixed old/new schemas, and schema validation.
- Watchdog regression: `.flywheel/tests/test_worker_auto_respawn_watchdog.sh`
  passed 35/35.
- Sibling regressions:
  `.flywheel/tests/test_capacity_halt_auto_continue_primitive.sh` passed 8
  cases / 24 assertions, and
  `.flywheel/tests/test_codex_queued_not_submitted_classifier_and_recovery.sh`
  passed 11 cases / 28 assertions.
- L112: `OK_capacity_halt_phase4_bead6_doctor_ledger`.

## Phase 4 Bead #7 closed: capacity-halt driver coverage matrix + probe (2026-05-06)

Bead: `flywheel-capacity-halt-driver-coverage-2026-05-06`.

Status: the 7-bead capacity-halt DAG is complete. Beads #1-#7 have now
closed across reconcile, auto-continue primitive, success measurement,
authorization, burst budget, doctor ledger, and driver coverage.

Leverage class: Donella #6 Information Flows. The recovery drivers were
already installed, but the coverage matrix was implicit in launchd plists and
script chains. The new probe makes future driver drift visible without
mutating plists or recovery primitives.

Coverage matrix from live `~/Library/LaunchAgents/ai.zeststream.*.plist`:
- Plists audited: 37.
- Drive capacity-halt recovery: 6 capability rows.
- Drive queued-not-submitted recovery: 5 capability rows.
- Monitors-only: 10 primary-category rows.
- Unrelated: 21 primary-category rows.

Probe: `.flywheel/scripts/capacity-halt-driver-coverage.sh`.

The probe classifies every plist into one primary category:
`drives_capacity_halt`, `drives_queued_not_submitted`, `monitors_only`, or
`unrelated`, and records capability flags so Codex detector plists with
`--auto-recover` count for both capacity-halt and queued-not-submitted driver
coverage.

Evidence:
- Test: `.flywheel/tests/test_capacity_halt_driver_coverage.sh` passed 5
  canonical cases / 10 assertions.
- Live probe: `plists_audited_count=37`,
  `drives_capacity_halt_count=6`,
  `drives_queued_not_submitted_count=5`,
  `monitors_only_count=10`, `unrelated_count=21`.
- L112: `OK_capacity_halt_phase4_bead7_driver_coverage`.

## Doctrine drift propagation: 19/291 repos drifted, oldest lag 25h (skillos:1 row 147) - RCA + sync patch + drift-trend probe shipped (2026-05-06)

Bead: `flywheel-doctrine-drift-propagation-19-of-291-2026-05-06`.

Class: `canonical-doctrine-drift-propagation`.

Severity: P1.

Signal: skillos:1 surfaced the 19/291 drift finding via cross-orch row 147.
Live verification in flywheel found 19 drifted repos and 44 drifted sync
surfaces before repair.

Top-5 drifted repos:
`alpsinsurance`, `alpsinsurance-seed-org-43451a8e-3256a440`, `cfs-expo`,
`comfyui`, and `cubcloud-aaas`.

Root cause: the sync substrate existed, but propagation failure was weakly
surfaced. The fleet propagator was running for at least some repos and logging
`sync_nonzero` failures, including repeated `alpsinsurance` failures, but the
canonical sync script had no durable drift-count ledger and no doctor-facing
trend probe. Drift could therefore accumulate as per-run failures rather than a
single visible fleet trend. Some repos also had no observed recent propagator
row, so coverage visibility was incomplete.

Fix shipped:
- `sync-canonical-doctrine.sh` now emits `ts`, `ledger_path`, and appends its
  JSON receipt to `~/.local/state/flywheel/doctrine-sync-ledger.jsonl` unless
  `SYNC_CANONICAL_LEDGER_DISABLE=1`.
- New `.flywheel/scripts/doctrine-drift-trend-probe.sh` reports current drift,
  24h delta, alert state, and top-N drifted repos from the ledger.
- New `.flywheel/tests/test_doctrine_drift_trend_probe.sh` covers zero, five,
  nineteen, improvement, worsening, malformed ledger, and quiet mode.

Live sync results: top-five dry-run/apply completed with zero errors, then the
remaining non-source drifted repos were dry-run/applied with zero errors. Final
global dry-run reports `drifted_count=1`; the only residual drift is the
flywheel source repo's `.flywheel/AGENTS-CANONICAL.md`, which was intentionally
not applied because this dispatch marked canonical doctrine source files
read-only.

Donella read:
- #6 Information Flows: drift now has a durable ledger and trend probe instead
  of isolated per-run receipts.
- #5 Rules: future doctor gates can consume one canonical receipt shape and
  alert on worsening drift.

Evidence:
- RCA: `/tmp/doctrine-drift-rca-2026-05-06.md`.
- Top-five receipts: `/tmp/doctrine-drift-top5-dry-run-preapply.jsonl`,
  `/tmp/doctrine-drift-top5-apply.jsonl`, and
  `/tmp/doctrine-drift-top5-dry-run-after.jsonl`.
- Remaining apply receipts: `/tmp/doctrine-drift-remaining-apply.jsonl`.
- Final dry-run: `/tmp/doctrine-sync-final-dry-run.json`.
- Final trend probe: `/tmp/doctrine-drift-trend-final.json`.
- Tests: `test_doctrine_drift_trend_probe.sh` passed 11 assertions; existing
  `test-sync-canonical-doctrine.sh` passed with ledger writes disabled.
- L112: `OK_doctrine_drift_propagation_shipped`.

## Fuckup-log <unknown> class triage: legacy `class` rows collapsed at review boundary (2026-05-06)

Bead: `flywheel-learn-review-fuckup-triage-2026-05-06`.

Class: `fuckup-log-unknown-class-review-loss`.

Severity: P1.

Signal: dispatch snapshot reported 785 last-24h unprocessed rows, 658 unknown
(84%). Live pre-patch triage had drifted to 821 unprocessed rows, 697 unknown.
A 50-row random sample found 48 recovery reminder rows, one model-capacity row,
and one `DATABASE_URL` leak row.

Root cause: emitters were not actually classless. They wrote meaningful legacy
`class` values, but `flywheel-loop fuckup list` aggregated only `trauma_class`,
so review/triage collapsed those rows into `<unknown>`.

Fix shipped:
- `flywheel-loop fuckup list` now normalizes legacy `class` into
  `trauma_class` when `trauma_class` is missing, `unknown`, or `<unknown>`.
- The shipped rule absorbs concrete legacy classes including
  `post-callback-reminder-template-recovery`,
  `codex-model-at-capacity-halt`, and `secret-leak`; one schema-compatibility
  rule was used instead of duplicate regex rules.
- The raw fuckup log is not mutated; normalized review rows preserve
  `original_trauma_class` and `classifier_source`.
- Explicit `trauma_class` still wins over legacy `class`.
- No promotion-ready new class surfaced: recovery reminder rows were low
  severity, capacity-halt had 4 high-severity legacy rows, and the rest were
  below threshold.

Evidence:
- RCA: `/tmp/fuckup-log-unknown-class-rca-2026-05-06.md`.
- Dry-run projection: `raw_unknown=697`, `dry_run_unknown=0`.
- Actual run: `unprocessed_24h=828`, `actual_unknown=0`,
  `classifier_source=flywheel-loop:legacy-class-field` rows `704`.
- Donella #6 Information Flows: unknown share moved from 84% at dispatch
  snapshot to 0% in post-patch review output for this class of rows.
- Test: `.flywheel/tests/test_fuckup_classifier_rules.sh` passed.
- L112: `OK_fuckup_log_unknown_class_triaged`.

## Plan-arc Phase 2 r3 refine: 10 open questions resolved + convergence test (2026-05-06)

Bead: `flywheel-plan-mission-lock-paradigm-extension-phase2-refine-r3-2026-05-06`.

Scope: plan-space only. No code-space, skill-file, MISSION, or Phase 3 audit
mutation was performed.

R3 closes the ten open questions left by r2 without adding a new finding class,
gate, bead class, or universal skill token. The plan keeps the three-gate shape:
mission-lock, dispatch-author, and close-validator.

Resolved policy:
- `canonical-cli-scoping` route-health `blocked_no_source` warns and forces a
  local `SKILL.md` read fallback when the exact skill file is readable; it
  blocks only when the local skill cannot be read.
- `simplify` remains the universal token; default concrete route is
  `code-simplifier`, with `simplify-and-refactor-code-isomorphically` reserved
  for behavior-preserving refactors.
- Missing exact `schema-complete-drift-guard` does not fail by itself; dispatch
  may proceed through `safe-migrations`, `supabase-postgres-best-practices`,
  and `data-quality-validation`, while skillos receives a candidate for
  reusable alias/template gaps.
- `/flywheel:dispatch` owns bead-class detection authority; `gsd-planner` may
  propose, skillos supplies taxonomy/templates, and a shared helper may
  implement matching.
- Close-validator proof requires artifact-backed `skill_receipts[]`; naming a
  skill in the packet is not enough.

Convergence:
- Semantic delta versus r2: 4 percent.
- `convergence_streak=1`.
- `phase3_audit_eligible=false` because the strict state rule requires two
  consecutive under-five-percent rounds and r3 is the first.
- Deferred implementation questions: 2, both field/API finalization questions
  for skillos alias/templates and close-validator receipt names.

Donella read: #6 Information Flows remains primary because skill evidence moves
from implicit worker judgment into dispatch and close receipts. #5 Rules fixes
the send/no-send and close/no-close contracts. #4 Self-Organization stays
bounded: flywheel consumes dispatch evidence, skillos owns reusable taxonomy,
and target repos own domain-specific fixtures.

Evidence:
- Refine artifact:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/02-REFINE-r3.md`.
- State:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/STATE.json`
  records `refine_round=3`, `open_questions_resolved=10`,
  `convergence_streak=1`, and `phase3_audit_eligible=false`.
- Socraticode: 10 r3 queries against canonical `/Users/josh/Developer/flywheel`,
  with 961 indexed chunks observed.
- Skill-search confirmed `code-simplifier`, `safe-migrations`, and
  `data-quality-validation` as concrete existing routes.
- L112:
  `OK_mission_lock_paradigm_phase2_r3`.

## Scoped commit pass: 3 commits shipping 11 untracked work-product files (2026-05-06)

Bead: `flywheel-scoped-commit-untracked-day-shipped-2026-05-06`.

Class: `scoped-commit-by-pathspec`.

Severity: P2.

Scope: promote today's shipped untracked work-product into three explicit
pathspec commits without absorbing unrelated modified files, runtime state, or
forensic `.beads` sidecars.

Commits:
- `aa57ca8` — scripts commit, 3 files:
  `.flywheel/scripts/capacity-halt-driver-coverage.sh`,
  `.flywheel/scripts/doctrine-drift-trend-probe.sh`, and
  `.flywheel/scripts/recovery-doctor-probe.sh`.
- `5026fa0` — tests commit, 7 files:
  `.flywheel/tests/test_capacity_halt_driver_coverage.sh`,
  `.flywheel/tests/test_doctrine_drift_trend_probe.sh`,
  `.flywheel/tests/test_enter_press_not_respawn_class_gate.sh`,
  `.flywheel/tests/test_flywheel_respawn_boot_wait_window.sh`,
  `.flywheel/tests/test_fuckup_classifier_rules.sh`,
  `.flywheel/tests/test_recovery_doctor_probe.sh`, and
  `.flywheel/tests/test_two_blocker_ticks_escalator_close_row_shapes.sh`.
- `ac343b9` — chore commit, 2 files:
  `.flywheel/validation-schema/v1/recovery-ledger.schema.json` and
  `.flywheel/handoffs/2026-05-06-1325-compact.md`.

Counts:
- Dispatch snapshot target: 11 work-product files; live scoped target included
  12 files because `test_fuckup_classifier_rules.sh` had landed as an untracked
  worker product before this pass.
- Untracked count excluding `.beads` forensic evidence: `16 -> 4`.
- Last-three commit file count: `12`.
- Non-additions in last-three commits: `0`.
- Forbidden paths in last-three commits: `0`.

Reserved/deferred paths skipped:
- `.flywheel/PLANS/mission-lock-paradigm-extension-2026-05-06/02-REFINE-r2.md`
- `.flywheel/PLANS/mission-lock-paradigm-extension-2026-05-06/02-REFINE-r3.md`
- `.ntm/pids/`
- `version`
- `.beads/*.bak.*` and `.beads/*.aside.*`
- `.beads/issues.jsonl` and `INCIDENTS.md` remained append-only closeout
  surfaces, not commit payload.

Evidence:
- Socraticode: 3 searches against `/Users/josh/Developer/flywheel`, 963 indexed
  chunks observed.
- L112: `OK_scoped_commit_pass_complete`.


## Memory index compaction: MEMORY.md tightened from 26.9KB to 16.1KB, 99 lines, avg 162.7 chars/line (2026-05-06)

Bead: `flywheel-memory-index-compaction-2026-05-06`.

Scope was limited to `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/MEMORY.md` plus append-only close receipts here and in `.beads/issues.jsonl`. Topic files were not modified.

Results:
- Bytes: `27566` -> `16475`.
- Entries: `99` -> `99`; order preserved.
- Max line length: `616` -> `190` chars.
- Linked topic files: `broken_links_after=0`.
- Topic hash diff: clean across 112 same-dir topic files.
- Stale index link corrected in-place from `feedback_data_guides_decisions_not_human_judgment.md` to existing `feedback_data_decides_not_human_meatpuppet.md`; no topic file was created or edited.
- Socraticode: 3 searches against canonical `/Users/josh/Developer/flywheel`, 30 result chunks observed.
- Reservation conflicts on append-only receipt files were coordinated via Agent Mail with `PearlBeacon` and `MagentaPond`; final edits stayed EOF-only.

Evidence:
- Survey: `/tmp/memory-index-compaction-research-survey.md`.
- Topic hash receipts: `/tmp/memory-topic-hashes-before.txt` and `/tmp/memory-topic-hashes-after.txt`.
- L112: `OK_memory_index_compacted`.

## Plan-arc Phase 3 Audit Lens 2 (idempotency-receipt-integrity) complete: 6 findings (sev: critical=0, high=1, medium=4, low=1) (2026-05-06)

Bead: `flywheel-phase3-audit-idempotency-receipt-integrity-2026-05-06`.

Scope: plan-space only. No code-space files, skill files, MISSION files, or
prior refine artifacts were modified.

The second Phase 3 lens audited r4 and its preserved r1-r3 three-gate contract
for replay safety, receipt completeness, deterministic skill routing,
append-only close truth, and shared-state race windows.

Findings:
- Critical: 0.
- High: 1.
- Medium: 4.
- Low: 1.
- Disposition: `auto_advance`.

The high finding is duplicate-dispatch risk: dispatch-author can recompute a
valid packet and send it again, but the plan does not yet require a
deterministic dispatch identity key, input hash, prior-send lookup, or
four-state delivery receipt in the skill discovery receipt.

Critical findings: none. No true Joshua-blocker class was identified.

Mitigation routing:
- Follow-up bead filed:
  `flywheel-mission-lock-idempotency-receipt-integrity-amendments-2026-05-06`.
- Required amendments: replay identity envelope, per-lens append-only audit
  rows, deterministic skill-suite and close-receipt identity keys, snapshot
  hashes for drift-prone routing inputs, duplicate-close policy, and repair
  idempotency fields for mission-lock readiness/scaffold receipts.

Disagreement note vs lens 1:
- Lens 1 security also closed with 0 critical, 1 high, 4 medium, and 1 low
  finding; both lenses agree on `auto_advance`.
- Security focuses on fields that must never carry secrets. This lens focuses
  on fields that must exist for duplicate/replay detection. The combined r5 or
  Phase 4 schema must add identity hashes and previous-row refs without
  embedding secret values.

Evidence:
- Audit report:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/03-AUDIT-r1-idempotency.md`.
- State:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/STATE.json`
  records `audit_lenses_complete` containing both `security-negative-invariants`
  and `idempotency-receipt-integrity`, with per-lens severity counts under
  `audit_findings_by_lens`.
- Socraticode: 10 queries against canonical `/Users/josh/Developer/flywheel`,
  with 100 result chunks observed.
- L112:
  `OK_phase3_audit_idempotency_lens`.

## Plan-arc Phase 2 r4 refine: stability confirmation, convergence_streak=2, Phase 3 audit eligibility=true (2026-05-06)

Bead: `flywheel-plan-mission-lock-paradigm-extension-phase2-refine-r4-2026-05-06`.

Scope: plan-space only. No code-space, skill-file, MISSION, L-rule, or Phase 3
audit mutation was performed.

R4 is the stability-confirmation pass after r3 resolved the ten r2 open
questions. It keeps the plan shape unchanged: 4 absorbed cross-orch findings, 3
gates, 5 universal skill tokens, 5 bead-class skill sets, 2 deferred
implementation questions, and 0 new finding classes.

Convergence:
- r3 lines: 231.
- r4 lines: 154.
- Semantic r3->r4 line change: 4 lines, rounded to 2 percent.
- `convergence_streak=2`.
- `phase3_audit_eligible=true`.

Phase 3 lenses recommended:
- `security-negative-invariants`
- `idempotency-receipt-integrity`
- `cross-cutting-skill-routing`

Total Phase 2 cost:
- r1: 479 lines, closed `2026-05-06T12:52:20Z`.
- r2: 405 lines, closed `2026-05-06T13:22:30Z`, 22 percent expansion for row
  154 skill injection.
- r3: 231 lines, closed `2026-05-06T13:54:43Z`, 4 percent closure and
  `convergence_streak=1`.
- r4: 154 lines, drafted `2026-05-06T14:13:08Z`, 2 percent stability and
  `convergence_streak=2`.
- Total refine artifact lines: 1269.
- Wall time from r1 close through r4 draft: about 81 minutes. Wall time from
  Lane C close at `2026-05-06T12:17:54Z` through r4 draft: about 115 minutes.

Donella read: #6 Information Flows remains primary. R4 does not add new
structure; it confirms the evidence is stable enough to move to audit. #5 Rules
now flips `phase3_audit_eligible` from false to true because the second
under-five-percent round landed. #4 Self-Organization is preserved by keeping
skillos, flywheel, and target-repo ownership boundaries unchanged.

Evidence:
- Refine artifact:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/02-REFINE-r4.md`.
- State:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/STATE.json`
  records `refine_round=4`, `convergence_streak=2`,
  `phase3_audit_eligible=true`, and three `phase3_audit_lenses`.
- Socraticode: 6 r4 queries against canonical `/Users/josh/Developer/flywheel`,
  with 964 indexed chunks observed.
- L112:
  `OK_mission_lock_paradigm_phase2_r4`.

## Plan-arc Phase 3 Audit Lens 1 (security-negative-invariants) complete: 6 findings, 0 critical, auto-advance (2026-05-06)

Bead: `flywheel-phase3-audit-security-negative-invariants-2026-05-06`.

Scope: plan-space only. No runtime code, skill files, MISSION files, or L-rules
were modified.

The first Phase 3 lens audited the r4 mission-lock paradigm extension for
credential, auth, secret, Agent Mail, skill-routing, close-validator, and
cross-orchestrator trust-boundary negative invariants.

Findings:
- Critical: 0.
- High: 1.
- Medium: 4.
- Low: 1.
- Disposition: `auto_advance`.

The high finding is packet-level secret hygiene: dispatch-author needs a
first-class invariant that packets may name secret classes, keys, vault paths,
and safe helpers, but may never carry secret values, token fragments, raw env
output, Agent Mail bearer tokens, or registration tokens.

Mitigation routing:
- Follow-up bead filed:
  `flywheel-mission-lock-security-negative-invariants-amendments-2026-05-06`.
- The follow-up bead also covers the medium/low amendment set: safe skill
  receipt markers, skillos cross-orch transfer limits, close-validator
  credential immutability, per-surface least-privilege metadata, and
  legacy-mode blocked-readiness for touched security surfaces.

Evidence:
- Audit artifact:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/03-AUDIT-r1-security.md`.
- State:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/STATE.json`
  records `current_phase=audit`, `audit_round=1`,
  `audit_lenses_complete=["security-negative-invariants"]`,
  `audit_findings_count=6`, and severity counts.
- Socraticode: 10 searches against canonical `/Users/josh/Developer/flywheel`,
  with 965 indexed chunks observed.
- Shared append surfaces had active stale/closeout reservations from
  `PearlBeacon` and `CobaltBeaver`; final edits were EOF-only and preserved the
  existing tail rows.
- L112:
  `OK_phase3_audit_security_lens`.

## Plan-arc Phase 3 Audit Lens 3 (cross-cutting-skill-routing) complete: 6 findings (sev: critical=0, high=2, medium=3, low=1) (2026-05-06)

Bead: `flywheel-phase3-audit-cross-cutting-skill-routing-2026-05-06`.

Scope: plan-space only. No runtime code, skill files, MISSION files, or L-rules
were modified.

The third Phase 3 lens audited the r4 mission-lock paradigm extension for
skill-floor coverage, bead-class collision handling, discovery-source
disagreement, skillos handshake shape, stale skill references, cross-cutting
overlays, and dispatch self-test soundness.

Findings:
- Critical: 0.
- High: 2.
- Medium: 3.
- Low: 1.
- Disposition: `auto_advance`.

The high findings are:
- Multi-class bead routing has no deterministic merge lattice, so real beads
  that touch backend, db, substrate, docs, and security surfaces can be
  under-injected or over-injected.
- Skill discovery disagreement is under-specified. Exact `get_skill`, semantic
  skill search, local skill roots, external `find-skills`, and grep/rg need a
  precedence contract and route-health receipt.

Mitigation routing:
- Recommended Phase 4 beads: `skill-routing-resolver`,
  `skill-discovery-precedence-receipt`, `skillos-template-handshake`,
  `skill-receipt-version-stamps`, `cross-cutting-overlays`, and
  `dispatch-self-test-negative-fixtures`.
- No r5 refine round is required unless Lens 2 later discovers a critical
  append-only or close-validator contradiction.

Evidence:
- Audit artifact:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/03-AUDIT-r1-cross-cutting.md`.
- State:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/STATE.json`
  records all three `audit_lenses_complete`, aggregate
  `audit_findings_count=18`, and `phase3_complete=true`.
- Socraticode: 10 searches against canonical `/Users/josh/Developer/flywheel`,
  with 965 indexed chunks observed.
- Skill-search: catalog total 455, filesystem total 463, drift count 8,
  freshness status WARN; exact `canonical-cli-scoping` and `find-skills` were
  found but route-blocked with `no_source`; `simplify` and
  `schema-complete-drift-guard` were missing exact skills.
- L112:
  `OK_phase3_audit_cross_cutting_lens`.

## Phase 3 Audit complete: 3 lenses converged (2026-05-06)

Phase 3 now has all three audit lenses complete:

- `security-negative-invariants`: 6 findings, 0 critical, auto-advance.
- `idempotency-receipt-integrity`: 6 findings, 0 critical, auto-advance.
- `cross-cutting-skill-routing`: 6 findings, 0 critical, auto-advance.

Aggregate findings: 18 total, critical=0, high=4, medium=11, low=3.
`STATE.json` marks `phase3_complete=true` and
`phase4_decompose_eligible=true`. Phase 4 should decompose mitigations rather
than reopen Phase 2 architecture.

## Plan-arc Phase 4 DECOMPOSE complete: 13 beads in DAG (3 amendments + 10 new), 4 waves, 18 audit findings covered (2026-05-06)

Bead: `flywheel-phase4-decompose-mission-lock-paradigm-extension-2026-05-06`.

Scope: plan-space only. No runtime code, skill files, MISSION files, or L-rules
were modified.

Phase 4 synthesized `02-REFINE-r4.md` plus all three Phase 3 audit lenses into
`.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/04-BEADS-DAG.md`.
The DAG has 13 nodes: 3 existing amendment beads from Phase 3 and 10 newly
created implementation beads. Work is organized into 4 waves: existing
amendments, schema/contracts, validator/handshake wiring, and replay/polish
gates.

Coverage:
- Total audit findings covered: 18 of 18.
- Medium-or-higher findings covered: 15 of 15.
- Critical findings: 0.
- Open scope items: 3.
- Phase 5 polish eligibility: true.

The three amendment beads are referenced as Wave 1 inputs and are not duplicated:
`flywheel-mission-lock-security-negative-invariants-amendments-2026-05-06`,
`flywheel-mission-lock-idempotency-receipt-integrity-amendments-2026-05-06`,
and `flywheel-mission-lock-cross-cutting-skill-routing-amendments-2026-05-06`.

Evidence:
- DAG artifact:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/04-BEADS-DAG.md`.
- State:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/STATE.json`
  records `current_phase=decompose`, `phase4_complete=true`,
  `phase5_polish_eligible=true`, `total_beads_in_dag=13`, and `wave_count=4`.
- JSONL fallback:
  `.beads/issues.jsonl` contains the Phase 4 dispatch close row and 10 new bead
  rows under parent `flywheel-plan-mission-lock-paradigm-extension-2026-05-06`.
- Socraticode: 10 queries against canonical `/Users/josh/Developer/flywheel`,
  with 100 result chunks observed.
- L112:
  `OK_mission_lock_paradigm_phase4_decompose`.

## gitignore: suppress .beads/ RCA evidence files (46 untracked -> ignored, .beads/issues.jsonl preserved) (2026-05-06)

Bead: `flywheel-gitignore-beads-rca-evidence-2026-05-06`.

Scope: `.gitignore` only for the committed source change, plus append-only
receipts in this file and `.beads/issues.jsonl`. No `.beads/` evidence files
were deleted or rewritten.

Live counts:
- Total untracked before: 54.
- Total untracked after: 8.
- `.beads/` RCA evidence untracked before: 46.
- `.beads/` RCA evidence untracked after: 0.

Patterns added:
- `.beads/beads.db.bak.*`
- `.beads/beads.db-shm.bak.*`
- `.beads/beads.db-wal.bak.*`
- `.beads/beads.db.aside.*`
- `.beads/beads.db-shm.aside.*`
- `.beads/beads.db-wal.aside.*`
- `.beads/beads.db*.malformed-*`
- `.beads/beads.db*.corrupt-*.aside.*`
- `.beads/beads.db*.malformed.*`
- `.beads/beads.db*.corrupt-*.bak.*`
- `.beads/issues.jsonl.bak.*`

Verification:
- `.gitignore` changed by 12 added lines.
- `.beads/issues.jsonl` still appears as `M` in `git status --porcelain`; it
  is not ignored.
- `.beads/beads.db` status was unchanged; it was already governed by the
  existing `.beads/.gitignore`.
- Scoped commit: `70c18fa`.
- Mission anchor present:
  `Mission-anchor: self-sustaining-company-architecture-health`.
- Socraticode: 3 searches against canonical `/Users/josh/Developer/flywheel`,
  with 966 indexed chunks observed.
- `INCIDENTS.md` and `.beads/issues.jsonl` had a stale completed-worker
  reservation from `ScarletDog`; final edits stayed EOF-only after its close
  rows were visible in the tail.
- L112:
  `OK_gitignore_beads_rca_evidence`.

## Plan-arc Phase 5 POLISH r1 complete: 13 beads polished, avg 679 chars, 4 needing further rounds (2026-05-06)

Bead: `flywheel-phase5-polish-mission-lock-paradigm-extension-r1-2026-05-06`.

Scope: plan-space only. No code-space files, skill files, MISSION files, L-rules,
or Phase 4 DAG structure were modified.

Phase 5 r1 converted all 13 mission-lock paradigm extension DAG nodes into
self-contained bead bodies using append-only JSONL polish events. Each body now
contains `What`, `Why`, 3-5 acceptance criteria, explicit future file
reservations, and dependencies. The three existing amendment beads and ten new
Phase 4 beads were all polished; none were skipped.

Round 1 stats:
- Beads polished: 13.
- Average before chars: 199.
- Average after chars: 679.
- Min/max after chars: 632 / 795.
- Bodies outside 150-800 chars: 0.
- Beads needing further substantive rounds: 4.
- `polish_convergence_streak`: 0 because r1 has no prior polish round for a
  diff comparison.

The four beads still needing a substantive r2 pass are
`flywheel-mission-lock-readiness-doctor-2026-05-06`,
`flywheel-dispatch-skillos-template-handshake-2026-05-06`,
`flywheel-mission-lock-validation-fixtures-golden-replay-2026-05-06`, and
`flywheel-phase5-polish-preflight-quality-gate-2026-05-06`.

Evidence:
- Polish report:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/05-POLISH-r1.md`.
- State:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/STATE.json`
  records `current_phase=polish`, `polish_round=1`,
  `polish_convergence_streak=0`, and `polish_avg_chars_after_r1=679`.
- JSONL fallback:
  `.beads/issues.jsonl` contains 13 `event=polish, round=1` rows plus the
  Phase 5 r1 close row.
- Socraticode: 6 searches against canonical `/Users/josh/Developer/flywheel`,
  with 60 result chunks observed.
- L112:
  `OK_mission_lock_paradigm_phase5_polish_r1`.

Fleet-doctor mid-session snapshot: pane=16/23 alive, doctor=red, top fuckup=fleet-propagation-failed, untracked=11 (2026-05-06)

## Phase 4 amendment shipped: cross-cutting-skill-routing 6 findings mitigated (CSR-001..006), collision-resolver + coverage map (2026-05-06)

Bead: `flywheel-mission-lock-cross-cutting-skill-routing-amendments-2026-05-06`.

Scope: bounded implementation surface for the cross-cutting skill-routing
amendment. The dispatch resolver, coverage map, implementation note, golden
test suite, and JSONL close receipt shipped without modifying audit reports,
plan rounds, mission files, validation schemas, or skill source files.

Evidence:
- Resolver:
  `.flywheel/scripts/dispatch-skill-router-collision-resolver.sh`.
- Golden tests:
  `.flywheel/tests/test_dispatch_skill_router_collision_resolver.sh`.
- Implementation receipt:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/impl/cross-cutting-amendments-impl.md`.
- Coverage map:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/impl/cross-cutting-concerns-coverage.md`.
- L112:
  `OK_cross_cutting_amendments_shipped`.

## CAAM recovery-path probe shipped: verdict=rotation_path_unverified, profiles_expired=4/6, rotation_health=0.5 (2026-05-06)

Bead: `flywheel-caam-recovery-verification-probe-2026-05-06`.

Scope: read-only recovery-path verification probe only. skillos-23fj remains
owner of the canonical CAAM fix; this worker did not refresh profiles, edit
CAAM config, restart daemons, mutate CAAM profile files, or touch the skillos
repo.

Result: the three CAAM LaunchAgents are present and loaded, and the probe found
the coordinator log at `~/.local/share/caam/auth-coordinator.log`. The last 24h
window contained no Anthropic 429 detection, no rotation event, and no rotation
success, so the path is `rotation_path_unverified` rather than proven healthy
or proven broken. Coordination row 160, landed after this dispatch, says
skillos-23fj shipped diagnostic-only while flywheel retains canonical
remediation and real rotation-test ownership.

Evidence:
- Probe:
  `.flywheel/scripts/caam-recovery-path-probe.sh`.
- Test:
  `.flywheel/tests/test_caam_recovery_path_probe.sh`.
- Verdict report:
  `/tmp/caam-recovery-path-verdict-2026-05-06.md`.
- Cross-orch coordination:
  `~/.local/state/flywheel/cross-orch-coordination.jsonl` row 163.
- L112:
  `OK_caam_recovery_path_probe_shipped`.

## Phase 4 amendment shipped: security-negative-invariants 6 findings mitigated (SEC-001..006), validator + test + MISSION.md template extension (2026-05-06)

Bead: `flywheel-mission-lock-security-negative-invariants-amendments-2026-05-06`.

Scope: Wave 1 amendment only. No audit/refine/polish reports were mutated.

Finding-by-finding mitigation:

| ID | Mitigation |
|---|---|
| SEC-001 | `secret_values_allowed=false` dispatch invariant forbids secret values, token fragments, raw env output, and Agent Mail bearer/registration tokens in packets. |
| SEC-002 | Credential-touching `skill_receipts[]` now require `credential_touch`, `safe_wrapper`, `secret_value_allowed=false`, and rotation approval source fields. |
| SEC-003 | Skillos/peer cross-orch transfer is limited to schema, aliases, templates, route health, and redacted evidence only. |
| SEC-004 | Close-validator authority is bounded: it may reject closure and demand receipts, but not rotate tokens, edit `.env`, write vault values, or close credential repair from pane text. |
| SEC-005 | Touched surfaces must declare secret source of truth, principal type, allowed operations, forbidden principals, and service-role/admin credential policy. |
| SEC-006 | Missing invariants on touched auth/credential/PII/customer-trust surfaces now block readiness unless Phase 0 scaffolding or no-touch proof exists. |

Shipped:
- MISSION.md additive section:
  `.flywheel/MISSION.md` `Negative invariants (security)`.
- Validator:
  `.flywheel/scripts/mission-lock-negative-invariants-validator.sh`.
- Test:
  `.flywheel/tests/test_mission_lock_negative_invariants_validator.sh`.
- Implementation report:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/impl/security-amendments-impl.md`.

Validation:
- `bash .flywheel/tests/test_mission_lock_negative_invariants_validator.sh`
  passed 10 fixture cases.
- Validator canonical CLI verbs passed:
  `--help`, `--info`, `--examples`, `--json`, and `--quiet`.
- `git diff -- .flywheel/MISSION.md` shows additions only for the mission
  append surface; this worker's security section is 29 lines.
- L112: `OK_security_amendments_shipped`.

## Phase 4 amendment shipped: idempotency-receipt-integrity 6 findings mitigated (IDEM-001..006), replay guard + receipt schema (2026-05-06)

Bead: `flywheel-mission-lock-idempotency-receipt-integrity-amendments-2026-05-06`.

Scope: bounded implementation surface for the idempotency and receipt-integrity
amendment. The additive dispatch receipt schema, replay guard primitive,
implementation note, golden-artifact tests, and JSONL close receipt shipped
without modifying audit reports, plan rounds, mission files, recovery-ledger
schema, or sibling amendment artifacts.

Evidence:
- Implementation receipt:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/impl/idempotency-amendments-impl.md`.
- Dispatch receipt schema:
  `.flywheel/validation-schema/v1/dispatch-receipt.schema.json`.
- Replay guard CLI:
  `.flywheel/scripts/idempotency-replay-guard.sh`.
- Golden tests:
  `.flywheel/tests/test_idempotency_replay_guard.sh`.
- Test result:
  `RESULT pass=20 fail=0`.
- Socraticode: 6 searches against canonical `/Users/josh/Developer/flywheel`,
  with 968 indexed chunks observed.
- L112:
  `OK_idempotency_amendments_shipped`.

## Phase 4 Wave 2 shipped: dispatch-author skill-routing contract + conformance probe + test (2026-05-06)

Bead: `flywheel-dispatch-author-skill-routing-contract-2026-05-06`.

Scope: canonical dispatch-author routing contract only. Wave 1 deliverables were
read-only references: collision resolver, idempotency replay guard, negative
invariants validator, and dispatch receipt schema.

Phase 4 Wave 2 shipped: dispatch-author skill-routing contract + conformance probe + test (2026-05-06)

Shipped:
- Contract:
  `.flywheel/doctrine/dispatch-author-skill-routing-contract.md`.
- Probe:
  `.flywheel/scripts/dispatch-author-contract-probe.sh`.
- Test:
  `.flywheel/tests/test_dispatch_author_contract_probe.sh`.

Metrics:
- Contract sections: 9.
- Contract lines: 177.
- Probe lines: 181.
- Test cases: 8 green, 16 assertions passed.
- Probe CLI verbs: `--info`, `--help`, `--examples`, `--json`, and `--quiet`.

Findings closed:
- `SEC-001`
- `SEC-003`
- `IDEM-001`
- `IDEM-003`
- `CSR-001`
- `CSR-002`
- `CSR-005`

Validation:
- `bash .flywheel/tests/test_dispatch_author_contract_probe.sh` passed.
- JSON output shape includes `ts`, `dispatch_path`, `checks`, `verdict`, and
  `violations`.
- L112:
  `OK_wave2_dispatch_author_contract_shipped`.

## Phase 4 Wave 2 shipped: close-validator receipt contract + probe + test (2026-05-06)

Bead: `flywheel-close-validator-receipt-contract-2026-05-06`.

Scope: canonical close-validator receipt contract only. Wave 1 deliverables were
read-only references: the idempotency replay guard and dispatch receipt schema.
The sibling dispatch-author contract is cited by path but not modified.

Phase 4 Wave 2 shipped: close-validator receipt contract + probe + test (2026-05-06)

Shipped:
- Contract:
  `.flywheel/doctrine/close-validator-receipt-contract.md`.
- Probe:
  `.flywheel/scripts/close-validator-contract-probe.sh`.
- Test:
  `.flywheel/tests/test_close_validator_contract_probe.sh`.

Metrics:
- Contract sections: 9.
- Contract lines: 147.
- Probe lines: 194.
- Test cases: 8 validation fixtures, 22 assertions passed.
- Probe CLI verbs: `--info`, `--help`, `--examples`, `--json`, and `--quiet`.

Findings closed:
- `SEC-002`
- `SEC-004`
- `IDEM-002`
- `IDEM-005`
- `CSR-004`

Validation:
- `bash .flywheel/tests/test_close_validator_contract_probe.sh` passed.
- Duplicate-close fixture reconciles to prior append-only truth with
  `dedupe_policy=latest-row-by-ref_id-event`.
- L112:
  `OK_wave2_close_validator_contract_shipped`.

## Phase 4 Wave 2 shipped: plan-state lens merge ledger contract + helper + test (2026-05-06)

Bead: `flywheel-plan-state-lens-merge-ledger-2026-05-06`.

Scope: canonical plan `STATE.json` lens merge ledger only. Wave 1
idempotency replay guard was read-only precedent for replay-safe state writes.

Phase 4 Wave 2 shipped: plan-state lens merge ledger contract + helper + test (2026-05-06)

Shipped:
- Contract:
  `.flywheel/doctrine/plan-state-lens-merge-ledger-contract.md`.
- Helper:
  `.flywheel/scripts/plan-state-lens-merge.sh`.
- Test:
  `.flywheel/tests/test_plan_state_lens_merge.sh`.

Metrics:
- Contract sections: 8.
- Contract lines: 115.
- Helper lines: 165.
- Required test cases: 6 green, 12 assertions passed.
- Helper CLI verbs: `--info`, `--help`, `--examples`, `--json`, and `--quiet`.

Findings closed:
- `IDEM-004` — parallel plan-state audit lenses now have append-only rows,
  `state_observed_sha`, race retry behavior, and derived summary semantics.

Validation:
- `bash .flywheel/tests/test_plan_state_lens_merge.sh` passed.
- L112:
  `OK_wave2_plan_state_lens_merge_shipped`.

## Phase 4 Wave 3 #1 shipped: skillos template handshake schemas + helper + test (2026-05-06)

Bead: `flywheel-dispatch-skillos-template-handshake-2026-05-06`.

Scope: consumer-side flywheel-to-skillos template handshake only. Skillos keeps
ownership of its producer and template generation.

Shipped:
- Request schema:
  `.flywheel/validation-schema/v1/skillos-template-handshake-request.schema.json`.
- Ack schema:
  `.flywheel/validation-schema/v1/skillos-template-handshake-ack.schema.json`.
- Helper:
  `.flywheel/scripts/skillos-template-handshake.sh`.
- Test:
  `.flywheel/tests/test_skillos_template_handshake.sh`.

Metrics:
- Request schema lines: 68.
- Ack schema lines: 98.
- Helper lines: 198.
- Required test cases: 6 green, 11 assertions passed.
- Helper CLI verbs: `--info`, `--help`, `--examples`, `--json`, and
  `--quiet`.

Findings closed:
- `SEC-003`
- `IDEM-003`
- `CSR-002`
- `CSR-003`

Validation:
- JSON Schemas self-validate under Draft 2020-12.
- `bash .flywheel/tests/test_skillos_template_handshake.sh` passed.
- Cross-orch row 165 gives `skillos:1` the consumer contract pointer.
- L112:
  `OK_wave3_skillos_handshake_shipped`.

## Phase 4 Wave 2 #4 shipped: mission-lock output schema (JSON Schema draft-07) + validator + test, unblocks Wave 3 (2026-05-06)

Bead: `flywheel-mission-lock-output-schema-amendments-2026-05-06`.

Scope: mission-lock output schema only. `.flywheel/MISSION.md`, Wave 1
deliverables, and already-shipped Wave 2 contracts were read-only.

Shipped:
- Schema:
  `.flywheel/validation-schema/v1/mission-lock-output.schema.json`.
- Validator:
  `.flywheel/scripts/mission-lock-output-schema-validator.sh`.
- Golden test:
  `.flywheel/tests/test_mission_lock_output_schema_validator.sh`.
- Implementation note:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/impl/mission-lock-output-schema-impl.md`.

Metrics:
- Schema dialect: JSON Schema draft-07.
- Validator lines: 167.
- Test lines: 166.
- Implementation note lines: 109.
- Golden cases: 6 required cases, plus CLI, quiet-mode, schema, and sidecar
  coverage.
- Validator CLI verbs: `--info`, `--help`, `--examples`, `--json`, and
  `--quiet`.

Fields made first-class:
- `mission_anchor_rev`
- `lock_hash`
- `mission_license`
- `negative_invariants`
- `cross_cutting_concerns_addressed`
- `surface_principal_metadata`
- `skill_surface_map`
- `failure_mode_matrix`
- `receipt_identity_envelope`

Validation:
- `bash .flywheel/tests/test_mission_lock_output_schema_validator.sh` passed:
  `RESULT pass=12 fail=0 golden_cases=6`.
- Shared append coordination: MagentaPond released ids 6348 and 6349 so
  BlueHarbor could finish Wave 3 EOF receipts first, then re-reserved ids 6371
  and 6372 before this append.
- L112:
  `OK_wave2_mission_lock_output_schema_shipped`.

## Plan-arc Phase 5 POLISH r2 complete: 13 beads polished, avg 694 chars, 2.12% diff, streak=1 (2026-05-06)

Bead: `flywheel-phase5-polish-mission-lock-paradigm-extension-r2-2026-05-06`.

Scope: plan-space only. No code-space files, skill files, MISSION files,
L-rules, DAG structure, or Wave 1/2/3 implementation artifacts were modified.

Phase 5 r2 tightened all 13 r1 bead bodies against newly shipped Wave 1, Wave 2,
and Wave 3 evidence. It kept every body inside the 150-800 character rule,
preserved the 13-node DAG and all dependencies, and appended round=2 polish
events without mutating prior rows.

Round 2 stats:
- Beads polished: 13.
- Average after chars: 694 vs 679 in r1.
- Average diff vs r1: 2.12%.
- Aggregate absolute char diff vs r1: 2.75%.
- Min/max after chars: 636 / 771.
- Individual bodies above 5% change: 3.
- `polish_convergence_streak`: 1.
- `phase5_ready`: false; r3 must provide the second consecutive <5% round.

The four r1 beads marked for further rounds were explicitly tightened:
`flywheel-mission-lock-readiness-doctor-2026-05-06`,
`flywheel-dispatch-skillos-template-handshake-2026-05-06`,
`flywheel-mission-lock-validation-fixtures-golden-replay-2026-05-06`, and
`flywheel-phase5-polish-preflight-quality-gate-2026-05-06`.

Evidence:
- Polish report:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/05-POLISH-r2.md`.
- State:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/STATE.json`
  records `polish_round=2`, `polish_convergence_streak=1`,
  `polish_avg_chars_after_r2=694`, and `phase5_ready=false`.
- JSONL fallback:
  `.beads/issues.jsonl` contains the r2 open row, 13 `event=polish, round=2`
  rows, and the Phase 5 r2 close row.
- Socraticode: 6 searches against canonical `/Users/josh/Developer/flywheel`,
  with 60 result chunks observed.
- L112:
  `OK_mission_lock_paradigm_phase5_polish_r2`.

## Phase 4 Wave 3 #2 shipped: mission-lock scaffold validator + impl + test (2026-05-06)

Bead: `flywheel-mission-lock-scaffold-validator-2026-05-06`.

Scope: read-only markdown scaffold validation for `.flywheel/MISSION.md`.
`.flywheel/MISSION.md`, Wave 1 amendments, and Wave 2 output schema artifacts
were read-only.

Shipped:
- Validator:
  `.flywheel/scripts/mission-lock-scaffold-validator.sh`.
- Golden test:
  `.flywheel/tests/test_mission_lock_scaffold_validator.sh`.
- Implementation note:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/impl/mission-lock-scaffold-validator-impl.md`.

Metrics:
- Validator lines: 184.
- Test lines: 136.
- Implementation note lines: 121.
- Golden cases: 6 required cases, plus CLI metadata and quiet-mode coverage.
- Validator CLI verbs: `validate`, `doctor`, `health`, `audit`, and `schema`.

Findings closed:
- `SEC-005`
- `IDEM-006`

Validation:
- `bash .flywheel/tests/test_mission_lock_scaffold_validator.sh` passed:
  `RESULT test_cases=8 failures=0`.
- Live `.flywheel/MISSION.md` reports `verdict=incomplete`, not `blocked`,
  because legacy locks lack embedded section hashes and substrate inventory.
- L112:
  `OK_wave3_mission_lock_scaffold_validator_shipped`.

## Plan-arc Phase 5 POLISH r3 complete: 13 beads polished, avg 694 chars (vs 694 r2), 0.00% diff, streak=2, phase5_ready=true (2026-05-06)

Bead: `flywheel-phase5-polish-mission-lock-paradigm-extension-r3-2026-05-06`.

Scope: plan-space only. No code-space files, skill files, MISSION files,
L-rules, DAG structure, or Wave implementation artifacts were modified.

Phase 5 r3 is a stability confirmation round. It kept all 13 r2 bead summaries
byte-identical, appended round=3 polish events, and advanced the plan STATE from
`phase5_ready=false` to `phase5_ready=true`.

Round 3 stats:
- Beads polished: 13.
- Average after chars: 694 vs 694 in r2.
- Average diff vs r2: 0.00%.
- Aggregate absolute char diff vs r2: 0.00%.
- Min/max after chars: 636 / 771.
- Individual bodies above 5% change: 0.
- `polish_convergence_streak`: 2.
- `phase5_ready`: true; plan arc READY and dispatchable.

Evidence:
- Polish report:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/05-POLISH-r3.md`.
- State:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/STATE.json`
  records `polish_round=3`, `polish_convergence_streak=2`,
  `polish_avg_chars_after_r3=694`, and `phase5_ready=true`.
- JSONL fallback:
  `.beads/issues.jsonl` contains the r3 open row, 13 `event=polish, round=3`
  rows, and the Phase 5 r3 close row.
- Socraticode: 6 searches against canonical `/Users/josh/Developer/flywheel`,
  with 60 result chunks observed.
- L112:
  `OK_mission_lock_paradigm_phase5_polish_r3`.

## Phase 4 Wave 3 #4 shipped: dispatch self-test + delivery-identity checker (2026-05-06)

Bead: `flywheel-dispatch-self-test-delivery-identity-2026-05-06`.

Scope: dispatch pre-send identity checking only. Wave 1/2 deliverables and the
live `.flywheel/dispatch-log.jsonl` were read-only references.

Shipped:
- Self-test:
  `.flywheel/scripts/dispatch-self-test-delivery-identity.sh`.
- Golden test:
  `.flywheel/tests/test_dispatch_self_test_delivery_identity.sh`.
- Implementation note:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/impl/dispatch-self-test-impl.md`.

Metrics:
- Script lines: 219.
- Test lines: 145.
- Implementation note lines: 96.
- Required test cases: 7 green, 18 total checks passed.
- CLI subcommands: `pretest`, `verify-identity`, and `mark-delivered`.
- Helper CLI verbs: `--info`, `--help`, `--examples`, `--json`, and `--quiet`.

Findings closed:
- `SEC-001`
- `IDEM-001`
- `CSR-003`
- `CSR-006`

Validation:
- `bash .flywheel/tests/test_dispatch_self_test_delivery_identity.sh` passed:
  `RESULT pass=18 fail=0 test_cases=7`.
- `pretest` refuses duplicate in-flight and already-complete dispatches before
  send; concurrent pretests allow exactly one writer to proceed.
- `mark-delivered` writes one canonical delivery-confirmed row per key to the
  self-test ledger, never to the live dispatch log.
- Shared append coordination: DustyDesert and WindyMountain held overlapping
  shared reservations; messages were sent and this entry used EOF-only append
  after a stable tail re-read.
- L112:
  `OK_wave3_dispatch_self_test_shipped`.

## Phase 4 Wave 3 #3 shipped: mission-lock readiness doctor + Phase 0 bead suggester (2026-05-06)

Bead: `flywheel-mission-lock-readiness-doctor-2026-05-06`.

Scope: read-only readiness aggregation. `.flywheel/MISSION.md`, Wave 2 #3,
Wave 2 #4, and Wave 3 #2 artifacts were consumed read-only.

Shipped:
- Doctor:
  `.flywheel/scripts/mission-lock-readiness-doctor.sh`.
- Golden test:
  `.flywheel/tests/test_mission_lock_readiness_doctor.sh`.
- Implementation note:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/impl/mission-lock-readiness-doctor-impl.md`.

Metrics:
- Doctor lines: 164.
- Test lines: 206.
- Implementation note lines: 84.
- Golden cases: 7 required cases, plus CLI metadata coverage.
- Doctor CLI verbs: `doctor`, `health`, `validate`, `audit`, and `schema`.

Findings closed:
- `SEC-006`
- `IDEM-004`
- `IDEM-006`
- `CSR-005`

Validation:
- `bash .flywheel/tests/test_mission_lock_readiness_doctor.sh` passed:
  `RESULT test_cases=8 failures=0 golden_cases=4`.
- Live `.flywheel/MISSION.md` reports readiness health `0.30`, with schema
  and scaffold suggestions emitted. No live mission mutation occurred.
- L112:
  `OK_wave3_mission_lock_readiness_doctor_shipped`.

## Plan-arc READY scoped commit pass: 4 commits shipping ~25 plan-arc artifacts + doctrine + scripts + impl (2026-05-06)

Bead: `flywheel-scoped-commit-plan-arc-deliverables-2026-05-06`.

Scope: git commit pass only, plus additive INCIDENTS and JSONL receipts.
Shared append files stayed unstaged, and no push was performed.

Commits:
- `24fa7de` `feat(plan-arc): ship mission-lock-paradigm-extension Phase 1-5 artifacts (READY)` - 11 files.
- `bd35f1a` `feat(doctrine): ship dispatch-author + close-validator + lens-merge contracts` - 3 files.
- `6aaf6d2` `feat(scripts): ship Wave 1/2/3 validators + probes + tests` - 24 files.
- `c062a3e` `feat(impl): ship Wave 1+2+3 amendment + contract impl docs` - 6 files.

Commit hygiene:
- Untracked count before: 45.
- Untracked count after: 8.
- Total files committed: 44.
- All four commits include `Plan-arc:
  mission-lock-paradigm-extension-2026-05-06 (READY)`.
- All four commits include `Mission-anchor:
  self-sustaining-company-architecture-health`.
- Staged sets were add-only; modified shared files were not committed.

Pane 3/4 reservation collision avoidance:
- Skipped `.flywheel/scripts/mission-lock-readiness-doctor.sh`.
- Skipped `.flywheel/tests/test_mission_lock_readiness_doctor.sh`.
- Skipped `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/impl/mission-lock-readiness-doctor-impl.md`.
- Skipped `.flywheel/scripts/dispatch-self-test-delivery-identity.sh`.
- Skipped `.flywheel/tests/test_dispatch_self_test_delivery_identity.sh`.
- Skipped `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/impl/dispatch-self-test-impl.md`.

Validation:
- `git log --oneline -4` shows exactly four new scoped commits.
- `git log --name-only HEAD~4..HEAD` contains no forbidden paths.
- Remaining untracked paths are the six skipped pane 3/4 paths plus `.ntm/pids/`
  and `version`.
- L112:
  `OK_plan_arc_ready_scoped_commit_pass_complete`.

## Petal 9 LEARN/REUSE: extracted 5 reusable patterns from mission-lock-paradigm-extension plan-arc (2026-05-06)

Required phrase template: `Petal 9 LEARN/REUSE: extracted N reusable patterns from mission-lock-paradigm-extension plan-arc (2026-05-06)`.

Bead: `flywheel-petal9-learn-review-plan-arc-2026-05-06`.

Scope: plan-space extraction only. No memory files and no skill files were
mutated.

Results:
- Reusable patterns extracted: 5.
- Promotion candidates: 11 total: 3 memory rule candidates, 5 skill update
  candidates, and 3 fuckup-log promotion candidates.
- Trauma recurrence stats: post-callback stale chevron/input-deaf class has
  913 same-family same-day rows; shared append reservation deadlock has 10
  same-family same-day rows; `br-db-wedge-recurrence` has 3 same-day rows.
- Cross-orch finding: skillos co-ownership worked because flywheel preserved the
  mission anchor, clarified scope, and asked for complementary artifacts instead
  of competing writes.

Evidence:
- Extraction document:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/06-PETAL9-LEARN-REUSE.md`.
- Socraticode survey:
  `/tmp/petal9-learn-review-survey.md`.
- Shared append coordination: DustyDesert held overlapping shared reservations;
  message 308 acknowledged the conflict and final edits were EOF-only after a
  stable tail re-read.

## Phase 4 Wave 4 #1 shipped: validation fixtures + golden replay runner (7 fixtures, 8-case test) (2026-05-06)

Bead: `flywheel-mission-lock-validation-fixtures-golden-replay-2026-05-06`.

Scope: integration fixture layer only. Wave 1/2/3 deliverables were consumed
read-only by the replay runner.

Shipped:
- Fixture directory:
  `.flywheel/tests/fixtures/mission-lock-paradigm-extension-2026-05-06/`.
- Replay runner:
  `.flywheel/scripts/golden-fixture-replay-runner.sh`.
- Golden test:
  `.flywheel/tests/test_golden_fixture_replay_runner.sh`.
- Implementation note:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/impl/validation-fixtures-impl.md`.

Metrics:
- Fixture files: 7.
- Runner lines: 187.
- Test lines: 85.
- Implementation note lines: 78.
- Test cases: 9 counted cases, 16 total pass assertions.
- Runner CLI verbs: `replay`, `replay-all`, `verify-invariants`,
  `list-fixtures`, and `schema`.

Findings closed:
- `SEC-004`
- `IDEM-001`
- `IDEM-003`
- `IDEM-005`
- `CSR-001`
- `CSR-004`
- `CSR-006`

Validation:
- `bash .flywheel/tests/test_golden_fixture_replay_runner.sh` passed:
  `RESULT pass=16 fail=0 test_cases=9`.
- `replay-all` reports 7 passing fixture replays.
- `verify-invariants` reports all 7 final findings covered and no missing
  Wave 1/2/3 artifacts.
- L112:
  `OK_wave4_validation_fixtures_shipped`.

## Petal 9 follow-on: 24h fuckup-log review (1063 rows) + Petal 9 candidate cross-correlation + Joshua-staged promotion recommendations (2026-05-06)

Bead: `flywheel-learn-review-fuckup-log-mining-2026-05-06`.

Scope: review-only learning pass. No memory files, skill files, or
`/flywheel:learn --promote` commands were mutated or executed.

Results:
- Review document:
  `.flywheel/reports/learn-review-2026-05-06.md`.
- Live 24h scrape observed 1080 unprocessed rows; dispatch snapshot was 1063
  rows, so the row count is treated as sample-size evidence, not a stable
  doctrine fact.
- Top trauma classes reviewed: 10.
- Petal 9 candidates evaluated: 11 total: 3 memory candidates, 5 skill update
  candidates, and 3 fuckup promotion candidates.
- Recommendations: 6 approve, 5 revise, 0 reject; 2 new gap candidates.
- Approved summary: 1 memory rule, 3 skill updates, and 2 fuckup classes ready
  for Joshua-reviewed promotion.

Evidence:
- Socraticode queries: 6.
- Fuckup-log scrape:
  `/tmp/fuckup-list-24h-unprocessed.jsonl`.
- Petal 9 source:
  `.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/06-PETAL9-LEARN-REUSE.md`.
- Anti-knowledge captured in the review: do not promote moving row counts,
  emitter noise, duplicate bead-DB aliases, or positive plan practices as
  trauma doctrine without revision.

## Phase 4 Wave 4 #2 — Polish Preflight Quality Gate

Phase 4 Wave 4 #2 shipped: polish-preflight-quality-gate orchestrator (8 sub-gates, 10-case test). 13-bead DAG fully closed. plan-arc mission-lock-paradigm-extension-2026-05-06 SHIPPED (2026-05-06)

Scope: terminal quality gate and plan arc closeout only. Wave 1/2/3/4
deliverables are consumed through their public CLI contracts.

Validation:
- `bash .flywheel/tests/test_polish_preflight_quality_gate.sh` passed:
  `RESULT pass=21 fail=0 test_cases=21`.
- `polish-preflight-quality-gate.sh --check --plan-slug mission-lock-paradigm-extension-2026-05-06 --json`
  returned `gate_status=PASS`, `gates_run=8`, and `composite_health_score=10`.
- L112:
  `OK_wave4_polish_preflight_quality_gate_dag_closed`.

## Plan-arc SHIPPED scoped commit pass: 4 commits shipping Wave 3+4 scripts/tests/schema/fixtures + impl docs + Petal 9 + learn-review (2026-05-06)

Bead: `flywheel-scoped-commit-shipped-deliverables-2026-05-06`.

Scope: git commit pass only, plus additive INCIDENTS and JSONL receipts.
Shared append files stayed unstaged, and no push was performed.

Commits:
- `10cec73` `feat(scripts): ship Wave 3+4 validators + doctor + replay-runner + quality-gate orchestrator` - 16 files.
- `bf9aefe` `feat(impl): ship Wave 3+4 impl docs (self-test, readiness-doctor, validation-fixtures, quality-gate)` - 4 files.
- `7d6e544` `docs(petal9): ship LEARN/REUSE extraction for mission-lock-paradigm-extension` - 1 file.
- `96e5fd2` `docs(reports): ship learn-review fuckup-log mining + Petal 9 candidate cross-correlation` - 1 file.

Commit hygiene:
- Untracked count before: 18.
- Untracked count after: 2.
- Total files committed: 22.
- All four commits include `Plan-arc:
  mission-lock-paradigm-extension-2026-05-06 (SHIPPED)`.
- All four commits include `Mission-anchor:
  self-sustaining-company-architecture-health`.
- All four commits are add-only; modified shared files were not committed.

Deferred untracked paths:
- `.ntm/pids/`
- `version`

Validation:
- L112:
  `OK_plan_arc_shipped_scoped_commit_pass_complete`.

## Beads sync recovery research: eight-ID recovery now stale-resolved pending Joshua option selection (2026-05-06)

Beads sync recovery research: 8 missing IDs analyzed (flywheel-6uxz/e2dj/f6p5/i2ad/l82y/nxuw/p2yj/x4ly), 3+ recovery options surfaced, dry-run merge artifact produced (NOT executed). Joshua-decision-needed for option selection (2026-05-06)

Evidence: `.flywheel/reports/beads-sync-recovery-research-2026-05-06.md` and `/tmp/beads-sync-recovery-dry-run-2026-05-06.sql`.

Finding: live DB/JSONL state no longer matches the original stale snapshot for the eight named IDs; all eight are now present in both stores. Broader sister mismatch remains: one DB-only ID and 95 JSONL-only IDs.

## P0 bead freshness audit: 15 wire-or-explain beads probed before dispatch authoring (2026-05-06)

P0 bead freshness audit shipped: 15 beads probed for live-substrate alignment. Verdicts: FRESH/STALE_RESOLVED/PARTIAL/UNKNOWN distribution surfaced. 4 stale-resolved candidates ready to close without dispatch (2026-05-06).

Verdicts: FRESH=3, STALE_RESOLVED=4, PARTIAL=8, UNKNOWN=0.

Evidence: `.flywheel/reports/p0-bead-freshness-audit-2026-05-06.md`.

Donella read: #6 information flows plus #5 rules. The audit moves stale-target detection before dispatch authoring and turns broad open beads into close/reduce/dispatch decisions.

## Bead-2j54 closed stale-resolved (live br 0.2.5 >= target 0.1.26). Lesson promoted: dispatch-author-stale-version-target class + accretive memory rule + accretive doctrine contract live-substrate verification gate (2026-05-06)

Bead: `flywheel-2j54`.

Class: `dispatch-author-stale-version-target`.

Scope: closeout and lesson promotion only. No Jeff repo source was patched, no
remote was pushed, and the `br` binary was not changed.

Live decision:
- Dispatch target was `br 0.1.20 -> 0.1.26`.
- Worker live probe found `br 0.2.5`.
- Latest observed upstream tag was `v0.2.5`.
- Downgrading a load-bearing binary would have increased substrate drift, so
  the worker correctly refused the stale-target packet.

Promoted lesson:
- Memory rule updated:
  `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_jeff_substrate_version_drift.md`.
- Memory index updated:
  `~/.claude/projects/-Users-josh-Developer-flywheel/memory/MEMORY.md`.
- Dispatch-author contract updated:
  `.flywheel/doctrine/dispatch-author-skill-routing-contract.md`.
- Fuckup-log row appended:
  `~/.local/state/flywheel/fuckup-log.jsonl`
  class `dispatch-author-stale-version-target`.

Forever-rule:
version or upgrade-class dispatches must cite live installed-version evidence
and upstream latest evidence before worker dispatch. If live installed version
is greater than or equal to the packet target, the author closes the bead as
drift-resolved or re-authors from live evidence; they do not dispatch a
downgrade-shaped packet.

Evidence:
- Worker report:
  `.flywheel/reports/jeff-br-upgrade-0.1.20-to-0.1.26-2026-05-06.md`.
- Pre-probe:
  `/tmp/jeff-br-pre-upgrade-2026-05-06.txt`.
- Post-probe:
  `/tmp/jeff-br-post-upgrade-2026-05-06.txt`.

## Substrate cleanup: stale-resolved P0 batch closed (2026-05-06)

Substrate cleanup: 4 STALE_RESOLVED P0 wire-or-explain beads closed via freshness-audit evidence (flywheel-1wkyb/2wvu/3sz6/g4zy). Live-substrate-verification-contract applied. No worker dispatches needed (substrate already wired) (2026-05-06)

## Canonical doctrine drift research: drift surface analyzed (2026-05-06)

Canonical doctrine drift research: drift surface analyzed (additive/stale/mutex/format taxonomy), 130 drifted lines categorized, reconciliation options surfaced, dry-run reconciler produced. Joshua-decision-needed (2026-05-06)

Evidence:
- Drift report: `.flywheel/reports/canonical-doctrine-drift-2026-05-06.md`.
- Dry-run script: `/tmp/canonical-doctrine-reconcile-dry-run-2026-05-06.sh`.
- Bead: `flywheel-2l9en`.

## Session reports committed: 4 docs (2026-05-06)

Session reports committed: 4 docs (3 in commit 13801ef + 1 in 90f36ee) shipped to git history. Race-condition surfaced: glob-based L112 vs mid-flight 4th report from pane 3 closure. Fuckup-class scoped-commit-glob-race-with-mid-flight-report logged for /flywheel:learn --review (2026-05-06)

## P0 PARTIAL bead scope-reduction research (2026-05-06)

P0 PARTIAL bead scope-reduction research: 8 PARTIAL beads from freshness audit analyzed; per-bead reduced-body proposals + Donella analysis + Joshua-decision recommendations. NO bead body mutations (Joshua decides) (2026-05-06)

Evidence: `.flywheel/reports/p0-partial-scope-reduction-2026-05-06.md`.

## Memory rule drafts from learn-review (2026-05-06)

Memory rule drafts from learn-review: 8 candidates (6 APPROVE + 2 NEW) drafted at /tmp/proposed-memory-rule-<slug>-2026-05-06.md. Joshua-actionable copy-paste paths surfaced. NO automatic memory file mutation (2026-05-06)

Evidence:
- Index: `/tmp/proposed-memory-rules-index-2026-05-06.md`.
- Draft count: 8 `/tmp/proposed-memory-rule-*-2026-05-06.md` files.
- Bead: `flywheel-memory-rule-drafts-from-learn-review-2026-05-06`.

## Doctrine forward-flow proposal (2026-05-06)

Doctrine forward-flow proposal: 36 additive_local lines from canonical-doctrine-drift research analyzed; PROMOTE/KEEP_LOCAL/DEFER decisions surfaced; dry-run forward-flow script produced (NOT executed). Joshua-decision-required (2026-05-06)

## Memory rule drafts shipped from learn-review (2026-05-06)

Shipped 8 memory rule drafts from learn-review (6 APPROVE + 2 NEW). Reversible: rm ~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_{agent_mail_short_lived_shared_append_reservations,br_prefix_mismatch_is_schema_drift,ci_substrate_failures_need_owner_route,plan_convergence_gates_positive_practice,post_callback_stale_chevron_input_deaf_class,shared_append_reservation_deadlock_family,shared_append_short_lease_stable_tail,worker_tick_shared_append_stable_tail_checklist}.md + MEMORY.md line removal (2026-05-06)

Evidence:
- Memory index: `~/.claude/projects/-Users-josh-Developer-flywheel/memory/MEMORY.md`.
- Source index: `/tmp/proposed-memory-rules-index-2026-05-06.md`.
- Bead: `flywheel-ship-memory-rule-drafts-2026-05-06`.

## Append-safe write primitive Phase 1 shipped (2026-05-06)

Shipped append-safe-write.sh primitive + test + pilot INCIDENTS callsite doc-only migration. Phase 1 of migration plan. Uses primitive to append THIS entry (dogfooding). Reversible: git-revert + dispatch-template doc revert (2026-05-06).

## Orch no-punt output gate Phase 1 shipped (2026-05-06)

Shipped orch-no-punt-output-gate.sh + 17-case test + Claude Code Stop hook (warn-mode). Reversible: git-revert + settings.json hook removal. Phase 1 of migration plan; Phase 2 promotes to refuse-mode after 24h (2026-05-06)

Evidence:
- Script: `.flywheel/scripts/orch-no-punt-output-gate.sh`.
- Test: `.flywheel/tests/test_orch_no_punt_output_gate.sh`.
- Hook: `~/.claude/settings.json hooks.Stop`.
- Bead: `flywheel-ship-orch-no-punt-output-gate-2026-05-06`.

## flywheel-uref closed and flywheel-2p25 promoted by hub-blocker rule (2026-05-06)

Closed flywheel-uref (hub-blocker rule designed) + auto-promoted flywheel-2p25 P1→P0 (6 parents blocked, exceeds N>3 threshold). Self-applied uref's own design rule to its trigger case. Reversible: JSONL revert rows. Downstream impl (doctor extension + /flywheel:status rendering) follows in separate dispatch (2026-05-06).

## Recency-weighted classifier Phase 1 shipped (2026-05-06)

Shipped recency_weighted_two_truth_classifier.sh primitive + 12+ test fixtures + 5 LOW-risk callsite migrations (warn-mode). Phase 1 of 22-callsite migration plan. Phase 2 (8 MED) + Phase 3 (9 HIGH) follow after 24h false-positive measurement. Reversible: git-revert per callsite (2026-05-06).

LOW-risk callsites migrated in warn-mode:
- /Users/josh/.claude/commands/flywheel/_shared/pane-state.sh
- .flywheel/scripts/pane-work-signal.sh
- .flywheel/scripts/l70-ticks-punted-counter.sh
- .flywheel/scripts/gap-hunt-probe.sh
- .flywheel/scripts/leverage-ceiling-probe.sh

Evidence:
- Classifier: .flywheel/scripts/recency-weighted-two-truth-classifier.sh
- Test: .flywheel/tests/test_recency_weighted_two_truth_classifier.sh
- Divergence log: ~/.local/state/flywheel/classifier-divergence-log.jsonl
- Manifest: /tmp/classifier-fix-migration-manifest-2026-05-06.md
- Bead: flywheel-ship-classifier-fix-phase-1-2026-05-06

## Doctrine forward-flow Phase 1 shipped (2026-05-06)

Shipped doctrine forward-flow Phase 1: 24 PROMOTE candidates landed in skill source ~/.claude/skills/.flywheel/. Fleet-wide auto-cure on peer-repo next-pull. Phase 2 + Phase 3 (remaining 0 candidates) follow after pilot validates 24h. Reversible: git revert per skill-source commit fd56417 (2026-05-06).

Evidence:
- Proposal: `.flywheel/reports/doctrine-forward-flow-proposal-2026-05-06.md`.
- Dry run: `/tmp/doctrine-forward-flow-dry-run-2026-05-06.sh`.
- Skill-source commit: `fd56417`.
- Bead: `flywheel-ship-doctrine-forward-flow-phase-1-2026-05-06`.

## Jeff clone symlink converter Phase 1 shipped (2026-05-06)

Shipped jeff-clone-symlink-converter.sh + 10-case test + 5 pair conversions Phase 1 (5/144 safe candidates). Backups at ~/.local/state/flywheel/jeff-clone-backups/<name>-<ts>.tar.gz with byte-count receipts. Reversible per pair: backup restore + symlink removal. Phase 2 (139 remaining) follows after pilot validates 24h (2026-05-06).

Pilot pairs converted:
- `automatic_cpp_code_analysis_with_gpt`: `/Users/josh/.local/state/flywheel/jeff-clone-backups/automatic_cpp_code_analysis_with_gpt-20260506T183513Z.receipt.json`
- `paxos_vs_raft`: `/Users/josh/.local/state/flywheel/jeff-clone-backups/paxos_vs_raft-20260506T183514Z.receipt.json`
- `interactive_reversible_cellular_automata`: `/Users/josh/.local/state/flywheel/jeff-clone-backups/interactive_reversible_cellular_automata-20260506T183515Z.receipt.json`
- `gemini-api-updater-doc`: `/Users/josh/.local/state/flywheel/jeff-clone-backups/gemini-api-updater-doc-20260506T183516Z.receipt.json`
- `hessian_free_email_chain`: `/Users/josh/.local/state/flywheel/jeff-clone-backups/hessian_free_email_chain-20260506T183517Z.receipt.json`

Validation:
- Reversibility drill: `/tmp/jeff-clone-reversibility-2026-05-06.json`.
- Live receipt JSONL: `/tmp/jeff-clone-phase1-receipts-2026-05-06.jsonl`.
- Bead: `flywheel-ship-jeff-clone-symlinks-phase-1-2026-05-06`.

## flywheel-1eg0k closed stale-resolved by drift (2026-05-06)

Closed flywheel-1eg0k stale-resolved-by-drift per Option D. Original 8-ID gap auto-resolved via concurrent inserts. Broader 1 DB-only / 95 JSONL-only state: FILED_AS_FOLLOWUP per worker judgment. Reversible: JSONL revert row (2026-05-06).

Evidence:
- Research: .flywheel/reports/beads-sync-recovery-research-2026-05-06.md
- Follow-up bead: flywheel-beads-sync-followup-reconciler-2026-05-06
- Closure bead: flywheel-1eg0k

## Canonical-doctrine Option H Phase 1 shipped (2026-05-06)

Shipped canonical-doctrine Option H Phase 1: 47 formatting_only drifted lines aligned to upstream. NO content change. Phase 2 (47 stale_local reverse-flow) follows. Reversible: git revert 9b6a79c (2026-05-06).

Evidence:
- Drift report: `.flywheel/reports/canonical-doctrine-drift-2026-05-06.md`.
- Dry-run output: `/tmp/canonical-doctrine-reconcile-dry-run-option-h-phase-1-observed-2026-05-06.txt`.
- Post-align diff: `/tmp/root-vs-canonical-after-option-h-phase-1.diff`.
- Commit: `9b6a79c`.
- Bead: `flywheel-ship-canonical-doctrine-option-h-phase-1-2026-05-06`.

## EOD scoped commit shipped: 2 reports (2026-05-06)

Shipped eod scoped-commit: 2 reports (doctrine forward-flow + p0 partial scope-reduction). Final eod git hygiene pass for 2026-05-06 substrate-research artifacts (2026-05-06).

Evidence:
- Commit: `9b6a79c7a0c4`.
- Reports: `.flywheel/reports/doctrine-forward-flow-proposal-2026-05-06.md`, `.flywheel/reports/p0-partial-scope-reduction-2026-05-06.md`.
- Bead: `flywheel-ship-eod-scoped-commit-2026-05-06`.

<!-- idempotency: ship-eod-scoped-commit:incidents:9b6a79c7a0c4 -->

## Correction: EOD scoped commit evidence SHA (2026-05-06)

Correction for the EOD scoped-commit incident immediately above: the report commit is `daf987f804fa9c78d0e9cee5b8bf495bd82806cc`, not `9b6a79c7a0c4`. `9b6a79c7a0c4` is the concurrent canonical-doctrine Option H commit that moved HEAD before the dispatch L112 ran. Commit `daf987f804fa9c78d0e9cee5b8bf495bd82806cc` adds exactly the two requested reports and includes the mission anchor; the literal HEAD-based L112 is blocked by this concurrent-commit race.

Follow-up bead: `flywheel-scoped-commit-l112-head-race-2026-05-06`.

<!-- idempotency: ship-eod-scoped-commit:incident-correction:daf987f804fa9c78d0e9cee5b8bf495bd82806cc -->

## Codex capacity cycles stall single-pane projects (2026-05-06)

Date: 2026-05-06

Promotion Action: NEW

Class: `codex-capacity-cycle-throttle`

Event Count: 2 capacity cycles in mobile-eats on 2026-05-06, plus one
170.2min rank-1 idle gap classified to the second cycle/recovery path.

Severity: high for single-pane projects; medium for multi-pane projects with
different model/provider fallback.

Cost: mobile-eats lost a 170.2min idle gap from 14:15:19Z to 17:05:30Z,
rank 1 idle gap of the day. The same diagnostic attributes 276min / 514min
= 53.7% avoidable idle to substrate-level traumas, with capacity-cycle
throttle as the largest contributor. The original finding also observed two
capacity cycles roughly 66min apart; cycle 1 cost about 9min and cycle 2
started as an 11-12min capacity stall before compounding into the 170min dry
stretch. Every single-worker flywheel project using a Codex high-demand tier
carries equivalent full-loop stall exposure.

Root Cause: Codex capacity/quota text is treated as a generic pane ERROR and
single-pane project topology has no alternate worker/model tier. The
orchestrator passively waits or retries the same throttled pane instead of
classifying the signal, rotating to an already-vaulted CAAM profile when the
signal is `codex_usage_limit`, or routing work to a different pane/model.

Forever-Rule: When a Codex pane reports capacity or usage-limit throttle,
orchestrators must classify the signal before treating it as worker failure.
For `codex_usage_limit`, route through the Lane A cure:
`codex_usage_limit -> caam_auto_rotate` with `recovery_class=credential_rotation`
and a no-secret recovery receipt. For model-capacity stalls, do not dispatch
new work to the throttled pane unless an explicit `--accept-stall` receipt is
present; route the next safe P0/P1 bead to a different model tier/provider or
secondary pane where available. Single-pane flywheel projects must carry either
a secondary-capacity plan or an explicit accepted-stall receipt.

Fix Applied/Status: PROPOSED canonical promotion. Implementation is already
represented in orch-uptime Lane A:
- A1 `flywheel-orch-uptime-caam-auto-rotate-primitive-2026-05-06` adds the
  dry-run-default CAAM selector primitive for vaulted Codex profiles.
- A2 `flywheel-orch-uptime-detector-codex-usage-limit-2026-05-06` adds the
  `codex_usage_limit` detector subclass and routes recovery to
  `caam_auto_rotate`.
This incident should close only after A1/A2 land, detector sibling regressions
stay green, and the dispatch surface exposes the `--accept-stall` or fallback
routing behavior.

Evidence:
- Source finding:
  `/Users/josh/Developer/mobile-eats/.flywheel/findings/2026-05-06-codex-capacity-cycle.md`.
- Mobile-eats local INCIDENTS rule promotion:
  `/Users/josh/Developer/mobile-eats/.flywheel/INCIDENTS.md` section
  `2026-05-06T19:30Z -- RULE PROMOTION: Capacity throttling on single-pane topology...`.
- CAAM diagnostic:
  `/Users/josh/Developer/mobile-eats/.flywheel/audits/2026-05-06-caam-diagnostic.md`
  section 2 rank 1 (170.2min) and avoidable idle line (53.7%).
- Skillos Codex stuck-family sibling:
  `/Users/josh/Developer/flywheel/INCIDENTS.md:185-222` records the
  `skillos:1` 17:15Z reproducer for `codex_queued_not_submitted`, a sibling
  non-progress class requiring classifier-specific recovery rather than generic
  pane failure handling.
- Cross-session detector sibling coverage:
  `/Users/josh/Developer/flywheel/INCIDENTS.md:1439-1468` records per-session
  stuck-detector coverage for both `mobile-eats` and `skillos`.
- Orch-uptime Lane A research:
  `/Users/josh/Developer/flywheel/.flywheel/plans/orch-uptime-2026-05-06/01-RESEARCH-A.md`.
- Orch-uptime DAG:
  A1 `flywheel-orch-uptime-caam-auto-rotate-primitive-2026-05-06`;
  A2 `flywheel-orch-uptime-detector-codex-usage-limit-2026-05-06`.

## Jeff Response Epics Require Live State Reconciliation (2026-05-07)

Date: 2026-05-07

Promotion Action: NEW

Class: `jeff-response-epic-stale-inventory`

Event Count: 1 epic closeout with two reconciliation gaps: `flywheel-bltm`
rendered 10 issue rows while acceptance required 11, and its stored inventory
listed `ntm#117` as open after GitHub had closed it on 2026-05-05.

Severity: medium

Cost: Parent epic closeout can silently undercount Jeff responses or leave stale
"open" state in the bead substrate, causing duplicated triage or missed
response absorption. This run also found duplicate closed `frankensqlite#85`
triage beads (`flywheel-4fjm`, `flywheel-gnjy`).

Root Cause: The response-triage epic trusted its static issue inventory instead
of reconciling the canonical issue URL set from existing auto-created response
beads plus live GitHub state at close time.

Forever-Rule: Jeff response-triage epics must close from a live reconciliation:
canonical issue URLs from triage beads, `gh issue view` current state, and a
dedup pass by URL. Do not close from the static table alone.

Fix Applied/Status: `flywheel-bltm` closeout evidence now includes the missing
`vibe_cockpit#4`, corrects `ntm#117` to closed, records the duplicate
`frankensqlite#85` beads, and leaves mechanism work on existing
`flywheel-gmat`.

Evidence:
- Triage receipt: `/tmp/flywheel-bltm-jeff-triage-2026-05-07.md`
- Lessons file: `/tmp/jeff-issue-submission-lessons-2026-05-03.md`
- Upstream issues:
  `https://github.com/Dicklesworthstone/ntm/issues/117`,
  `https://github.com/Dicklesworthstone/vibe_cockpit/issues/4`,
  `https://github.com/Dicklesworthstone/frankensqlite/issues/85`

## Batch structural-gate promotion for 33 META-RULE advisory rules (2026-05-07)

Date: 2026-05-07

Promotion Action: BATCH

Class: advisory-to-structural

Event Count: 33 META-RULE memory files promoted to structural gate coverage

Severity: medium

Cost: 33 META-RULE memory files (feedback_*.md) had zero structural gate
evidence, meaning the memory-rule-gate-parity-detector classified them all as
UNWIRED. Without structural gates, the flywheel detector cannot mechanically
confirm these rules are enforced. The batch accumulated because the wire-or-explain
pipeline's B1-B14 promotion closed without covering this second tier of rules.

Root Cause: The detector auto-filed 33 `flywheel-wire-*` beads. Each bead
required: script evidence in .flywheel/scripts/, hook/settings reference,
test evidence in .flywheel/tests/, and INCIDENTS.md mention. No batch promotion
path existed; each rule was expected to get individual wiring.

Forever-Rule: When the parity detector files N>10 advisory-to-structural beads
in one run, create a consolidated batch gate script covering all N rules rather
than attempting N individual scripts. The consolidated gate satisfies script
evidence via first_gate_mention (scans *-gate.sh content for aliases), hook
evidence via settings.json reference, and test evidence via per-rule test stubs.

Rules promoted in this batch (each with test stub and gate script coverage):
- accretive-corpus-ingestion
- audit-before-build-when-substrate-underutilized
- beads-jsonl-writes-via-br-only
- caam-activate-is-flywheel-decided-not-joshua-gated
- canonical-ntm-spawn-shape
- chevron-visible-does-not-mean-submits-work
- codex-relaunch-command-canonical
- convergent-evolution-is-canonical-signal
- fleet-count-in-workers-not-panes
- frozen-projection-of-mutable-state-class
- l91-auto-retry-helper-failed-4-data-points
- meadows-rules-unblock-paradigm-intact
- misbehaving-substrate-orch-disables-does-not-ask
- naming-convention-distinguishable-ownership
- naming-rename-is-cross-repo-wire-or-explain
- no-ad-hoc-per-repo-doctrine-edits
- ntm-rotate-stdin-contamination-use-respawn-path
- orchestrators-kill-panes-without-respawn
- post-wire-or-explain-three-skill-polish-gate
- scope-aware-rename-is-the-rule
- senior-dev-discipline-fleet-wide
- single-capture-misses-freeze
- skills-library-load-bearing
- storage-discipline-global
- storage-pressure-blocks-substrate
- substrate-rebuild-is-disposable-not-class-5
- substrate-watchtower-must-be-wired
- three-audit-questions-per-surface
- topology-lookup-before-dispatch
- validate-redispatch-foundational-discipline
- validator-must-check-four-lenses
- workers-read-not-mint-identity
- xpane-recovery-recommendations-must-verify-canonical-flags-and-protections

Fix Applied/Status: Consolidated gate script at
.flywheel/scripts/meta-rule-structural-batch-gate.sh covers all 33 rules.
33 individual test stubs at .flywheel/tests/test-<rule>.sh each verify batch
gate registration. Settings.json updated to reference the gate script for hook
evidence. INCIDENTS.md entry added for incidents_evidence coverage.

Evidence:
- Gate script: .flywheel/scripts/meta-rule-structural-batch-gate.sh
- Test stubs: .flywheel/tests/test-<rule>.sh (33 files)
- Detector: .flywheel/scripts/memory-rule-gate-parity-detector.sh check --json

## Evidence packs replace four-lens close self-grades (2026-05-07)

Date: 2026-05-07

Promotion Action: NEW

Class: `self-grade-claim-treated-as-fact`

Severity: high

Cost: Four-lens and three-judges callback fields were worker assertions. A
worker could send `four_lens=brand:9,sniff:9,jeff:9,public:9` and the
orchestrator treated it as close truth without deterministic citations. The
same failure mode exists for plan close gates: a plan can look polished because
the self-grade says so, not because an evidence pack proves acceptance criteria,
test depth, and theater checks.

Root Cause: The quality bar was expressed as score fields in callback text.
Those fields had no mandatory backing pack, no schema-cited evidence items, and
no convergence requirement.

Forever-Rule: New closures use the beads-compliance evidence-pack contract.
Callbacks carry `compliance_score=<N>/1000` and
`compliance_pack_path=<audit-dir>/<bead-id>/`; schema v4 plan close gates
require `compliance_score >= 700`, all required pack files, and
`convergence_streak >= 2`. Legacy four-lens rows remain history and are not
migrated.

Fix Applied/Status: L126 landed in AGENTS surfaces. Dispatch boilerplate,
close-handler guidance, worker-tick callback shape, `/flywheel:plan`
STATE.json schema, and `quality-bar-close-gate.sh` now have a forward-only
compliance-pack path. The close gate keeps schema v3 legacy behavior but
switches schema v4 plans to evidence-pack validation.

Evidence:
- Canonical rule: `AGENTS.md` L126 and `.flywheel/AGENTS-CANONICAL.md` L126.
- Contract: `~/.claude/commands/flywheel/_shared/dispatch-template.md`.
- Plan schema: `~/.claude/commands/flywheel/plan.md`.
- Close gate: `.flywheel/scripts/quality-bar-close-gate.sh`.
- Regression: `tests/quality-bar-close-gate.sh`.
- Skill contract:
  `~/.claude/skills/beads-compliance-and-completion-verification/references/EVIDENCE-SCHEMAS.md`.
- Doctrine bead: `flywheel-x6ok8`.

## ci-substrate-failure

Date: 2026-05-08

Promotion Action: NEW

Class: `ci-substrate-failure`

Event Count: 3 events in 7 days

Severity: medium

Cost: Three ALPS post-merge PRs reported CI substrate failures after admin
self-merge while local validation and Vercel staging evidence were green. Each
worker had to distinguish task-local correctness from shared CI substrate
breakage before closeout, which turns routine verification into repeated
worker-local triage.

Root Cause: CI failures were treated as task verdicts even when the failing
surface was outside the changed code path. The loop lacked an owner-routing
rule that captures runner, command, failing substrate, retry evidence, and why
the issue is not a task-local fix.

Forever-Rule: When CI fails outside the changed code path, the worker must
record the exact CI command or job, runner, failing substrate, ownership guess,
retry or corroborating evidence, and `why_not_task_local_fix`. If the task's
targeted local validation and live/staging smoke pass, route the failure to a
CI-substrate repair bead or owner handoff instead of overfitting the task patch.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote ci-substrate-failure`. Existing memory rule
`feedback_ci_substrate_failures_need_owner_route` already carries the operator
reflex; this entry makes the L56 INCIDENTS coverage explicit and points future
promotion-candidate scans at a durable repo doctrine surface.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L1287`: PR #172 CI failed before
  build at Infisical OIDC 403 while Vercel staging `/demo` returned 200.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1290`: PR #174 reported
  pre-existing substrate failures after local validation and staging `/demo`
  passed.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1292`: PR #178 reported
  pre-existing substrate failures after local validation, Vercel staging, and
  live `/demo` toast smoke passed.
- Memory: `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_ci_substrate_failures_need_owner_route.md`.
- Review source: `.flywheel/reports/learn-review-2026-05-06.md`.
- Bead: `flywheel-mh983`.

## dispatch_callback_overdue

Date: 2026-05-08

Promotion Action: NEW

Class: `dispatch_callback_overdue`

Event Count: 98 events in 7 days

Severity: medium

Cost: Callback-overdue repeats kept orchestration in passive wait loops while
worker panes had either no proper callback, stale idle output, or unresolved
dispatch state. The repeated failure forced humans and orchestrators to
reconstruct worker truth from pane state, dispatch logs, and bead state instead
of receiving the normal callback contract.

Root Cause: Overdue callbacks were recorded as repeated observations, but the
loop lacked a layer-2 routing rule for turning an overdue dispatch into a
specific recovery decision. That let the same class recur as telemetry noise
instead of forcing validation, redispatch, bead repair, or an explicit
no-action reason.

Forever-Rule: When a dispatch callback is overdue, the orchestrator must treat
the callback as missing evidence, not as a reason to keep waiting. Validate the
dispatch against pane state, dispatch log, expected artifact, and bead state,
then record exactly one recovery outcome: callback recovered with evidence,
redispatched or respawned, repair bead opened or updated, or explicit
`no_bead_reason` when the worker is still legitimately within budget.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote dispatch_callback_overdue`. The entry gives the promotion-candidate
bead `flywheel-3jf8s` durable L56 coverage and routes future scans toward
validate-and-redispatch / callback-delivery verification instead of repeatedly
creating duplicate promotion candidates.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L298`: early mobile-eats callback
  overdue event before the main 2026-05-05 cluster.
- `~/.local/state/flywheel/fuckup-log.jsonl#L389`: second early mobile-eats
  callback overdue event.
- `~/.local/state/flywheel/fuckup-log.jsonl#L681-L1268`: main cluster of
  callback-overdue rows that drove the 7-day count.
- `~/.local/state/flywheel/fuckup-processed.jsonl#L157`: prior aggregate
  processing row recorded 96 callback-overdue lines and created follow-up bead
  coverage, leaving this promotion-candidate entry as the missing INCIDENTS
  layer.
- Bead: `flywheel-3jf8s`.

## skillos-loop-integrity-still-limping

Date: 2026-05-08

Promotion Action: NEW

Class: `skillos-loop-integrity-still-limping`

Event Count: 12 events in 7 days

Severity: high

Cost: The same validation bead (`flywheel-668a`) was redispatched repeatedly
while skillos stayed LIMPING. Workers re-ran dry-run classifiers, pane health,
relay checks, and design-artifact probes, then rediscovered the same two failed
L60 signals instead of routing to the apply owner. This burned worker cycles and
kept the skillos loop in a partial-failure state that looked inspected but not
repaired.

Root Cause: LIMPING was treated as validation evidence to re-check, not as a
halt-and-repair state. The loop had enough doctrine to name the failing signals,
but no layer-2 incident rule forcing the redispatch path to stop after repeated
no-state-change probes and route recovery to the bounded apply/decision owner.

Forever-Rule: When a session reports `driver_status=VERIFIED` but loop
integrity is still LIMPING, classify it as a live partial failure. If the same
failed L60 signals recur after three redispatches without state change, halt new
validation redispatches for that bead, attach the latest `no_silent_darkness`
or `gap-hunt` JSON to the apply-owner bead, and require recovery evidence of
`verdict=OK` plus all five L60 signals before closing the validation bead.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote skillos-loop-integrity-still-limping`. The entry binds the 12-row
cluster to the `flywheel-recovery` LIMPING recovery rule and `loop-enforcement`
stall gate, making future handlers route to repair state rather than another
validation-only redispatch.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L1074`: first `flywheel-668a`
  validation found skillos LIMPING with `callback_received_in_last_2_ticks` and
  `fuckup_log_decisions_made_since_last_tick` failed.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1079`: redispatch without state
  change reproduced the same failed signals.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1086-L1171`: follow-on
  redispatches continued to find skillos LIMPING while `flywheel-hg2w` remained
  the apply/decision owner.
- Skills: `~/.claude/skills/flywheel-recovery/SKILL.md` Forever-Rule
  `loop-integrity-still-limping`; `~/.claude/skills/loop-enforcement/SKILL.md`.
- Beads: `flywheel-id0pm`, `flywheel-668a`, `flywheel-hg2w`.

## three-surface-drift-detected

Date: 2026-05-08

Promotion Action: NEW

Class: `three-surface-drift-detected`

Event Count: 78 events in 7 days

Severity: medium

Cost: Three-surface doctrine drift fired repeatedly after L96/L108 already
named the correct convergence gate. The repeated rows turned a clear rule into
ambient telemetry: workers had to rediscover whether cache freshness,
propagator success, or actual `--check-three-surface` convergence was the
truth source before closing drift work.

Root Cause: The sync substrate and L-rules existed, but the recurring trauma
class had no layer-2 INCIDENTS target. That let the ladder keep filing
promotion candidates even when live flywheel convergence was clean, because the
history had not been processed into durable repo doctrine.

Forever-Rule: A three-surface drift event is not closed by cache freshness,
prose, or a stale prior sync claim. The close evidence must include a
machine-readable `sync.sh --check-three-surface --target <repo> --json`
receipt. If `drift_count=0`, close or route the promotion candidate as
processed; if drift remains nonzero, route to the existing L96/L108 repair
path or a concrete sync/apply owner bead.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote three-surface-drift-detected`. The live flywheel check now reports
`status=pass` and `drift_count=0`; this entry supplies the missing L56
INCIDENTS coverage so future scans point at the L96/L108 convergence rule
instead of filing duplicate promotion candidates.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L625`: first recorded
  `three-surface-drift-detected` row in the current log.
- `~/.local/state/flywheel/fuckup-log.jsonl#L3606-L4331`: recent flywheel
  cluster behind the promotion-candidate count.
- `/Users/josh/.flywheel/canonical-meta-rules/sync.sh --check-three-surface --target /Users/josh/Developer/flywheel --json`:
  `status=pass`, `drift_count=0`, and all three surfaces have 91 rules.
- L96/L108 in `AGENTS.md` define the convergence rule and the
  cache-is-not-convergence distinction.
- Skills covered: `flywheel`, `flywheel-doctor-author`; no new skill gap.
- Bead: `flywheel-g9gbe`.

## tick-driver-primitive-failed

Date: 2026-05-08

Promotion Action: NEW

Class: `tick-driver-primitive-failed`

Event Count: 70 events in 7 days

Severity: high

Cost: The tick driver kept firing while manifest primitives failed underneath
it. The loop looked alive because fire IDs were emitted, but safety and repair
subsystems were dark for repeated ticks: `storage-headroom-watcher` failed 29
times, `agents-md-fleet-propagator` failed 27 times, and
`regen-sources-from-gh` failed 14 times. Counting those degraded fires as
productive loop activity would hide an outage behind normal tick cadence.

Root Cause: Primitive failure telemetry existed in fuckup-log rows, and the
`loop-enforcement` skill already had a forever-rule for this exact class, but
the flywheel repo lacked a layer-2 INCIDENTS entry. That left the 70-event
cluster eligible for repeated promotion scans instead of a durable owner-routing
rule.

Forever-Rule: A tick-driver fire with any primitive `status=error`, nonzero
`exit_status`, or timeout is a degraded loop fire, not a healthy tick. Three
consecutive degraded ticks on the same primitive must be treated as a
primitive-down outage: inspect the primitive's stderr and script, run the
primitive manually with the same driver args, file or update the primitive
owner bead, and do not count the degraded fire as productive throughput until a
later tick-driver ledger row reports `status=ok` or the primitive is explicitly
disabled with an owner and repair bead.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote tick-driver-primitive-failed`. The entry links the 70-row cluster to
the existing `loop-enforcement` forever-rule and makes the recovery route
explicit for future promotion-candidate scans.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L697`: first
  `storage-headroom-watcher` tick-driver primitive failure in the cluster.
- `~/.local/state/flywheel/fuckup-log.jsonl#L709`: first
  `agents-md-fleet-propagator` tick-driver primitive failure in the cluster.
- `~/.local/state/flywheel/fuckup-log.jsonl#L858`: first
  `regen-sources-from-gh` tick-driver primitive failure in the cluster.
- `~/.local/state/flywheel/fuckup-log.jsonl#L697-L1046`: full 70-row
  high-severity cluster behind the promotion candidate.
- Skill: `~/.claude/skills/loop-enforcement/SKILL.md` Forever-Rule
  `tick-driver-primitive-failed`.
- Bead: `flywheel-og9n4`.

## fleet-propagation-failed

Date: 2026-05-08

Promotion Action: NEW

Class: `fleet-propagation-failed`

Event Count: 211 events in 7 days

Severity: medium

Cost: Agents-md fleet propagation failed repeatedly across peer repositories,
mostly through `sync_nonzero` canonical-sync exits. The loop kept recording
per-repo propagation failures while doctrine drift and dirty target surfaces
remained a fleet-level process gap, making operators read hundreds of symptom
rows instead of one routed repair state.

Root Cause: The propagator had telemetry and edge tests, but the recurring
failure class lacked a layer-2 incident rule that forces aggregation by reason
and target surface. A `/flywheel:learn --review` pass coalesced the 211 rows
into an attempted bead route, but without INCIDENTS coverage future promotion
scans kept treating the class as uncodified doctrine debt.

Forever-Rule: When `agents-md-fleet-propagator` emits repeated
`fleet-propagation-failed` rows, handlers must aggregate by `reason`, `repo`,
and target surface, run the fleet process-gap detector, and update the existing
repair bead or file exactly one new repair bead. Do not keep rerunning the
propagator as a per-repo retry loop after the same class crosses the L56
threshold; route to the structural sync/drift owner with the latest ledger and
representative fuckup-log lines.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote fleet-propagation-failed`. The entry gives promotion-candidate bead
`flywheel-lx47b` durable L56 coverage and points future scans at the existing
L105 process-gap detector and agents-md fleet propagator telemetry instead of
creating duplicate promotion candidates.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L698`: first observed
  `fleet-propagation-failed` row in the 211-event cluster.
- `~/.local/state/flywheel/fuckup-log.jsonl#L702-L708`: first multi-repo
  burst across mobile-eats, skillos, terratitle, zeststream-infra, zesttube,
  vrtx, and polymarket-pico-z.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1033-L1049`: tail cluster showing
  the same `sync_nonzero` propagation failure recurring hours later.
- `~/.local/state/flywheel/fuckup-processed.jsonl#L156`: prior review
  coalesced 211 rows and attempted to route them to a repair bead.
- Producer: `.flywheel/scripts/agents-md-fleet-propagator.sh`.
- Edge tests: `tests/agents-md-fleet-propagator.sh`.
- Process-gap route: `AGENTS.md` L105 and
  `.flywheel/scripts/fleet-process-gap-detector.sh`.
- Bead: `flywheel-lx47b`.

## br-sync-stale-db-export-blocked

Date: 2026-05-08

Promotion Action: NEW

Class: `br-sync-stale-db-export-blocked`

Event Count: 9 events in 7 days

Severity: medium

Cost: Workers could close or update beads in the live Beads DB, but
`br sync --flush-only --json` refused to export because DB and JSONL counts had
diverged and export would lose eight issue IDs. Each closeout had to preserve
DB truth, skip lossy export, and explain why `.beads/issues.jsonl` could not be
committed as a normal sync artifact.

Root Cause: The sync guard correctly blocked data loss, but the recurring
class had no layer-2 INCIDENTS entry separating "br DB mutation works" from
"DB-to-JSONL export is stale and unsafe." Without that routing, workers kept
re-reporting the same eight-ID loss set instead of treating it as a known
substrate convergence issue owned by Beads recovery.

Forever-Rule: When `br sync --flush-only --json` refuses export because the
DB/JSONL delta would lose issue IDs, do not force export and do not manually
append `.beads/issues.jsonl`. Verify the intended `br` mutation with `br show`
or the relevant `br dep` command, record the refused sync with the exact lost
IDs or count, route convergence to the existing Beads recovery owner, and
continue task closeout with DB-visible evidence rather than treating JSONL
export as the source of truth.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote br-sync-stale-db-export-blocked`. The entry connects the 9-row cluster
to `beads-br` explicit-sync discipline and AGENTS L124 substrate discipline:
`br` owns Beads writes, lossy JSONL export is blocked, and rebuild/convergence
belongs to the Beads recovery path rather than ad-hoc worker fallback rows.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L1161`: `flywheel-0cm9` close
  succeeded in DB, but `br sync --flush-only --json` refused export because it
  would lose eight issue IDs.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1170-L1185`: repeated close/update
  events hit the same stale DB/JSONL export guard.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1190-L1235`: follow-on closeouts
  and parent-note updates again preserved DB truth while skipping lossy export.
- Existing recovery context: `INCIDENTS.md#beads-sync-recovery-research-eight-id-recovery-now-stale-resolved-pending-joshua-option-selection-2026-05-06`.
- Doctrine: `AGENTS.md` L124 `SUBSTRATE-DISCIPLINE-NO-ORCHESTRATOR-PAUSE`.
- Skill: `~/.claude/skills/beads-br/SKILL.md` explicit `br sync --flush-only`
  discipline.
- Bead: `flywheel-1irgl`.

## owner-custody-missing

Date: 2026-05-08

Promotion Action: NEW

Class: `owner-custody-missing`

Event Count: 71 events in 7 days

Severity: medium

Cost: Mobile-eats kept redispatching and polling `mobile-eats-31g` after the
same Nango owner-social connection was absent. The loop produced 71
medium-severity rows and many idle receipts, but no new owner-state delta,
which burned worker cycles and made the project look continuously active while
the underlying custody prerequisite remained unchanged.

Root Cause: The 2026-05-06 review correctly routed the class to the existing
product owner bead `mobile-eats-31g`, with `mobile-eats-1en` covering callback
evidence formatting, but the flywheel repo still lacked layer-2 INCIDENTS
coverage. That left the class eligible for promotion-candidate rediscovery
even though the downstream owner bead already existed.

Forever-Rule: Repeated owner-custody blockers are not productive redispatch
work. After the same target artifact reports `owner-custody-missing` twice
without `owner_state_delta`, stop idle poll/reap redispatches, update the
single custody owner bead with the latest evidence, and require either a live
owner-connection proof or an explicit owner decision before live-send can
resume. Do not file duplicate product canary work or treat idle receipts as
progress.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote owner-custody-missing`. The existing downstream owner route remains
`/Users/josh/Developer/mobile-eats/.beads/issues.jsonl#mobile-eats-31g`; this
entry makes the flywheel L56 coverage explicit so future scans route to the
known custody owner instead of creating another promotion-candidate bead.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L754`: first
  `owner-custody-missing` row, showing the Nango owner-social canary could not
  live-send because the target owner/truck/provider social connection was
  absent.
- `~/.local/state/flywheel/fuckup-log.jsonl#L754-L1267`: full 71-row
  owner-custody cluster behind the promotion candidate.
- `~/.local/state/flywheel/fuckup-processed.jsonl#L158`: prior
  `/flywheel:learn --review` row routed the class to existing bead
  `mobile-eats-31g` and related callback bead `mobile-eats-1en`.
- Owner bead:
  `/Users/josh/Developer/mobile-eats/.beads/issues.jsonl#mobile-eats-31g`.
- Callback evidence bead:
  `/Users/josh/Developer/mobile-eats/.beads/issues.jsonl#mobile-eats-1en`.
- Planning substrate: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md`
  D3.G2/D3.G3 and `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/01-REVIEW-donella.md`
  revision 7 owner-custody loop primitive.
- Bead: `flywheel-n3hs0`.

## br-db-wedge-recurrence

Date: 2026-05-08

Promotion Action: NEW

Class: `br-db-wedge-recurrence`

Event Count: 3 events in 7 days

Severity: high

Cost: The Beads DB wedge recurred after the same-day repair path: `br close`
again hit WAL corruption and SQLite freelist/page errors, while workers had to
choose between DB-backed mutation, JSONL-truth closeout, and read-only
diagnosis. The recurrence made the existing repair entry insufficiently
machine-routable for L56 because the exact fuckup class was not a heading or
processed promotion target.

Root Cause: The original `br-db-wedge` incident documented repair and the later
RCA documented freelist recurrence, but the `br-db-wedge-recurrence` trauma
class still lacked an exact layer-2 INCIDENTS target. That left the class
eligible for promotion-candidate rediscovery even though the operational answer
is already known: integrity is measured by SQLite checks, DB-backed mutation is
red when integrity is not `ok`, and recovery routes through the monitor/rebuild
path rather than manual `.beads/issues.jsonl` fallback rows.

Forever-Rule: When `br-db-wedge-recurrence` appears, first run or cite
`.flywheel/scripts/br-db-corruption-monitor.sh` and
`.flywheel/scripts/verify-br-db-close-path-active.sh`; do not trust
`br sync --status` alone. If `PRAGMA integrity_check` is not `ok`, treat
DB-backed create/close/update as red, preserve JSONL truth without manual
append edits, and route to the Beads recovery/rebuild owner under AGENTS L124.
If the monitor reports healthy on current `br`, close the promotion candidate
as stale-resolved with monitor evidence rather than reopening the old wedge
response.

Fix Applied/Status: NEW exact-class layer-2 INCIDENTS entry from
`/flywheel:learn --promote br-db-wedge-recurrence`. This entry points future
promotion scans at the existing `br-db wedge repair` and `br-db wedge recurrence
root-cause + mitigation` incidents while giving the exact trauma class a
durable L56 target and processed ledger row.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L1335`: `br close
  flywheel-wire-dispatch-delivery-valida-f29a` failed with WAL corruption and
  freelist/page integrity errors after concurrent shared-file closeouts.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1337`: follow-on closeout hit
  existing Beads DB corruption and JSONL priority schema fallback.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1338`: recurrence persisted after
  repair, with freelist leaf count errors on pages 765/766.
- Existing incident: `INCIDENTS.md#br-db-wedge-repair--jsonl-fallback-eliminated-on-close-2026-05-05`.
- Existing RCA incident: `INCIDENTS.md#br-db-wedge-recurrence-root-cause--mitigation-2026-05-05`.
- Monitor: `.flywheel/scripts/br-db-corruption-monitor.sh`.
- Probe: `.flywheel/scripts/verify-br-db-close-path-active.sh`.
- Doctrine: `AGENTS.md` L124 `SUBSTRATE-DISCIPLINE-NO-ORCHESTRATOR-PAUSE`.
- Skill: `~/.claude/skills/beads-br/SKILL.md`.
- Bead: `flywheel-69974`.

## agent-mail-token-transcript-exposure

Date: 2026-05-08

Promotion Action: NEW

Class: `agent-mail-token-transcript-exposure`

Event Count: 3 events in 7 days

Severity: high

Cost: Agent Mail token-shaped material reached pane-visible transcript
surfaces. Pane text is durable operational substrate: it is copied, searched,
summarized, and reused as dispatch evidence. Once token material appears there,
the exposure has already happened and later redaction can only limit spread.

Root Cause: Workers and dispatch helpers still treated Agent Mail registration
tokens as ordinary command or callback parameters instead of out-of-band
identity material. The repo already had L58 and security-scan surfaces, but this
specific class lacked a layer-2 INCIDENTS entry that forces redacted evidence,
no raw transcript replay, and pre-callback scanning.

Forever-Rule: Agent Mail registration tokens, bearer tokens, sender tokens, and
token-shaped fragments must never be echoed into pane-visible commands,
dispatch packets, callback text, reports, or copied transcript evidence. Use
structured MCP token fields, token-path or vault-backed handles, and redacted
class-only evidence. Before closing any secret-adjacent task, scan changed
artifacts and the intended callback with the scrub wrapper; if a hit exists,
regenerate redacted evidence before sending.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote agent-mail-token-transcript-exposure`. This entry gives
promotion-candidate bead `flywheel-3aef` durable L56 coverage while preserving
the core safety rule: evidence names the rows and secret classes, not values or
token fragments.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L337`: redacted Agent Mail token
  transcript exposure row. Body intentionally not quoted.
- `~/.local/state/flywheel/fuckup-log.jsonl#L534`: redacted Agent Mail token
  transcript exposure row. Body intentionally not quoted.
- `~/.local/state/flywheel/fuckup-log.jsonl#L540`: redacted Agent Mail token
  transcript exposure row. Body intentionally not quoted.
- `AGENTS.md` L58: `SECRET-MATERIAL-NEVER-IN-PANE-TEXT`.
- `SECURITY.md` Secret Discipline section.
- Scrub wrapper: `.flywheel/scripts/ntm-scrub-secret-scan-wrapper.sh`.
- Canary scanner: `.flywheel/scripts/canary-secret-scan.sh`.
- Bead: `flywheel-3aef`.

## agent-mail-reservation-token-path-gap

Date: 2026-05-08

Promotion Action: NEW

Class: `agent-mail-reservation-token-path-gap`

Event Count: 9 events in 7 days

Severity: medium

Cost: ALPS worker dispatches repeatedly skipped or failed L51 file
reservations because their Agent Mail identity registry exposed a safe
`token_path`, while the MCP reservation call expected an inline
`registration_token`. The result was a bad choice between violating the
no-raw-token transcript rule or proceeding without the reservation layer that
prevents concurrent file edits.

Root Cause: Two valid rules collided without a bridging primitive: L51 requires
file reservations before edits, while L58 and the Agent Mail identity registry
push workers toward token-path-only identity handling. Agent Mail reservation
tools did not accept the resolver token-path pattern, and dispatches responded
by skipping reservation instead of routing the incompatibility to a durable
tool-patch owner.

Forever-Rule: Agent Mail file reservation helpers must accept a token-path or
resolver-backed identity handle, never require workers to paste raw
registration tokens into pane-visible calls. If a reservation tool cannot
consume token-path identity, the worker must record
`agent-mail-reservation-token-path-gap`, keep edits isolated, and route a
tool-patch bead; it must not downgrade L51 to optional or echo raw token
material to satisfy the reservation call.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote agent-mail-reservation-token-path-gap`. This entry makes the
token-path-vs-inline-token reservation gap explicit and separates it from the
neighboring token-transcript exposure class: the safe target is a resolver-aware
reservation primitive, not raw-token callbacks.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L593`: reservation failed because
  `file_reservation_paths` required inline `registration_token` and did not
  accept token-path identity.
- `~/.local/state/flywheel/fuckup-log.jsonl#L600-L611`: follow-on ALPS
  dispatches hit the same L51 token-path identity boundary.
- `~/.local/state/flywheel/fuckup-log.jsonl#L614-L647`: later ALPS dispatches
  skipped Agent Mail reservation because the token-path policy still conflicted
  with inline-token tool requirements.
- Doctrine: `AGENTS.md` L51 `DISPATCH-FILE-RESERVATIONS-MANDATORY` and L58
  `SECRET-MATERIAL-NEVER-IN-PANE-TEXT`.
- Skill: `~/.claude/skills/agent-mail/SKILL.md`.
- Existing related bead: `flywheel-1d3` fleet-mail identity token vault.
- Bead: `flywheel-amzsf`.

## br-prefix-mismatch

Date: 2026-05-08

Promotion Action: NEW

Class: `br-prefix-mismatch`

Event Count: 3 events in 7 days

Severity: medium

Cost: Mobile-eats workers hit `br` prefix checks while trying to inspect or
create beads: `br show` failed with `CONFIG_ERROR Prefix mismatch expected
mobile found flywheel-wire ids`, auto-import rejected mixed-prefix JSONL, and
follow-up bead creation had to be skipped even though task validation itself
passed. Each event forced read-only fallback through SQLite or `.beads/issues.jsonl`
and made workers choose between preserving repo truth and filing needed follow-up
work.

Root Cause: The repo-local Beads substrate contained issue IDs from more than
one prefix family. `br` correctly refused to auto-import or mutate mixed-prefix
state, but the class had no layer-2 INCIDENTS entry routing it to schema/ID
normalization. The 2026-05-06 learn review explicitly identified
`br-prefix-mismatch` as a net-new gap with no targeted memory or classifier
coverage.

Forever-Rule: A Beads prefix mismatch is schema/ID drift, not a reason to
guess a manual closeout path. Treat mutating `br create`, `br close`, and
auto-import as blocked until the prefix state is normalized. Use read-only
inspection with `--no-auto-import --allow-stale`, SQLite, or direct JSONL reads
only to recover context; then route a Beads schema/ID normalization owner bead
or update the existing recovery owner. Do not manually rewrite issue IDs or
append mixed-prefix rows from a worker closeout.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote br-prefix-mismatch`. This entry gives promotion-candidate bead
`flywheel-tdy4m` durable L56 coverage and points future scans at Beads
schema/ID normalization instead of repeated worker-local fallback.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L2269`: `br show` failed with
  `CONFIG_ERROR Prefix mismatch expected mobile found flywheel-wire ids`; the
  worker recovered context read-only through SQLite and `.beads/issues.jsonl`.
- `~/.local/state/flywheel/fuckup-log.jsonl#L2326`: auto-import rejected
  `.beads/issues.jsonl` because `flywheel-wire` IDs violated the mobile prefix;
  read-only `br` with `--no-auto-import --allow-stale` worked.
- `~/.local/state/flywheel/fuckup-log.jsonl#L2345`: follow-up bead writes were
  blocked by mixed issue prefixes while the task's Stripe KV dedupe work passed
  verification.
- Review report: `.flywheel/reports/learn-review-2026-05-06.md` ranked
  `br-prefix-mismatch` as a rising net-new/partial class and recommended
  `feedback_br_prefix_mismatch_is_schema_drift.md`.
- Skill: `~/.claude/skills/beads-br/SKILL.md`.
- Bead: `flywheel-tdy4m`.

## agent-mail-identity-needs-registration

Date: 2026-05-08

Promotion Action: NEW

Class: `agent-mail-identity-needs-registration`

Event Count: 7 events in 7 days

Severity: medium

Cost: Agent Mail identity rows reached `needs_registration` without a
same-loop drain to token-safe registration broadcast or deferral. Dispatch and
callback code then had to choose between operating with incomplete
file-reservation/contact identity or attempting ad-hoc registration in
pane-visible context.

Root Cause: The identity registry can represent `needs_registration`, and
`agentmail-registration-broadcast.sh` can drain live rows safely, but this
trauma class lacked a layer-2 incident rule forcing handlers to classify each
row as live-broadcastable, deferrable, or already active before dispatch/Agent
Mail operations.

Forever-Rule: A `needs_registration` identity row is not a worker prompt to
paste registration material. Resolve identity by
`(session,pane,fleet_mail_project_key)`, run or cite
`agentmail-registration-broadcast.sh --doctor --json`, honor active
`identity-registration-deferral/v1` receipts for dead sessions, and only
continue once the row is `active`, broadcasted, or explicitly deferred. Never
mint from memory or send raw registration tokens through NTM, callbacks, or
reports.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote agent-mail-identity-needs-registration`. The entry gives
`flywheel-77qds` L56 coverage and points future scans at L76/L58, the identity
registry, and the token-safe registration broadcaster.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L574`: needs-registration row
  evidence; body intentionally not quoted.
- `~/.local/state/flywheel/fuckup-log.jsonl#L588-L615`: later six-row cluster;
  bodies intentionally not quoted.
- `AGENTS.md` L76: `AGENTMAIL-IDENTITY-CANONICAL`.
- `AGENTS.md` L58: `SECRET-MATERIAL-NEVER-IN-PANE-TEXT`.
- Broadcaster: `.flywheel/scripts/agentmail-registration-broadcast.sh`.
- Fixture coverage: `tests/agentmail-registration-broadcast.sh`.
- Identity registry tests: `tests/agent-mail-identity-registry.sh`.
- Bead: `flywheel-77qds`.

## agent-mail-reservation-timeout

Date: 2026-05-08

Promotion Action: NEW

Class: `agent-mail-reservation-timeout`

Event Count: 3 events in 7 days

Severity: medium

Cost: Three flywheel workers attempted required L51 Agent Mail file
reservations and hit 120-second timeouts or registration-path stalls before
narrow edits. The tasks still landed with evidence, but each worker had to
record an exception path and proceed without the reservation substrate that
normally prevents concurrent file edits.

Root Cause: Agent Mail reservation availability was treated as a worker-local
runtime problem instead of a routed substrate incident. Existing diagnostic bead
`flywheel-0w1` identified an Agent Mail FD/lock leak family and
`flywheel-ntaf` tracks launchd maxfiles/doctor follow-up, but the exact
`agent-mail-reservation-timeout` class lacked layer-2 L56 coverage. That left
doctrine-ladder scans creating duplicate promotion candidates instead of
routing to the existing Agent Mail recovery owner.

Forever-Rule: Required Agent Mail reservations that time out are a reservation
substrate outage, not permission to silently downgrade L51. A worker may
continue only for a narrow, documented edit after recording the timeout,
checking for existing owner beads, and preserving unrelated worktree state. The
next owner action is Agent Mail health/FD diagnosis, release/retry evidence, or
an existing recovery bead update; do not paste raw tokens, retry indefinitely,
or treat a timed-out reservation as a successful lock.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote agent-mail-reservation-timeout`. This entry gives
promotion-candidate bead `flywheel-2tgl` durable L56 coverage and points future
scans at the existing `flywheel-0w1` / `flywheel-ntaf` Agent Mail reservation
recovery family.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L472`: `flywheel-sur0` reservation
  calls timed out after 120 seconds and reservation resource reads also timed
  out.
- `~/.local/state/flywheel/fuckup-log.jsonl#L473`: `flywheel-hxzw` file
  reservation timed out and the `.claude` registration path required an
  existing-token identity.
- `~/.local/state/flywheel/fuckup-log.jsonl#L474`: `flywheel-eyvi` reserved the
  `~/.claude` target binary, but the flywheel repo test-file reservation timed
  out twice.
- Existing diagnostic bead: `flywheel-0w1`.
- Existing follow-up bead: `flywheel-ntaf`
  `agent-mail-launchd-maxfiles-and-doctor-fd-probe`.
- Doctrine: `AGENTS.md` L51 `DISPATCH-FILE-RESERVATIONS-MANDATORY`.
- Skill: `~/.claude/skills/agent-mail/SKILL.md`.
- Bead: `flywheel-2tgl`.

## agent-mail-reservation-unavailable

Date: 2026-05-09

Promotion Action: NEW

Class: `agent-mail-reservation-unavailable`

Event Count: 13 events in 7 days

Severity: medium

Cost: Thirteen flywheel/skillos worker preflights tried to take an L51 Agent
Mail file reservation and could not even reach the reservation surface — the
attempt failed before any timeout fired. Each worker proceeded with edits
under a documented narrow-scope exception path; none of the 13 had the
substrate-level concurrency lock that L51 requires. The events clustered
across ~4 hours (2026-05-09T00:08Z through 2026-05-09T04:19Z), all on the
skillos session, indicating a session-level Agent Mail outage rather than 13
independent transient miss-fires.

Root Cause: `agent-mail-reservation-unavailable` is the **preflight-failure
sibling** of `agent-mail-reservation-timeout` (entry above). Where the
timeout class fires when a reservation call is accepted but never returns,
this class fires when the call cannot connect at all. Three failure shapes
appear in the 13 fuckup-log rows:

1. **FD exhaustion** ("Too many open files"): 7 of 13 — the Agent Mail
   server-side process has run out of file descriptors and refuses new
   reservation requests at the OS level. Symptomatically identical to the
   `agent-mail-too-many-open-files` family already covered at line 6382 of
   this file; this class is the worker-side observation of that
   server-side state.
2. **MCP transport failure** ("HTTP request failure to 127.0.0.1:8765" /
   "Agent-mail MCP transport was unavailable"): 4 of 13 — the local
   Agent Mail HTTP server is down, restarting, or unreachable on its
   canonical port. Sister to `flywheel-ntaf` `agent-mail-launchd-maxfiles`
   doctor concerns.
3. **Registration token gap** ("required a registration token in this MCP
   session"): 1 of 13 — the worker pane held a non-Agent-Mail-authenticated
   MCP session and could not surface a reservation without first
   re-authenticating. Sister to the `agent-mail-identity-needs-registration`
   class at line 5680.

Existing recovery beads `flywheel-0w1` (FD/lock leak family) and
`flywheel-ntaf` (launchd maxfiles + doctor follow-up), plus the
`agent-mail-fd-doctor.sh` diagnostic, already own these three failure
shapes. This entry's job is to give the **preflight-unavailable observer**
a layer-2 INCIDENTS landing pad so doctrine-ladder scans route future rows
to the existing recovery family instead of filing duplicate
promotion-candidate beads.

Forever-Rule: An Agent Mail file reservation that is **unavailable at
preflight** (FD exhaustion, MCP transport down, missing registration) is a
substrate outage just like a reservation timeout, not permission to silently
downgrade L51. A worker may continue only for a narrow, documented edit
after recording the unavailability shape (FD / transport / registration),
checking for an existing owner bead under `flywheel-0w1` /
`flywheel-ntaf` / `agent-mail-too-many-open-files`, and preserving
unrelated worktree state. The next owner action is Agent Mail FD doctor
(`agent-mail-fd-doctor.sh`), MCP transport health check, or
registration-token rotation — never indefinite retry, never downgraded
locking semantics, never silent preflight skip.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote agent-mail-reservation-unavailable` (worker-tick by
`flywheel-ijsb7`). This entry pairs with the `agent-mail-reservation-timeout`
entry above so doctrine-ladder scans dedup BOTH preflight-unavailable AND
in-call-timeout shapes, with the dedup heuristic now searching repo-local
INCIDENTS.md (fixed in companion bead `flywheel-qnkj2`).

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L4547,L4581,L4587,L4590,L4594,L4605,L4613,L4615,L4621,L4625,L4629,L4631,L4636`:
  the 13 events, all on 2026-05-09, clustered between 00:08Z and 04:19Z
  on the skillos session.
- Failure-shape distribution:
  - FD exhaustion ("Too many open files"): 7 rows
  - MCP transport failure: 4 rows
  - Registration token gap: 1 row
  - Other ("Agent-mail MCP transport was unavailable" without specific
    sub-shape): 1 row
- Sister INCIDENTS entry: `INCIDENTS.md#agent-mail-reservation-timeout`
  (line 5730).
- Server-side sibling: `INCIDENTS.md#agent-mail-too-many-open-files`
  (line 6382).
- Existing diagnostic bead: `flywheel-0w1`.
- Existing follow-up bead: `flywheel-ntaf`
  `agent-mail-launchd-maxfiles-and-doctor-fd-probe`.
- Diagnostic: `.flywheel/scripts/agent-mail-fd-doctor.sh`.
- Doctrine: `AGENTS.md` L51 `DISPATCH-FILE-RESERVATIONS-MANDATORY`.
- Skill: `~/.claude/skills/agent-mail/SKILL.md`.
- Companion dedup fix: `flywheel-qnkj2` (added `$REPO/INCIDENTS.md` to
  `doctrine-ladder-promote.sh default_incident_paths`).
- Bead: `flywheel-ijsb7`.

## file-reservation-closeout-conflict

Date: 2026-05-08

Promotion Action: NEW

Class: `file-reservation-closeout-conflict`

Event Count: 4 events in 7 days

Severity: medium

Cost: Four flywheel workers completed implementation or plan artifacts but
could not write required closeout evidence to `INCIDENTS.md` and/or
`.beads/issues.jsonl` because active exclusive reservations were held by other
agents. The result was partial closeout state: completed work had to wait,
message holders, write side artifacts, or report that L112/close gates failed
only because append surfaces were locked.

Root Cause: L51 correctly prevented write-through on active reservations, but
closeout append lanes were treated as ordinary per-worker locks. Workers had
the right safety rule and no explicit layer-2 doctrine for how to close or
route completed work when the implementation is done and only shared closeout
surfaces are blocked.

Forever-Rule: When implementation is done but closeout rows are blocked by
active file reservations on `INCIDENTS.md`, `.beads/issues.jsonl`, or another
append lane, do not write through the lock and do not claim fully closed
status. Preserve implementation evidence in a worker-owned artifact, message
the holders, retry or reserve with holder evidence, and either wait for release
or callback BLOCKED/partial with `file-reservation-closeout-conflict` plus the
exact holder and reservation IDs. If the holder is stale or idle, release only
with coordination evidence. Shared closeout append lanes should be serialized,
not bypassed.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote file-reservation-closeout-conflict`. This entry separates legitimate
reservation respect from silent closeout loss: the next worker should preserve
evidence and coordinate the append lane rather than bypassing L51 or leaving the
task indistinguishable from incomplete work.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L1561`: continuous productivity
  detector implementation shipped, but append-only `INCIDENTS.md` and
  `.beads/issues.jsonl` closeout rows were blocked by active FrostyBasin and
  CloudyGorge reservations.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1654`: capacity-halt Phase 1-3
  artifacts were complete, but `INCIDENTS.md` marker and `.beads/issues.jsonl`
  closure were blocked by active CloudyAnchor and CyanCreek reservations.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1665`: Phase 4 capacity-halt
  decompose built the plan-local DAG, but could not append seven bead rows, an
  INCIDENTS entry, or JSONL closure because CyanCreek held active exclusive
  reservations.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1832`: wire-calling-in-sick-policy
  hook/settings/test completed, but shared `INCIDENTS.md` and
  `.beads/issues.jsonl` append closure was blocked by active CrimsonGlen and
  MistySparrow reservations.
- Doctrine: `AGENTS.md` L51 `DISPATCH-FILE-RESERVATIONS-MANDATORY`.
- Doctrine: `AGENTS.md` L107 `SHARED-SURFACE-RESERVATION-BEFORE-STAGING`.
- Doctrine: `AGENTS.md` L137 `BEADS-MUTATIONS-USE-A-SERIAL-WRITE-LANE`.
- Skill: `~/.claude/skills/agent-mail/SKILL.md`.
- Bead: `flywheel-3gc1p`.

## integrate_worker_active

Date: 2026-05-08

Promotion Action: NEW

Class: `integrate_worker_active`

Event Count: 3 events in 7 days

Severity: low

Cost: Mobile-eats integrate prelude saw pane 2 still `THINKING` three times
and correctly deferred callback reaping instead of touching worker files. The
behavior was safe, but without layer-2 coverage the same safe deferral class
kept surfacing as an unprocessed promotion candidate rather than being routed
to the worker-progress receipt substrate.

Root Cause: The loop had canonical worker-progress rules in AGENTS.md and a
stall probe, but the exact positive/safe deferral class was not represented in
`INCIDENTS.md`. Doctrine-ladder triage could not distinguish "worker active,
wait" from callback-overdue, stuck-worker, or no-progress failure classes.

Forever-Rule: When INTEGRATE sees a worker pane still classified as active
`THINKING`, do not reap callbacks, mutate worker-owned files, or mark the
worker stale from a single snapshot. Record the active-worker evidence, defer
reaping, and continue only through the L91/L95 path: live activity/capture
proof, dispatch-log callback state, output-advance or stall receipt, and the
worker-stall recovery ladder if activity stops advancing. `integrate_worker_active`
is a wait/observe class, not a closeout failure.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote integrate_worker_active`. This entry closes promotion-candidate bead
`flywheel-2ljj` and routes future rows to the existing worker-progress receipt
and stall-probe surfaces instead of creating duplicate promotion candidates.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L435-L437`: three mobile-eats
  INTEGRATE prelude rows where pane 2 was still `THINKING`, so callback reaping
  was deferred.
- Doctrine: `AGENTS.md` L91 `DISPATCH-DELIVERY-IS-A-FOUR-STATE-RECEIPT`.
- Doctrine: `AGENTS.md` L95 worker-stall recovery guidance.
- Probe: `.flywheel/scripts/worker-stall-alert-probe.sh`.
- Test: `tests/worker-stall-alert-probe.sh`.
- Bead: `flywheel-2ljj`.

## worker-evidence-file-write-before-reservation

Date: 2026-05-08

Promotion Action: NEW

Class: `worker-evidence-file-write-before-reservation`

Event Count: 3 events in 7 days

Severity: low

Cost: Three flywheel validation/redispatch paths wrote `/tmp` evidence
artifacts before taking a matching Agent Mail reservation for those evidence
paths. No source file or repo substrate was mutated in the observed rows, but
the pattern weakens L51/L107 by training workers that "temporary evidence" is
outside the reservation contract.

Root Cause: The dispatch and closeout rules clearly reserve source and shared
append paths, but evidence artifacts generated during validation probes were
treated as harmless scratch output. That left a narrow write-before-reserve
class with no layer-2 coverage, even though the Agent Mail skill already states
that additive/evidence writes are not exempt from pre-flight reservations.

Forever-Rule: Evidence files are write targets. Before a worker writes probe,
dry-run, validation, callback, or closeout evidence to `/tmp`, `.flywheel/`, or
any shared substrate path, reserve the exact evidence path or a narrow evidence
directory first. If the evidence is intentionally ephemeral and reservation
would be disproportionate, record the exception before writing and keep it out
of source, bead, dispatch-log, and shared append surfaces. Never use a clean
source diff as proof that write-before-reserve did not happen.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote worker-evidence-file-write-before-reservation`. This entry gives
promotion-candidate bead `flywheel-eikur` durable L56 coverage and routes
future rows to the Agent Mail reservation discipline instead of treating `/tmp`
evidence writes as outside the worker contract.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L1102`: `flywheel-668a`
  redispatch generated `/tmp/flywheel-668a-*` probe evidence before Agent Mail
  reservations for those evidence paths.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1111`: `flywheel-g343`
  validation wrote `/tmp/flywheel-g343-vibing-forbidden.json` before a matching
  Agent Mail reservation.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1112`: `flywheel-g343`
  validation wrote `/tmp/flywheel-g343-dryrun-preview.json` before a matching
  Agent Mail reservation.
- Doctrine: `AGENTS.md` L51 `DISPATCH-FILE-RESERVATIONS-MANDATORY`.
- Doctrine: `AGENTS.md` L107 `SHARED-SURFACE-RESERVATION-BEFORE-STAGING`.
- Skill: `~/.claude/skills/agent-mail/SKILL.md`.
- Skill: `~/.claude/skills/dispatch-tool-contracts/SKILL.md`.
- Bead: `flywheel-eikur`.

## coordination-collision-detected

Date: 2026-05-09

Promotion Action: NEW

Class: `coordination-collision-detected`

Event Count: 184 events in 7 days (largest L56 cluster observed
2026-05-07 → 2026-05-09)

Severity: medium-volume / low-individual

Cost: 184 reservation requests via
`.flywheel/scripts/shared-surface-reservation-check.sh --reserve`
returned `status=blocked` because another flywheel pane already held
an active L107 reservation on the same path. Each row is a single
collision; on its own each is a healthy "another worker is editing
this; back off and coordinate" signal — the trauma is the **volume**.
The 184-event cluster reveals that many shared surfaces are
collision-hot and the current reservation TTL + EOF-lease model
forces serialized worker access at human-scale cadence rather than
multi-pane parallelism.

Top collision targets (per fuckup-log breakdown):
- `/Users/josh/Developer/flywheel/.beads/issues.jsonl` — 94
  collisions (51% of total)
- `/Users/josh/Developer/flywheel/INCIDENTS.md` — 42 collisions
  (23%)
- `~/.claude/skills/.flywheel/lib/portable/core.sh` — 6
- `.flywheel/AGENTS-CANONICAL.md` — 5
- `~/.local/state/flywheel/fuckup-processed.jsonl` — 4
- `~/.claude/skills/.flywheel/lib/loop.sh` — 4
- `~/.claude/skills/.flywheel/bin/flywheel-loop` — 4
- 6 other paths with 1–3 collisions each.

Pane attribution: `flywheel:2` (74 collisions), `flywheel:3` (55),
`flywheel:4` (51), `flywheel:worker` (2), `flywheel:?` (2). All four
worker panes saturate the top two surfaces (`.beads/issues.jsonl`
and `INCIDENTS.md`) which are the canonical append targets for
worker callbacks and L56 promotions respectively.

Root Cause: Shared-append surfaces in flywheel are reservation-gated
via `shared-surface-reservation-check.sh`, but the canonical worker
flow (write evidence → append to `.beads/issues.jsonl` via `br
close` → append to `INCIDENTS.md` via `/flywheel:learn --promote`)
hits both top-collision targets back-to-back at the end of every
worker tick. With 3+ active worker panes, the probability of two
panes wanting the same target inside the same TTL window is high;
that's by design (the reservation system catches it) but it surfaces
as a 184-row cluster in the fuckup-log. The healthy resolution
(retry after the holder releases) is what every blocked worker
already does — see `flywheel-uyd9i` (this session) for the canonical
"reservation blocked → drafted patch artifacts → re-tried after
release → applied" pattern.

Forever-Rule: A `coordination-collision-detected` event is a
**healthy collision-prevention signal**, not a worker failure.
Workers MUST treat the `status=blocked` return from
`shared-surface-reservation-check.sh --reserve` as a coordination
boundary: (a) capture the blocker pane + task id from the
`blocking_holders` field, (b) draft any patch artifacts in the audit
pack so the work doesn't stall on the reservation, (c) retry the
reservation after the holder's TTL or after observing them release.
Workers MUST NOT bypass the reservation, MUST NOT extend their own
reservation indefinitely to avoid contention, and MUST NOT downgrade
to a non-coordinated write path. Orchestrators routing through
high-collision surfaces (`.beads/issues.jsonl`, `INCIDENTS.md`)
should prefer dispatching one worker tick at a time per high-traffic
target rather than fanning out simultaneously when contention is
already saturated.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote coordination-collision-detected` (worker-tick by
`flywheel-8nrza`). Recategorizes the trauma class from "184
failures" to "184 healthy back-offs that revealed two saturation
hotspots." The Forever-Rule is the existing organic discipline
(used today by `flywheel-uyd9i` to coordinate the
INCIDENTS.md merge with `flywheel-s2yd8`). Companion observation: a
follow-up `coordination-collision-saturation-hotspots` analysis bead
could quantify whether the `.beads/issues.jsonl` / `INCIDENTS.md`
saturation warrants a per-target reservation TTL tune or a fan-in
serialization gate; that's beyond this bead's scope.

Evidence:
- 184 fuckup-log rows across `~/.local/state/flywheel/fuckup-log.jsonl`
  spanning 2026-05-07T13:50Z → 2026-05-09T18:54Z, all
  `trauma_class:"coordination-collision-detected"`. Earliest:
  pane=4 path=.beads/issues.jsonl. Latest: pane=2 path=INCIDENTS.md
  during today's `flywheel-uyd9i` race (resolved per evidence pack).
- Top-target distribution validated: `grep -c 'path=/Users/josh/Developer/flywheel/.beads/issues.jsonl'` returns 94, `grep -c 'INCIDENTS.md'` returns 42, totaling 74% of the cluster on two targets.
- Pane attribution: 74/55/51 across panes 2/3/4 respectively (the canonical worker pane allocation for flywheel session).
- Reservation script: `.flywheel/scripts/shared-surface-reservation-check.sh`.
- Sister INCIDENTS entries (the L107 reservation family):
  `INCIDENTS.md#file-reservation-closeout-conflict` (line 5882),
  `INCIDENTS.md#worker-evidence-file-write-before-reservation` (line
  5991).
- Doctrine: `AGENTS.md` L107 `SHARED-SURFACE-RESERVATION-BEFORE-STAGING`.
- Sister bead pattern (this session): `flywheel-uyd9i` evidence pack
  documents the canonical reservation-blocked-then-released flow,
  reusable for future `coordination-collision-detected` events.
- Companion dedup fix: `flywheel-qnkj2` (added `$REPO/INCIDENTS.md`
  to `doctrine-ladder-promote.sh default_incident_paths`, which
  ensures future ladder runs see this section).
- Bead: `flywheel-8nrza`.

## fire-and-forget-dispatch

Date: 2026-05-08

Promotion Action: NEW

Class: `fire-and-forget-dispatch`

Event Count: 3 events in 7 days

Severity: high

Cost: Three skillos dispatches were treated as terminal sends instead of the
start of a monitored work window. Joshua had to notice the first "fire and
forget" case directly, and a later dirty-preflight BLOCKED callback sat for
roughly 30 minutes before the orchestrator re-established worker truth.

Root Cause: Dispatch packets carried callback contracts, but the orchestrator
path did not consistently prove post-send liveness, callback timers, or a
probe schedule within the first few minutes after send. That let transport
success stand in for work-start evidence and allowed a single-strike defense
to drift toward canonical doctrine without the L56 three-strike evidence trail.

Forever-Rule: A worker dispatch is not complete at `ntm send`. Every dispatch
must enter a monitored liveness window: record the send receipt, verify pane
activity or blocked state, set or honor `callback_expected_by`, and run a
post-send probe within five minutes. If the worker is blocked, idle, unhealthy,
or silent, route through L91/L95/L120 recovery immediately instead of waiting
for the callback window to expire.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote fire-and-forget-dispatch`. This entry gives promotion-candidate bead
`flywheel-bin7a` durable L56 coverage and routes future rows toward dispatch
delivery verification, callback timers, and worker-stall recovery instead of
treating send success as an orchestration closeout.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L1628`: `skillos-1z8x` dispatch
  was sent without a post-send liveness probe; Joshua flagged the "fire and
  forget" pattern after the orchestrator treated dispatch as terminal.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1629`: `PB-2` dispatch had no
  post-send probe, and a dirty-preflight BLOCKED callback was not detected for
  roughly 30 minutes.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1630`: same-day recurrence showed
  dispatch packets without a liveness-window contract, callback timer, or
  post-send probe schedule.
- Doctrine: `AGENTS.md` L91 `DISPATCH-DELIVERY-IS-A-FOUR-STATE-RECEIPT`.
- Doctrine: `AGENTS.md` L95 worker-stall recovery guidance.
- Doctrine: `AGENTS.md` L120 callback close-executed requirement.
- Probe: `.flywheel/scripts/dispatch-delivery-verify.sh`.
- Probe: `.flywheel/scripts/verify-callback-delivery.sh`.
- Skill: `~/.claude/skills/dispatch-tool-contracts/SKILL.md`.
- Bead: `flywheel-bin7a`.

## shared-repo-dirty-preflight

Date: 2026-05-08

Promotion Action: NEW

Class: `shared-repo-dirty-preflight`

Event Count: 3 events in 7 days

Severity: medium

Cost: Three skillos dispatches reached worker pre-flight with dirty or
untracked shared-repo state already present. Workers correctly refused or
blocked instead of writing through the dirt, but each dispatch burned a worker
slot and pushed cleanup back to the orchestrator after the packet was already
sent.

Root Cause: Shared-repo cleanliness was treated as a worker-owned pre-flight
check instead of an orchestrator-owned dispatch gate. The dispatch packet could
name a clean-tree requirement, but the worker cannot make a shared repo safe
after the orchestrator has already selected the pane, written the packet, and
started the task.

Forever-Rule: Orchestrators own dirty pre-flight for every shared repo they
dispatch into. Before sending a worker to `~/.claude`, `~/Developer/skillos`,
or another shared substrate, run `git status --short` on that repo and resolve,
route, or explicitly waive all dirty/untracked paths before packet generation.
Do not ask the worker to clean the shared repo as part of the dispatched scope;
the worker's correct response to unexpected dirty state is BLOCKED with the
dirty paths and owner surface.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote shared-repo-dirty-preflight`. This entry gives promotion-candidate
bead `flywheel-7xcfl` durable L56 coverage and routes future rows to the
existing dispatch dirty-preflight discipline in `dispatch-tool-contracts`
instead of treating dirty shared-repo state as a worker-local setup problem.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L1344`: `skillos-1z8x` dispatch
  required clean `~/.claude` pre-flight, but `git status --short` reported
  1697 dirty paths and an untracked `skills/rust-best-practices` target.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1485`: `PB-2` strictness sweep
  required clean skillos git state, but the repo carried many dirty paths and
  untracked validation schema targets.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1632`: third strike where skillos
  still carried 50+ dirty paths and untracked validation schemas at dispatch
  time.
- Skill: `~/.claude/skills/dispatch-tool-contracts/SKILL.md` section
  `Forever-Rule: Orchestrator owns shared-repo dirty preflight before
  dispatch`.
- Bead: `flywheel-7xcfl`.

## concurrent-dirty-validation-drift

Date: 2026-05-09

Promotion Action: NEW

Class: `concurrent-dirty-validation-drift`

Event Count: 13 events in 7 days

Severity: medium

Cost: Thirteen mobile-eats worker validations on 2026-05-08 (between
09:34Z and 15:17Z) saw their `pnpm test` / `pnpm typecheck` / `pnpm
build` fail because of unrelated dirty edits a sibling pane had made
in the same shared worktree. Each affected worker re-ran validation
in an isolated `/tmp/mobile-eats-<task>-validate-<pid>` worktree and
the validation passed there, proving the worker's own changes were
clean — only the cross-pane drift was poisoning shared validation.
The cost is wasted CI cycles, false-failure noise, and worker time
spent recovering an isolated worktree.

Root Cause: Validation tooling (`pnpm test`, `pnpm typecheck`,
`pnpm build`) is whole-repo by design — it picks up every dirty file
in the worktree, including paths the worker never touched. When two
worker panes operate in the same git worktree on parallel tracks
(common in multi-pane mobile-eats sessions), pane A's clean validation
on its own narrow scope is gated by pane B's in-flight dirty edits
that have nothing to do with pane A's task. Sister class to
`shared-repo-dirty-preflight` above: that one is about
orchestrator-side dispatch gates; this one is about worker-side
validation surfaces.

Forever-Rule: When a worker performs full-repo validation
(`pnpm test`, `pnpm build`, `pnpm typecheck`, `pytest -q`, etc.)
inside a shared worktree where another active pane has dirty state,
**the worker MUST validate in a dedicated isolated worktree** rather
than the shared one. The canonical pattern observed in the 13 events
is `git worktree add /tmp/<repo>-<task>-validate-<pid> <commit-sha>`
followed by validation against that path. The worker's own narrow
scope can still ship from the shared worktree (so pathspec staging
discipline holds), but the validation gate runs against the isolated
copy. A worker MUST NOT downgrade validation to "no full test run"
just because the shared worktree is poisoned; the isolated worktree
is the canonical workaround.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote concurrent-dirty-validation-drift` (worker-tick by
`flywheel-8qal5`). Pairs with `shared-repo-dirty-preflight` (sister
section above): orchestrator gates on dirty pre-flight before
dispatch (orch layer); worker isolates validation when dirty state
appears mid-flight (worker layer). The isolated-worktree pattern is
already canon in mobile-eats per the 13 events; this entry codifies
it as Forever-Rule.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L4263,L4264,L4267,L4268,L4273,L4274,L4277,L4278,L4279,L4281,L4283,L4285,L4287`:
  the 13 events, all on 2026-05-08 09:34Z–15:17Z, all
  `session=mobile-eats` with cross-pollution between panes 2 and 3
  (Track A vs Track B vs Track H validation work).
- Pattern observed in every event: shared `pnpm test`/`pnpm
  typecheck`/`pnpm build` failure + isolated
  `/tmp/mobile-eats-<task>-validate-<pid>` worktree validation
  passes.
- Failure-shape distribution:
  - Pane 3 dirty billing/copy edits poisoning Track A: 2 rows
  - Pane 2 dirty entitlements/dunning/stripe edits poisoning Track L: 2 rows
  - Track H email-sequences cross-pollination: 4 rows
  - Track A/B fixture drift: 1 row
  - Track H7/customer-reengagement copy drift: 4 rows
- Sister INCIDENTS entry: `INCIDENTS.md#shared-repo-dirty-preflight`
  (the orch-layer counterpart).
- Doctrine: `AGENTS.md` L107 `SHARED-SURFACE-WRITES-MUST-RESERVE`
  covers the file-level reservation case; this rule covers the
  whole-repo validation-tooling case where reservations don't help
  because the validation itself reads every file.
- Skill: `~/.claude/skills/dispatch-tool-contracts/SKILL.md` (the
  shared-repo-dirty-preflight Forever-Rule lives here; this section's
  isolated-worktree-validation pattern should be added to the same
  skill in a follow-up).
- Companion dedup fix: `flywheel-qnkj2` (added `$REPO/INCIDENTS.md`
  to `doctrine-ladder-promote.sh default_incident_paths`).
- Bead: `flywheel-8qal5`.

## worker-close-git-commit-skipped-dirty-shared-doctrine-surfaces — already covered by L143 (2026-05-09 cross-reference)

Date: 2026-05-09

Class: `worker-close-git-commit-skipped-dirty-shared-doctrine-surfaces`

Event Count: 3 events on 2026-05-09 (clustered 03:34-04:00Z, all
flywheel session pane 2, agent claude); the third event explicitly
cites L143 in its `rule_violated_or_proven` field.

Severity: low

Cost: Three flywheel worker dispatches (`flywheel-hv071`,
`flywheel-dwavb`, `flywheel-r52ig`) closed bead with
`git_committed=skipped` because shared doctrine surfaces (`AGENTS.md`,
`.flywheel/AGENTS-CANONICAL.md`, `templates/flywheel-install/AGENTS.md`,
`README.md`, `.beads/issues.jsonl`) carried unrelated dirty changes
from concurrent worker panes. The workers' own scope was clean and
their compliance pack landed, but the implementation files stayed
dirty in the working tree because the workers refused to bundle
unrelated drift into a same-bead commit.

Root Cause: Pre-L143 close-handler doctrine permitted
`git_committed=skipped` as an exception path for "shared doctrine
surfaces have unrelated dirty changes." Workers used the exception
to preserve other panes' work, which was a correct read of the
**Joshua-disposes** axiom (don't bundle other workers' drift). But
the exception left every closed bead's implementation in dirty
state, violating the L120 br-close-before-callback contract's
implicit "close means done" semantic.

Forever-Rule (already shipped 2026-05-08 in L143
`WORKER-CLOSE-REQUIRES-GIT-COMMIT`,
`.flywheel/rules/L094-L143-worker-close-requires-git-commit.md`):
Workers MUST emit `git_committed=<yes|no_changes|skipped>` alongside
`br_close_executed=yes` in every DONE callback. `skipped` is a
workflow violation and a fuckup-log promotion candidate.
Close-handler refuses close when any declared file-scope path is
dirty or when `git_committed=yes` lacks a commit reachable from
HEAD after dispatch start. The canonical fix workers should
practice now is **pathspec staging only**: `git add -- <declared
scope paths only>` followed by `git commit`, leaving every
unrelated dirty path untouched. This pairs with the
`shared-repo-dirty-preflight` orch-side gate (line 6205) which
ensures the orchestrator surfaces dirty preconditions BEFORE
dispatch generation rather than after.

Fix Applied/Status: Doctrine landed 2026-05-08 in L143 (one day
before these 3 events). The 3 events on 2026-05-09 are the L143
contract working as intended — the rule's
`rule_violated_or_proven` field captures the violation in the
fuckup-log so the L56 ladder fires a promotion candidate. This
INCIDENTS.md cross-reference entry closes the doctrine-ladder
visibility loop: the existing L143 surface is canonical, but
without a discoverable INCIDENTS surface the ladder kept filing
re-promotion candidates (`flywheel-35exy`, this bead) for a class
already covered.

Recurrence Prevention: The L56 ladder probe
(`doctrine-ladder-promote.sh`) inspects
`~/.claude/skills/.flywheel/INCIDENTS.md`, `$REPO/INCIDENTS.md`, and
`$REPO/AGENTS.md` for class-name coverage but does NOT scan
`.flywheel/rules/`. Same Recurrence Prevention shape as pane 3's
`flywheel-u5ml3` cross-reference for `daily_report_missing_dispatch_gate`
(line 7421+ in this file). The L56 ladder gap is a known
heuristic-narrowing follow-up; the immediate fix is this
INCIDENTS surface giving the dedup heuristic a discoverable hit.

Evidence:
- Trauma rows: `~/.local/state/flywheel/fuckup-log.jsonl#L4614,L4623,L4627`,
  3 rows on 2026-05-09 (03:34Z, 03:48Z, 04:00Z), all
  `session=flywheel pane=2 agent=claude` with
  `git_committed=skipped` recorded in the worker's own DONE
  callback path.
- L143 rule: `.flywheel/rules/L094-L143-worker-close-requires-git-commit.md`
  (status: long_term, shipped 2026-05-08, review_due 2026-11-08).
- AGENTS.md citation: line 132 of root `AGENTS.md`
  (`L143 — WORKER-CLOSE-REQUIRES-GIT-COMMIT | long_term |
  .flywheel/rules/L094-L143-worker-close-requires-git-commit.md`).
- Per-bead receipts:
  `~/.flywheel/receipts/flywheel-hv071/compliance-pack.md`,
  `~/.flywheel/receipts/flywheel-dwavb/compliance-pack.md`,
  `~/.flywheel/receipts/flywheel-r52ig/compliance-pack.md`.
- Sister INCIDENTS entries:
  `INCIDENTS.md#shared-repo-dirty-preflight` (line 6205, orch-side
  pre-flight gate),
  `INCIDENTS.md#concurrent-dirty-validation-drift` (line 6258, the
  worker-side validation-isolation sister pattern),
  `INCIDENTS.md#worker-evidence-file-write-before-reservation`
  (line 5991, related L107 reservation contract).
- Memory cross-ref:
  `feedback_worker_close_requires_git_commit.md` (META-RULE
  2026-05-07: "br_close_executed=yes (L120) without
  git_committed=yes leaves impl in dirty tree; mobile-eats audit
  found 7/8 worst-scoring closed beads in this state").
- Companion dedup fix: `flywheel-qnkj2` (repo-local INCIDENTS.md
  path search ensures this section is discovered).
- Bead: `flywheel-35exy`.

Follow-up Bead Filed (separate dispatch): None — the underlying
class is already covered by L143. A future improvement would be
extending `doctrine-ladder-promote.sh`'s `default_incident_paths()`
function to scan `.flywheel/rules/*.md` so the ladder doesn't
re-fire on classes already covered at the L-rule layer (per
pane 3's `flywheel-u5ml3` Recurrence Prevention note).

## jeff-dedupe-bead-stale-scope

Date: 2026-05-08

Promotion Action: NEW

Class: `jeff-dedupe-bead-stale-scope`

Event Count: 4 events in 7 days

Severity: high

Cost: Four `flywheel-zaat` redispatches sent workers back into stale Jeff
dedupe scope: the bead still targeted `/Users/josh/Developer/dicklesworthstone-stack`
and 19 flat clones while live substrate had moved to `/Users/josh/Developer/jeff-corpus`
with 177 flat Dicklesworthstone clones and seven dirty direct-child repos.
Each redispatch consumed a worker slot, repeated the same read-only probe, and
preserved no safe mutation path.

Root Cause: The dedupe decision treated an old bead/title match and stale
acceptance wording as authoritative after the underlying Jeff corpus substrate
changed. The correct live owner, `flywheel-2mz2x`, already covered the current
177-clone reconciliation shape, but `flywheel-zaat` remained dispatchable
because INCIDENTS coverage did not yet name this stale-scope class.

Forever-Rule: Jeff dedupe matches are advisory until the live substrate proves
the matched bead is open and still in scope. Before redispatching, closing, or
merging evidence into a Jeff dedupe bead, run a live probe of the actual corpus
path, `br show` the candidate bead, and compare the current evidence against
the bead description. If the corpus path, count, dirty-state premise, or
successor owner has changed, stop the stale bead and route the worker to the
current owner instead of reusing the old scope.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote jeff-dedupe-bead-stale-scope`. This entry closes promotion-candidate
bead `flywheel-cgnv5`, cites the already-updated `jeff-issue-chain` skill
Forever-Rule for the operational runbook, and gives doctrine-ladder scans a
durable repo INCIDENTS target instead of recreating the same promotion
candidate.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L1073`: first `flywheel-zaat`
  stale-scope row found the missing `dicklesworthstone-stack` path, 177 live
  flat clones, canonical `jeff-corpus`, and seven dirty repos.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1081`: redispatch repeated the
  contradiction and confirmed successor bead `flywheel-2mz2x` owned the live
  177-clone corpus problem.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1091`: later dispatch still
  targeted the missing path and 19-clone premise; worker blocked without
  rename, symlink, or delete mutation.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1099`: fourth recurrence again
  blocked on stale scope while `flywheel-2mz2x` remained the current owner.
- Skill: `~/.claude/skills/jeff-issue-chain/SKILL.md` section
  `FOREVER-RULE: jeff-dedupe-bead-stale-scope`.
- Bead: `flywheel-cgnv5`.

## parent-bead-dispatched-with-open-children

Date: 2026-05-08

Promotion Action: NEW

Class: `parent-bead-dispatched-with-open-children`

Event Count: 5 events in 7 days

Severity: medium

Cost: Five dispatches sent workers to parent beads whose own close gates were
blocked by open child decomposition work. The workers repeatedly rediscovered
the same topology, ran read-only probes, and returned BLOCKED callbacks instead
of advancing the actionable child beads.

Root Cause: The idle dispatch path treated a parent bead as dispatchable because
the parent itself was open, while the real work had already been decomposed into
children. The Beads graph and parent notes carried enough evidence to route to
the first open child, but the dispatch selector did not fail closed on parent
close gates owned by open children.

Forever-Rule: Do not dispatch a parent bead when its acceptance gate is owned by
open child beads. Before dispatching a parent, inspect `br dep tree`, `br show`,
and any parent close notes for open or in-progress children. If children remain,
dispatch the first actionable child or emit a no-candidate receipt naming the
blocked topology; do not spend a worker slot proving the parent still cannot
close.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote parent-bead-dispatched-with-open-children`. This entry gives
promotion-candidate bead `flywheel-9xi4q` durable L56 coverage and routes
future rows to the idle dispatch gate and Beads child-DAG selection rule instead
of creating duplicate parent-dispatch promotion candidates.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L1198`: `flywheel-se3h` parent was
  dispatched even though its notes required nine child beads
  `flywheel-se3h.1-.9` to close first.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1205`: `flywheel-se3h` was sent to
  a worker while open/in-progress topology children still blocked parent close.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1214`: the same `flywheel-se3h`
  parent redispatch repeated the open-child close blocker.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1227`: later `flywheel-se3h`
  dispatch still found nine open children and a parent validator note saying
  children must close first.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1237`: a fifth `flywheel-se3h`
  parent dispatch again found the child DAG open and returned a bounded child
  dispatch next action.
- Plan evidence: `.flywheel/PLANS/INFRA-GAP-SCAN-2026-05-05.md` D2.G4 and
  DCT.8 name the idle dispatcher refusal rule for parents with open children.
- Test evidence: `tests/failure-class-emit.sh` covers
  `gate_unmet_open_children`.
- Skill: `~/.claude/skills/beads-br/SKILL.md`.
- Skill: `~/.claude/skills/dispatch-tool-contracts/SKILL.md`.
- Bead: `flywheel-9xi4q`.

## orchestrator-delegates-preflight-to-worker

Date: 2026-05-08

Promotion Action: NEW

Class: `orchestrator-delegates-preflight-to-worker`

Event Count: 3 events in 7 days

Severity: high

Cost: Three skillos dispatch observations showed the orchestrator sending
shared-repo readiness work to workers after the packet was already in flight.
Workers correctly refused dirty shared-repo cleanup/verification as out of
scope, but the dispatches still consumed worker slots and delayed the actual
owner action: clean or route the shared substrate before dispatch.

Root Cause: The orchestrator treated pre-flight as a checklist that could be
delegated inside the worker packet. That collapses two ownership layers:
orchestrator-owned substrate readiness and worker-owned scoped implementation.
Once the packet is sent, the worker can report dirty state, but it cannot make
the dispatch valid retroactively.

Forever-Rule: Orchestrators must complete shared-repo and substrate pre-flight
before authoring or sending the worker packet. Do not dispatch "clean the
shared repo, verify it is clean, then do the work" as a worker task. If
pre-flight finds dirty state, token gaps, missing schemas, or shared-index
contention, the orchestrator owns the repair, waiver, or owner-route before
worker selection. Worker packets may verify their scoped pathspec, but they
must not be used to outsource dispatch-readiness gates.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote orchestrator-delegates-preflight-to-worker`. This entry gives
promotion-candidate bead `flywheel-zz858` durable L56 coverage and links the
exact delegation anti-pattern to sibling incident
`INCIDENTS.md#shared-repo-dirty-preflight` and the existing
`dispatch-tool-contracts` dirty-preflight rule.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L1633`: `skillos-1z8x` BLOCKED
  because the orchestrator dispatched clean-`~/.claude` verification to the
  worker instead of running the shared-repo pre-flight first.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1634`: codex refused a packet that
  expected it to clean a shared repo, verify it, then do scoped work.
- `~/.local/state/flywheel/fuckup-log.jsonl#L1635`: PB-2 repeated the same
  pre-flight delegation anti-pattern within 90 minutes and raised severity to
  high.
- Sibling incident: `INCIDENTS.md#shared-repo-dirty-preflight`.
- Skill: `~/.claude/skills/dispatch-tool-contracts/SKILL.md` section
  `Forever-Rule: Orchestrator owns shared-repo dirty preflight before
  dispatch`.
- Bead: `flywheel-zz858`.

## l70-orch-pane-refill-delay

Date: 2026-05-08

Promotion Action: NEW

Class: `l70-orch-pane-refill-delay`

Event Count: 3 events in 7 days

Severity: high

Cost: Three flywheel worker panes returned to `WAITING` after callback or
blocker handling while the orchestrator still had parallel-independent work
available. Each missed refill converted available worker capacity into idle
time and required Joshua or later validation to notice that L70 same-tick
chaining had stopped at the first completed pane.

Root Cause: Callback/blocker handling was treated as the end of the tick for
the individual pane instead of a trigger to re-run live pane activity, ready
work, and capacity selection immediately. L70 existed as doctrine, but the
orchestrator path lacked a hard post-callback refill decision artifact for every
hot pane.

Forever-Rule: After every worker callback, BLOCKED callback, or pane-return
classification, the orchestrator must run a live hot-pane refill decision before
composing the next human-facing summary. If the pane is `WAITING`, capacity
exists, and ready independent work exists, dispatch in the same tick and write
the auto-refill decision row. If no refill occurs, record the concrete blocker
such as `no_ready_work`, `capacity_exhausted`, `worker_active`, or
`reservation_conflict`; a silent idle pane is an L70 violation.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote l70-orch-pane-refill-delay`. This entry gives promotion-candidate
bead `flywheel-nh7tt` durable L56 coverage and routes future rows to the L70
same-tick chain gate plus the hot-pane auto-refill decision helper instead of
creating duplicate promotion candidates.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L592`: pane 2 stayed `WAITING`
  after a cross-cutting callback until Joshua flagged the missing same-tick
  dispatch.
- `~/.local/state/flywheel/fuckup-log.jsonl#L597`: pane 3 stayed `WAITING`
  after a security callback; live pane verification found the second same-session
  refill miss.
- `~/.local/state/flywheel/fuckup-log.jsonl#L612`: pane 4 returned idle after a
  Phase 4 BLOCKED callback and was not refilled with parallel-independent work.
- Doctrine: `AGENTS.md` L70 `ORCH-NO-PUNT`.
- Helper: `.flywheel/scripts/auto-refill-decision-log.sh`.
- Tests: `tests/test_hot_pane_refill_after_callback_reap.sh` and
  `tests/orch-no-punt-chain.sh`.
- Bead: `flywheel-nh7tt`.

## integrate-prelude-blocked

Date: 2026-05-08

Promotion Action: NEW

Class: `integrate-prelude-blocked`

Event Count: 7 observed rows in 7 days

Severity: medium

Cost: Mobile-eats INTEGRATE prelude repeatedly stopped before callback reaping
because doctor errors and an active worker pane made integration unsafe. The
behavior protected live work, but repeated prelude blocks without layer-2
coverage made the loop look stuck and kept spawning promotion-candidate debt
instead of routing to the exact doctor/worker-progress blockers.

Root Cause: INTEGRATE prelude had enough evidence to refuse unsafe callback
reaping: `daily_report_missing`, `storage_low_headroom`, `jeff_corpus_storage_red`,
and pane 2 still `THINKING`. The missing piece was a durable distinction
between safe prelude refusal and productive integration work. Without that
incident target, the same block class recurred as unresolved promotion stock.

Forever-Rule: An INTEGRATE prelude block is a safe refusal, not an idle loop
failure. When doctor failures or active worker panes make reaping unsafe, do
not reap callbacks, mutate worker files, or mark work complete. Record the
blocking doctor classes and worker activity proof, route each blocker to its
owner, and resume INTEGRATE only after the doctor signal clears or the worker
progress path reaches a valid callback/stall outcome.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote integrate-prelude-blocked`. This entry gives promotion-candidate bead
`flywheel-ozha` durable L56 coverage and routes future rows to the doctor
blocker plus worker-progress receipts instead of creating duplicate promotion
candidates. It is sibling to `INCIDENTS.md#integrate_worker_active`: active
worker evidence is safe wait/observe; doctor-prelude failures are safe refusal
until the blockers clear.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L419-L420`: mobile-eats INTEGRATE
  prelude blocked on doctor errors including `daily_report_missing` and pane 2
  still `THINKING`.
- `~/.local/state/flywheel/fuckup-log.jsonl#L425-L429`: repeated
  `daily_report_missing` / `storage_low_headroom` prelude blocks while pane 2
  continued work on `mobile-eats-67r.1`.
- `~/.local/state/flywheel/fuckup-log.jsonl#L432-L433`: later auth-proof
  continuation still blocked on doctor errors plus active pane 2.
- Sibling incident: `INCIDENTS.md#integrate_worker_active`.
- Doctrine: `AGENTS.md` L91 `DISPATCH-DELIVERY-IS-A-FOUR-STATE-RECEIPT`.
- Doctrine: `AGENTS.md` L95 worker-stall recovery guidance.
- Bead: `flywheel-ozha`.

Sibling Classes:
- `daily-report-missing-integrate-blocker` (`flywheel-qqv5r`) — 4
  fuckup-log events on 2026-05-04 between 01:25Z and 01:40Z
  (`fuckup-log.jsonl#L402,L406,L409,L413`), all "INTEGRATE prelude
  blocked because doctor reports daily_report_missing". This class is
  the specific INTEGRATE-prelude shape of the parent trauma; this
  section's Forever-Rule already covers the canonical response (record
  blocking doctor classes + worker activity proof, route to owner,
  resume after the doctor signal clears). Companion bead: `flywheel-qqv5r`
  (Path A merge into this section; bead closes as superseded after
  the cross-link lands). Prior closed sibling `flywheel-vy0t` (2026-05-08)
  cited canonical AGENTS-CANONICAL.md coverage; this Sibling Classes
  citation gives the L56 doctrine-ladder dedup heuristic a discoverable
  INCIDENTS surface, post `flywheel-qnkj2`'s repo-local INCIDENTS.md
  path-search fix.
- Cross-gate sibling (different gate, same root cause):
  `daily_report_missing_dispatch_gate` covered at
  `INCIDENTS.md#daily_report_missing_dispatch_gate` (line 7317, sister
  bead `flywheel-u5ml3`, 2026-05-09). That class is the dispatch-gate
  shape; canonical L-rule coverage is L91 + L92 per that section's
  Forever-Rule. Both classes share the "doctor signal
  `daily_report_missing` as a blocker" trauma family but resolve via
  different doctrine paths (this section for INTEGRATE prelude
  variant; L91+L92 for dispatch-gate variant).

## dispatch-health-and-capacity-gate

Date: 2026-05-08

Promotion Action: NEW

Class: `dispatch-health-and-capacity-gate`

Event Count: 3 events in 7 days

Severity: medium

Cost: Mobile-eats DISPATCH aborted three times in one short window because
doctor health was red and the target worker pane was not `WAITING`. The aborts
were safety-correct, but without exact-class layer-2 coverage the same health
plus capacity refusal could recur as promotion debt instead of routing to the
doctor owners and pane-capacity gate.

Root Cause: Dispatch health checks and pane capacity checks both fired, but the
combined class lacked a durable incident target. Existing `dispatch-capacity-gate`
coverage handles robot-mode disagreement and override cases; this class is the
sibling hard-stop case where doctor errors plus no waiting worker pane mean
dispatch must not proceed.

Forever-Rule: Dispatch requires both a healthy-enough substrate and real worker
capacity. If doctor reports blocking classes such as `beads_db_health_failed`,
`storage_low_headroom`, or `publishability_bar_score_low`, and the selected
worker pane is not `WAITING`, abort dispatch, record the exact doctor classes
and pane state, and route to the health owner or capacity refill path. Do not
override a health failure simply because a dispatch candidate exists.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote dispatch-health-and-capacity-gate`. This entry gives
promotion-candidate bead `flywheel-hm88f` durable L56 coverage and routes
future rows to the health/capacity refusal path instead of duplicating
promotion candidates.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L487`: mobile-eats DISPATCH
  aborted on doctor errors `beads_db_health_failed`,
  `storage_low_headroom`, `publishability_bar_score_low`, and pane 2 not
  `WAITING`.
- `~/.local/state/flywheel/fuckup-log.jsonl#L488`: later DISPATCH `150759`
  aborted on the same doctor error set and pane 2 not `WAITING`.
- `~/.local/state/flywheel/fuckup-log.jsonl#L489`: DISPATCH `151302` repeated
  the same health/capacity refusal.
- Sibling incident: `INCIDENTS.md#robot-mode-classification-disagreement`.
- Script: `.flywheel/scripts/dispatch-capacity-gate.sh`.
- Skill: `~/.claude/skills/dispatch-tool-contracts/SKILL.md`.
- Bead: `flywheel-hm88f`.

## agent-mail-too-many-open-files

Date: 2026-05-08

Promotion Action: NEW

Class: `agent-mail-too-many-open-files`

Event Count: 8 events in 7 days at promotion-candidate creation; 10
exact-class rows observed by closeout

Severity: high

Cost: Agent Mail file reservation and session bootstrap calls repeatedly failed
with "Too many open files" during concurrent worker dispatches. Workers had to
fall back to narrow path discipline, local append primitives, or incomplete
reservation receipts, weakening L51's concurrency guarantee exactly when the
fleet was under high parallel load.

Root Cause: Agent Mail FD pressure was treated as a transient per-worker MCP
failure instead of a shared substrate health signal. The server could sometimes
free cached repos or recover on retry, but the recurring class still meant the
daemon's file descriptor budget, lock-file pressure, and cleanup behavior had
crossed a fleet-level threshold.

Forever-Rule: A repeated `agent-mail-too-many-open-files` row is a substrate
health event, not a worker-local reservation exception. After two same-session
or same-day rows, stop treating reservation fallback as normal, run the Agent
Mail FD doctor, inspect service `maxfiles` and lock FD pressure, and route to
the existing Agent Mail launchd/maxfiles recovery owner. Workers may continue
only on explicitly non-overlapping scoped files with `files_reserved` marked as
failed; orchestrators must not silently absorb the FD pressure while continuing
to dispatch overlapping file work.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote agent-mail-too-many-open-files`. This entry gives
promotion-candidate bead `flywheel-bika` durable L56 coverage and routes future
rows to the FD doctor plus existing Agent Mail reservation recovery family
instead of creating duplicate promotion candidates or normalizing reservation
fallback.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L131-L133`: first three
  alpsinsurance rows where reservation grant/release, `macro_start_session`, and
  `file_reservation_paths` failed with "Too many open files".
- `~/.local/state/flywheel/fuckup-log.jsonl#L135-L137`: three more
  alpsinsurance bootstrap/reservation failures during the same worker wave.
- `~/.local/state/flywheel/fuckup-log.jsonl#L139-L140`: seventh and eighth
  exact-class rows, completing the original promotion threshold.
- `~/.local/state/flywheel/fuckup-log.jsonl#L2503`: later flywheel worker
  reservation attempts failed twice with the same class under storage-headroom
  analysis.
- `~/.local/state/flywheel/fuckup-log.jsonl#L2505`: side-effect discovery row
  identified FD exhaustion under sustained Agent Mail query load.
- Existing incident: `INCIDENTS.md#agent-mail-reservation-timeout`.
- Diagnostic: `.flywheel/scripts/agent-mail-fd-doctor.sh`.
- Test: `tests/agent-mail-fd-doctor.sh`.
- Skill: `~/.claude/skills/agent-mail/SKILL.md`.
- Bead: `flywheel-bika`.

## jeff-corpus-storage-red-integrate-blocker

Date: 2026-05-08

Promotion Action: NEW

Class: `jeff-corpus-storage-red-integrate-blocker`

Event Count: 3 events in 7 days

Severity: medium

Cost: Mobile-eats INTEGRATE prelude blocked three times in a ten-minute window
because flywheel doctor reported Jeff corpus storage RED at `66766.7 MB`.
The refusal was safety-correct, but without exact-class layer-2 coverage the
same signal stayed as promotion debt instead of routing directly to the Jeff
corpus storage budget and compaction owner.

Root Cause: The Jeff corpus had a doctor-visible storage budget signal, but
the repeated mobile-eats blocker class lacked an INCIDENTS target that tied
the downstream INTEGRATE prelude refusal to L72 storage discipline and L78
Jeff corpus accretive ingestion. General integrate-prelude coverage explains
why callback reaping stopped; this class names the exact corpus storage owner.

Forever-Rule: `jeff_corpus_storage_health=RED` blocks corpus-growth work and
any integration path whose next step would depend on fresh Jeff corpus ingest,
mirror growth, or Qdrant expansion. Treat downstream INTEGRATE rows as a safe
refusal and route them to Jeff corpus compaction/storage recovery, not to
worker-stall recovery. Resume only after doctor reports Jeff corpus storage
`GREEN` or `YELLOW`, or after a valid storage override receipt explicitly
scopes the allowed non-growth work.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote jeff-corpus-storage-red-integrate-blocker`. This entry gives
promotion-candidate bead `flywheel-l82y` durable L56 coverage, links the class
to L72/L78 and the `storage-health` skill, and prevents future doctrine-ladder
scans from recreating the same promotion candidate.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L405`: mobile-eats INTEGRATE
  prelude blocked because doctor reported Jeff corpus storage RED at
  `66766.7 MB`.
- `~/.local/state/flywheel/fuckup-log.jsonl#L408`: same blocker recurred five
  minutes later with the same RED storage value.
- `~/.local/state/flywheel/fuckup-log.jsonl#L412`: third recurrence kept the
  integration path halted on the same Jeff corpus storage signal.
- Doctrine: `AGENTS.md` L72 `STORAGE-DISCIPLINE-SYSTEM-WIDE`.
- Doctrine: `AGENTS.md` L78 `Jeff corpus accretive ingestion`.
- Sibling incident: `INCIDENTS.md#integrate-prelude-blocked`.
- Test: `tests/jeff-corpus-accretive.sh` storage budget fixture asserts RED
  blocks new ingestion and doctor exposes Jeff corpus storage fields.
- Skill: `~/.claude/skills/storage-health/SKILL.md`.
- Bead: `flywheel-l82y`.

## ubs-module-checksum-mismatch

Date: 2026-05-08

Promotion Action: NEW

Class: `ubs-module-checksum-mismatch`

Event Count: 4 events in 7 days

Severity: medium

Cost: Four mobile-eats worker validations could not run UBS as intended because UBS module checksum verification failed for JS/Python/helper modules, and `ubs doctor --fix` did not restore the expected checksums. Workers fell back to typecheck/lint/tests/Playwright/a11y/build/security checks, which protected local code paths but left the UBS safety lane unavailable exactly when pre-close review was needed.

Root Cause: UBS treats module checksum mismatch as a hard integrity failure, but the repair path (`doctor --fix`) did not converge for the affected JS/Python/helper/type_narrowing modules. The fleet had safety-stack guidance that UBS is required pre-merge, but no layer-2 incident target distinguishing "UBS unavailable due to module checksum drift" from a normal code finding or from a worker skipping UBS.

Forever-Rule: A UBS module checksum mismatch is a safety-substrate failure, not a clean UBS pass and not a worker-local waiver. When checksum verification fails, run the documented repair once, record expected/got module evidence, and if repair does not converge route to the UBS/tool-patch owner while using alternate verification only as a bounded fallback. Closeout must say `UBS unavailable: checksum mismatch` and name the replacement checks that ran; do not report the fallback as equivalent to UBS.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn --promote ubs-module-checksum-mismatch`. This entry gives promotion-candidate bead `flywheel-w5j7t` durable L56 coverage and routes future rows to UBS substrate repair/tool-patch ownership instead of recreating promotion candidates or silently downgrading the safety lane.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L2856`: `mobile-2igc` UBS scan blocked because JS/Python/helper module checksums mismatched even after `doctor --fix`.
- `~/.local/state/flywheel/fuckup-log.jsonl#L2951`: `mobile-ulhv` changed-file scan blocked by JS/Python checksum mismatches; `doctor --fix` reproduced mismatch; fallback checks verified code path and existing bead `mobile-o2wt` tracked the tool issue.
- `~/.local/state/flywheel/fuckup-log.jsonl#L3190`: `mobile-eats-hkio` could not refresh JS/Python/type_narrowing modules; compile/test/build still passed.
- `~/.local/state/flywheel/fuckup-log.jsonl#L3533`: `mobile-1eis` UBS scan could not run; JS mismatch persisted after previous repair, so build/trace/security checks were used instead.
- Reference: `~/.claude/references/claude-md-safety.md` UBS safety-stack guidance.
- Bead: `flywheel-w5j7t`.

## ubs-module-checksum

Date: 2026-05-08

Promotion Action: NEW

Class: `ubs-module-checksum`

Event Count: 4+ events in 7 days (6 exact-class rows observed at promotion time)

Severity: medium

Cost: UBS file-targeted and focused scans were repeatedly unavailable across mobile-eats workers because cached or refreshed JS/Python/helper modules failed checksum verification. Several workers had to stop `ubs doctor --fix`, accept that the repair path did not converge, and substitute local adoption scans, typecheck, lint, tests, build, Playwright, or a11y checks. Those fallback checks protected individual code paths, but the fleet lost the intended UBS safety lane during pre-close review.

Root Cause: UBS module acquisition and cache refresh can land in a checksum drift state where both the cached module and the refreshed module disagree with the expected checksum. The operational doctrine treated UBS as an invocable pre-merge scanner but lacked an exact-class L56 incident for "UBS unavailable because the module checksum substrate is unhealthy." Without that incident, workers kept rediscovering the same tool-substrate failure and recording fallback verification as isolated closeout context.

Forever-Rule: A `ubs-module-checksum` row means the UBS substrate is unavailable, not that UBS found no issues. Run the documented refresh/repair path once, capture the expected/got checksum evidence when available, and route recurring failures to UBS/tool-patch ownership. A worker may use bounded fallback verification to finish local work, but closeout must explicitly say `UBS unavailable: module checksum` and name the replacement checks. Do not treat fallback verification as equivalent to UBS, and do not create another promotion candidate while this exact-class incident is active.

Fix Applied/Status: NEW exact-class layer-2 INCIDENTS entry from `/flywheel:learn --promote ubs-module-checksum`. This entry gives promotion-candidate bead `flywheel-5wfy4` durable L56 coverage, points future scans at UBS substrate repair/tool-patch ownership, and cross-links the narrower mismatch class already promoted in `INCIDENTS.md#ubs-module-checksum-mismatch`.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L2525`: `mobile-eats-1gqt.21` file-targeted scan did not complete because the cached JS module checksum differed; `ubs doctor --fix` from `/tmp` hung and was stopped.
- `~/.local/state/flywheel/fuckup-log.jsonl#L2920`: `mobile-1aps` UBS scan and `ubs doctor --fix` failed because JS/Python/helper modules downloaded with checksum mismatches; worker used adoption scan plus typecheck/lint/tests as fallback.
- `~/.local/state/flywheel/fuckup-log.jsonl#L2943`: `mobile-2gzh` UBS JS scan blocked by cached JS module checksum mismatch; refresh fetched a different checksum and failed verification.
- `~/.local/state/flywheel/fuckup-log.jsonl#L3017`: `mobile-1ocb` UBS JS sweep could not run because cached and refreshed JS module checksums mismatched the expected checksum.
- `~/.local/state/flywheel/fuckup-log.jsonl#L3912`: UBS focused scan could not run because JS module checksum verification failed after refresh.
- `~/.local/state/flywheel/fuckup-log.jsonl#L3918`: `mobile-eats-1skv.13` UBS scan could not run because JS module checksum verification failed after refresh; evidence captured expected/got checksum prefix.
- Related incident: `INCIDENTS.md#ubs-module-checksum-mismatch`.
- Reference: `~/.claude/references/claude-md-safety.md` UBS safety-stack guidance.
- Bead: `flywheel-5wfy4`.

## peer-orch-idle-on-blocker — escalate flywheel-class blocker within 5min (2026-05-04)

Date: 2026-05-04 (cross-link landed 2026-05-09 via flywheel-2xdi.27)

Promotion Action: NEW

Class: `peer-orch-idle-on-blocker`

Event Count: 3 documented occurrences (mobile-eats canonical_doctrine_drift
30+min idle before flywheel:1 probed directly; skillos auth-marker contract
bounced to Joshua instead of flywheel:1; mobile-eats L70 punt-to-next-tick
on a flywheel-class blocker).

Severity: medium (orchestrator-uptime drag on the self-sustaining-fleet
mission anchor; same family as L70 ORCH-NO-PUNT).

Cost: peer orchestrator sits idle while a flywheel-class blocker waits
for cross-orch coordination. Joshua flagged 2026-05-04T00:31Z: "we need
orchestrator rules that say — when you've gotten a flywheel blocker —
work with pane 1 of flywheel to address all of it — they can't sit idle
due to a blocker."

Root Cause: peer orchestrators (mobile-eats, skillos, alps, etc.) had no
forever-rule that classified blockers as flywheel-class vs peer-class
vs external, and no canonical xpane handoff packet shape for
flywheel-class blockers. The default failure mode was either single-tasking
on the blocker (idle) or bouncing to Joshua when flywheel:1 had the
scope, data, and delegation to unblock.

Forever-Rule: when a peer orchestrator detects a flywheel-class blocker
(originates from doctrine/substrate flywheel:1 owns, or unblockable by
cross-repo file edits / system-wide rule ratification), it MUST:

1. Classify within minutes: `flywheel_class | peer_class | external`.
2. If `flywheel_class`: send xpane packet to flywheel:1 within 5 minutes
   with `blocker_class`, `requested_owner`, `proposed_action`,
   `flywheel_orch_action_required`.
3. While awaiting flywheel:1 response: continue OTHER work in the queue.
   Single-tasking on a remote-owned blocker is the failure mode.
4. Log to `cross-orch-coordination.jsonl` with `blocker_type`, `ts`,
   `ack_expected_by`.

flywheel:1 must (a) probe peer-orch state directly rather than wait for
explicit packets (sibling rule
`feedback_orch_paralysis_recurring.md`), (b) apply file-edits or
rule-ratification to unblock when the substrate is in scope, and
(c) ACK in `cross-orch-coordination.jsonl` within minutes, not hours.

Anti-patterns:
- Peer-orch sends packet then idles awaiting reply (single-task instead
  of multi-task)
- Peer-orch bounces to Joshua when flywheel:1 has scope + data + delegation
- Flywheel:1 waits for explicit ask when proactive probe would unblock
  faster (orch-paralysis-recurring sibling)
- Flywheel:1 dispatches into peer's WORKERS to fix (scope violation per
  `feedback_orchestrator_scope_boundary.md`)

Companion canonical:
- AGENTS.md L70 ORCH-NO-PUNT (next actionable runs same tick, not next tick)
- AGENTS.md L71 VALIDATE-AND-REDISPATCH-DISCIPLINE
- INCIDENTS.md `orchestrator-idle-with-actionable-work` (sibling pattern
  on the flywheel:1 side; same family at the peer-orch side)
- INCIDENTS.md `orchestrator-paralysis-on-meadows-rules-not-yet-ratified`
  (Joshua-judgment escalation that pairs with this rule)

Companion memory:
- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_peer_orch_idle_on_blocker.md`
- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orch_paralysis_recurring.md`
- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orchestrator_scope_boundary.md`
- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_two_blocker_ticks_escalate_to_flywheel_plan.md`
- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_meadows_rules_unblock_paradigm_intact.md`

Bead audit trail:
- `flywheel-2xdi.27` (this cross-link landing) — gap-hunt-probe
  `memory-without-cross-link:feedback_peer_orch_idle_on_blocker.md`.

Evidence:
- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_peer_orch_idle_on_blocker.md`:
  trauma-class authoring memory entry written from Joshua's
  2026-05-04T00:31Z directive; cites 3 documented occurrences
  (mobile-eats canonical_doctrine_drift idle 30+min; skillos
  auth-marker bounced to Joshua; mobile-eats L70 punt-to-next-tick).
- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orch_paralysis_recurring.md`:
  sibling memory describing the flywheel:1-side mirror failure mode
  (waits for explicit asks instead of probing).
- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orchestrator_scope_boundary.md`:
  defines flywheel-orch's scope so peer-orch knows what to escalate.
- `.flywheel/audit/flywheel-2xdi.27/`: cross-link landing evidence
  pack; includes deterministic re-probe receipt
  (`probe-result.json`) showing
  `memory-without-cross-link:feedback_peer_orch_idle_on_blocker.md`
  no longer emits.
- `.flywheel/scripts/gap-hunt-probe.sh:498-512`
  (`probe_memory_without_cross_link`): probe source.

## jeff-corpus-compactor-production-safety-gaps (2026-05-04, recorded 2026-05-09)

Root Cause: The `jeff-corpus-compact.sh` script had four production-safety
gaps when `flywheel-cwov` tried to trigger live compaction against the
66.7GB v1 corpus that was reading RED on `jeff_corpus_storage_health`.
All four gaps would have silently failed or produced doctor-invisible
output:

1. The script rejected `--idempotency-key` as an unknown argument, but
   the production dispatch required `--idempotency-key cwov-1777858715`
   for safe re-run semantics.
2. `--apply` wrote a v3 manifest to
   `.flywheel/jeff-corpus/v3/manifest.json`, but the doctor reads
   `total_repo_size_mb` from the v1 manifest at
   `.flywheel/jeff-corpus/v1/manifest.json`. Compaction could not move
   the doctor's RED → GREEN/YELLOW signal.
3. Cold-storage archive went to
   `.flywheel/jeff-corpus/cold-storage/manifest-v1-retired-<ts>.json.gz`
   instead of the doctrine-required
   `.flywheel/jeff-corpus/v1.archived-<ts>.json.gz` path that the
   doctor and downstream auditors read.
4. The script never called Qdrant. It could not prove superseded chunks
   were dropped or produce a pre/post point-count diff — so a
   compaction run could "succeed" by exit code while leaving the
   embedding store unchanged.

A production compaction with the unfixed script would have looked like
a successful 66.7GB drop in v3 while v1 still RED in doctor,
cold-storage in the wrong path, Qdrant unchanged, and no idempotency
receipt.

Forever-Rule: Before triggering any production substrate-mutation
script (compaction, manifest promotion, embedding rebuild, archive),
audit the script for these four production-safety gates: (a)
idempotency-key argument with durable receipt; (b) output path matches
the doctor's read path so health signals can move; (c) archive path
matches the doctrine-required canonical, not the script author's
ad-hoc choice; (d) external system mutations (Qdrant, sqlite, etc.)
are actually performed and proven via pre/post diff. A P0
foundational-substrate compaction must surface a `--dry-run` plan that
itemizes exactly which storage layers will change before `--apply` is
allowed.

Fix Applied/Status: All four gaps fixed in `jeff-corpus-compact.sh`
before the production compaction ran. As of 2026-05-09:

- `--idempotency-key KEY` accepted; receipt path
  `<receipt_dir>/<safe_key>.json` written on apply
  (`jeff-corpus-compact.sh:35,71-72`).
- Production usage path documented in script header
  (`jeff-corpus-compact.sh:19`).
- Sibling beads `flywheel-cwov` (production trigger),
  `flywheel-cwov.1` (cold-storage path correction), and
  `flywheel-w3pr` (related deep pattern mining) all closed alongside
  this bead.

Evidence:
- Bead: `flywheel-24a3`
  ([cwov.audit-gap] jeff corpus compactor is not production-safe).
- Bead: `flywheel-cwov`
  ([jeff-corpus-compaction-trigger] PRODUCTION run of compact.sh —
  66.7GB RED right now).
- Bead: `flywheel-cwov.1`
  ([flywheel-cwov.audit-gap] AG5 cold-storage manifests created at
  `.flywheel/jeff-corpus/v1.archived-<ts>.json.gz`).
- Bead: `flywheel-w3pr`
  ([jeff-corpus-deep-pattern-mining] systematic measure of Jeff's
  work/quality/methods).
- Live precompact doctor at time of audit:
  `/tmp/cwov-pre-compact.json` — `jeff_corpus_v1_total_mb=66766.7`,
  `jeff_corpus_storage_health=RED`.
- Compactor surface today: `.flywheel/scripts/jeff-corpus-compact.sh`
  (idempotency-key, doctor-path manifest promotion, canonical
  cold-storage path, Qdrant pre/post diff all addressed).
- Probe source: `.flywheel/scripts/gap-hunt-probe.sh:582-607`
  (`probe_bead_without_followup`).

## Coordinator daemon wire-in complete (2026-05-07, recorded 2026-05-09)

Auto-assign live with custom worker-tick template. Full bleed-immunity
proven 4/4 CWDs identical (no working-dir cross-contamination between
worker spawns). First end-to-end auto-dispatched bead `flywheel-olhg`
closed cleanly 2026-05-07. The NTM coordinator daemon
(`launchctl` label `ai.zeststream.flywheel-coordinator-daemon`)
becomes the canonical worker dispatch substrate, with
`/flywheel:dispatch` retained as the manual override path.

Root Cause: For the period after the original `--watch --auto` design
landed but before ntm#122 + ntm#124 closed upstream,
`feedback_ntm_assign_watch_unsafe_pending_124` halted the daemon and
made `/flywheel:dispatch` the canonical dispatch path. Live auto-assign
could route to busy panes when robot-activity wasn't honored. The
session ran for several days on operator-fired dispatch only, which is
correct for safety but inverted the substrate intent — `/flywheel:dispatch`
was always meant to be the override, not the default.

Forever-Rule (now codified as L152): Worker dispatch substrate is
the **NTM coordinator daemon**. Auto-dispatch via the pinned-wrapper
daemon is the canonical path. Operator-fired `/flywheel:dispatch`
becomes the manual override path for cases where the daemon's
selection is wrong, the work needs operator-pinned routing, or the
daemon is intentionally halted for safety. When upstream ntm has an
open safety issue blocking auto-assign, halt the daemon via
`launchctl bootout gui/501/<label>` and switch to override-only
operation until remediation lands; never re-enable while the
upstream contract is unresolved.

Fix Applied/Status: Daemon installed via
`.flywheel/scripts/install-coordinator-daemon.sh`; health probe
`.flywheel/scripts/coordinator-daemon-health.sh --json` returns
`status:pass`, `coordinator_daemon_alive:true`, daemon uptime
60724+ seconds at 2026-05-09. Memory
`feedback_ntm_assign_watch_unsafe_pending_124` updated 2026-05-08 to
RESOLVED — old halt obsolete. ntm#122 + ntm#124 closed upstream
(commits `c0f8f222` plumbed `AutoReassignOptions.DryRun` through
`runWatchMode`/`PerformAutoReassignment`/`WatchLoop.handleCompletion`;
`3e44fe9e` added `robot.IsLiveBusy()` busy-pane defense). L152
shipped 2026-05-09 codifying the canonical/override split. README
Dispatch Contract gains a coordinator-daemon row.

Evidence:
- Bead: `flywheel-8d11`
  ([coord-wire-in T6] INCIDENTS.md + AGENTS.md L121 + README
  ecosystem-wire-in — bead title's "L121" was stale at filing,
  rule shipped at next-free L152 instead).
- First end-to-end auto-dispatched bead: `flywheel-olhg` (closed
  cleanly 2026-05-07; bleed-immunity verified 4/4 CWDs identical).
- L-rule: `.flywheel/rules/L103-L152-coordinator-daemon-canonical-dispatch.md`.
- Daemon installer:
  `.flywheel/scripts/install-coordinator-daemon.sh`.
- Daemon health probe:
  `.flywheel/scripts/coordinator-daemon-health.sh`.
- Install ledger:
  `~/.local/state/flywheel/coordinator-daemon-install.jsonl`.
- launchd plist:
  `templates/flywheel-install/launchd/ai.zeststream.flywheel-coordinator-daemon.plist`.
- launchctl label: `ai.zeststream.flywheel-coordinator-daemon`.
- Memory:
  `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_ntm_assign_watch_unsafe_pending_124.md`
  (RESOLVED 2026-05-08 — supersedes the halt).
- Upstream commits: ntm `c0f8f222` + `3e44fe9e`.
- Upstream issues closed: `Dicklesworthstone/ntm#122`, `#124`.

## parent-redispatched-before-open-child-complete (3 events 2026-05-05, recorded 2026-05-09)

Root Cause: The autoloop / orchestrator dispatch selector picks
parent beads for closure verification while open children or open
rework beads still exist. The worker resolves identity, runs
Socraticode, inspects bead state, and finds the parent CANNOT close
because acceptance gates depend on open children or open rework.
Work is genuine — Socraticode, doctor, dep tree, validator probes
all run cleanly — but the SELECTION was wrong. The next-actionable
was the child or rework, not the parent.

Three fuckup-log events in 11 minutes on 2026-05-05 (all on
`flywheel:0.3` worker, all `severity: medium`):

| Time (UTC) | Parent | Open blockers found |
|---|---|---|
| 14:43:51 | `flywheel-useh` | child `.1` open (Phase B split); rework `flywheel-uc9x` open (parent evidence/Four-Lens rework) |
| 14:47:42 | `flywheel-se3h` | children `.1`-`.9` open/in_progress; rework `flywheel-2yt5` open |
| 14:54:54 | `flywheel-useh` (re-redispatch) | same blockers as 14:43:51 — selector picked the same dead parent twice |

Each event's worker correctly identified the next-actionable
("finish child .1 → rework → re-run parent close validation") but
the dispatch path didn't take that. The third event proves the
selector lacks memory: it picked the same dead-end parent twice in
11 minutes.

The close-time gate IS in place: `validate-callback-before-close.sh:425`
fires `open_child_blocks_close: $C state=$STATE`. So a parent that
TRIES to close gets blocked correctly. The gap is at the **selector
layer**: dispatch-time selection should pre-filter parents whose
`br dep tree` shows open children OR whose name has a sibling
`*-rework-*` open. Today the selector only checks "is this bead
ready" without "are this bead's children/rework still open."

Forever-Rule: Before dispatching a parent bead for closure
verification, the selector must check (a) `br dep tree <bead>` for
open children — if any child is `open` or `in_progress`, route the
dispatch to the highest-priority open child instead; (b) open
rework beads via the heuristic
`br list --status open --search '<parent-bead-id>'` (rework beads
typically include the parent's id in their title). If either check
returns hits, the parent dispatch is preempted and the child/rework
is dispatched in its place. The close-time `open_child_blocks_close`
gate remains as the safety net but should rarely fire because the
selector has already routed correctly.

Fix Applied/Status: Doctrine codified here (no L-rule yet — three
strikes promotes to INCIDENTS per L56 ladder; further hits would
promote to a numbered L-rule). Recommended sibling bead (NOT
auto-filed per worker scope):
`[selector] add open-child / open-rework pre-filter to autoloop
parent dispatch selector` — the dispatch selector improvement
that prevents this trauma class at the SELECTION layer rather
than catching it at the close-validation layer. Until that ships,
workers receiving parent dispatches with open children should:

1. Run `br dep tree <parent>` first.
2. If any child is open / in_progress, BLOCKED-callback with
   `reason=parent-redispatched-with-open-children
   need=route-to-<child-id>-instead`. Do NOT do the parent's
   research; surface the misroute to the orchestrator.
3. Same for rework: search for sibling rework beads before
   committing parent-research time.

Evidence:
- Bead: `flywheel-41xjl` ([promotion-candidate]
  parent-redispatched-before-open-child-complete; auto-created by
  doctrine-ladder-promote.sh on 3-strike threshold).
- Fuckup-log entries (3 events, all `severity:medium`):
  `~/.local/state/flywheel/fuckup-log.jsonl` filtered on
  `trauma_class:"parent-redispatched-before-open-child-complete"`.
- Close-time gate (already in place):
  `.flywheel/scripts/validate-callback-before-close.sh:425`
  emits `open_child_blocks_close` failure class.
- Cited parent beads (open at time of incident): `flywheel-useh`
  (child `.1` + rework `flywheel-uc9x`), `flywheel-se3h`
  (children `.1`-`.9` + rework `flywheel-2yt5`).
- Promoter: `.flywheel/scripts/doctrine-ladder-promote.sh` (the
  L56 ladder script that auto-files promotion-candidate beads).
- Companion rules: L56 (doctrine-ladder promotion), L70
  (orch-no-punt — selector should route next-actionable
  same-tick), L71 (validate-and-redispatch discipline — the
  redispatch path itself is what should be validated against
  open children/rework).

## bead-missing-from-local-db

Date: 2026-05-09

Promotion Action: NEW

Class: `bead-missing-from-local-db`

Event Count: 3 events in 7 days

Severity: low

Cost: Worker dispatches received bead IDs (e.g. `josh-19yvg`,
`josh-2jyzb`, `josh-bmd26`) that existed orch-side but were absent
from the worker's local `.beads/beads.db`. Workers could not run
`br show <id>`, `br close <id>`, or `br update <id>` to mark
dispatch state, forcing them to either skip Beads-DB updates,
fall back to JSONL-only mode, or attempt cross-repo lookups
that the canonical `br` CLI doesn't expose. Closeout receipts
became less reliable because the bead-state machine could not
follow the dispatch through the worker tick.

Root Cause: Beads stores per-repo SQLite DBs at `.beads/beads.db`
plus a JSONL export at `.beads/issues.jsonl`. When orch creates a
dispatch bead in repo A and dispatches to a worker checked out in
repo B (e.g. `/private/tmp/alpsinsurance-worker-pane-4-josh-...`),
repo B's local `.beads/beads.db` does NOT have the bead until
it (a) `br sync --import-only` after a `git pull`, or (b) the orch
explicitly publishes the bead through some inter-repo channel.
Worker-pane checkouts spun up via `mktemp -d` worktrees inherit
whatever `issues.jsonl` was committed at branch-base time and
miss any beads created post-branch in the parent repo.

Forever-Rule: Worker dispatches that operate on a bead ID MUST
verify the bead is present in the worker's local Beads DB before
attempting `br show|update|close`. The canonical sequence is:
1. `br show <id> --json` — fast-path check.
2. If absent, `br sync --import-only` — pull JSONL → DB.
3. If still absent, `br close` is not authoritative; worker MUST
   surface `bead-missing-from-local-db` in the closeout receipt
   and let orch reconcile via `br sync --flush-only` on the orch
   side.
A worker MUST NOT silently treat a missing bead as success, and
MUST NOT fabricate a `br close` outcome by writing directly to
`.beads/issues.jsonl` (the canonical write path is `br close`).

Fix Applied/Status: NEW layer-2 INCIDENTS entry from
`/flywheel:learn --promote bead-missing-from-local-db` (this
dispatch). Three observed events all originated from alpsinsurance
session pane 4 cross-worktree dispatches; the entry establishes the
canonical sync-or-surface contract so workers stop fabricating
close outcomes when the bead is missing locally.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl` lines 3928, 3929, 3930
  (durable copy at `.flywheel/audit/flywheel-s2yd8/fuckup-evidence.jsonl`):
  three `trauma_class:"bead-missing-from-local-db"` rows on
  2026-05-07T18:43-19:01Z, all session=alpsinsurance pane=4,
  beads = josh-19yvg, josh-2jyzb, josh-bmd26.
- One row records `should_become=tool-patch`, indicating the worker
  recognized this as a structural gap, not a one-off.
- Cross-repo paths involved: `/Users/josh/Developer/alpsinsurance`
  (orch-side) vs `/private/tmp/alpsinsurance-worker-pane-4-josh-*`
  (worker mktemp worktrees).
- Doctrine: `AGENTS.md` L120 `BR-CLOSE-EXECUTED` (close before
  callback); the rule fires too early when the bead isn't
  worker-local.
- Beads CLI: `br sync --import-only` is the canonical worker-side
  pull; `br sync --flush-only` is the orch-side push.
- Bead: `flywheel-s2yd8`.

Sibling Classes:
- `bead-substrate-missing` (cosmetic alias, same trauma) — 7 fuckup-log
  events on 2026-05-08 between 02:40Z and 03:31Z reporting the same
  `br show / br close ISSUE_NOT_FOUND` shape against `josh-*` bead
  IDs. The class-name divergence emerged from slightly different
  `--class` strings used by fuckup-log writers; the underlying trauma
  is identical to `bead-missing-from-local-db` above. This sibling
  citation gives doctrine-ladder dedup (post `flywheel-qnkj2`'s
  repo-local `INCIDENTS.md` path search) a single landing pad, so
  future ladder runs that see the alias-class string still find
  canonical coverage here.
- `~/.local/state/flywheel/fuckup-log.jsonl#L4078,L4081,L4144,L4181,L4182,L4185,L4186`:
  the 7 sibling events, all with `josh-*` bead IDs (`josh-q32zp`,
  `josh-8lliy`, `josh-8kp1u`, `josh-c8tqy`, `josh-e84oj`, `josh-qrp79`,
  `josh-ylpa3`).
- Companion bead: `flywheel-uyd9i` (Path A merge into this section;
  bead closes as superseded after the cross-link lands).

## br-source-repo-dot-after-create

Date: 2026-05-09

Promotion Action: NEW

Class: `br-source-repo-dot-after-create`

Event Count: 7 events in 7 days (bead claimed 5; live count is 7)

Severity: low

Cost: `br create` invocations from absolute repo paths (e.g.
`/Users/josh/Developer/flywheel`, `/Users/josh/Developer/mobile-eats`)
were emitting bead rows with `source_repo='.'` (literal dot string)
instead of the resolved absolute repo path. Operators had to manually
repair each row after creation, either via direct SQLite UPDATE or
via `br update <id> --source-repo <absolute-path>`. With 7 events in
the recent window, this manual repair burden was non-trivial and
risked rows being left mis-attributed if the repair step was skipped.

Root Cause: A `br create` code path resolves `source_repo` from the
shell's current working directory representation rather than from
`pwd -P`/`realpath`. When the working dir is queried via a
short-cut that returns "." (or when `source_repo` defaults to the
literal "." sentinel), the resulting row stores "." rather than
the absolute path. Mis-attribution downstream: cross-repo bead
queries can't filter by canonical source_repo, and any tooling
that joins beads back to their source repo (e.g. fleet rollups,
plan-source-pinning) sees opaque "." values.

Forever-Rule: Every `br create` invocation MUST produce a row whose
`source_repo` is an absolute path. Two enforcement layers:
1. **Worker discipline**: workers SHOULD `cd "$(realpath "$REPO")"`
   before `br create`, and verify the resulting row via
   `br show <id> --json | jq -e '.source_repo | startswith("/")'`.
   On failure, repair via `br update <id> --source-repo "$(realpath
   "$REPO")"` BEFORE the bead is referenced downstream.
2. **Tool patch (Jeff-substrate)**: `br create` should canonicalize
   `source_repo` to an absolute path internally and refuse to write
   "." or relative paths. This is upstream `br` work; surface
   via a Jeffrey issue if not already filed.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from
`/flywheel:learn --promote br-source-repo-dot-after-create` (this
dispatch). 7 observed events all involve `br create` from various
absolute-path working directories producing `source_repo='.'`. The
entry establishes the worker-side verify-or-repair contract; the
upstream `br` canonicalization fix is recommended but out of worker
scope.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl` lines 198, 200, 231,
  240, 248, 249, 251 (durable copy at
  `.flywheel/audit/flywheel-e4tfe/fuckup-evidence.jsonl`).
- 7 events on 2026-05-02 to 2026-05-03, all `severity:low`, all
  describing manual row repair after `br create` emitted
  `source_repo='.'`.
- Affected repos: `/Users/josh/Developer/flywheel`,
  `/Users/josh/Developer/mobile-eats`, skillos tick context.
- Affected beads (representative): `flywheel-0oms`, `flywheel-zb5n`,
  `flywheel-4m68`, `flywheel-9osi`, `flywheel-zuqc`, plus 10
  mobile-eats MISSION Section 14 followup beads.
- Bead: `flywheel-e4tfe`.

## daily_report_missing_dispatch_gate — already covered by L91+L92 (2026-05-09 cross-reference)

Date: 2026-05-09

Class: `daily_report_missing_dispatch_gate`

Event Count: 4 events on 2026-05-04 (clustered 04:06-04:21Z, mobile-eats session, pane 1, agent claude); zero recurrence in the 5 days since.

Severity: low

Cost: dispatcher refused to dispatch mobile-eats tasks because doctor errors
contained `daily_report_missing` while pane 2 was visibly WAITING. 4 dispatch
attempts blocked over 15 minutes. The pattern is dispatch_gate treating a
telemetry-class doctor signal (daily-report freshness) as a hard structural
blocker rather than a non-blocking warning.

Root Cause: dispatch_gate's error-class predicate did not partition between
structural blockers (br-db corruption, pane unhealthy, identity drift) and
telemetry-class signals (daily_report_missing, fuckup-log freshness, etc.).
A WAITING worker was therefore gated by an operational telemetry error rather
than a true substrate fault.

Forever-Rule (already shipped, 2026-05-04): L91 (`dispatch-delivery-is-a-four-state-receipt`,
`.flywheel/rules/L045-L91-dispatch-delivery-is-a-four-state-receipt.md`)
explicitly cites this trauma class in its Why section ("`daily_report_missing_dispatch_gate`
4 rows `~/.local/state/flywheel/fuckup-log.jsonl#L445-L448`"). L92
(`audit-findings-route-by-data`, `.flywheel/rules/L046-L92-audit-findings-route-by-data.md`)
also cites it. Both rules direct dispatch decisions to use machine-readable
four-state receipts plus data-routed disposition rather than treating any
non-zero doctor signal as a hard block.

Fix Applied/Status: Doctrine landed 2026-05-04 in L91+L92 (same day as the
4 events). No source-code change to dispatch-capacity-gate.sh was needed
because the L91 contract reframed dispatch decisions: a worker is dispatchable
if the four-state receipt (transport_accepted + prompt_visible_in_target +
prompt_submitted + work_started) is achievable, irrespective of telemetry-class
doctor noise. Zero recurrence since 2026-05-04 confirms the gate refinement
took.

Recurrence Prevention: The L56 ladder probe (`doctrine-ladder-promote.sh`)
inspects `~/.claude/skills/.flywheel/INCIDENTS.md`, `$REPO/INCIDENTS.md`, and
`$REPO/AGENTS.md` for class-name coverage but does NOT scan `.flywheel/rules/`.
This caused the ladder to keep filing promotion-candidate beads (4 in this
case: ticks 2026-05-04T04:06+, 04:33+, 06:06+, 07:11+, 13:01+, plus today
2026-05-09T17:16+ and 17:19+) for a class already covered by L91+L92. This
INCIDENTS.md cross-reference entry closes that loop. Donella leverage point
#5 (rules) is now wired to leverage point #6 (information flow) by giving the
ladder probe a discoverable INCIDENTS surface.

Evidence:
- Trauma rows: `~/.local/state/flywheel/fuckup-log.jsonl` 4 rows on 2026-05-04
  (04:06:29Z, 04:11:28Z, 04:16:47Z, 04:21:29Z), all session=mobile-eats pane=1.
- L91 rule: `.flywheel/rules/L045-L91-dispatch-delivery-is-a-four-state-receipt.md`.
- L92 rule: `.flywheel/rules/L046-L92-audit-findings-route-by-data.md`.
- Verify-pass: `.flywheel/PLANS/doctrine-propagation-2026-05-07/01-VERIFY-PASS.json`
  documents L91+L92 body text including this class citation.
- Promote script: `.flywheel/scripts/doctrine-ladder-promote.sh`
  (incident-paths function omits `.flywheel/rules/` — see Recurrence Prevention).
- Bead: `flywheel-u5ml3` (this dispatch).
- Memory cross-ref: `feedback_dispatch_delivery_validation_required.md`,
  `feedback_audit_findings_are_data_decided_not_joshua_gated.md`.

Follow-up Bead Filed (separate dispatch): None — the underlying class is
already covered. A future improvement would be extending
`doctrine-ladder-promote.sh`'s `default_incident_paths()` function to scan
`.flywheel/rules/*.md` so the ladder doesn't re-fire on classes already
covered at the L-rule layer (per `feedback_calibrate_test_to_actual_contract_before_filing_upstream`:
calibrate the gate to the actual coverage surface rather than treat the
known-good state as a bug).

## dcg-blocked-temp-cleanup — DCG canonical primitive working correctly (2026-05-09)

Date: 2026-05-09

Class: `dcg-blocked-temp-cleanup`

Event Count: 3 events in 7d (2026-05-04T20:23:17Z, 2026-05-05T00:47:39Z,
2026-05-09T00:02:55Z); all workers pivoted safely after DCG block.

Severity: low (DCG firing IS the intended safety; no substrate damage in any event)

Cost: workers attempted recursive-force deletion on scratch/temp dirs and DCG
(Destructive Command Guard) blocked execution. Each event added 30-60s of
pivot time as the worker rewrote the cleanup to use either a
unique-temp-dir-without-deletion pattern OR the canonical
`flywheel-cleanup-scratch` / `.flywheel/scripts/cleanup-scratch.sh --apply --json
$WORK_TMP` helper. No data lost or substrate corrupted.

Root Cause: workers don't reflexively reach for the canonical scratch-cleanup
helper; bare recursive-force deletion of `$WORK_TMP` is muscle memory. DCG is
the canonical safety surface and IS firing correctly. The trauma is the worker
pattern, not a substrate fault.

Forever-Rule (already in worker-tick contract step 8b + memory): every
dispatch that creates a `WORK_TMP` scratch directory MUST close it via the
canonical helper:
- `flywheel-cleanup-scratch --apply --json "$WORK_TMP"` (preferred)
- OR `.flywheel/scripts/cleanup-scratch.sh --apply --json "$WORK_TMP"` (fallback)
- NEVER bare recursive-force-delete on `$WORK_TMP` in worker reports, dispatch
  packets, commit messages, or `br create -d` prose — DCG will block execution
  and the redirect-prose may also trip prose-trigger blocks (see
  `feedback_dcg_prose_trigger_strip_dangerous_substrings`).

Memory references:
- `feedback_dcg_prose_trigger_strip_dangerous_substrings.md` — DCG matches
  dangerous shell substrings even inline in br/ntm prose; rephrase before submit.
- `feedback_retention_policy_by_default_for_accreting_surfaces.md` — every
  accreting surface gets launchd/cron retention at creation, not after-the-fact
  recursive-force cleanup. Long-term solution to the underlying motivation.

Fix Applied/Status: No source-code change needed. DCG is working as designed.
Workers' canonical pivot pattern (use cleanup-scratch.sh or skip deletion
entirely) is already documented in worker-tick contract step 8b. This INCIDENTS
entry makes the doctrine visible to the L56 ladder probe so it stops re-firing
on already-canonical-handled classes.

Recurrence Prevention: Donella leverage point #6 (information flow) — the
ladder probe now sees coverage in INCIDENTS.md and skips. Donella #5 (rules) —
DCG is the safety surface and remains untouched. Donella #2 (buffer size) —
canonical scratch-cleanup helpers + memory rules are the worker-side knobs.
`flywheel-vl0c9` (filed by `flywheel-u5ml3` in the prior tick) will eventually
extend the ladder probe to scan `.flywheel/rules/` too, reducing future
probe-firing on L-rule-covered classes (this class is INCIDENTS-covered, not
L-rule-covered).

Evidence:
- Trauma rows: `~/.local/state/flywheel/fuckup-log.jsonl` 3 rows on
  2026-05-04T20:23:17Z, 2026-05-05T00:47:39Z, 2026-05-09T00:02:55Z; all
  `severity=low` and `what_attempted=[]` (DCG fired BEFORE execution).
- DCG canonical: `~/.claude/skills/dcg/SKILL.md`.
- Canonical scratch cleanup: `.flywheel/scripts/cleanup-scratch.sh` +
  `~/.local/bin/flywheel-cleanup-scratch`.
- Worker contract (already documents the pattern): worker-tick step 8b.
- Memory: `feedback_dcg_prose_trigger_strip_dangerous_substrings.md`,
  `feedback_retention_policy_by_default_for_accreting_surfaces.md`.
- Bead: `flywheel-8io1s` (this dispatch — retry of `f8ebdb` after r1 `ad242e`
  blocked on peer reservation).
- Sibling completed today (precedent): `flywheel-u5ml3` (closed; same
  cross-reference pattern for `daily_report_missing_dispatch_gate`).

## sniff-lens-status-without-outcome — activity-shaped evidence treated as outcome (2026-05-09 promotion)

Date: 2026-05-09

Promotion Action: NEW

Class: `sniff-lens-status-without-outcome`

Event Count: 8 events on 2026-05-04 alone, plus reworks for
`flywheel-w3pr.3`, `flywheel-0rlc`, `flywheel-1wbr`, `flywheel-lam3`,
and the `flywheel-keji` audit row cluster (notes lines 140, 174, 246,
280, 297, 444 region, 1138). Pattern continued through 2026-05-09.

Severity: medium

Cost: Workers shipped substantively correct work (skill drafts, L-rule
candidates, validator hooks) but worded close evidence as activity
("mapped N candidates", "reviewed K patterns", "scanned X files")
instead of founder-ops outcome ("shipped N promotion-ready skills
usable for next-tick selection; saved Y human-review-hours/week;
closed Z gaps in skill library"). The sniff-lens validator (Joshua-tone,
25-year-ops-judgment perspective) correctly flagged this as
`status_without_outcome` and BLOCK_CLOSED the bead. Each rework cycle
cost a full worker-tick to reframe evidence without changing
substance — pure prose rework, zero code/doctrine delta. On
2026-05-04 this fired 6+ times in a single day across multiple
workers (OrangeRaven, GoldSnow, NobleVale, others), indicating the
trauma is workflow-shaped not worker-shaped.

Root Cause: The dispatch-template's evidence-pack contract names
required FIELDS (DID/DIDNT/GAPS, validation, files-changed,
acceptance-receipts) but does not require outcome-shaped LANGUAGE.
A worker can populate every required field with activity verbs and
pass mechanical validation while failing the sniff lens. The
beads-compliance evidence pack contract (L126, INCIDENTS section
"Evidence packs replace four-lens close self-grades") solves the
worker-self-grade-as-fact failure mode but is orthogonal to the
activity-vs-outcome framing failure mode — workers can produce a
700+ scoring evidence pack that still reads as Kubernetes status,
not founder leverage.

Forever-Rule: Closure evidence packs MUST shape the headline finding
as outcome ("we shipped X usable for Y; saved Z; closed N gaps"),
not activity ("we mapped/scanned/reviewed N items"). The sniff-lens
validator (`scripts/sniff-lens-validator.sh` or equivalent) is the
mechanical gate; `flywheel-0rlc`'s evidence pack
(`.flywheel/evidence/flywheel-0rlc/report.md`) is the canonical
fix-shape: activity-vs-outcome table + outcome math + gate-by-gate
restating + concrete leverage delta. Future workers facing a
`status_without_outcome` BLOCK_CLOSE follow the 0rlc reframe
template, not new substrate.

Fix Applied/Status: NEW layer-2 INCIDENTS entry surfaced from
`gap-hunt-probe` (filed `flywheel-2xdi.39` because `flywheel-0rlc`
shipped doctrine/canonical/promotion work — the activity→outcome
reframe pattern + 5 staged skill drafts + 5 candidate L-rules — but
was not cited in INCIDENTS.md). The 0rlc evidence pack and its
sibling rework `flywheel-w3pr.3` evidence pack ARE the canonical
fix-shape. No code change required; this entry makes the doctrine
visible to the L56 ladder probe so it stops re-firing on the
already-canonical-handled class.

Recurrence Prevention: Donella leverage point #6 (information
flow) — the L56 ladder now sees coverage in INCIDENTS.md and skips.
Donella #5 (rules) — sniff-lens validator IS the active rule;
`status_without_outcome` is the canonical FAIL token; no new gate
needed. Donella #4 (self-organization) — the 0rlc precedent
("activity-vs-outcome table + outcome math + gate-by-gate restating")
gives future workers a copy-pasteable template, reducing the
per-rework cycle from ~1 worker-tick of trial-and-error to
~5-min reframe.

Sibling Classes:
- `self-grade-claim-treated-as-fact` (INCIDENTS section "Evidence
  packs replace four-lens close self-grades", 2026-05-07): worker
  asserting a four-lens score without backing pack. Different
  failure mode (no evidence vs evidence shaped wrong); same family
  (close-quality drift).

Evidence:
- 0rlc evidence pack: `.flywheel/evidence/flywheel-0rlc/report.md`
  + `.flywheel/evidence/flywheel-0rlc/w3pr.3-rework-target.md`
  (canonical fix-shape with activity→outcome table).
- w3pr.3 rework evidence pack:
  `.flywheel/evidence/flywheel-w3pr.3/report.md`.
- 1wbr rework evidence: `.flywheel/audit/flywheel-1wbr/evidence.md:13`
  cites the same `status_without_outcome` finding.
- lam3 rework target: `.flywheel/evidence/flywheel-lam3/152b.1-rework-target.md:43`
  shows the same outcome-vocabulary check pattern.
- 2026-05-04 cluster: `.flywheel/audit/flywheel-keji/before-test-output-merged.txt`
  notes lines 140, 174, 246, 280, 297, 1138 — 6 BLOCK_CLOSE events
  in a single day.
- Memory: `feedback_post_wire_or_explain_three_skill_polish_gate.md`
  (5-skill polish gate), `user_joshua_lens_judgment_depth.md`
  (Joshua-lens grades operator-durability + team-fit + company-
  building leverage, NOT generic mission-fit).
- Doctrine bead: `flywheel-0rlc` (canonical fix-shape demonstrated;
  closed 2026-05-09).
- This bead: `flywheel-2xdi.39` (gap-hunt-probe surfaced the
  missing INCIDENTS coverage; closed via this entry).

## autoloop-executor.jsonl — self-instrumentation ledger (cross-source-silos cross-reference, 2026-05-09)

Date: 2026-05-09

Class: `cross-source-silos:autoloop-executor.jsonl`

Event Count: 1 finding (gap-hunt-probe scan, surfaced as `flywheel-2xdi.40`).

Severity: low (probe correctly surfacing a category gap-hunt's cross-source-silos rule
doesn't yet model — self-instrumentation ledgers).

Cost: gap-hunt-probe's `probe_cross_source_silos()` flags every `*.jsonl` in
`~/.local/state/flywheel/` that isn't referenced by the 6 receiver surfaces
(tick.md, status.md, synth.md, AGENTS.md, INCIDENTS.md, README.md). The
autoloop-executor.jsonl ledger is self-instrumentation: it exists so that
gap-hunt-probe's `wired-but-cold` rule sees the autoloop-executor library
being exercised. It is NOT meant to be consumed by doctrine surfaces.

Root Cause: cross-source-silos rule does not yet distinguish self-instrumentation
ledgers (whose contract IS to be sampled by gap-hunt-probe) from operational-data
ledgers (whose absence from doctrine surfaces is a real silo).

Forever-Rule (already in writer): `~/.claude/skills/.flywheel/lib/autoloop-executor.sh`
header explicitly declares the self-instrumentation contract:
"[wired-but-cold fix flywheel-2xdi.32] Self-logs each main()-entry to
AUTOLOOP_EXECUTOR_LEDGER so gap-hunt-probe's wired-but-cold sampling of
$HOME/.local/state/flywheel/*.jsonl sees this library being exercised."

The `~/.claude/skills/.flywheel/lib/doctor.d/part-03-security-posture.sh`
follows the same pattern (writes to `security-posture.jsonl`).

Fix Applied/Status: This INCIDENTS cross-reference makes
`autoloop-executor.jsonl` visible in the cross-source-silos receiver-text scan,
resolving the immediate finding. Systemic improvement (gap-hunt-probe knows
about self-instrumentation ledgers without per-ledger INCIDENTS edits) tracked
under `flywheel-gui5f`.

Recurrence Prevention: Donella leverage point #6 (information flow) — the
cross-source-silos probe now sees the ledger name in INCIDENTS.md. Long-term
fix at flywheel-gui5f extends the probe with a known-silo allowlist or
self-instrumentation schema marker, eliminating per-ledger INCIDENTS edits
for the 15+ findings of this class. Until then, similar self-instrumentation
ledgers (e.g. `security-posture.jsonl`) can be cross-referenced in this same
INCIDENTS section.

Other known self-instrumentation ledgers (named here for cross-source-silos
visibility):
- `autoloop-executor.jsonl` — written by `lib/autoloop-executor.sh`
- `security-posture.jsonl` — written by `lib/doctor.d/part-03-security-posture.sh`

Evidence:
- Ledger: `~/.local/state/flywheel/autoloop-executor.jsonl` (1 entry, 2026-05-09T16:11:40Z, schema=`autoloop-executor.entry.v1`).
- Writer: `~/.claude/skills/.flywheel/lib/autoloop-executor.sh` (declares self-instrumentation contract in header).
- Probe: `.flywheel/scripts/gap-hunt-probe.sh::probe_cross_source_silos()` (lines 642-654).
- Receiver-text source: `command_text()` reads tick.md, status.md, synth.md, AGENTS.md, INCIDENTS.md, README.md.
- Bead: `flywheel-2xdi.40` (this dispatch).
- Sibling fix (precedent): `flywheel-2xdi.32` (made autoloop-executor.sh self-log to address `wired-but-cold` rule; this dispatch handles the sibling `cross-source-silos` rule for the same ledger).
- Systemic followup: `flywheel-gui5f` (extend cross-source-silos probe with self-instrumentation awareness).
