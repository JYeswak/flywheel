# flywheel-gcaf compliance pack

Task: `flywheel-gcaf-118182`
Bead: `flywheel-gcaf`
Identity: `CloudyMill`
Date: 2026-05-09

## Scope

Evidence close for `[skillos-v2-loop-r1-complete] Routed decisions drove skill updates`.

No runtime source, doctrine, skills, AGENTS, or README surfaces were changed by this worker. This pack records the already-completed routed-decision loop and calls out the current JSM validation caveat instead of treating it as invisible.

## Evidence

| Claim | Evidence |
|---|---|
| Dispatch packet is valid | `bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-gcaf-118182.md` returned `valid=true`. |
| Bead had no dependency blocker | `br dep tree flywheel-gcaf` showed only `flywheel-gcaf` open. |
| AG3 held before artifact write | `br show flywheel-gcaf --json` showed `status=open` before this pack was created. |
| Upstream measurement bead closed | `br show flywheel-mdry --json` returned `status=closed`. |
| Routed update beads processed | `flywheel-vd2c` and `flywheel-a2eo` are both `status=closed`, `priority=3`, and their close reasons name skill updates. |
| Nango social Actions coverage exists | `nango-integrations/SKILL.md:4` includes `action`, `SKILL.md:45-66` describes action/callback proof flow, and `flywheel-vd2c` close reason names `Social Actions (SaaS Posting Through Nango)`. |
| Nango-on-Railway handoff exists | `nango-integrations/references/SELF-HOSTED.md:6-19` records the `Nango on Railway Runbook` and ownership split with `railway-api`. |
| Railway API Nango runbook exists | `railway-api/SKILL.md:73-98` records `Nango on Railway Runbook` covering topology, env scope, deploy health, callback path, migration backup, and handoff back to `nango-integrations`. |
| Source row 4 is preserved | `~/.local/state/flywheel/skillos-routed.jsonl` contains original row ref `line:4:sha256:85717547fcbc4b1a` for `nango-social-actions` and a later `notification_status=notified` row. |
| Source row 5 is preserved | `~/.local/state/flywheel/skillos-routed.jsonl` contains original row ref `line:5:sha256:1342593f3bc1917f` for `railway-nango-selfhost-runbook` and a later `notification_status=notified` row. |
| JSM validation caveat is explicit | Current `jsm validate` fails for both updated skill directories due `EXECUTABLE_NOT_ALLOWED` on executable scripts. This pack does not claim current JSM structural validation passes. |

## JSM Validation Caveat

Current validation commands:

```bash
timeout 20 jsm validate /Users/josh/.claude/skills/nango-integrations --json
timeout 20 jsm validate /Users/josh/.claude/skills/railway-api --json
```

Both return `success=false` with `EXECUTABLE_NOT_ALLOWED` for executable scripts under `scripts/`. This appears aligned with the already-known library-wide executable-bit backlog described in `~/.claude/skills/.flywheel/GAPS-LIVE.md` (`G-CF-38`, `G-CF-52`), but it means this closeout cannot honestly cite current `jsm validate` pass evidence.

Follow-up bead filing was attempted, but `.beads/issues.jsonl` was reserved by `flywheel-syfq-0272b3` at the time this pack was created. If the bead lane opens before callback, this pack will be patched with the follow-up bead ID.

## Acceptance Gates

AG1: Pass. Close evidence is recorded in `.flywheel/audit/flywheel-gcaf/compliance-pack.md` and `.flywheel/receipts/flywheel-gcaf/flywheel-gcaf-118182-evidence.md`.

AG2: Pass with caveat. The targeted L112 probe verifies routed rows, upstream/child bead closure, and skill content coverage. Current `jsm validate` does not pass because of the executable-script policy caveat above.

AG3: Pass. `br show flywheel-gcaf --json` remained `open` until this artifact existed.

## Verification Commands

```bash
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-gcaf-118182.md
br show flywheel-gcaf --json
br show flywheel-mdry --json
br show flywheel-vd2c --json
br show flywheel-a2eo --json
jq -c 'select((.original_row_ref=="line:4:sha256:85717547fcbc4b1a") or (.original_row_ref=="line:5:sha256:1342593f3bc1917f"))' ~/.local/state/flywheel/skillos-routed.jsonl
bash .flywheel/receipts/flywheel-gcaf/l112-probe.sh
```

## Skill Auto-Routes

`canonical-cli-scoping=n/a`: no CLI source changed; existing validation commands already expose machine-readable output where needed.

`rust-best-practices=n/a`: no Rust files changed.

`python-best-practices=n/a`: no Python files changed.

`readme-writing=n/a`: no README or public docs changed.

## L61 Surface

No doctrine, canonical L-rule, or skill surface was modified by this worker. `agents_md_updated=not_applicable`, `readme_updated=not_applicable`, `no_touch_reason=evidence_only_no_doctrine_or_public_readme_surface`.

## L52 / L53

Observed gap: current JSM validation fails for the two updated skills due executable-script policy. Follow-up bead filing is pending `.beads/issues.jsonl` reservation release.

No fuckup row was logged. The gap is a known validation-policy backlog, not a task-blocking runtime incident for the routed-decision loop evidence.

## Four-Lens Self-Grade

`four_lens=brand:7,sniff:8,jeff:8,public:8`

Brand: closes the loop evidence without hiding the validator caveat.

Sniff: claims are tied to Beads, local routed rows, and skill file line evidence.

Jeff: structured closure with pathspec-ready artifacts and a re-runnable probe.

Public: a skeptical operator, maintainer, and future worker can verify the loop evidence and see the validation caveat plainly.

## Compliance Score

`745/1000`

The pack meets dispatch, L112, L120, L126, and token hygiene requirements. The score is reduced because current `jsm validate` does not pass for both updated skills, even though the routed loop evidence and skill coverage are present.
