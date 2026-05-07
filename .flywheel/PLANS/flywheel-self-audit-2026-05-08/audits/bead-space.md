# Bead-Space Layer Audit - 2026-05-08

Bead: `flywheel-e0lsb`  
Scope: beads-workflow, plan-space-convergence before bead creation,
beads-bv graph triage, beads-br tooling, `/flywheel:bead-new`,
`/flywheel:beads`, plan-to-bead conversion, bead body quality, and repo-local
`.beads/issues.jsonl` conventions.

Socraticode receipt: `socraticode_queries=6`, project
`/Users/josh/Developer/flywheel`, K=10 each. Queries covered `polish`,
`convergence`, `dedup`, `plan_to_bead`, `bead body`, and `br create`; returned
60 chunks.

## 1. Inventory

| Surface | Kind | Citation | Current role |
|---|---|---|---|
| `beads-workflow` | skill | `~/.claude/skills/beads-workflow/SKILL.md:1-4`, `~/.claude/skills/beads-workflow/SKILL.md:14-31` | Canonical plan-to-beads and polish workflow. |
| `beads-workflow` stage table | skill section | `~/.claude/skills/beads-workflow/SKILL.md:52-62` | Names conversion, 6-9x polish, fresh eyes, coverage, cross-model review, and ready state. |
| `beads-workflow` pre-conversion checklist | skill section | `~/.claude/skills/beads-workflow/SKILL.md:66-77` | Requires steady-state plan, testable acceptance, explicit dependencies, and self-contained plan before beads. |
| `beads-workflow` plan-to-beads prompt | skill section | `~/.claude/skills/beads-workflow/SKILL.md:81-94` | Active prompt contract for converting plans into self-contained beads. |
| `beads-workflow` quality checklist | skill section | `~/.claude/skills/beads-workflow/SKILL.md:165-179` | Defines bead body quality: self-contained, <=5 files, dependencies, tests, no cycles, synced. |
| `beads-workflow` Agent Mail integration | skill section | `~/.claude/skills/beads-workflow/SKILL.md:183-190` | Ties file reservations and bead threads to bead execution. |
| `plan-space-convergence` | skill | `~/.claude/skills/plan-space-convergence/SKILL.md:1-4`, `~/.claude/skills/plan-space-convergence/SKILL.md:32-39` | Gate before `br create` for non-trivial, audit, refactor, multi-file, and long-body beads. |
| `plan-space-convergence` verification | skill section | `~/.claude/skills/plan-space-convergence/SKILL.md:53-57` | Refuses dispatch until premise is authorized or rewritten. |
| `beads-bv` | skill | `~/.claude/skills/beads-bv/SKILL.md:1-6`, `~/.claude/skills/beads-bv/SKILL.md:12-21` | Graph-aware triage and robot-mode safety for `bv`. |
| `beads-bv` command matrix | skill section | `~/.claude/skills/beads-bv/SKILL.md:25-65` | Documents `--robot-triage`, `--robot-next`, `--robot-plan`, alerts, history, search, and graph surfaces. |
| `beads-bv` metrics | skill section | `~/.claude/skills/beads-bv/SKILL.md:103-121` | Explains PageRank, betweenness, cycles, k-core, articulation. |
| `beads-br` | skill | `~/.claude/skills/beads-br/SKILL.md:1-6`, `~/.claude/skills/beads-br/SKILL.md:14-23` | Rust `br` CLI operational rules: JSON, explicit sync, no cycles, no bare `bv`. |
| `beads-br` lifecycle and sync | skill section | `~/.claude/skills/beads-br/SKILL.md:47-80`, `~/.claude/skills/beads-br/SKILL.md:116-124` | Query/create/update/close/deps/sync commands and session-ending pattern. |
| `beads-br` DB-wedge fallback | skill section | `~/.claude/skills/beads-br/SKILL.md:159-170` | JSONL fallback when live DB is malformed, busy, or stale. |
| `/flywheel:bead-new` | command doc | `~/.claude/commands/flywheel/bead-new.md:1-4`, `~/.claude/commands/flywheel/bead-new.md:23-39` | Guided bead creation surface; replaces manual `br create`. |
| `/flywheel:bead-new` validator path | command doc | `~/.claude/commands/flywheel/bead-new.md:46-67`, `~/.claude/commands/flywheel/bead-new.md:90-98` | Requires canonical AG validation plus `br-create-validated.sh`; forbids direct first-choice creation. |
| `/flywheel:beads` | command doc | `~/.claude/commands/flywheel/beads.md:1-4`, `~/.claude/commands/flywheel/beads.md:8-16` | Repo-scoped bead view with source-repo contamination check. |
| `BEAD-ANATOMY.md` | reference doc | `~/.codex/skills/beads-workflow/references/BEAD-ANATOMY.md:60-71`, `~/.codex/skills/beads-workflow/references/BEAD-ANATOMY.md:74-99` | Body-shape contract: context, approach, success criteria, test plan, considerations. |
| `PROMPTS.md` | reference doc | `~/.codex/skills/beads-workflow/references/PROMPTS.md:11-25`, `~/.codex/skills/beads-workflow/references/PROMPTS.md:31-62` | Full conversion and polish prompts, including 6-9 polish rounds and GPT-5.5 cross-model review. |
| `.beads/config.yaml` | repo-local bead config | `.beads/config.yaml:1` | Declares `issue_prefix: flywheel`. |
| `.beads/issues.jsonl` | repo-local bead store | `.beads/issues.jsonl:1-6`, `.beads/issues.jsonl:540` | Durable issue rows: IDs, title, description, status, priority, source_repo, deps; line 540 is this audit bead. |
| `br-create-validated.sh` | script | `.flywheel/scripts/br-create-validated.sh:1-13`, `.flywheel/scripts/br-create-validated.sh:63-71` | Validates body AG format before delegating to `br create`. |
| `bead-ag-format.py` | script | `.flywheel/scripts/bead-ag-format.py:8-24`, `.flywheel/scripts/bead-ag-format.py:56-90` | Canonical `AG<N>: single-line assertion` validator. |
| `plan-to-bead-auto-trigger.sh` | script | `.flywheel/scripts/plan-to-bead-auto-trigger.sh:1-20`, `.flywheel/scripts/plan-to-bead-auto-trigger.sh:80-100` | Auto-creates plan-decomposition beads for converged or stale plans. |
| `bead-quality-mining.sh` | script | `.flywheel/scripts/bead-quality-mining.sh:15-25`, `.flywheel/scripts/bead-quality-mining.sh:103-160` | Mines closed beads for AG/body quality gaps and can create audit-gap beads. |
| `validation-fix-bead.py` | script | `.flywheel/scripts/validation-fix-bead.py:18-37`, `.flywheel/scripts/validation-fix-bead.py:262-290` | Plans or applies repo-local auto-fix beads from failed validation receipts. |
| `closed-bead-artifact-scan.py` | script | `.flywheel/scripts/closed-bead-artifact-scan.py:18-39`, `.flywheel/scripts/closed-bead-artifact-scan.py:177-180` | Scans closed-bead claims for missing paths, bad schemas, and failing commands. |
| `br-close-with-gate.sh` | script | `.flywheel/scripts/br-close-with-gate.sh:4-22`, `.flywheel/scripts/br-close-with-gate.sh:53-86` | Gates `br close` behind callback-envelope schema and L112 validation. |
| `doctor-signal-bead-promotion.sh` | script | `.flywheel/scripts/doctor-signal-bead-promotion.sh:1-18`, `.flywheel/scripts/doctor-signal-bead-promotion.sh:116-150` | Promotes doctor signals into matching or new beads. |
| `br-db-corruption-monitor.sh` | script | `.flywheel/scripts/br-db-corruption-monitor.sh:4-24`, `.flywheel/scripts/br-db-corruption-monitor.sh:85-95` | Checks `.beads/beads.db` integrity and can invoke rebuild with explicit flag. |
| `test-beads-jsonl-writes-via-br-only.sh` | test | `.flywheel/tests/test-beads-jsonl-writes-via-br-only.sh:1-20` | Structural guard for "issues.jsonl writes via br only" doctrine. |
| agent-flywheel.com local analysis | doctrine input | `.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:44-55`, `.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:89-94` | Public bead-space benchmark: conversion, polishing, thresholds, anti-patterns. |

