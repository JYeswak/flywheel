# MP-54 — Template publish gate

**Discovered:** 2026-05-19T08:39Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Reusable artifacts need a publish gate beyond syntactic validity: manifests, draft state, registry entries, dry-runs, rollback windows, and human-readable support blocks must agree.

## Where it applies

n8n templates, workflow migrations, crate publishing, repo hygiene plans, installer packages, and any reusable package promoted from local work to shared substrate.

## Adoption signal

Skill distinguishes draft from published, validates manifests, registers artifacts, performs dry-runs, and blocks destructive publish/cutover until rollback and supportability are proven.

## Exemplar skills (≥5)

- `~/.claude/skills/n8n-template-standard/SKILL.md:28` — `DRAFT_NOT_PUBLISHED` is allowed only with explicit publication gates.
- `~/.claude/skills/n8n-template-standard/SKILL.md:35` — template review reports PASS/WARN/FAIL and does not publish or deploy.
- `~/.claude/skills/n8n-template-standard/SKILL.md:65` — manifest must parse and include standard identity fields.
- `~/.claude/skills/n8n-template-standard/SKILL.md:81` — syntactic validity is not production proof.
- `~/.claude/skills/internal-n8n-ops/SKILL.md:249` — deployed workflows are registered in workflow and webhook registries.
- `~/.claude/skills/n8n-migration-v1-to-v2/SKILL.md:89` — v1 deletion waits seven days while rollback stays open.
- `~/.claude/skills/rust-crates-publishing/SKILL.md:35` — publishing requires a local dry-run.
- `~/.claude/skills/repo-hygiene/SKILL.md:126` — apply mode requires reviewed YAML and an idempotency key.

## Adoption recipes

**Recipe 1 — Publish state:** encode `draft`, `candidate`, `ready`, or `published` in the manifest and receipt.

**Recipe 2 — Registry proof:** shared artifacts must register in the canonical registry before they count as deployed.

**Recipe 3 — Rollback window:** publish/cutover receipts name rollback command, wait window, and owner.

## Compliance test

```bash
grep -E "(DRAFT_NOT_PUBLISHED|manifest|registry|dry-run|rollback|idempotency key)" SKILL.md || fail
```
