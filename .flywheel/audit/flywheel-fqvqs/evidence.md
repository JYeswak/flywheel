# flywheel-fqvqs Evidence — agent-lifecycle shell self-test wrapper

Task: `flywheel-fqvqs-f577cc`
Bead: `flywheel-fqvqs` (P2 OPEN → CLOSED this turn)
Title: Add agent-lifecycle shell self-test wrapper
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=infrastructure` — adds the `.sh`
substrate the skill-builder validator requires so agent-lifecycle stops
failing the fleet validation check.

## What changed

| File | Action | Purpose |
|---|---|---|
| `~/.claude/skills/agent-lifecycle/scripts/self-test.sh` | NEW (executable) | Shell wrapper running `python3 -m py_compile` + `--deploy --json` smoke |
| `~/.claude/skills/agent-lifecycle/SELF-TEST.md` | NEW | Names the wrapper, expected output, and the surface it satisfies |
| `.flywheel/audit/flywheel-fqvqs/agent-lifecycle.jsm-import-ready.patch` | NEW | Paired jsm-import-ready patch artifact (per skill-enhance JSM discipline for unmanaged skills) |

## JSM discipline pre-flight

Per the dispatch's SKILL-ENHANCE JSM DISCIPLINE BLOCK:

```bash
jsm list --json | jq '.skills[] | select(.name == "agent-lifecycle")'   # empty
jsm list --json | jq '.skills[] | select(.name == "skill-builder")'     # empty
```

Neither skill is JSM-managed (`empty` from both selects → `managed=false`
on the `skill-enhance-jsm-discipline.sh` validator). Direct mutation
under `~/.claude/skills/agent-lifecycle/` is allowed; paired
`jsm-import-ready` patch artifact is shipped at
`.flywheel/audit/flywheel-fqvqs/agent-lifecycle.jsm-import-ready.patch`
so the change can be imported into JSM later if Joshua chooses.

## Acceptance gates (bead body) + dispatch AGs

| Gate | Status | Evidence |
|---|---|---|
| Bead AC: `validate-skill.sh` exits 0 or remaining failures unrelated to scripts/*.sh | DID | `validator-after.txt` shows `OK: validate-skill: all hard checks passed`; `scripts/ has 1 .sh file(s)` and `all scripts pass bash -n` |
| Bead AC: wrapper uses `set -euo pipefail` | DID | line 2 of `scripts/self-test.sh`: `set -euo pipefail` |
| Bead AC: wrapper runs `python3 -m py_compile` | DID | line 80 of `scripts/self-test.sh` calls `python3 -m py_compile "$LIFECYCLE_PY"`; check 1 of the smoke |
| Bead AC: wrapper runs `lifecycle_manager` deploy JSON smoke | DID | line 91 calls `python3 "$LIFECYCLE_PY" --deploy --json` and asserts envelope shape (operation=deploy, status=completed, total_findings>=1) |
| Bead Testing: `bash -n scripts/self-test.sh` | DID | exit 0 (captured `bash_n=ok`) |
| Bead Testing: `validate-skill.sh ...` | DID | `validator-after.txt` |
| AG1 — substrate updated | DID | scripts/self-test.sh + SELF-TEST.md + audit pack + jsm-import-ready patch |
| AG2 — targeted validator passes and named | DID | both `bash scripts/self-test.sh --json` (status=pass) and `bash scripts/validate-skill.sh ~/.claude/skills/agent-lifecycle` (all hard checks passed) |
| AG3 — `br show` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |

did=8/8 didnt=none gaps=none.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| self-test wrapper | `~/.claude/skills/agent-lifecycle/scripts/self-test.sh` | `03431fb75778ae04fe7bda5ce669226ac1362f94081a0ba2672b74f8e0e4a82a` |
| SELF-TEST.md | `~/.claude/skills/agent-lifecycle/SELF-TEST.md` | `8a4de36e8b1dda11d5a4889c33d5584b09b936a72e51a6e5f40a08d8c7db820d` |
| jsm-import-ready patch | `.flywheel/audit/flywheel-fqvqs/agent-lifecycle.jsm-import-ready.patch` | `6bd36b17dd64e3f1f87fb7a6e90e6731ed896e1233eaaaa4c2248cf277bd19e7` |

## Validator before / after

### BEFORE (from `validator-before.txt`)

```
OK:   Anti-Patterns table present
FAIL: scripts/ has no .sh files
OK:   all scripts pass bash -n
OK:   references/ has 3 .md file(s)
OK:   SKILL.md line count: 293 (< 500)
WARN: SELF-TEST.md missing (recommended)

