---
title: bead-evidence-indexer.sh canonical-CLI scaffold + 18-TODO fillin
type: evidence
bead: flywheel-lrdum
task: flywheel-lrdum-7368bf
priority: P0
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
parent: flywheel-ok1sk (jloib wave-1; sub-bead 3 of 17)
sister_exemplars: 0pkcf (985 — py-scaffolder), ou656 (985 — py-scaffolder)
interpreter: bash (with python3 heredoc body)
---

# Surface

| Attribute | Value |
|---|---|
| Path | `.flywheel/scripts/bead-evidence-indexer.sh` |
| Lines (before) | 367 |
| Lines (after) | 853 |
| Pre status | canonical_cli_scoping=missing |
| Post status | canonical_cli_scoping=passing |
| Scaffolder | `scaffold-canonical-cli.sh` (bash; bash wrapper around Python heredoc) |
| TODO markers | 18 |
| Verb collisions | NONE |

## Acceptance gates

| Gate | Result |
|---|---|
| AG1: 18 TODO replaced | ✓ TODO 18→0 |
| AG2: bash -n exits 0 | ✓ |
| AG3: lint exits 0 | ✓ 0 violations |
| AG4: tests >= 13 | ✓ 19/19 |
| AG5a: doctor 6+ named probes | ✓ python3, jq, repo_root, beads_dir, state_dir, audit_log_dir |
| AG5b: health binds audit log | ✓ last_run_ts + age + recent + total |
| AG5c: repair scope-specific | ✓ 2 scopes (state_dir, audit_log_dir) |
| AG5d: validate per-subject | ✓ 3 subjects (bead-id, evidence-path, audit-row) |
| AG5e: audit cli_emit_audit_tail | ✓ |
| AG5f: why provenance | ✓ found / not_found / unavailable |

## Domain-specific fillin highlights

- **`validate bead-id`** enforces canonical br id pattern `^flywheel-[a-z0-9]+(\.[0-9]+)*$`
  including dotted sub-bead form (e.g. `flywheel-wzjo9.1.2`) — explicitly tested
- **`validate evidence-path`** restricts to canonical evidence dirs:
  `.flywheel/audit/flywheel-<id>/` OR `.flywheel/journal/`
- **Doctor probes the load-bearing indexing primitives:** python3 (the heredoc
  interpreter) + jq (envelope shaping) + repo_root + .beads/

## L112 verify probe

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/bead-evidence-indexer.sh \
  && grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/bead-evidence-indexer.sh | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/bead-evidence-indexer.sh \
  && bash tests/bead-evidence-indexer-canonical-cli.sh \
  && echo "AG1-5 PASS"
# expected: AG1-5 PASS + SUMMARY pass=19 fail=0
```
