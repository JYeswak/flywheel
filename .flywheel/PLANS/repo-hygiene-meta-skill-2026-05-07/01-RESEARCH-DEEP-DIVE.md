---
title: "Repo Hygiene Meta-Skill Phase 1 Research Deep Dive"
type: plan
created: 2026-05-07
frontmatter_source: scaffold-doc-frontmatter
---

# Repo Hygiene Meta-Skill Phase 1 Research Deep Dive

Generated: 2026-05-07T20:03:00Z
Bead: flywheel-1p9of
Scope: research-only. No cleanup applied, no beads created, no repo-local target files written.

## Method

Socraticode was run at K=10 per sample repo after confirming indexes were present. The canonical wrapper was invoked for mobile-eats and completed cleanly; all five repos had live indexed status before search. Measurement used `du`, `find`, `stat`, and `git status --short --untracked-files=all --ignored=no`. Candidate bytes below are measured inventory bytes, not reclaimable-byte promises.

Amendment #2 supersedes the bundled-skill wrapper idea. The design target is now:

1. Declarative `.flywheel/hygiene-targets.yaml` per repo.
2. A universal prompt template that composes existing skills inline:
   `/storage-health /dev-cache-janitor /apfs-snapshot-ops /docker-storage-ops /orbstack-ops /storage-ballast-helper /disk-observer /path-rationalization /canonical-cli-scoping /extreme-software-optimization`.

## Socraticode Ledger

| Repo | Indexed chunks observed | Queries | Key hits |
|---|---:|---:|---|
| `/Users/josh/Developer/flywheel` | 1139 | 10 | `storage-probe.sh`, `storage-prune.sh`, `session-residue-prune.sh`, storage L-rules, backup/generated skip rules |
| `/Users/josh/Developer/mobile-eats` | 3584 | 10 | Next 16 app, `mobile-eats-visual-gate.mjs`, repo-local flywheel storage doctrine |
| `/Users/josh/Developer/alpsinsurance` | 70384 | 10 | rehearsal screenshots, Supabase temp state, backend coverage/pycache, Docker/Next surfaces |
| `/Users/josh/Developer/zesttube` | 13783 | 10 | `src/storage/cache_prune.py`, Remotion render paths, video/cache outputs, model cache setup |
| `/Users/josh/Developer/skillos` | 2924 | 10 | gitignore-hardening receipt, skill inventory state, beads-compliance audit pattern, canonical CLI wrappers |

Query families per repo: cleanup/storage prior art, dropped artifacts, substrate backups, test residue, `.gitignore` gaps, local conventions, CLI surfaces, tool-specific residue, dry-run/idempotency schema, and prompt/composition pattern.

## Section 1 - Per-Repo Trauma Classes

### flywheel

Repo: `/Users/josh/Developer/flywheel`
HEAD: `99bea54`
Disk size: 1129428 KiB

| Trauma class | Glob / source | Count | Bytes | Age range UTC | Safety |
|---|---|---:|---:|---|---|
| beads backup roots | `.beads.bak.*` | 5 | 719450112 | 2026-05-01T16:15:04Z..2026-05-04T20:23:31Z | age-gated |
| beads failed roots | `.beads.failed.*` | 1 | 4149248 | 2026-05-01T16:18:37Z..same | age-gated |
| beads db backups | `.beads/*.bak*` | 7 | 14573568 | 2026-05-05T00:32:47Z..2026-05-07T01:28:39Z | age-gated |
| lock preview drafts | `.flywheel/*.md.preview.*` | 3 | 12288 | 2026-05-01T04:41:01Z..2026-05-01T04:41:02Z | age-gated |
| reconcile diffs | `.flywheel/.reconcile-*.diff` | 1 | 12288 | 2026-05-01T05:20:23Z..same | age-gated |
| script backup files | `.flywheel/scripts/*.bak.*` | 6 | 90112 | 2026-05-03T01:42:04Z..2026-05-05T02:07:25Z | age-gated |
| Python bytecode | `__pycache__/` | 2 | 704512 | 2026-05-06T02:50:49Z..2026-05-07T14:55:10Z | always-safe |
| sqlite sidecars | `storage.sqlite3*` | 3 | 323584 | 2026-05-03T06:30:31Z..2026-05-07T15:34:39Z | never-delete-only-document while process may own DB |

