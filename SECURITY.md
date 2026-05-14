# Security

Report suspected vulnerabilities, exposed secrets, install safety issues, or
dispatch-safety regressions to `security@zeststream.ai` and include the affected
path plus the observed behavior.

Do not open public issues with sensitive details.

## Threat Model

Flywheel's main risk is not a public web exploit. It is control-plane drift:

- a worker receives a dispatch without the wrapper ledger
- a callback claims closure without evidence
- pane state is read from stale scrollback instead of `ntm health`
- a prompt or receipt prints secret-shaped material
- a recovery script installs the wrong LaunchAgent label
- a plan mutates after results and calls that convergence

Security here means the orchestration substrate stays truthful under pressure.

## Destructive Command Guard

DCG is load-bearing. Commands and docs must stay DCG-clean:

- use explicit path staging and explicit path removals
- avoid force-style flags unless the task explicitly owns the destructive path
- keep dangerous command strings out of prose when a safer description works
- when DCG blocks, change the command shape and record the reason

DCG is not a suggestion layer. It is part of the repo's safety boundary.

## Secret Discipline

Never print or store secret values, token fragments, raw env output, Agent Mail
bearer tokens, registration tokens, or credential helper output. Name secret
classes and vault paths instead.

Allowed patterns:

- secret names without values
- Infisical paths without values
- redacted evidence with `[REDACTED:<class>]`
- hashes of secret material only when the task explicitly asks for a verifier

Use the secret-handling doctrine in `AGENTS.md` before touching
credential-shaped work. Project maintainers must explicitly approve token
rotation.

## Dispatch Safety

Dispatches are security-sensitive because they move authority between panes.
The accepted path is `/flywheel:dispatch`, which writes a dispatch-log row and
enforces callback grammar. Worker dispatches must carry wrapper proof or an
explicit override.

Pane-state source must be recorded as `ntm_health`, `ntm_copy`, `raw_capture`,
or `none`. Dispatch context treats raw capture as a violation. Use:

- `ntm health <session>` for state truth
- `ntm copy <session>:<pane> -l <N>` for scrollback
- `ntm grep <session> <pattern>` for content search
- `ntm save <session>:<pane> <path>` for persistence

## Recovery Safety

LaunchAgent installers validate but do not activate unless the bead explicitly
owns activation. Status rows must record `reboot_recovery_claimed=false` until a
real activation and reboot claim exists. Exactly-one-label checks block duplicate
watchers.

## Reporting

Include:

- affected file or command surface
- expected behavior
- observed behavior
- evidence path or receipt
- whether credentials, client data, or dispatch authority may be involved

Do not include secret values.
