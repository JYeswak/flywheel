## L144 — GIT-JANITOR-FLEET-HYGIENE

---
id: L144
title: Git janitor fleet hygiene
status: long_term
shipped: 2026-05-08
review_due: 2026-11-08
trauma_class: repo-state-leak
---

Repo dirt is repo state leakage. The flywheel skill arsenal treats
`/git-repo-janitor` and `/git-stash-janitor` as foundational substrate hygiene
surfaces next to `dicklesworthstone-stack`.

For working-tree dirt, `/flywheel:tick`, dispatch gates, daily reports, and
repo-local close surfaces MUST use `.flywheel/scripts/repo-discipline-check.sh`
or an equivalent envelope. The required behavior is not merely to flag dirty
state; it is to route the dirt to a responsible disposition:

- owner-scoped work commits;
- generated/runtime noise restores;
- out-of-scope discoveries become beads;
- recurring untracked artifacts become `.gitignore` work after shadowing audit;
- dirty sets above janitor threshold route to `/git-repo-janitor` in
  `triage-only` mode before unrelated dispatch continues;
- halt-threshold dirty state blocks new unrelated dispatch until a cleanup
  plan, cleanup commit, or explicit skip receipt exists.

For stash bloat, use stash count `<5` as manual/default-no-run territory, `5-9`
as Quick mode, `10-80` as Standard mode, and `80+` as Comprehensive mode.
`/flywheel:tick` Step 4 fleet self-diagnosis MUST surface any fleet repo with
`>=10` stashes as soft signal `fleet_stash_bloat_detected`; `/flywheel:onboard`
MUST include a stash-count health check and recommend `/git-stash-janitor`
before continuing when the target repo has `>=10` stashes.

Recovery bundles are user-owned safety artifacts. The shared convention is:
`<project-parent>/<basename>-stash-archive-YYYY-MM-DD/`. Orchestrators and
cleanup agents MUST NOT delete these bundles; lifecycle belongs to the user.

**Evidence:** bead `flywheel-hnul2`; Joshua direct ask
2026-05-14T16:54Z; self-audit hygiene finding
`.flywheel/PLANS/flywheel-self-audit-2026-05-08/audits/hygiene.md`; skill
sources `~/.claude/skills/git-repo-janitor/SKILL.md`,
`~/.claude/skills/git-stash-janitor/SKILL.md` and
`~/.claude/skills/git-stash-janitor/references/BUNDLE-FORMAT-SPEC.md`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

**Cross-references:** L61, L101, L118, L143, `dicklesworthstone-stack`,
`git-repo-janitor`, and `git-stash-janitor`.