Prior art: `.flywheel/scripts/storage-prune.sh`, `.flywheel/scripts/storage-probe.sh`, `.flywheel/scripts/session-residue-prune.sh`, `.flywheel/scripts/private-tmp-prune.sh`, tests under `tests/storage-*.sh`.

### mobile-eats

Repo: `/Users/josh/Developer/mobile-eats`
HEAD: `5bb5fd2`
Disk size: 2004268 KiB

| Trauma class | Glob / source | Count | Bytes | Age range UTC | Safety |
|---|---|---:|---:|---|---|
| dependency tree | `next-app/node_modules/` | 1 | 1028063232 | 2026-05-07T18:12:57Z..same | never-delete-only-document by default; dev-cache skill can advise |
| substrate backups | `*.bak.*` | 93 | 19959808 | 2026-05-02T15:10:14Z..2026-05-06T13:26:36Z | age-gated |
| flywheel tick receipts | `.flywheel/ticks*` | 47 | 376832 | 2026-05-02T12:11:50Z..2026-05-03T19:11:50Z | age-gated |
| ntm local state | `.ntm/` | 1 | 65536 | 2026-05-07T19:42:14Z..same | never-delete-only-document unless ntm says safe |
| Vercel state | `.vercel/` | 1 | 8192 | 2026-05-02T12:17:01Z..same | always-safe if not deploy-auth dependent |
| Playwright results | `test-results/` | 1 | 4096 | 2026-05-07T15:13:10Z..same | always-safe after receipt capture |
| Next build output | `.next/` | 0 | 0 | none | always-safe when present |
| visual-gate artifacts | `next-app/.mobile-eats-visual-gate*` | 0 | 0 | none | age-gated because artifacts may be evidence |

Prior art: `next-app/scripts/mobile-eats-visual-gate.mjs` writes screenshot receipts; `next-app/scripts/README.md` classifies package scripts by mutation class.

### alpsinsurance

Repo: `/Users/josh/Developer/alpsinsurance`
HEAD: `3ce7c7e3`
Disk size: 3499684 KiB

| Trauma class | Glob / source | Count | Bytes | Age range UTC | Safety |
|---|---|---:|---:|---|---|
| substrate backups | `*.bak*` | 80 | 815861760 | 2026-04-24T21:51:40Z..2026-05-07T03:39:08Z | age-gated |
| Next build output | `frontend/.next*` | 1224 | 777158656 | 2026-04-24T17:13:39Z..2026-04-30T18:01:44Z | always-safe if no local server depends on it |
| Python bytecode | `__pycache__/` | 1386 | 207667200 | 2026-04-22T04:07:35Z..2026-05-07T13:42:27Z | always-safe, but venv-contained caches should route through dev-cache janitor |
| rehearsal screenshots | `knowledge/rehearsal-screenshots*` | 9 | 9781248 | 2026-05-07T16:05:26Z..same | never-delete-only-document; evidence artifacts |
| coverage packages/caches | `coverage/` dirs | 2 | 3289088 | 2026-04-23T15:19:47Z..2026-05-04T18:06:12Z | document; paths are package dirs inside venvs, not coverage reports |
| Supabase temp | `supabase/.temp*` | 10 | 73728 | 2026-04-30T17:33:10Z..2026-05-07T06:35:55Z | age-gated; Supabase CLI state |
| htmlcov | `htmlcov/` | 0 | 0 | none | always-safe when present |

Prior art: `docker-compose.yml`, `frontend/Dockerfile`, Supabase README/runbooks, Playwright rehearsal cleanup in `frontend/tests/e2e/demo/dress-rehearsal.spec.ts`.

### zesttube

Repo: `/Users/josh/Developer/zesttube`
HEAD: `e5c939d`
Disk size: 70417760 KiB

