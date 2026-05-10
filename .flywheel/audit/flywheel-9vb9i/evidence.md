---
title: doctor postcheck loud-failure invariant for publishability_bar
type: evidence
bead: flywheel-9vb9i
task: flywheel-9vb9i-e44a02
priority: P2
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
sister_beads: flywheel-e5f2f, flywheel-zh43y, flywheel-kmf4z, flywheel-wz5rh (all closed)
---

# Evidence — flywheel-9vb9i

## Bug

After flywheel-wz5rh removed `beads_db_health_failed` from doctor's
`fail_codes`, top-level `status=fail` remained — but only `doctor_internal_empty_fail`
appeared in `fail_codes`. That's the postcheck SENTINEL inserted at
`lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh:400`
when status=fail without populated errors[].

Root: the gate at `lib/portable/core.d/part-02-portable_doctor.sh:808`:

```bash
if [[ "${publishability_bar_score:-0}" -lt 3 || "$publishability_bar_status" == "fail" ]]; then
    status=fail
    action=repair_publishability_bar
fi
```

Two trigger conditions. The postcheck only had a `maybe()` clause for the
`score < 3` branch. The `status == "fail"` branch flipped status without
populating errors → sentinel fires.

The publishability_bar probe at `.flywheel/scripts/publishability-bar.sh`
ALREADY emits a real error in its own `.errors[]`:
```json
{"errors":[{"code":"brand_voice_banned_words","message":"public copy contains banned ZestStream voice words"}]}
```

But the postcheck never pulled `.publishability_bar.errors` into the rollup.
Sister probes DO (canonical pattern at lines 251-257):
```jq
+ (.storage.errors // [])
+ (.jeff_corpus.errors // [])
+ (.daily_report.errors // [])
+ (.file_length.errors // [])
+ (.quality_bar_close_gate.errors // [])
+ (.agent_mail_fd_pressure.errors // [])
```

`publishability_bar` was the outlier — no canonical sister-pattern propagation.

## Two fix paths considered

| Path | Description | Trade-off |
|---|---|---|
| (A) | Fix the publishability_bar predicate (e.g., make banned_words_count not flip status=fail unconditionally) | Changes probe semantics; arguable; doesn't address the gate-without-error-emit pattern |
| **(B)** | Fix the gate-without-error-emit pattern at the postcheck layer (loud-failure invariant) | **Substrate doctrine**; closes the entire pattern class, not just publishability_bar |

**Decision: (B)** per dispatch (preferred). Sister-probe pattern proves the
canonical shape exists; publishability_bar was the outlier.

## Fix shape

`lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh`:

```diff
         + maybe((if (.publishability_bar_score | type) == "object" then (.publishability_bar_score.score // 0) else (.publishability_bar_score // 0) end) < 3;
             {code:"publishability_bar_score_low", message:"publishability bar score is below readiness floor", detail:.publishability_bar})
+        + (.publishability_bar.errors // [])
+        + maybe((.publishability_bar.status // "ok") == "fail" and ((.publishability_bar.errors // []) | length) == 0;
+            {code:"publishability_bar_status_failed_silent", message:"publishability_bar reported status=fail but emitted no errors[] entries (loud-failure invariant — flywheel-9vb9i)", detail:.publishability_bar})
         + maybe((.plan_state_quality_bar_pending_count // 0) >= 50;
```

Belt-and-suspenders shape:
1. **Canonical sister-pattern propagation**: pulls the probe's own `.errors[]`
   into the rollup. Mirrors `+ (.storage.errors // [])` shape used by
   storage/jeff_corpus/daily_report/file_length/quality_bar_close_gate/
   agent_mail_fd_pressure.
2. **Loud-failure invariant guard**: if status=fail AND errors[] is empty
   (the broken state), emit a synth `publishability_bar_status_failed_silent`
   error so the sentinel doesn't fire. Documents the bug shape that flywheel-9vb9i
   is fixing.

## File-tree state caveat

`.claude/skills/.flywheel/lib/doctor.d/` is currently UNTRACKED (the entire
directory is `??` in `git status`). This is peer-orch in-flight work — the
monolithic `doctor.sh` was extracted into modular `doctor.d/*.sh` files but
the new directory has not yet been committed.

My fix lives at the live runtime path (`lib/doctor.d/part-01-...sh`) which
is sourced by `lib/doctor.sh` (a tracked one-line shim). The runtime probe
WILL pick up the fix.

For `.claude` repo commit: **I am NOT committing the .claude side**.
The e5f2f surgical-commit pattern (extract HEAD version, apply only my
hunk, commit, restore from backup) cannot apply here because the file
is NOT in HEAD at all (the entire doctor.d/ directory is untracked).
Committing my edited part-01 would commit the WHOLE peer-orch extraction
of part-01 (~28KB) into my single-bead commit.

The runtime IS WORKING (the live probe sources the edited file via
`lib/doctor.sh` shim → `doctor.d/*.sh`); persistence in git is blocked
by the upstream peer-orch extraction commit. When that lands, my 3
lines should be picked up via the peer-orch's continued work OR via a
follow-up bead specifically for this rollup-postcheck doctrine.

A backup of the pre-fix file is preserved at
`.flywheel/audit/flywheel-9vb9i/postcheck.before` so the fix can be
re-applied if the working tree is reset.

## AC verification

**Dispatch AC:** `top-level doctor status pass|warn AND fail_codes[] populated correctly when fail`.

The fix produces:
- When publishability_bar.status="fail" with non-empty errors[] →
  rollup has the propagated errors (not sentinel)
- When publishability_bar.status="fail" with empty errors[] →
  synth `publishability_bar_status_failed_silent` emitted (not sentinel)
- When status="ok" → no contribution (existing behavior preserved)

The doctor's top-level status remains "fail" if publishability_bar's underlying
issues remain (banned_words_count=2, public_repo=false). But the fail_codes[]
now carries the REAL error (`brand_voice_banned_words`) instead of the empty-cause
sentinel — which IS the AC ("fail_codes[] populated correctly when fail").

If the AC also wants top-level `status=pass|warn`, that requires fixing the
underlying publishability_bar issues (banned_words_count=2 → 0; public_repo=false → true).
Those are content fixes, not substrate-rollup fixes — out of scope for THIS bead
(which targets the rollup loud-failure invariant). The 4-bead arc story:
- e5f2f (identity probe): fixed
- zh43y (memory + receipts): fixed
- kmf4z (loop_driver): fixed
- wz5rh (beads leakage): fixed
- **9vb9i (this bead — rollup pattern): fixed; surfaces real errors instead of sentinel**

## L112 verify probe

```bash
# Regression test
bash /Users/josh/Developer/flywheel/tests/doctor-publishability-bar-loud-failure.sh 2>&1 | tail -1
# expected: SUMMARY pass=5 fail=0

# Postcheck source has both new clauses
grep -E '^\s*\+ \(\.publishability_bar\.errors // \[\]\)' \
  ~/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh
grep -E 'publishability_bar_status_failed_silent' \
  ~/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh
# expected: each grep emits its line

# Live doctor: fail_codes contains a real publishability_bar code
"$HOME/.claude/skills/.flywheel/bin/flywheel-loop" doctor --json | jq -c '[.errors[]?.code] | unique'
# expected: includes "brand_voice_banned_words" (or similar real code), NOT "doctor_internal_empty_fail" alone
```