Inventory count: 31 rows.

## 2. Load-bearing

Callsite scan command:

```bash
for term in 'beads-workflow' 'plan-space-convergence' 'beads-bv' 'beads-br' \
  'flywheel:bead-new' 'flywheel:beads' 'br-create-validated' 'bead-ag-format' \
  'plan-to-bead-auto-trigger' 'bead-quality-mining' 'validation-fix-bead' \
  'br-close-with-gate' 'closed-bead-artifact-scan' \
  'doctor-signal-bead-promotion'; do
  rg -l "$term" /Users/josh/Developer/flywheel ~/.claude/commands \
    ~/.claude/skills ~/.codex/skills --glob '!**/.git/**' \
    --glob '!**/node_modules/**' --glob '!**/.venv/**' 2>/dev/null | wc -l
done
```

Observed unique-file counts: `beads-workflow=289`,
`plan-space-convergence=15`, `beads-bv=48`, `beads-br=56`,
`flywheel:bead-new=9`, `flywheel:beads=6`, `br-create-validated=12`,
`bead-ag-format=11`, `plan-to-bead-auto-trigger=5`,
`bead-quality-mining=27`, `validation-fix-bead=11`,
`br-close-with-gate=9`, `closed-bead-artifact-scan=24`,
`doctor-signal-bead-promotion=36`.

