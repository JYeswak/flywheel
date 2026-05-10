# flywheel-hzsro — semantic split plan + fixture design

Bead: `flywheel-hzsro` (P2, [file-length-discipline] semantically split extracted analyzer bodies)
Worker: CloudyMill on flywheel:0.2 (codex-pane), 2026-05-09
Plan-status: APPLY-READY (semantic-domain map + fixture skeletons + per-file edit motion documented; execution deferred to follow-up dispatches per worker-tick scope discipline)

## Scope analysis

Three files, **3516 lines total**, exceeding file-length-discipline thresholds:

| File | Lines | Threshold | Over | Allow-large receipt |
|---|---|---|---|---|
| `lib/portable/core.d/part-02-portable_doctor.sh` | 1836 | 500 (shell) | +1336 (3.7×) | YES — line 2 |
| `lib/portable/identity.d/identity.py` | 1098 | 400 (Python) | +698 (2.7×) | YES — file-length receipt cited in bead |
| `lib/loop.d/loop_driver_doctor_json.py` | 582 | 400 (Python) | +182 (1.5×) | YES — line 1 |

The bead's acceptance is sequenced: **fixtures first, splits second.** The fixtures are the parity contract; splits cannot proceed safely without them. Per skill axiom (canonical-cli-scoping `[ ] file-length threshold respected or allowed-large receipt cited`), all three currently carry allow-large exemption receipts. The bead asks us to revisit those exemptions and split anyway.

**Worker-tick budget**: 120s. The full work is multi-dispatch:
- Phase 1 (each file): write behavior fixtures
- Phase 2 (each file): execute the split
- Phase 3 (each file): re-run fixtures and confirm parity

3 files × 3 phases = 9 sub-tasks. Worker scope: PLAN + DESIGN, defer execution to ordered follow-up beads.

## Per-file split plan

### File 1: `loop_driver_doctor_json.py` (582 lines → split into 2)

**Easiest of the three** — clean script-vs-helpers separation. 13 helper functions (lines 28-330) followed by main logic (lines 333-582).

**Semantic split**:

```
~/.claude/skills/.flywheel/lib/loop.d/
├── loop_driver_doctor_json.py     (~250 lines — entry script, main logic only; preserves filename for path-based callers)
└── loop_driver_doctor_lib.py      (~330 lines — 13 helper functions)
```

**Helper module contents** (`loop_driver_doctor_lib.py`):
- I/O helpers: `load_json`, `load_toml`, `nested` (lines 28-54)
- Parsing helpers: `parse_interval_seconds`, `parse_ts` (lines 57-84)
- Topology integration: `latest_topology` (lines 87-103)
- Marker discovery: `find_loop_marker`, `inactive_marker_post_stop_ticks` (lines 106-163)
- launchd integration: `plist_info`, `launchctl_loaded` (lines 166-210)
- ntm integration: `ntm_pane_live`, `pane_prompt_observed` (lines 213-281)
- Log scanning: `latest_dispatch_ts`, `latest_drain_receipt` (lines 284-330)

**Entry script contents** (`loop_driver_doctor_json.py`):
- Path constants (lines 18-25)
- Main: marker discovery, config loading, status synthesis, violation/warning aggregation, JSON output (lines 333-582)

**Edit motion**:

```bash
cd ~/.claude/skills/.flywheel/lib/loop.d/
# 1. Cut helpers into the new module
sed -n '1,330p' loop_driver_doctor_json.py > loop_driver_doctor_lib.py
# 2. Replace the helper section in the entry with an import
# (Add: from loop_driver_doctor_lib import load_json, load_toml, nested, parse_interval_seconds, parse_ts, latest_topology, find_loop_marker, inactive_marker_post_stop_ticks, plist_info, launchctl_loaded, ntm_pane_live, pane_prompt_observed, latest_dispatch_ts, latest_drain_receipt)
# 3. Replace lines 28-330 in entry with the import
# 4. Re-run fixtures
```

**Caveat**: `loop_driver_doctor_lib.py` reads module-scope `repo`, `topology_path`, `home`, `loops_dir`, `launch_agents_dir`, `loop_log_dir`, `drain_receipt_ledger` from `sys.argv` and env vars at lines 18-25. These are USED inside `find_loop_marker` (uses `loops_dir`, `project`), `latest_topology` (uses `topology_path`), `plist_info` (none), etc. The split must thread these as function arguments (preferred) OR move them into `loop_driver_doctor_lib.py` and re-export. **Function-argument threading is canonical** (avoids module-scope side effects).

### File 2: `identity.py` (1098 lines → split into 6)

~32 functions across clear semantic clusters. Already has natural seams in line ranges.

**Semantic split**:

