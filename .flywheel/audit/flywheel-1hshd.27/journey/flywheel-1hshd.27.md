# Journey: flywheel-1hshd.27

## Phase 1: baseline probe
- Native has install/load/unload/status/run/validate plist subcommands
- Bare invocation emits status JSON (native default)
- No --info/--schema/--examples/--doctor flags
- **Verb collision**: scaffold's validate vs native's `validate plist`

## Phase 2: variant choice — SELECTIVE-VERB-BYPASS at sub-arg level
- Scaffold owns validate verb
- BUT: `validate plist` (with args[1] == "plist") bypasses to NATIVE
- Scaffold validate adds new subjects: label, cadence-seconds, state-dir
- Native paths preserved: install/load/unload/status/run/validate plist/bare

## Phase 3: scaffold + fill 8 stubs
- 618 → 874 lines pre-fillin
- 18 stubs filled with launchd-specific logic (com.zeststream.flywheel.* label pattern, cadence-seconds [10,3600] launchd StartInterval contract, state_dir/audit_log_dir/launchagents_dir scopes)

## Phase 4: bonus fix
- L3 brace-default-ambiguity at line 99 (pre-scaffold) — fixed with `local empty_obj='{}'` intermediate variable

## Phase 5: tests 13 → 19
- 6 fillin tests incl SELECTIVE-VERB-BYPASS test (test 18 verifies validate plist still bypasses to native) + 4-direction fidelity (test 19 verifies both scaffold AND native paths intact)

## Phase 6: ship
- 19/19 PASS, lint CLEAN (improved 3 errors → 0), 22 smoke captures
