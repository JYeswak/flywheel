# Public Live-State Denylist Draft

Created: 2026-05-12T21:26Z
Agent: TopazMeadow
Primary downstream bead: B0.5 / `flywheel-qmuvn`
Status: implementation input, not the gated denylist

## Purpose

B0.5 must ensure public extraction refuses Joshua-local state before any
depersonalization or assembly step can copy it. This draft defines the denylist
classes, probe cases, and failure semantics for the eventual
`state/live-state-denylist.yaml` and `scripts/depersonalize.py --probe-denylist`
implementation.

This file intentionally does not create the gated `state/` YAML. B0 remains
open until the charter has the required review trailer.

## Source Basis

- `CHARTER.md` excluded-state and publishability sections.
- `SECURITY.md` secret discipline and dispatch safety sections.
- `05-INSTALLABILITY-COVERAGE-AUDIT.md` A1/A4/A5 gap map.
- `11-FIRST-RUN-JOURNEY-SPEC.md` private-state guardrail.
- Socraticode search for live-state, depersonalization, Agent Mail, NTM, CASS,
  JSM, Socraticode, and secret-state anchors.
- `data-deidentification` skill: publishability needs field classification and
  residual-risk checks, not only direct identifier removal.
- `agent-security` skill: agent state is an exfiltration boundary and must be
  denied by execution-time checks, not by prompt guidance.

## Denylist Model

Each denylist row should classify a path or pattern with stable fields:

```yaml
- id: ntm-runtime-state
  class: live-runtime-state
  pattern: ".ntm/**"
  decision: deny
  reason_code: private_pane_runtime
  public_replacement: "document NTM install/detect, not local runtime state"
  probe_fixture: "fixtures/denylist/ntm-runtime-tree"
```

Required row fields:

| Field | Meaning |
|---|---|
| `id` | Stable kebab-case identifier used in probe errors. |
| `class` | One of the classes in the table below. |
| `pattern` | Repo-relative path or anchored absolute-family marker. |
| `decision` | `deny`, `manual-review`, or `fixture-only`. |
| `reason_code` | Stable machine-readable failure code. |
| `public_replacement` | What the public extraction should use instead. |
| `probe_fixture` | Synthetic fixture path that proves the row is enforced. |

No row may contain secret values, bearer tokens, account IDs, credential
fragments, raw environment output, or live pane text.

## Classes

| Class | Meaning | Default decision |
|---|---|---|
| `live-runtime-state` | Mutable state from active sessions, panes, dispatches, or local daemons. | deny |
| `private-identity-state` | Agent identities, mailboxes, registrations, account maps, or local operator identity. | deny |
| `credential-state` | Secrets, tokens, env files, cookies, keychains, auth caches, or secret-shaped fixtures without synthetic markers. | deny |
| `private-memory-state` | CASS, JSM, Socraticode, vector DB, memory, or research indexes generated from private work. | deny |
| `client-evidence-state` | Client repo names, client incidents, customer data, consent-gated case evidence. | manual-review |
| `public-fixture-state` | Synthetic fixture data that is explicitly fake and safe to publish. | fixture-only |
| `public-template-state` | Parameterized templates with no private defaults. | allow after classification |

The extractor should fail closed when a path matches both an allow class and a
deny/manual-review class. The safer class wins unless a manual-review receipt
explicitly signs off.

## Initial Path Families