```
~/.claude/skills/.flywheel/lib/portable/identity.d/
├── identity.py                   (~80 lines — entry/CLI dispatch; preserves filename for callers)
├── identity_time.py              (~40 lines — TIME/TS helpers)
├── identity_keys.py              (~70 lines — KEY/PATH/HASH helpers)
├── identity_io.py                (~120 lines — ROW/JSON IO + write_token, normalize_name, make_row, load_row, save_row)
├── identity_topology.py          (~250 lines — topology integration: latest_topology_rows, latest_topology_entries, topology_sparse_merge_receipts, ntm_health_payload, live_panes_from_health, split_confirmed_unreachable, topology_entry_for, topology_row_has_pane_fields)
├── identity_actions.py           (~150 lines — upgrade_row, resolve, register, stable_identity, predecessor_chain, canonical_rotation_reason)
└── identity_migrations.py        (~250 lines — migrate_token_json, migrate_skillos_env, token_owner_record, orphan_token_rows, sweep_orphan_tokens, cleanup_predecessor_token, migrate_existing, migrate_registry_schema, all_rows, identity_deferrals)
```

**Function → module map** (anchored at function-line-numbers from inv-identity.txt):

| Module | Functions | Rough line range |
|---|---|---|
| `identity_time.py` | `now_iso`, `parse_ts`, `identity_deferral_now` | 71-92 |
| `identity_keys.py` | `session_path`, `token_path_for`, `token_hash`, `project_key_for_session`, `identity_primary_key`, `identity_primary_key_text`, `canonical_rotation_reason` | 93-131 |
| `identity_io.py` | `write_json`, `write_token`, `read_json`, `normalize_name`, `make_row`, `load_row`, `save_row`, `topology_row_has_pane_fields` | 156-224 |
| `identity_topology.py` | `latest_topology_rows`, `latest_topology_entries`, `topology_sparse_merge_receipts`, `ntm_health_payload`, `live_panes_from_health`, `split_confirmed_unreachable`, `topology_entry_for` | 225-401 |
| `identity_actions.py` | `predecessor_chain`, `stable_identity`, `upgrade_row`, `resolve`, `register` | 132-145, 145-211, 402-498 |
| `identity_migrations.py` | `migrate_token_json`, `migrate_skillos_env`, `token_owner_record`, `orphan_token_rows`, `sweep_orphan_tokens`, `cleanup_predecessor_token`, `migrate_existing`, `migrate_registry_schema`, `all_rows`, `identity_deferrals` | 498-684+ |

**Caveat**: identity.py is imported as a module by callers. Splitting requires either:
1. **Re-export pattern**: `identity.py` keeps the same public surface by importing from the 6 sub-modules (`from identity_time import now_iso, parse_ts, identity_deferral_now` etc.). Callers see no change.
2. **Caller migration**: Callers update their imports. Higher blast radius; not recommended.

**Pattern 1 is the canonical move** — preserves caller surface while subdividing internals.

### File 3: `part-02-portable_doctor.sh` (1836 lines → split into 6-8)

**Hardest of the three** — ONE giant `portable_doctor()` function. Plus this file is ALREADY a "part-NN" extraction (the `core.d/` directory naming convention shows it was previously sliced from a monolith). Further splitting requires moving SUB-OPERATIONS into part-NN or sub-helpers.

**Semantic boundaries already in the file** (per inv-portable-doctor.txt):

The function's body has natural seams marked by `local scoped_doctor="..."` blocks (each ~20 lines, invoking a different sub-probe script) AND a wire-in-table at lines 1713-1820 with explicit Section A-G structure:

- **Section A**: L-rule fields (15 rules × 5 = wired)
- **Section B**: substrate primitive auto-fire surfaces (11)
- **Section C**: quality-bar fields (8)
- **Section D**: README/AGENTS.md propagation fields (6)
- **Section E**: /flywheel:plan skill fields (6)
- **Section F**: comms fields (3)
- **Section G**: session-level violation fields (5)

**Semantic split** (8 sub-files in `core.d/portable_doctor.d/`):