| Trauma class | Glob / source | Count | Bytes | Age range UTC | Safety |
|---|---|---:|---:|---|---|
| Remotion output | `remotion/out*` | 3 | 654729216 | 2026-04-27T10:54:33Z..2026-04-27T10:54:35Z | age-gated; may be evidence |
| pre-ship AV caches | `pre_ship_av_check_cache/` | 2 | 494845952 | 2026-04-25T16:54:03Z..2026-04-27T17:29:03Z | age-gated; existing `cache_prune.py` owns |
| Python bytecode | `__pycache__/` | 1220 | 210681856 | 2026-04-23T23:40:24Z..2026-04-30T17:06:54Z | always-safe |
| archived render mp4s | `render-*.mp4` | 3 | 103403520 | 2026-04-24T03:03:19Z..2026-04-25T16:54:02Z | never-delete-only-document unless episode policy says archived media can move |
| Remotion build | `remotion/build*` | 43 | 89616384 | 2026-04-27T17:41:54Z..2026-04-27T17:41:56Z | always-safe after build not running |
| intro/outro caches | `intro_outro_grade_cache/` | 2 | 36986880 | 2026-04-27T18:02:11Z..2026-04-28T04:07:43Z | age-gated; existing `cache_prune.py` owns |
| pre-ship failures | `pre_ship_failures/` | 1 | 13320192 | 2026-04-27T17:18:59Z..same | age-gated; may support rejection analysis |
| FFmpeg pass logs | `ffmpeg2pass*` | 0 | 0 | none | always-safe when present |

Prior art: `src/storage/cache_prune.py` already implements report/prune, default dry-run, TTL 14 days, `--execute --yes`, repo-bound deletion, and symlink refusal. Repo hygiene should wrap this local convention, not replace it.

### skillos

Repo: `/Users/josh/Developer/skillos`
HEAD: `3e83833`
Disk size: 340024 KiB

| Trauma class | Glob / source | Count | Bytes | Age range UTC | Safety |
|---|---|---:|---:|---|---|
| beads db backups | `.beads/*.bak*` | 68 | 73949184 | 2026-05-05T22:17:57Z..2026-05-07T19:40:58Z | age-gated |
| Python bytecode | `__pycache__/` | 8 | 4775936 | 2026-05-07T03:10:35Z..2026-05-07T19:24:05Z | always-safe |
| outputs | `outputs*` | 6 | 573440 | 2026-05-05T22:17:58Z..same | age-gated; can be evidence |
| pytest cache | `.pytest_cache/` | 1 | 163840 | 2026-05-03T03:37:09Z..same | always-safe |
| ntm local state | `.ntm/` | 1 | 159744 | 2026-05-07T18:33:49Z..same | never-delete-only-document unless ntm says safe |
| preview files | `*.preview.*` | 1 | 16384 | 2026-05-05T22:17:57Z..same | age-gated |
| state backups | `state/*.bak*` | 0 | 0 | none | age-gated when present |
| tmp files | `*.tmp` | 0 | 0 | none | always-safe when present |

Prior art: `state/skillos-6l18-claude-gitignore-hardening-2026-05-06.json` provides the best local model: classify runtime state, count dirty-tree reduction, cite patterns, and avoid hiding real WIP.

## Section 2 - Cross-Repo Patterns

Patterns common to 3+ repos and suitable for default trauma classes:

| Pattern | Repos seen | Default safety |
|---|---:|---|
| `*.bak*`, `*.bak.*`, `.beads/*.bak*` | 5 | age-gated |
| `__pycache__/` | 4 | always-safe |
| `.flywheel/` generated receipts/ticks/backups | 5 | age-gated by class; many are evidence |
| `.ntm/` local state | 3 | never-delete-only-document unless ntm provides safe prune |
| build/runtime outputs (`.next/`, `remotion/out`, `remotion/build`) | 3 | always-safe to age-gated depending evidence role |
| screenshot/render evidence | 3 | never-delete-only-document unless receipt is archived |

Default schema should distinguish `reclaimable`, `evidence`, `substrate`, and `dependency_cache`. A repo-hygiene pass should refuse tracked files and refuse evidence-class deletion unless an explicit archive receipt exists.

## Section 3 - Per-Tooling Residue

