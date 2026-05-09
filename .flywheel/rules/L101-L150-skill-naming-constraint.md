## L150 — SKILL-NAMING-CONSTRAINT

---
id: L150
title: Skill names stay within Codex loader limits
status: long_term
shipped: 2026-05-09
review_due: 2026-11-09
trauma_class: codex-skill-name-length
---

Every skill package installed into Codex-visible skill roots MUST keep its
loader-visible `SKILL.md` frontmatter `name` at 64 characters or fewer. Human
readability belongs in `description`, README prose, aliases, or cross-reference
docs; it does not belong in an overlong skill identifier.

**How to apply:**
- Before installing or syncing third-party skills into `~/.codex/skills` or
  `~/.claude/skills`, validate every `SKILL.md` frontmatter `name` length.
- For overlong upstream names, preserve a short local alias such as
  `agent-ergonomics-cli-max` and file an upstream issue rather than carrying a
  permanent local-only fork.
- Directory basenames may remain longer for compatibility, but the
  loader-visible skill name must stay under the Codex limit.
- JSM-managed skills follow L146: write a `jsm-push-ready` patch artifact or
  upstream issue, not an unauthorized direct live mutation.

**Forbidden outputs:**
- Installing a skill whose `SKILL.md` frontmatter `name` exceeds 64 characters
  into a Codex-visible root.
- Treating a short directory alias as sufficient while the frontmatter `name`
  remains overlong.
- Directly mutating a JSM-managed skill as the permanent fix without L146
  ownership and patch discipline.

**Evidence:** bead `flywheel-rzgqc`; Codex log error
`invalid name: exceeds maximum length of 64 characters` for
`agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools/SKILL.md`;
local workaround frontmatter `agent-ergonomics-cli-max`; upstream issue
Dicklesworthstone/jeffreysprompts.com#5.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

**Cross-references:** L50, L51, L61, L120, L135, L146, and L147.
