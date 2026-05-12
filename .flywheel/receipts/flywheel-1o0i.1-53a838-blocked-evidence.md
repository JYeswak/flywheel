# flywheel-1o0i.1 Evidence

## Scope

- Added `tests/phase2-audit.sh` guard `T2.8b runtime_handoff supports distinct session/workdir rows`.
- The guard builds an isolated fixture DB from the live `runtime_handoff` schema and attempts two distinct `(session_name, working_dir)` rows.
- No live NTM state mutation was performed. The only direct runtime probe copied `~/.config/ntm/state.db` into the dispatch scratch directory before insert attempts.

## Result

Current NTM fails the new guard truthfully:

```text
PASS T2.8 runtime_handoff has working_dir column
FAIL T2.8b runtime_handoff supports distinct session/workdir rows
  - isolated fixture rejected distinct session/workdir rows: Error: stepping, CHECK constraint failed: id = 1 (19)
```

This is the expected scope-pass close shape after scope expansion to patch NTM
was declined. The flywheel guard now captures the bug; upstream owns the fix.

## Upstream

- GitHub issue: https://github.com/Dicklesworthstone/ntm/issues/135
- Flywheel tracking bead: `flywheel-3o76p`
- Issue body draft: `.flywheel/receipts/flywheel-1o0i.1-53a838-jeff-issue-body.md`

Upstream file:line evidence cited in the issue:

- `internal/state/migrations/011_runtime_handoff.sql:6-22`
- `internal/state/runtime_store.go:970-990`
- `internal/state/runtime_store.go:1010-1016`
- `internal/state/runtime_store.go:1032-1038`
- `internal/state/runtime_store.go:1046-1066`
- `internal/state/runtime_store.go:1080-1082`

## Validation

- `bash -n tests/phase2-audit.sh`
- `shellcheck tests/phase2-audit.sh`
- `NTM_STATE_DB="$HOME/.config/ntm/state.db" bash tests/phase2-audit.sh`
  - expected current-state result: nonzero, with `T2.8` passing and `T2.8b` failing on `CHECK constraint failed: id = 1`
- `gh issue list --repo Dicklesworthstone/ntm --state all --search "runtime_handoff singleton id working_dir" --limit 20 --json number,title,state,url`
  - result before filing: `[]`

## Four-Lens Self-Grade

- brand:8
- sniff:8
- jeff:8
- public:8

## Close Notes

- No local patches were made to `/Users/josh/Developer/ntm`.
- The new flywheel guard is intentionally red against the current upstream contract.
- `flywheel-1o0i.1` remained open until this evidence artifact existed.