| ID | Pattern family | Class | Decision | Public replacement |
|---|---|---|---|---|
| `repo-ntm-runtime` | `.ntm/**` | live-runtime-state | deny | Explain NTM concepts and install/detect commands. |
| `repo-flywheel-runtime` | `.flywheel/runtime/**` | live-runtime-state | deny | Generate runtime dirs during public init. |
| `repo-local-receipts-private` | `.flywheel/receipts/private/**` | live-runtime-state | deny | Publish scrubbed example receipts only. |
| `repo-dispatch-ledger` | `.flywheel/dispatch-log.jsonl` | live-runtime-state | manual-review | Publish schema and synthetic rows. |
| `repo-handoffs` | `.flywheel/handoffs/**` | client-evidence-state | manual-review | Publish generalized handoff templates. |
| `repo-private-reports` | `.flywheel/reports/**` | client-evidence-state | manual-review | Publish only depersonalized metrics or fixtures. |
| `repo-research-private` | `.flywheel/research/**` | private-memory-state | manual-review | Publish methodology summaries, not raw research ledgers. |
| `agent-mail-archive` | `**/agent_mail*/**`, `**/mcp_agent_mail*/**` when under state/archive roots | private-identity-state | deny | Public setup docs and empty fixtures. |
| `cass-state` | `**/cass*/**` when under state/db roots | private-memory-state | deny | Public install/detect instructions. |
| `jsm-state` | `**/jsm*/**` when under state/db roots | private-memory-state | deny | SkillOS capability-control-plane docs. |
| `socraticode-index` | `**/qdrant/**`, `**/socraticode*/**` when under state/db roots | private-memory-state | deny | MCP setup docs and fresh local index command. |
| `tmux-pane-captures` | `**/*pane*capture*`, `**/*scrollback*` | live-runtime-state | deny | NTM command examples without saved live text. |
| `env-and-auth` | `.env*`, `**/*.pem`, `**/*.key`, `**/*token*`, `**/*cookie*` | credential-state | deny unless synthetic fixture marker exists | Redacted examples with fake markers. |
| `client-named-artifacts` | paths containing known private client names from depersonalization table | client-evidence-state | manual-review | Industry-only or synthetic replacement. |
| `halted-propagators` | halted propagator script names from B3.4 | live-runtime-state | deny | Public docs must not ship clobber-capable propagation tools. |

The eventual YAML should keep exact names for halted propagator scripts in one
place, sourced from the B3.4 extraction sweep, so B0.5 does not drift from the
script-sweep acceptance gate.

## Probe Fixtures

B0.5 should ship a synthetic fixture tree with no private data:

| Fixture | Contains | Expected result |
|---|---|---|
| `fixtures/denylist/ntm-runtime-tree` | `.ntm/rate_limits.json`, `.ntm/sessions.json` | deny with `private_pane_runtime` |
| `fixtures/denylist/agent-mail-archive` | fake Agent Mail inbox/outbox paths, no real bodies | deny with `private_agent_identity_state` |
| `fixtures/denylist/memory-indexes` | fake CASS/JSM/Socraticode DB paths | deny with `private_memory_state` |
| `fixtures/denylist/env-secret-shapes` | `.env.local` with only fake markers | deny unless marked as public fixture |
| `fixtures/denylist/client-artifacts` | fake client-name markers from a synthetic table | manual-review with `client_evidence_state` |
| `fixtures/denylist/public-template` | parameterized template with placeholders only | allow after classification |

The probe must validate both positive and negative cases. A denylist that only
finds obviously bad paths but cannot prove safe template paths remain extractable
will create release friction later.

## Failure Contract

`scripts/depersonalize.py --probe-denylist` should exit with stable codes:

| Exit | Meaning |
|---:|---|
| 0 | All fixture expectations matched. |
| 30 | Denylisted live/private path would be copied. |
| 31 | Manual-review path lacks signed review row. |
| 32 | Credential-shaped fixture lacks synthetic marker. |
| 33 | Denylist schema is malformed. |
| 34 | Probe fixture expectation is missing or stale. |

The human-facing error should include:

- `reason_code`
- matched `id`
- matched repo-relative path
- public replacement hint
- whether the block is `deny` or `manual-review`

It should not print file contents.

## Manual-Review Receipt

Manual-review rows should require a JSONL receipt shaped like:

```json
{
  "schema_version": "flywheel.public_review.v0",
  "path": ".flywheel/reports/example.md",
  "denylist_id": "repo-private-reports",
  "reviewer": "authorized-reviewer-id",
  "decision": "publish|redact|drop",
  "rationale": "depersonalized aggregate only",
  "reviewed_at": "2026-05-12T00:00:00Z"
}
```

No `publish` decision is valid unless the reviewed file also passes the
depersonalization table and secret-shape scan.

## Non-Completion Note

This draft does not satisfy B0.5. B0.5 remains open until the gated YAML exists,
the probe implementation exists, synthetic fixtures pass, and B0 charter review
has landed. The active public-installability goal remains incomplete.
