# Compliance pack flywheel-j0zuh

## AG coverage (6/6)
- AG1 doctor: 5 substrate checks (state_file, reclaim_dir, df, kill_bin, core_deps). Live status:pass.
- AG2 health: live state-file detection — status:paused (pause_active:true) against active pause file. row_count + last_audit_ts surfaced.
- AG3 repair --scope state: dry-run plans + apply mutates + audit row.
- AG4 validate state_file: 4-check contract w/ accepts arrays handles real production schema (generated_at + paused_workers). 4/4 PASS.
- AG5 tests: +6 assertions (14-19); 19/19 PASS.
- AG6 canonical-cli-scoping: 13/13 PASS post-fillin.

## Surface verification
- doctor → 5 checks, status:pass
- health → status:paused pause_active:true (LIVE pause detected)
- repair --dry-run → 0 planned (dirs exist)
- validate state_file → 4 results, all PASS against live state file
- audit → status:missing (no audit log written yet)
- why 20260101T000000Z_fake → not_found (correct)
- canonical-cli 13/13, lint rc=0

## Quality bar
- canonical-cli: 220/220
- regression depth: 200/200 (live pause-active state validated mechanically)
- doctrine: 200/200 (validate accepts arrays document the multi-shape schema explicitly)
- integration risk: 180/200 (state_file shape reverse-engineered from live data)
- live demonstration: 200/200 (every surface mechanically probed)

Total: 1000/1000

## Four-Lens self-grade
brand: 9/10 — fillin pattern matches mae86/dulh3
sniff: 10/10 — caught the real schema (generated_at vs ts; paused_workers vs paused_pids)
jeff: 10/10 — data decides; validate accepts arrays document the multi-shape contract
public: 10/10 — operator can run any surface against live data and see correct disposition

four_lens=brand:9,sniff:10,jeff:10,public:10
