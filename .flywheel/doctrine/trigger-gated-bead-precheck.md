---
title: "Trigger-Gated Bead Pre-Check"
type: doctrine
created: 2026-05-09
frontmatter_source: scaffold-doc-frontmatter
---

# Trigger-Gated Bead Pre-Check

Version: `trigger-gated-bead-precheck/v1`
Owner: `/flywheel:dispatch` packet author (`build-dispatch-packet.sh`)
Status: canonical, shipped 2026-05-10
Source bead: `flywheel-lh64t` (parent: `flywheel-g6xaw`; sister: `flywheel-ubrb5` watchtower author)

## Why

A bead is *trigger-gated* when its first acceptance gate is an external event the
flywheel cannot cause. The canonical example: `flywheel-g6xaw` whose AG1 was
`gh repo view Dicklesworthstone/frankenterm` showing `latestRelease.tagName >= v0.1.0`.

`br-ready` checks bead-graph readiness — parents closed, deps satisfied, status open.
It does NOT check the *operational* trigger. Result: as soon as the watchtower-author
parent closes, the trigger-gated bead becomes dispatchable. The orchestrator hands a
worker a packet. The worker probes the trigger, sees premise-not-met, returns BLOCKED
with `blocker_class=upstream_release_not_yet_published`. Clean, but the round-trip
is wasted work — the orch had deterministic data (the watchtower output) and could
have pre-checked.

## The Pattern

A bead is trigger-gated when its body declares an external trigger via the canonical
structured field:

```text
external_trigger_watchtower=<watchlist-name>
```

The `<watchlist-name>` MUST appear in the watchtower JSON output at
`.watchlists.<name>`. Today the supported watchlists are:

| name | watchtower | release-fired statuses |
|---|---|---|
| `frankenterm_release` | `.flywheel/scripts/jeff-binary-version-watchtower.sh` | `released` |
| `codex_release` | `.flywheel/scripts/jeff-binary-version-watchtower.sh` | `target_released`, `newer_than_target` |

Any of `release_available`, `released`, `target_released`, `newer_than_target` count
as "trigger has fired" — the dispatch is allowed.

Anything else (`public_no_release`, `not_found`, `hold_target_not_released`,
`unknown`, missing watchlist) means the bead must wait.

## Pre-Check Surface

`build-dispatch-packet.sh` runs `dispatch-trigger-gated-precheck.sh validate
--bead-body-file <body>` before emitting a packet.

| Outcome | Default behavior | Override |
|---|---|---|
| not trigger-gated (no field) | build packet | — |
| trigger fired (release_available) | build packet | — |
| trigger not yet fired | refuse with exit 6 | `--allow-trigger-gated` (warn-only) |
| watchtower probe fails | warn, continue | `--skip-trigger-gated-precheck` |

The pre-check JSON is preserved in `--json` output at
`fields_resolved.trigger_gated_precheck.{status,probe}` for orch audit.

## Authoring Trigger-Gated Beads

When you file a bead whose AG1 is an external event, add the field to the bead body:

```text
external_trigger_watchtower=frankenterm_release
```

Prose-only signals ("Operational trigger is ...", "Depends on ... release
announcement") are detected and surfaced as a warning that nags the bead author
to add the structured field. They do NOT refuse dispatch — the orch should still
build the packet, since the field-less bead may be trigger-adjacent rather than
trigger-gated.

## Adding a New Watchlist

When a new watchtower is added that should gate dispatch:

1. Ensure the watchtower emits `.watchlists.<name>.status` with a stable enum.
2. Add the name to `dispatch-trigger-gated-precheck.sh` info output.
3. If the "release_available" enum differs, extend `RELEASE_AVAILABLE_STATUSES`.
4. Reference this doctrine in the bead body.

## Anti-Patterns

| Do not | Why | Do this instead |
|---|---|---|
| Filter trigger-gated beads out of `br ready` | They ARE ready by graph criteria — pre-check operational trigger separately. | Use `external_trigger_watchtower=<name>` and let dispatch consult the watchtower. |
| Add prose-only "operational trigger" with no field | The pre-check warns but cannot enforce. | Add the structured `external_trigger_watchtower=<name>` field. |
| Hard-code allowed statuses inline | Watchlist authors may emit different enum names. | Map them in `RELEASE_AVAILABLE_STATUSES` once. |
| `--skip-trigger-gated-precheck` as default | Silent regression: trigger-gated beads fan out as wasted worker round-trips. | Use `--allow-trigger-gated` when you specifically want to forward a known-blocked dispatch with a warning audit. |

## Test Surface

`.flywheel/tests/test-trigger-gated-watchtower-precheck.sh` covers:

- gated bead + watchtower public_no_release → rc=6
- gated bead + watchtower released → rc=0
- prose-only bead → rc=0 with warning
- clean bead → rc=0 with no warnings
- introspection trio (info / examples / schema)
- doctor / health command shapes

## Sister Surfaces

- `feedback_substrate_watchtower_must_be_wired` (META-RULE) — the watchtower IS
  wired; this doctrine closes the consumer-side gap that the watchtower author
  surfaced.
- `flywheel-g6xaw` evidence (`pattern-emerged: trigger-gated bead BLOCKED-disposition class`)
  — the *worker-side* canonical disposition for trigger-gated beads when this
  pre-check is bypassed or the field is absent.
