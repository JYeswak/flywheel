---
bead: flywheel-mrjzb
title: 70-repo triage recommendation — KEEP-and-LIFT / ARCHIVE / JEFF-AUDIT-ONLY with license pre-check
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: DONE
priority: P1
mission_fitness: adjacent
parent: flywheel-cu6u9 (sibling — inventory)
sub_bar_framing: 2026-05-11T23:30Z Joshua approval deadline
---

# mrjzb evidence pack — 70-repo triage manifest

## What this bead ships

`inventory/triage-manifest.json` — per-repo classification of all 70 jyeswak github repos (from cu6u9 inventory) into 3 buckets with rationale + license action.

## Distribution

| Triage | Count | License action distribution |
|--------|-------|----------------------------|
| KEEP-and-LIFT | 36 | 24 ADD_MIT, 7 KEEP_EXISTING:MIT, 3 NONE_PRIVATE_PERSONAL, 2 KEEP_EXISTING:Other |
| ARCHIVE | 32 | 32 NONE_PRE_RETIRE |
| JEFF-AUDIT-ONLY | 2 | 2 JEFF_UPSTREAM_AUTHORITATIVE |
| **TOTAL** | **70** | |

## Acceptance gates (implicit from bead title)

| # | Gate | Status | Evidence |
|---|------|--------|----------|
| 1 | Per-repo KEEP-and-LIFT / ARCHIVE / JEFF-AUDIT-ONLY classification for ALL 70 repos | DID | sanity-check assertion in builder script (missing/extra triage entries → AssertionError); 70 manifest rows |
| 2 | Per-repo rationale for each classification | DID | each row has `rationale` field with concrete justification (size, staleness, scope, substrate-boundary class) |
| 3 | LICENSE pre-check with MIT default | DID | `license_action_required` field per row: ADD_MIT for unlicensed KEEP-and-LIFT, KEEP_EXISTING for already-licensed, NONE_PRIVATE_PERSONAL for josh-*, NONE_PRE_RETIRE for ARCHIVE, JEFF_UPSTREAM_AUTHORITATIVE for Jeff forks |
| 4 | Output `triage-manifest.json` for Joshua approval | DID | `inventory/triage-manifest.json` (30KB, 70 rows + summary metadata) |
| 5 | Reference cu6u9 inventory | DID | manifest `source_inventory` field points to `inventory/jyeswak-repos.jsonl (cu6u9)` |
| 6 | Sub-bar framing 2026-05-11T23:30Z | DID | manifest `sub_bar_framing` field |
| 7 | Substrate-boundary-three-class-taxonomy respected | DID | mcp-agent-mail + beads_rust classified JEFF-AUDIT-ONLY with explicit Class 3 reference |

`did=7/7`, `didnt=none`, `gaps=none`.

## Notable triage decisions

**JEFF-AUDIT-ONLY (2)**: `mcp-agent-mail`, `beads_rust` — both are jyeswak forks of Jeff Emanuel's canonical substrate; canonical-locator authority lies with Dicklesworthstone upstream. No flywheel-side mutation per substrate-boundary-three-class-taxonomy Class 3 discipline.

**KEEP-and-LIFT (36)**: All actively-pushed ZestStream / flywheel / client repos. Subgroups:
- **CORE substrate** (3): flywheel, zeststream-skillos, ZestStream-v2
- **Commercial clients** (6): alps-insurance, polymarket-pico-z, ClutterFreeSpaces, mobile-eats, vrtx, terratitle
- **ZestStream commercial surfaces** (8): zeststream-platform, zeststream-brand-voice, zeststream-procurement, zeststream-infra, zeststream-pipeline, zesttube, zesttube-avatars, ZestStream (legacy v1)
- **Personal-substrate KEEP-PRIVATE** (3): josh-claude-config, josh-ops, josh-connect-ui-zeststream
- **AI/infra tooling** (7): comfyui, email-migration, fleet-commander, gpu-optimization, langgraph-toolkit, local-agents, agent-bench
- **Orchestrator research** (3): orchestrator-a, orchestrator-b, orchestrator-c
- **Brand surfaces** (3): cubcloudwebsite, cubcloud-docs, soundsoftheforest
- **Active small** (3): agno-service, remy, 100minds-mcp

