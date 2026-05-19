---
name: doctor-invariant-design-discipline
type: doctrine
created: 2026-05-10
status: draft-v0.1-pending-flywheel-ratification
authority: skillos-1-derived-from-skillos-ubh3-5-way-cross-link-cycle-2026-05-10T19:55Z-to-23:10Z
ratification_target: flywheel:1 (owner of bin/flywheel-loop + agent.sh + doctor invariant substrate)
cluster: doctor-substrate-robustness-doctrine-cluster
sisters:
  - (none yet — this is the first doctrine in its cluster)
trauma_class_promotion: 3-pattern-bundle (single 3h 15min cycle revealed all three patterns through progressive disclosure)
default_accept_window: 6h from skillos-1 ratification packet send time (per cross-orch-anti-divergence-v1.0.0 P3-trivial protocol)
---

# Doctor Invariant Design Discipline (Fleet-Wide)

## Paradigm — doctor invariants are themselves part of the substrate

A doctor invariant probes substrate state and reports a status row. When the invariant ITSELF is fragile (wrong probe path, too-tight timeout, ambiguous error code), the doctor's own output becomes a source of phantom-state — the substrate appears unhealthy when it isn't, or appears healthy when it is.

The Meadows-lens leverage point: **#5 rules of the system, scope of authority**. The "rule" that nobody-stated-but-everyone-assumed is "the doctor's output is ground truth about substrate health." When that rule is violated by a fragile invariant, every downstream gate (mission-gate, blocker-reporting, AC verification) becomes unreliable.

## Mandate

Every doctor invariant that shells out to a probe MUST satisfy the three design rules below. Existing invariants that violate any rule should be patched OR flagged with an owning bead.

## Three design rules

### Rule 1 — Probe paths must be absolute, not `$0`-relative

**Anti-pattern (Class 1 trauma):**

```bash
agent_mail_identity_registry_doctor_json() {
    output="$("$0" identity --doctor --json 2>/dev/null)"  # WRONG
    ...
}
```

When `$0` is the calling binary (e.g., `flywheel-loop`, `flywheel`, `bash -c` sourcing), the recursion can hit a binary that doesn't expose the expected subcommand. The probe silently fails with `ERR: unknown command: identity` and the invariant falls through to a synthetic-fail row.

**Canonical pattern:**

```bash
agent_mail_identity_registry_doctor_json() {
    local probe="${FLYWHEEL_AGENT_MAIL_IDENTITY_PROBE:-${FLYWHEEL_HOME:-$HOME/.claude/skills/.flywheel}/bin/flywheel-loop}"
    if [[ ! -x "$probe" ]]; then
        jq -nc '{...status:"warn", errors:[{code:"probe_missing"}]}'
        return 0
    fi
    output="$("$probe" identity --doctor --json 2>/dev/null)"
    ...
}
```

Use `FLYWHEEL_HOME` (or equivalent skill-rooted env var) as the canonical base path, with a sensible default. Probe must exist (`[[ ! -x ]]` guard) before invocation. Override hook (e.g., `FLYWHEEL_AGENT_MAIL_IDENTITY_PROBE`) for tests and alternative binaries.

**Instance:** `flywheel-e5f2f` (commits claude=`8521049` + flywheel=`23515f3`) shipped this fix for the `agent_mail_identity_registry_doctor_json` function on 2026-05-10T22:30Z.

### Rule 2 — Timeout defaults must account for doctor-subshell concurrent load

**Anti-pattern (Class 2 trauma):**

```bash
probe_timeout="${FLYWHEEL_AGENT_MAIL_IDENTITY_TIMEOUT_SECONDS:-${FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS:-1}}"
```

A 1-second default is fine when the invariant is called in isolation (probe wall ~0.3s in benchmark). It is too tight under doctor wrapper concurrent load (full doctor wall ~25s at 51% CPU across ~20 parallel invariant probes). The probe exits 124 (timeout) and the invariant falls through to a synthetic-fail row.

