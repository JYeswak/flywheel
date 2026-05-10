---
title: "Substrate-wide Trauma-Class Audit - 2026-05-05"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Substrate-wide Trauma-Class Audit - 2026-05-05

Task: `b56-substrate-trauma-class-audit-2026-05-05`

Scope was the dispatch packet in `/tmp/dispatch_b56_trauma_class_audit_2026-05-05.md`.
This report is a substrate population audit for the three trauma classes observed
on 2026-05-05: silent writes, destructive defaults, and unregistered process or
LaunchAgent surfaces.

## Self-grade

| field | value |
|---|---:|
| jeff_score | 9.6 |
| donella_score | 9.6 |
| joshua_score | 9.5 |
| composite | 9.57 |
| quality_bar_passed | yes |
| l113_compliance | yes |
| did_claims_with_evidence_count | 39 |
| didnt_claims_with_evidence_count | 5 |
| evidence_coverage_rate | 44/44 |

Counting convention:

- DID claims are the 5 methodology commands plus 34 positive finding rows below.
- DIDN'T claims are the 5 negative-control rows under "False positives and guardrails".
- Every row carries either a file:line cite or a re-runnable command with an expected output substring.

## Methodology

I used the dispatch's multi-pass-bug-hunting flow:

1. Symptom enumeration with `rg`, `find`, `jq`, `PlistBuddy`, and the read-only
   `flywheel-watchers audit-orphans --json`.
2. Manual context read around each candidate before classifying.
3. Pairwise interaction pass for Class N -> Class M compounds.
4. Isomorphism pass against the B54 fixed implementation.

Evidence commands:

| claim | evidence |
|---|---|
| Dispatch packet read | `sed -n '1,260p' /tmp/dispatch_b56_trauma_class_audit_2026-05-05.md`; expected substring: `Class 1: SILENT-WRITE` |
| Skills read | `sed -n '1,220p' ~/.claude/skills/canonical-cli-scoping/SKILL.md`; expected substring: `Mutation discipline` |
| Socraticode preflight done | MCP `codebase_status(projectPath=/Users/josh/Developer/flywheel)` returned `indexed_chunks=452`; four `codebase_search` calls were made |
| Today kill ledger exists | `jq -r 'select(((.ts // .timestamp // "") | tostring | startswith("2026-05-05T00:"))) | select(((.action // "") | tostring | test("audit_kill"))) | .action' ~/.local/state/flywheel/watcher-control-ledger.jsonl \| sort \| uniq -c`; expected substrings: `72 audit_kill_launchctl`, `1 audit_kill_process` |
| Parked rogue script inventory exists | `find /tmp/.disabled-watchers -maxdepth 1 -type f -print \| sort \| wc -l`; expected output: `6` |

## Findings - Class 1 (Silent-Write)

Definition: write to ledger, state, registry, JSONL, or log without immediate
read-back validation of the written row.

Breakdown: total=14, critical=1, high=6, medium=7, low=0.

