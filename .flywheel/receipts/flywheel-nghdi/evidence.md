# flywheel-nghdi Evidence

## Acceptance Gates

- AG1: authored `.flywheel/scripts/inject-l-rule-hints.sh`.
- AG2: injector emits at most three ranked L-rule hints from `.flywheel/rules`
  shards, or AGENTS fallback when the default shard dir is absent.
- AG3: 30 minute dedup window implemented by task id plus rule id in the
  JSONL emit log.
- AG4: fail-closed behavior implemented: injector passthrough on explicit
  missing rules dir, disabled env, or internal error; build-packet ignores
  injector failure.
- AG5: `.flywheel/scripts/build-dispatch-packet.sh` now runs the injector after
  memory hits and skill auto-routes, and reports `l_rule_hints_count` in JSON.
- AG6: `tests/inject-l-rule-hints.sh` covers known packet to known hints,
  dedup suppression, missing rules dir passthrough, disabled passthrough, and
  no input mutation.

## Verification

```bash
bash -n .flywheel/scripts/inject-l-rule-hints.sh .flywheel/scripts/build-dispatch-packet.sh tests/inject-l-rule-hints.sh
bash tests/inject-l-rule-hints.sh
bash tests/inject-skill-auto-routes.sh
FLYWHEEL_PACKET_BUILT_AT=2026-05-09T04:10:30Z \
  FLYWHEEL_L_RULE_HINTS_LOG="$PACKET_DIR/l-rule-hints.jsonl" \
  .flywheel/scripts/build-dispatch-packet.sh \
    --bead-id flywheel-nghdi --target-pane 2 --target-session flywheel \
    --task-id flywheel-nghdi-test --output-dir "$PACKET_DIR" --apply --json
.flywheel/validation-schema/v1/dispatch-template-audit.sh "$packet_path"
.flywheel/scripts/inject-l-rule-hints.sh --schema | jq empty
```

Observed:

- `tests/inject-l-rule-hints.sh`: `SUMMARY pass=9 fail=0`.
- `tests/inject-skill-auto-routes.sh`: `SUMMARY pass=14 fail=0`.
- Build smoke: `validation_status=pass`, `l_rule_hints_count=3`.
- Dispatch-template audit: `valid=true`.
- Direct probe on this packet emitted `L107,L52,L80`.

## Notes

- Agent Mail MCP reservation failed in this session because the active
  `CloudyMill` registration token was not available to this MCP context.
  L107 shared-surface reservations succeeded for the touched paths.
- The worktree already had substantial unrelated dirty state in
  `.flywheel/scripts/build-dispatch-packet.sh` before this bead; no commit was
  created to avoid bundling other panes' edits.

## Four-Lens Self-Grade

- brand: 8
- sniff: 8
- jeff: 8
- public: 8

Three Judges check: a skeptical operator can rerun the injector and packet
smoke; a maintainer can inspect the narrow script and regression; a future
worker gets explicit doctrine hints without a blocking dependency.
