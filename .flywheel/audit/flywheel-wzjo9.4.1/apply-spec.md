# flywheel-wzjo9.4.1 — apply-spec

## Identity

**Bead:** flywheel-wzjo9.4.1
**Wave label:** wave-2.0d-a (sub-bead a of 2 in wave-2.0d — recovery lane cleanup)
**Parent (wave):** flywheel-wzjo9.4
**Grandparent (lane):** flywheel-wzjo9

## Surface

| Attribute | Value |
|---|---|
| Name | `npm-install-guard.sh` |
| Path | `/Users/josh/.claude/skills/.flywheel/bin/npm-install-guard.sh` |
| Lines | 38 |
| Interpreter | bash |
| Priority | P2 |
| Location | skill bin |

## Special note

**SMALL-GUARD VARIANT:** 38 lines — second-smallest surface in lane (after wzjo9.3.8 at 37 lines). The script's sole purpose is to BLOCK global `npm install` if codex processes are running (returns rc=0 safe / rc=1 blocked). Canonical scaffold will expand ~20x → ~750 lines.

Closest variant in tetrad: **guard-class** (similar to wzjo9.3.8 version-check). The cmd_run is a binary safety gate; canonical surfaces probe the gate's substrate (pgrep + tmux + FLYWHEEL_NPM_FORCE override).

## Scope

Single-surface scaffold + 18-TODO substantive fillin following the canonical sister-fillin shape (wave-2.0c avg 990).

## Deliverables

1. **Dry-run scaffold:** `scaffold-canonical-cli.sh /Users/josh/.claude/skills/.flywheel/bin/npm-install-guard.sh --json`
2. **Apply with idempotency-key:** `scaffold-canonical-cli.sh /Users/josh/.claude/skills/.flywheel/bin/npm-install-guard.sh --apply --idempotency-key=flywheel-wzjo9.4.1-pilot --json`
3. **Substantive 18-TODO fillin** matching guard-class pattern (similar to wzjo9.3.8 version-check):
   - doctor: ≥5 substrate probes (pgrep on PATH, tmux on PATH, FLYWHEEL_NPM_FORCE env state, codex-process live count, tmux-session live count)
   - repair: 2 scopes (`audit-log-rotate` 5MB + `force-override-prime` read-only probe of FLYWHEEL_NPM_FORCE)
   - validate: 5 subjects (row, schema, config, **codex-state**, **guard-status**) — last two are guard-class-specific
4. **Test additions:** extend baseline 13-test scaffold to 20

## Acceptance gates

- AG1: 18 TODO markers replaced
- AG2: bash -n clean
- AG3: canonical-cli-lint clean
- AG4: scaffold-test PASS (≥13/13, prefer 20/20)
- AG5: each canonical surface returns concrete data

## Validation predicate (strict)

```bash
cd /Users/josh/Developer/flywheel
bash -n /Users/josh/.claude/skills/.flywheel/bin/npm-install-guard.sh \
  && grep -c 'TODO(canonical-cli-scaffold)' /Users/josh/.claude/skills/.flywheel/bin/npm-install-guard.sh | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh /Users/josh/.claude/skills/.flywheel/bin/npm-install-guard.sh \
  && bash tests/npm-install-guard-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

## Estimated wall-time

20-30 min (small surface; guard-class fillin pattern transferable from wzjo9.3.8).

## Cross-refs

- Parent (wave): flywheel-wzjo9.4
- Lane: flywheel-wzjo9
- Sister wave-2.0c (CLOSED 9/9 avg 990) — variant taxonomy operational
- Closest pattern match: wzjo9.3.8 (tick-skill-version-check, guard-class)
- Scaffolder: .flywheel/scripts/scaffold-canonical-cli.sh
- Helper lib: .flywheel/lib/canonical-cli-helpers.sh

## Doctrine pointers

- Use local skill_root pattern (independent of `_SCAFFOLD_REPO_ROOT`) per wzjo9.3.3 thin-wrapper lesson
- 3 orthogonal canonical surfaces (doctor + repair + validate) observing same substrate state per producer+product variant doctrine
- cmd_run guard rc=0/1 semantics preserved (canonical layer doesn't replace the gate behavior)
