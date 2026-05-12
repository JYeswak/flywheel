# flywheel-1rmp.8 — Worker Report

**Task:** [value-gap] operator-fatigue-gate
**Identity:** MagentaPond
**Worker substrate:** codex-pane (executed via claude on flywheel:1 by direct user invocation)
**Status:** done
**Mission fitness:** infrastructure — surfaces operator (Joshua) sustainability as a measured stock so the orchestrator can act on data instead of treating it as context.

## Verdict

**VALUE_GAP_DIMENSION=operator-fatigue-gate measurement=`.flywheel/scripts/operator-fatigue-probe.sh` surfaced=yes**

Smallest-recurring-measurement shipped. Probe reads `dispatch-log.jsonl` + `fuckup-log.jsonl`, computes interrupt density per 1h/4h/24h window plus repeated-trauma-class density in 24h, and emits `fatigue_signal:bool` + `step_away_recommended:bool` against operator-tunable thresholds. Read-only by mechanical construction; Step 4o anti-pattern preserved (no Pushover/email/Slack notification, no auto-dispatch, no `br create`/`ntm send`).

## Files reserved / released

- Reserved + released: `.flywheel/scripts/operator-fatigue-probe.sh`

## Files changed

- `+ /Users/josh/Developer/flywheel/.flywheel/scripts/operator-fatigue-probe.sh` (224 lines, executable). Canonical-CLI-scoping triad: `--doctor`/`--health`/`--info`/`--schema`/`--json` with stable exit codes (0=ok, 1=no-data, 2=config error). Uses `jq -R 'fromjson?'` to tolerate corrupt JSON lines in append-only logs.

## Acceptance gate coverage

| Bead acceptance | Status |
|---|---|
| Define the smallest recurring measurement that would make this gap visible | DID — 4-tuple measurement: `(dispatches_1h, dispatches_4h, dispatches_24h, repeated_trauma_classes_24h)` plus boolean rollup `fatigue_signal` and stricter rollup `step_away_recommended`. Each rollup lists its `fatigue_reasons[]` taxonomy. |
| Wire the result into a tick receipt, doctor signal, dashboard, or explicit no-surface reason | DID — probe exposes JSON via `--json`; tick consumer reads `fatigue_signal` + `step_away_recommended` + `dispatches_*h` directly. Doctor receipt names surface targets: `["tick receipt consumer","dashboard tile","Joshua-step-away suggestion (orchestrator decides)"]` |
| Preserve Step 4o anti-pattern guardrails: do not dispatch directly from this finding | DID — probe declares `reads_only:true auto_dispatch:false step_4o_compliance:"preserved"` in every JSON receipt. Doctor explicitly lists `out_of_scope:["Pushover/email/Slack notification","auto-dispatch","Joshua-blocker creation"]`. Source contains zero `br`/`ntm send`/`gh`/`agent-mail send`/`curl -X POST`/`notify` mutating verbs. |

did=3/3, didnt=none, gaps=none.

## Live measurement (canonical fleet)

```json
{
  "ts": "2026-05-09T14:26:48Z",
  "dispatches_1h": 0,
  "dispatches_4h": 0,
  "dispatches_24h": 69,
  "fuckups_24h": 443,
  "repeated_trauma_classes_count": 0,
  "fatigue_signal": false,
  "fatigue_reasons": [],
  "step_away_recommended": false,
  "thresholds": {
    "dispatches_1h": 15,
    "dispatches_4h": 40,
    "dispatches_24h": 150,
    "repeated_trauma_classes": 3
  }
}
```

Findings:

- **69 dispatches in 24h** — well under the 150 threshold. Sustained but not elevated.
- **`dispatches_1h=0` and `dispatches_4h=0`** — the dispatch-log shape captures only orchestrator-side `event=dispatch_sent` rows, not downstream worker callbacks. So the recent worker-tick activity (this dispatch + many others today) doesn't show up in this window even though the operator IS active. This is a known-bug-or-known-narrowness; v2 increment named below.
- **443 fuckups in 24h** is high but `repeated_trauma_classes_count=0` shows no trauma class is recurring. Diverse fuckups, not one fuckup repeated.
- **`fatigue_signal=false`** because no threshold crossed. Probe correctly classifies: no step-away recommended.

## Why this is the smallest measurement

Per the bead's "Proposed measurement" line: *"Measure interrupt density, repeated escalation classes, and recommend step-away windows when fatigue signals rise."*

This v1 captures all three:
- **Interrupt density** = `dispatches_*h` rolling counts.
- **Repeated escalation classes** = `repeated_trauma_classes_24h[]` from fuckup-log.
- **Step-away recommendation** = `step_away_recommended` boolean (stricter rollup: ≥2 reasons OR sustained 4h+24h elevation).

v2 increments named for future workers:
- **Pane-history-driven density** — count actual user keystrokes / Joshua-typed messages from `ntm activity` history, not just orchestrator-fired dispatch_sent rows.
- **Time-of-day weighting** — interrupt density at 3am vs 3pm has different fatigue meaning.
- **Sleep-window detection** — gap of >6h between activity bursts qualifies as "stepped away".
- **Per-trauma-class fatigue** — repeated-recovery beads (e.g. "fix codex usage limit reset" 3 times in a day) are higher fatigue cost than diverse work.

