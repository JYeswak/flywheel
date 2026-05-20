---
name: doctor-invariant-author-checklist
type: checklist
created: 2026-05-10
status: v1.0-author-facing-companion-to-doctor-invariant-design-discipline
source_doctrine: .flywheel/doctrine/doctor-invariant-design-discipline.md
authority: flywheel-8n3ua (codification bead for doctrine ratification wire-in)
cluster: doctor-substrate-robustness-doctrine-cluster
applies_to: any new doctor invariant function that shells out to a probe
---

# Doctor Invariant Author Checklist

**When to use:** before merging any doctor invariant function that shells out to a probe (binary, script, subshell). One pass through this checklist per invariant.

**When NOT to use:** invariants that only read in-process state (no exec, no subshell). The 3 rules below all address shell-out fragility — they don't apply to pure in-process probes.

## Quick verification (run before commit)

```bash
# From the file you're authoring, exit 0 if all 3 rules pass:
INVARIANT_FILE=path/to/your-invariant.sh
INVARIANT_FN=your_invariant_function_name

# Rule 1: no $0-relative probes
grep -n '"\$0"' "$INVARIANT_FILE" && echo "FAIL: \$0-relative probe found — see Rule 1" || echo "Rule 1: OK"

# Rule 2: timeout default >= 3s
grep -nE 'TIMEOUT_SECONDS:-[12]\b' "$INVARIANT_FILE" && echo "FAIL: timeout default <3s — see Rule 2" || echo "Rule 2: OK"

# Rule 3: 3 distinct error codes (probe_missing + timeout + invalid_json)
for code in probe_missing timeout invalid_json; do
  grep -q "${code}" "$INVARIANT_FILE" || echo "FAIL: missing error code '${code}' — see Rule 3"
done
```

All three checks pass = invariant satisfies the discipline.

## Rule 1 — Probe paths MUST be absolute, not `$0`-relative

**Trigger:** any `"$0"`, `$BASH_SOURCE`, or `dirname $0` used as the probe path.

**Why it fails:** when the calling binary changes (`flywheel-loop` invoked from a wrapper, or `bash -c` sourcing the function), `$0` resolves to something the probe doesn't recognize. The probe silently fails with `ERR: unknown command: <subcommand>` and the invariant falls through to a synthetic-fail row that is **not actually substrate failure** — it is invariant failure.

**Anti-pattern:**

```bash
output="$("$0" identity --doctor --json 2>/dev/null)"   # WRONG
```

**Canonical pattern:**

```bash
local probe="${FLYWHEEL_AGENT_MAIL_IDENTITY_PROBE:-${FLYWHEEL_HOME:-$HOME/.claude/skills/.flywheel}/bin/flywheel-loop}"
if [[ ! -x "$probe" ]]; then
    jq -nc '{...,status:"warn",errors:[{code:"...probe_missing"}]}'
    return 0
fi
output="$("$probe" identity --doctor --json 2>/dev/null)"
```

**Three requirements:**

1. **Skill-rooted env var as base** — use `$FLYWHEEL_HOME` (or equivalent for non-flywheel skills) with a sensible default. Never `$0`.
2. **Per-invariant override hook** — name a `FLYWHEEL_<INVARIANT>_PROBE` env var so tests can swap in fixtures and alternative binaries.
3. **`[[ ! -x ]]` guard before invocation** — emit a `status:"warn"` + `code:"..._probe_missing"` row if the probe binary doesn't exist or isn't executable. Do not let the missing-probe case fall through to the generic invalid-json error.

**Canonical instance:** `flywheel-e5f2f` (commits `claude=8521049` + `flywheel=23515f3`, 2026-05-10T22:30Z) — fix for `agent_mail_identity_registry_doctor_json`.

## Rule 2 — Timeout defaults MUST account for doctor-subshell concurrent load

**Trigger:** any `timeout` invocation with a default value derived from `FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS` (or sibling umbrella default) of 1-2s.

**Why it fails:** an isolated-probe wall of ~0.3s sounds like 1s is plenty of headroom. But under full-doctor concurrent load (~20 parallel invariants at ~51% CPU), the same probe takes 5-15s. A 1s timeout fires `exit 124` and the invariant emits a synthetic-fail row that is **not actually substrate failure** — it is invariant timeout.

