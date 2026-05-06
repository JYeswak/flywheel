# P0 Bead Freshness Audit - 2026-05-06

Task: `p0-bead-freshness-audit-2026-05-06`.

Scope: read-only audit of 15 open P0 wire-or-explain beads. I did not close
audited beads, author dispatches, edit bead bodies, edit memory/skill files, or
mutate substrate code. Socraticode preflight: 6 queries, 60 results observed.

## Per-Bead Findings

### flywheel-1bt7 | [wire-or-explain] A9 L55 skillos-relay auto-fire (Finding 10)

**Bead body claim**: L55 missing-skill trauma classes need an auto-fire path that emits skillos relay rows and warns on tick.

**Live state probe**:
- `flywheel-skillos-relay --info --json`: binary exists with relay ledger at `~/.local/state/flywheel/skillos-relay-ledger.jsonl`.
- `bash tests/flywheel-skillos-relay-canonical-cli.sh`: PASS; classifier test also passed `skill_candidate_routes_to_skillos`.

**Freshness verdict**: PARTIAL
- Relay substrate exists, but live pending-candidate rows remain and recent auto-drain was not proven.

**Recommended action**: reduce-scope

### flywheel-1kha | [wire-or-explain] A7 L53 callback fuckup-field validator + foundational-tool-repeat-halt

**Bead body claim**: BLOCKED/DONE-with-trauma callbacks need `fuckups_logged`, plus a repeat-halt for recurring foundational-tool risk flags.

**Live state probe**:
- `rg fuckups_logged ~/.claude/commands/flywheel/_shared/dispatch-template.md`: callback template requires the field and rejects `BLOCKED ... fuckups_logged=none`.
- `rg foundational-tool-repeat .flywheel ~/.claude`: no implementation found for the repeat-halt half.

**Freshness verdict**: PARTIAL
- L53 callback field contract is wired in the template and validator path; repeat-halt remains fresh.

**Recommended action**: reduce-scope

### flywheel-1wjt | [wire-or-explain] A6 L52 issues-beads-or-no-bead-receipt enforcer

**Bead body claim**: observed gaps must become beads or explicit `no_bead_reason` receipts.

**Live state probe**:
- `rg no_bead_reason ~/.claude/commands/flywheel/_shared/dispatch-template.md`: callback envelope requires a bead action or explicit reason.
- `rg no_bead_reason .flywheel/scripts/validate-callback.py`: validator parses `no_bead_reason` and fails callbacks without valid bead actions.

**Freshness verdict**: PARTIAL
- Callback-side enforcement exists; a standalone observed-gap scanner remains broader than the current wiring.

**Recommended action**: reduce-scope

### flywheel-1wkyb | [wire-or-explain] H9 launchctl pre-bootstrap wrapper hook - refuses unregistered plists

**Bead body claim**: `launchctl bootstrap` needs a registry-backed wrapper gate so unregistered plists cannot load.

**Live state probe**:
- `type -a launchctl`: PATH resolves `/Users/josh/.local/bin/launchctl` before `/bin/launchctl`; it is a symlink to `launchctl-guard`.
- `launchctl-guard --info --json`: reports registry, ledger, blocked exit code 4, and bypass envs.

**Freshness verdict**: STALE_RESOLVED
- The named load-time gate is present. Any exact doctor-field naming polish should be a smaller follow-up.

**Recommended action**: close-stale-resolved

### flywheel-2bfg | [wire-or-explain] DCG orphan reset blocker

**Bead body claim**: reset safety must prevent orphaning unmerged worker commits, with reset-intent plus sorted orphan commit receipts.

**Live state probe**:
- `bash tests/wire-or-explain-classifier.sh`: PASS, including `reset_guard_records_hash_and_sorted_orphans`.
- `dcg explain 'git reset --mixed HEAD~1'`: ALLOW; current DCG does not inspect orphan-commit reachability for mixed resets.

**Freshness verdict**: FRESH
- Ledger/classifier support exists, but the DCG reset blocker itself is not live.

**Recommended action**: continue-with-dispatch

### flywheel-2fz8z | [wire-or-explain] H2 phase-anchor-probe.sh doctor field + dispatcher refusal hook

**Bead body claim**: a phase-anchor probe should expose current phase and block ahead-of-phase dispatches.

**Live state probe**:
- `rg current_open_phase .flywheel/scripts/mission-anchor-dispatch-license.sh`: mission license emits current phase and phase-tag data.
- `rg --files | rg phase-anchor`: no `phase-anchor-probe.sh` or named refusal hook found.

