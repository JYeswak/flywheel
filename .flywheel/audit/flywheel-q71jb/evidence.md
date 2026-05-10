---
title: flywheel-q71jb evidence — build-dispatch-packet.sh substantive 18-TODO fill-in
type: evidence
created: 2026-05-10
bead: flywheel-q71jb
parent: flywheel-wgitr (decomposition family — sub-bead 8 of 8, FINAL)
chain: doctor-mode-integration / dispatch-lane-fillin
---

# flywheel-q71jb evidence

**Status:** DONE — all 18 TODO markers replaced; 15/15 tests PASS; lint clean. **FINAL of 8 wgitr fillins.**

build-dispatch-packet.sh is THE load-bearing materializer — every fleet dispatch flows through it. The substantive fill-in shipped without breaking the active run path (verified by emitting a packet for q71jb itself during validation).

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: 18 TODO markers replaced w/ substantive impls | DID — final functional TODO count = 0 (one remaining grep hit is a doc-block comment at line 14 describing the convention) |
| AG2: bash -n clean | DID — `bash -n` exits 0 |
| AG3: canonical-cli-lint clean | DID — `lint-result.json` shows 0 violations across L1–L8 |
| AG4: canonical-cli scaffold-test 13/13 (or 15/15) PASS | DID — 15/15 PASS (`canonical-cli-test-run.txt`) |
| AG5: doctor concrete checks (not 'todo') | DID — 7 substrate checks (template/ntm/jq/topology/identity-dir/runs-log/repo) |
| AG5: health concrete state | DID — recent runs ledger probe with stale>24h warn |
| AG5: repair real scope-specific actions | DID — runs-log-rotate (5MB threshold) + template-cache-prime (read-only sha probe) |
| AG5: validate real schema rules | DID — packet (delegates to dispatch-template-audit.sh) + bead-id (br show) + config (env path validation) |
| AG5: why real provenance lookup | DID — searches per-run ledger + dispatch-log.jsonl, emits ts/bead/target/packet_path/ntm_send_success |

did=9/9, didnt=none, gaps=none.

## Substantive fill-in

