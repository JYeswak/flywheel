# L164 — TENANT-VERIFICATION-GATE-MANDATORY-BEFORE-DB-MUTATION

---
id: L164
title: Tenant verification gate is mandatory before database mutation
status: long_term
shipped: 2026-05-15
review_due: 2026-11-15
trauma_class: db-mutation-without-tenant-verification
source_owner: skillos
source_locator: /Users/josh/Developer/skillos/.flywheel/doctrine/cross-infisical-project-credential-collision-wrong-tenant-connect.md
ratification: .flywheel/handoffs/20260512T052716Z-from-flywheel-1-to-skillos-1-L163-L167-RATIFICATION.md
---

Before any database-mutating operation, the system must verify that the
credential, connection URL, project reference, or account identity resolves to
the intended tenant.

The gate must run before migration apply, schema change, production write,
deploy-triggered migration, infrastructure apply against stateful resources, or
any equivalent state-changing operation. A successful login is not enough.

## Flywheel application

Flywheel should treat tenant verification as a preflight receipt, not as prose
in a runbook. A mutation path without a tenant-verification receipt is blocked
until the path proves expected tenant, actual tenant, verification source, and
the state-changing command guarded by that proof.

## SkillOS source

- SkillOS canonical:
  `/Users/josh/Developer/skillos/.flywheel/doctrine/cross-infisical-project-credential-collision-wrong-tenant-connect.md`
- Flywheel ratification:
  `.flywheel/handoffs/20260512T052716Z-from-flywheel-1-to-skillos-1-L163-L167-RATIFICATION.md`

