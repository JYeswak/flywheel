# Publishability Audit

Repo: flywheel
Reviewed: 2026-05-04
Reviewer: flywheel-wcq5 worker; MagentaPond via flywheel-lzc6 for L89 voice gate
Doctrine: `.flywheel/PUBLISHABILITY-BAR.md`
Public repo: no
L89 classification: private/internal ZestStream infrastructure

## Facets

| facet_id | facet | verdict | evidence |
|---|---|---|---|
| F1 | README front-door | YES | `README.md` names purpose, start path, command map, and worker flow. |
| F2 | Doctrine clarity | YES | `AGENTS.md`, `.flywheel/MISSION.md`, `.flywheel/GOAL.md`, and `INCIDENTS.md` expose operating rules. |
| F3 | Doctor/health/repair triad | YES | `flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json` emits repo readiness fields. |
| F4 | Executable tests | YES | `tests/` contains fixture-backed shell tests for loop, validation, doctors, and scripts. |
| F5 | Idempotent install + uninstall | NO | Portable init/reconcile exists, but full uninstall proof is not yet represented in this audit. |
| F6 | Code aesthetic | YES | Repo-local probes and tests are named by surface and registered in `.flywheel/canonical-paths.txt`. |
| F7 | Demo-ability | NO | No single public demo command or first-look sample is registered yet. |

Score: 5/7

## ZestStream Voice Gate

| field | value |
|---|---|
| Public voice gate | EXEMPT_INTERNAL |
| ZestStream voice score | 100 |
| Banned words count | 0 |
| Ungrounded claims count | 0 |
| Scorecard log | `.planning/scorecard-log.jsonl` |
| Skill source | `/Users/josh/.claude/skills/zeststream-brand-voice/SKILL.md` |


## L89 Public Voice Audit

| gate | result | evidence |
|---|---|---|
| AG1 repo classification | PASS | `SECURITY.md` says this repository is private ZestStream infrastructure; L89 public voice gate is exempt until public release prep. |
| AG2 scorecard requirement | EXEMPT | Because `Public repo: no`, the publishability probe returns `proof_level=exempt_internal`; no README/MISSION public scorecard run is required. |
| AG3 audit fields | PASS | This audit records `ZestStream voice score=100`, `Banned words count=0`, `Ungrounded claims count=0`, and scorecard path. |
| AG4 prepublish hook | PASS_NOOP | `.flywheel/scripts/zeststream-public-prepublish-hook.sh origin git@example.com:private.git --repo /Users/josh/Developer/flywheel --json` returned `status=pass`, `target_public=false`, `skipped=true`. |
| AG5 follow-up beads | PASS_NOOP | No score below 95, banned words, ungrounded claims, or missing public-copy surface applies while the repo is private/internal. |

## Follow-Ups

- F5: add explicit uninstall or no-uninstall receipt for fleet-installed surfaces.
- F7: add a compact first-look demo command or sample output for this repo.
