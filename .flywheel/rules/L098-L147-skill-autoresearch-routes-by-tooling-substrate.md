## L147 — SKILL-AUTORESEARCH-ROUTES-BY-TOOLING-SUBSTRATE

---
id: L147
title: Skill-autoresearch routes by tooling substrate
status: long_term
shipped: 2026-05-09
review_due: 2026-11-09
trauma_class: skill-autoresearch-python-vs-shell-mismatch
---

Skill-enhance dispatches MUST classify the target tooling substrate before
using `skill-autoresearch` as an evaluator or rewrite driver.

Shell-first flywheel surfaces are not routed through `skill-autoresearch` as
the primary path. This includes `canonical-cli-scoping`, `jsm`, `beads-br`, and
`agent-orchestration`, plus skillos requests whose output is a shell/transport
contract. Workers must re-author these with shell-first acceptance gates:
existing shell entrypoint, canonical-cli-scoping triad, dry-run/apply
discipline, JSON schema, stable exit codes, Beads/JSM ownership rules, and
runtime receipts.

Python-operational skill targets may use `skill-autoresearch` when Python
tooling is the intended substrate, including `skill-builder`-managed skills
where the `scripts/` artifact is a Python CLI.

**Evidence:** bead `flywheel-ftj0m`; doctrine
`.flywheel/doctrine/skill-autoresearch-tooling-preference-class.md`; packet
guard `.flywheel/scripts/build-dispatch-packet.sh`; regression
`tests/skill-autoresearch-tooling-preference-class.sh`; failed pattern beads
`flywheel-spdu`, `flywheel-2gvl`, and `flywheel-njzi`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

**Cross-references:** L50, L51, L61, L120, L146, and
`~/.claude/skills/skill-autoresearch/SKILL.md`.