| Tooling | Detection markers | Residue classes | Repos observed | Recommended route |
|---|---|---|---|---|
| Next.js | `package.json`, `.next/` | `.next/`, standalone build output, `.turbo/` if present | mobile-eats, alpsinsurance | declarative age-gated class; use package manager docs, not raw `rm` first |
| Vercel | `.vercel/` | `.vercel/`, `.vercel/output`, `.vercel/cache` | mobile-eats | document credentials risk; prune only non-auth cache leaves |
| Supabase | `supabase/`, `supabase/.temp` | CLI temp, local branch/state | alpsinsurance | age-gated and tool-aware |
| Remotion | `remotion/package.json` | `remotion/out`, `remotion/build`, render mp4/mov | zesttube | age-gated; media outputs often evidence |
| Python | `requirements.txt`, `pyproject.toml` | `__pycache__`, `.pytest_cache`, `.mypy_cache`, `.ruff_cache`, venv caches | alpsinsurance, zesttube, skillos, flywheel | dev-cache janitor route |
| Beads | `.beads/` | `.beads/*.bak*`, `.br_recovery`, sidecars | flywheel, mobile-eats, alpsinsurance, skillos | substrate-aware age gate |
| Docker/OrbStack | `Dockerfile`, `docker-compose.yml` | images/buildkit/volumes external to repo | alpsinsurance | inline `/docker-storage-ops /orbstack-ops`; repo YAML only records detection |
| FFmpeg/OBS/MLflow | passlogs, recordings, `mlruns/` | none measured in sample repos except video outputs | zesttube candidate | optional patterns activated by detection |

## Section 4 - .gitignore Coverage Gaps

| Repo | Gap | Proposed disposition |
|---|---|---|
| flywheel | `.flywheel/MISSION.md.corrupted-*` untracked | add to hygiene-targets as age-gated substrate-corruption evidence; do not blanket ignore until repair receipts are stable |
| flywheel | `.beads/events.jsonl.recovery-archive-*` untracked | add to hygiene-targets as age-gated recovery archive |
| flywheel | many plan artifacts untracked | no hygiene action; active planning docs are WIP, not residue |
| mobile-eats | `.beads/issues.jsonl.bak` untracked | add to `.gitignore` and hygiene-targets; backup accumulator |
| mobile-eats | `.claude/scheduled_tasks.lock` untracked | add hygiene target as stale lock; ignore if generated locally |
| mobile-eats | `.flywheel/audits/**`, `.flywheel/findings/**` untracked | no prune by default; likely evidence/WIP |
| alpsinsurance | no untracked residue in first 120 status rows | no gap found |
| zesttube | repeated `AGENTS.md.bak.*` and `.flywheel/AGENTS-CANONICAL.md.bak.*` untracked | add to hygiene-targets as age-gated doctrine backup |
| zesttube | `visual/candidates/**` untracked | never-delete-only-document; visual evidence |
| skillos | `state/loop-30m.log`, `state/loop-schedule.jsonl`, blocker state JSONL untracked | add to hygiene-targets as age-gated runtime logs, not immediate ignore without retention policy |
| skillos | `state/beads-compliance-*.md` untracked | never-delete-only-document; audit evidence |

## Section 5 - Existing Prior Art

| Repo | Prior art to preserve |
|---|---|
| flywheel | `storage-prune.sh`, `storage-probe.sh`, `session-residue-prune.sh`, `private-tmp-prune.sh`, storage-headroom watcher, tests for dry-run/apply split |
| mobile-eats | `next-app/scripts/README.md` mutation taxonomy, `mobile-eats-visual-gate.mjs` artifact README, repo-local flywheel doctrine |
| alpsinsurance | Supabase README/runbooks, `frontend/tests/e2e/demo/dress-rehearsal.spec.ts` generated artifact cleanup, Docker/Next deployment surfaces |
| zesttube | `src/storage/cache_prune.py` is the strongest repo-local cleanup contract; dry-run default and symlink refusal are must-keep |
| skillos | gitignore-hardening receipt shape, canonical CLI wrappers, state receipt discipline |

## Section 6 - Proposed `hygiene-targets.yaml` Schema Draft

The planner phase should refine this into actual `.flywheel/hygiene-targets.yaml` files. This phase intentionally writes only the draft.

