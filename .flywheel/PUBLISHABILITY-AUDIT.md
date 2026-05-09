# Publishability Audit

Repo: flywheel
Reviewed: 2026-05-09
Reviewer: CloudyMill via flywheel-lzc6 for L89 public-ready voice gate
Doctrine: `.flywheel/PUBLISHABILITY-BAR.md`
Public repo: no
L89 classification: Joshua-owned ZestStream infrastructure, public-ready by default
Public-ready default: yes
Exemption: none

## Facets

| facet_id | facet | verdict | evidence |
|---|---|---|---|
| F1 | README front-door | YES | `README.md` names purpose, start path, command map, worker flow, and the publishability probe surface. |
| F2 | Doctrine clarity | YES | `AGENTS.md`, `.flywheel/MISSION.md`, `.flywheel/GOAL.md`, and `INCIDENTS.md` expose operating rules and cost citations. |
| F3 | Doctor/health/repair triad | YES | `FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json` surfaces `publishability_bar_score`. |
| F4 | Executable tests | YES | `tests/publishability-bar.sh` validates schema, pass/warn/fail scoring, and doctor JSON wiring. |
| F5 | Idempotent install + uninstall | NO | Portable init/reconcile exists, but full uninstall proof is not yet represented in this audit. |
| F6 | Code aesthetic | YES | Repo-local probes and tests are named by surface and registered in `.flywheel/canonical-paths.txt`; publishability probe is 331 lines and CLI-scoped. |
| F7 | Demo-ability | NO | No single public demo command or first-look sample is registered yet. |

Score: 5/7

## Probe Evidence

| command | status | evidence |
|---|---|---|
| `.flywheel/scripts/publishability-bar.sh --doctor --json --repo /Users/josh/Developer/flywheel` | PASS | `status=pass`, `publishability_bar_score.score=5`, `brand_voice_composite=96`, `banned_words_count=0`, `ungrounded_claims_count=0`. |
| `FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json` | PASS | Doctor JSON includes `publishability_bar.schema_version=publishability-bar/v1` and numeric `publishability_bar_score.score`. |
| `bash tests/publishability-bar.sh` | PASS | Validates probe schema, thresholds, and doctor publishability field. |

## ZestStream Voice Gate

| field | value |
|---|---|
| Public voice gate | PUBLIC_READY_DEFAULT_SCORECARD_LINKED |
| ZestStream voice score | 96 |
| Banned words count | 0 |
| Banned words | none |
| Ungrounded claims count | 0 |
| Scorecard log | `.planning/scorecard-log.jsonl` |
| Skill source | `/Users/josh/.claude/skills/zeststream-brand-voice/SKILL.md` |

## L89 Public Voice Audit

| gate | result | evidence |
|---|---|---|
| AG1 repo classification | PASS | `SECURITY.md` says this repository is private ZestStream infrastructure, but L148 makes private status metadata only; no `EXEMPT_CLIENT_OWNED` or `EXEMPT_PUBLIC_FACING` exemption applies. |
| AG2 scorecard requirement | PASS | `zeststream-brand-voice` structural probe passed after README/MISSION public prose repair; scorecard row appended with composite 96, verdict `pass`, and zero banned-word hits. |
| AG3 audit fields | PASS | This audit records `ZestStream voice score=96`, `Banned words count=0`, `Ungrounded claims count=0`, and scorecard path. |
| AG4 prepublish hook | PASS_ENFORCING | `.flywheel/scripts/zeststream-public-prepublish-hook.sh public git@example.com:public.git --repo /Users/josh/Developer/flywheel --json` returns `status=pass` after the public-copy repair. |
| AG5 follow-up beads | PASS | Follow-up bead filed for the public-copy banned-word repair. |

## Follow-Ups

| facet | disposition | receipt |
|---|---|---|
| Facet F5 | no_bead_reason | Existing score is passing at 5/7; this audit records the gap without minting another bead because install/uninstall work is already covered by active installer and launchd-install surfaces (`flywheel-nh6d`, `flywheel-l5go`, `flywheel-cwdu`). |
| Facet F7 | no_bead_reason | Existing score is passing at 5/7; demo-ability is intentionally deferred until the conductor/onboarding proof path (`flywheel-4vfa`) creates a real first-look flow instead of a fixture-only demo. |
| L89 banned words | repaired | Follow-up bead `flywheel-lzc6.1` removes public-prose banned-word hits from README/MISSION surfaces and records passing hook evidence. |
