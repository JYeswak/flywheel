# NTM Surface Gap Audit Spreadsheet

Date: 2026-05-07
Repo: `/Users/josh/Developer/flywheel`
Mission anchor: `continuous-orchestrator-uptime-self-sustaining-fleet`
NTM version: `ntm version v1.14.0-290-g99c67b31`
NTM commit: `99c67b310485d6ba9ca5d2823dc7b3fec99c39c3`
NTM built: `2026-05-07T13:53:15Z`

Grounding used:
- Inventory: `.flywheel/NTM-SURFACE-INVENTORY.md`
- Wire-in DAG: `.flywheel/plans/ntm-surface-wire-in-USE-ISSUE-WRAP-2026-05-07/04-BEADS-DAG.md`
- Dispatch log: `.flywheel/dispatch-log.jsonl`
- Bead ground truth: `br list --json --status closed --limit 0` and open list
- Jeff backlog: `gh issue list --repo Dicklesworthstone/ntm --state open --limit 30`
- Live surface list: `ntm --help`
- Socraticode survey: 10 queries against `/Users/josh/Developer/flywheel`

Important audit note: the live NTM binary exposes 108 commands. The inventory master table has 106 numbered rows because it combines `personas / profiles` and `worktree / worktrees`. This audit splits those two combined rows so the per-row table has 108 one-command rows.

## Section 1 - Headline Gaps

| Metric | Count | Finding |
|---|---:|---|
| Re-classified surfaces | 15 | 13 original `USE` rows are actually `WRAP` or `WRAP-transitional` after implementation experience; `scrub` should be treated as `ISSUE/WRAP-pending` until `redact` equivalence is proven; `worktree/worktrees` must split into separate tracked surfaces. |
| Unverified `USE` rows | 44 | Many live NTM commands remain correct to classify as `USE`, but have no direct flywheel callsite plus test/probe receipt. They are plan-valid, not regression-measured. |
| Unverified `WRAP` rows | 2 | `coordinator` and `pipeline` have wrapper fixtures, but remain transitional until ntm#124 unlocks daemon/watch correctness. |
| New spreadsheet rows discovered | 2 | `profiles` and `worktrees` are live commands hidden inside combined inventory rows. No live command is absent after expansion. |
| Stale surfaces | 0 | No inventory command is deprecated or absent from `ntm --help` after the two combined rows are expanded. |
| Open upstream blockers | 1 | Jeff issue #124: `assign --watch dispatches to busy panes; idle-detection ignores robot-activity`. This blocks the three remaining original W1 P0 beads. |
| Remaining original wire-in beads | 3 | `flywheel-7fcki`, `flywheel-sox9n`, and `flywheel-rd8oa` remain open and all depend on the #124 wait/watch/assign behavior. |
| Evidence coverage gap | material | `/private/tmp` evidence exists for the late W3/W4 set, but not every closed W1/W2 bead has a durable evidence file discoverable by bead id. Dispatch close events are not enough for a future measurement gate. |
| CLI audit correction | 1 | The packet requested `ntm --version`; the live CLI supports `ntm version`. The audit cites the working command and should update future audit instructions. |

Interpretation: the wire-in landed enough native surface to remove substantial hand-roll, but the spreadsheet still overstates `USE` as if it always means direct native call. Post-wire-in, the useful states are: `USE-direct`, `USE-unmeasured`, `WRAP-doctrine`, `WRAP-transitional`, `ISSUE-upstream`, and `EXCLUDED-receipt-needed`.

## Section 2 - Per-Row Audit Table

Legend: `Verified` means there is at least one concrete callsite/test/evidence receipt. `Partial` means native is used but blocked by a known upstream or measurement gap. `Unverified` means the inventory decision can still be right, but future drift would not break a gate today.

