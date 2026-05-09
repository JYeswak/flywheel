# flywheel-2xdi.30 Evidence — wired-but-cold session-start hook

Task: `flywheel-2xdi.30-556f55`
Bead: `flywheel-2xdi.30` (P3 OPEN → CLOSED this turn)
Title: [gap-wired-but-cold] .claude/skills/.flywheel/hooks/session-start.sh
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Source: gap-hunt-probe auto-filed under parent `flywheel-2xdi`
(constant-gap-hunter cron-loop step), classification
`wired-but-cold:.claude-skills-.flywheel-hooks-session-start.sh`.
Mission fitness: `mission_fitness=infrastructure` — substrate-validation
work that adds a flywheel-side smoke test so the gap-hunter no longer
classes the hook as cold, and routes Joshua-gated activation through a
new follow-up bead.

## Headline finding — script is load-bearing AND functional, just intentionally inactive

The hook at `~/.claude/skills/.flywheel/hooks/session-start.sh` (345
lines, 0.1.0, last modified 2026-05-06) is the **canonical Claude Code
SessionStart consumer** of skillos's E1.5b
`context_upgrade_packet.session_start.v1` schema. It works: 7/7 PASS
on the new smoke test (`tests/session-start-hook-smoke.sh`). It is
"cold" because three preconditions are simultaneously absent:

1. Not registered in `~/.claude/settings.json` under `hooks.SessionStart`
   (only `PreToolUse`, `PostToolUse`, `Stop` are wired today).
2. Producer side
   (`/Users/josh/Developer/skillos/scripts/skillos_session_start_hook.sh`)
   is shipped but not actively writing packets per Claude Code session.
3. Canonical state directory
   (`~/.local/state/flywheel/sessions/`) does not exist on this host.

The gap-hunter detected the absence of recent flywheel jsonl ledger
references — accurate signal, but the classification "wired-but-cold"
should not be read as "remove" because:

- Skillos owns and tests the consumer
  (`tests/unit/test_flywheel_session_start_hook.bats`,
  `tests/unit/test_session_start_hook.py`).
- The hook is backwards-compatible by design: silent no-op (exit 0,
  empty stdout) when the packet is missing, malformed, or
  `SKILLOS_DISABLED=1`. Activation is **safe by default**; it just
  doesn't do anything until the producer side ramps up.
- Wiring it into `settings.json` is a global config change that affects
  every Claude Code session for Joshua. Per the Joshua-disposes axiom,
  this requires owner sign-off, not a worker auto-edit.

## What this rework does

| Action | Status |
|---|---|
| Add flywheel-side smoke test exercising the canonical-cli-scoping surface (`--info`, `--examples`, unknown-flag exit, missing-packet silent no-op, `--json` envelope shape, `SKILLOS_DISABLED=1` silent no-op) | DID — `tests/session-start-hook-smoke.sh` 7/7 PASS |
| File Joshua-gated follow-up bead for activation | DID — `flywheel-fqsmx` filed at P3 with explicit pre-flight checklist |
| Verify hook still works end-to-end | DID — `--info` exit 0 with schema + mission lock hash; `--dry-run` silent no-op exit 0 |
| Surface the gap-hunter classification with explicit no-touch reason | DID — this evidence pack |

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — substrate updated with close evidence | DID | this evidence pack at `.flywheel/audit/flywheel-2xdi.30/`; new smoke test at `tests/session-start-hook-smoke.sh` |
| AG2 — targeted test passes and is named | DID | `bash tests/session-start-hook-smoke.sh` returns `SUMMARY pass=7 fail=0`; smoke output captured at `smoke-output.txt` |
| AG3 — `br show flywheel-2xdi.30` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |

did=3/3 didnt=none gaps=none.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| consumer hook | `~/.claude/skills/.flywheel/hooks/session-start.sh` | `866715ece0935d2f9137f6b1c87b5ccc7e732cd3cc87e46aae022ead111f77c8` |
| smoke test | `tests/session-start-hook-smoke.sh` | `5eaf95cb80726282b2d39b857dbbd2d7c748d6b510bd954556ad24667a7adbbf` |

## Surface inventory (canonical-cli-scoping check on the existing hook)

The hook already implements the canonical-cli-scoping triad; the smoke
test now exercises it.

