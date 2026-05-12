# flywheel-r52ig Compliance Pack

## Scope

Bead: `flywheel-r52ig`
Task: apply `agent-ergonomics-cli-max` to Flywheel's `.flywheel/scripts`
substrate.

## Acceptance Gates

- AG1: Top-10 inventory written to `audit/top_10_cli_inventory.jsonl`.
- AG2: Skill inventory/recommendation artifacts written for the ranked top-3:
  `flywheel-loop`, `dispatch-and-verify`, and `sync-canonical-doctrine`.
- AG3: Low-blast auto-mode change applied to `dispatch-and-verify.sh`; high-blast
  recommendations deferred in `recommendations.jsonl`.
- AG4: Post-change scores and first-try simulation receipts written to
  `audit/post_scores.jsonl` and `audit/fresh_agent_simulations.jsonl`.
- AG5: Doctrine baseline written to
  `.flywheel/doctrine/agent-ergonomics-application-baseline-2026-05-08.md`.
- AG6: Quarterly cadence established in the doctrine baseline with
  `next_due=2026-08-08`.

## Applied Change

`dispatch-and-verify.sh` now has agent-friendly introspection:

- `--help` exits 0.
- `--info --json` reports runtime defaults.
- `--examples --json` reports copy-paste workflows.
- `--schema` reports exit-code and JSON-surface contract.

`tests/dispatch-and-verify.sh` pins these surfaces.

## Verification

- `bash -n .flywheel/scripts/dispatch-and-verify.sh`: PASS
- `bash -n tests/dispatch-and-verify.sh`: PASS
- `bash tests/dispatch-and-verify.sh`: PASS, 14 pass
- `git diff --check -- <touched files>`: PASS
- `.flywheel/receipts/flywheel-r52ig/l112-probe.sh`: PASS

## Notes

The full skill preflight reports missing `flock` on macOS. The mini audit path
used direct inventory/recommendation artifacts and logged skill discovery
`sd-95764cf96b7e70c1` so the skill can add a Darwin fallback.

No root `AGENTS.md` or `README.md` change was made; this bead's durable doctrine
surface is the named baseline page.

## Four-Lens Self-Grade

- Brand: 8/10
- Sniff: 8/10
- Jeff: 8/10
- Public: 8/10