| Surface | Why load-bearing | Evidence |
|---|---|---|
| `beads-workflow` | It is the primary conversion and polish skill; >3 callsites and it owns the "check beads N times" doctrine. | `~/.claude/skills/beads-workflow/SKILL.md:10-12`, `~/.claude/skills/beads-workflow/SKILL.md:98-106`; callsite count 289. |
| `plan-space-convergence` | Critical path before non-trivial `br create`; lower callsite count still matters because it blocks bad bead premises before 5x/25x rework. | `~/.claude/skills/plan-space-convergence/SKILL.md:32-39`, `~/.claude/skills/plan-space-convergence/SKILL.md:53-57`; callsite count 15. |
| `beads-bv` | Graph routing is the bead-space scheduler; PageRank and betweenness decide what work should run before local intuition. | `~/.claude/skills/beads-bv/SKILL.md:12-21`, `~/.claude/skills/beads-bv/SKILL.md:103-121`; callsite count 48. |
| `beads-br` | Operational source for safe `br` lifecycle, explicit sync, JSON-only use, and DB failure fallback. | `~/.claude/skills/beads-br/SKILL.md:14-23`, `~/.claude/skills/beads-br/SKILL.md:159-170`; callsite count 56. |
| `/flywheel:bead-new` | Critical creation path because it consults skills, prompts for BEAD-ANATOMY, validates AG format, and checks source_repo. | `~/.claude/commands/flywheel/bead-new.md:8-18`, `~/.claude/commands/flywheel/bead-new.md:46-69`; callsite count 9. |
| `/flywheel:beads` | Critical view path because it scopes queries to the repo-local DB and flags cross-repo contamination. | `~/.claude/commands/flywheel/beads.md:8-16`, `~/.claude/commands/flywheel/beads.md:37-39`; callsite count 6. |
| `br-create-validated.sh` + `bead-ag-format.py` | They are mechanical write-time body gates for AG shape. Without them, the worker-visible bead body format becomes optional prose. | `.flywheel/scripts/br-create-validated.sh:63-71`, `.flywheel/scripts/bead-ag-format.py:56-90`; combined callsite count 23. |
| `bead-quality-mining.sh` | It closes the feedback loop on closed beads by deriving missing artifacts, missing AGs, skipped tests, and canonical AG violations. | `AGENTS.md:1618-1642`, `.flywheel/scripts/bead-quality-mining.sh:103-160`; callsite count 27. |
| `plan-to-bead-auto-trigger.sh` | It is a live automatic bead materializer. Critical path but dangerous because it can create thin plan-decompose beads. | `.flywheel/scripts/plan-to-bead-auto-trigger.sh:42-59`, `.flywheel/scripts/plan-to-bead-auto-trigger.sh:80-100`; `.beads/issues.jsonl:9`, `.beads/issues.jsonl:59`, `.beads/issues.jsonl:115` show rows it created. |
| `validation-fix-bead.py` | It turns failed callback validation into repo-local fix beads or explicit no-bead reasons. | `.flywheel/flywheel-loop-tick:1181`, `.flywheel/scripts/validation-fix-bead.py:282-301`; callsite count 11. |
| `closed-bead-artifact-scan.py` | It treats closed beads as claims and probes artifacts, schemas, executables, and commands. | `AGENTS.md:1203`, `.flywheel/scripts/closed-bead-artifact-scan.py:136-174`; callsite count 24. |
| `doctor-signal-bead-promotion.sh` | It is the doctor-to-bead promotion bridge; many P0/P1 repair rows are produced by this path. | `.flywheel/flywheel-loop-tick:1261`, `.flywheel/scripts/doctor-signal-bead-promotion.sh:116-150`, `.beads/issues.jsonl:270`; callsite count 36. |
| `br-close-with-gate.sh` | It makes close-step ordering enforceable before callback. | `.flywheel/scripts/br-close-with-gate.sh:53-86`, `tests/auto-l112-gate-orch-adoption-test.sh:6`; callsite count 9. |

