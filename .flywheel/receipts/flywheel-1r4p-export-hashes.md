# flywheel-1r4p close evidence

Task: `[br-gap] import-only fails on export_hashes unique constraint`

## Finding

The `beads_rust` worktree already contains the targeted fix and regression coverage:

- Import path clears/rebuilds `export_hashes` before writing import-derived rows.
- Batch export hash writes use delete-then-insert semantics, so repeated writes for the same `issue_id` are idempotent under the current SQLite facade.
- Regression test `e2e_auto_import_reuses_existing_export_hash_rows` covers `br show <id> --json` auto-importing newer JSONL without `UNIQUE constraint failed: export_hashes.issue_id`.

## Verification

Socraticode survey:

- `/Users/josh/Developer/flywheel` query `br sync import-only export_hashes issue_id unique constraint auto-import JSONL newer than DB` returned 10 chunks and found the 2026-05-04 incident fixture.
- `/Users/josh/Developer/flywheel` query `export_hashes table import issues jsonl sync implementation beads rust python` returned 10 chunks and pointed to the existing incident/doctrine context.
- `/Users/josh/Developer/flywheel` query `br import-only sync export hashes issues jsonl hash metadata rebuild duplicate issue_id test` returned 10 chunks and surfaced the br-db recovery context.

Targeted source test:

```bash
cd /Users/josh/Developer/beads_rust
cargo test e2e_auto_import_reuses_existing_export_hash_rows --test e2e_sync_artifacts -- --nocapture
```

Result: `1 passed; 0 failed`.

Installed binary probe:

```bash
tmp=$(mktemp -d /tmp/br-export-hash-live.XXXXXX)
cd "$tmp"
br init
br create "Original title"
br sync --flush-only
# edit .beads/issues.jsonl title and updated_at
br show "$issue_id" --json
```

Result: `br show` auto-imported the newer JSONL and returned title `Imported title` without stale bypass or `export_hashes` UNIQUE failure.

Probe workspace: `/tmp/br-export-hash-live.hjxTiF`

## Acceptance

- AG1: evidence artifact exists at this path.
- AG2: targeted regression test and installed binary probe passed.
- AG3: `br show flywheel-1r4p` remained open until this artifact existed.
