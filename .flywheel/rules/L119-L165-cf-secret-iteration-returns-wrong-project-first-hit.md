# L165 — CF-SECRET-ITERATION-RETURNS-WRONG-PROJECT-FIRST-HIT

---
id: L165
title: Cloudflare secret iteration must not trust first-hit project selection
status: long_term
shipped: 2026-05-15
review_due: 2026-11-15
trauma_class: cloudflare-secret-first-hit-wrong-project
source_owner: skillos
source_locator: /Users/josh/Developer/skillos/.flywheel/doctrine/cross-infisical-project-credential-collision-wrong-tenant-connect.md
ratification: .flywheel/handoffs/20260512T052716Z-from-flywheel-1-to-skillos-1-L163-L167-RATIFICATION.md
---

Secret iteration across Cloudflare projects must not rely on first-match or
iteration order to choose the project. Iteration order is not a tenant
verification mechanism.

Any Cloudflare secret read/write path must use explicit project/account scope
where the tool supports it. If the tool cannot enforce scope, the wrapper must
verify the selected project against the intended tenant before returning a value
or applying a mutation.

## Flywheel application

Fleet helpers that inspect or synchronize Cloudflare secrets must surface the
project/account ID used, the expected project/account ID, and the verification
source. A first-hit lookup without that proof remains blocked.

## SkillOS source

- SkillOS canonical:
  `/Users/josh/Developer/skillos/.flywheel/doctrine/cross-infisical-project-credential-collision-wrong-tenant-connect.md`
- Flywheel ratification:
  `.flywheel/handoffs/20260512T052716Z-from-flywheel-1-to-skillos-1-L163-L167-RATIFICATION.md`