```yaml
schema_version: 1
repo_path: /absolute/repo/path
repo_kind: flywheel-managed
generated_by: repo-hygiene-phase1-research
generated_at: 2026-05-07T20:03:00Z

safety_contract:
  dry_run_default: true
  apply_requires_joshua_review: true
  idempotency_key_required: true
  refuses_tracked_files: true
  refuses_unmeasured_patterns: true
  refuses_evidence_without_archive_receipt: true
  receipt_dir: .flywheel/receipts/repo-hygiene
  measurement_fields:
    - path_glob
    - total_bytes
    - file_count
    - oldest_mtime
    - newest_mtime
    - recurrence_count

toolchain_detection:
  node:
    files_any: [package.json, pnpm-lock.yaml, package-lock.json, yarn.lock]
  next:
    dirs_any: [.next, frontend/.next, next-app/.next]
  vercel:
    dirs_any: [.vercel]
  python:
    files_any: [pyproject.toml, requirements.txt]
  beads:
    dirs_any: [.beads]
  flywheel:
    dirs_any: [.flywheel]
  remotion:
    files_any: [remotion/package.json]
  supabase:
    dirs_any: [supabase]
  docker:
    files_any: [Dockerfile, docker-compose.yml, compose.yml]

trauma_classes:
  substrate_backups:
    patterns: ["*.bak*", ".beads/*.bak*", ".beads.bak.*", ".beads.failed.*"]
    min_age_days: 7
    safety: age-gated
  preview_drafts:
    patterns: ["*.preview.*", ".flywheel/*.md.preview.*"]
    min_age_days: 7
    safety: age-gated
  python_bytecode:
    patterns: ["__pycache__/", ".pytest_cache/", ".mypy_cache/", ".ruff_cache/"]
    min_age_days: 0
    safety: always-safe
  build_outputs:
    patterns: [".next/", "dist/", "build/", "out/", "target/"]
    min_age_days: 1
    safety: age-gated
  evidence_artifacts:
    patterns: ["knowledge/rehearsal-screenshots/", "visual/candidates/", "render-*.mp4"]
    min_age_days: null
    safety: never-delete-only-document
```

### flywheel draft targets

```yaml
repo_path: /Users/josh/Developer/flywheel
trauma_classes:
  beads_backup_roots:
    patterns: [".beads.bak.*", ".beads.failed.*"]
    min_age_days: 7
    max_total_mb: 500
    safety: age-gated
  beads_db_sidecars:
    patterns: [".beads/*.bak*", ".beads/*.aside.*", ".beads/.br_recovery/"]
    min_age_days: 3
    safety: age-gated
  lock_skill_previews:
    patterns: [".flywheel/*.md.preview.*", ".flywheel/.reconcile-*.diff"]
    min_age_days: 7
    safety: age-gated
  python_bytecode:
    patterns: ["__pycache__/"]
    safety: always-safe
  sqlite_runtime:
    patterns: ["storage.sqlite3", "storage.sqlite3-wal", "storage.sqlite3-shm"]
    safety: never-delete-only-document
local_prior_art:
  prefer_scripts: [".flywheel/scripts/storage-prune.sh", ".flywheel/scripts/session-residue-prune.sh"]
```

### mobile-eats draft targets

```yaml
repo_path: /Users/josh/Developer/mobile-eats
trauma_classes:
  node_dependencies:
    patterns: ["next-app/node_modules/"]
    safety: never-delete-only-document
  substrate_backups:
    patterns: ["*.bak.*", ".beads/*.bak*"]
    min_age_days: 7
    safety: age-gated
  flywheel_ticks:
    patterns: [".flywheel/ticks/"]
    min_age_days: 7
    safety: age-gated
  test_residue:
    patterns: ["next-app/test-results/", "next-app/.mobile-eats-visual-gate*/"]
    min_age_days: 2
    safety: age-gated
  vercel_state:
    patterns: [".vercel/"]
    safety: never-delete-only-document
local_prior_art:
  read: ["next-app/scripts/README.md", "next-app/scripts/mobile-eats-visual-gate.mjs"]
```

### alpsinsurance draft targets

```yaml
repo_path: /Users/josh/Developer/alpsinsurance
trauma_classes:
  next_build_output:
    patterns: ["frontend/.next/"]
    min_age_days: 1
    safety: age-gated
  substrate_backups:
    patterns: ["*.bak*"]
    min_age_days: 7
    safety: age-gated
  python_bytecode:
    patterns: ["__pycache__/"]
    safety: always-safe
  supabase_temp:
    patterns: ["supabase/.temp/"]
    min_age_days: 3
    safety: age-gated
  rehearsal_evidence:
    patterns: ["knowledge/rehearsal-screenshots/"]
    safety: never-delete-only-document
  venv_caches:
    patterns: ["backend/.venv*/"]
    safety: never-delete-only-document
local_prior_art:
  read: ["docker-compose.yml", "frontend/Dockerfile", "infrastructure/supabase/README.md"]
```

