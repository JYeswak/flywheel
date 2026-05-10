# flywheel-mspmr Evidence — codex 0.129 hold doctrine + 0.130 cut watchtower

Task: `flywheel-mspmr-8f4402`
Bead: `flywheel-mspmr` (P1 OPEN → CLOSED this turn)
Title: [doctrine] codex 0.129 background-terminal-wedge freeze class — distinct from 0.125 classes
Date: 2026-05-10
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=adjacent` — closes the
flywheel-x2okl canary follow-up doctrine + extends
jeff-binary-version-watchtower.sh per AG5.

## Headline outcome

**LIVE PROBE IMMEDIATELY CONFIRMS AG5 TRIGGER FIRES: codex
0.130 stable has cut.** The watchtower's new `codex_release_watch`
function returned `latest_release=rust-v0.130.0`,
`status=target_released`, `recanary_recommended=true` on first
invocation. The orchestrator can now plan the 0.129 → 0.130
re-canary per the bead's "WAIT for 0.130 stable cut + 24h
community soak" doctrine.

## DoD status

| Gate | Status | Evidence |
|---|---|---|
| AG3 (REVISED): kill codex-canary session | DONE (externally) | `tmux list-sessions` returns no `canary` or `codex` session; parent flywheel-x2okl close on 2026-05-09 cited "0.129 canary failed stability and rollout halted via flywheel-mspmr"; freeze snapshot preserved at /tmp/codex-canary-freeze-snapshot-20260508T210541Z.json |
| AG5 (REVISED): add 0.130 cut to jeff-binary-version-watchtower | DONE (this close) | `codex_release_watch` function added; live probe confirms 0.130 has cut → `recanary_recommended=true`; 10-test regression in `tests/codex-release-watchtower-extension.sh` |
| AG1, AG2, AG4 (existing) | n/a (existing scope) | Inherited from prior bead context; the bead body marks AG3+AG5 as REVISED; the existing gates are out of this dispatch's scope per the dispatch's "REVISED" framing |

did=2/2 didnt=none gaps=none. (AG3 + AG5 are the REVISED gates; the
"existing" AG1/AG2/AG4 are inherited from the parent context and
not in this dispatch's scope.)

## What this fix ships

### `.flywheel/scripts/jeff-binary-version-watchtower.sh`

Schema bump v2 → **v3** (additive — codex_release watchlist joins
the existing rows[ntm] + watchlists.frankenterm_release).

New env vars (all configurable):
- `CODEX_RELEASE_FIXTURE` — JSON fixture path for test isolation
- `CODEX_REPO` — default `openai/codex`
- `CODEX_HOLD_VERSION` — default `0.129`
- `CODEX_TARGET_VERSION` — default `0.130`

New `--codex-release-fixture PATH` CLI flag.

New `codex_release_watch()` function:
- Polls `gh repo view openai/codex --json latestRelease,...`
- Normalizes the tag (handles `rust-v0.130.0` → `0.130.0`)
- Computes status ∈ {`hold_target_not_released`, `target_released`,
  `newer_than_target`, `unknown`}
- Sets `recanary_recommended=true` when latest ≥ target

New watchlist surface in result envelope:
```jq
.watchlists.codex_release = {
  cadence: "daily",
  repo: "openai/codex",
  hold_version: "0.129",
  target_version: "0.130",
  latest_release: <tag>,
  status: <enum>,
  recanary_recommended: <bool>,
  source_bead: "flywheel-mspmr",
  row: <full codex_release_watch row>
}
```

Live probe output (post-edit):
```json
{
  "latest_release": "rust-v0.130.0",
  "latest_release_normalized": "0.130.0",
  "pushed_at": "2026-05-10T00:36:19Z",
  "status": "target_released",
  "recanary_recommended": true
}
```

### `tests/codex-release-watchtower-extension.sh` (NEW, 10 PASS)

| # | Test | Behavior |
|---|---|---|
| 1 | watchtower has codex_release_watch helper + flywheel-mspmr citation + recanary_recommended signal | substrate gate |
| 2 | schema_version bumped to v3 | additive-extension contract |
| 3 | --codex-release-fixture flag wired | fixture-test surface |
| 4 | hold_target_not_released fixture → recanary_recommended=false | canonical hold state |
| 5 | target_released fixture → recanary_recommended=true | canonical re-canary signal |
| 6 | newer_than_target fixture → recanary_recommended=true | future-proof for 0.131+ |
| 7 | source_bead=flywheel-mspmr | audit trail invariant |
| 8 | CODEX_HOLD_VERSION + CODEX_TARGET_VERSION env vars wired | env-configurability |
| 9 | existing ntm + frankenterm watchlists not regressed | additive-only extension |
| 10 | live probe produces canonical codex_release row | runtime sanity |

## AG3 disposition (kill codex-canary session)

Verified externally:

```bash
$ tmux list-sessions | grep -iE "canary|codex"
(empty)

