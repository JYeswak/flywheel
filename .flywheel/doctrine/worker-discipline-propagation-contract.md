# Worker Discipline Propagation Contract

Source bead: `flywheel-2uha0`
Status: dry-run primitive, Joshua-gated for real cross-orch writes
Authority boundary: flywheel mirrors and proposes; skillos canonical-locator owns canonical absorption decisions.

## Propagated Doctrines

The propagation package covers these six worker-discipline doctrines:

1. `auto-push-blocked-worker-discipline.md`
2. `codex-goal-mode-discipline.md`
3. `dry-run-apply-parity-contract.md`
4. `dcg-worker-freeze-discipline.md`
5. `runtime-doctrine-separation-discipline.md`
6. `repo-hygiene-tick-discipline.md`

The codex goal-mode doctrine is skillos-canonical. Flywheel may mirror it into
repo-local doctrine surfaces for conformance measurement, but canonical edits
belong to the skillos canonical-locator lane.

## Absorption Checklist

For each orch, the propagation primitive checks:

- all six doctrine files exist at repo-local canonical doctrine paths;
- the four memory pins are indexed in that repo's `MEMORY.md`;
- the dispatch template names the Codex activation primitive or `/goal` rule;
- the worker tick contract requires post-callback `auto_push_status` verification;
- missing hooks are reported as propagation gaps, not silently treated as applied.

Real fleet writes are not automatic. `worker-discipline-propagate.sh --apply`
refuses real cross-orch targets unless the Joshua plus skillos canonicalization
gate is explicit. Synthetic test repos may use apply mode to prove the mutation
path.

## Conformance Score

`discipline-conformance-probe.sh` scores each orch across 12 atomic checks:

- 6 doctrine-file checks;
- 4 memory-pin checks;
- 1 dispatch-template activation primitive check;
- 1 post-callback auto-push verification check.

Score formula:

```text
score = passed_atomic_checks / 12
```

The default P2 threshold is `0.85`. Below-threshold repos receive an auto-bead
action. In dry-run mode the action is reported as `dry_run`; in apply mode the
probe creates a repo-local P2 bead through `br create`.

## Cross-Orch Write Gate

The safe default is read-only:

```bash
.flywheel/scripts/discipline-conformance-probe.sh --fleet-default --dry-run --auto-bead --json
```

Actual peer-repo doctrine or memory mutation is out of scope until Joshua and
skillos authorize canonicalization. The only valid apply path for real
cross-orch targets requires explicit operator intent plus the skillos
canonical-locator decision. Flywheel workers must not infer that authorization
from the existence of a missing doctrine file.