Load-bearing count: 13.

## 3. Vestigial

| Surface | Evidence | Disposition |
|---|---|---|
| Dispatch-named `~/.claude/skills/.flywheel/skills/flywheel:bead-new.md` | Exact path is absent; active command is `~/.claude/commands/flywheel/bead-new.md:1-7`. | Sunset the path reference or add a pointer. Dispatches should name the active command file. |
| Dispatch-named `~/.claude/skills/.flywheel/skills/flywheel:beads.md` | Exact path is absent; active command is `~/.claude/commands/flywheel/beads.md:1-7`. | Same path-drift fix as above. |
| Raw `br create` examples in skills | `beads-workflow` still shows direct `br create` lifecycle at `~/.claude/skills/beads-workflow/SKILL.md:112-120`; `beads-br` also lists direct create at `~/.claude/skills/beads-br/SKILL.md:49-55`. Active command says direct `br create` is not first-choice at `~/.claude/commands/flywheel/bead-new.md:65-67`. | Superseded for flywheel-managed repos. Keep as upstream CLI reference, but mark "use `br-create-validated.sh` or `/flywheel:bead-new` first". |
| `plan-to-bead-auto-trigger.sh` thin bodies | It creates generic bodies with five bullets at `.flywheel/scripts/plan-to-bead-auto-trigger.sh:83-95`; agent-flywheel.com gap analysis warns against pseudo-beads and vague beads at `.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:57-76`. | Candidate for shadow-only mode until it emits BEAD-ANATOMY + canonical AGs + file scope. |
| `validation-fix-bead.py` generated AG format | Generated body still writes numbered `1.` acceptance gates at `.flywheel/scripts/validation-fix-bead.py:215-221`, while canonical validator requires exact `AG<N>:` at `.flywheel/scripts/bead-ag-format.py:56-90`. | Superseded body format. Fix generator before using it as a model for new beads. |
| Markdown-only DAG beads | Recent plans contain `04-BEADS-DAG.md` previews and plan rows, e.g. `.flywheel/PLANS/orch-heartbeat-no-idle-projects-2026-05-06/05-POLISH-r1-DAG-preview.md` exists and `.flywheel/PLANS/orchestrator-workforce-supervision-2026-05-04/01-RESEARCH-C.md:306` says placeholder IDs only. | Allowed as plan-space previews only. They must not be treated as executable beads until `br` rows exist. |
| Legacy direct `.beads/issues.jsonl` append temptation | L125 says `.beads/issues.jsonl` is written only through `br create`, `br update`, or `br close` at `AGENTS.md:3628-3629`; structural test exists at `.flywheel/tests/test-beads-jsonl-writes-via-br-only.sh:1-20`. | Keep the rule; sunset any manual-append fallback text in future docs. |