### zesttube draft targets

```yaml
repo_path: /Users/josh/Developer/zesttube
trauma_classes:
  zesttube_regenerable_caches:
    patterns: ["pre_ship_av_check_cache/", "intro_outro_grade_cache/", "pre_ship_failures/", ".zest-cache/"]
    min_age_days: 14
    safety: age-gated
    local_owner: "src/storage/cache_prune.py"
  remotion_build_outputs:
    patterns: ["remotion/out/", "remotion/build/"]
    min_age_days: 3
    safety: age-gated
  archived_media:
    patterns: ["render-*.mp4", "*.mov", "*.wav"]
    safety: never-delete-only-document
  python_bytecode:
    patterns: ["__pycache__/"]
    safety: always-safe
  doctrine_backups:
    patterns: ["AGENTS.md.bak.*", ".flywheel/AGENTS-CANONICAL.md.bak.*"]
    min_age_days: 7
    safety: age-gated
local_prior_art:
  prefer_scripts: ["src/storage/cache_prune.py"]
```

### skillos draft targets

```yaml
repo_path: /Users/josh/Developer/skillos
trauma_classes:
  beads_backups:
    patterns: [".beads/*.bak*"]
    min_age_days: 7
    safety: age-gated
  runtime_logs:
    patterns: ["state/*.log", "state/*-counters.json", "state/*-schedule.jsonl"]
    min_age_days: 14
    safety: age-gated
  evidence_receipts:
    patterns: ["state/beads-compliance-*.md", "outputs/"]
    safety: never-delete-only-document
  preview_drafts:
    patterns: ["*.preview.*"]
    min_age_days: 7
    safety: age-gated
  python_bytecode:
    patterns: ["__pycache__/", ".pytest_cache/"]
    safety: always-safe
local_prior_art:
  read: ["state/skillos-6l18-claude-gitignore-hardening-2026-05-06.json"]
```

## Section 7 - Proposed Bead DAG (Preliminary)

1. P0 - Author hygiene-targets schema validator
   Output: JSON Schema + semantic validator for `.flywheel/hygiene-targets.yaml`.
   Acceptance: catches tracked-file deletion target, evidence class without archive policy, and missing dry-run safety contract.

2. P0 - Install repo-local hygiene-targets for five seed repos
   Output: one `.flywheel/hygiene-targets.yaml` per sample repo.
   Acceptance: all five validate; dry-run measurement reproduces Phase 1 counts within expected drift.

3. P0 - Author universal repo-hygiene prompt template
   Output: prompt artifact that loads inline skills and pins repo YAML as context.
   Acceptance: template includes safety gates, measurement receipt schema, no-apply default, and exact callback shape.

4. P1 - Build read-only hygiene doctor probe
   Output: flywheel-loop doctor field `repo_hygiene`.
   Acceptance: emits `coverage`, `candidate_bytes`, `untracked_gap_count`, and `unsafe_target_count` without modifying files.

5. P1 - Wire hygiene dry-run into onboarding
   Output: onboarding checklist step that creates/validates targets and runs dry-run.
   Acceptance: new repo cannot be marked flywheel-installed without a hygiene dry-run receipt or explicit waiver.

6. P2 - Add local-prior-art adapters
   Output: first adapters for flywheel `storage-prune.sh` and zesttube `cache_prune.py`.
   Acceptance: repo-hygiene prompt prefers local scripts over generic deletion.

## Section 8 - Inline Skill Composition Inventory and Universal Prompt Template

Amendment #2 decision: no bundled `repo-hygiene/SKILL.md` wrapper in this phase. The wrapper tier is declarative YAML plus the prompt template below.

