# Consumer Repo Drift Tenant Registry Owner Workflow

**From:** flywheel:1
**To:** registry-owner lane / JSM-Infisical owner
**Real-word prefix:** CANDLE
**Mission anchor (sender):** `bb5b92c08ea5df4006b87b8233ee78adf0950baf`
**Companion plan:** `/tmp/goal-mode-worker-test-cycle-980-act-tenant-registry-routing/receipt.json`
**Posture:** RATIFICATION-REQUEST
**Block:** SkillOS `consumer-repo-drift` remains WARN until canonical tenant rows and repo declarations are produced, or explicit per-repo deferrals land.

## TL;DR

SkillOS reports three remaining partial consumer repo rows: `terratitle`, `agent-bench`, and `cubcloud-aaas`. Each is missing `.zs-tenant.yaml` because the canonical tenant registry has no concrete row for that slug.

This lane is routing the work only. Do not hand-edit `/Users/josh/.claude/skills/infisical-secrets/data/project-mappings.yaml` from the SkillOS orchestrator lane or this flywheel routing lane.

## Current Live Evidence

Command run from `/Users/josh/Developer/skillos`:

```bash
PATH="$PWD/bin:$PATH" skillos doctor --scope consumer-repo-drift --json
```

Observed status: `WARN`.

Fully bootstrapped rows:

- `mobile-eats`
- `alpsinsurance`
- `blackfoot__nextra_documentation_site`
- `zesttube`
- `clutterfreespaces`

Partial rows:

| repo | repo path | missing surface | registry row |
|---|---|---|---|
| `terratitle` | `/Users/josh/Developer/terratitle` | `.zs-tenant.yaml` | absent |
| `agent-bench` | `/Users/josh/Developer/agent-bench` | `.zs-tenant.yaml` | absent |
| `cubcloud-aaas` | `/Users/josh/Developer/cubcloud-aaas` | `.zs-tenant.yaml` | absent |

Registry path:

```text
/Users/josh/.claude/skills/infisical-secrets/data/project-mappings.yaml
```

Read-only probe found only a comment mention for `terratitle`; no concrete rows for `agent-bench` or `cubcloud-aaas` were found in the registry file.

## Receiver Ask

Use the authorized JSM/Infisical registry workflow to choose one path per repo:

1. Add a canonical registry row, then run the tenant bootstrap flow to generate `.zs-tenant.yaml`.
2. Emit a per-repo deferral receipt naming why the tenant row is not authorable yet.

The row must not be guessed from a comment, TODO placeholder, repo name, or stale cross-repo state. It needs canonical non-secret identifiers for the tenant binding, including the Infisical project id, Supabase project ref/url where applicable, and canonical key validators.

## Suggested Local Contract

Flywheel has an L168 helper that can render non-secret evidence into a registry patch plan:

```bash
python3 /Users/josh/Developer/flywheel/.flywheel/scripts/l168-registry-patch-plan.py \
  --input <registry-evidence-packet.json> \
  --json
```

When evidence is incomplete, that helper emits `decision_required` rows instead of registry patches. That is acceptable close evidence if each repo has a concrete missing-field reason.

## Acceptance Criteria

Return a callback to SkillOS with:

- registry workflow used;
- registry rows added, or per-repo deferral reasons;
- `zs-tenant-doctor` or equivalent validation output for each added row;
- post-action summary from:

```bash
cd /Users/josh/Developer/skillos
PATH="$PWD/bin:$PATH" skillos doctor --scope consumer-repo-drift --json
```

- any generated `.zs-tenant.yaml` paths.

## Current Flywheel Disposition

Flywheel did not mutate the JSM-managed registry and did not generate `.zs-tenant.yaml` files. No dedicated registry-owner NTM pane was present in the active pane list, so this handoff is the durable queued owner-lane packet.

— flywheel:1

Mission anchor: `bb5b92c08ea5df4006b87b8233ee78adf0950baf`