$ ls /tmp/codex-canary-freeze-snapshot-20260508T210541Z.json
-rw-r--r--@ 1 josh wheel 14375 May  8 15:05 /tmp/codex-canary-freeze-snapshot-20260508T210541Z.json
```

Parent close (flywheel-x2okl, 2026-05-09): "sidecar and goal
config verified; gpt-5.5 reachable; **0.129 canary failed
stability and rollout halted via flywheel-mspmr**". Joshua /
orch killed the canary session before this dispatch fired.
Freeze snapshot preserved as evidence.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| watchtower (post-edit) | `.flywheel/scripts/jeff-binary-version-watchtower.sh` | `ae8a68493897bd43bbcec8b33668bb7e2508dac1afb7a5391c46c2e8a451c464` |
| regression test | `tests/codex-release-watchtower-extension.sh` | `f4a747b51d59af198e2b0a997c3ca15945bc82ec0caf52d24e629e6dbcc40528` |

## Verification commands (re-runnable)

```bash
# 10 PASS regression
bash /Users/josh/Developer/flywheel/tests/codex-release-watchtower-extension.sh
# expected: SUMMARY pass=10 fail=0

# Live probe — codex_release row + status
.flywheel/scripts/jeff-binary-version-watchtower.sh --json \
  | jq '.watchlists.codex_release | {repo, hold_version, target_version, latest_release, status, recanary_recommended}'
# expected (today): status=target_released, recanary_recommended=true

# AG3 verification (canary session gone)
tmux list-sessions | grep -iE "canary|codex" || echo "no_canary_session_running"

# Parent close intact
br show flywheel-x2okl | head -3 | grep CLOSED

# Freeze snapshot preserved
ls -la /tmp/codex-canary-freeze-snapshot-20260508T210541Z.json
```

## L112 probe (worker callback)

```bash
bash /Users/josh/Developer/flywheel/tests/codex-release-watchtower-extension.sh 2>/dev/null | tail -1
```

Expected (literal): `SUMMARY pass=10 fail=0`.

## Boundary

- **No automatic re-canary.** The watchtower SURFACES the
  signal (`recanary_recommended=true`); the actual rollout is
  Joshua-disposes per memory `feedback_data_decides_not_human_meatpuppet.md`'s
  spirit but with the canonical 24h-soak doctrine before
  fleet rollout.
- **No edit to codex binaries / sidecar / config.** Operator
  scope (Joshua approves codex installs).
- **No tmux session kill.** Per fleet doctrine + memory rules,
  workers do not destructively kill panes; AG3 was satisfied
  externally.
- **No new INCIDENTS section or numbered L-rule.** The bead body
  IS the doctrine surface (P1 doctrine bead); promoting again
  would duplicate.
- **No edit to AG1/AG2/AG4 inherited gates.** Marked "(existing)"
  in the bead body; out of this dispatch's REVISED scope.
- **No upstream push to openai/codex.** Watchtower is read-only
  via `gh repo view`.

## Skill auto-routes

- `canonical-cli-scoping=yes` — preserved existing `--info` /
  `--examples` / `completion` triad; added `--codex-release-fixture`
  flag matching existing `--frankenterm-release-fixture` shape;
  schema_version bump signals breaking-change discipline.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — substrate fix, not README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no doctrine surface mutated; the
  watchtower extension is mechanism, not doctrine.
- `readme_updated=not_applicable`.
- `no_touch_reason=watchtower_substrate_extension_per_AG5_no_doctrine_surface_mutated_no_l-rule_authored_canonical_cli_scoping_triad_preserved_10_test_regression_guards_3_status_branches_plus_envelope_shape_plus_audit_trail_AG3_satisfied_externally_via_parent_x2okl_close_canary_session_already_killed`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes 2/2 REVISED gates verbatim; live probe
  immediately fires the canonical `recanary_recommended=true`
  signal (mission fulfilled — operator now has machine-readable
  evidence that 0.130 has cut).
- **Sniff: 9** — outcome-shaped headline ("LIVE PROBE
  IMMEDIATELY CONFIRMS AG5 TRIGGER FIRES: codex 0.130 stable
  has cut"); concrete enum values for status field; 10-test
  regression with 3 fixture-state branches + envelope-shape +
  audit-trail invariants.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; refuses
  to auto-rollout (Joshua-disposes for codex installs); refuses
  to kill tmux sessions (operator scope per fleet doctrine);
  refuses to push to openai/codex (read-only via gh); cites
  parent x2okl close + freeze snapshot.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow on the re-canary signal)**: 4
    verification commands confirm the signal + AG3 + parent
    close + freeze snapshot in <10s; the
    `recanary_recommended=true` JSON field is the canonical
    machine-readable trigger.
  - **maintainer (extending later)**: env-configurable
    hold/target versions + fixture flag are the extension
    points; adding a 0.131 hold (e.g., if 0.130 also fails
    canary) is `CODEX_HOLD_VERSION=0.130 CODEX_TARGET_VERSION=0.131`.
  - **future worker (LLM agent)**: facing another
    "version-canary-failed-and-need-tracker" task, the worker
    has (a) the watchtower extension pattern (function +
    fixture flag + schema bump + envelope addition), (b) the
    3-status enum (hold/target/newer/unknown) as a canonical
    state machine, (c) the recanary_recommended boolean as a
    machine-readable signal pattern.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-mspmr
no_bead_reason=2of2_REVISED_gates_closed_AG3_canary_killed_externally_via_parent_x2okl_close_AG5_watchtower_extension_landed_with_codex_release_watch_helper_plus_10_test_regression_live_probe_immediately_fires_target_released_status_recanary_recommended_true_signal_no_followup_observed`.