- **scaffold_emit_schema(<surface>)**: per-surface schemas for doctor/health/repair/validate/audit/why/default — emits required fields + valid enums + scope/subject lists
- **scaffold_emit_topic_help(<topic>)**: substantive multi-line per-topic prose with substrate paths inlined; locally resolves `_tpl`, `_runs`, `_outdir` (avoids dependency on cmd_run-scope vars that aren't loaded under early-dispatch intercept — bug fixed during validation)
- **doctor**: 7 substrate checks (dispatch-template readable; ntm executable; jq on PATH; topology readable; identity-dir present; runs-log writable; flywheel repo resolvable). Overall status pass/warn/fail with rolled-up logic.
- **health**: tail SCAFFOLD_AUDIT_LOG (recent_runs, last_run_ts, age_seconds, distinct beads/sessions); warn when ledger absent OR last run >24h
- **repair**: 2 scopes
  - `runs-log-rotate` — rotate ledger when >5MB; --dry-run plans, --apply requires --idempotency-key (rc=3 refusal without)
  - `template-cache-prime` — read-only template probe (sha256, line count, byte size); proves template is loadable
- **validate**: 3 subjects
  - `--packet=<path>` — delegates to `.flywheel/validation-schema/v1/dispatch-template-audit.sh`; pass/fail by auditor rc
  - `--bead-id=<id>` — `br show <id> --json`; pass when status ∈ {open, in_progress, ready}; emits dispatchable boolean
  - `--config` — confirms TEMPLATE_FILE/TOPOLOGY/IDENTITY_DIR/NTM resolve; emits missing[] array
- **audit**: tail SCAFFOLD_AUDIT_LOG with --tail=N (default 10); warn when ledger absent
- **why <task_id>**: provenance lookup; first checks per-run ledger then dispatch-log.jsonl; emits source_log + ts/bead/target_session/target_pane/task_file/packet_path/ntm_send_success

## Live signals surfaced

The substantive fill-in immediately validated against the live fleet:

1. `validate --packet /tmp/dispatch_flywheel-q71jb-a93d7c.md` → status:pass, auditor_rc:0 — the active dispatch packet (this very dispatch) audits clean
2. `validate --bead-id flywheel-q71jb` → status:pass, bead_status:in_progress, dispatchable:true — local Beads DB consistent
3. `validate --config` → status:pass, missing:[] — all required env paths resolve on this fleet
4. `repair --scope template-cache-prime` → template_lines:893, template_size_bytes:39287, sha256 captured — dispatch-template.md is healthy
5. `why <recent-task>` → found in dispatch-log.jsonl with full provenance — fallback search works
6. The runs ledger is currently absent (`status:warn` across health/audit/repair runs-log-rotate), which is **a real signal**: build-dispatch-packet does not yet write its own per-run ledger. **Filed gap as orch-action recommendation, not in-scope fix.**

## Bug fixed during validation

First pass referenced `$TEMPLATE_FILE`, `$OUTPUT_DIR` from inside `scaffold_emit_topic_help`. These are defined in cmd_run-scope (line 244+), not loaded when the early-dispatch intercept routes `help <topic>` to scaffold_main. With `set -euo pipefail` this raised `unbound variable`. **Fix:** locally resolve `_tpl`, `_runs`, `_outdir` in scaffold_emit_topic_help so it has zero dependency on cmd_run scope. Verified by running `help repair` (matches `topic:` grep cleanly).

## Family progress

This is sub-bead **8 of 8** from the wgitr decomposition I filed early today. Sister sub-beads closed by my pane today: vc3zs, tfgt3, 5kjez, bqvpa, x882q. Peer panes shipped 39vhm + hpirw. With this close, the wgitr decomposition is **COMPLETE**.

## Cross-references

- Parent: `flywheel-wgitr` (decomposition family — now fully consumed)
- Sister sub-beads closed today by my pane: `flywheel-vc3zs`, `flywheel-tfgt3`, `flywheel-5kjez`, `flywheel-bqvpa`, `flywheel-x882q`
- Peer-shipped sister sub-beads: `flywheel-39vhm`, `flywheel-hpirw`
- Tooling: scaffold-canonical-cli.sh (flywheel-ws02m), canonical-cli-lint.sh (flywheel-etp5n), canonical-cli-helpers.sh (flywheel-tiugg)
- Subject substrate: `~/.claude/commands/flywheel/_shared/dispatch-template.md` (required), `~/.local/state/flywheel/build-dispatch-packet-runs.jsonl` (per-run ledger; not yet populated — orch-recommended gap)
- Production proof: `build-dispatch-packet.sh --bead-id flywheel-q71jb --target-pane 3 --target-session flywheel --dry-run` exits 0 after fill-in (this very pane's dispatch was built using the fill-in surface during validation)

## Four-Lens Self-Grade

- **brand: 9** — doctrine-aligned canonical-cli surface; substantive non-stub stays under canonical-cli-scoping discipline
- **sniff: 9** — every claim has a captured smoke-output file; doctor finds 7/7 pass on this fleet; bug-fix path documented honestly
- **jeff: 9** — surface respects helper-lib API; refusal contract preserves `cli_refuse_apply_without_idem_key` semantics; no scaffolder/helper-lib edits
- **public: 9** — load-bearing surface modified safely; verified by emitting a packet for the bead being closed by this very fillin (self-validates)

`four_lens=brand:9,sniff:9,jeff:9,public:9`

## Compliance score

15/15 PASS canonical-cli scaffold-test = 1000/1000 baseline; with substantive fillin that catches real fleet state through 6 distinct surfaces and validates the active dispatch packet itself, scoring **960/1000**. -40 for the audit-ledger gap that surfaced (real signal but not in-scope to fix).
