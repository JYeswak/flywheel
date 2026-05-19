# MP-128 - Substrate health and recovery ladder

**Discovered:** 2026-05-19T07:56Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Substrate work needs registry metadata, runtime detection, exit-coded health probes, cheapest-first recovery, and explicit approval before destructive or cross-boundary actions.

## Where it applies

Docker and OrbStack runtime dependencies, named volumes, flywheel substrate bundles, validator scripts, doctor invariants, skill packs, stateful services, and remote validation suites.

## Adoption signal

The skill registers the substrate, names consumers and validators, probes the runtime before action, distinguishes state from process, uses a recovery ladder that never auto-escalates, and requires approval for destructive reset or live mutation.

## Exemplar skills (>=5)

- `~/.claude/skills/install-substrate/SKILL.md:9` - substrate should not ship without future discoverability for how, why, where, consumers, and retirement.
- `~/.claude/skills/install-substrate/SKILL.md:43` - registry rows require name, kind, scope, version, source, owner, validator, consumers, state, and retirement fields.
- `~/.claude/skills/install-substrate/SKILL.md:81` - workflow starts by checking the existing registry.
- `~/.claude/skills/install-substrate/SKILL.md:90` - validation runs substrate registry checks and flywheel doctor.
- `~/.claude/skills/orbstack-ops/SKILL.md:18` - OrbStack work probes before any Docker assumption.
- `~/.claude/skills/orbstack-ops/SKILL.md:38` - recovery captures health-probe exit code and reason.
- `~/.claude/skills/orbstack-ops/SKILL.md:44` - after two escalations, stop and surface diagnosis instead of resetting data.
- `~/.claude/skills/docker-volume-ops/SKILL.md:12` - volumes are state and `docker volume rm` is irreversible.
- `~/.claude/skills/docker-volume-ops/SKILL.md:102` - backup-before-rm is a core pattern.
- `~/.claude/skills/cubcloud-validate/SKILL.md:11` - a green CI pipeline is necessary but not sufficient.

## Adoption recipes

**Recipe 1 - Registry and consumer map:** record substrate fields, consumers, validator, doctor invariant, state path, and retirement path before calling it installed.

**Recipe 2 - Health before repair:** run runtime-specific, exit-coded probes and capture status, reason, branch, or context.

**Recipe 3 - Recovery ladder:** try no-side-effect and cheap recovery first; require approval and backup evidence before destructive or live-system mutation.

## Compliance test

```bash
grep -E "(registry|consumer|validator|doctor|health-probe|exit code|runtime|recovery ladder|backup|destructive|approval)" SKILL.md || exit 1
```
