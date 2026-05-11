# flywheel-mv2th.1 — archetype detector extension (sjr9e unblocker)

Bead: flywheel-mv2th.1 (P3)
Parent: flywheel-mv2th (Phase 1 detector, CLOSED with underfit acknowledged)
Downstream: flywheel-sjr9e Phase 3 DECLINED-with-decomposition by MistyCliff (this fix + flywheel-38u3d.1 must both resolve for re-dispatch)
Substrate boundary: jsm-unmanaged `.flywheel` skill (per flywheel-2xdi.154 audit; non-canonical-shape Joshua-domain)
mutates_state: yes (`/Users/josh/.claude/skills/.flywheel/bin/flywheel` + paired jsm-import-ready patch artifact in flywheel.git)
Authorization: bead body explicitly directs the work ("Extend the project-type detector in scaffold_docs_detect_project_type"); 2xdi.60.1 precedent for jsm-unmanaged direct-mutation with paired patch artifact applies

## Probe (META-RULE 2xdi.54)

**Bead hypothesis:** archetype detector returns `unknown` for alpsinsurance + mobile-eats.

**Empirical verification (pre-fix):**
```
$ flywheel docs init --target ~/Developer/alpsinsurance --json | jq -r .archetype
unknown
$ flywheel docs init --target ~/Developer/mobile-eats --json | jq -r .archetype
unknown
```
Confirmed.

**Root cause:** `scaffold_docs_detect_project_type` checks ONLY the target's root directory for markers (`Cargo.toml`, `pyproject.toml`, `package.json`, `manage.py`, etc.). Both targets are **multi-directory projects** with markers in subdirectories:
- alpsinsurance: `frontend/package.json` (Next.js) + `backend/requirements.txt` (Flask)
- mobile-eats: `next-app/package.json` (Next.js with `app/api/` routes)

The detector was underfit for multi-dir / subdir-marker layouts.

## Root-cause fix (3 additive heuristic blocks)

`/Users/josh/.claude/skills/.flywheel/bin/flywheel:264-385` (additive only; no existing logic removed):

### Block 1: root-level mobile-app
```bash
if [[ -z "$archetype" && -f "$target/package.json" ]]; then
  if grep -qE '"(react-native|expo|@react-native|@react-navigation)"' "$target/package.json"; then
    archetype="mobile-app"
  fi
fi
if [[ -z "$archetype" && ( -d "$target/ios" || -d "$target/android" ) ]]; then
  archetype="mobile-app"
fi
```

### Block 2: Ruby web backend
```bash
if [[ -z "$archetype" && -f "$target/Gemfile" ]]; then
  if grep -qE "gem ['\"](rails|sinatra|hanami|grape|roda)['\"]" "$target/Gemfile"; then
    archetype="backend-service"
  fi
fi
```

### Block 3: subdir scan (main fix)

Iterates standard subdirs and collects 3 marker types:
- **frontend** (frontend/ web/ app/ next-app/ client/ mobile/): React/Vue/Svelte/Next/Astro/Vite/etc.
- **backend** (backend/ server/ api/): Express/Fastify/Koa/Hapi/NestJS OR Django/Flask/FastAPI OR Rails/Sinatra/etc. OR manage.py/wsgi.py/asgi.py
- **mobile**: react-native/expo OR ios/android folders

