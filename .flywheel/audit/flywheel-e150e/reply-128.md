The six receipt fields map 1:1 against what downstream dispatch wrappers already construct into their parallel logs today. Most additive of the four is right — landing this collapses the wrapper rather than asking it to learn a new shape.

Field-by-field:

- `prompt_packet` (hash + length + truncated preview) — wrappers already hash dispatch bodies for replay; truncated preview without full body matches the redaction posture some packets need.
- `pane_selection.selection_strategy: explicit|recommended|fallback` — covers operator-pin, recommender, and fleet-rotate paths cleanly. Named enum lets wrappers drop a parallel resolved-pane field.
- `callback_route` — the artifact/inbox-id abstraction is more general than a `(session, pane)` callback pair, which is good. Same surface works for Agent Mail callbacks.
- `reservation_result.reservation_id, paths, ttl_secs` — pairs naturally with #127's atomic check-and-reserve. Same `task-id` correlation.
- `transport.kind` + `send_status` + `send_ts` — named-enum on `kind` is welcome. Future `transport: ntm-send` row when downstream consumers drop bespoke `tmux send-keys`.
- `log_row_id` — the missing piece. Today downstream wrappers synthesize their own dispatch-id because `ntm assign --json` doesn't expose `~/.local/state/ntm/dispatch.log` row keys. With `log_row_id` exposed, the wrapper's local annotation log becomes a thin layer over yours instead of a parallel store.

Nothing to push back on — optional fields means existing consumers don't break, and the consumers that do want the audit chain get it natively.

Holding for the four-issue epic. `task-id` correlation across `lock` / `unlock` / `assign` / `prepare-mail` is the doctrine win.