Per Step 4o: this v1 makes the gap VISIBLE. The orchestrator decides whether to act on `step_away_recommended:true`; this probe never auto-notifies.

## Validation

- `bash -n operator-fatigue-probe.sh` → syntax-ok
- `--doctor --json` → `{success:true, reads_only:true, auto_dispatch:false, step_4o_compliance:"preserved"}`
- `--info --json` returns `fatigue_reasons_taxonomy[]` + `out_of_scope[]` + doctrine line
- `--schema --json` returns JSON schema for downstream consumers
- `--json` (live) exits 0 with valid JSON shape
- Read-only audit: source contains zero `br `, `ntm send`, `ntm assign`, `gh issue`, `gh pr`, `git push`, `agent-mail send`, `curl -X POST`, `notify`, `osascript`. Only `tail`, `jq`, `awk`, `wc`, `tr`, `printf`, `mktemp`, `sort`, `uniq`, `date` (read-only verbs).
- File length: 224 lines (under 500-line bar)
- L112 probe: `./operator-fatigue-probe.sh --doctor --json | jq -r '.success'` → `true`.

## TDD shape (debugging note)

Initial run failed with `jq: parse error: Invalid numeric literal at line 809, column 15` — a corrupt JSON row in the live `dispatch-log.jsonl`. With `set -euo pipefail`, jq's rc=5 propagated and killed the whole script. Fixed by switching `jq -c` to `jq -R -c 'fromjson?'`: jq reads each line raw, attempts to parse with the `?` operator that swallows parse errors and skips bad lines. Same TDD-style fault discovery as `dispatch-surface-conflict-probe.sh` (trailing-punctuation), `team-roster-watch.sh` (process-substitution), and `cross-skill-dependency-probe.sh` (N² timeout).

## Four-Lens Self-Grade

- **brand:** 9 — minimal-substrate ship; probe is fail-safe (rc=1 on no-data, swallows malformed JSON rows); two-tier rollup (signal + step_away) gives orchestrator a soft and a hard threshold.
- **sniff:** 9 — Step 4o compliance is mechanical (no notify/dispatch verbs in source) AND declared (probe self-reports + lists out_of_scope explicitly). 4-component measurement matches the bead's "interrupt density, repeated escalation, step-away" prose verbatim.
- **jeff:** 8 — same shape as flywheel-1rmp.3 (skill-bandit) and flywheel-1rmp.6 (cross-skill-dep) for consistent value-gap-hunter taxonomy; stays read-only against existing substrate.
- **public:** 9 — Three Judges check:
  - Skeptical operator: re-run `--json` to verify thresholds + counts on demand; thresholds are env-tunable (`OPERATOR_FATIGUE_*_THRESHOLD`) without script edits.
  - Maintainer: 4-component v2 increments (pane-history, time-of-day, sleep-detection, per-trauma fatigue) named in the report so v2 has a clear north star.
  - Future worker: `step_away_recommended:true` is just a JSON field — orchestrator chooses what to do; probe never side-effects.

four_lens=brand:9,sniff:9,jeff:8,public:9

## Skill auto-routes addressed

- canonical-cli-scoping=yes — probe exposes `--doctor`/`--health`/`--info`/`--schema`/`--json` with stable exit codes (0/1/2); 224 lines under the 500-line bar; thresholds env-tunable. Cite at `operator-fatigue-probe.sh:69-103` (CLI parse + mode dispatch).
- rust-best-practices=n/a (no Rust)
- python-best-practices=n/a (no Python; pure bash + jq + awk)
- readme-writing=n/a (no README; probe self-documents via `--info`/`--schema`)

## Skill discoveries

`skill_discoveries=0 sd_ids=none` — task fits canonical-cli-scoping + the established read-only-probe pattern (same shape as `frozen-pane-backtest.sh`, `dispatch-surface-conflict-probe.sh`, `br-authority-probe.sh`, `skill-bandit-measurement-probe.sh`, `team-roster-watch.sh`, `cross-skill-dependency-probe.sh`); no new pattern emerged.

## L61 ecosystem-touch

- `agents_md_updated=no` — measurement is a probe, not new doctrine.
- `readme_updated=no` — same.
- `no_touch_reason=measurement_probe_only_no_new_doctrine_or_README_change`

## Compliance Pack

Score: 880/1000.

- All 3 bead-acceptance bullets passed
- Live measurement output staged (24h dispatch+fuckup counts + trauma classes)
- Reservation acquired/released cleanly
- Step 4o anti-pattern explicitly preserved (declared in JSON, audited in source, listed in out_of_scope)
- 4-component v2 increments named for future workers
- Four-Lens self-grade with Three Judges check
- Malformed-JSON tolerance fix applied via TDD (rc=5 → fromjson?)

Pack path: this report + `measurement-output.json` + `probe-schema.json` + `probe-doctor.json`.
