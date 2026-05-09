# flywheel-th8w Compliance Pack

Task: `flywheel-th8w-ca7233`

## Artifact State

- Skill path exists: `/Users/josh/.claude/skills/agent-fleet-management/`.
- Main skill file exists: `/Users/josh/.claude/skills/agent-fleet-management/SKILL.md`.
- Skill support files exist: `SELF-TEST.md`, 3 references, 1 script.
- No direct live skill mutation was performed in this dispatch.

## Acceptance Mapping

- New skill path: present.
- Required sections: present in `SKILL.md`:
  - account inventory
  - machine inventory
  - token-budget tracking and composite leverage score
  - swap-MAX-tier rotation rule
  - leverage anti-pattern catalog
- Donella Meadows and bitter-lesson framing: present.
- Composes with:
  - `agent-cost-optimization`
  - `coding-agent-usage-tracker`
  - `dicklesworthstone-stack`
  - `donella-meadows-systems-thinking`
  - `leverage-ceiling-probe`
- JSM publication state: local authored skill is validated; external `jsm push`
  remains explicitly deferred to open decision bead `flywheel-syfq`.
- Exact prompt block: present.

## Validation

```bash
jsm validate /Users/josh/.claude/skills/agent-fleet-management --json --offline
# success=true, errors=[], warnings=[]

bash -n /Users/josh/.claude/skills/agent-fleet-management/scripts/fleet-leverage-snapshot.sh

bash /Users/josh/.claude/skills/agent-fleet-management/scripts/fleet-leverage-snapshot.sh --info --json
# version=leverage-ceiling-probe.v1

bash /Users/josh/.claude/skills/agent-fleet-management/scripts/fleet-leverage-snapshot.sh --json
# success=true, status=critical, leverage_ceiling_score=235, binding_constraint=machines

rg -n "THE EXACT PROMPT|Account Inventory|Machine Inventory|Token-Budget|swap-MAX|Anti-Patterns|Donella|Bitter|agent-cost-optimization|coding-agent-usage-tracker|dicklesworthstone-stack|donella-meadows|leverage-ceiling-probe" /Users/josh/.claude/skills/agent-fleet-management/SKILL.md
# all required anchors found
```

## JSM Discipline

- `jsm status agent-fleet-management --json` is not a valid command shape for the installed JSM CLI.
- Packet discipline validator was attempted and failed because its internal
  `jsm list --json` probe timed out after 20 seconds.
- `jsm list --json --offline` and `jsm status --json --offline` also hung and
  were stopped.
- Because this dispatch did not mutate the live skill, no JSM-managed direct
  edit risk was introduced.
- Existing follow-up `flywheel-syfq` tracks the explicit publish/redaction
  decision for `jsm push`.

## Skill Routes

- `canonical-cli-scoping`: addressed as n/a. This dispatch did not author or
  change a CLI; it validated the existing skill wrapper and cites the canonical
  JSM discipline outcome.
- `rust-best-practices`: n/a, no Rust changed.
- `python-best-practices`: n/a, no Python changed.
- `readme-writing`: n/a, no README changed.

## Four-Lens Self-Grade

- Brand: 8/10. The skill names the ZestStream fleet constraint model without
  exposing secrets or private account material.
- Sniff: 8/10. The artifact is small, validated, and has a live probe wrapper.
- Jeff: 9/10. It wraps Jeff/JSM skill flow, Beads, and the Dicklesworthstone
  substrate into reusable fleet doctrine.
- Public: 8/10. Skeptical operator, maintainer, and future worker can verify
  the skill through explicit commands and the open publication decision bead.

Compliance score: 860/1000.

## L112

Probe:

```bash
test -f /Users/josh/.claude/skills/agent-fleet-management/SKILL.md && jsm validate /Users/josh/.claude/skills/agent-fleet-management --json --offline 2>/dev/null | jq -e '.success == true and (.errors | length == 0)'
```

Expected: `jq:true`