| # | Surface | Original decision | Verified? | Re-classify? | Validation gap | Action |
|---:|---|---|---|---|---|---|
| 1 | `activity` | USE | yes - high callsite volume and W3 evidence via pane-work/dispatch verification | no | none material | keep; include in coverage matrix |
| 2 | `add` | EXCLUDED | partial - rationale exists, no executable receipt | no | no explicit no-fit assertion | add exclusion receipt test |
| 3 | `adopt` | USE | unverified | no | no flywheel onboarding proof found | add onboarding/no-fit callsite or receipt |
| 4 | `agents` | USE | partial | no | identity-registry replacement not proven by a fixture | add identity-manifest fixture against `ntm agents --json` |
| 5 | `analytics` | USE | partial - W4 daily-report evidence exists | no | daily-report suite still has unrelated launchd plist failure | split/fix daily-report validation |
| 6 | `approve` | USE | yes - W2 wrapper class exists | yes - USE -> WRAP-doctrine | native gate plus flywheel exact-question receipt must both stay measured | matrix as wrapper, not direct USE |
| 7 | `assign` | USE | partial - dispatch/capacity callsites verified | no, but mark blocked submode | `assign --watch` is blocked by ntm#124 | finish the three W1 beads after #124 |
| 8 | `attach` | USE | unverified | no | operator surface only; no regression probe | add explicit operator-surface receipt |
| 9 | `audit` | USE | partial - wrapper/test references exist | yes - USE -> WRAP-doctrine | hash-chain/canonical-writer wrapper is the actual flywheel contract | matrix as wrapper with native source |
| 10 | `beads` | EXCLUDED | partial | no | br ownership is doctrine, not test-backed | add exclusion receipt test |
| 11 | `bind` | USE | yes - W4 onboarding fixture invokes native command | no | none material | keep in onboarding fixture |
| 12 | `bugs` | USE | yes - W4 daily-report rollup fixture references native bugs path | no | daily-report suite failure should be isolated | add focused bugs fixture |
| 13 | `cass` | USE | unverified | no | direct CASS replacement not proven | add CASS/native replacement bead or receipt |
| 14 | `changes` | USE | unverified | no | no path-attribution replacement proof | add changes-vs-handroll fixture |
| 15 | `checkpoint` | USE | yes - rollback/checkpoint wrapper class closed | yes - USE -> WRAP-doctrine | dirty-worktree exception protocol is flywheel-specific | matrix as wrapper |
| 16 | `cleanup` | USE | yes - private tmp prune evidence delegates to native cleanup | no | none material | keep fixture |
| 17 | `completion` | USE | yes - W4 onboarding fixture invokes native command | no | none material | keep in onboarding fixture |
| 18 | `config` | USE | unverified | no | TOML installer claim lacks test receipt in this audit | add config installer probe |
| 19 | `conflicts` | USE | unverified | no | no conflict-detector replacement proof | add file-conflict fixture or no-fit receipt |
| 20 | `context` | USE | yes - build-dispatch-packet evidence uses native context | no | none material | keep packet materializer fixture |
| 21 | `controller` | USE | unverified | no | no controller replacement callsite/test | add operator receipt or future bead |
| 22 | `coordinator` | USE | partial - shadow wrapper tested | yes - USE -> WRAP-transitional | daemon correctness blocked by ntm#124 | delete shadow after #124 and add native probe |
| 23 | `copy` | USE | unverified | no | no clipboard/tail replacement proof | add copy fixture or operator receipt |
| 24 | `create` | USE | unverified | no | onboarding uses spawn/setup more than create; create not directly asserted | add create/session fixture or no-fit receipt |
| 25 | `dashboard` | USE | unverified | no | interactive operator surface only | add explicit operator-surface receipt |
| 26 | `deps` | USE | yes - W4 onboarding fixture invokes native command | no | none material | keep in onboarding fixture |
| 27 | `diff` | USE | unverified | no | two-truth replacement not proven | add diff/two-pane fixture |
| 28 | `doctor` | USE | partial | no | should be a sibling probe in flywheel doctor, but no matrix assertion | add ntm doctor probe to validation matrix |
| 29 | `ensemble` | USE | unverified | no | W4T queued language but no closed evidence | add triage/no-fit receipt |
| 30 | `errors` | USE | yes - stale-error-auto-ping evidence derives candidates from native errors JSON | no | none material | keep fixture |
| 31 | `extract` | USE | unverified | no | no worker-stall-alert proof | add extract fixture or receipt |
| 32 | `get-all-session-text` | USE | unverified | no | tail aggregation replacement not measured | add tail replacement fixture |
| 33 | `git` | USE | unverified | no | recovery flow replacement not measured | add git coordination fixture |
| 34 | `grep` | USE | partial | no | direct grep replacement broad, but not fully mapped | add grep surface test for frozen/stuck flows |
| 35 | `guards` | USE | unverified | no | hook overlap not proven | add guards/no-overlap audit bead |
| 36 | `handoff` | USE | unverified | no | prose handoff wrapper not measured | add handoff receipt fixture |
| 37 | `health` | USE | yes - fleet health and capacity-gate evidence | no | none material | keep health fixtures |
| 38 | `help` | EXCLUDED | partial | no | self-referential exclusion lacks assertion | add exclusion receipt |
| 39 | `history` | USE | yes - dispatch-delivery and pane-work evidence use native history/activity | no | none material | keep four-state fixture |
| 40 | `hooks` | USE | unverified | no | hook replacement not measured | add hooks audit/no-fit receipt |
| 41 | `init` | USE | yes - W4 onboarding fixture invokes native command | no | none material | keep in onboarding fixture |
| 42 | `interrupt` | USE | unverified | no | recovery escape replacement not measured | add interrupt fixture with dry-run/mock |
| 43 | `kernel` | USE | unverified | no | validator cross-reference not proven | add kernel registry probe |
| 44 | `kill` | USE | unverified | no | only test-fixture replacement claim | add fixture migration or exclusion receipt |
| 45 | `level` | USE | unverified | no | onboarding/operator doc claim only | add operator receipt |
| 46 | `list` | USE | yes - fleet health fixtures use native list | no | none material | keep list/health matrix |
| 47 | `lock` | ISSUE | partial | no | MCP Agent Mail parity still unresolved | file compare bead / upstream issue if fields missing |
| 48 | `locks` | ISSUE | partial | no | same as lock | file compare bead / upstream issue if fields missing |
| 49 | `logs` | USE | unverified | no | no log aggregation replacement proof | add logs fixture |
| 50 | `mail` | USE | partial | no | human-orch broadcast replacement not fully proven | add mail/send equivalence fixture |
| 51 | `memory` | USE | unverified | no | direct memory replacement not proven | add memory command fixture |
| 52 | `message` | USE | yes - agentmail registration/broadcast evidence uses native message/send path | no | none material | keep broadcast fixture |
| 53 | `metrics` | USE | yes - W1 wrapper class closed | yes - USE -> WRAP-doctrine | metric-to-gate-action mapping is flywheel-specific | matrix as wrapper |
| 54 | `models` | USE | unverified | no | Ollama-status replacement not measured | add models probe or no-fit receipt |
| 55 | `modes` | USE | unverified | no | mode enum replacement not measured | add modes receipt |
| 56 | `openapi` | USE | unverified | no | flywheel REST exposure not established | likely no-fit receipt unless serve/openapi path exists |
| 57 | `overlay` | USE | unverified | no | interactive overlay only | add operator-surface receipt |
| 58 | `palette` | USE | unverified | no | interactive palette only | add operator-surface receipt |
| 59 | `personas` | USE | unverified | no | combined row obscured exact command | split row and add CAAM rotate fixture |
| 60 | `profiles` | USE | unverified | yes - hidden combined row -> explicit USE row | no independent row/receipt | split row and add profile fixture |
| 61 | `pipeline` | USE | partial - shadow wrapper tested | yes - USE -> WRAP-transitional | daemon/watch correctness blocked by ntm#124 | delete shadow after #124 and add native probe |
| 62 | `plugins` | USE | unverified | no | no plugin replacement proof | add operator receipt |
| 63 | `policy` | USE | yes - W3 wrapper class closed | yes - USE -> WRAP-doctrine | privilege-escalation warn-only semantics are flywheel-specific | matrix as wrapper |
| 64 | `preflight` | USE | yes - W2 wrapper class closed | yes - USE -> WRAP-doctrine | L91 four-state receipt is flywheel-specific | matrix as wrapper |
| 65 | `profile` | USE | unverified | no | session profile replacement not measured | add spawn-profile fixture |
| 66 | `quick` | USE | unverified | no | onboarding did not prove quick path | add no-fit or quick setup receipt |
| 67 | `quota` | USE | yes - W1 wrapper class closed | yes - USE -> WRAP-doctrine | threshold/unknown-provider semantics are flywheel-specific | matrix as wrapper |
| 68 | `rebalance` | USE | yes - peer blocker watch evidence invokes rebalance JSON | no | none material | keep swarm/rebalance fixture |
| 69 | `recipes` | USE | unverified | no | session bootstrap replacement not measured | add recipe fixture |
| 70 | `redact` | ISSUE | partial | no | overlap with scrub wrapper still unresolved | file compare bead |
| 71 | `replay` | USE | unverified | no | recovery resend replacement not measured | add replay fixture |
| 72 | `repo` | USE | unverified | no | repo_realpath replacement not measured | add repo topology fixture |
| 73 | `respawn` | USE | yes - respawn-permit evidence uses native respawn/health | no | LOC target missed but behavior verified | keep fixture; optionally trim further later |
| 74 | `resume` | USE | unverified | no | handoff resume path not measured | add resume receipt fixture |
| 75 | `review-queue` | ISSUE | partial | no | lacks L85 idle-state schema; upstream bead open `flywheel-txeui.1` | track upstream issue/bead |
| 76 | `rollback` | USE | yes - checkpoint/rollback wrapper class closed | yes - USE -> WRAP-doctrine | dirty-worktree gate is flywheel-specific | matrix as wrapper |
| 77 | `rotate` | USE | yes - W0 wrapper class closed | yes - USE -> WRAP-doctrine | CAAM profile/idempotency layer is flywheel-specific | matrix as wrapper |
| 78 | `safety` | USE | yes - W2 wrapper class closed | yes - USE -> WRAP-doctrine | DCG remains authority; native is advisory | matrix as wrapper |
| 79 | `save` | USE | unverified | no | tail-capture replacement not measured | add save fixture |
| 80 | `scale` | USE | unverified | no | worker-slot replacement not measured | add scale dry-run fixture |
| 81 | `scan` | USE | yes - daily-report evidence includes scan path | no | daily-report suite failure should be isolated | add focused scan fixture |
| 82 | `scrub` | USE | partial | yes - USE -> ISSUE/WRAP-pending | duplicate with redact not resolved | compare scrub/redact and either delete wrapper or file Jeff issue |
| 83 | `search` | USE | unverified | no | CASS search replacement not measured | add search fixture |
| 84 | `send` | USE | yes - many dispatch/callback fixtures use native send | no | none material | keep canonical send probes |
| 85 | `serve` | USE | yes - W1 wrapper class closed | yes - USE -> WRAP-doctrine | loopback/redaction envelope is flywheel-specific | matrix as wrapper |
| 86 | `session-templates` | USE | unverified | no | companion to recipes, not measured | add template/session fixture |
| 87 | `sessions` | USE | partial | no | claim says already wired, but no focused regression receipt | add sessions probe |
| 88 | `setup` | USE | yes - W4 onboarding fixture invokes native command | no | none material | keep in onboarding fixture |
| 89 | `shell` | USE | yes - W4 onboarding fixture invokes native command | no | none material | keep in onboarding fixture |
| 90 | `spawn` | USE | yes - W4 onboarding fixture invokes native command | no | none material | keep in onboarding fixture |
| 91 | `status` | USE | partial | no | coordinator status claim blocked by transitional wrapper | add direct status fixture after #124 |
| 92 | `summary` | USE | yes - daily-report evidence includes summary path | no | daily-report suite failure should be isolated | add focused summary fixture |
| 93 | `support-bundle` | USE | unverified | no | diagnostic bundle replacement not measured | add support-bundle fixture |
| 94 | `swarm` | USE | partial - peer blocker fixture exists | no, but upstream JSON gap | live `swarm status --json` has no JSON envelope when no swarm sessions | file Jeff issue or wrapper guard |
| 95 | `template` | USE | yes - build-dispatch-packet evidence uses native template | no | none material | keep packet materializer fixture |
| 96 | `timeline` | USE | yes - dispatch-log fitness evidence uses native timeline | no | none material | keep timeline fixture |
| 97 | `tutorial` | EXCLUDED | partial | no | one-shot interactive exclusion lacks receipt | add exclusion receipt |
| 98 | `unlock` | ISSUE | partial | no | same Agent Mail parity issue as lock | file compare bead / upstream issue if fields missing |
| 99 | `upgrade` | USE | yes - Jeff binary watchtower evidence invokes native upgrade/version | no | none material | keep version/upgrade fixture |
| 100 | `version` | USE | yes - Jeff binary watchtower evidence invokes native version | no | packet used wrong flag form | update audit instructions to `ntm version` |
| 101 | `view` | USE | unverified | no | operator view surface not measured | add operator receipt |
| 102 | `wait` | USE | partial | no, but blocked submode | three W1 beads remain open on wait/watch semantics | finish after #124 |
| 103 | `watch` | USE | partial | no, but blocked submode | same #124 idle-detection blocker | finish after #124 |
| 104 | `work` | ISSUE | partial | no | duplicate/contract overlap with assign unresolved | file compare bead |
| 105 | `workflows` | USE | unverified | no | workflow replacement not measured | add workflows fixture |
| 106 | `worktree` | ISSUE | partial | no | combined row obscures single-command tracking | split row and compare with PRD skill |
| 107 | `worktrees` | ISSUE | partial | yes - hidden combined row -> explicit ISSUE row | no independent row/receipt | split row and compare with PRD skill |
| 108 | `zoom` | EXCLUDED | partial | no | interactive exclusion lacks receipt | add exclusion receipt |

