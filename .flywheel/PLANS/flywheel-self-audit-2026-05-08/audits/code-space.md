# Code-Space Layer Audit

Audit bead: `flywheel-a19y3`

Scope anchor: code-space is the review/test/harden layer between expensive code changes and closure. The 6-section audit contract is from `.flywheel/PLANS/flywheel-self-audit-2026-05-08/00-PLAN.md:19`.

## Section 1: Inventory

Inventory count: 523 surfaces in scope: 8 primary skills plus 515 repo-local test/fixture files across `tests/`, `.flywheel/tests/`, and `templates/flywheel-install/tests/`.

| Surface | Inventory evidence | Notes |
|---|---|---|
| `ubs` skill | `/Users/josh/.claude/skills/ubs/SKILL.md:2`, `/Users/josh/.claude/skills/ubs/SKILL.md:17`, `/Users/josh/.claude/skills/ubs/SKILL.md:29` | Ultimate Bug Scanner; explicit pre-commit rule, staged/diff scan loop, triage and rerun. |
| `ubs` helper script | `/Users/josh/.claude/skills/ubs/scripts/validate.py:1`, `/Users/josh/.claude/skills/ubs/SKILL.md:77` | Skill-local validation/doctor support. |
| `multi-pass-bug-hunting` skill | `/Users/josh/.claude/skills/multi-pass-bug-hunting/SKILL.md:2`, `/Users/josh/.claude/skills/multi-pass-bug-hunting/SKILL.md:38`, `/Users/josh/.claude/skills/multi-pass-bug-hunting/SKILL.md:216` | Four-pass audit/fix/rescan loop with convergence criteria. |
| `de-slopify` skill | `/Users/josh/.claude/skills/de-slopify/SKILL.md:2`, `/Users/josh/.claude/skills/de-slopify/SKILL.md:10`, `/Users/josh/.claude/skills/de-slopify/SKILL.md:43` | Manual prose polish for AI writing artifacts; no script directory. |
| `code-review-gemini-swarm-with-ntm` skill | `/Users/josh/.claude/skills/code-review-gemini-swarm-with-ntm/SKILL.md:2`, `/Users/josh/.claude/skills/code-review-gemini-swarm-with-ntm/SKILL.md:12`, `/Users/josh/.claude/skills/code-review-gemini-swarm-with-ntm/SKILL.md:112` | Gemini review swarm, repeated explore/cross-review rounds, NTM spawn. |
| `security-review` skill | `/Users/josh/.claude/skills/security-review/SKILL.md:2`, `/Users/josh/.claude/skills/security-review/SKILL.md:15`, `/Users/josh/.claude/skills/security-review/SKILL.md:34` | OWASP/security review gate before security-sensitive commits. |
| `security-review` scripts | `/Users/josh/.claude/skills/security-review/scripts/security_scanner.py:1`, `/Users/josh/.claude/skills/security-review/scripts/probe.sh:1`, `/Users/josh/.claude/skills/security-review/SKILL.md:44` | Scanner/probe scripts exposed by the skill. The `__pycache__` file is generated cache, not a source surface. |
| `ui-polish` skill | `/Users/josh/.claude/skills/ui-polish/SKILL.md:2`, `/Users/josh/.claude/skills/ui-polish/SKILL.md:17`, `/Users/josh/.claude/skills/ui-polish/SKILL.md:51` | Iterative UI/UX polish; explicitly separates desktop and mobile. |
| `simplify-and-refactor-code-isomorphically` skill | `/Users/josh/.claude/skills/simplify-and-refactor-code-isomorphically/SKILL.md:2`, `/Users/josh/.claude/skills/simplify-and-refactor-code-isomorphically/SKILL.md:10`, `/Users/josh/.claude/skills/simplify-and-refactor-code-isomorphically/SKILL.md:22` | Behavior-preserving shrink/refactor skill with baseline, proof, and LOC ledger. |
| `simplify-and-refactor-code-isomorphically` scripts | `/Users/josh/.claude/skills/simplify-and-refactor-code-isomorphically/scripts/check_skills.sh:1`, `/Users/josh/.claude/skills/simplify-and-refactor-code-isomorphically/scripts/ai_slop_detector.sh:1`, `/Users/josh/.claude/skills/simplify-and-refactor-code-isomorphically/scripts/verify_isomorphism.sh:1`, `/Users/josh/.claude/skills/simplify-and-refactor-code-isomorphically/SKILL.md:61` | 27 helper scripts: baseline, duplication scan, callsite census, slop detector, isomorphism, lint ceiling, LOC delta, scoring, validation. |
| `code-simplifier` skill | `/Users/josh/.claude/skills/code-simplifier/SKILL.md:2`, `/Users/josh/.claude/skills/code-simplifier/SKILL.md:19`, `/Users/josh/.claude/skills/code-simplifier/SKILL.md:31` | Lightweight simplification reviewer for recent changes; no local script directory. |
| Flywheel test corpus | `.flywheel/tests/test_polish_preflight_quality_gate.sh:1`, `.flywheel/tests/test_mission_lock_negative_invariants_validator.sh:1`, `.flywheel/tests/test_golden_fixture_replay_runner.sh:1` | 205 files under `.flywheel/tests/`: substrate gates, security invariants, close validation, NTM hardening, fixtures. |
| Repo test corpus | `tests/quality-bar-close-gate.sh:1`, `tests/callback-envelope-schema-validator.sh:1`, `tests/bead-quality-mining.sh:1` | 278 files under `tests/`: operational regression tests, validators, gates, watchtower probes, fixture tests. |
| Template install test corpus | `templates/flywheel-install/tests/test_polish_gate_schemas.sh:1`, `templates/flywheel-install/tests/test_polish_gate_scope_allowlist.sh:1`, `templates/flywheel-install/tests/test_polish_gate_runner.sh:1` | 32 files under `templates/flywheel-install/tests/`: installable polish-gate and render tests. |
| Polish-gate runner | `templates/flywheel-install/polish-gate/run-grader.py:1`, `templates/flywheel-install/polish-gate/run-grader.py:16`, `templates/flywheel-install/polish-gate/run-grader.py:18` | Code-space measured surface: lanes include `ubs`, `simplify`, `extreme-opt`, `readme`, `canonical-cli`. |
| Polish-gate replay and reconcile | `templates/flywheel-install/polish-gate/replay-to-ledger.py:1`, `templates/flywheel-install/polish-gate/replay-to-ledger.py:18`, `templates/flywheel-install/scripts/reconcile-polish-gate.sh:1`, `templates/flywheel-install/scripts/reconcile-polish-gate.sh:23` | Moves grade receipts into ledgers and reconciles repo-local manifest/state fields. |
| Polish-gate schemas | `templates/flywheel-install/polish-gate/v1/manifest.schema.json:1`, `templates/flywheel-install/polish-gate/v1/manifest.schema.json:21`, `templates/flywheel-install/polish-gate/v1/grade-receipt.schema.json:1`, `templates/flywheel-install/polish-gate/v1/grade-receipt.schema.json:41` | Manifest and grade receipt schemas define blocking modes and per-skill scores. |
| Git hook surface | `.git/hooks/pre-commit.sample:1`, `.git/hooks/pre-commit.sample:8`, `.git/hooks/pre-commit.sample:48` | Only Git sample hooks observed; no active `.git/hooks/pre-commit` UBS gate. |