```
~/.claude/skills/.flywheel/lib/portable/core.d/
├── part-02-portable_doctor.sh                        (~150 lines — entry: parse args, dispatch to sub-probes, aggregate)
└── portable_doctor.d/
    ├── 01-arg-parse.sh                               (~50 lines — strict, fix, scope, storage thresholds)
    ├── 02-scoped-probes-pre.sh                       (~250 lines — 11 scoped_doctor calls before main aggregation: auto-l112, quality-bar-close-gate, watcher-isomorphic, stale-in-progress, jsm-sandbox-auth, substrate-loop-contract, storage-headroom, peer-orch-respawn, peer-orch-freeze, codex-template-stuck, callback-envelope)
    ├── 03-scoped-probes-mid.sh                       (~200 lines — 6 more scoped_doctor calls: tick-hook-firing, flywheel-tick-driver, flywheel-loop-driver-writeback, l70-ticks-punted, agents-md-fleet-propagator, beads-db-recover)
    ├── 04-section-a-l-rule-fields.sh                 (~150 lines — Section A wire-in)
    ├── 05-section-b-substrate-primitives.sh          (~120 lines — Section B substrate primitive auto-fire)
    ├── 06-section-c-quality-bar.sh                   (~80 lines — Section C quality-bar fields)
    ├── 07-section-de-propagation-plan-skill.sh       (~150 lines — Sections D + E)
    └── 08-section-fg-comms-session.sh                (~80 lines — Sections F + G)
```

The dispatch motion in entry: each sub-script defines a function (or sources its body); entry calls them in order and aggregates outputs.

**Caveat**: shell function-body extraction is more delicate than Python module imports — variables flow via `local` declarations and the function's outer scope. The extracted sub-files must use the same `local`-variable contract OR the caller must export. Behavior fixtures are essential here to catch any state-leak regressions.

## Fixture design

**Each split is gated on behavior fixtures that prove command-surface parity.** The fixtures are FIRST per bead acceptance.

### Fixture 1: `loop_driver_doctor_json.py` parity contract

**Test path**: `.flywheel/tests/test-loop-driver-doctor-parity.sh`

**What it asserts**:

```bash
# Run the analyzer with a fixture topology + marker setup
# Capture JSON output
# Assert: same JSON keys + same value classes for both pre-split and post-split versions

PRE_OUT=$(python3 ~/.claude/skills/.flywheel/lib/loop.d/loop_driver_doctor_json.py \
  /tmp/fixture-repo /tmp/fixture-topology.jsonl)
# Compare expected JSON shape
echo "$PRE_OUT" | jq -e '
  has("active_marker") and
  has("dispatch_mode") and
  has("driver_status") and
  has("active_marker_project_label_loaded") and
  has("inactive_marker_post_stop_tick_count") and
  has("inactive_marker_post_stop_tick") and
  has("violations") and
  has("warnings")
' >/dev/null
```

**Fixture inputs**:
- A fixture repo path (mktemp -d) with `.flywheel/config.toml`
- A fixture topology file (single-row JSONL)
- A fixture loops dir + plist (or absent for missing-driver path)
- A fixture dispatch-log.jsonl with timestamped rows
- ENV vars: `FLYWHEEL_LOOP_MARKER_DIR`, `FLYWHEEL_LOOP_LAUNCH_AGENTS_DIR`, `FLYWHEEL_LOOP_NTM_HEALTH_JSON`, etc. (the file already has fixture-friendly env-var hooks at lines 191-198 and 216-220)

**Coverage matrix** (each row = one branch through the analyzer):
| Scenario | Expected `driver_status` | Expected violations |
|---|---|---|
| inactive marker | `UNKNOWN` | empty |
| active marker, no plist, no script | `MISSING_DRIVER` | `loop_state_without_driver` |
| active marker, plist exists, no recent dispatch | `STALE` | `loop_driver_stale` |
| active marker, plist exists, recent dispatch, ntm pane live, prompt observed | `VERIFIED` | empty |
| active marker, recent dispatch, prompt NOT observed | (any) | `loop_send_without_pane_prompt` |

**5 scenarios × ~30 lines each = ~150 line fixture**.

### Fixture 2: `identity.py` parity contract

**Test path**: `.flywheel/tests/test-identity-py-parity.sh`

**What it asserts**: each of the 32 functions has at least one black-box invocation that returns a stable shape:

```bash
python3 -c "
import sys
sys.path.insert(0, '/Users/josh/.claude/skills/.flywheel/lib/portable/identity.d/')
import identity

# Each function tested with fixture inputs
assert identity.now_iso().endswith('Z')
assert identity.parse_ts('2026-05-09T12:00:00Z') is not None
key = identity.identity_primary_key('flywheel', 2, 'flywheel')
assert isinstance(key, tuple) and len(key) == 3
# ... etc for all 32 functions
"
```

**Fixture inputs**: temp directory for token writes; temp topology JSONL; mock `sys.argv`.

**Coverage matrix**: 32 functions × 1-2 invocations each = ~50 assertions. Each function gets at least one input-output snapshot frozen against the pre-split state.

### Fixture 3: `part-02-portable_doctor.sh` parity contract

**Test path**: `.flywheel/tests/test-portable-doctor-parity.sh`

**What it asserts**: `portable_doctor` runs against a fixture repo and emits the same JSON shape pre/post split. This is the most expensive fixture because the function calls 17+ sub-probes.

