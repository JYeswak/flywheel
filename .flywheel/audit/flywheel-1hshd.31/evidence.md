# Evidence Pack — flywheel-1hshd.31

**Surface:** `.flywheel/scripts/frozen-pane-detector-fleet.sh`
**Bead:** flywheel-1hshd.31 — wave-4-general-31 partial → passing
**Identity:** MagentaPond | **Pane:** flywheel:0.3 | **Date:** 2026-05-11

## What Shipped

**IN-PLACE AUGMENTATION pattern** (no scaffold layer needed). Native script (497 lines) already had every canonical verb implemented (`doctor`, `health`, `install`, `uninstall`, `cycle`, `repair`, `validate`, `audit`, `why`, `schema`, `quickstart`, `completion`) plus `--info` and `--examples` flags. Two pre-existing regression suites (17 + 7 assertions) cover the native contract.

This bead's contribution: four surgical in-place augmentations to satisfy AG3 strict gates while preserving every native field the regression tests assert on.

| Augmentation | Purpose | Preserves |
|---|---|---|
| `info_json()` adds `.name` + `.capabilities[6]` | AG3.1 | `.commands`, `.version`, `.label`, `.detector`, `.plist`, `.state_dir` (regression `index("doctor") and index("repair") and ...`) |
| `schema_json()` adds `.input_schema` + `.output_schema` | AG3.2 | `.title`, `.required` |
| `examples()` adds `--json` branch (JSON envelope when `JSON_OUT==1`) | AG3.3 | text mode for back-compat (`"$SCRIPT" --examples >/dev/null` checks rc) |
| `augmented_doctor_json()` wraps `doctor_json()` with `.checks` array | AG3.4 | every native field (`.status`, `.daemon_installed`, `.cadence_seconds`, `.warnings`, `.errors`) — both regression suites assert these |

Plus magic comment `# flywheel-cli-surface: true` (closes lint L6).

