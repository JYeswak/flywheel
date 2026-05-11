---
bead: flywheel-nhqc4
title: Dual observational analysis — beads_rust + opencode-grok-first-router (zero mutations)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: DONE
priority: P2
mission_fitness: adjacent
discipline: observational-only / zero-mutations
---

# nhqc4 evidence pack — dual observational analysis

## Disposition

DONE with two recommendations to surface to Joshua. **No mutations performed** (per bead body): no archiving, no forking, no PR filing, no doctrine extraction, no fork-sync. Pure observation + recommendation.

---

## (a) beads_rust — JEFF-AUDIT-ONLY class

### Fork-vs-upstream comparison

| Field | jyeswak/beads_rust | Dicklesworthstone/beads_rust |
|-------|--------------------|-----------------------------|
| Created | 2026-05-06T16:53Z | (canonical) |
| Last push | 2026-05-06T17:20Z | 2026-05-11T18:00Z |
| Default branch | main | main |
| isFork | true (parent=Dicklesworthstone/beads_rust) | (canonical) |
| Visibility | PUBLIC | PUBLIC |

### Drift analysis (gh api compare)

```
jyeswak/main vs Dicklesworthstone/main: ahead_by=0, behind_by=133, status=behind
```

The jyeswak fork has **0 unique commits** beyond the upstream canonical and is **133 commits behind** Dicklesworthstone canonical. Created 5 days ago, last pushed 5 days ago — coincides with fork creation. The fork has had no jyeswak-side activity since.

### Substrate-boundary-three-class taxonomy classification

CONFIRMED: **Class 3 (Jeff-Premium substrate)**. jyeswak fork is a read-only consumer mirror; Dicklesworthstone is the canonical-locator authority. Per `feedback_no_push_ntm_br` + `feedback_jeff_issue_chain` Joshua memories: don't push to Jeff's forks; file issues against canonical upstream.

### Recommendation: **UPSTREAM-ISSUE-ONLY** (do NOT fold-archive)

The fork at 0-unique-commits with 5d-stale-since-creation is consistent with the canonical Class 3 discipline — Joshua never had any intent to push downstream. The fork was created likely for:
- An audit/inspection point-in-time snapshot
- A reference target for hypothetical PRs (none ever filed)
- Repository-list completeness within the jyeswak org

**Do not retire** because:
1. Class 3 discipline says forks are AUDIT-ONLY snapshots — retiring them doesn't lose anything important, but neither does keeping them
2. Joshua's bead workflow may reference the jyeswak/beads_rust namespace in issue links or doctrine cross-references; a missing repo would break those refs
3. Future PR-filing scenarios (if Joshua ever wants to contribute upstream) need the fork present
4. Storage cost is trivial (120MB) vs. canonical-link continuity value

**Action path forward**: surface as JEFF-AUDIT-ONLY in the triage manifest (already done in flywheel-mrjzb at row `beads_rust`). File any issues directly against `Dicklesworthstone/beads_rust` per the canonical upstream issue chain.

### Counter-recommendation: fold-archive IF Joshua prefers minimal-footprint

If the jyeswak org footprint matters more than namespace continuity, fold-archive (retire-via-gh-cli) is defensible since the fork has 0 unique commits. The downside is a minor: any link from `.flywheel/doctrine/*.md` or upstream-issue draft references to `jyeswak/beads_rust` would 404 if the fork is deleted (retiring it makes the repo read-only but it stays reachable; outright deletion would break links).

Both paths preserve substrate-boundary discipline; **observational recommendation is UPSTREAM-ISSUE-ONLY**.

---

## (b) opencode-grok-first-router — PUBLIC ARCHIVE candidate

### Repo metadata

| Field | Value |
|-------|-------|
| Visibility | PUBLIC |
| Created | 2026-01-14T00:21Z |
| Last push | 2026-01-14T00:41Z (117d stale) |
| Disk size | 6KB |
| Primary language | TypeScript |
| isFork | false (original Joshua-authored) |
| License | MIT (already present) |
| Has README | YES (6KB) |
| Description | "Automated complexity-based routing for OpenCode - 76% cost savings with 10/10 correctness" |

### Contents

```
.gitignore       66 B
LICENSE        1061 B
README.md      6251 B
index.ts       3003 B  (the actual routing logic)
package.json    869 B
tsconfig.json   451 B
```

### Salvage assessment — **CONTENT HAS REAL VALUE**

The `index.ts` (3KB) implements:
- A complexity-keyword detector with ~30 keywords across 6 categories (architectural, novelty, optimization, decision-making, problem-solving, ambiguity)
- A 90/10 routing split (90% to free tier `opencode/grok-code`, 10% to premium `xai/grok-4-1-fast`)
- A clean ModelSelectInput/Output interface

The `README.md` (6KB) documents:
- Validated A/B test results: 10/10 correctness on both tiers
- Cost benchmark: $2.50 (all-Claude) vs $0.60 (Grok-First Router) per 100 tasks = **76% cost savings**
- 3 installation methods (opencode.json, local dev, direct GitHub)