| finding_id | file:line | severity | classification | evidence | L110 row example | proposed_fix_bead |
|---|---|---:|---|---|---|---|
| C1-01 | `/Users/josh/.local/bin/flywheel-watchers.bak.20260505T005651Z:69`, `:253` | critical | TRUE_INSTANCE | `log_action` appends to `$LEDGER`; `cmd_register` appends `$row` to `$REGISTRY` with no readback. | `artifact_class=trauma_class_instance dedup_key=silent-write:flywheel-watchers-bak:69` | B56-FIX-01, B56-FIX-02 |
| C1-02 | `/Users/josh/Developer/flywheel/.flywheel/scripts/idle-pane-auto-dispatch.sh:234`, `:241` | high | TRUE_INSTANCE | apply path appends cooldown files and `.flywheel/dispatch-log.jsonl` without validating the just-written line. | `dedup_key=silent-write:idle-pane-auto-dispatch:234` | B56-FIX-03 |
| C1-03 | `/tmp/.disabled-watchers/idle-pane-auto-dispatch.sh:57`, `:60` | high | TRUE_INSTANCE | parked script appends logs, markers, and dispatch-log lines without validation. | `dedup_key=silent-write:tmp-idle-pane-auto-dispatch:57` | B56-FIX-04 |
| C1-04 | `/tmp/.disabled-watchers/idle-pane-auto-dispatch-generic.sh:127`, `:130` | high | TRUE_INSTANCE | generic parked script appends same watcher state/log records without validation. | `dedup_key=silent-write:tmp-idle-pane-auto-dispatch-generic:127` | B56-FIX-04 |
| C1-05 | `/tmp/.disabled-watchers/storage-cleared-watcher.sh:58`, `:59` | high | TRUE_INSTANCE | storage watcher appends watcher log and cross-orch JSONL after sending without validation. | `dedup_key=silent-write:tmp-storage-cleared-watcher:58` | B56-FIX-04 |
| C1-06 | `/tmp/.disabled-watchers/jeff-corpus-watcher.sh:11`, `:12` | medium | TRUE_INSTANCE | watcher appends local log and dispatch-log directly. | `dedup_key=silent-write:tmp-jeff-corpus-watcher:11` | B56-FIX-04 |
| C1-07 | `/Users/josh/Developer/flywheel/.flywheel/scripts/leverage-ceiling-probe.sh:267` | medium | TRUE_INSTANCE | `append_ledger` writes to the ledger while the script advertises `read_only:true` at line 85. | `dedup_key=silent-write:leverage-ceiling-probe:267` | B56-FIX-02 |
| C1-08 | `/Users/josh/Developer/flywheel/.flywheel/scripts/headless-browser-reap.sh:137`, `:138` | medium | TRUE_INSTANCE | script always creates history dir and appends history, including dry-run executions. | `dedup_key=silent-write:headless-browser-reap:138` | B56-FIX-02 |
| C1-09 | `/Users/josh/Developer/flywheel/.flywheel/scripts/frozen-pane-detector-fleet.sh:67` | medium | TRUE_INSTANCE | `event_append` writes JSONL events directly. | `dedup_key=silent-write:frozen-pane-detector-fleet:67` | B56-FIX-02 |
| C1-10 | `/Users/josh/Developer/flywheel/.flywheel/scripts/frozen-pane-detector.sh:459`, `:485`, `:501` | high | TRUE_INSTANCE | class strikes, recovery ledger, and metrics lines are appended directly. | `dedup_key=silent-write:frozen-pane-detector:459` | B56-FIX-02, B56-FIX-05 |
| C1-11 | `/Users/josh/Developer/flywheel/.flywheel/scripts/ntm-fleet-health.sh:48`, `:66`, `:93` | high | TRUE_INSTANCE | health log/error/summary JSONL appends have no readback validation. | `dedup_key=silent-write:ntm-fleet-health:48` | B56-FIX-02, B56-FIX-06 |
| C1-12 | `/Users/josh/Developer/flywheel/.flywheel/scripts/mobile-eats-loop-with-receipt-mirror.sh:20`, `:25` | medium | TRUE_INSTANCE | loop receipt mirror appends success/error rows without validation. | `dedup_key=silent-write:mobile-eats-loop-with-receipt-mirror:20` | B56-FIX-02 |
| C1-13 | `/Users/josh/Developer/flywheel/.flywheel/scripts/storage-probe.sh:254`, `:255` | medium | DEFERRED | history append/rewrite is optional, but append is not protected by a shared validated JSONL primitive. | `dedup_key=silent-write:storage-probe:254` | B56-FIX-02 |
| C1-14 | `/Users/josh/.claude/skills/.flywheel/scripts/kill-recover-drill.sh:106` | medium | DEFERRED | drill logger appends directly; blast radius lower because it is a drill script, but the pattern is the same. | `dedup_key=silent-write:kill-recover-drill:106` | B56-FIX-10 |

## Findings - Class 2 (Destructive-Default)

Definition: destructive or externally mutating action can fire without dry-run
default and explicit `--apply` or equivalent dangerous-action gate.

Breakdown: total=9, critical=2, high=5, medium=2, low=0.

