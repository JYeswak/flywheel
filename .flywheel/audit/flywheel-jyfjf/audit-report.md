---
title: Existing doctor invariants audit against the 3 design rules
type: audit-report
created: 2026-05-10
bead: flywheel-jyfjf
parent_doctrine: .flywheel/doctrine/doctor-invariant-design-discipline.md
parent_checklist: .flywheel/doctrine/doctor-invariant-author-checklist.md
sister_bead_closed: flywheel-ffyyx (agent.sh 4 invariants fixed)
follow_up_bead_filed: see "Recommendation" section
---

# Existing Doctor Invariants Audit

**Scope:** every shell-out doctor invariant in the substrate sourced by `flywheel-loop`:
- `bin/flywheel-loop` binary (the umbrella entrypoint)
- `lib/*.sh` (38 module files)
- `lib/doctor.d/*.sh` (doctor-specific modules)
- `lib/portable/core.d/*.sh` (portable-tier modules)

**Method:** the checklist's quick-verification grep predicate, run as-is against the full scope. Per-rule audits, then per-invariant compliance verdict.

## Summary by rule

| Rule | Pre-doctrine (estimated) | Post-3ycjw + post-ffyyx | Status |
|---|---:|---:|---|
| **Rule 1** — probe paths not `$0`-relative | 1 violation (e5f2f scope) | **0 violations** | ✅ CLEAN — propagation complete |
| **Rule 2** — timeout default ≥3s | 9 violations (5 sister + 4 known) | **5 violations remaining** | ⚠️ 4 of 9 fixed; 5 sister gaps remain |
| **Rule 3** — distinct timeout/invalid_json codes | 9 violations | **5 violations + schema-divergent cases** | ⚠️ 4 of 9 fixed; 5 sister + 2 schema-divergent |
| **Rule 4** (provisional) — umbrella aggregator | 1 violation (7228o) | 0 known violations | ✅ canonical instance fixed; deeper audit pending v1.1 |

## Per-invariant compliance matrix

### ✅ Fully compliant (5 invariants)

| Invariant | File | Rules 1/2/3 | Compliant since |
|---|---|---|---|
| `agent_mail_identity_registry_doctor_json` | lib/agent.sh:141 | ✅✅✅ | flywheel-3ycjw |
| `agent_mail_fd_pressure_json` | lib/agent.sh:3 | ✅✅✅ | flywheel-ffyyx |
| `orphaned_mcp_tool_call_json` | lib/agent.sh:47 | ✅✅✅ | flywheel-ffyyx |
| `agent_browser_leak_doctor_json` | lib/agent.sh:91 | ✅✅✅ | flywheel-ffyyx |
| `agent_mail_registration_broadcast_doctor_json` | lib/agent.sh:207 | ✅✅✅ | flywheel-ffyyx |

### ⚠️ Rules 2+3 violations (5 invariants in 4 files)

| Invariant | File | Line | Rule 2 default | Rule 3 codes present | Rule 3 missing |
|---|---|---:|---|---|---|
| `bead_quality_mining_doctor_json` | lib/bead.sh | 31 | `:-2` | `bead_quality_mining_invalid_json` | `_probe_missing` + `_timeout` |
| `canonical_doctrine_propagation_json` | lib/canonical.sh | 195 | `:-1` | (uses `error:"..."` string, not `errors:[{code}]` schema) | ALL — schema-divergent |
| `memory_rule_gate_parity_doctor_json` | lib/memory.sh | 208 | `:-1` | `memory_rule_gate_parity_detector_missing` + `_invalid_json` (in `warning:` string, not `warnings:[{code}]`) | `_timeout` + canonical schema migration |
| `state_md_miner_doctor_json` | lib/memory.sh | 241 | `:-1` | `state_md_miner_missing` + `state_md_miner_invalid_json` (in `warnings:[{code}]`) | `_timeout` |
| `check_beads_db_health` (sub-probe) | lib/doctor.d/part-02-… | 16 | `:-1` | (sub-probe inside multi-step check; emits via `br_db_corruption_monitor` payload nest) | `_timeout` distinction unclear at sub-probe layer |

### 🟢 Rule 1 compliance — fleet-wide audit clean

```bash
$ grep -nE '"\$0"\s+[a-z]+\s+--doctor|"\$0"\s+--doctor' \
    ~/.claude/skills/.flywheel/lib/*.sh \
    ~/.claude/skills/.flywheel/lib/doctor.d/*.sh \
    ~/.claude/skills/.flywheel/lib/portable/core.d/*.sh
# (no output — 0 matches)
```

**Rule 1 propagation is complete.** Every shell-out probe in scope uses `$FLYWHEEL_HOME`, `$REPO_ABS`, or absolute path resolution. The `flywheel-e5f2f` fix pattern is universal.

### Files audited but no invariant emissions found (28 files)

Files in scope that contain no `TIMEOUT_SECONDS` references or shell-out invariant patterns:
`autoloop-executor.sh, callback.sh, canonical-cli-helpers.sh, common.sh, daily.sh, doctor.sh, drift-status.sh, fleet.sh, jeff.sh, loop.sh, misc.sh, mission.sh, parse.sh, polish.sh, portable.sh, print.sh, reconcile.sh, render.sh, repo.sh, session.sh, skill-discovery.sh, step4i-coherence.sh, storage.sh, tentacle.sh, wire.sh, doctor.d/part-01, doctor.d/part-03, portable/core.d/part-01, portable/core.d/part-03`

These files either don't emit doctor invariants OR emit them via fully-canonical patterns without timeouts (e.g., pure in-process checks). The 3-rule discipline only applies to shell-out probes.