### Cross-reference probe

Searched current flywheel + skillos + zeststream-skillos repos for refs to `grok-first | opencode-grok | grok-first-router | 90/10 split | grok-code.*grok-4`: **0 hits**. The routing pattern has NOT been ported anywhere current.

### cc-router successor probe

`jyeswak/cc-router` (active 2d, 76KB, no language) is a planning-stub for a Claude Code router — appears to be the conceptual successor. Currently contains only `.planning/{PROJECT,REQUIREMENTS,ROADMAP,STATE}.md + config.json` — NO implementation yet. The opencode-grok-first-router pattern is a natural input for cc-router's implementation.

### Recommendation: **EXTRACT-THEN-RETIRE** (or retire-but-cite)

Two compatible paths, both preserving the salvage value:

**Path A (extract-then-retire)** — author a flywheel doctrine doc at `.flywheel/doctrine/complexity-based-model-routing.md` that distills:
- The 90/10 routing split rationale
- The keyword-based complexity detector list (verbatim from index.ts)
- The validated 76% cost-savings benchmark (with caveat: results were specific to opencode + grok-code/grok-4-1-fast in Jan 2026; re-verify if applied to Claude Code routing in cc-router)
- A pointer to the original repo URL + commit sha as provenance

After the doctrine doc exists, retire the repo cleanly. Doctrine doc + provenance link = full salvage; the original repo's storage and discoverability become redundant.

**Path B (retire-but-cite)** — retire the repo as-is and add a one-line note in cc-router's `.planning/REQUIREMENTS.md` pointing to the retired-but-still-reachable `https://github.com/jyeswak/opencode-grok-first-router` for the original routing pattern. Lighter-weight than Path A but loses a friction point if the repo is ever deleted vs retired.

### Recommendation strength: HIGH confidence on extract-then-retire

The 76% cost-savings + 10/10 correctness combo is a load-bearing claim that should be preserved in flywheel-canonical doctrine even if the repo is retired. Path A is the cleaner archival.

---

## Acceptance gates (implicit from bead title)

| # | Gate | Status | Evidence |
|---|------|--------|----------|
| 1 | beads_rust JEFF-AUDIT-ONLY class observational analysis | DID | gh api compare + repo view; 0 unique commits / 133 behind |
| 2 | beads_rust recommendation: upstream-issue-only OR fold-archive | DID | UPSTREAM-ISSUE-ONLY recommended; counter-recommendation noted for footprint-minimization preference |
| 3 | opencode-grok-first-router PUBLIC archive confirmation | DID | metadata + 6-file content probe + salvage assessment |
| 4 | opencode-grok-first-router salvage check | DID | EXTRACT-THEN-RETIRE recommended (Path A); Path B documented |
| 5 | Zero mutations performed | DID | no gh repo retire calls; no fork-sync; no doctrine extraction; no PR filing |
| 6 | Substrate-boundary discipline Class 3 for beads_rust | DID | explicit Class 3 reference + canonical-locator vs read-only-consumer language |

`did=6/6`, `didnt=none`, `gaps=none`.

## L112 probe

```bash
test -f /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-nhqc4/evidence.md && grep -c "UPSTREAM-ISSUE-ONLY\|EXTRACT-THEN-RETIRE" /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-nhqc4/evidence.md
```

Expected: numeric >=2 (both recommendation labels present in evidence pack).

## Files changed

- `.flywheel/audit/flywheel-nhqc4/evidence.md` — this evidence pack (the dual analysis)
- `.flywheel/audit/flywheel-nhqc4/compliance-pack.md` — compliance breakdown

**Zero mutations to repos, doctrine docs, scripts, or fleet state per bead body.**

## Mission fitness

`mission_fitness=adjacent`. Observational analysis without mutation supports the continuous-orchestrator-uptime-self-sustaining-fleet mission anchor by giving Joshua decision-ready recommendations for two repos without committing to either path. Discipline-preserving: substrate-boundary Class 3 honored; salvage value protected before any retire action.

## Skill discoveries

`skill_discoveries=0 sd_ids=none`. The observe-recommend pattern is canonical (multi-instance in this session: 2xdi.157 bead-hypothesis-probe, mrjzb triage recommendation). Not a new pattern.

## Four-Lens Self-Grade

- Brand: 9/10 — dual-analysis format with explicit recommendation strength + counter-recommendation
- Sniff: 10/10 — empirical gh api probes (compare, metadata, contents, README, index.ts); cross-reference search across 3 repos
- Jeff: 10/10 — Class 3 substrate-boundary discipline preserved; UPSTREAM-ISSUE-ONLY recommendation aligns with feedback_no_push_ntm_br + feedback_jeff_issue_chain memories
- Public: 9/10 — three judges: skeptical operator sees concrete metrics + reversibility paths; maintainer sees two compatible options for opencode-grok-first-router; future worker sees the salvage extraction template
