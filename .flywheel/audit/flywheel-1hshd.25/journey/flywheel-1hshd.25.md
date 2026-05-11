# Journey: flywheel-1hshd.25

## Phase 1: baseline probe
- Native has --schema ONLY (different shape: metadata_fields/output_fields, no .command/mode field)
- Native does NOT have --info/--doctor/--examples or any scaffold verbs
- Native owns top-level --self-test/--repo/--doc flags

## Phase 2: variant choice
- **PARTIAL-BYPASS** (only --schema bypasses to native)
- Verb-first refinement applied (same pattern as flywheel-1hshd.24 — 2nd recurrence)

## Phase 3: scaffold + fill 8 stubs
- 149 → 395 lines (scaffold added 246 lines)
- 18 stubs filled per recipe: doctor (6 probes incl awk load-bearing), health (binds audit log), repair (2 scopes), validate (3 subjects with validation-status cross-source), audit, why

## Phase 4: tests 13 → 19
- Calibrated test 3 to native PARTIAL-BYPASS shape (metadata_fields/output_fields)
- Calibrated test 7 to real scope (audit_log_dir)
- Calibrated test 9 to bare-validate rc=64
- Added 6 fillin tests incl validation-status full-enum sweep (4 accept + 1 reject)

## Phase 5: ship
- 19/19 PASS, lint clean, 20 smoke captures, commit, close, callback