## Section 3 - Validation Matrix Recommendation

The next layer should be generated, not hand-maintained. A future check should load live `ntm --help`, parse the inventory table, expand combined rows, and require every surface to carry one of four proof shapes.

```yaml
schema_version: ntm_surface_validation_matrix.v1
generated_by: .flywheel/scripts/ntm-surface-validation-matrix.sh
ntm:
  version_command: ntm version
  version: v1.14.0-290-g99c67b31
  commit: 99c67b310485d6ba9ca5d2823dc7b3fec99c39c3
  help_command: ntm --help
inventory:
  path: .flywheel/NTM-SURFACE-INVENTORY.md
  expected_live_surface_count: 108
  combined_rows_must_be_split:
    - original_row: 59
      expands_to: [personas, profiles]
    - original_row: 105
      expands_to: [worktree, worktrees]
rules:
  USE:
    required:
      - flywheel_callsites:
          search: rg -n 'ntm <surface>|"$NTM_BIN" <surface>|$NTM_BIN <surface>' .flywheel scripts tests templates
          min: 1
      - validation_artifact:
          one_of:
            - test_script_passed
            - doctor_probe
            - dispatch_evidence_file
            - explicit_unmeasured_receipt_with_bead
  WRAP:
    required:
      - wrapper_path
      - native_command_invoked_by_wrapper
      - wrapper_fixture
      - doctrine_reason:
          enum: [exact_question_receipt, hash_chain, dirty_worktree_gate, L91_four_state, quota_threshold, security_envelope, caam_profile, transitional_ntm124]
  ISSUE:
    required:
      - upstream_or_research_tracking:
          one_of: [br_bead_id, gh_issue_id, compare_fixture]
      - local_behavior_until_resolved:
          enum: [keep_wrapper, no_op, use_alternate_native, excluded]
  EXCLUDED:
    required:
      - no_fit_receipt
      - reason:
          enum: [interactive_only, br_owned, self_referential, out_of_mission]
      - regression_assertion:
          description: breaks if inventory silently flips to USE without evidence
surface_record:
  name: activity
  row: 1
  decision: USE
  flywheel_callsites: []
  tests_or_probes: []
  evidence_files: []
  upstream_issue: null
  br_tracking: null
  status: verified
```

