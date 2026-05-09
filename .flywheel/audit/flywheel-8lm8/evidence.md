# flywheel-8lm8 evidence

Task: prove and close the gap that `flywheel-loop init` did not distribute
selected INCIDENTS doctrine to fresh repos.

## Result

The live `flywheel-loop init` path now distributes a selected INCIDENTS snapshot
to fresh repos at `.flywheel/INCIDENTS.md`.

Verified behavior:

- Fresh repo receives `.flywheel/INCIDENTS.md`.
- Snapshot includes `mission-anchor-drift-sub-mission-promotion`.
- Snapshot excludes unrelated `agent-mail-token-continuity-after-compaction`.
- Init JSON declares `.flywheel/INCIDENTS.md` in `planned_writes`.

The remediation shape is intentionally narrow: selected canonical incident
blocks are distributed, not the full canonical INCIDENTS file.

## Evidence Commands

Focused proof:

```bash
proof=$(mktemp -d -t flywheel-8lm8-proof.XXXXXX)
git -C "$proof" init -q
printf '# Probe Repo\n' >"$proof/README.md"
printf '# Fixture AGENTS\n' >"$proof/AGENTS.md"
out=$(~/.claude/skills/.flywheel/bin/flywheel-loop init --repo "$proof" --mission-source "$proof/README.md" --goal-source "$proof/README.md" --state-source "$proof/README.md" --json)
test -s "$proof/.flywheel/INCIDENTS.md"
grep -q 'mission-anchor-drift-sub-mission-promotion' "$proof/.flywheel/INCIDENTS.md"
! grep -q 'agent-mail-token-continuity-after-compaction' "$proof/.flywheel/INCIDENTS.md"
printf '%s' "$out" | jq -e '.planned_writes[] | select(endswith("/.flywheel/INCIDENTS.md"))' >/dev/null
printf 'OK_init_distributes_selected_incidents\n'
```

Observed:

```text
OK_init_distributes_selected_incidents
```

Regression suite context:

- `bash tests/flywheel-loop-core.sh` reported `PASS T3.8 init distributes selected canonical INCIDENTS`.
- The same full suite had one unrelated failure: `T3.2 fleet scan reports flywheel docs ready`, caused by current repo docs drift.

Dispatch packet audit:

```bash
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-8lm8-b50f5e.md
```

Observed: `valid=true`.

## Four-Lens Self-Grade

- brand: 8 - The evidence names the operator-facing contract and avoids broad doctrine copying.
- sniff: 8 - The proof exercises a real fresh repo init, not static grep only.
- jeff: 8 - The shape matches information-flow leverage: distribute selected incidents where future workers will search.
- public: 8 - A skeptical operator, maintainer, and future worker can rerun the L112 probe.
