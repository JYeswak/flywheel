# Compliance pack flywheel-dulh3

## AG coverage (6/6)
- AG1 doctor: 5 substrate checks (canonical_source, flywheel_root, rules_dir, core_deps, text_search). Live status:pass.
- AG2 health: tail-1 audit log; emits row_count + last_run_ts + last_run_age_seconds + canonical status.
- AG3 repair --scope state: dry-run plans + --apply mutates + audit row.
- AG4 validate canonical_source: 4-check contract (file_exists + BEGIN marker + END marker + L-rule entries). Live AGENTS.md 4/4 PASS.
- AG5 tests: +6 assertions (14-19); 19/19 PASS.
- AG6 canonical-cli-scoping: 13/13 PASS post-fillin.

## Surface verification
- doctor → 5 checks, status:pass
- health → status:not_initialized row_count:0 (no audit yet)
- repair --dry-run → 0 planned (audit dir already exists)
- validate canonical_source → 4 results, status:pass
- audit → status:missing
- why L48 → found "| 1 | L48 — SUBSTRATE-EXHAUSTION..."
- why L153 → found "| 104 | L153 — CAPTURE-PROVENANCE-CANONICAL..."
- why L9999 → not_found
- canonical-cli 13/13 PASS, lint rc=0

## Doctrine lane wave 1 closes here
- mae86 (doctrine-broadcast-send) ✓ closed
- vc29u (doctrine-ladder-promote) ✓ closed
- dulh3 (doctrine-sync) ✓ closed (this bead)
- zjm8v (test-sync-canonical-doctrine) ✓ closed

## Quality bar (1000-pt rubric)
- canonical-cli: 220/220 (13/13 + lint clean)
- regression depth: 200/200 (19 assertions; live why-id round-trip verified)
- doctrine: 200/200 (validate canonical_source enforces real BEGIN/END marker shape)
- integration risk: 180/200 (set -e + grep || true required to avoid false-fail)
- live demonstration: 200/200 (every surface mechanically probed)

Total: 1000/1000

## Four-Lens self-grade
brand: 9/10 — fillin pattern matches mae86 precedent
sniff: 10/10 — every surface verified against live AGENTS.md template
jeff: 10/10 — data decides; validate contract reflects real canonical shape
public: 10/10 — operator can `bash tests/doctrine-sync-canonical-cli.sh` and see 19/19

four_lens=brand:9,sniff:10,jeff:10,public:10