## Section 2: Load-Bearing

Load-bearing count: 10.

Evidence method: direct `rg -n`/line reads plus 7 Socraticode K=10 searches against `/Users/josh/Developer/flywheel` for `review`, `lint`, `test`, `harden`, `polish`, `ubs`, and `security`.

| Surface | Why load-bearing | Evidence |
|---|---|---|
| UBS practice | Critical path by doctrine and cross-skill dependency. The skill says `ubs <changed-files> before every commit`, uses `ubs --staged`, and blocks on exit 0; `multi-pass-bug-hunting` calls UBS in pass 1 and pass 4. | `/Users/josh/.claude/skills/ubs/SKILL.md:17`, `/Users/josh/.claude/skills/ubs/SKILL.md:29`, `/Users/josh/.claude/skills/multi-pass-bug-hunting/SKILL.md:38`, Socraticode `ubs Ultimate Bug Scanner pre commit code-space` returned polish-gate grade receipts and tests. |
| Multi-pass bug hunting | Critical-path hardening pattern: random exploration, UBS, tests, final clean scan, explicit convergence. | `/Users/josh/.claude/skills/multi-pass-bug-hunting/SKILL.md:38`, `/Users/josh/.claude/skills/multi-pass-bug-hunting/SKILL.md:99`, `/Users/josh/.claude/skills/multi-pass-bug-hunting/SKILL.md:216`, Socraticode `review code review cross-agent random exploration ubs` surfaced repeated plan/audit convergence practice. |
| Security review | Critical path for auth, PII, tokens, APIs, database queries; also mirrored by recent security-negative-invariant implementation. | `/Users/josh/.claude/skills/security-review/SKILL.md:15`, `/Users/josh/.claude/skills/security-review/SKILL.md:23`, `.flywheel/tests/test_mission_lock_negative_invariants_validator.sh:19`, Socraticode `harden security review secret scan safety UBS` surfaced the security-negative-invariants audit and amendment. |
| De-slopify | Load-bearing for public docs/tone; directly covers the named Tier-3 gap patterns. Multiple callsites in skill ecosystem reference `/de-slopify` as hard invariant for customer-visible copy. | `/Users/josh/.claude/skills/de-slopify/SKILL.md:43`, `/Users/josh/.claude/skills/de-slopify/SKILL.md:47`, `/Users/josh/.claude/skills/de-slopify/SKILL.md:50`, `rg` surfaced `/Users/josh/.codex/skills/user-support-ticketing-system-for-saas/SKILL.md:272` as every customer-visible reply through `/de-slopify`. |
| UI polish | Critical path when shipping UI; skill explicitly requires desktop/mobile separate treatment and repeated passes. | `/Users/josh/.claude/skills/ui-polish/SKILL.md:17`, `/Users/josh/.claude/skills/ui-polish/SKILL.md:26`, `/Users/josh/.claude/skills/ui-polish/SKILL.md:92`, Socraticode `polish ui mobile desktop de-slopify` surfaced polish-gate allowlists and template tests. |
| Simplify/refactor isomorphically | Critical path for safe LOC reduction; heavily scripted and cross-linked from `code-simplifier`, UBS, multi-pass bug hunting, and code review swarm. | `/Users/josh/.claude/skills/simplify-and-refactor-code-isomorphically/SKILL.md:22`, `/Users/josh/.claude/skills/simplify-and-refactor-code-isomorphically/SKILL.md:44`, `/Users/josh/.claude/skills/simplify-and-refactor-code-isomorphically/SKILL.md:76`, `rg` surfaced 3+ direct helper script paths at `/Users/josh/.claude/skills/.flywheel/proposals/non-ascii-script-triage-2026-04-28.md:250`. |
| Polish-gate | Repo-local measured code-space gate: grades `ubs`, `simplify`, `extreme-opt`, `readme`, `canonical-cli`, writes receipts, has schema/tests. | `templates/flywheel-install/polish-gate/run-grader.py:18`, `templates/flywheel-install/polish-gate/v1/grade-receipt.schema.json:41`, `templates/flywheel-install/tests/test_polish_gate_schemas.sh:91`, Socraticode `polish ui mobile desktop de-slopify` returned runner, schemas, fixtures, and tests. |
| Test corpus | 515 files is the mechanical code-space safety net. Direct code-space examples include quality-bar close gates, polish preflight, negative-invariant validation, golden fixture replay, and schema tests. | `.flywheel/tests/test_polish_preflight_quality_gate.sh:19`, `tests/quality-bar-close-gate.sh:22`, `templates/flywheel-install/tests/test_polish_gate_schemas.sh:91`, Socraticode `test fixtures flywheel tests validation hardening` surfaced golden fixture replay and validation evidence. |
| Code-review Gemini swarm | Load-bearing as cross-agent/random exploration pattern, but less mature in current doctrine because it still names `CronCreate` despite current `/loop` doctrine. It is a high-value review option, not default write-time gate. | `/Users/josh/.claude/skills/code-review-gemini-swarm-with-ntm/SKILL.md:12`, `/Users/josh/.claude/skills/code-review-gemini-swarm-with-ntm/SKILL.md:112`, `/Users/josh/.claude/skills/code-review-gemini-swarm-with-ntm/SKILL.md:141`, `rg` surfaced multiple cross-skill references. |
| Code-simplifier | Load-bearing as lighter simplification pass for recent changes; explicitly recommended before commit and after complex logic, but lower proof burden than isomorphic refactor skill. | `/Users/josh/.claude/skills/code-simplifier/SKILL.md:19`, `/Users/josh/.claude/skills/code-simplifier/SKILL.md:31`, `/Users/josh/.claude/skills/code-simplifier/SKILL.md:168`, `rg` surfaced mission-gap proposals using `/ubs`, `/security-review`, and `/code-simplifier` as repeated passes. |

