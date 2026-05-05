# Skill Handoff To Skillos Fleet-Mail Template

This template standardizes how flywheel sessions hand newly created or revised
skills to skillos for hardening. It is a fleet-mail message template, not a
skillos work order; the sender proposes context and requests, and skillos owns
the intake decision, hardening scope, version bump, and receipt.

## Use Cases

1. **Single skill handoff:** render one message for one skill after the flywheel
   worker has shipped or revised the skill and released its file reservations.
2. **Batch handoff:** render this template once per skill. Do not bundle multiple
   skills into one subject because skillos receipts are skill-scoped.
3. **`ownership=forbidden` short-circuit:** do not send the fleet-mail message.
   Write a local no-handoff receipt explaining that distribution or ownership
   forbids skillos hardening.

## Required Substitutions

| Placeholder | Meaning |
|---|---|
| `{{skill_name}}` | Canonical skill directory/name, for example `canonical-cli-scoping`. |
| `{{version}}` | Current source version without a leading `v`, for example `0.1.0`. |
| `{{path}}` | Absolute path to the skill directory being handed off. |
| `{{ownership}}` | Ownership declaration: `local`, `upstream`, or `forbidden`. |
| `{{flywheel_origin_session}}` | Session that created or changed the skill, for example `flywheel:2`. |
| `{{flywheel_creation_bead_id}}` | Flywheel bead that created or changed the skill. |
| `{{flywheel_dispatch_log_ref}}` | Durable dispatch/callback/log reference for provenance. |
| `{{hardening_requests}}` | YAML array of requested hardening improvements; each rendered item starts with `  - `. |

## Fleet-Mail Message

```text
Subject: [skill-handoff] {{skill_name}} v{{version}} — for skillos hardening cycle
```

Canonical subject format: `[skill-handoff] <name> v<X.Y.Z> — for skillos hardening cycle`.

```markdown
# Skill Handoff: {{skill_name}} v{{version}}

source: fleet-mail-skill-handoff
schema_version: skill-handoff-to-skillos/v1

## Ownership

- ownership: {{ownership}}
- allowed values: local | upstream
- forbidden policy: if ownership is `forbidden`, this message should not be sent;
  create a local no-handoff receipt instead.

## Skill

- name: {{skill_name}}
- path: {{path}}
- current_version: {{version}}
- requested_receiver: skillos
- requested_cycle: hardening

## Flywheel Provenance

- origin_session: {{flywheel_origin_session}}
- creation_bead_id: {{flywheel_creation_bead_id}}
- dispatch_log_ref: {{flywheel_dispatch_log_ref}}

## Hardening Requests

Sender-suggested improvements. Skillos owns acceptance, ordering, and versioning.

hardening_requests:
{{hardening_requests}}

## Receipt Compatibility

This message is shaped to populate skillos `skill_hardening_receipt` fields:

- `source`: `fleet-mail-skill-handoff`
- `fleet_mail.subject`: `[skill-handoff] {{skill_name}} v{{version}} — for skillos hardening cycle`
- `skill.name`: `{{skill_name}}`
- `skill.path`: `{{path}}`
- `skill.previous_version`: `{{version}}`
- `skill.distribution`: `{{ownership}}`
- `hardening_requests_from_message`: `{{hardening_requests}}`

## Sender Contract

- The sender has completed any flywheel-side reservations and validation before
  this handoff.
- The sender does not ask skillos to accept unsafe ownership. If ownership is
  `forbidden`, the sender records a no-handoff receipt instead.
- The sender treats this as an intake request. Skillos may harden, defer, split,
  or reject the handoff.
```
