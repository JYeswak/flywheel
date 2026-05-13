# Publishability Audit

Repo: flywheel
Reviewed: 2026-05-12
Reviewer: Codex continuation audit for public-share readiness
Doctrine: `.flywheel/PUBLISHABILITY-BAR.md`
Public repo: no
L89 classification: Joshua-owned ZestStream infrastructure, public-ready by default
Public-ready default: yes
Exemption: none

## Facets

| facet_id | facet | verdict | evidence |
|---|---|---|---|
| F1 | README front-door | YES | `README.md` now opens with the public ZestStream/Flywheel story, names the SMB problem, links the first-run guide, and preserves the operator command map. |
| F2 | Doctrine clarity | YES | `AGENTS.md`, `.flywheel/MISSION.md`, `.flywheel/GOAL.md`, and `INCIDENTS.md` expose operating rules and cost citations. |
| F3 | Doctor/health/repair triad | YES | `FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json` surfaces `publishability_bar_score`. |
| F4 | Executable tests | YES | `tests/publishability-bar.sh` validates schema, pass/warn/fail scoring, Flywheel source wiring, and direct publishability JSON; final runtime 1.19s after replacing a full-doctor proxy assertion. |
| F5 | Idempotent install + uninstall | YES | `bash tests/installer-smoke.sh` proves dry-run, install, installed reduced first-run, idempotent reinstall, uninstall, and empty-prefix byte equality. |
| F6 | Code aesthetic | YES | Repo-local probes and tests are named by surface and registered in `.flywheel/canonical-paths.txt`; publishability probe is 331 lines and CLI-scoped. |
| F7 | Demo-ability | YES | `scripts/journey-smoke.sh --matrix claude,codex,openclaw,gemini,reduced --dry-run --json` emits five support-tier rows and runtime-proves reduced dispatch-or-simulate. |

Score: 7/7

## Probe Evidence

| command | status | evidence |
|---|---|---|
| `.flywheel/scripts/publishability-bar.sh --doctor --json --repo /Users/josh/Developer/flywheel` | PASS | `status=pass`, `publishability_bar_score.score=5`, `brand_voice_composite=96`, `banned_words_count=0`, `ungrounded_claims_count=0`. |
| `FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 FLYWHEEL_DOCTOR_CACHE_DISABLE=1 FLYWHEEL_TEAM_ROSTER_NTM_TIMEOUT_SECONDS=0 /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json` | WARN_NO_ERRORS | `status=warn`, `errors=[]`, `repo_docs_state=ready`, `action=inspect_memory_health`, `agent_mail_fd_pressure.status=ok`, `publishability_bar.status=pass`, `watcher_isomorphic.status=pass`; remaining warnings are fleet/backlog hygiene. |
| `bash tests/publishability-bar.sh` | PASS | Validates probe schema, thresholds, Flywheel source wiring, and direct publishability JSON in 1.19s. |
| `bash tests/installer-smoke.sh` | PASS | `SUMMARY pass=10 fail=0`; install/uninstall proof includes installed reduced first-run and empty prefix after uninstall. |
| `bash tests/journey-smoke.sh` | PASS | `SUMMARY pass=7 fail=0`; dry-run matrix validates Claude, Codex, OpenClaw, Gemini, and reduced lanes. |
| `scripts/journey-smoke.sh --matrix claude,codex,openclaw,gemini,reduced --dry-run --json` | PASS | `status=pass`, `lanes=5`, `registry_valid=5`, `runtime_proven=1`, `reduced_dispatch_or_simulate=pass`. |

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
| Facet F5 | repaired | `tests/installer-smoke.sh` now records the public install, idempotent reinstall, uninstall, and empty-prefix proof. |
| Facet F7 | repaired | `scripts/journey-smoke.sh` now provides the first-look dry-run matrix; reduced mode is runtime-proven while full harness rows remain registry-valid until later smoke. |
| L89 banned words | repaired | Follow-up bead `flywheel-lzc6.1` removes public-prose banned-word hits from README/MISSION surfaces and records passing hook evidence. |