## Section 3: Vestigial

Vestigial count: 4.

| Surface | Classification | Evidence |
|---|---|---|
| Active UBS pre-commit hook | Missing enforcement, despite documented rule. Current repo has only the stock Git sample hook; no active `.git/hooks/pre-commit` file invoking UBS was observed. | `.git/hooks/pre-commit.sample:1`, `.git/hooks/pre-commit.sample:8`, `.git/hooks/pre-commit.sample:48`, `/Users/josh/.claude/skills/ubs/SKILL.md:17`. |
| `security-review/scripts/__pycache__/...pyc` | Generated cache, not a source-of-truth script; should not count as a maintained code-space surface. | `/Users/josh/.claude/skills/security-review/scripts/security_scanner.py:1`, `/Users/josh/.claude/skills/security-review/scripts/probe.sh:1`, `/Users/josh/.claude/skills/security-review/SKILL.md:44`. |
| `code-review-gemini-swarm-with-ntm` cron wording | Superseded operationally by current NTM/loop doctrine; the review loop is useful, but the CronCreate monitoring instruction is stale for this repo's current loop discipline. | `/Users/josh/.claude/skills/code-review-gemini-swarm-with-ntm/SKILL.md:88`, `/Users/josh/.claude/skills/code-review-gemini-swarm-with-ntm/SKILL.md:90`, `/Users/josh/.claude/skills/code-review-gemini-swarm-with-ntm/SKILL.md:100`. |
| `code-simplifier` as commit-first simplifier | Its example commits before simplification, which conflicts with write-time quality gates and makes it weaker than isomorphic simplify for risky refactors. Keep as low-risk review helper, not a closing gate. | `/Users/josh/.claude/skills/code-simplifier/SKILL.md:117`, `/Users/josh/.claude/skills/code-simplifier/SKILL.md:120`, `/Users/josh/.claude/skills/simplify-and-refactor-code-isomorphically/SKILL.md:31`. |