| Artifact | Before | After |
|---|---|---|
| `.flywheel/scripts/frozen-pane-detector-fleet.sh` | 497 lines, lint=L6-error | 591 lines, lint=clean |
| `tests/frozen-pane-detector-fleet-canonical-cli.sh` | absent | 17-test suite (PASS) |
| `tests/frozen-pane-detector-fleet.sh` (regression A) | 17/0 PASS | 17/0 PASS (zero regression) |
| `.flywheel/tests/test-frozen-pane-detector-fleet-introspection.sh` (regression B) | 7/0 PASS | 7/0 PASS (zero regression) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` row 134 | partial | passing |

## AG3 Strict Gates

| Gate | Command | Result |
|---|---|---|
| AG3.1 | `--info --json \| jq -e '.name and .version and .capabilities'` | PASS — 6 capabilities + native `.commands` preserved (`smoke-info.json`) |
| AG3.2 | `--schema --json \| jq -e '.input_schema and .output_schema'` | PASS — native `.title` + `.required` preserved (`smoke-schema.json`) |
| AG3.3 | `--examples --json \| jq -e '.examples \| length > 0'` | PASS — 5 examples; native text mode preserved (`smoke-examples.json`) |
| AG3.4 | `doctor --json \| jq -e '.checks'` | PASS — 6 named probes; both `doctor` (positional) and `--doctor` (flag) route through augmentation (`smoke-doctor-{positional,flag}.json`) |

## Mid-Author Bug Caught + Fixed Pre-Commit

First draft of `examples()` used `if [[ "${JSON:-0}" == "1" ]]` to gate the JSON envelope branch — but the native script's variable is named `JSON_OUT`, not `JSON`. Result: `--examples --json` returned the text heredoc (no envelope), failing AG3.3.

Fixed to `if [[ "${JSON_OUT:-0}" == "1" ]]`. Detected by AG3.3 quick-probe before the canonical-cli test suite was even authored. Reusable substrate-self-exercise reference (doctrine v0.1.9 Shape C signal).

## Surface Coverage

| Surface | Owner | Evidence |
|---|---|---|
| `--info` | native (in-place augmented w/ .name + .capabilities[6]) | `smoke-info.json` |
| `--schema` | native (in-place augmented w/ .input_schema + .output_schema) | `smoke-schema.json` |
| `--examples` | native (in-place augmented w/ --json envelope branch) | `smoke-examples.json` (json) + Test 4 (text-mode) |
| `--doctor` flag | native (augmented via `augmented_doctor_json` wrap) | `smoke-doctor-flag.json` |
| `doctor` (positional) | same wrap as `--doctor` | `smoke-doctor-positional.json` |
| `health` | native (unchanged) | regression A |
| `install` `--dry-run`/`--apply` | native (unchanged; LaunchAgent disabled-by-default) | regression A + Test 13 |
| `uninstall` | native (unchanged) | regression A |
| `cycle` | native (unchanged; degraded-truth blocks recovery) | regression A |
| `repair --scope install` | native (unchanged) | regression A |
| `validate plist\|budgets\|cycle` | native (unchanged) | `smoke-validate-budgets.json` + Test 12 |
| `audit` | native (unchanged) | `smoke-audit.json` + Test 8 |
| `why <gate\|truth\|budget\|launchd>` | native (unchanged) | regression A + Test 9 |
| `quickstart`/`completion` | native (unchanged) | regression A + Tests 10/11 |

## Skill Auto-Routes

| Skill | Status | Evidence |
|---|---|---|
| canonical-cli-scoping | yes | `lint.json` clean RC=0 (was L6 error); 17/17 canonical-cli + 17/0 + 7/0 regression PASS; AG3.1-4 all PASS |
| rust-best-practices | n/a | bash + jq + plutil + launchctl surface |
| python-best-practices | n/a | 1-line python3 import for plist write fallback only |
| readme-writing | n/a | no README touched |

## Backward Compatibility

Both pre-existing regression suites pass with zero delta:

- `tests/frozen-pane-detector-fleet.sh`: 17/0 PASS — exercises absent + installed daemon doctor contracts, install dry-run + apply, cycle stop/fatal/budget paths, validate budgets, audit, info `.commands`, examples surface, why surface
- `.flywheel/tests/test-frozen-pane-detector-fleet-introspection.sh`: 7/0 PASS — exercises introspection surfaces

The `augmented_doctor_json` wrap preserves every native field that the regression test asserts on (verified by Tests 6 + 7 in the new canonical-cli suite which check `.status`, `.daemon_installed`, `.cadence_seconds`, `.recovery_budget` AND `.checks`).

## Four-Lens Self-Grade

- **Brand:** 10/10 — IN-PLACE AUGMENTATION is the right pattern when native already has every verb; no unnecessary scaffold layer.
- **Sniff:** 10/10 — every claim has an evidence file; AG3 strict gates literally executed; mid-author bug caught + documented + fixed pre-commit.
- **Jeff:** 10/10 — augmentations are explicit comments (each `info_json/schema_json/examples/augmented_doctor_json` carries a v0.1.9 reference + back-compat preservation note); the `--examples` --json branch is a clean conditional that doesn't break the rc-only call pattern.
- **Public:** 10/10 — operator (clear `--info`/`--schema` introspection with both old + new fields), maintainer (in-place comments mark each augmentation + preservation rationale), future worker (Test 6 explicitly verifies both `--doctor` flag AND positional `doctor` route through augmentation, so the contract is tested both ways).

`four_lens=brand:10,sniff:10,jeff:10,public:10`

## Compliance Score

| Dimension | Points | Evidence |
|---|---|---|
| Lint clean | 100/100 | `lint.json` status=clean (was L6 error) |
| AG3 strict gates | 250/250 | AG3.1-4 all PASS |
| Canonical-cli test suite | 200/200 | 17/17 PASS |
| Pre-existing regression preserved (TWO suites) | 250/250 | 17/0 + 7/0 PASS (zero delta) |
| Inventory transitioned | 50/50 | partial → passing with annotation |
| In-place augmentation discipline | 100/100 | no scaffold layer; minimum-surface intervention |
| Mid-author bug caught + fixed pre-commit | 50/50 | $JSON vs $JSON_OUT typo documented |
| **TOTAL** | **1000/1000** | |

`compliance_score=1000/1000`

## L112 Verify Probe

```bash
bash .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/frozen-pane-detector-fleet.sh --json
```
Expected: `jq:.status == "clean"`. Timeout 30s.