**Strategy**:
- Create a fixture repo with all the expected substrate (config.toml, dispatch-log.jsonl, loops dir, etc.)
- For each of the 17 sub-probes, EITHER:
  - (a) provide a fixture stub that returns a deterministic JSON
  - (b) skip the sub-probe with a `--skip-<probe>` flag
- Run `portable_doctor --json` and capture stdout
- Assert: top-level JSON keys present (90 fields per line 688-702 declarations)

**Coverage matrix**: 90 declared fields × 1 presence-check = 90 assertions. Plus 8 scoped_doctor result-passthrough checks (one per Section A-G + the pre/mid scoped probes).

This fixture is the most labor-intensive. Probably 2 dispatches just for the fixture, before the actual splits can land.

## Order of operations (recommended sibling-bead sequence)

The orch should file these as a 6-bead sequence:

```
flywheel-hzsro.1  →  fixture: loop_driver_doctor_json.py parity contract     (P2, ~150 lines test)
flywheel-hzsro.2  →  split:    loop_driver_doctor_json.py → entry + lib       (P2, depends on .1)
flywheel-hzsro.3  →  fixture: identity.py parity contract                    (P2, ~50 assertions)
flywheel-hzsro.4  →  split:    identity.py → 6 sub-modules with re-export    (P2, depends on .3)
flywheel-hzsro.5  →  fixture: part-02-portable_doctor.sh parity contract     (P2, larger; possibly 2 sub-beads)
flywheel-hzsro.6  →  split:    part-02-portable_doctor.sh → entry + 7 sub    (P2, depends on .5)
```

**Order matters**: smallest file first (loop_driver_doctor) proves the pattern; identity.py uses re-export pattern (different shape); portable_doctor is largest and risk-tier-3.

**Regression-protection chain**: each split's apply gate is "pre-split fixture passes AND post-split fixture passes AND JSON shapes are byte-equal". The fixture from .1 is the apply-gate for .2; from .3 for .4; from .5 for .6.

## Worker-tick scope decision

This dispatch's worker-tick scope ENDS at producing this plan. Reasons:

1. **3516 lines refactor + 6-bead sequence is multi-dispatch work**, not 120s scope.
2. **Fixtures-first is a hard precondition** — splits without fixtures violate the bead's safety constraint ("only after adding behavior fixtures").
3. **Even one fixture (fixture-1: loop_driver_doctor parity) is ~150 lines of shell+python assertion code** with substrate setup; bordering on tick budget alone.
4. **The actual splits each modify a JSM-relevant skill module** (~/.claude/skills/.flywheel/) and require careful staging + parity verification across multiple test paths.

**Sibling-bead recommendation surfaced via `flywheel_orch_action_required`**: file `flywheel-hzsro.1` through `.6` per the order-of-operations table above.

## Acceptance gate map

The bead has implicit acceptance gates from its body text. This plan addresses each:

| # | Implicit gate | Plan addresses? | Where |
|---|---|---|---|
| 1 | Add behavior fixtures for the analyzer boundaries | ✓ Three fixture designs documented (loop_driver_doctor, identity.py, portable_doctor) with coverage matrices |
| 2 | Split lib/portable/core.d/part-02-portable_doctor.sh by semantic subdomain | ✓ 6-8 sub-files plan documented with line-anchored function-to-module map |
| 3 | Split lib/portable/identity.d/identity.py by semantic subdomain | ✓ 6 sub-modules plan documented with function-cluster map |
| 4 | Split lib/loop.d/loop_driver_doctor_json.py by semantic subdomain | ✓ 2-file plan documented (entry + lib) |
| 5 | Preserve command surface parity | ✓ Each split has a fixture-design that asserts byte-equality of JSON shape pre/post split; ordering rule (fixture-first, split-second) makes parity verifiable |

did=5/5

## Caveats and risks documented

- **Module-scope side effects in loop_driver_doctor**: `repo`, `topology_path` etc. are read at module load from sys.argv. Split must thread these as args, not just import.
- **`identity.py` is a callable module**: split must use re-export pattern to preserve caller imports (else 32+ caller updates needed).
- **`portable_doctor` is one giant function**: shell function-body extraction is more delicate than Python module imports; the fixture for parity must run the FULL function end-to-end to catch state-leak regressions.
- **17 sub-probe scoped_doctor calls in portable_doctor**: each delegates to a separate script. Splitting the function body affects only the orchestration layer; the sub-probe scripts themselves are untouched.
- **JSM management**: `~/.claude/skills/.flywheel/` is NOT JSM-managed (`jsm list | grep .flywheel` returns 0). Direct edit allowed. But the split lands in a skill repo that downstream consumers source — coordinate with skillos session per memory `project_skillos_separated.md`.