| Inline skill | Existing path | Role in prompt |
|---|---|---|
| storage-health | `~/.claude/skills/storage-health/SKILL.md` | global disk pressure gates, never broad volume prune automatically |
| dev-cache-janitor | `~/.claude/skills/dev-cache-janitor/SKILL.md` | language/package cache pruning strategy |
| apfs-snapshot-ops | `~/.claude/skills/apfs-snapshot-ops/SKILL.md` | APFS/Time Machine snapshot awareness |
| docker-storage-ops | `~/.claude/skills/docker-storage-ops/SKILL.md` | Docker images/buildkit/volume classification |
| orbstack-ops | `~/.claude/skills/orbstack-ops/SKILL.md` | Joshua's active Docker runtime context |
| storage-ballast-helper | `~/.claude/skills/storage-ballast-helper/SKILL.md` | ballast/headroom policy |
| disk-observer | `~/.claude/skills/disk-observer/SKILL.md` | `du`/`dust`/trend observation framing |
| path-rationalization | `~/.claude/skills/path-rationalization/SKILL.md` | path safety, canonical path, backup/verify discipline |
| canonical-cli-scoping | `~/.claude/skills/canonical-cli-scoping/SKILL.md` | doctor/health/repair, validate/audit/why, `--json`, dry-run/apply discipline |
| extreme-software-optimization | `~/.claude/skills/extreme-software-optimization/SKILL.md` | measurement-first, prove impact, avoid assumption-driven cleanup |

### Universal prompt template

```text
/storage-health /dev-cache-janitor /apfs-snapshot-ops /docker-storage-ops
/orbstack-ops /storage-ballast-helper /disk-observer /path-rationalization
/canonical-cli-scoping /extreme-software-optimization

Repo hygiene pass for <repo_path>.

Context:
- Read <repo_path>/.flywheel/hygiene-targets.yaml.
- Research-only unless explicitly told otherwise.
- Default mode is dry-run. Do not delete, move, compress, or rewrite files.
- Refuse tracked-file targets. Verify with git ls-files before any apply proposal.
- Treat evidence classes as never-delete-only-document unless an archive receipt
  is explicitly present.
- Prefer local prior-art scripts named in hygiene-targets.yaml over generic
  shell deletion.

Required phases:
1. Storage gate:
   - Run storage-health read-only probes.
   - Record disk free, repo size, and global pressure context.
2. Target validation:
   - Validate hygiene-targets.yaml schema and semantic invariants.
   - Classify each trauma class as always-safe, age-gated, or never-delete-only-document.
3. Measurement:
   - For every target pattern, measure path glob, total bytes, file count,
     oldest mtime, newest mtime, and recurrence count.
   - Use du/find/stat or a local read-only script. No estimates.
4. Git safety:
   - Verify no target is tracked.
   - Separately report untracked recurring gaps not covered by .gitignore.
5. Tooling pass:
   - Detect Node/Next/Vercel/Python/Beads/Flywheel/Remotion/Supabase/Docker.
   - Use the inline skills to classify tool-specific cleanup surfaces.
6. Recommendation:
   - Output JSON plus a Markdown receipt.
   - For each candidate: recommend add-to-gitignore, add-to-hygiene-targets,
     prune-dry-run-only, never-delete-only-document, or no-action.

Output contract:
{
  "schema_version": "repo_hygiene.dry_run_receipt.v1",
  "repo_path": "<repo_path>",
  "mode": "dry-run",
  "storage_gate": {"ok": true, "notes": []},
  "targets_valid": true,
  "candidate_total_bytes": 0,
  "candidate_count": 0,
  "unsafe_target_count": 0,
  "tracked_target_count": 0,
  "gitignore_gap_count": 0,
  "classes": [
    {
      "name": "substrate_backups",
      "patterns": ["*.bak*"],
      "safety": "age-gated",
      "count": 0,
      "bytes": 0,
      "oldest_mtime": null,
      "newest_mtime": null,
      "recommendation": "dry-run-only"
    }
  ],
  "next_actions": []
}
```

## Measurement Summary

| Repo | Inventoried bytes |
|---|---:|
| flywheel | 739315712 |
| mobile-eats | 1048477696 |
| alpsinsurance | 1813831680 |
| zesttube | 1603584000 |
| skillos | 79638528 |
| Total | 5284847616 |

## Recommendation

Proceed to planner phase with the YAML-plus-prompt design. The highest-value next step is the schema validator plus five repo-local target drafts, not a new bundled skill. The existing skill library is already the execution substrate; the repo-specific YAML should become the stable onboard-time configuration surface.
