---
title: "Repo Hygiene Phase 2 Plan"
type: plan
created: 2026-05-07
frontmatter_source: scaffold-doc-frontmatter
---

# Repo Hygiene Phase 2 Plan

Generated: 2026-05-07T20:28:00Z
Bead: flywheel-1p9of
Phase: 2 PLAN

## Scope

This phase implements the Jeff-reshaped plan surface:

- Build `.flywheel/hygiene-targets.yaml` as the repo-local residue contract.
- Build one universal prompt template that composes existing skills inline.
- Do not author a bundled `repo-hygiene/SKILL.md`.
- Do not ship cleanup scripts, subagents, or references.
- Do not run apply mode.

Phase 1 source:
`/Users/josh/Developer/flywheel/.flywheel/plans/repo-hygiene-meta-skill-2026-05-07/01-RESEARCH-DEEP-DIVE.md`.

## Shipped Artifacts

| Artifact | Purpose |
|---|---|
| `/Users/josh/Developer/flywheel/templates/flywheel-install/hygiene-targets.schema.json` | Authoritative Draft 2020-12 schema for repo-local hygiene YAML |
| `02-PLAN/yaml-drafts/flywheel.yaml` | flywheel seed residue contract |
| `02-PLAN/yaml-drafts/mobile-eats.yaml` | mobile-eats seed residue contract |
| `02-PLAN/yaml-drafts/alpsinsurance.yaml` | alpsinsurance seed residue contract |
| `02-PLAN/yaml-drafts/zesttube.yaml` | zesttube seed residue contract |
| `02-PLAN/yaml-drafts/skillos.yaml` | skillos seed residue contract |
| `/Users/josh/Developer/flywheel/templates/peer-orch-broadcasts/repo-hygiene-prompt-template.md` | Universal inline-skill prompt template |

## Phase 1 Mapping

| Phase 1 finding | YAML field |
|---|---|
| Per-repo trauma classes tables | `trauma_classes[].name`, `patterns`, `safety`, `min_age_days`, `max_total_mb` |
| Cross-repo backup / pycache / build output patterns | repeated `trauma_classes` defaults in each repo draft |
| Per-tooling residue table | `trauma_classes[].applicable_skills` |
| `.gitignore` coverage gaps | `gitignore_gaps[]` with `root_cause_fix_tier` |
| Existing prior art | `provenance.source_sections` and class-level `provenance` strings |
| Amendment #2 inline composition | `repo-hygiene-prompt-template.md` skill line and hard gates |

## Repo Draft Summary

| Repo | Trauma classes | Gitignore gaps | Dominant measured stock from Phase 1 |
|---|---:|---:|---|
| flywheel | 5 | 2 | `.beads.bak.*` roots, 719450112 bytes |
| mobile-eats | 5 | 3 | `next-app/node_modules/`, 1028063232 bytes |
| alpsinsurance | 6 | 0 | `*.bak*` and `frontend/.next/`, 1593020416 combined bytes |
| zesttube | 5 | 3 | Remotion outputs and ZestTube caches, 1196178432 combined bytes |
| skillos | 5 | 3 | `.beads/*.bak*`, 73949184 bytes |

## Schema Contract

The schema requires:

- `schema_version: 1`
- absolute `repo_path`
- `doctrine_version` following the date-stamped doctrine pattern
- `safety_contract` with dry-run default, idempotency key, tracked-file refusal, and receipt dir
- trauma classes with unique names checked by convergence smoke test
- each class tagged with applicable inline skills
- gitignore gaps classified by disposition and root-cause tier

The schema intentionally does not contain an apply surface. Apply behavior stays in future implementation, gated by Joshua review and idempotency key.

## Universal Prompt Contract

The prompt template loads:

`/storage-health /dev-cache-janitor /apfs-snapshot-ops /docker-storage-ops /orbstack-ops /storage-ballast-helper /disk-observer /path-rationalization /canonical-cli-scoping /extreme-software-optimization`

It pins the target repo and YAML as context, validates the YAML before measurement, refuses tracked candidates, and emits a read-only `repo_hygiene.dry_run_receipt.v1` JSON contract.

## Proposed Implementation Beads

Recommendations only; no beads were created in this phase.

1. P0 - Ship hygiene-targets schema validator
   Acceptance: validates all five drafts; rejects missing safety contract, invalid safety enum, duplicate trauma class names.

2. P0 - Install seed `.flywheel/hygiene-targets.yaml` files in five repos
   Acceptance: each repo gets the reviewed YAML; `git ls-files` confirms no tracked-file target can be pruned.

3. P0 - Add flywheel doctor probe `hygiene_targets_present`
   Acceptance: doctor emits `hygiene_targets_present`, `hygiene_targets_valid`, `hygiene_unsafe_target_count`, and `hygiene_candidate_total_bytes`.

4. P1 - Add onboarding checklist gate
   Acceptance: flywheel install cannot mark a repo onboarded without valid hygiene targets or an explicit waiver.

5. P1 - Wire repo-hygiene prompt broadcast command
   Acceptance: orchestrator can send the universal prompt to a target session with repo path/YAML substitutions.

6. P1 - Add dry-run receipt schema
   Acceptance: prompt receipts validate as `repo_hygiene.dry_run_receipt.v1` and include class-level measurement fields.

7. P2 - Local prior-art adapters
   Acceptance: flywheel dry-run cites `storage-prune.sh`; zesttube dry-run cites `src/storage/cache_prune.py`; generic deletion stays lower priority.

## Convergence Smoke Test

Command:

```bash
python3 - <<'PY'
import glob, json, yaml
from jsonschema import Draft202012Validator

schema_path = "templates/flywheel-install/hygiene-targets.schema.json"
with open(schema_path, encoding="utf-8") as handle:
    schema = json.load(handle)
Draft202012Validator.check_schema(schema)
validator = Draft202012Validator(schema)

for path in sorted(glob.glob(".flywheel/plans/repo-hygiene-meta-skill-2026-05-07/02-PLAN/yaml-drafts/*.yaml")):
    with open(path, encoding="utf-8") as handle:
        payload = yaml.safe_load(handle)
    validator.validate(payload)
    names = [row["name"] for row in payload["trauma_classes"]]
    assert len(names) == len(set(names)), f"duplicate trauma class in {path}"
    print(f"PASS {path} classes={len(names)} gaps={len(payload['gitignore_gaps'])}")
PY
```

Result: PASS.

## Residual Risks

- The source bead body still names a bundled `repo-hygiene/SKILL.md` in acceptance; the dispatch reshape supersedes it. Future bead text should be amended before full close.
- These are drafts, not installed repo-local YAML files. Phase 3 should copy reviewed drafts into each repo.
- The prompt template references a future dry-run receipt schema that should be formalized in the implementation bead.

## Recommendation

Advance to implementation planning with the YAML-plus-prompt design. The next concrete ship should be the validator/doctor probe pair, not a new skill wrapper.
