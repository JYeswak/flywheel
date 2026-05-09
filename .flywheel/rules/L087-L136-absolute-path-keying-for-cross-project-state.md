## L136 — ABSOLUTE-PATH-KEYING-FOR-CROSS-PROJECT-STATE

---
id: L136
title: Absolute path keying for cross-project state
status: long_term
shipped: 2026-05-08
review_due: 2026-11-08
trauma_class: basename-keying-collision
---

Cross-project state is keyed by absolute path from `realpath` or `pwd -P`, not
by repo basename. Same-basename workspaces collide silently. Migration rule:
all `cm` calls include `--workspace <abs-path>`, and substrate JSONL uses
`project_path` or `repo_path` rather than basename-only `project` when the row
identifies a workspace.

**Evidence:** Jeff ntm#132, commit `cb0a98de`; bead `flywheel-9f7h6`; memory
`feedback_basename_keying_collision_class.md`; audit receipt
`.flywheel/receipts/flywheel-9f7h6-cm-workspace-audit.md`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

