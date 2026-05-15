# L166 — INFISICAL-SET-IGNORES-PROJECT-ID-ENV-OVERRIDE-USE-CLI-FLAG

---
id: L166
title: Infisical writes must use explicit project scoping instead of env override assumptions
status: long_term
shipped: 2026-05-15
review_due: 2026-11-15
trauma_class: infisical-write-project-scope-drift
source_owner: skillos
source_locator: /Users/josh/Developer/skillos/.flywheel/doctrine/cross-infisical-project-credential-collision-wrong-tenant-connect.md
ratification: .flywheel/handoffs/20260512T052716Z-from-flywheel-1-to-skillos-1-L163-L167-RATIFICATION.md
---

Infisical write paths must pass explicit project scope in the CLI invocation
when the CLI supports it. Environment overrides are not sufficient unless the
wrapper verifies that the CLI version honors them for the specific command.

This rule is a write-path sister to L158. In both cases, the unsafe repair is
trusting the shape we wish the CLI had instead of proving the shape installed
on the machine.

## Flywheel application

Any Flywheel script that sets a secret must declare its project source, pass the
project explicitly where possible, and emit a tenant-verification receipt before
the write. If the CLI version lacks reliable explicit scope, the script must
fail closed.

## SkillOS source

- SkillOS canonical:
  `/Users/josh/Developer/skillos/.flywheel/doctrine/cross-infisical-project-credential-collision-wrong-tenant-connect.md`
- Flywheel ratification:
  `.flywheel/handoffs/20260512T052716Z-from-flywheel-1-to-skillos-1-L163-L167-RATIFICATION.md`

