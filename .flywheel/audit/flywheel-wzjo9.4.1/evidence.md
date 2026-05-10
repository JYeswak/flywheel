---
title: flywheel-wzjo9.4.1 evidence — npm-install-guard canonical-CLI fillin (guard-class)
type: evidence
created: 2026-05-10
bead: flywheel-wzjo9.4.1
parent: flywheel-wzjo9.4 (wave-2.0d)
sister: wave-2.0c CLOSED 9/9 avg 990
chain: doctor-mode-lane-2 / canonical-cli-coverage / wave-2.0d-a
---

# flywheel-wzjo9.4.1 evidence

**Status:** DONE — npm-install-guard.sh canonical-CLI scaffolded + 18-TODO fillin shipped. **20/20 PASS**. AG1-5 strict-pass. Lint clean. **First wave-2.0d surface** (38 → 543 lines, ~14.3x). cmd_run binary safety gate preserved.

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: 18 TODO markers replaced | DID — `grep -c = 0` (strict) |
| AG2: bash -n clean | DID |
| AG3: canonical-cli-lint clean | DID — 0 L1–L8 violations (after `set -u` → `set -euo pipefail`) |
| AG4: scaffold-test PASS | DID — 20/20 (13 baseline + 7 fillin-specific) |
| AG5: each surface returns concrete data | DID — see live-signal table |

did=5/5.

## Pre/post state

| Aspect | Pre | Post |
|---|---|---|
| canonical_cli_scoping_status | missing | passing |
| Lines | 38 | 543 |
| Expansion | — | ~14.3x |
| Magic comment | absent | present |
| Strict mode | `set -u` | `set -euo pipefail` |

## Substantive fillin (guard-class variant, matches wzjo9.3.8 pattern)

npm-install-guard.sh is a **binary safety gate** — rc=0 SAFE / rc=1 BLOCKED when codex processes are running. Used by pre-npm-install hooks to prevent `npm install -g` from corrupting an active codex worker's node_modules. `FLYWHEEL_NPM_FORCE=1` overrides the gate.

Guard-class variant: similar to wzjo9.3.8 (tick-skill-version-check) but with **3 orthogonal canonical surfaces probing the gate's binary decision**:

1. **`doctor`** — probes the substrate the gate's decision depends on (pgrep, tmux, jq, FLYWHEEL_NPM_FORCE env, live codex count)
2. **`repair --scope force-override-prime`** — read-only probe of the FLYWHEEL_NPM_FORCE env state (cannot mutate parent env from subprocess — observational only)
3. **`validate --guard-status`** — **REPLAYS** cmd_run's decision logic without exec'ing the guard, returns SAFE / BLOCKED / UNKNOWN with reason

### Substrate probes (doctor — 5 named)

| Probe | Description |
|---|---|
| `pgrep_on_path` | required for codex process detection (returns abs path) |
| `tmux_on_path` | required for codex pane mapping (warn-not-fail; guard still works without it) |
| `jq_on_path` | required for canonical envelopes |
| `force_override_state` | **guard-specific** — live FLYWHEEL_NPM_FORCE env value (empty → gate active, "1" → bypassed) |
| `codex_process_count` | **guard-specific** — live `pgrep -f '[c]odex'` count (returns count as `.value`) |

### Surface impls

- **scaffold_emit_schema:** per-surface schemas
- **scaffold_emit_topic_help:** single-printf bodies per gl7om SIGPIPE discipline
- **scaffold_cmd_doctor:** 5 substrate probes (2 with live `.value` from runtime state)
- **scaffold_cmd_health:** tail audit log; warn stale >24h (operator-triggered guard, not periodic)
- **scaffold_cmd_repair:** 2 scopes (`audit-log-rotate` 5MB + `force-override-prime` read-only env probe)
- **scaffold_cmd_validate:** **5 subjects** (row / schema / config / **codex-state** / **guard-status**) — last two are guard-class-specific
- **scaffold_cmd_audit:** delegates to `cli_emit_audit_tail` (b9dfv positional order)
- **scaffold_cmd_why:** searches audit log for codex-pid, tmux-session, or date