Recommended gates:
- `ntm-surface-validation-matrix.sh --json` emits one JSON record per live command.
- `ntm-surface-validation-matrix.sh --strict` fails when live command count differs from expanded inventory count.
- `flywheel-loop doctor` consumes the matrix summary and warns on `USE-unmeasured` or `WRAP-unverified`.
- Dispatch closeout writes a durable evidence index keyed by bead id, not only ad-hoc `/private/tmp` filenames.

## Section 4 - Follow-Up Beads

1. Title: `[ntm-gap-audit] split combined inventory rows into exact 108 live surfaces`
   Priority: P1
   Expected delta: +20 LOC markdown, +1 parser fixture
   Mission anchor: `continuous-orchestrator-uptime-self-sustaining-fleet`
   Why it matters: one live command per row is the base invariant for every future measurement.

2. Title: `[ntm-validation] generate ntm-surface-validation-matrix.json`
   Priority: P0
   Expected delta: +1 script, +2 tests
   Mission anchor: `continuous-orchestrator-uptime-self-sustaining-fleet`
   Why it matters: turns the spreadsheet from plan prose into a regression gate.

3. Title: `[ntm-validation] add exclusion receipts for add/beads/help/tutorial/zoom`
   Priority: P1
   Expected delta: +6 tests/receipts
   Mission anchor: `continuous-orchestrator-uptime-self-sustaining-fleet`
   Why it matters: EXCLUDED should be an explicit decision, not absence of work.