## Schema-divergence findings (sub-audit)

Beyond the 3 design rules, the audit surfaced **2 schema-divergent invariants** that don't follow the canonical envelope shape (`errors:[{code:"..."}]` / `warnings:[{code:"..."}]` arrays-of-objects):

1. **`canonical_doctrine_propagation_json`** (lib/canonical.sh:181) — emits `error:"flywheel-doctrine-sync probe failed"` as a **top-level string field**, not `errors:[{code:"..."}]`. This means downstream consumers (umbrella aggregators, error-code-routing logic) cannot grep a stable error code. Sub-finding: needs schema migration to canonical `errors[]` shape AND addition of all 3 distinct codes per Rule 3.

2. **`memory_rule_gate_parity_doctor_json`** (lib/memory.sh:200) — emits `warning:"memory_rule_gate_parity_detector_missing"` as a **top-level string field**, not `warnings:[{code:"..."}]`. Same downstream-routing problem. Sub-finding: needs schema migration to canonical `warnings[]` shape AND addition of `_timeout` code.

These divergences pre-date the doctrine and would have been hard to spot without the audit pass.

## Rule 4 (provisional) — umbrella aggregator survey

**Scope:** `lib/portable/core.d/part-02-portable_doctor.sh` — the umbrella aggregator file. `flywheel-7228o` fixed the cascade for the identity probe at line 335. Deeper audit of all umbrella-export sites is **out of scope** for this audit pass — Rule 4 is still provisional (1-instance), and a full audit would require either:
- 2nd canonical instance to firm up the rule pattern, OR
- Doctrine promotion of Rule 4 from provisional to canonical (would itself require Joshua/skillos-1 sign-off)

Recommendation: defer Rule 4 audit until Rule 4 is non-provisional.

## Recommendation: file follow-up bead for the 5-invariant bundle

The 5 remaining Rules 2+3 violations follow the same fix pattern as `flywheel-ffyyx` (which fixed 4 sister invariants in agent.sh):

- Bump timeout default `:-1` (or `:-2`) → `:-5`
- Drop `FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS` umbrella fallback (it's tuned for "fast probes")
- Add `local probe_rc=0` + `|| probe_rc=$?` capture
- Split post-jq-fail branch by rc=124 → `<inv>_timeout` distinct from `_invalid_json`
- For the 2 schema-divergent cases: also migrate top-level `error:"..."` / `warning:"..."` strings to canonical `errors:[{code:"..."}]` / `warnings:[{code:"..."}]` array-of-object shape

**Estimated effort:** 60-90 min for the 5-invariant bundle. The pattern is identical 4× then schema-migration discipline for the 2 outliers.

**Filed as:** `flywheel-0qkjj` (follow-up bead — see L52 receipt below).

## Audit verification predicate (post-fix, re-runnable)

```bash
# Rule 2 verification — must return 0
grep -cE 'TIMEOUT_SECONDS:-[12]\b' \
    ~/.claude/skills/.flywheel/bin/flywheel-loop \
    ~/.claude/skills/.flywheel/lib/*.sh \
    ~/.claude/skills/.flywheel/lib/doctor.d/*.sh \
    ~/.claude/skills/.flywheel/lib/portable/core.d/*.sh

# Rule 3 verification — every invariant function should have BOTH _invalid_json AND _timeout
for fn in bead_quality_mining_doctor_json canonical_doctrine_propagation_json \
          memory_rule_gate_parity_doctor_json state_md_miner_doctor_json check_beads_db_health; do
  # Search bash variable assignments OR literal jq strings
  has_timeout=$(grep -cE "(code:\"|error_code=\")${fn%_json}.*_timeout" \
    ~/.claude/skills/.flywheel/lib/*.sh ~/.claude/skills/.flywheel/lib/doctor.d/*.sh)
  [[ "$has_timeout" -eq 0 ]] && echo "GAP: $fn missing _timeout code"
done
```

When both checks return 0/empty, the 5-invariant bundle is closed.

## Audit grep refinement noted (checklist v1.1)

The checklist's Rule 3 grep matches literal `code:"<inv>_timeout"` strings but misses the canonical `error_code="..."` bash-variable form. Both forms emit identical JSON at runtime, but the source-grep treats them differently. The audit verification predicate above widens to `(code:"|error_code=")` for full coverage.

**Carry-over from `flywheel-ffyyx` evidence:** the checklist v1.1 refinement is filed informally (skill discovery `sd-checklist-rule3-grep-widen-to-error_code-variable-form-v1.1-refinement`). This audit confirms the refinement is operationally necessary, not just cosmetic.

## Cross-references

- **Source doctrine:** `.flywheel/doctrine/doctor-invariant-design-discipline.md`
- **Author-facing checklist:** `.flywheel/doctrine/doctor-invariant-author-checklist.md` (flywheel-8n3ua)
- **Canonical instances:** flywheel-e5f2f (Rule 1) + flywheel-3ycjw (Rules 2+3 identity probe) + flywheel-7228o (Rule 4 provisional) + flywheel-ffyyx (Rules 2+3 × 4 sister invariants in agent.sh)
- **Audit scope (files):** 38 files in lib/ + bin/flywheel-loop; 10 contain TIMEOUT_SECONDS references; 5 contain Rules 2+3 violations
- **Sister bead surfacer:** flywheel-8n3ua's checklist self-verification (the meta-pattern: checklist surfaces gaps → audit confirms across wider scope → follow-up bead fixes)
- **Follow-up bead:** flywheel-0qkjj (5-invariant bundle fix + 2-case schema migration)