| Surface | Behavior | Smoke gate |
|---|---|---|
| `--info` | help + version + paths + env + schema + mission lock hash | exit 0 + `skillos.context_upgrade_packet.session_start.v1` + mission anchor hash present |
| `--examples` | curated invocations | cites `--session=` and `--dry-run` |
| `--version` | semver only | covered by skillos bats test (out-of-flywheel-scope) |
| `--json` | machine-readable envelope on stderr | conforms to `flywheel.session_start_hook.status.v1`, `status=noop` on missing packet |
| `--dry-run` | parsed skill list + path; no hook envelope emitted | covered indirectly via missing-packet path; full coverage in skillos bats |
| unknown flag | exit 1 (recoverable arg error) | exit 1 verified |
| missing packet | silent no-op exit 0 | empty stdout + exit 0 verified |
| `SKILLOS_DISABLED=1` | silent no-op exit 0 | empty stdout + exit 0 verified |

## Follow-up bead

**`flywheel-fqsmx`** — `[session-start-hook activation] joshua-gated
wire-in to ~/.claude/settings.json SessionStart` (P3 OPEN). Pre-flight:

1. `bash tests/session-start-hook-smoke.sh` PASS.
2. Confirm at least one session has a conformant
   `~/.local/state/flywheel/sessions/<session>/context_upgrade_packet.json`
   in production.
3. Joshua signs off on the global `settings.json` edit.

## Why no settings.json edit was made here

`~/.claude/settings.json` is a global Claude Code config that affects
every future session for Joshua. Per the Joshua-disposes axiom and the
canonical "data + methodology decide; owner approves global config"
profile, a worker-tick should never silently flip a global hook on. The
gap-hunter's role is to surface; the worker's role is to validate the
surface and route activation to a Joshua-gated bead.

## Verification commands (re-runnable)

```bash
# Smoke (the new flywheel-side gate)
bash /Users/josh/Developer/flywheel/tests/session-start-hook-smoke.sh
# Expected: SUMMARY pass=7 fail=0

# Hook is still load-bearing
~/.claude/skills/.flywheel/hooks/session-start.sh --info | head -5

# Gap-hunter no longer sees this as cold (after this commit lands)
grep -r "session-start" /Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl \
  /Users/josh/Developer/flywheel/.beads/issues.jsonl 2>/dev/null | head -5
```

## L112 probe (worker callback)

```bash
bash /Users/josh/Developer/flywheel/tests/session-start-hook-smoke.sh 2>/dev/null | tail -1
```

Expected (literal): `SUMMARY pass=7 fail=0`.

## Boundary

- **No `settings.json` edit.** Global config activation is owner-gated.
- **No producer-side change.** Skillos owns the producer half and its
  bats tests; cross-repo edits are out of scope for a P3 wired-but-cold
  surface.
- **Hook script unchanged.** Only added a flywheel-side smoke test +
  audit pack.
- **No L-rule edit.** No new doctrine.

## Skill auto-routes

- `canonical-cli-scoping=yes` — verified the existing hook's
  doctor/info/version/examples/--json/--dry-run triad. Smoke test
  re-runnable in <1s with stable exit codes.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — audit doc.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no doctrine surface mutated; the smoke test
  is per-script coverage, not a new L-rule.
- `readme_updated=not_applicable`.
- `no_touch_reason=smoke_test_only_no_canonical_doctrine_surface_authored_session_hook_activation_routed_to_flywheel-fqsmx`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes AG1/AG2/AG3 verbatim. Names "wired-but-cold"
  the right way: load-bearing, functional, intentionally inactive.
- **Sniff: 9** — every claim is jq/bash-checkable; smoke gates are
  deterministic; SHA pins are re-derivable in <1s.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; smoke test
  doesn't duplicate skillos's bats coverage; refuses unsigned global
  config edit; small surface (one new test + one audit pack + one
  follow-up bead).
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: one bash command runs the smoke;
    pre-flight checklist on `flywheel-fqsmx` is grep-friendly.
  - **maintainer (extending later)**: surface inventory table maps
    each canonical-cli-scoping surface to its smoke gate, so future
    additions slot in.
  - **future worker (LLM agent)**: bar named, the wired-but-cold
    classification has a documented response template (validate +
    smoke + Joshua-gated activation bead), reusable for the next
    cold-surface gap.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=flywheel-fqsmx beads_updated=flywheel-2xdi.30
no_bead_reason=wired-but-cold_validated_smoke_landed_activation_routed_to_joshua-gated_followup`.
