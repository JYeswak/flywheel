# L163 — CROSS-INFISICAL-PROJECT-CREDENTIAL-COLLISION-WRONG-TENANT-CONNECT

---
id: L163
title: Cross-tenant credential routing must be treated as a secrets-class breach surface
status: long_term
shipped: 2026-05-15
review_due: 2026-11-15
trauma_class: cross-tenant-credential-misrouting
source_owner: skillos
source_locator: /Users/josh/Developer/skillos/.flywheel/doctrine/cross-infisical-project-credential-collision-wrong-tenant-connect.md
ratification: .flywheel/handoffs/20260512T052716Z-from-flywheel-1-to-skillos-1-L163-L167-RATIFICATION.md
---

A credential that belongs to tenant A but authorizes tooling against tenant B
is a secrets-class routing failure. The failure is not limited to Infisical; it
generalizes to scoped cloud accounts, deployment teams, vaults, API providers,
and database projects.

The dangerous shape is "credential accepted" without proving "credential
belongs to the expected tenant." Any workflow that can mutate state must treat
that ambiguity as default-deny.

## Flywheel application

Flywheel orchestration and fleet checks must distinguish "tool authenticated"
from "tool authenticated to the expected tenant." The second fact requires a
registry-backed or provider-backed identity check before mutation.

## SkillOS source

- SkillOS canonical:
  `/Users/josh/Developer/skillos/.flywheel/doctrine/cross-infisical-project-credential-collision-wrong-tenant-connect.md`
- Flywheel ratification:
  `.flywheel/handoffs/20260512T052716Z-from-flywheel-1-to-skillos-1-L163-L167-RATIFICATION.md`