Vestigial/superseded count: 6.

## 4. Missing per agent-flywheel.com gap analysis

### Gap 1: bead polishing rounds-by-content schedule

agent-flywheel.com names the schedule explicitly: rounds 1-3 major fixes, 4-7
architecture, 8-12 edge cases, 13+ polish
(`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:89-94`).
Our `beads-workflow` says polish 6-9 times until steady-state
(`~/.claude/skills/beads-workflow/SKILL.md:98-106`) and `PROMPTS.md` says
round 1 significant, round 2 moderate, round 3 fewer, round 6-9 steady-state
(`~/.codex/skills/beads-workflow/references/PROMPTS.md:51-62`). We do not yet
encode the public guide's content-by-round expectation.

Recent evidence says we often ship before 4-6 rounds when the local metric
stabilizes. Mission-lock polish ran r1/r2/r3 and marked ready when
`polish_convergence_streak=2` after r3, with r3 diff 0 percent per Socraticode
results from `INCIDENTS.md:4321-4330`. That is rational for small DAGs, but it
does not test the guide's architecture/edge-case rounds 4-7/8-12.

### Gap 2: convergence 0.75 / 0.90 thresholds

The public benchmark uses weighted score thresholds: 0.75 ready and 0.90
diminishing returns
(`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:89-92`).
Our bead polish uses a local `<5%` body-diff/streak style, and `/flywheel:plan`
schema v4 uses `convergence_streak >= 2` for polish advancement per L126
(`AGENTS.md:3720-3727`). The close gate also references compliance score
thresholds, but bead-space lacks a weighted body-quality score with explicit
0.75/0.90 equivalents.

Recommendation: use a bead-body weighted score with components for context,
file scope, AG testability, dependency closure, risk/rollback, and source
citations. Ready at `>=0.75`; diminishing returns at `>=0.90`; still require
acyclic graph and no hard validation failures.

### Gap 3: pseudo-beads-in-markdown anti-pattern

The guide names pseudo-beads in markdown as anti-pattern #1
(`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:57-76`).
Recent plans use markdown DAGs heavily. That is fine in Phase 4 planning, but
the audit found examples where the boundary is visible and fragile:

- `04-BEADS-DAG.md` artifacts are common plan-space previews, not executable
  work. Good examples cite no direct bead creation during audit, such as
  `.flywheel/PLANS/orchestrator-workforce-supervision-2026-05-04/02-REFINE-r2.md:631`.
- Auto-created plan-decompose rows in `.beads/issues.jsonl:9`, `:59`, and
  `:115` are executable beads, but their bodies are generic and can still
  require reading the original plan. That is pseudo-bead pressure moved from
  markdown into `br`.
- `.flywheel/PLANS/orchestrator-workforce-supervision-2026-05-04/01-RESEARCH-C.md:306`
  explicitly says placeholder IDs only; this is good labeling and should be
  required anywhere markdown bead tables exist.

### Gap 4: embed complete context in each bead

The guide defines beads as self-contained work units with context,
dependencies, and test obligations
(`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:16-24`).
Our BEAD-ANATOMY requires background, technical approach, success criteria,
test plan, and considerations
(`~/.codex/skills/beads-workflow/references/BEAD-ANATOMY.md:74-99`), and
`/flywheel:bead-new` asks for inline tags, skills, dependencies, and AG format
(`~/.claude/commands/flywheel/bead-new.md:29-39`).

The body-shape is strong when humans or orchestrators author focused beads:
`opwu8`, `flsau`, `a2lff`, and `mqy5l` all include mission anchor, origin plan,
scope, acceptance, hard rules/process, and callback shape in `.beads/issues.jsonl`
or `br show` output. The weak point is generated or fix-bead paths:
`plan-to-bead-auto-trigger.sh` creates generic bodies at
`.flywheel/scripts/plan-to-bead-auto-trigger.sh:83-95`, and
`validation-fix-bead.py` uses old numbered gates at
`.flywheel/scripts/validation-fix-bead.py:215-221`.