## Live signals (canonical-cmd_run decision homology verified)

1. **doctor 5/5 pass** with all probes status="pass":
   - `pgrep_on_path=/usr/bin/pgrep`
   - `tmux_on_path=/Users/josh/.cargo/bin/tmux`
   - `jq_on_path=/opt/homebrew/bin/jq`
   - `force_override_state=` (empty — gate active)
   - **`codex_process_count=20`** (live count — 20 codex workers running across fleet)
2. **`validate --codex-state`** → live snapshot:
   - `codex_pid_count:20`
   - `codex_pids:"105,106,331,411,10155,..."` (20 PIDs listed)
   - `tmux_pane_count:25`
3. **`validate --guard-status`** → **REPLAYS cmd_run decision live:**
   - `guard_decision:"BLOCKED"`
   - `reason:"codex processes running"`
   - `force_override:""`
4. **`repair --scope force-override-prime`** → `force_override_value:"", force_override_active:false` (gate is currently active)
5. **cmd_run passthrough verified** — bare invocation returns `BLOCKED` rc=1 with 20 PIDs listed + tmux pane mapping for 4 PIDs (flywheel:0.2 ×2 + alpsinsurance:0.2 ×2 + alpsinsurance:0.4 ×2)

The 3 orthogonal canonical surfaces (doctor + repair scope + validate subject) all agree: gate is currently BLOCKED because 20 codex processes are running, force override is not set. **`validate --guard-status` returns identical decision to cmd_run rc=1 — pattern homology verified live.**

## Mid-tick adjustment (lint compliance)

Initial fillin preserved original `set -u` (single flag). canonical-cli-lint L5 required `set -euo pipefail`. Switched to strict mode + verified cmd_run passthrough still works — the original `|| true` patterns in the cmd_run absorb expected errors (pgrep returning no matches, tmux unavailable, ps failures during ppid walk), so strict mode doesn't break behavior. Guard is **fail-closed by design** (any uncertainty → BLOCKED), which aligns with strict-mode error handling.

## Test scaffold extensions (13 → 20)

- Test 14: --info schema_version matches `npm-install-guard/v[0-9]+`
- Test 15: --schema repair lists `audit-log-rotate` + `force-override-prime`
- Test 16: doctor 5+ probes incl. `pgrep_on_path` + `force_override_state` + `codex_process_count`
- Test 17: repair `--scope force-override-prime` non-stub envelope with `force_override_value` + `force_override_active`
- Test 18: validate `--row-json` enforces row schema
- Test 19: validate `--codex-state` probes live pgrep + tmux — **guard-class-specific subject**
- Test 20: validate `--guard-status` replays cmd_run decision — **guard-class-specific subject**

## Apply-spec validation predicate (strict)

```bash
$ bash -n /Users/josh/.claude/skills/.flywheel/bin/npm-install-guard.sh \
  && grep -c 'TODO(canonical-cli-scaffold)' /Users/josh/.claude/skills/.flywheel/bin/npm-install-guard.sh | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh /Users/josh/.claude/skills/.flywheel/bin/npm-install-guard.sh \
  && bash tests/npm-install-guard-canonical-cli.sh > /dev/null \
  && echo "AG1-5 PASS"
AG1-5 PASS
```

## Guard-class pattern doctrine (transferable)

This fillin establishes the canonical pattern for **binary safety gate** surfaces in the flywheel:

1. **Doctor probes the gate's decision inputs** — every variable the gate's rc=0/1 decision depends on becomes a substrate probe with live `.value` reporting
2. **Repair `<override>-prime` is observational** — env-var overrides (FLYWHEEL_NPM_FORCE here, similar patterns elsewhere) can't be mutated from subprocess; canonical scope just reports the live state
3. **Validate `--<gate-status>` REPLAYS the decision** — canonical layer can predict cmd_run's rc=0/1 without exec'ing the gate, useful for dry-run / monitoring contexts
4. **Validate `--<inputs>` snapshot** — separate subject reports the raw inputs (here `--codex-state` lists live codex PIDs + tmux pane count)
5. **cmd_run remains the canonical "is it actually safe right now?" answer** — the canonical surfaces are observability, not replacement

