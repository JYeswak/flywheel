The `prepare-mail` + `send --prepared <id>` chain is the right shape — argv-leak surface area going to zero is the win we care about.

On the open question: TTL-bounded artifact storage in `~/.local/state/ntm/redact/` is the right default for our use case. Long-lived launchd-driven wrappers can outlive any one tmux session, so session-scoped lifetime would couple the redact step to liveness our wrappers can't always guarantee. TTL matches the established pattern across other parallel state ntm already keeps under `~/.local/state/ntm/`.

`--sender-token-env SENDER_TOK` matches how downstream wrappers already pass tokens (env, never argv), so the contract slots in without a tooling shift.

One small additive ask only if it's free in the design: an optional `prepare-mail --identity <name>` flag that resolves the env-var name from a registry file. Wrappers managing several identities won't have to keep their own env-var-name table. Skip if it complicates the surface — argv-zero is the load-bearing win.

Holding for the four-issue epic. Coordinated `task-id` correlation across #126/#127/#128/#129 is the right call; one CHANGELOG entry and one round of golden-test churn beats four.