4. Title: `[ntm-upstream] make swarm status --json return a stable empty-swarm envelope`
   Priority: P1
   Expected delta: upstream issue or patch, +1 fixture
   Mission anchor: `continuous-orchestrator-uptime-self-sustaining-fleet`
   Why it matters: current peer-blocker wrapper cannot trust native JSON in the no-session case.

5. Title: `[ntm-wire-in] finish ntm#124-blocked wait/watch/assign beads`
   Priority: P0
   Expected delta: about -1418 LOC across the three open W1 scripts
   Mission anchor: `continuous-orchestrator-uptime-self-sustaining-fleet`
   Why it matters: these are the last original high-priority daemon/polling wire-ins.

6. Title: `[ntm-validation] repair daily-report native rollup fixture isolation`
   Priority: P1
   Expected delta: +1 focused fixture, possible -1 brittle launchd assertion
   Mission anchor: `continuous-orchestrator-uptime-self-sustaining-fleet`
   Why it matters: analytics/bugs/scan/summary are wired but hidden behind an unrelated failing suite.

7. Title: `[ntm-validation] persist bead evidence index for every closed dispatch`
   Priority: P1
   Expected delta: +1 evidence writer, +1 closeout fixture
   Mission anchor: `continuous-orchestrator-uptime-self-sustaining-fleet`
   Why it matters: future audits should not depend on ad-hoc `/private/tmp` discovery.