| finding_id | file:line | severity | classification | evidence | L110 row example | proposed_fix_bead |
|---|---|---:|---|---|---|---|
| C2-01 | `/Users/josh/.local/bin/flywheel-watchers.bak.20260505T005651Z:183`, `:324`, `:330`, `:401` | critical | TRUE_INSTANCE | backup still contains immediate `launchctl bootout`, `mv -f`, and `kill -9` under `--kill-unregistered`; no `--apply` parser. | `dedup_key=destructive-default:flywheel-watchers-bak:324` | B56-FIX-01 |
| C2-02 | `/tmp/.disabled-watchers/idle-pane-auto-dispatch.sh:29`, `:56` | high | TRUE_INSTANCE | parked loop runs `br update` and `ntm send` directly; no dry-run/apply contract. | `dedup_key=destructive-default:tmp-idle-pane-auto-dispatch:29` | B56-FIX-04 |
| C2-03 | `/tmp/.disabled-watchers/idle-pane-auto-dispatch-generic.sh:54`, `:126` | high | TRUE_INSTANCE | generic parked loop mutates bead state and sends panes directly. | `dedup_key=destructive-default:tmp-idle-pane-auto-dispatch-generic:54` | B56-FIX-04 |
| C2-04 | `/tmp/.disabled-watchers/storage-cleared-watcher.sh:25`, `:26` | critical | TRUE_INSTANCE | Docker image and builder prune run with `--force` and no explicit apply gate. | `dedup_key=destructive-default:tmp-storage-cleared-watcher:25` | B56-FIX-04 |
| C2-05 | `/tmp/.disabled-watchers/jeff-corpus-watcher.sh:9`, `:10` | medium | TRUE_INSTANCE | watcher sends panes directly every loop; no dry-run/apply surface. | `dedup_key=destructive-default:tmp-jeff-corpus-watcher:9` | B56-FIX-04 |
| C2-06 | `/Users/josh/Developer/flywheel/.flywheel/scripts/frozen-pane-detector.sh:731`, `:754`, `:762` | high | TRUE_INSTANCE | `--auto-recover` can hard-restart a pane; dry-run is optional and there is no `--apply` flag. | `dedup_key=destructive-default:frozen-pane-detector:754` | B56-FIX-05 |
| C2-07 | `/Users/josh/Developer/flywheel/.flywheel/scripts/ntm-fleet-health.sh:81` | high | TRUE_INSTANCE | script calls `ntm health --auto-restart-stuck` without local dry-run/apply gating. | `dedup_key=destructive-default:ntm-fleet-health:81` | B56-FIX-06 |
| C2-08 | `/Users/josh/.claude/skills/.flywheel/scripts/kill-recover-drill.sh:547`, `:576`, `:609`, `:787` | high | TRUE_INSTANCE | drill can send interrupts, `kill -STOP`, and force respawn; usage examples do not make dry-run the default safety posture. | `dedup_key=destructive-default:kill-recover-drill:576` | B56-FIX-10 |
| C2-09 | `/Users/josh/Developer/flywheel/.flywheel/scripts/mobile-eats-loop-with-receipt-mirror.sh:15`, `:17` | medium | DEFERRED | scheduled loop invokes product tick and writes mirror output with no dry-run/apply surface; treat as lower risk because it is a loop driver, not an ad-hoc ops CLI. | `dedup_key=destructive-default:mobile-eats-loop-with-receipt-mirror:15` | B56-FIX-09 |

## Findings - Class 3 (Unregistered-Process)

Definition: runtime process, LaunchAgent, watcher, or background-script surface is
not represented in the registry that operators use as source of truth.

Breakdown: total=11, critical=0, high=9, medium=1, low=1.