## Section 4: Missing Per Agent-Flywheel.com Gap Analysis

Tier gaps addressed: 4.

1. UBS before every commit: documented, not enforced. External doctrine says UBS is run before every commit and recommends a DCG-style pre-commit hook on changed files (`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:192`). Our `ubs` skill says the same at `/Users/josh/.claude/skills/ubs/SKILL.md:17`, but repo hook evidence only shows `.git/hooks/pre-commit.sample:1`. Gap: no active UBS hook.

2. De-slopify named-pattern coverage: covered. External doctrine names emdash overuse, "let's dive in", and "at its core" (`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:197`). Our de-slopify skill covers all three plus adjacent phrases at `/Users/josh/.claude/skills/de-slopify/SKILL.md:47`, `/Users/josh/.claude/skills/de-slopify/SKILL.md:50`, and `/Users/josh/.claude/skills/de-slopify/SKILL.md:51`. Gap remaining: coverage is skill text, not a reusable public-doc gate in flywheel itself.

3. Platform-specific UI/UX polish: partially covered. External doctrine calls for desktop and mobile separately (`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:202`). Our skill says the same at `/Users/josh/.claude/skills/ui-polish/SKILL.md:17` and `/Users/josh/.claude/skills/ui-polish/SKILL.md:92`. Gap: the flywheel repo's polish-gate grades code/doc surfaces, but does not store separate desktop/mobile visual receipts by default.

