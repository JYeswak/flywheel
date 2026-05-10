The proposed envelope `{state: free|reserved|blocked, holder: {...}|null, reservation_id, task-id}` covers our wrapper callsites exactly. Today our shell-out walks `ntm conflicts --json` for native truth but maintains a parallel JSONL audit trail because `ntm locks list` doesn't carry the `task-id` correlation key. Atomic check-and-reserve with `task-id` as the durable key into `ntm assign --json` (#128) is what unblocks dropping that parallel ledger.

On your design question: lean atomic `check-and-reserve` as the default, `--check-only` as a flag. The TOCTOU window is the entire reason wrappers maintain audit ledgers in the first place; surfacing two non-atomic primitives just moves the race up one layer.

One tiny additive on `state` if it fits cleanly: when the path is `reserved` by the same `(session, pane, task-id)` tuple as the caller, returning a distinct `state: held_by_caller` (vs `reserved`) lets the wrapper distinguish "I already hold this" from "someone else holds this" without parsing `holder`. Saves an idempotency branch on worker close paths. Skip if it complicates `state`'s domain — `holder == self` is parseable.

Coordinated four-issue epic + single CHANGELOG entry is the right call. Holding for #128/#129 to land alongside.
