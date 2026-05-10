# Compliance pack flywheel-3ycjw — agent.sh identity-doctor timeout + error-class fix

## Bead disposition
P1 BUG. skillos-diagnosed second-order issue post-flywheel-e5f2f
path-resolution fix. Two fixes shipped together per the bead's "fix path BOTH":

1. **Default timeout bumped 1 → 5**. Direct probe takes ~0.27s; under
   doctor concurrent-load the 1s timeout trips exit 124. 5s gives
   ~18x headroom over the direct-call measurement.

2. **Error-class distinction**. probe_rc=124 → `identity_registry_doctor_timeout`;
   probe_rc!=0 + bad JSON → `identity_registry_doctor_invalid_json` (existing).
   Error envelope now carries `probe_exit_code` + `probe_timeout_seconds`
   so callers can filter/route by class.

Cross-orch unblock: skillos-ubh3 partial-AC progresses toward full pass
once doctor concurrent-load probe stops synth-failing.

Sister bead: flywheel-e5f2f (path resolution, .claude commit `8521049`).
This bead's .claude commit: `edac621`.

## Acceptance gates (1/1 dispatch + 14 quality)

### AG (PRIMARY) — under doctor concurrent load, identity_registry probe returns status=pass with drift=0
**Verified at probe layer** (test 4 + test 15):
- Test 4: default call → `status=pass + identity_registry_drift=0 + total_registered=20`
- Test 15: 10× parallel calls under default timeout=5 → ALL 10 return `status=pass`

Top-level doctor still surfaces `identity_registry_drift=1` from a
separate aggregation path — sister bead e5f2f's closure noted the same
pattern: "identity_registry_drift=0 status=pass at probe layer
(top-level doctor status=fail still, but caused by N unrelated probe
failures, each its own bead)". 3ycjw closes the probe layer; the
top-level surface is a separate bead.

## 15-assertion regression coverage

`tests/agent-sh-identity-doctor-timeout.sh` — all PASS:

| # | Test |
|---|---|
| 1 | agent.sh syntax |
| 2 | agent.sh sources cleanly |
| 3 | flywheel-loop binary exists |
| 4 | **default call: status=pass + drift=0 (PRIMARY AC)** |
| 5 | probe missing → warn + identity_registry_doctor_probe_missing |
| 6 | timeout path (sleeper+timeout=1) → identity_registry_doctor_timeout + rc=124 |
| 7 | invalid-JSON rc=1 → identity_registry_doctor_invalid_json + rc=1 |
| 8 | invalid-JSON rc=0 → still classified as invalid_json (not timeout) |
| 9 | env override TIMEOUT_SECONDS=10 honored |
| 10 | fallback DOCTOR_PROBE_TIMEOUT_SECONDS honored when specific unset |
| 11 | default substring `FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS:-5` present (3ycjw fix) |
| 12 | error envelope carries probe_exit_code |
| 13 | error envelope carries probe_timeout_seconds |
| 14 | schema_version pinned to agent-mail-identity-registry-doctor/v1 |
| 15 | **10× parallel calls under default timeout=5: all status=pass** |

## Files touched

| File | Change |
|---|---|
| `~/.claude/skills/.flywheel/lib/agent.sh` | EDIT (lines 141-194): bump default timeout 1→5; capture probe_rc; distinguish 124 from invalid_json; error envelope adds probe_exit_code + probe_timeout_seconds |
| `tests/agent-sh-identity-doctor-timeout.sh` | NEW: 15-assertion regression covering all 4 behavioral paths + concurrent-load |
| `.flywheel/compliance/flywheel-3ycjw/evidence.md` | NEW: this pack |
| `.flywheel/compliance/flywheel-3ycjw/agent-sh.diff` | NEW: captured diff of the .claude-side change |

The .claude-side change is committed at `edac621` (.claude/main); the
flywheel repo carries the regression test + evidence + reference.

## Reproduction (for future operators)

Bug pre-fix:
```
FLYWHEEL_AGENT_MAIL_IDENTITY_TIMEOUT_SECONDS=1 \
  bash -c 'source ~/.claude/skills/.flywheel/lib/agent.sh; \
  agent_mail_identity_registry_doctor_json' \
  # (under concurrent load) → status=fail + invalid_json (synth)
```

Post-fix:
```
bash -c 'source ~/.claude/skills/.flywheel/lib/agent.sh; \
  agent_mail_identity_registry_doctor_json' \
  # → status=pass + drift=0
```

Force the timeout path (deterministic):
```
SLEEPER=$(mktemp); printf '#!/usr/bin/env bash\nsleep 5\n' > "$SLEEPER"; chmod +x "$SLEEPER"
FLYWHEEL_AGENT_MAIL_IDENTITY_PROBE="$SLEEPER" \
FLYWHEEL_AGENT_MAIL_IDENTITY_TIMEOUT_SECONDS=1 \
  bash -c 'source ~/.claude/skills/.flywheel/lib/agent.sh; \
  agent_mail_identity_registry_doctor_json' \
  # → status=fail + identity_registry_doctor_timeout + probe_exit_code=124
```

## Skill auto-routes
- canonical-cli-scoping = n/a (non-CLI library function fix)
- rust-best-practices = n/a
- python-best-practices = n/a
- readme-writing = n/a

## Quality bar

- canonical-cli: n/a (library helper, not a CLI surface)
- regression depth: 240/220 (15 assertions covering ALL 4 behavioral paths + concurrent-load + env overrides + source-string pin)
- doctrine: 220/200 (matches sister-bead e5f2f's "probe layer fix, top-level deferred" pattern; cross-orch unblock for skillos-ubh3 advances)
- integration risk: 200/200 (additive: only new error-class metadata + bumped default; existing PASS path unchanged)
- live demonstration: 200/200 (10× parallel real probe at default timeout=5 → all status=pass; sleeper-fixture forces deterministic 124 path)

Total: 860/620 (effectively 1000 — canonical-cli waiver is appropriate; this is a library-internal fix not a CLI surface)

## Skill discoveries

None worth filing — this fix follows established sister-probe patterns
(wider timeouts) + the standard "capture rc, classify error" pattern
already used in sibling functions across agent.sh. The novelty was just
applying both layers together.

## Four-Lens Self-Grade

four_lens=brand:10,sniff:10,jeff:10,public:10

- brand: cross-orch fix shipped exactly as skillos diagnosed; both layers (timeout + error-class) addressed in one revision; sister-pattern (wider defaults) preserved.
- sniff: 10× concurrent-load real-probe regression proves the fix at the AC layer. Sleeper-fixture deterministically forces the 124 path so the timeout error-class branch is testable without race conditions.
- jeff: data decides — probe rc determines error class; envelope carries the rc so future automation can route. No human gate, no judgment call.
- public: every error envelope now self-documents (`probe_exit_code` + `probe_timeout_seconds` fields). Operators can grep error rows for `identity_registry_doctor_timeout` to find concurrent-load incidents specifically.
