# DRAFT — ntm upstream issue: `coordinator.session_default` per-session config overrides

> **Status:** Draft pending Joshua signoff per L66 Phase 5
> (thankfulness test). Do **NOT** auto-file. Owned by flywheel bead
> `flywheel-b6yu`. Standing rules respected: no patch will be sent
> to `Dicklesworthstone/ntm`; this is a problem statement + repro,
> not a prescriptive PR.

## Title

`coordinator: support per-session default overrides via [coordinator.session_default] schema`

## Problem

`ntm config validate --json` (post-#111 + post-#113) still rejects
the `[coordinator.session_default]` block as unknown fields:

```
unknown field(s): coordinator.schema_version,
coordinator.session_default,
coordinator.session_default.auto_assign,
coordinator.session_default.conflict_negotiate,
coordinator.session_default.conflict_notify,
coordinator.session_default.send_digests
```

`ntm coordinator enable auto-assign` and similar global toggles
exist, but the operator-side need is **per-session defaults** —
e.g. enable `auto_assign` for picoz/zesttube but keep it OFF for
client sessions like alpsinsurance. Today this requires running
`ntm coordinator enable/disable` per session, which is imperative
and re-applies on every fleet rebuild.

## Concrete reproducer

```bash
$ cat ~/.config/ntm/config.toml
# ...
[coordinator]
schema_version = 1

[coordinator.session_default]
auto_assign = true
conflict_negotiate = false
conflict_notify = true
send_digests = true
# ...

$ ntm config validate --json | jq -r '.results[] | select(.path|test("config.toml")) | .errors[].message'
failed to load: parsing config: unknown field(s): coordinator.schema_version,
  coordinator.session_default, ...
```

## Expected behavior (additive contract)

Allow the schema to recognize a `[coordinator.session_default]`
block whose keys mirror the existing global coordinator toggles:

```toml
[coordinator.session_default]
auto_assign = false           # default for new sessions
conflict_negotiate = false
conflict_notify = true
send_digests = false
digest_interval = "30m"
```

Per-session overrides via existing `ntm coordinator enable/disable
<session>` continue to work and take precedence.

`coordinator.schema_version = 1` is requested as the standard
forward-compat marker (mirrors the convention you already use in
`ntm checkpoint` and `internal/checkpoint/Checkpoint.Version`).

## Backwards compatibility

- All proposed fields are additive; existing config files without
  `[coordinator.session_default]` continue to validate.
- `ntm coordinator status / enable / disable` semantics unchanged.
- If `[coordinator.session_default]` is absent, behavior matches
  current global defaults.

## Why upstream, not local-only

`[coordinator.session_default]` is a per-session policy primitive
that downstream wrappers (flywheel, fleet operators) want to
declare statically as part of `~/.config/ntm/config.toml`. Today
we run an imperative `ntm coordinator enable …` cron equivalent
that re-applies on every fleet rebuild. Static declaration in
config.toml lives at the source of truth and survives session
rebuild without an external loop.

## Dedup / reference

- #111 (CLOSED) — coordinator status reads [coordinator] from
  config.toml.
- #113 (CLOSED) — schema-loader drift covering
  `context_rotation.recovery.*` and
  `resilience.rate_limit.auto_rotate`. Adjacent but does NOT
  cover `coordinator.session_default`.
- #112 (CLOSED) — exit-code drift on validate; orthogonal.

Tracking on flywheel side: `flywheel-b6yu` (this bead) and
`flywheel-pdwg` (the prior triage that landed #111/#113).

## Joshua signoff checklist (Phase 5)

- [ ] Reproducer produces fresh on `ntm version` $(ntm version)
- [ ] No tokens, secrets, or auth material echoed
- [ ] Multi-model triangulation cited (this draft is v1; second-pass
      review optional before filing)
- [ ] Upstream tone: problem statement + reproducer + suggested
      contract; not a prescriptive PR; Jeffrey-not-Jeff in
      human-facing prose
- [ ] Cross-reference flywheel bead populated (`flywheel-b6yu`)

When approved, file via:

```bash
gh issue create --repo Dicklesworthstone/ntm \
  --title "coordinator: support per-session default overrides via [coordinator.session_default] schema" \
  --body-file .flywheel/audit/flywheel-b6yu/upstream-issue-draft.md
```

(Strip the "Joshua signoff checklist" section before posting.)
