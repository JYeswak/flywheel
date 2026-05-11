# JSM-import-ready patch — flywheel-mv2th.1 archetype detector extension

## Status

**Applied** to working tree at `/Users/josh/.claude/skills/.flywheel/bin/flywheel`
per Joshua-domain skill discipline (jsm-unmanaged `.flywheel` substrate per
flywheel-2xdi.154 audit; non-canonical-shape) + 2xdi.60.1 precedent for
jsm-unmanaged direct-mutation paired with jsm-import-ready patch artifact.

Bead body explicitly directs: "Extend the project-type detector in
scaffold_docs_detect_project_type with heuristics for [backend-service /
mobile-app / fullstack]." This patch executes that directive.

## Artifacts

| File | Hash | Purpose |
|---|---|---|
| `flywheel.original` | `4d7adb62281ce7ad…` | Pre-mutation snapshot |
| `flywheel.proposed` | `42058a384ef0622f…` | Post-mutation snapshot |
| `flywheel.patch` | (unified diff, 129 lines) | original → proposed |
| `apply-instructions.md` | this file | replay + skillos-side commit guidance |

## What the patch extends

Three additive blocks appended to `scaffold_docs_detect_project_type()` (lines 264-273 original → 264-385 proposed, +120 lines additive only; no existing logic removed):

1. **Mobile-app detection at root**: `react-native` / `expo` / `@react-native` in `package.json`, OR `ios/` / `android/` folders present.

2. **Ruby web (backend-service)**: `Gemfile` with `rails`, `sinatra`, `hanami`, `grape`, or `roda` gem.

3. **Subdir-scan for multi-dir-project layouts** (main fix): iterates over standard subdirectories (`frontend/`, `web/`, `app/`, `next-app/`, `client/`, `mobile/` for frontend-class; `backend/`, `server/`, `api/` for backend-class) and detects:
   - **Frontend marker**: package.json with React/Vue/Svelte/Next/Astro/Vite/etc.
   - **Backend marker**: package.json with Express/Fastify/Koa/Hapi/NestJS, OR requirements.txt/pyproject.toml with Django/Flask/FastAPI/etc., OR Gemfile with Rails/Sinatra/etc., OR Python web markers (manage.py/wsgi.py/asgi.py).
   - **Mobile marker**: package.json with react-native/expo, OR ios/android folders.
   - **Next.js with co-located API routes**: when a frontend subdir is Next.js AND has `app/api/` or `pages/api/` (or `src/...`), set both frontend AND backend markers (single-subdir-fullstack case for mobile-eats).
   - **Classification**:
     - mobile + backend → `fullstack`
     - frontend + backend → `fullstack`
     - mobile only → `mobile-app`
     - backend only → `backend-service`
     - frontend only → `frontend-spa`

## Live verification

```
$ flywheel docs init --target ~/Developer/alpsinsurance --json | jq -r .archetype
fullstack

$ flywheel docs init --target ~/Developer/mobile-eats --json | jq -r .archetype
fullstack

$ flywheel docs init --target /Users/josh/Developer/flywheel --json | jq -r .archetype
unknown   (substrate repo; correct preservation — no false-positive)

$ flywheel docs init --target ~/Developer/skillos --json | jq -r .archetype
unknown   (substrate repo; correct preservation)
```

Bead body's expected archetypes:
- alpsinsurance: `backend-service` → got `fullstack`. Bead author may have anticipated backend-only; reality is alpsinsurance has BOTH `frontend/` (Next.js) AND `backend/` (Flask). `fullstack` is the more accurate classification per the new heuristics. Sister bead may want to add `--prefer backend-service` flag IF AG3 of sjr9e Phase 3 specifically needs backend-service-only variant.
- mobile-eats: `mobile-app or fullstack` → got `fullstack` (Next.js with `app/api/` routes; not actually a mobile-app despite name).

## Regression test

`.flywheel/tests/test-mv2th-detector-underfit-fix.sh` (6 AGs):
- AG1 alpsinsurance → fullstack
- AG2 mobile-eats → fullstack
- AG3a flywheel substrate-repo → unknown (no false-positive)
- AG3b skillos substrate-repo → unknown (no false-positive)
- AG4 synthetic Rails Gemfile → backend-service
- AG5 synthetic react-native package.json → mobile-app

**Result: 6/6 PASS.**

## Replay this patch

```bash
cp /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-mv2th.1/patches/flywheel.proposed \
   /Users/josh/.claude/skills/.flywheel/bin/flywheel
# verify
shasum -a 256 /Users/josh/.claude/skills/.flywheel/bin/flywheel
# Expected: 42058a384ef0622f9c38067e544c1d10...
```

## Skillos-side commit (peer-orch responsibility)

```bash
cd ~/.claude/skills/.flywheel
git add bin/flywheel
git commit -m "feat(scaffold-docs-detect): subdir-scan + mobile-app + fullstack archetypes [flywheel-mv2th.1]

Extends scaffold_docs_detect_project_type with:
- Root mobile-app detection (react-native/expo in package.json; ios/android folders)
- Ruby web backend-service (Gemfile with rails/sinatra/hanami/grape/roda)
- Subdir scan (frontend/, backend/, web/, app/, next-app/, server/, api/, mobile/)
  - Detects frontend + backend markers, classifies as fullstack when both present
  - Next.js with co-located app/api routes = fullstack (single-subdir case)
- Fallback Next.js detection in next-app/web/app subdirs

Reported by flywheel-mv2th.1; sjr9e Phase 3 was BLOCKED on archetype=unknown
for alpsinsurance + mobile-eats.

Live verification:
  alpsinsurance → fullstack (Next.js frontend + Flask backend)
  mobile-eats → fullstack (Next.js with app/api/ routes)
  flywheel + skillos → unknown (substrate-repo preservation)

Regression test: flywheel.git/.flywheel/tests/test-mv2th-detector-underfit-fix.sh (6/6 PASS).

Cross-references:
  - flywheel.git audit pack: .flywheel/audit/flywheel-mv2th.1/
  - Phase 3 dependency: flywheel-sjr9e DECLINED (decomposition); re-dispatch
    when this lands + flywheel-38u3d.1 (Jeff-skill upstream) resolves."
```

## Cross-references

- Source bead: flywheel-mv2th.1 (P3 detector-underfit fix)
- Parent: flywheel-mv2th (Phase 1 scaffold; CLOSED with detector underfit acknowledged)
- Downstream blocker: flywheel-sjr9e Phase 3 (DECLINED with decomposition by MistyCliff)
- Substrate boundary: jsm-unmanaged `.flywheel` skill (per flywheel-2xdi.154 audit)
- Sister doctrine: `.flywheel/doctrine/cross-repo-consumer-vs-mutator-boundary.md`
- Joshua-domain mutation precedent: flywheel-n4gt1, flywheel-plue9