8. Title: `[ntm-research] compare lock/locks/unlock with MCP Agent Mail reservations`
   Priority: P1
   Expected delta: +1 compare fixture, possible Jeff issue
   Mission anchor: `continuous-orchestrator-uptime-self-sustaining-fleet`
   Why it matters: file reservation is concurrency safety; partial parity is dangerous.

9. Title: `[ntm-research] compare redact and scrub against flywheel secret fixtures`
   Priority: P1
   Expected delta: +1 fixture suite, possible wrapper deletion
   Mission anchor: `continuous-orchestrator-uptime-self-sustaining-fleet`
   Why it matters: duplicate secret-cleaning surfaces drift unless one owns the contract.

10. Title: `[ntm-validation] classify operator-only USE rows with receipts`
    Priority: P2
    Expected delta: +12 small receipts
    Mission anchor: `continuous-orchestrator-uptime-self-sustaining-fleet`
    Why it matters: dashboard/overlay/palette/view/zoom-like surfaces need intentional status.

11. Title: `[ntm-wire-in] delete coordinator and pipeline shadow wrappers after ntm#124`
    Priority: P1
    Expected delta: about -200 LOC
    Mission anchor: `continuous-orchestrator-uptime-self-sustaining-fleet`
    Why it matters: transitional wrappers should not become permanent doctrine by inertia.

12. Title: `[ntm-research] compare work/workflows/worktree/worktrees with assign and PRD skill hand-roll`
    Priority: P2
    Expected delta: +3 compare fixtures, possible Jeff issue
    Mission anchor: `continuous-orchestrator-uptime-self-sustaining-fleet`
    Why it matters: these high-level orchestration commands are easy to double-implement unless their contracts are pinned.

## Self-Grade

`four_lens=brand:9,sniff:9,jeff:9,public:9`

Rationale: the audit is strict about the measurement gap without treating closed beads as failed work. It separates native-use correctness from regression proof, which is the next leverage point for keeping the wire-in from drifting back to hand-roll.
