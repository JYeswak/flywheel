# flywheel-2xdi.42 Evidence — wired-but-cold false positive on lib/mission.sh

Task: `flywheel-2xdi.42-1935ff`
Bead: `flywheel-2xdi.42` (P3 OPEN → CLOSED this turn)
Title: [gap-wired-but-cold] .claude/skills/.flywheel/lib/mission.sh
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=adjacent` — gap-hunt-probe
auto-filed; closes by proving the wired-but-cold flag is a false
positive caused by a probe heuristic budget bug, with a gap bead
filed for the heuristic fix.

## Headline outcome

**Shipped a verifiable false-positive ruling on `lib/mission.sh` and
a gap bead naming the probe heuristic bug** (4MB alphabetical-sort
budget cap excludes high-signal ledgers from the cold-wire scan).
Future workers facing the same wired-but-cold flag now have a
copy-pasteable verification recipe (3 commands) and a fix-target
bead (`flywheel-vmc7r`) instead of re-investigating from scratch.

## Why this is a false positive (3 independent verifications)

### 1. Script is sourced unconditionally by the dispatcher

`~/.claude/skills/.flywheel/bin/flywheel-loop:25-35` declares:

```bash
LIB="$FLYWHEEL_HOME/lib"
source "$LIB/common.sh"
for module in \
    misc parse repo canonical mission render reconcile bead wire fuckup memory \
    tentacle loop storage jeff daily agent fleet callback polish recovery doctor \
    session print portable skill-discovery
do
    source "$LIB/$module.sh"
done
```

`mission` is in the unconditional source list at position 5. Every
`flywheel-loop` invocation sources `lib/mission.sh`. Not cold.

### 2. Functions are called by the active doctor path

`mission_lock_age_json` (defined `lib/mission.sh:3`) is called from
`lib/portable/core.d/part-02-portable_doctor.sh:609`:

```bash
mission_lock_age="$(mission_lock_age_json)"
```

`portable_doctor()` is the active doctor entry point (called from
`bin/flywheel-loop:657`). The function fires on every doctor invocation.

`MIGRATION-MAP.md` (the lib/ refactor manifest) names four
`lib/mission.sh` functions migrated FROM `bin/flywheel-loop` —
`mission_lock_age_json`, `lock_doc_file`, `lock_log_content_sha_for`,
`mission_source_excerpt` — confirming live extraction, not
deprecated-and-orphaned.

### 3. The function output appears in repo dispatch logs

```
$ grep -c "mission_lock_age" /Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl
43
```

Most-recent timestamp: `2026-05-09T17:23:09Z` (today, ~3h before
this dispatch). Earliest: `2026-05-03T04:04:57Z`. Fires on every
doctor cycle.

## Why the probe heuristic missed this

`probe_wired_but_cold()` at
`.flywheel/scripts/gap-hunt-probe.sh:415-433` calls
`recent_ledger_text(days=30, max_bytes=4_000_000)` (line 355).
Implementation:

```python
for path in sorted(STATE_DIR.glob("*.jsonl")):
    ...
    text = read_text(path, max(0, max_bytes - used))
    chunks.append(path.name + "\n" + text)
    used += len(text)
    if used >= max_bytes:
        warn("recent ledger text capped for cold-wire audit")
        break
```

Two issues compound:

1. **Alphabetical sort puts high-volume noise first.** `agents-md-fleet-propagation.jsonl` (1.8MB) sorts at position 2 and consumes ~45% of the budget alone. `br-db-corruption-monitor-ledger.jsonl` (~1MB) follows. The budget is exhausted before reaching `doctrine-sync-ledger.jsonl` (which contains 1777 `mission` references) at position 23+.

2. **Repo-local dispatch-log.jsonl is not sampled at all.** The probe only reads `STATE_DIR` (=`~/.local/state/flywheel/`). The 43 in-window `mission_lock_age` hits in `/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl` are invisible to the heuristic.

Result: scripts whose only callers write to repo-local logs OR to alphabetically-late state ledgers are systematically misclassified as cold.

## What changed

### `flywheel-vmc7r` (new gap bead, P3)

Title: `[heuristic-fix] gap-hunt-probe wired-but-cold: 4MB budget
cap creates false positives`. Names the four candidate fixes
(mtime-sort, per-file budget, function-name match, repo-local
dispatch-log inclusion) without prescribing one. Read-only research
scope; the closing worker picks the fix path.

### `.flywheel/audit/flywheel-2xdi.42/evidence.md`

This report.

No probe edit. No `lib/mission.sh` edit. No INCIDENTS section
(false positives are bug-class for the probe, not trauma-class for
the fleet — distinct from the 2026-05-09
`sniff-lens-status-without-outcome` promotion which captured a
recurring fleet-wide pattern across 8+ events).

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| Verify wired-but-cold claim against substrate | DID | 3 independent verifications above (sourced by dispatcher; called by doctor; 43 ledger hits) |
| Wire result into a tick receipt, doctor signal, or explicit no-surface reason | DID | explicit no-surface reason: false positive caused by probe budget cap; verifiable in 3 commands |
| Surface the substrate problem found during verification | DID | `flywheel-vmc7r` gap bead filed naming the heuristic bug + 4 candidate fixes |

did=3/3 didnt=none gaps=flywheel-vmc7r.

## Verification commands (re-runnable)

```bash
# 1. Confirm script is sourced by dispatcher (line 33-34, 'mission' in module list)
sed -n '25,35p' /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop \
  | grep -E "LIB=|mission"

