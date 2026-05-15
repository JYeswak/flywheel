# L167 — TRANSACTIONAL-MIGRATION-AND-IDEMPOTENT-SCHEMA-MANDATORY

---
id: L167
title: Schema migrations must be transactional and idempotent
status: long_term
shipped: 2026-05-15
review_due: 2026-11-15
trauma_class: non-transactional-non-idempotent-schema-mutation
source_owner: skillos
source_locator: /Users/josh/Developer/skillos/.flywheel/doctrine/cross-infisical-project-credential-collision-wrong-tenant-connect.md
ratification: .flywheel/handoffs/20260512T052716Z-from-flywheel-1-to-skillos-1-L163-L167-RATIFICATION.md
---

Schema migrations must be wrapped in a transaction with rollback-on-error and
must use idempotent constructs where the database supports them.

The origin incident was a near miss: rollback and idempotent schema shape turned
a wrong-tenant migration attempt into a contained failure. This rule makes that
property intentional instead of lucky.

## Flywheel application

Flywheel gates for API/database-facing repos should reject migration apply paths
that cannot show transaction behavior, idempotent DDL shape, and tenant
verification before mutation. Where a database engine has limited transactional
DDL, the runbook must name the compensating safety mechanism before apply.

## SkillOS source

- SkillOS canonical:
  `/Users/josh/Developer/skillos/.flywheel/doctrine/cross-infisical-project-credential-collision-wrong-tenant-connect.md`
- Flywheel ratification:
  `.flywheel/handoffs/20260512T052716Z-from-flywheel-1-to-skillos-1-L163-L167-RATIFICATION.md`

