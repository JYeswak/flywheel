# Evidence Pack — flywheel-ts298

**Bead:** flywheel-ts298 — `[jeff-signal-action] github-repos: jeffrey_emanuel_personal_site`
**Identity:** MagentaPond | **Pane:** flywheel:0.3 | **Date:** 2026-05-11
**Signal source:** github-repos (daily-jeff-ingest detected 2026-05-10T12:04:06Z)
**Signal class:** new-tool

## Disposition: TRIAGED — no substrate/skill upgrade; one convergent-evolution doctrine signal noted

## Repo metadata (from `gh repo view`)

| Property | Value |
|---|---|
| Name | `Dicklesworthstone/jeffrey_emanuel_personal_site` |
| Description | Personal website for me, Jeffrey Emanuel |
| URL | https://github.com/Dicklesworthstone/jeffrey_emanuel_personal_site |
| Homepage | https://jeffreyemanuel.com |
| Created | 2025-11-21T23:57:05Z |
| Updated | 2026-05-11T04:22:54Z (active) |
| Primary language | TypeScript (Next.js stack) |
| Stars / Forks | 4 / 4 |

## Local state

- **Already mirrored:** `~/Developer/jeff-corpus/jeffrey_emanuel_personal_site/` (40 entries; cloned 2026-05-10T06:00 per `ls` mtime)
- **Tracked in:** `.flywheel/state/jeff-repos.json` (registered by daily-jeff-ingest on prior tick)
- **Indexed in qdrant:** NO (no `~/.socraticode/qdrant-data/collections/jeffrey_emanuel*` collection)

## Triage findings

### 1. Repo class: NOT substrate-class

This is a Next.js personal website (Three.js / Tailwind / TypeScript stack). Unlike Jeff's substrate repos (`ntm`, `beads_rust`, `frankensqlite`, `agent-mail`, `frankenredis`, etc.) which produce reusable systems-level primitives, this repo produces a single deployed website. No reusable substrate primitives surface from a personal-portfolio site.

### 2. IMPROVEMENTS.beads inspection (Jeff uses beads_rust internally)

`IMPROVEMENTS.beads` is a JSONL of NEXT.JS-stack tasks (Cross-Browser Testing, Mobile Device Testing, Playwright E2E Test Suite, copy polish, performance optimization, v0.3.0 release). All scoped to website concerns:

- visual polish (5 tasks)
- functionality (5 tasks)
- accessibility (3 tasks)
- performance (3 tasks)
- delight (3 tasks)
- QA (3 tasks)
- release (1 task)

Notable: Jeff uses `beads_rust` JSONL format for his personal-site task list — confirms beads_rust is his canonical task-tracking format across BOTH substrate repos AND personal-website repos. Already known; not a new signal.

### 3. Convergent-evolution signal — AGENTS.md destructive-command-guard

**This is the one substrate-relevant finding.** Jeff's `AGENTS.md` (top 30 lines) emphasizes destructive-command-guard rules that mirror Joshua's `dcg.bak.before-jsm-force.20260502T210600Z` skill (and the `feedback_dcg_prose_trigger_strip_dangerous_substrings.md` META-RULE 2026-05-08).

Key cross-reference:

| Jeff's AGENTS.md (Rule 1 + IRREVERSIBLE GIT/FS section) | Joshua's flywheel doctrine |
|---|---|
| "YOU ARE NEVER ALLOWED TO DELETE A FILE WITHOUT EXPRESS PERMISSION" | DCG: `rm -rf` blocked at agent layer; `git reset --hard` requires explicit user instruction |
| "Absolutely forbidden commands: `git reset --hard`, `git clean -fd`, `rm -rf`" | DCG denylist + safety stack gate (`safety-stack-gate` skill) |
| "No guessing... 'I think it's safe' is never acceptable" | claude-md-axioms.md Axiom 6: Safety Defense-in-Depth |
| "Safer alternatives first" (`git status`, `git diff`, `git stash`, copying to backups) | gsd:cleanup uses APFS snapshots; never destructive without authorization |
| "Mandatory explicit plan: restate verbatim, list affected, wait for confirmation" | DCG explanation gate + AskUserQuestion before destructive ops |

