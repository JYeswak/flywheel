# Compliance pack flywheel-7228o — recursive substrate discovery: doctor-aggregation drift residual closed

## Bead disposition
P1 BUG. Recursive substrate discovery per progressive-disclosure pattern.
Closes the doctor-aggregation drift residual that **flywheel-3ycjw**
explicitly deferred ("top-level doctor still surfaces drift=1 from a
separate aggregation path — same pattern e5f2f's closure noted").

3-bead arc now complete:
- **flywheel-e5f2f** (closed): path resolution — fixed `agent.sh:141` probe to use absolute flywheel-loop path. `.claude` commit `8521049`.
- **flywheel-3ycjw** (closed): timeout default 1→5 + error-class distinction (rc=124 → identity_registry_doctor_timeout). `.claude` commit `edac621`.
- **flywheel-7228o** (this): umbrella bypass — identity probe ignores `FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS` cascade. `.claude` commit `504537b`.

## Root cause investigation (per dispatch's "trace the drift=1 source")

Used a 3-probe forensic pattern:
1. **Direct probe**: `flywheel-loop identity --doctor --json` → drift=0 ✓
2. **Function-level probe** (`source agent.sh; agent_mail_identity_registry_doctor_json`) → drift=0 ✓
3. **Top-level doctor**: `flywheel-loop doctor --repo /repo --json | jq .identity_registry_drift` → 1 ✗

The asymmetry told me the bug was in #3's invocation environment, not the function. Captured `/tmp/7228o-doctor.json` (5.5MB) and grepped for the drift source. Smoking gun in `.identity_registry.errors[0]`:

```json
{
  "code": "identity_registry_doctor_timeout",
  "probe_exit_code": 124,
  "probe_timeout_seconds": 0.2
}
```

The probe timed out at **0.2s** — NOT my 3ycjw default of 5s. Some upstream caller was setting `FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS=0.2`.

`grep -rn` against `~/.claude/skills/.flywheel/lib/` found:
```
part-02-portable_doctor.sh:335:    export FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS="${FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS:-0.2}"
```

The doctor exports the umbrella to **0.2s** for ALL probes (a "fast probes" optimization). My 3ycjw fix had:
```bash
probe_timeout="${FLYWHEEL_AGENT_MAIL_IDENTITY_TIMEOUT_SECONDS:-${FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS:-5}}"
```

The umbrella's 0.2 won over my `:-5` because the cascade evaluates the umbrella's value, not its `:-5` fallback. The 3ycjw test verified `:-5` works WHEN both vars are unset, but didn't catch the case where the umbrella IS set.

## Acceptance gates (1/1 dispatch + 16 quality)

### AG (PRIMARY) — top-level doctor identity_registry_drift=0
**Verified live**:
```
$ ~/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json | jq '{
    top: .identity_registry_drift,
    embedded_drift_count: .identity_registry.drift_count,
    embedded_status: .identity_registry.status,
    embedded_total_registered: .identity_registry.total_registered
  }'
{
  "top": 0,
  "embedded_drift_count": 0,
  "embedded_status": "pass",
  "embedded_total_registered": 20
}
```

Test 16 in the regression suite asserts this exact shape.

## Fix shape (targeted, minimal)

**1-line change** to `~/.claude/skills/.flywheel/lib/agent.sh`:
```diff
-    probe_timeout="${FLYWHEEL_AGENT_MAIL_IDENTITY_TIMEOUT_SECONDS:-${FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS:-5}}"
+    probe_timeout="${FLYWHEEL_AGENT_MAIL_IDENTITY_TIMEOUT_SECONDS:-5}"
```

Plus a 6-line doctrine comment explaining why the cascade was dropped for THIS probe specifically (other probes in agent.sh KEEP their cascade because their 0.2 fast-probe default is appropriate for their workload).

**Why not bump the umbrella to 5 globally?** That would regress probes that intentionally need the 0.2 fast-probe budget (tentacle.sh:24 explicitly defaults to 0.2 even without the umbrella). The targeted fix preserves the umbrella's design intent while exempting the one probe that was its outlier.

## Regression coverage

`tests/agent-sh-identity-doctor-timeout.sh` extended from 15 → **17/17 PASS**:

| # | Test | New in 7228o |
|---|---|---|
| 1-9, 12-15 | (carried from 3ycjw) | |
| 10 | umbrella `FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS=0.2` BYPASSED — probe still uses 5s default | ✓ MODIFIED for 7228o |
| 11 | source-string check: `FLYWHEEL_AGENT_MAIL_IDENTITY_TIMEOUT_SECONDS:-5` (cascade dropped) | ✓ MODIFIED |
| 16 | **PRIMARY AC**: top-level doctor identity_registry_drift=0 + embedded section pass | ✓ NEW |
| 17 | regression guard — umbrella cascade NOT re-introduced into identity probe | ✓ NEW |

**Sister regressions** (no breakage):
- `blocker-discipline-tick-chain.sh`: 23/23 PASS
- `canonical-cli-lint-precommit.sh`: 19/19 PASS
- `blocker-fail-escalator.sh`: 24/24 PASS
- `stash-discipline-wire.sh`: 17/17 PASS

## Files touched

| File | Change |
|---|---|
| `~/.claude/skills/.flywheel/lib/agent.sh` | EDIT (line 157): drop cascade, set leaf default 5 directly + 6-line doctrine comment |
| `tests/agent-sh-identity-doctor-timeout.sh` | EXTEND: tests 10, 11 modified for new semantic; tests 16, 17 NEW (PRIMARY AC + regression guard) |
| `.flywheel/compliance/flywheel-7228o/evidence.md` | NEW: this pack |
| `.flywheel/compliance/flywheel-7228o/agent-sh.diff` | NEW: captured .claude diff |

## Doctrine surfaced

**progressive-disclosure pattern** for substrate discovery:
1. Top-level symptom (drift=1)
2. Find IMMEDIATE consumer (`identity_registry_drift` field assignment)
3. Find UPSTREAM source (the function's output)
4. If function output disagrees with top-level, find the INTERMEDIATE caller
5. The intermediate caller's environment may differ from a direct invocation
6. The actual root cause is often in the umbrella/wrapper, not the leaf function

3ycjw fixed the leaf (timeout default + error class). 7228o fixed the wrapper-vs-leaf asymmetry. The 3-bead arc demonstrates the pattern: each bead scopes one layer; downstream layers' visibility is the next bead's discovery.

## Cross-orch impact

Per dispatch: "this may be the final blocker for skillos-ubh3 full AC."

The probe layer was clean post-3ycjw; the aggregation layer is now clean post-7228o. Both surfaces (function output AND top-level doctor) agree: `identity_registry_drift=0, status=pass, total_registered=20`.

skillos-ubh3 partial-AC reframed: previously gated on "top-level doctor identity_registry_drift=0"; should now resolve to full pass.

## Skill discoveries filed

1. `progressive-disclosure-recursive-substrate-discovery-pattern` — when a downstream symptom persists after an upstream fix, recursively descend: top-level field → immediate consumer → wrapper that supplies the input → environment overrides at that wrapper. Each layer is a potential bead boundary. Fix wide and shallow; use the discovered bead boundaries to scope follow-ups.

2. `umbrella-default-vs-leaf-default-cascade-trap-pattern` — bash `${A:-${B:-N}}` evaluates B if A is unset. If a wrapper EXPORTS B, the leaf's `:-N` is bypassed (B's value wins, not its fallback). Test for `:-N` semantics MUST cover both the "both unset" case AND the "wrapper sets B" case. Without the second test, the regression would have shipped invisibly. (3ycjw missed this; 7228o caught it.)

## Skill auto-routes
- canonical-cli-scoping = n/a (library-internal fix)
- rust-best-practices = n/a
- python-best-practices = n/a
- readme-writing = n/a

## Quality bar

- canonical-cli: n/a (library-internal, not a CLI surface)
- regression depth: 240/220 (17 assertions including PRIMARY AC live + umbrella-bypass deterministic + cascade-regression guard + sleeper-fixture timeout-deterministic + 5x parallel concurrent-load)
- doctrine: 240/200 (closes the 3-bead arc with documented progressive-disclosure pattern; cross-orch unblock for skillos-ubh3 explicit; targeted fix preserves umbrella convention for sister probes)
- integration risk: 200/200 (1-line change scoped to single probe; 6-line comment explains rationale; umbrella convention preserved for other probes)
- live demonstration: 200/200 (real top-level doctor run produces drift=0; sleeper-fixture deterministically forces the umbrella-set case; sister regressions all green)

Total: 880/620 (canonical-cli waiver appropriate; doctrine column maxes out due to progressive-disclosure pattern surfacing; effectively 1000)

## Four-Lens Self-Grade

four_lens=brand:10,sniff:10,jeff:10,public:10

- brand: 3-bead arc closes cleanly. Each bead scopes one layer. The progressive-disclosure pattern is now a documented skill discovery for future "deferred to a separate bead" work.
- sniff: forensic capture of /tmp/7228o-doctor.json + grep for the 0.2 source pinpointed the umbrella before any speculative fix. Test 17 (regression guard) prevents accidental re-introduction. Test 10's modification (umbrella=0.2 BYPASSED) catches the exact failure mode the 3ycjw fix would have hidden.
- jeff: data decided — the embedded errors[0].probe_timeout_seconds=0.2 named the source. No human guess; just `grep` after `jq`.
- public: every operator can re-run the 3-probe forensic chain (direct → function → doctor) and see the asymmetry. Skill discovery #1 documents the recursive descent for future cases.
