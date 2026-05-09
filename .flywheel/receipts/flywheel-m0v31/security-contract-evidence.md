# flywheel-m0v31 Security Contract Evidence

Task: `flywheel-m0v31-06abeb`
Worker identity: `CloudyMill`
Mission fitness: `adjacent`

## Socraticode Survey

Canonical project path: `/Users/josh/Developer/flywheel`

Queries run: 10
Indexed chunks observed: 100

Relevant findings:
- Existing receipt schemas use draft 2020-12 JSON Schema and expose `schema_version.const`.
- Storage override receipts provide the nearest rollback-guard precedent.
- Security-negative-invariant work requires secret classes, redacted evidence, and no secret values in dispatch packets.
- Existing security corpus at `.flywheel/security/v1/secret-patterns.json` is synthetic-only and redaction-first.

## Artifacts

| Artifact | Path | Status |
|---|---|---|
| Security control schema | `.flywheel/validation-schema/v1/agent-security-control.schema.json` | exists |
| Claude deny template | `.flywheel/security/v1/claude-settings-deny.json` | exists |
| Schema README | `.flywheel/validation-schema/v1/README.md` | updated |
| Root README | `README.md` | updated |

## Contract Notes

`agent-security-control/v1` is scoped to sandbox security controls. The schema
requires path denies, a managed deny block path, redacted Bash output posture,
synthetic-only fixtures, doctor signals, issuance metadata, expiry, issuer, and
a rollback guard.

The deny template includes 30 deny entries under `.permissions.deny` and names
the bounded `canonical-security-allow` token. Overrides require owner, reason,
expiry, risk acknowledgement, tracking bead, and exact path or command scope.

No real secret values, token fragments, raw environment output, Agent Mail
tokens, or credential helper output were read or stored.