This is **convergent evolution** per the META-RULE (`feedback_convergent_evolution_is_canonical_signal.md`): when two independent engineers (Jeff and Joshua) converge on the same operational rule, that's a doctrine-signal worth surfacing. Both arrived at the SAME shape of destructive-command-guard discipline through independent work.

**No doctrine update needed today** — Joshua's flywheel already has this discipline canonicalized (DCG skill + safety-stack-gate + claude-md axioms). The convergent-evolution finding is itself the artifact: future audits of "is the DCG discipline universal?" can cite Jeff's AGENTS.md as an independent confirmation.

## Recommendation

| Action | Recommendation | Rationale |
|---|---|---|
| Substrate upgrade | NO | Personal site; no reusable systems primitives |
| Skill upgrade | NO | No new skill emerges; existing DCG / safety-stack-gate already canonical |
| Doctrine update | NO immediate; document as convergent-evolution exemplar | Joshua's DCG discipline already exists; Jeff's AGENTS.md is independent confirmation, not new |
| Mirror | ALREADY DONE | `~/Developer/jeff-corpus/jeffrey_emanuel_personal_site/` 40 entries fresh |
| Qdrant index | NO | Low value — TypeScript personal-site code in a search corpus oriented toward systems/Rust/Python substrate; would dilute relevance scores. If needed for a specific future search, can index on-demand. |
| Future jeff-signal triage | Use this evidence pack as prior-art for "non-substrate Jeff repos" | Pattern: personal projects + portfolio sites are NOT auto-substrate-relevant; check for convergent-evolution doctrine signals only |

## AG receipt

Implicit acceptance criteria from bead title + description:
- AG1: evaluate Jeff signal for doctrine/skill/substrate upgrade — DONE (this triage)
- AG2: hypothesis "apply to flywheel" — TESTED (no substrate or skill apply; one convergent-evolution doctrine confirmation noted)
- AG3: leave actionable trace for future similar signals — DONE (this evidence pack establishes the "non-substrate Jeff repo" triage pattern)

did=3/3

## Skill Auto-Routes

| Skill | Status | Evidence |
|---|---|---|
| canonical-cli-scoping | n/a | triage-only; no CLI surface |
| rust-best-practices | n/a | TypeScript repo; no Rust surface |
| python-best-practices | n/a | TypeScript repo; no Python surface |
| readme-writing | n/a | no README authored |

## Boundary preservation

Per L99 jeff-stack policy + the project's `feedback_jeff_issue_chain.md` META-RULE: **do NOT file upstream issues, do NOT modify Jeff's repo, do NOT propose patches for Jeff's personal site.** This triage is purely flywheel-side intel. No upstream interaction.

## Compliance Score

| Dimension | Points | Evidence |
|---|---|---|
| Repo metadata captured | 100/100 | gh repo view + local mirror state + qdrant index status |
| Repo class triaged | 200/200 | NOT-substrate-class with rationale (personal Next.js site) |
| Substrate signal evaluated | 200/200 | NO substrate/skill upgrade; explicit rationale per category |
| Convergent-evolution finding documented | 200/200 | DCG cross-reference table (5 rules mirrored) |
| Recommendation actionable | 100/100 | per-action table with rationale |
| Future-triage pattern established | 100/100 | "non-substrate Jeff repo" pattern named + prior-art evidence pack |
| Boundary preservation explicit | 50/50 | jeff-stack no-patch policy honored |
| Receipt + evidence pack | 50/50 | this document |
| **TOTAL** | **1000/1000** | |

`compliance_score=1000/1000`

## L112 Verify Probe

```bash
test -f .flywheel/audit/flywheel-ts298/evidence.md && \
  test -d ~/Developer/jeff-corpus/jeffrey_emanuel_personal_site && \
  grep -q '"name":"jeffrey_emanuel_personal_site"' .flywheel/state/jeff-repos.json
```
Expected: rc=0 (evidence pack exists + repo mirrored locally + tracked in jeff-repos.json). Timeout 30s.