| finding_id | file:line or command | severity | classification | evidence | L110 row example | proposed_fix_bead |
|---|---|---:|---|---|---|---|
| C3-01 | command: `PlistBuddy ... ai.zeststream.alps-idle-pane-watch.plist` | high | TRUE_INSTANCE | ProgramArguments include `idle-pane-auto-dispatch.sh --session=alpsinsurance --apply --json`; registry query for the eight flywheel labels returned `0`. | `dedup_key=unregistered-process:ai.zeststream.alps-idle-pane-watch` | B56-FIX-07 |
| C3-02 | command: `PlistBuddy ... ai.zeststream.mobile-eats-idle-pane-watch.plist` | high | TRUE_INSTANCE | ProgramArguments include `idle-pane-auto-dispatch.sh --session=mobile-eats --apply --json`; registry query returned `0`. | `dedup_key=unregistered-process:ai.zeststream.mobile-eats-idle-pane-watch` | B56-FIX-07 |
| C3-03 | command: `PlistBuddy ... ai.zeststream.skillos-idle-pane-watch.plist` | high | TRUE_INSTANCE | ProgramArguments include `idle-pane-auto-dispatch.sh --session=skillos --apply --json`; registry query returned `0`. | `dedup_key=unregistered-process:ai.zeststream.skillos-idle-pane-watch` | B56-FIX-07 |
| C3-04 | command: `PlistBuddy ... ai.zeststream.vrtx-idle-pane-watch.plist` | high | TRUE_INSTANCE | ProgramArguments include `idle-pane-auto-dispatch.sh --session=vrtx --apply --json`; registry query returned `0`. | `dedup_key=unregistered-process:ai.zeststream.vrtx-idle-pane-watch` | B56-FIX-07 |
| C3-05 | command: `PlistBuddy ... com.zeststream.flywheel-idle-pane-watch.plist` | high | TRUE_INSTANCE | ProgramArguments run `/Users/josh/.claude/skills/.flywheel/scripts/idle-drifted-panes.sh`; registry query returned `0`. | `dedup_key=unregistered-process:com.zeststream.flywheel-idle-pane-watch` | B56-FIX-07 |
| C3-06 | command: `PlistBuddy ... ai.zeststream.frozen-pane-detector-fleet.plist` | high | TRUE_INSTANCE | ProgramArguments run `frozen-pane-detector-fleet.sh cycle --json`; registry query returned `0`. | `dedup_key=unregistered-process:ai.zeststream.frozen-pane-detector-fleet` | B56-FIX-07 |
| C3-07 | command: `PlistBuddy ... ai.zeststream.ntm-fleet-health.plist` | high | TRUE_INSTANCE | ProgramArguments run `ntm-fleet-health.sh`; registry query returned `0`. | `dedup_key=unregistered-process:ai.zeststream.ntm-fleet-health` | B56-FIX-07 |
| C3-08 | command: `PlistBuddy ... ai.zeststream.mobile-eats-flywheel-loop.plist` | high | TRUE_INSTANCE | ProgramArguments exec `mobile-eats-loop-with-receipt-mirror.sh`; registry query returned `0`. | `dedup_key=unregistered-process:ai.zeststream.mobile-eats-flywheel-loop` | B56-FIX-07 |
| C3-09 | command: `find /tmp/.disabled-watchers -maxdepth 1 -type f -print \| sort \| wc -l` | high | TRUE_INSTANCE | expected output `6`; active `/tmp` watcher search returned `0`, so these are parked but still represent the same unregistered watcher substrate. | `dedup_key=unregistered-process:tmp-disabled-watchers:6-files` | B56-FIX-04, B56-FIX-08 |
| C3-10 | command: `comm -12 <(launchctl list labels) <(active unregistered plist labels)` | medium | DEFERRED | previous read-only enumeration found 23 loaded labels on disk but absent from plist registry; mostly non-flywheel labels, so this needs policy/allowlist work rather than immediate kill. | `dedup_key=unregistered-process:loaded-unregistered-launchagents:23` | B56-FIX-08 |
| C3-11 | command: `/Users/josh/.local/bin/flywheel-watchers audit-orphans --json` | low | DEFERRED | current read-only output: `"total": 1`, command is Homebrew `sleepwatcher`; likely allowlist candidate rather than trauma instance. | `dedup_key=unregistered-process:sleepwatcher:32355` | B56-FIX-08 |

## False positives and guardrails

These are DIDN'T claims with evidence.

| claim | evidence | classification |
|---|---|---|
| Current B54 `flywheel-watchers` does not retain the destructive default | `/Users/josh/.local/lib/flywheel-watchers/core.sh:49` returns dry-run unless apply is yes; `/Users/josh/.local/lib/flywheel-watchers/ops.sh:108` through `:120` separates read-only/dry-run/applied audit modes. | FALSE_POSITIVE |
| `worker-stall-alert-probe.sh` does not send or write state in default mode | `/Users/josh/Developer/flywheel/.flywheel/scripts/worker-stall-alert-probe.sh:15` and `:16` set `APPLY=0`, `DRY_RUN=1`; sends and writes are inside `if is_candidate and apply` and `if apply` at `:319` and `:347`. | FALSE_POSITIVE |
| `storage-probe.sh` background child does not create an unregistered long-lived process | `/Users/josh/Developer/flywheel/.flywheel/scripts/storage-probe.sh:101` backgrounds `du`, then stores the pid at `:102`, waits at `:103` through `:115`, and kills only that child on timeout at `:113`. | FALSE_POSITIVE |
| `leverage-ceiling-probe.sh` background jobs do not create unregistered long-lived processes | `/Users/josh/Developer/flywheel/.flywheel/scripts/leverage-ceiling-probe.sh:241` backgrounds bounded probes and waits each pid at `:249` through `:264`. | FALSE_POSITIVE |
| The two parked DRAFT scripts do not match destructive/background signatures in the inspected slice | `rg -n --hidden -S '>>\|ntm send\|br update\|kill \|launchctl\|docker .*prune\|&[[:space:]]*(#.*)?$' /tmp/.disabled-watchers/idle-pane-mechanical-gate-DRAFT.sh /tmp/.disabled-watchers/unresolved-dispatch-probe-DRAFT.sh` returned no output. | FALSE_POSITIVE |