**Freshness verdict**: PARTIAL
- Phase data exists in the mission-license surface; the named probe/refusal hook remains unwired.

**Recommended action**: reduce-scope

### flywheel-2gix | [wire-or-explain] A4 L50 socraticode preflight count

**Bead body claim**: dispatch substrate should detect zero Socraticode preflight counts.

**Live state probe**:
- `rg socraticode_queries ~/.claude/commands/flywheel/_shared/dispatch-template.md`: template requires callback counts.
- `rg socraticode_zero .flywheel/scripts ~/.claude`: no concrete zero-count scanner matching the bead body found.

**Freshness verdict**: FRESH
- The advisory/template contract exists, but the requested scanner/enforcer is still absent.

**Recommended action**: continue-with-dispatch

### flywheel-2wvu | [wire-or-explain] A11 L57 loop-driver drift detector

**Bead body claim**: loop-state markers must be compared to driver evidence rather than trusted as active loops.

**Live state probe**:
- `flywheel-loop doctor --scope loop-driver --json`: exposes `loop_driver.driver_status`.
- Live result: `driver_status=MISSING_DRIVER`, with `loop_state_without_driver`, project-label, and pane-prompt violations.

**Freshness verdict**: STALE_RESOLVED
- The detector exists and is actively surfacing drift.

**Recommended action**: close-stale-resolved

### flywheel-2x5yi | [wire-or-explain] H7 flywheel-watchers canonical CLI for plist on/off/status

**Bead body claim**: canonical `flywheel-watchers` CLI needs on/off/status, JSON, triad surfaces, and doctor integration.

**Live state probe**:
- `flywheel-watchers --info --json`: binary exists, reports registry/ledger paths and dry-run-by-default mutation posture.
- `bash tests/flywheel-watchers-test.sh`: PASS 62/62; live `status --repo flywheel --json` reports 20 rows, active=5, disabled=15, loaded=4.

**Freshness verdict**: PARTIAL
- The CLI is strong; exact `watcher_off_age_seconds` doctor-field integration was not proven.

**Recommended action**: reduce-scope

### flywheel-3iz0 | [wire-or-explain] dogfood import 2026-05-04

**Bead body claim**: existing 2026-05-04 findings need idempotent import into wire-or-explain ledger with skill relay proof.

**Live state probe**:
- `rg --files | rg dogfood-import`: no live import script found.
- `tests/wire-or-explain-close-gate.sh`: contains B8 dogfood bootstrap proof fixtures, but not the actual backfill importer.

**Freshness verdict**: FRESH
- The dogfood importer itself still appears absent.

**Recommended action**: continue-with-dispatch

### flywheel-3sz6 | [wire-or-explain] A1 L29 ntm-canonical-cli enforcer

**Bead body claim**: raw pane/session operations should be blocked in favor of canonical `ntm` verbs.

**Live state probe**:
- `ls ~/.claude/hooks/flywheel-orch-use-ntm-not-raw-tmux-gate.sh`: hook exists and is executable.
- `bash .flywheel/tests/test_use_ntm_not_raw_tmux_gate.sh`: prior shipped test surface exists; Socraticode found the INCIDENTS entry wiring it into settings.

**Freshness verdict**: STALE_RESOLVED
- The structural gate is shipped and wired.

**Recommended action**: close-stale-resolved

### flywheel-8na7 | [wire-or-explain] A12 L61 3-surface drift error escalation

**Bead body claim**: L61 doctrine landing needs 3-surface drift detection and error escalation.

**Live state probe**:
- `.flywheel/scripts/doctrine-3-surface-divergence-probe.sh --json`: exists and returns `doctrine_3_surface_divergent_count=2`.
- `rg doctrine_3_surface .flywheel/scripts/doctor-signal-bead-promotion.sh`: doctor promotion consumes the drift count.

**Freshness verdict**: PARTIAL
- Detection/escalation substrate exists, but live drift remains, so scope should shrink to current divergence handling.

**Recommended action**: reduce-scope

### flywheel-dt2w | [wire-or-explain] dispatch worker-side branch enforcement

**Bead body claim**: dispatches and callbacks need branch/ref identity proof to prevent local-main worker artifacts being reset away.

**Live state probe**:
- `bash tests/wire-or-explain-classifier.sh`: PASS `worker_branch_records_ref_and_identity_hash`.
- `rg branch_ref ~/.claude/commands/flywheel/_shared/dispatch-template.md`: no broad dispatch-template requirement found.

