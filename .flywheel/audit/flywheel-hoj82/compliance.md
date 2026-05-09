# flywheel-hoj82 Compliance Pack

## Acceptance

1. Inspect `/private/var/folders/d0` without destructive cleanup: PASS.
2. Classify disposable cache vs live macOS/app state: PASS.
3. Add protected cleanup/offload policy or explicit no-clean receipt: PASS,
   explicit no-clean receipt plus protected policy gates.
4. Rerun `storage-pressure-doctor`: PASS.

## Validation Notes

- No destructive cleanup was run against `/private/var/folders/d0`.
- DCG blocked a scratch redirect into `/var/folders`; that block was respected.
- The APFS snapshot probe script under `apfs-snapshot-ops` was not executable,
  but prior `flywheel-0y1nr` evidence already ruled out Time Machine local
  snapshots and showed only the expected sealed system snapshot.
- Storage remains `FIRE`; the close is investigative, not a reclamation claim.

## Findings

- `/private/var/folders/d0/.../T` accounts for about 201G of the 206G `d0`
  total.
- `beads_mem_*_0.db*` top-level temp files account for 186.11G.
- The `beads_mem` files looked disposable and had no matching `lsof` rows in
  the sample, but cleanup still needs a protected primitive because the same
  temp root contains active macOS/app and worker state.

## Follow-Up

Filed follow-up bead `flywheel-1935y` for protected `beads_mem`
cleanup/offload primitive.

## Compliance Score

`910/1000`

Minor deductions: APFS probe script was not executable, and this dispatch did
not reclaim bytes because the safe outcome was no-clean plus a scoped follow-up.