**Anti-pattern:**

```bash
probe_timeout="${FLYWHEEL_AGENT_MAIL_IDENTITY_TIMEOUT_SECONDS:-${FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS:-1}}"   # WRONG (1s)
```

**Canonical pattern:**

```bash
# Default timeout calibrated to typical doctor-subshell load, NOT isolated-probe wall.
probe_timeout="${FLYWHEEL_AGENT_MAIL_IDENTITY_TIMEOUT_SECONDS:-${FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS:-5}}"
```

**Calibration table:**

| Probe class | Default timeout |
|---|---|
| Trivial (single SQL select, single grep) | 3s |
| Non-trivial (multi-step JSON emit) | 5s |
| Heavy (walks filesystem, emits >10KB JSON) | 10s+ |

**Two requirements:**

1. **Default ≥ 3s** for any non-trivial probe — calibrate against observed doctor-subshell wall under typical fleet load, not isolated benchmark.
2. **Per-invariant override preserved** — keep the `FLYWHEEL_<INVARIANT>_TIMEOUT_SECONDS` lookup so noisy individual invariants can be tuned without disturbing the umbrella default.

**Canonical instance:** `flywheel-3ycjw` (2026-05-10T22:38Z) — default bumped 1s → 5s; per-invariant overrides preserved.

## Rule 3 — Synthetic-fail rows MUST distinguish failure modes via error codes

**Trigger:** a single `errors:[{code:"...invalid_json"}]` row firing for multiple distinct failure modes.

**Why it fails:** the same `..._invalid_json` row can be emitted when (a) `timeout` fires at exit=124, (b) the probe ran but emitted error text at exit=1, or (c) the probe shipped but JSON-format-corrupted at exit=0. A future debugger cannot grep `..._invalid_json` and know what actually broke — they must rerun the probe with `--debug` flags and benchmark timing/CPU to disambiguate. Observed in skillos-ubh3 cycle: 4+ minutes of root-cause attribution per incident.

**Anti-pattern:**

```bash
jq -nc '{
    status:"fail",
    drift_count:1,
    errors:[{code:"identity_registry_doctor_invalid_json"}]  # AMBIGUOUS — fires for 3 distinct modes
}'
```

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
    jq -nc '{status:"fail", errors:[{code:"identity_registry_doctor_timeout", probe:"'"$probe"'", timeout_seconds:'"$probe_timeout"'}]}'
    return 0
fi

if jq -e . >/dev/null 2>&1 <<<"$output"; then
    jq -c '.' <<<"$output"
    return 0
fi

jq -nc '{status:"fail", errors:[{code:"identity_registry_doctor_invalid_json", exit_code:'"$rc"'}]}'
```

**Three required error codes per shell-out invariant:**

| Code suffix | Fires when | Distinguishing field |
|---|---|---|
| `..._probe_missing` | `[[ ! -x "$probe" ]]` guard fires before invocation | `code` only |
| `..._timeout` | `timeout` binary exit=124 | `timeout_seconds` |
| `..._invalid_json` | exit≠0,124 OR exit=0 with bad JSON | `exit_code` |

A future debugger greps one code, knows which design rule was violated, and which env var to tune or which dependency to install.

**Canonical instance:** `flywheel-3ycjw` (2026-05-10T22:38Z) — shipped alongside the timeout-default bump.

## Rule 4 (provisional) — Umbrella aggregator exports MUST be derivative of leaf outputs

**Status:** provisional — pending second instance count. One observation so far.

**Trigger:** a doctor's umbrella row aggregates N leaf invariants. Umbrella exports include `<leaf>_drift_count` or similar leaf-derived fields.

**Why it fails:** if the umbrella's aggregator hardcodes a default for the leaf-derived field instead of reading the leaf's actual output, the leaf can return `drift_count=0` (fixed) while the umbrella still reports `drift_count=1` (stale). Downstream gates trust the umbrella, observe stale `drift_count=1`, fire false alarms.

**Anti-pattern:** (`part-02-portable_doctor.sh:335`, pre-`flywheel-7228o`)

```bash
# umbrella aggregator
echo "{\"identity_registry_drift\":1}"   # hardcoded — does not read leaf output
```

**Canonical pattern:**

```bash
# umbrella aggregator
leaf_drift="$("$0" leaf-invariant --doctor --json | jq -r '.drift_count // 0')"
jq -nc --argjson d "$leaf_drift" '{identity_registry_drift:$d}'
```

**Requirement:** any field the umbrella exports that names a specific leaf invariant MUST come from that leaf's actual output, not a hardcoded default.

**Canonical instance:** `flywheel-7228o` (2026-05-10T23:05Z) — 1-line fix dropping cascade for identity probe at `part-02-portable_doctor.sh:335`. Pattern named `umbrella_default_vs_leaf_default_cascade_trap`.

## Author self-check before commit

Run the [Quick verification](#quick-verification-run-before-commit) snippet at the top of this checklist. If all 3 grep checks pass + Rule 4 considered when umbrella aggregator touched, the invariant satisfies the discipline.

For an existing invariant audit pass (separate bead), grep across the doctor invariant tree:

```bash
# Anti-pattern surface — should return 0 lines after full audit
grep -rE '"\$0"\s+identity\s+--doctor' .flywheel/ ~/.claude/skills/.flywheel/

