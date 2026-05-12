# flywheel-rzgqc Skill Naming Findings

## Verification

- Current long-path skill frontmatter:
  - `/Users/josh/.codex/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools/SKILL.md`
    has `name: agent-ergonomics-cli-max` (24 chars).
  - `/Users/josh/.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools/SKILL.md`
    has `name: agent-ergonomics-cli-max` (24 chars).
- Current short alias skill:
  - `/Users/josh/.codex/skills/agent-ergonomics-cli/SKILL.md`
    has `name: agent-ergonomics-cli` (20 chars).
  - `/Users/josh/.claude/skills/agent-ergonomics-cli/SKILL.md`
    has `name: agent-ergonomics-cli` (20 chars).
- Codex logs before the local rename show:
  `invalid name: exceeds maximum length of 64 characters` for the long skill's
  `SKILL.md`.
- Codex logs after the local rename show no new invalid-name rows in the recent
  tail checked during this task.

## Conclusion

The failing limit is the loader-visible `SKILL.md` frontmatter `name`. The
directory basename can remain long after the frontmatter is shortened; current
Codex loaded the skill as `agent-ergonomics-cli-max` from the long path in this
session's active skill list.

## Workaround

The local workaround is already present:

- `name: agent-ergonomics-cli-max` in both long-path skill copies.
- `agent-ergonomics-cli` short copies in both `.codex` and `.claude` roots.
- A `.claude/skills/agent-ergonomics-max` symlink to the long-path skill.

No direct JSM-managed live mutation was performed in this dispatch.

## Upstream

Filed upstream issue:
https://github.com/Dicklesworthstone/jeffreysprompts.com/issues/5

The initially suggested `Dicklesworthstone/jeffreys-skills` repository did not
exist via `gh repo view`; the local upstream repo for Jeffrey's site resolves to
`Dicklesworthstone/jeffreysprompts.com`.

## JSM Discipline

- `jsm status --json` and
  `.flywheel/scripts/skill-enhance-jsm-discipline.sh --validate-packet ...`
  were attempted with a 10 second timeout and produced no usable JSON before
  timeout in this environment.
- L146 was preserved by avoiding direct skill mutation and by filing the
  upstream issue plus a patch artifact.