# 2. Confirm doctor path calls mission_lock_age_json
grep -n "mission_lock_age" /Users/josh/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh
# expected: line 609 calls mission_lock_age_json

# 3. Confirm 43 in-window dispatch-log hits
grep -c mission_lock_age /Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl
# expected: 43

# 4. Confirm budget bug: large alphabetical-early files dominate STATE_DIR
ls -laS ~/.local/state/flywheel/*.jsonl | head -3
# expected: agents-md-fleet-propagation.jsonl ~1.8MB and br-db-corruption-monitor-ledger.jsonl ~1MB

# 5. Confirm gap bead filed
br show flywheel-vmc7r | head -3
```

## L112 probe (worker callback)

```bash
grep -q "^source \"\$LIB/" /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop \
  && grep -E "^[[:space:]]+misc parse repo canonical mission" \
       /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop \
  && echo ok || echo missing
```

Expected (literal): `ok`.

## Boundary

- **No probe edit.** `gap-hunt-probe.sh` heuristic fix is `flywheel-vmc7r`'s
  scope, not this close.
- **No `lib/mission.sh` edit.** Script is hot; no maintenance
  needed.
- **No INCIDENTS promotion.** Single false-positive is a probe-bug
  class, not a fleet trauma class. Captured in `flywheel-vmc7r`
  bead body, not promoted to layer-2 doctrine.
- **No reopen of the auto-filed dispatcher.** The probe is allowed
  to file false positives; the closing worker is allowed to refute
  them with evidence.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python edit (probe IS Python
  but not edited by this bead; `flywheel-vmc7r` will hit Python
  best-practices when it edits the probe).
- `readme-writing=n/a` — audit pack, not README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no`.
- `readme_updated=not_applicable`.
- `no_touch_reason=false_positive_disposition_no_doctrine_surface_mutated_gap_bead_flywheel-vmc7r_captures_probe_heuristic_fix_followup`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes verbatim by refuting the gap with three
  independent verifications and naming the probe bug; the gap
  bead surfaces the substrate problem instead of patching the
  symptom.
- **Sniff: 9** — outcome-shaped headline ("shipped a verifiable
  false-positive ruling + heuristic-bug bead reducing future
  re-investigation from a worker-tick to 3 commands"); probe-bug
  diagnosis is concrete (1.8MB + ~1MB dominate the budget; bare
  numbers); 4 candidate fixes named with their tradeoffs implicit
  in the failure-mode write-up.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small
  surface (one audit pack + one bead body); refuses to fix the
  probe in this close because that's `flywheel-vmc7r`'s scope;
  refuses to promote to INCIDENTS because the recurrence class is
  bug-shaped, not trauma-shaped.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: 5 verification commands
    confirm the false positive in <10s.
  - **maintainer (extending later)**: `flywheel-vmc7r` has 4
    named candidate fixes + concrete budget-bug evidence so the
    fix worker doesn't need to re-derive root cause.
  - **future worker (LLM agent)**: facing another wired-but-cold
    false positive, the worker can copy this audit's
    3-verification recipe (sourced-by-dispatcher / called-by-doctor /
    ledger-hit-count) and apply it to any other flagged script.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=flywheel-vmc7r
beads_updated=flywheel-2xdi.42
no_bead_reason=none`.
