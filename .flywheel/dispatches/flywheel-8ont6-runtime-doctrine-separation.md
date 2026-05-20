# flywheel-8ont6 — .flywheel/ runtime-vs-doctrine separation (gitignore + cached-untrack sweep + state symlinks per repo bootstrap)

## Context

Joint mobile-eats:1 deep-dive (2026-05-20T04:05Z) identified this as P0 paired with flywheel-ge03h. ge03h measures bloat; 8ont6 makes bloat structurally impossible by separating accreting RUNTIME state from versioned DOCTRINE. Mobile-eats hit 1417 tracked .flywheel/* files (64 MB) before tonight's cleanup — most was ledger/snapshot data that belongs in `~/.local/state/flywheel/` per canonical doctrine. This bead generalizes the migration.

Taxonomy from the deep-dive memo (already triaged):

| Subdir | Class | Action |
|---|---|---|
| .flywheel/doctrine/ | DOCTRINE | KEEP TRACKED |
| .flywheel/specs/ | DOCTRINE | KEEP TRACKED |
| .flywheel/scripts/ | DOCTRINE | KEEP TRACKED |
| .flywheel/dispatches/ | DOCTRINE | KEEP TRACKED |
| .flywheel/handoffs/ | DOCTRINE | KEEP TRACKED |
| .flywheel/audits/ | EVIDENCE | KEEP if <10MB/file; rotate quarterly otherwise |
| .flywheel/runtime/ | RUNTIME | MIGRATE to ~/.local/state/flywheel/<repo>/runtime/, gitignore + symlink |
| .flywheel/state/ | RUNTIME | MIGRATE to ~/.local/state/flywheel/<repo>/state/, gitignore + symlink |
| .flywheel/evidence/ | RUNTIME | MIGRATE to ~/.local/state/flywheel/<repo>/evidence/, gitignore + symlink |
| .flywheel/validation/ | MIXED | Per-file review; live validators stay tracked, snapshots rotate |
| .flywheel/private/ | SECRETS | NEVER TRACK — audit-if-tracked = INCIDENT |
| .flywheel/brand-candidates/ | MIXED | Per-file review |

## Deliverables

### A. .flywheel/scripts/runtime-doctrine-separation-migrate.sh
Per-repo idempotent migration primitive. Flags: --repo PATH --dry-run --apply --json.

Steps:
1. Probe current state of each subdir class
2. For each RUNTIME class (runtime/state/evidence):
   - mkdir -p ~/.local/state/flywheel/<repo-basename>/<class>/
   - Copy current contents into target dir (preserve mtimes)
   - cached-untrack the in-repo subdir via canonical git ergonomics (no --force)
   - Add subdir glob to .gitignore (idempotent: skip if already present)
   - Replace in-repo subdir with symlink to ~/.local/state/flywheel/<repo>/<class>/
3. For SECRETS class (.flywheel/private/): refuse + emit incident envelope if ANY file currently tracked
4. For MIXED classes (validation, brand-candidates, audits): emit per-file report, NO mutation, surface to operator
5. Idempotent: re-run produces no changes if migration complete
6. Backup: pre-migration tarball at ~/.local/state/flywheel/<repo>/migration-backup-<ts>.tar.gz

Output envelope:
```json
{
  "schema_version": "runtime_doctrine_separation_migrate.v1",
  "ts": "...",
  "repo": "...",
  "mode": "dry-run|apply",
  "outcome": "ok|incident|mixed-needs-operator",
  "runtime_migrated": [".flywheel/runtime", ".flywheel/state", ".flywheel/evidence"],
  "tracked_files_before": N,
  "tracked_files_after": N,
  "bytes_recovered": N,
  "secrets_incidents": [],
  "mixed_classes_pending_review": [...]
}
```

### B. .flywheel/scripts/runtime-doctrine-separation-fleet-rollout.sh
Iterates the 5 flywheel-managed repos (flywheel, skillos, zesttube, mobile-eats, clutterfreespaces). Per-repo dry-run report. Joshua-gated apply.

### C. Doctrine
.flywheel/doctrine/runtime-doctrine-separation-discipline.md citing:
- The taxonomy table above
- Migration recipe
- Why-this-matters: ge03h tracked-substrate-bloat metric becomes meaningful only when runtime is OUT of repo
- Cross-link to flywheel-ge03h (paired primitive)
- Cross-link to mobile-eats JANITOR-FINAL-REPORT.md as before/after evidence (1417 tracked → much less after migration)

### D. tests/runtime-doctrine-separation-smoke.sh
- 8+ assertions:
  1. Synthetic repo with .flywheel/runtime/X.jsonl + .flywheel/doctrine/Y.md → migrate moves only runtime
  2. Symlink target points correctly after migration
  3. .gitignore updated idempotently
  4. cached-untrack happens for migrated paths
  5. .flywheel/private/ with tracked file → INCIDENT outcome (no mutation)
  6. Re-run on already-migrated repo → no changes (idempotent)
  7. Backup tarball created at ~/.local/state/flywheel/<repo>/migration-backup-<ts>.tar.gz
  8. Mixed classes (validation/) → operator-review report, no mutation

### E. Initial fleet dry-run report
.flywheel/audits/runtime-doctrine-separation-fleet-dry-run-<ts>.md showing per-repo what WOULD be migrated. Joshua reviews before applying.

## Acceptance

- 3 scripts + 1 doctrine + smoke ship
- shellcheck PASS
- Smoke 8+ assertions PASS
- Initial 5-repo dry-run report written
- Idempotent verified (run twice → identical envelope)
- Backup tarball pre-migration safety
- DO NOT actually apply migration on real repos — Joshua-gate
- Bead flywheel-8ont6 closed

## Loop contract

- Track 3 only
- mcp-agent-mail file_reservation_paths before edits
- socraticode K>=10 with 2 phrasings on existing migration patterns + git cached-untrack canonical + symlink ergonomics
- Bridge daemon LIVE
- SCR event: C6_trauma_outflow + C7_verification_density
- STOP on Track 1/2 breach, BLOCKED, >3h hard cap
- DEEP-WORK validate: shellcheck + smoke + 5-repo dry-run
- DO NOT apply real migration — dry-run only, Joshua-gated

## FIRST ACTION

1. br show flywheel-8ont6.
2. Read mobile-eats JANITOR-FINAL-REPORT.md for the before/after motivation.
3. Read .flywheel/scripts/repo-hygiene-doctor.sh (just shipped via ge03h) for the metric the migration affects.
4. ACK row.
5. Implement 3 scripts + smoke + doctrine.
6. Self-validate.
7. Initial 5-repo dry-run report.
8. Commit + close bead + DIRECT pane-1 ntm send.