## 5. Lessons learned (today's evidence)

1. **Strong beads made large NTM wire-ins tractable.** `opwu8` bundled 4 P0
   surfaces with explicit surface list, callsite targets, process, anti-patterns,
   and atomic-commit rules. It shipped 4 commits (`c82b351`, `a557c10`,
   `0af69ff`, `d63ad1f`) and the bead body demanded per-surface tests and >=3
   native callsites. Lesson: bundle by shared substrate, but keep acceptance
   per surface.

2. **`flsau` reused the same body shape and scaled to 8 P1 surfaces.** It
   explicitly references `opwu8`, lists all 8 surfaces, states the callback
   envelope, and repeats "do not bundle commits." It shipped 8 commits
   (`3cddc67` through `975f49e`). Lesson: good bead bodies are templates for
   the next wave; reuse the proven contract instead of inventing a new one.

3. **`a2lff` proves triage beads need output manifests, not code edits.** It
   classified 50 not-wired surfaces via 500 Socraticode searches, required a
   five-section output document, banned new bead creation, and closed with a
   disposition artifact. Lesson: research beads should make future beads
   obvious while preserving orchestrator synthesis authority.

4. **`mqy5l` shows research beads need adoption posture.** The Brenner deep dive
   required 16+ Socraticode queries, file:line citations, comparison to existing
   primitives, and 3-7 wire-in proposals. It closed with 6 proposals and no
   ambiguous "interesting ideas" residue. Lesson: every research bead should
   end in ADOPT/EXTEND/AVOID/ALREADY-COVERED decisions.

5. **The 8 self-audit beads have the right macro-body shape.** `ivy6g/e0lsb/a19y3/r41sn/up0uw/uz7so/3c5eq/ug399` all point to explicit target artifacts
   in `.beads/issues.jsonl:216`, `:437`, `:540`, `:702`, `:885`, `:981`, `:989`,
   and `:997`. Lesson: audit beads work when each has one output file, a shared
   six-section contract, and "recommendations only" guardrails.

6. **The weakest bead-space discipline is generated body quality.** Human-authored
   P0/P1 beads now routinely include mission anchor, scope, process, tests,
   callback, hard rules, and no-mutation boundaries. Auto-created plan-decompose
   and validation-fix beads still lag behind the standard body shape.

## 6. Fix-bead manifest

Recommendations only; no beads filed.

1. **P0 - `[bead-space] add weighted bead_body_score and 0.75/0.90 close thresholds`**  
   Scope: `bead-ag-format.py`, `br-create-validated.sh`, `bead-quality-mining.sh`,
   and docs in `beads-workflow`.  
   Acceptance: validator emits `bead_body_score` with weighted components
   (context, file scope, AG testability, dependencies, tests, rollback, skills);
   `>=0.75` is dispatch-ready, `>=0.90` is diminishing returns; warnings below
   threshold block `/flywheel:bead-new` unless `JOSHUA_OVERRIDE` is logged.

2. **P1 - `[bead-space] codify polish rounds-by-content and pseudo-bead boundary`**  
   Scope: `beads-workflow`, `PROMPTS.md`, and `/flywheel:plan` Phase 4/5 docs.  
   Acceptance: docs define r1-3 fixes, r4-7 architecture, r8-12 edges, r13+
   polish; markdown DAGs must carry `artifact_state=preview_only` until `br`
   rows exist; generated plan-decompose beads must reference whether they are
   executable or placeholder.

3. **P1 - `[bead-space] upgrade generated bead bodies to BEAD-ANATOMY + canonical AG format`**  
   Scope: `plan-to-bead-auto-trigger.sh`, `validation-fix-bead.py`, and fixture
   tests.  
   Acceptance: generated beads include Background, Technical Approach, Success
   Criteria, Test Plan, file scope, dependencies, skills, and `AG<N>:` single-line
   gates; `bead-ag-format.py --json` returns `status=pass` for generated bodies;
   no generated row requires reading the source plan to understand scope.

Fix beads proposed: 3.