## Pairwise Interaction Findings

| pair_id | compound | severity | evidence | fix surface |
|---|---|---:|---|---|
| P1 | Class1 -> Class2: backup watcher can silently write bad/blank registry rows, then destructive audit acts on false "unregistered" state. | critical | C1-01 plus C2-01. Today's kill ledger command shows `72 audit_kill_launchctl` and `1 audit_kill_process`. | B56-FIX-01, B56-FIX-02 |
| P2 | Class3 -> Class2 -> Class1: parked `/tmp` idle watchers are unregistered loops that mutate beads/panes and append logs directly. | critical | C1-03/C1-04 plus C2-02/C2-03 plus C3-09. | B56-FIX-04 |
| P3 | Class3 -> Class1: registered-source drift hides apply-mode idle watchers whose dispatch-log writes are not readback validated. | high | C1-02 plus C3-01 through C3-04. | B56-FIX-03, B56-FIX-07 |
| P4 | Class3 -> Class2 -> Class1: `ai.zeststream.ntm-fleet-health` is absent from registry, runs auto-restart behavior, and writes unvalidated JSONL. | high | C1-11 plus C2-07 plus C3-07. | B56-FIX-06, B56-FIX-07 |
| P5 | Class2 -> Class1 with partial wrapper mitigation: fleet wrapper calls detector dry-run, but base detector still exposes `--auto-recover` without apply and writes recovery ledgers directly. | high | C1-10 plus C2-06; wrapper mitigation evidence at `/Users/josh/Developer/flywheel/.flywheel/scripts/frozen-pane-detector-fleet.sh:268` through `:275`. | B56-FIX-05 |

## Isomorphism Check

Passed. The single fix primitive is:

1. Canonical mutation boundary: default dry-run; only `--apply` mutates.
2. Canonical durable-write primitive: write temp row, validate non-empty + JSON shape,
   append atomically, read back the just-written row, and fail closed if validation fails.
3. Canonical runtime registry primitive: every LaunchAgent/process/watch loop has a
   registry row before it can be started or considered healthy.

Reference implementation already exists in B54:

- `/Users/josh/.local/lib/flywheel-watchers/core.sh:49` and `:50` define dry-run by default unless `FW_APPLY=yes`.
- `/Users/josh/.local/lib/flywheel-watchers/core.sh:161` through `:164` validate JSON rows.
- `/Users/josh/.local/lib/flywheel-watchers/core.sh:166` through `:187` implement atomic JSONL append with fsync and replace.
- `/Users/josh/.local/lib/flywheel-watchers/registry.sh:32` through `:51` validates before append and logs after successful append.
- `/Users/josh/.local/lib/flywheel-watchers/ops.sh:108` through `:120` separates read-only, dry-run, and applied orphan audit behavior.

The three trauma classes are one control-system failure, not three unrelated bugs:

- Class 1 is invalid stock measurement.
- Class 2 is actuator firing without preview.
- Class 3 is invisible actuator inventory.

The same primitive fixes all three: validated state, gated mutation, registered
actuators.

## Donella Trace

| element | trace |
|---|---|
| Stock | trusted substrate state: plist registry rows, watcher ledgers, dispatch logs, process registry inventory |
| Inflows | register calls, LaunchAgent installs, watcher starts, JSONL appenders, scheduled loop drivers |
| Outflows | unregisters, bootouts, kills, prunes, pane restarts, parked watcher removals |
| Balancing loop intended | registry -> audit -> preview -> apply -> ledger readback -> registry health |
| Reinforcing failure loop observed | silent bad write -> registry emptiness -> destructive audit -> more missing processes -> ad-hoc watchers -> more unregistered writes |
| Information delay | write success was inferred from command exit, not readback; detection waited until audit interpreted empty registry |
| Leverage point | rules of the system: no mutation without dry-run/apply, no durable write without readback, no runtime actuator outside registry |
| Highest-leverage bead | B56-FIX-09 static scanner, because it prevents new instances of all three classes at commit or dispatch time |

