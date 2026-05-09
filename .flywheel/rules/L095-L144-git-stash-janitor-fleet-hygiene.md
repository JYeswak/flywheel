## L144 — GIT-STASH-JANITOR-FLEET-HYGIENE

---
id: L144
title: Git stash janitor fleet hygiene
status: long_term
shipped: 2026-05-08
review_due: 2026-11-08
trauma_class: stash-bloat-state-leak
---

Stash bloat is repo state leakage. The flywheel skill arsenal treats
`/git-stash-janitor` as the cleanup surface next to `dicklesworthstone-stack`:
use stash count `<5` as manual/default-no-run territory, `5-9` as Quick mode,
`10-80` as Standard mode, and `80+` as Comprehensive mode. `/flywheel:tick`
Step 4 fleet self-diagnosis MUST surface any fleet repo with `>=10` stashes as
soft signal `fleet_stash_bloat_detected`; `/flywheel:onboard` MUST include a
stash-count health check and recommend `/git-stash-janitor` before continuing
when the target repo has `>=10` stashes.

Recovery bundles are user-owned safety artifacts. The shared convention is:
`<project-parent>/<basename>-stash-archive-YYYY-MM-DD/`. Orchestrators and
cleanup agents MUST NOT delete these bundles; lifecycle belongs to the user.

**Evidence:** bead `flywheel-hnul2`; self-audit hygiene finding
`.flywheel/PLANS/flywheel-self-audit-2026-05-08/audits/hygiene.md`; skill
source `~/.claude/skills/git-stash-janitor/SKILL.md` and
`~/.claude/skills/git-stash-janitor/references/BUNDLE-FORMAT-SPEC.md`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

**Cross-references:** L61, L101, L118, L143, `dicklesworthstone-stack`, and
`git-stash-janitor`.

