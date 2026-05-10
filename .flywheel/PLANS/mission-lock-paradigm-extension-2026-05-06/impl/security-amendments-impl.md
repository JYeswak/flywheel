---
title: "Security Negative-Invariants Amendments Implementation"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Security Negative-Invariants Amendments Implementation

task_id: `amendment-security-negative-invariants-2026-05-06`
bead: `flywheel-mission-lock-security-negative-invariants-amendments-2026-05-06`
implemented_at: `2026-05-06T15:59:00Z`
socraticode_queries: 6

## Per-Finding Implementation Table

| ID | Finding summary | Mitigation chosen | File(s) touched | Line counts |
|---|---|---|---|---:|
| SEC-001 | Dispatch-author lacked a packet-level credential payload ban. | Added mission invariant requiring `secret_values_allowed=false` and forbidding token fragments, raw env output, Agent Mail bearer/registration tokens, private keys, and copied secret-bearing pane text. Validator checks SEC-001 terms. | `.flywheel/MISSION.md`; `.flywheel/scripts/mission-lock-negative-invariants-validator.sh`; `.flywheel/tests/test_mission_lock_negative_invariants_validator.sh` | MISSION section 29; validator 147; test 91 |
| SEC-002 | Credential-touching skill receipts lacked safe-execution markers. | Added required `skill_receipts[]` fields: `credential_touch`, `safe_wrapper`, `secret_value_allowed=false`, `rotation_approval_source`, and `joshua_explicit_rotation_approval`. Validator exposes the receipt fields. | same as SEC-001 | MISSION section 29; validator 147; test 91 |
| SEC-003 | Skillos cross-orch trust boundary was implicit. | Added redacted-only transfer invariant for skillos and peer orchestrators: schemas, aliases, templates, route health, and redacted evidence only; no customer-private evidence, raw pane captures, env dumps, or secret values. | same as SEC-001 | MISSION section 29; validator 147; test 91 |
| SEC-004 | Close-validator credential immutability boundary was implicit. | Added close-validator forbidden actions: no token rotation, `.env` edits, MCP secret config overwrite, vault writes, or credential repair closure from pane text. | same as SEC-001 | MISSION section 29; validator 147; test 91 |
| SEC-005 | Mission-lock negative invariants lacked least-privilege principal metadata. | Added per-surface metadata requirement: secret source of truth, principal type, allowed operations, forbidden principals, and service-role/admin credential policy. | same as SEC-001 | MISSION section 29; validator 147; test 91 |
| SEC-006 | Legacy audit-only continuation could be misread as safe for touched security surfaces. | Added blocked-readiness default for touched auth/credential/PII/customer-trust surfaces until Phase 0 scaffolding lands or a no-touch proof exists. | same as SEC-001 | MISSION section 29; validator 147; test 91 |

Note: no local `~/.claude/skills/flywheel/mission-lock/SKILL.md` or Codex copy exists. Follow-up scaffold bead filed:
`flywheel-mission-lock-skill-phase0-scaffold-2026-05-06`.

## Test Coverage

Golden-style fixture coverage lives in `.flywheel/tests/test_mission_lock_negative_invariants_validator.sh`.

| ID | Fixture case | Expected |
|---|---|---|
| SEC-001 | Complete fixture declares secret payloads blocked. | PASS |
| SEC-001 | Fixture omits the packet-level secret ban. | FAIL on SEC-001 |
| SEC-002 | Fixture omits safe receipt fields. | FAIL on SEC-002 |
| SEC-003 | Fixture omits cross-orch transfer limit. | FAIL on SEC-003 |
| SEC-004 | Fixture omits close-validator immutability. | FAIL on SEC-004 |
| SEC-005 | Fixture omits per-surface principal metadata. | FAIL on SEC-005 |
| SEC-006 | Fixture omits blocked-readiness default. | FAIL on SEC-006 |
| ALL | Repo `.flywheel/MISSION.md` after append. | PASS |

Additional CLI metadata cases validate `--help`, `--info --json`, `--examples --json`, and `--quiet`.

## Negative-Invariant Declaration Text

Actual prose added to `.flywheel/MISSION.md`:

```markdown
## Negative invariants (security)

# AUDIT-ADDED: SEC-001..006 - needs Joshua review on next mission-relock

These invariants are additive mission-lock template requirements for touched
auth, credential, PII, and customer-trust surfaces.

- SEC-001: dispatch packets set `secret_values_allowed=false`; they may name
  secret classes, keys, vault paths, and safe helper commands, but never include
  token fragments, raw env output, Agent Mail bearer tokens, registration
  tokens, private keys, or copied secret-bearing pane text.
- SEC-002: credential-touching `skill_receipts[]` include `credential_touch`,
  `safe_wrapper`, `secret_value_allowed=false`, `rotation_approval_source`, and
  `joshua_explicit_rotation_approval` when rotation or destructive credential
  work is involved.
- SEC-003: skillos and peer orchestrators receive skill names, aliases,
  templates, route health, schemas, and redacted evidence only; they never
  receive customer-private evidence, raw pane captures, env dumps, secret values,
  or repo-local credential payloads.
- SEC-004: close-validator may fail closure, open/update beads, and demand
  receipts, but may not rotate tokens, edit `.env`, overwrite MCP secret config,
  write vault values, or mark credential repair complete from pane text.
- SEC-005: every touched surface declares its secret source of truth, principal
  type, allowed operations, forbidden principals, and whether service-role/admin
  credentials are permitted or explicitly forbidden.
- SEC-006: missing negative invariants on touched auth/credential/PII/customer-trust
  surfaces mean blocked readiness until Phase 0 scaffolding lands or a no-touch
  proof shows that the security surface is outside the dispatch scope.
```

## Receipts Schema Additions

Validator JSON emits `receipt_schema_additions` with these required fields:

- `dispatch_template[]`: `secret_values_allowed=false`, `credential_touch`,
  `safe_wrapper_required`, `redaction_required`, `no_raw_pane_secret_evidence`.
- `skill_receipts[]`: `credential_touch`, `safe_wrapper`,
  `secret_value_allowed=false`, `rotation_approval_source`,
  `joshua_explicit_rotation_approval`.
- `surface_metadata[]`: `secret source of truth`, `principal type`,
  `allowed operations`, `forbidden principals`, and service-role/admin
  credential policy.

Validation commands:

```bash
bash .flywheel/tests/test_mission_lock_negative_invariants_validator.sh
./.flywheel/scripts/mission-lock-negative-invariants-validator.sh --json
```