FAIL: validate-skill: 1 hard check(s) failed for /Users/josh/.claude/skills/agent-lifecycle
```

### AFTER (from `validator-after.txt`)

```
OK:   Anti-Patterns table present
OK:   scripts/ has 1 .sh file(s)
OK:   all scripts pass bash -n
OK:   references/ has 3 .md file(s)
OK:   SKILL.md line count: 293 (< 500)
OK:   SELF-TEST.md present

OK:   validate-skill: all hard checks passed for /Users/josh/.claude/skills/agent-lifecycle
```

Net: 1 FAIL → 0 FAIL; 1 WARN → 0 WARN; validator now reports `all hard
checks passed`.

## Self-test envelope (canonical-cli-scoping)

```json
{"schema_version":"agent-lifecycle.self-test.v1","version":"0.1.0","status":"pass","exit_code":0,"message":"self-test passed","target":"/Users/josh/.claude/skills/agent-lifecycle/scripts/lifecycle_manager.py","checks":{"py_compile":"pass","deploy_json_smoke":"pass"}}
```

The wrapper exposes `--info`, `--version`, `--json`, and `--help` per
the canonical-cli-scoping skill. Unknown flags exit `2` (verified rc=2);
PASS exits `0`; either check failing exits `1`.

## Verification commands (re-runnable)

```bash
bash ~/.claude/skills/agent-lifecycle/scripts/self-test.sh --json
# expected: status=pass, py_compile=pass, deploy_json_smoke=pass

bash ~/.claude/skills/skill-builder/scripts/validate-skill.sh \
  ~/.claude/skills/agent-lifecycle
# expected: "validate-skill: all hard checks passed"
```

## L112 probe (worker callback)

```bash
bash ~/.claude/skills/agent-lifecycle/scripts/self-test.sh --json \
  | jq -e '.status == "pass" and .checks.py_compile == "pass" and .checks.deploy_json_smoke == "pass"' \
  >/dev/null && echo ok || echo missing
```

Expected (literal): `ok`.

## Boundary

- **No other skills touched.** The dispatch detected `agent-lifecycle`
  and `skill-builder`; only `agent-lifecycle` was mutated (per the bead
  body's named outputs).
- **No JSM push.** The jsm-import-ready patch is generated for future
  import; this rework does not call `jsm push`.
- **No SKILL.md edit.** `agent-lifecycle/SKILL.md` SHA unchanged; all
  changes are confined to the new files.
- **No flywheel doctrine surface mutated.** No L-rule, no INCIDENTS,
  no AGENTS.md change. Audit pack is the only flywheel-repo write.

## Skill auto-routes

- `canonical-cli-scoping=yes` — wrapper exposes
  `--info`/`--version`/`--json`/`--help` with stable exit codes (0
  pass, 1 fail, 2 usage); JSON envelope schema-versioned
  `agent-lifecycle.self-test.v1`; file-length 96 lines (under
  threshold).
- `python-best-practices=n/a` — no Python files authored or modified;
  the existing `lifecycle_manager.py` is unchanged. Wrapper invokes it
  via py_compile + subprocess.
- `rust-best-practices=n/a` — no Rust.
- `readme-writing=n/a` — `SELF-TEST.md` is a per-skill smoke note, not
  a public README. Quick Start is one command (`bash scripts/self-test.sh`)
  + one command (`--json` variant); when-to-use is implicit (validator
  surface).

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no AGENTS.md or doctrine surface mutated.
- `readme_updated=not_applicable`.
- `no_touch_reason=skill-local_test_wrapper_only_no_higher_doctrine_layer_required`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes every bead AC and dispatch AG verbatim. The
  validator before→after delta is the headline proof.
- **Sniff: 9** — wrapper actually runs both checks (py_compile +
  --deploy --json envelope shape) rather than a `true` no-op; jq filter
  asserts at least one finding to catch silent-failure regressions.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small surface
  (one sh + one md + one patch); paired jsm-import-ready patch
  artifact ships per skill-enhance JSM discipline; no upstream patch
  to any Jeffrey-owned repo.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: one bash command runs the wrapper
    in <1s; one command re-runs the validator and reports green.
  - **maintainer (extending later)**: schema-versioned envelope
    (`agent-lifecycle.self-test.v1`) and stable exit codes mean
    additions slot in without a redesign.
  - **future worker (LLM agent)**: bar named, the wrapper template
    (set -euo pipefail + py_compile + JSON smoke + canonical-cli-scoping
    surface) is reusable for any other agent-lifecycle-shaped skill.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-fqvqs
no_bead_reason=acceptance_gates_satisfied_validator_clean_no_residual_failures_to_split_into_followup`.
