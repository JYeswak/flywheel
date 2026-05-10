# flywheel-g6xaw redispatch evidence — 2026-05-10T02:57:58Z

Worker: CloudyMill (codex-pane / claude-orch)
Task ID: flywheel-g6xaw-d80bbe
Disposition: **BLOCKED** (canonical trigger-gated-bead-BLOCKED-disposition-class)

## Summary

g6xaw is the trigger-gated FrankenTerm-adoption bead. Re-dispatched at
2026-05-10T02:57:58Z; AG1 still not met. Disposing as BLOCKED with a
self-protective follow-up bead so this round-trip cannot recur.

## AG1 mechanical probe

```bash
gh repo view Dicklesworthstone/frankenterm \
  --json name,url,isPrivate,latestRelease,pushedAt,description
```

Result (verbatim, 2026-05-10T02:58:30Z):

```json
{
  "description": "Terminal hypervisor for AI agent swarms: real-time pane capture, state-machine pattern detection, and a JSON API for coordinating fleets of coding agents across WezTerm",
  "isPrivate": false,
  "latestRelease": null,
  "name": "frankenterm",
  "pushedAt": "2026-05-10T02:55:33Z"
}
```

`latestRelease=null` → AG1 (`tagName >= v0.1.0`) FAILS.

## Watchtower confirmation

```bash
.flywheel/scripts/jeff-binary-version-watchtower.sh --json | jq '.watchlists.frankenterm_release | {status,public_count,release_count}'
```

```json
{ "status": "public_no_release", "public_count": 1, "release_count": 0 }
```

The substrate-side watchtower agrees: trigger has not fired.

## Doctrine cross-check

The lh64t pre-check shipped earlier this session
(`flywheel-lh64t`, commits `0593b34` + `f2e7ac0`) provides exactly this
gate. Demonstrated:

```bash
# g6xaw body + appended structured field + live watchtower
.flywheel/scripts/dispatch-trigger-gated-precheck.sh validate \
  --bead-body-file <g6xaw-body-with-external_trigger_watchtower-frankenterm_release> \
  --json
# rc=6
# {"status":"trigger_not_yet_fired","watchtower_status":"public_no_release",...}
```

So if g6xaw's body had carried the structured field at packet-build time,
the dispatch would have been refused with exit 6. Without the field, the
pre-check emits a warning but does not refuse — that is why this
re-dispatch reached a worker.

## AG2-AG5 status

All blocked behind AG1. Per the canonical trigger-gated-bead disposition
class (parent g6xaw evidence `report.md`), AG2-AG5 are NOT attempted; the
premise is unmet. Returning DECLINED would discard the prep; returning
DONE would silently absorb a not-fired trigger; BLOCKED with a concrete
unblock condition is the canonical shape.

## Self-protective follow-up

Filed `flywheel-ejjur` (P3, chore):

> [bead-hygiene] add external_trigger_watchtower=frankenterm_release to flywheel-g6xaw body

When that bead lands, future re-dispatches of g6xaw build through the
build-dispatch-packet.sh pre-check; orch gets a clean exit-6 refusal at
packet-build instead of round-tripping a worker.

## Disposition

```
blocker_type=external
blocker_class=upstream_release_not_yet_published
unblock_condition=Dicklesworthstone/frankenterm latestRelease.tagName >= v0.1.0
unblock_signal=jeff-binary-version-watchtower.sh frankenterm_release.status flips to released
```

## Cross-references

- Parent `flywheel-ubrb5` (closed) — watchtower author.
- Sister `flywheel-lh64t` (closed) — dispatch-author pre-check.
- Doctrine `.flywheel/doctrine/trigger-gated-bead-precheck.md`.
- Memory `feedback_substrate_watchtower_must_be_wired` — META-RULE.
- Prior g6xaw evidence `report.md` — first BLOCKED disposition (different worker).

## Four-Lens Self-Grade

- brand: 9/10 — canonical-cli-scoping pre-check used as designed; doctrine path cited
- sniff: 10/10 — both gh and watchtower probed independently, results match
- jeff: 9/10 — data decides; the trigger has measurably not fired; clean BLOCKED, not theater
- public: 9/10 — a skeptical operator can re-run the gh probe and watchtower in 5s and reproduce

four_lens=brand:9,sniff:10,jeff:9,public:9
