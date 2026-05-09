# flywheel-13u0.5 evidence receipt

Bead: `flywheel-13u0.5`
Task: `flywheel-13u0.5-c4357a`
Evidence redacted: `yes`

## Result

Exact class disposition: `no_followup_needed` for `br-source-repo-dot-after-create`.

Reason: `flywheel-5ktw` and beads_rust#273 are the durable upstream owner, the GitHub issue is closed, `flywheel-f505` records local rebuild and post-fix validation, and `flywheel-ap9n` stale-closed the local promotion candidate after no fresh occurrences since 2026-05-04.

No `INCIDENTS.md` edit was made.

## Distinct Gap

`bash tests/phase2-audit.sh` still fails current source-repo checks:

- T2.3: existing repo-local DBs still have `source_repo='.'` rows.
- T2.4: current `br create` wrote a non-absolute basename value.

This is not the exact closed dot-after-create upstream issue. It should be tracked as a separate current source-repo hygiene/write-path gap.

## Commands Run

```bash
br show flywheel-13u0.5 --json
br dep tree flywheel-13u0.5
br show flywheel-7rr --json
br show flywheel-5ktw --json
br show flywheel-f505 --json
br show flywheel-ap9n --json
sed -n '1,180p' .flywheel/audit/flywheel-13u0.4/disposition.md
bash tests/phase2-audit.sh
bash .flywheel/receipts/flywheel-13u0.5/l112-probe.sh
```

## Redacted Facts

- `/tmp/br_create_canonicalize_plan.md` was missing.
- `/tmp/promote-draft-br-source-repo-dot-after-create.md` was missing.
- `/tmp/promote-draft-br-source-repo-dot-after-create-round2.md` was missing.
- GitHub issue #273 was live-checked and was closed.
- Current Phase 2 audit failure is recorded as a separate gap from the exact dot-after-create incident.

## Acceptance

- AG1: pass
- AG2: pass
- AG3: pass

## Notes

No token values, token fragments, registration tokens, or token hashes are copied into this receipt.