**Freshness verdict**: PARTIAL
- Classifier and ledger shape exist; dispatch/callback contract enforcement is not proven.

**Recommended action**: reduce-scope

### flywheel-g4zy | [wire-or-explain] C5 callback-validator gates 3-judges scores

**Bead body claim**: callback validation should require `jeff_score`, `donella_score`, and `joshua_score`.

**Live state probe**:
- `callback-envelope-schema-validator.sh --info --json`: validator exists and names the callback-envelope schema ledger.
- `rg jeff_score .flywheel/scripts/callback-envelope-schema-validator.sh`: required fields and thresholds are implemented.

**Freshness verdict**: STALE_RESOLVED
- The 3-judges callback envelope gate exists.

**Recommended action**: close-stale-resolved

### flywheel-olrx | [wire-or-explain] C7 dispatch-template L111 inheritance + bead acceptance gate

**Bead body claim**: dispatch template should inherit L111 quality fields and bead acceptance gate so C1-C5 rows happen automatically.

**Live state probe**:
- `rg jeff_score ~/.claude/commands/flywheel/_shared/dispatch-template.md`: template includes L111 score fields.
- `rg AUTO-L112 ~/.claude/commands/flywheel/_shared/dispatch-template.md`: template includes machine-rerunnable L112 callback gate.

**Freshness verdict**: PARTIAL
- Template inheritance exists; automatic row production for the whole C1-C5 chain was not proven.

**Recommended action**: reduce-scope

## Counts By Verdict

FRESH=3, STALE_RESOLVED=4, PARTIAL=8, UNKNOWN=0. Total=15.

## Stale-Resolution Candidates

These can be considered for close without dispatch, subject to Joshua review:

- `flywheel-1wkyb`
- `flywheel-2wvu`
- `flywheel-3sz6`
- `flywheel-g4zy`

## Highest-Leverage FRESH Beads

- `flywheel-2bfg`: DCG reset/orphan protection prevents irreversible substrate loss; it is a rule change at a destructive boundary.
- `flywheel-2gix`: zero Socraticode preflight detection moves stale-target prevention upstream into dispatch information flow.
- `flywheel-3iz0`: dogfood import turns historical known gaps into durable wire-or-explain rows, increasing self-organization for the whole gate.

## Donella Analysis

System boundary: flywheel dispatch authoring and closeout for P0 wire-or-explain work.

Stock: stale or partially stale P0 beads that can accidentally become dispatch packets.

Pattern: without freshness checks, dispatch authors send workers toward already-closed drift targets or broad beads whose true remaining work is narrower.

Leverage points, using the Donella Meadows 1999 ladder from the local skill:

- #6 information flows: this audit adds live substrate evidence beside each bead body before dispatch authoring.
- #5 rules: the recommended pre-dispatch protocol below makes stale-target checks mandatory before upgrade/wiring dispatches.
- #4 self-organization: categorizing PARTIAL beads lets the system split/reduce scope instead of forcing one large stale bead through implementation.

Primary-source basis: Donella H. Meadows, "Leverage Points: Places to Intervene in a System", Donella Meadows Project archive, retrieved in the local skill source registry at 2026-05-02T01:30:41Z.

## Pre-Dispatch Check Protocol

1. **Body claim extraction**: summarize the bead's substrate assumption in one sentence and name the exact target files, scripts, binaries, hooks, ledgers, or versions.
2. **Two-truth live probe**: before dispatch, run one semantic Socraticode query plus one direct read-only probe (`--info --json`, `rg`, `test -x`, `doctor --scope`, or version command) against the target.
3. **Decision gate**: if live target is already wired, close as stale-resolved; if partially wired, re-author the dispatch around the remaining field/hook/test only; if still absent, dispatch implementation with the probe evidence embedded.

## Probe Ledger

- Socraticode queries: 6.
- Indexed/result chunks observed: 60.
- Local tests run read-only/temp-scoped: `wire-or-explain-classifier.sh` PASS 20 checks; `flywheel-watchers-test.sh` PASS 62/62; `test-callback-receipt-validator.sh` PASS 16 assertions; `validate-callback.sh` PASS 18 checks.
- Interrupted probe: `tests/wire-or-explain-doctor.sh` hung during full doctor; earlier checks passed through skill relay metrics. The hang did not block the report because live `flywheel-loop doctor --scope loop-driver` and targeted scripts supplied the needed evidence.