**ARCHIVE (32)**: 90d+ stale OR scratch. Notable clusters:
- **aider-test* cohort** (6): all sub-50KB scratch from a test-driver session
- **Tiny stubs** (6): coo, grok-voice-demos, ai-benchmark-research, fleet-dashboard, rano, cc-router — recent push but minimal content
- **ElektraFi-era artifacts** (3): ISP-Acquisition-AI, claims-automation-catalog, Operations — Joshua left 2025-12-31; these are pre-transition
- **101d-stale abandoned experiments** (13): chatbot, email-assistant, video-audio-mcp, Customer_Service, Dialpad-HubSpot-Integration, eo-insurance-catalog, 100-minds-research, 100minds-ai (superseded by 100minds-mcp KEEP), ServerPlus-Research, multi-agent, sinfulgemma, agent-improvement-meta, ceo-api-service
- **Borderline (manual confirm before retiring)** (4): opencode-grok-first-router (117d), optimization-research (94d, 144MB), swarm-daemon (86d, 178MB), openclaw-smb (82d)

## License pre-check summary

- 24 repos need MIT license added (default per bead body) — all KEEP-and-LIFT non-personal repos that currently have no license file
- 7 repos already have MIT — no action
- 3 personal-substrate repos (josh-*) explicitly stay PRIVATE without public license
- 2 repos already have a non-MIT license ("Other") — KEEP_EXISTING, manual review for upgrade-to-MIT before public lift
- 32 ARCHIVE repos: no license action needed pre-retire
- 2 JEFF-AUDIT-ONLY repos: license upstream-authoritative; no flywheel-side action

## L112 probe

```bash
test -f /Users/josh/Developer/flywheel/inventory/triage-manifest.json && python3 -c "import json; m=json.load(open('/Users/josh/Developer/flywheel/inventory/triage-manifest.json')); print(m['total_repos'])"
```

Expected: literal `70`.

## Files changed

- `inventory/triage-manifest.json` — new, 70 rows + summary metadata, 30KB
- `.flywheel/audit/flywheel-mrjzb/evidence.md` — this evidence pack
- `.flywheel/audit/flywheel-mrjzb/compliance-pack.md` — compliance breakdown
- `/tmp/build-triage-manifest.py` — builder script (kept in /tmp; not committed; reproducible from this evidence)

## Mission fitness

`mission_fitness=adjacent`. Triage manifest gives Joshua a concrete decision-ready document for the 23:30Z sub-bar: 36 lift candidates, 32 retire candidates, 2 Jeff-substrate audit-only. Reduces fleet surface area by ~46% if all ARCHIVE candidates retire. Mission-anchor support: continuous-orchestrator-uptime-self-sustaining-fleet benefits from reduced cognitive load + clear visibility of which repos warrant public-ready investment.

## Skill discoveries

`skill_discoveries=0 sd_ids=none`. Triage classification is standard inventory-to-decision pattern; cu6u9 + mrjzb together represent the "inventory → categorize → triage" template that future scope-bar dispatches can replay.

## Four-Lens Self-Grade

- Brand: 9/10 — 3-class taxonomy + per-repo rationale + license action; presentation matches what an operator would want in a 23:30Z decision packet
- Sniff: 9/10 — empirical mapping; all 70 repos covered (assertion-validated, no orphans); substrate-boundary discipline honored
- Jeff: 10/10 — 2 Jeff-fork repos correctly classified JEFF-AUDIT-ONLY with explicit Class 3 reference
- Public: 9/10 — three judges (skeptical operator / maintainer / future worker): each gets a concrete action list, rationale, and reversal path