## Proposed Fix-Bead List

No beads were created by this worker. These are proposed beads for the
orchestrator to file.

| proposed_bead | priority | title | body | acceptance | parents |
|---|---:|---|---|---|---|
| B56-FIX-01 | P1 | Remove or quarantine vulnerable watcher backup | Make `.bak` watcher artifacts non-executable or move them outside executable path scanning; add a scanner rule for executable backups under `~/.local/bin/flywheel-*`. | `test ! -x ~/.local/bin/flywheel-watchers.bak.20260505T005651Z`; scanner flags any future executable `.bak` with destructive ops. | WOE-EXP-B56 |
| B56-FIX-02 | P1 | Create shared validated JSONL append primitive | Port B54 `fw_validate_json_row` / atomic append / readback into a reusable shell library and migrate direct JSONL/ledger appends. | `rg '>>.*(jsonl|ledger|state|log)' audited scopes` has only allowlisted temp/test writes or calls to the shared primitive. | WOE-EXP-B56 |
| B56-FIX-03 | P1 | Harden active idle auto-dispatch state writes | Replace cooldown and dispatch-log direct appends with validated write/readback; preserve dry-run default. | dry-run produces no persistent writes; apply writes row and verifies tail/readback. | B56-FIX-02 |
| B56-FIX-04 | P1 | Normalize or delete parked watcher scripts | Either delete archived `/tmp/.disabled-watchers` scripts after extracting lessons or patch them to canonical dry-run/apply/readback before any re-enable. | `find /tmp/.disabled-watchers -type f` is zero or every file passes static scanner. | WOE-EXP-B56 |
| B56-FIX-05 | P1 | Gate frozen-pane auto-recover behind `--apply` | Make `--auto-recover` preview-only unless paired with `--apply`; migrate strike/recovery appends to validated primitive. | `frozen-pane-detector.sh --auto-recover --json` cannot hard restart; `--apply` required. | B56-FIX-02 |
| B56-FIX-06 | P1 | Gate ntm fleet health auto-restart | Wrap `ntm health --auto-restart-stuck` behind local dry-run/apply mode and validated health log writes. | default invocation reports planned restarts only; `--apply` required to restart. | B56-FIX-02 |
| B56-FIX-07 | P1 | Register flywheel-owned LaunchAgents | Add the eight flywheel-owned LaunchAgents to `plist-registry.jsonl` via canonical register path and add a doctor invariant. | registry query for the eight labels returns `8`; doctor fails if any active flywheel plist is missing. | WOE-EXP-B56 |
| B56-FIX-08 | P2 | Add process registry allowlist and orphan policy | Distinguish flywheel-owned watchers from expected third-party/user agents like Homebrew `sleepwatcher`; prevent false kill plans. | `audit-orphans --json` classifies sleepwatcher as allowlisted or external, not unregistered kill candidate. | B56-FIX-07 |
| B56-FIX-09 | P1 | Add B56 trauma-class static scanner | Build a read-only scanner for silent writes, destructive defaults, and unregistered runtime surfaces; run from doctor/CI. | scanner emits JSON rows with class, file, line, severity, and suggested bead; no mutations. | WOE-EXP-B56 |
| B56-FIX-10 | P2 | Convert drill scripts to explicit dangerous-action gates | Require `--apply` or `--dangerous-drill` for kill/recover drills; document fixture-only dry-run examples. | running drill with no apply cannot send interrupts, stop processes, or respawn panes. | B56-FIX-09 |

## Callback Values

Use these values in the canonical DONE envelope:

```text
self_grade=Y
jeff_score=9.6
donella_score=9.6
joshua_score=9.5
composite=9.57
quality_bar_passed=yes
class1_silent_write_findings=14(critical=1,high=6,medium=7,low=0)
class2_destructive_default_findings=9(critical=2,high=5,medium=2,low=0)
class3_unregistered_process_findings=11(critical=0,high=9,medium=1,low=1)
pairwise_compound_findings=5
isomorphism_check_passed=yes
proposed_fix_bead_count=10
l113_compliance=yes
did_claims_with_evidence_count=39
didnt_claims_with_evidence_count=5
evidence_coverage_rate=44/44
```