# Tight-timeout surface — should return 0 lines for non-trivial probes
grep -rE 'TIMEOUT_SECONDS:-[12]\b' .flywheel/ ~/.claude/skills/.flywheel/

# Generic-error surface — find invariants with <3 distinct error codes
for f in $(find .flywheel ~/.claude/skills/.flywheel -name '*-doctor*' -type f); do
    codes="$(grep -oE 'code:"[a-z_]+"' "$f" | sort -u | wc -l)"
    [[ "$codes" -lt 3 ]] && echo "$f: only $codes distinct error codes"
done
```

## Cross-references

- **Source doctrine:** `.flywheel/doctrine/doctor-invariant-design-discipline.md` (v0.1 drafted 2026-05-10T22:55Z; ratification window closes 2026-05-11T04:55Z under cross-orch-anti-divergence-v1.0.0 P3-trivial)
- **Sister doctrine (concurrent state mutation):** `.flywheel/doctrine/cross-pane-git-discipline.md`
- **Sister doctrines (substrate hygiene):** `.flywheel/doctrine/blocker-discipline.md`, `.flywheel/doctrine/git-stash-discipline.md`
- **Canonical instance beads:** `flywheel-e5f2f` (Rule 1), `flywheel-3ycjw` (Rules 2+3), `flywheel-7228o` (Rule 4 provisional)
- **Originating trauma class:** `skillos-ubh3` (2026-05-10T19:55Z → 23:10Z, 3h 15min round-trip, 5-way cross-link composite, 6 ACK rounds, all data-decided)

## Trauma-class lineage

| # | Pattern | Counterpart bead | Closed |
|---|---|---|---|
| 1 | probe-path-resolution-via-absolute-bin-path | `flywheel-e5f2f` | 2026-05-10T22:30Z |
| 2 | timeout-default-too-tight-under-doctor-concurrent-load | `flywheel-3ycjw` | 2026-05-10T22:38Z |
| 3 | umbrella-default-vs-leaf-default-cascade-trap | `flywheel-7228o` | 2026-05-10T23:05Z |

Three patterns surfaced in a single 3h cycle. Future patterns of similar shape (doctor-probe-robustness, not concurrent-state-mutation) belong in this cluster, not in `cross-pane-git-discipline`.

## Anti-patterns at a glance

| Rule | Anti-pattern signature | Canonical replacement |
|---|---|---|
| 1 | `"$0" identity --doctor` | `"${FLYWHEEL_HOME}/bin/flywheel-loop" identity --doctor` + `[[ -x ]]` guard |
| 2 | `TIMEOUT_SECONDS:-1` | `TIMEOUT_SECONDS:-5` (or 3-10s per probe class) |
| 3 | one `..._invalid_json` code for everything | three codes: `..._probe_missing` / `..._timeout` / `..._invalid_json` |
| 4 (prov) | hardcoded `drift_count:1` in umbrella | `--argjson d "$(jq -r '.drift_count // 0' <<<"$leaf")"` |


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