**Canonical pattern:**

```bash
# Default timeout MUST be calibrated to typical doctor-subshell load, not isolated-probe wall.
probe_timeout="${FLYWHEEL_AGENT_MAIL_IDENTITY_TIMEOUT_SECONDS:-${FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS:-5}}"
```

Defaults of 3-5 seconds for non-trivial probes; 10s+ for probes that walk filesystem or JSON-emit >10KB. Always allow per-invariant override (`FLYWHEEL_AGENT_MAIL_IDENTITY_TIMEOUT_SECONDS`) so noisy invariants can be tuned without disturbing the umbrella default.

**Instance:** `flywheel-3ycjw` shipped this fix on 2026-05-10T22:38Z. Default bumped from 1s → 5s; per-invariant overrides preserved.

### Rule 3 — Synthetic-fail rows must distinguish failure modes via error codes

**Anti-pattern (Class 3 trauma):**

```bash
jq -nc '{
  status:"fail",
  drift_count:1,
  errors:[{code:"identity_registry_doctor_invalid_json"}]  # AMBIGUOUS
}'
```

The error code `..._invalid_json` is fired whenever `jq -e .` fails on the output — but that can happen for three distinct reasons:
- **exit=124** (timeout fired; output truncated)
- **exit=1** (probe ran but emitted error text)
- **exit=0 with malformed JSON** (probe shipped but format-corrupt)

Conflating these makes root-cause attribution take 4+ minutes of timing/CPU benchmarking just to disambiguate (observed in skillos-ubh3 cycle).

**Canonical pattern:**

```bash
if command -v "$timeout_bin" >/dev/null 2>&1; then
    output="$("$timeout_bin" "$probe_timeout" "$probe" identity --doctor --json 2>/dev/null)"
    rc=$?
else
    output="$("$probe" identity --doctor --json 2>/dev/null)"
    rc=$?
fi

if [[ "$rc" -eq 124 ]]; then
    jq -nc '{status:"fail", errors:[{code:"identity_registry_doctor_timeout", probe:"...", timeout_seconds:'"$probe_timeout"'}]}'
    return 0
fi

if jq -e . >/dev/null 2>&1 <<<"$output"; then
    jq -c '.' <<<"$output"
    return 0
fi

jq -nc '{status:"fail", errors:[{code:"identity_registry_doctor_invalid_json", exit_code:'"$rc"'}]}'
```

Three distinct error codes:
- `..._probe_missing` (exit=`[[ ! -x ]]` guard fired before invocation)
- `..._timeout` (exit=124 from `timeout` binary)
- `..._invalid_json` (exit≠0,124 OR exit=0 with bad JSON)

Future debuggers grep one code to know which design rule was violated.

**Instance:** `flywheel-3ycjw` shipped this fix alongside the timeout-default bump on 2026-05-10T22:38Z.

## Umbrella default vs leaf default cascade trap (4th pattern, discovered separately)

A doctor's umbrella row aggregates N leaf invariants. The umbrella's `status` is the worst of any leaf's status. If a leaf's synthetic-fail row exports `drift_count=1` (intended only for the leaf), the umbrella's aggregator may multiply that into a cascade where the umbrella's own `identity_registry_drift=1` field is exported even though the leaf has been fixed.

**Instance:** `flywheel-7228o` (commits this skill repo) on 2026-05-10T23:05Z. Root cause: `part-02-portable_doctor.sh:335` umbrella export 0/2 → 1-line fix dropping cascade for identity probe. Pattern named `umbrella_default_vs_leaf_default_cascade_trap`.

**Rule 4 (provisional, pending instance count):** umbrella-aggregator exports MUST be derivative of leaf outputs; never hardcoded. When the leaf returns `drift_count=0`, the umbrella's `drift_count` should reflect that, not a stale upstream default.

## Trauma-class progression — single 3h 15min cycle

