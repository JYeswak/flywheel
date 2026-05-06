# Flywheel Incidents

Promoted trauma classes from `~/.local/state/flywheel/fuckup-log.jsonl`.

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