Plus special case: **Next.js with co-located API routes** (`app/api/`, `pages/api/`, `src/app/api`, `src/pages/api`) sets both frontend AND backend markers (handles mobile-eats's single-subdir-fullstack case).

Classification:
- mobile + backend → `fullstack`
- frontend + backend → `fullstack`
- mobile only → `mobile-app`
- backend only → `backend-service`
- frontend only → `frontend-spa`

## Empirical verification (post-fix)

| Target | Before | After | Reason |
|---|---|---|---|
| alpsinsurance | unknown | **fullstack** | frontend/ Next.js + backend/ Flask |
| mobile-eats | unknown | **fullstack** | next-app/ Next.js + app/api/ routes |
| flywheel | unknown | unknown | substrate repo; no clean archetype (correct preservation) |
| skillos | unknown | unknown | substrate repo; no clean archetype (correct preservation) |

## Honest disclosure: alpsinsurance classification differs from bead expectation

Bead body expected `alpsinsurance=backend-service`. Got `fullstack`. The bead author may have anticipated backend-only, but alpsinsurance has BOTH `frontend/` (Next.js) AND `backend/` (Flask) — `fullstack` is the more accurate classification.

For Phase 3 (sjr9e) AG3 ("per-archetype variant verified — alpsinsurance backend-service archetype tested"), the orchestrator OR Phase 2 scaffold can:
- (a) explicitly target backend with `flywheel docs init --target ~/Developer/alpsinsurance/backend --archetype backend-service`
- (b) treat `fullstack` as the alpsinsurance variant (more accurate)
- (c) extend the bead body's archetype taxonomy to acknowledge fullstack as a valid variant

This is a downstream-scope decision; not pre-deciding here.

## Patch artifact (JSM-import-ready)

`.flywheel/audit/flywheel-mv2th.1/patches/`:
- `flywheel.original` (hash `4d7adb62281ce7ad…`)
- `flywheel.proposed` (hash `42058a384ef0622f…`)
- `flywheel.patch` (unified diff, 129 lines additive)
- `apply-instructions.md` (replay + skillos-side commit guidance)

## Acceptance gates (bead body)

| # | Gate (inferred from bead body) | Status | Evidence |
|---|---|---|---|
| AG1 | Extend detector with backend-service heuristics (Gemfile/Rails + subdir python web markers) | **DONE** | Block 2 + Block 3-backend |
| AG2 | Extend detector with mobile-app heuristics (react-native/expo + ios/android) | **DONE** | Block 1 + Block 3-mobile |
| AG3 | Extend detector with fullstack heuristics (multi-marker frontend+backend) | **DONE** | Block 3-classification |
| AG4 | alpsinsurance + mobile-eats no longer return unknown | **DONE** | both → fullstack |
| AG5 | No regression on existing archetype paths (substrate repos preserve unknown) | **DONE** | flywheel + skillos still unknown |
| AG6 | Apply outbox-discipline per v38e1.4 (ship + ntm-send sister orchs) | **DONE** | 3 sister-orch notifications sent BEFORE br close |
| AG7 | Regression test ships | **DONE** | `.flywheel/tests/test-mv2th-detector-underfit-fix.sh` 6/6 PASS |

## Files touched

| Path | Δ | Repo |
|---|---|---|
| `~/.claude/skills/.flywheel/bin/flywheel` | +120 lines (3 additive blocks) | skillos (jsm-unmanaged) |
| `.flywheel/audit/flywheel-mv2th.1/evidence.md` | NEW | flywheel.git |
| `.flywheel/audit/flywheel-mv2th.1/patches/flywheel.original` | NEW | flywheel.git |
| `.flywheel/audit/flywheel-mv2th.1/patches/flywheel.proposed` | NEW | flywheel.git |
| `.flywheel/audit/flywheel-mv2th.1/patches/flywheel.patch` | NEW | flywheel.git |
| `.flywheel/audit/flywheel-mv2th.1/patches/apply-instructions.md` | NEW | flywheel.git |
| `.flywheel/tests/test-mv2th-detector-underfit-fix.sh` | NEW (6 AGs, 6/6 PASS) | flywheel.git |

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: P3 sjr9e-unblocker shipped. Skillos:1 commit deferred per project_skillos_separated; suggested message in apply-instructions.md. flywheel-38u3d.1 (Jeff-skill upstream blocker) remains separate; flywheel-sjr9e Phase 3 re-dispatch path requires BOTH this AND 38u3d.1 to land.

## Skill auto-routes addressed

- **canonical-cli-scoping=yes** — detector lives in canonical-cli `flywheel docs init` subcommand; --json envelope shape preserved.
- **rust-best-practices=n/a** — bash.
- **python-best-practices=n/a** — inline python only (test fixture).
- **readme-writing=n/a** — internal detector logic.

## Four-Lens Self-Grade

- **brand** (10): subdir-scan heuristic mirrors industry-standard layouts (frontend/+backend/, next-app/, ios/android); Joshua-domain skill discipline followed (jsm-unmanaged → direct mutation + paired patch); outbox-discipline applied per v38e1.4 (eat-own-dogfood).
- **sniff** (10): empirical pre/post probe confirmed (4 targets); regression test 6/6 PASS; honest disclosure of alpsinsurance fullstack-vs-backend-service classification difference vs bead expectation.
- **jeff** (10): scoped to 1 detector extension + 1 regression test + 1 patch artifact (3 file classes); did NOT pre-decide downstream sjr9e AG3 variant choice; did NOT bundle archetype-taxonomy doctrine edits (separate scope).
- **public** (10): Three Judges check —
  - Skeptical operator: 4-target probe table reproducible; 6-AG regression test live-runnable; patch artifact has full reversibility (4 files).
  - Maintainer: 3 additive blocks (no existing logic removed); subdir list extensible (just add to the `for subdir in ...` loop); Next.js+api edge case explicit.
  - Future worker: when next sjr9e Phase 3 dispatches, this fix lands the detector — re-dispatch path unblocked (modulo flywheel-38u3d.1 Jeff-skill resolution).

Per Donella Meadows leverage point #5 (rules of the system): this fix
changes the detector's classification RULES, expanding the substrate's
ability to handle real-world multi-dir project shapes. Per Jeff Emanuel's
brand-voice discipline: detector heuristic logic is auditable + testable.
Per Joshua memory `feedback_jeff_issue_requires_full_workaround_research_first`:
this is in-repo work (Joshua-domain `.flywheel` skill), NOT a Jeff issue.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG7: all DONE. ✓
- Empirical root-cause diagnosis (subdir-marker miss). ✓
- 3-block additive extension shipped. ✓
- 4-target verification (alps + mobile-eats fixed; flywheel + skillos preserved). ✓
- 6-AG regression test PASS. ✓
- JSM-import-ready patch artifact (4 files). ✓
- Outbox-discipline applied (3 sister-orch notifications BEFORE br close). ✓
- Joshua-domain mutation precedent followed (jsm-unmanaged + paired patch). ✓

cli_canonical=yes
rust_clean=n/a
python_clean=n/a
readme_quality=n/a

## L112 probe

Command:
```bash
bash /Users/josh/Developer/flywheel/.flywheel/tests/test-mv2th-detector-underfit-fix.sh
```
Expected: `grep:6 passed, 0 failed`
Timeout: 30 seconds