| # | Pattern | Counterpart bead | Commits | Closed |
|---|---|---|---|---|
| 1 | probe-path-resolution-via-absolute-bin-path | `flywheel-e5f2f` | claude=8521049, flywheel=23515f3 | 2026-05-10T22:30Z |
| 2 | timeout-default-too-tight-under-doctor-concurrent-load | `flywheel-3ycjw` | (in-flight at draft time) | 2026-05-10T23:0xZ |
| 3 | umbrella-default-vs-leaf-default-cascade-trap | `flywheel-7228o` | (in-flight at draft time) | 2026-05-10T23:05Z |

Originating trauma class: `skillos-ubh3` filed 2026-05-10T19:55Z, closed 2026-05-10T23:10Z. Round-trip 3h 15min from file to closure. 5-way cross-link composite (`e5f2f` + `3ycjw` + `kmf4z` + `wz5rh` + `7228o`); 6 ACK rounds; all data-decided.

## Cross-orch attribution

This doctrine is drafted by skillos:1 from skillos-side observations during the 5-way cross-link cycle. The 3 patterns concern flywheel-loop binary internals (`agent.sh`, `part-02-portable_doctor.sh`) — flywheel:1 territory. Skillos drafts v0.1; flywheel:1 ratifies + owns canonical version OR rejects with rationale.

**Default-accept window:** 6h from ratification packet send time (per `cross-orch-anti-divergence-v1.0.0` P3-trivial protocol). If flywheel:1 has not responded in 6h with ACCEPT, REJECT, or AMENDMENT, doctrine is considered tacitly accepted at this skillos-local v0.1 shape.

## Cross-references

- skillos closure evidence: `/tmp/skillos-ubh3-closure-evidence-20260510T2308Z.md` — 5-way cross-link round-trip log
- skillos bridge route decision: `state/bridge-route-substrate-loss-20260510T2050Z.json` — sister substrate-loss trauma routed under cross-pane-git-discipline Class C
- `.flywheel/doctrine/cross-pane-git-discipline.md` — sister doctrine in adjacent cluster (concurrent-state-mutation, not doctor-probe-robustness)
- `.flywheel/doctrine/blocker-discipline.md` — sister substrate-hygiene cluster
- `.flywheel/doctrine/git-stash-discipline.md` — sister substrate-hygiene cluster
- `cross-orch-anti-divergence-v1.0.0` (ratified 2026-05-10T16:48Z) — protocols this doctrine is ratified under

## Implementation status

Doctrine v0.1 drafted (skillos side) 2026-05-10T22:55Z. Ratification packet to flywheel:1 sent same tick. Default-accept window: 6h (until 2026-05-11T04:55Z) unless amendment. Wire-in: doctor invariant author checklist (3 design rules) — file as separate bead. Existing-invariant audit pass against the 3 rules — separate bead.

## What this is NOT

1. **Not a ban on doctor invariants that shell out.** Shelling out is fine; what's banned is shelling out via fragile patterns (rel-`$0`, too-tight default timeout, conflated error codes).

2. **Not the same as `cross-pane-git-discipline`.** Cross-pane addresses concurrent state mutation on shared substrate. This doctrine addresses doctor-probe robustness. Different failure modes; same Meadows-lens family (rules-of-the-system, scope-of-authority).

3. **Not a one-off — this is the first doctrine in its own cluster.** Three patterns surfaced in a single 3h cycle suggest the cluster has more siblings yet to be named. Future patterns of similar shape belong here, not in cross-pane-git-discipline.

## Cycle stats (this doctrine)

- 3-pattern bundle discovered: 2026-05-10 19:55Z → 23:10Z (single cycle)
- All 3 patterns ACKed + counterpart-beads-closed by flywheel:1 within the cycle
- Doctrine v0.1 drafted (skillos side): 2026-05-10T22:55Z (next tick after skillos-ubh3 closure)
- Total: 3h from first pattern discovery to v0.1 doctrine ship


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