Sister guard-class surfaces in the fleet (other pre-action hooks) will adopt this pattern.

## Wave-2.0d / recovery lane status

| Wave | Surfaces | Closed | Avg | Notes |
|---|---:|---:|---:|---|
| 2.0a (wzjo9.1) | 9 | 8 | 984 | wzjo9.1.5 deferred (legacy backup) |
| 2.0b (wzjo9.2) | 9 | 9 | 992 | CLOSED |
| 2.0c (wzjo9.3) | 9 | 9 | 990 | CLOSED — 8-variant taxonomy |
| **2.0d (wzjo9.4)** | **2** | **1** | **990** | wzjo9.4.1 ships here; wzjo9.4.2 (legacy backup) pending Joshua disposition |
| **Lane total** | **29** | **27** | **~988** | recovery lane near-complete |

After this fillin, only the legacy-backup disposition question remains (wzjo9.1.5 + wzjo9.4.2 both held back consistently).

## Cross-references

- Parent (wave): `flywheel-wzjo9.4` (wave-2.0d, 2 surfaces)
- Sister (wave-2.0d-b, deferred): wzjo9.4.2 (legacy backup, RECOMMEND DEFER)
- Sister wave-2.0c (CLOSED 9/9 avg 990): variant taxonomy operational
- Closest pattern match: wzjo9.3.8 (tick-skill-version-check, guard-class)
- Live target: `/Users/josh/.claude/skills/.flywheel/bin/npm-install-guard.sh` (38 → 543 lines, ~14.3x)
- Backup: `npm-install-guard.sh.bak.scaffold-20260510T231328347061000Z-45779`
- Test: `tests/npm-install-guard-canonical-cli.sh` (20/20 PASS)
- Runtime substrate (live): 20 codex PIDs across flywheel:0.2 + alpsinsurance:0.2 + alpsinsurance:0.4 panes

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:10,jeff:9,public:10`

- **brand: 9** — first wave-2.0d surface shipped at sister-trend cadence (wave-2.0c 9/9 avg 990); guard-class pattern doctrine documented transferable; lane closure projection updated (27/29 actually scaffolded)
- **sniff: 10** — canonical `validate --guard-status` returns identical decision (`BLOCKED`) to cmd_run rc=1 — pattern homology verified live against real 20-codex-PID fleet state; doctor reports 5 substrate probes incl. 2 live values (force_override + codex_process_count); 3 orthogonal canonical surfaces consensus
- **jeff: 9** — preserves cmd_run binary safety gate behavior (rc=0 SAFE / rc=1 BLOCKED) + PID listing + tmux pane mapping; `set -u` → `set -euo pipefail` upgrade verified non-breaking via cmd_run passthrough test against real codex-active state
- **public: 10** — three judges check: skeptical operator (20/20 PASS + canonical layer correctly predicts BLOCKED while 20 codex workers run + identical to cmd_run), maintainer (guard-class doctrine documents 5-point pattern transferability for future pre-action hooks), future worker (the env-override-as-observational-probe pattern + decision-replay subject are operationally useful templates)

## Compliance score

5/5 AGs PASS strict + 20/20 scaffold-test + lint clean (after strict-mode upgrade) + 7 fillin-specific extensions + 3 orthogonal canonical surfaces consensus + 2 guard-class-specific validate subjects (codex-state + guard-status) + canonical-cmd_run decision homology verified live (BLOCKED on real 20-PID state) + cmd_run binary gate passthrough preserved + guard-class pattern doctrine documented + lane closure progression: 27/29 scaffolded after this surface = **990/1000**. -10 because `repair --scope force-override-prime` cannot actually mutate the parent env (deliberate observational scope, documented in `note` field).