4. Random code exploration plus cross-agent review: partially covered. External doctrine alternates cross-agent review and random exploration until clean (`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:89`). Our multi-pass skill covers random exploration and clean convergence at `/Users/josh/.claude/skills/multi-pass-bug-hunting/SKILL.md:24` and `/Users/josh/.claude/skills/multi-pass-bug-hunting/SKILL.md:216`; Gemini swarm covers cross-review at `/Users/josh/.claude/skills/code-review-gemini-swarm-with-ntm/SKILL.md:141`. Gap: there is no single close gate that requires both to alternate until both are clean.

## Section 5: Lessons Learned

Today's evidence says LOC delta direction is a weak proxy by itself.

`opwu8` shows the classical hand-rolled to native win: 4 P0 NTM wire-ins, 51 callsites, about -2200 LOC, and 5 atomic commits. The lesson is that code-space discipline can be subtractive when native primitives replace local clones; success is obvious when fewer local lines produce more native behavior.

`flsau` complicates the metric: 8 P1 NTM wire-ins, 55 callsites, about +421 LOC, and 9 atomic commits. Positive delta was not automatically bloat because native primitives needed fixtures, wrapper integration, and test coverage. A native wire-in can add lines when it makes previously implicit behavior explicit and testable.

The right code-space success metric is callsite quality, not raw callsite count or raw LOC removed. A good wire-in has native primitive usage, clear fallback/removal of hand-rolled code, tests or receipts covering the path, and fewer hidden assumptions. LOC removed is a strong signal only when behavior and test depth do not shrink. LOC added is acceptable when it buys fixture coverage, measured gates, or integration receipts.

For bead bodies, this means code-space beads should require: files in scope, explicit test obligations, native-vs-hand-rolled target, expected proof shape, and allowed LOC direction. If a bead only says "wire native X", workers may optimize for negative delta and skip fixture obligations; if it only says "add coverage", workers may preserve duplicate code. The best body shape names both the simplification target and the proof target.

## Section 6: Fix-Bead Manifest

Recommendations only. No beads filed.

1. Title: `[code-space] add UBS staged pre-commit gate with DCG-compatible bypass receipt`
   Priority: P1
   Scope: repo-local hook/template surface plus documentation and tests only; do not mutate global `ubs` skill.
   Acceptance: active hook or installable hook template runs `ubs --staged --fail-on-warning` on staged code files, has a documented bypass receipt shape, and includes a regression test proving commits without clean UBS are blocked.

2. Title: `[code-space] add alternating review close gate for random exploration + cross-agent review`
   Priority: P2
   Scope: flywheel close/polish gate schema and docs; integrate existing `multi-pass-bug-hunting` and `code-review-gemini-swarm-with-ntm` as selected skills.
   Acceptance: close receipt can record random exploration pass, cross-agent review pass, final UBS pass, tests pass, and no deferred items; validation fails if either lane is missing for high-risk code-space beads.

3. Title: `[code-space] split UI polish receipts by desktop/mobile modality`
   Priority: P2
   Scope: polish-gate schema/runner/test fixtures only; do not edit `ui-polish` skill.
   Acceptance: grade receipts can store separate desktop and mobile evidence paths/scores, existing audit-only mode remains backward-compatible, and template tests prove both modalities are represented when UI surfaces are in scope.
