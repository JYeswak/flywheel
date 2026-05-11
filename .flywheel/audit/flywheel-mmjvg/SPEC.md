---
schema_version: flywheel-stamp-spec/v0.1
spec_id: flywheel-stamp-v0.1
bead: flywheel-mmjvg
authored_by: MagentaPond (flywheel:0.3)
authored_at: 2026-05-11
status: design (v0.1)
directive: Joshua-stamping-process-directive-2026-05-11T23:00Z
mission_anchor_link: project_flywheel_publish_readiness_every_jyeswak_repo_mission_2026_05_11
publish_decision_link: project_publish_decision_internal_proof_first_no_npm_v01_2026_05_11
---

# flywheel-stamp v0.1 — Design Spec

## 1. Purpose

`flywheel-stamp` is the **canonical idempotent applicator** that brings any
target repo to ZestStream publish-readiness by reproducing the
**skillos exemplar artifact set** (top-of-repo public face + `.flywheel/`
operational substrate) with target-specific placeholder fills.

Per the Joshua stamping-process directive (2026-05-11T~23:00Z):

> *Every jyeswak GitHub repo must end up either publish-ready
> (matches the stamp) or triaged to fold/archive. The stamp process
> applies to every project. The substrate-quality discipline is recursive
> across ~100+ repos.*

Paired with the publish-decision directive (2026-05-11T~22:00Z):

> *Prove the system is what we say it is internally before publishing.
> PRR = internal-substrate-quality-ladder. npm publish stays gated until
> paying-customer-pull.*

The stamp is therefore a **substrate quality propagator**, not a publishing
pipeline. It encodes "this is the shape of a repo we'd actually be proud of"
and lets that shape replicate at fleet scale (~100+ repos) without
hand-stamping each one.

## 2. Mission fitness

Class: **adjacent**.

Direct mission delivery = running the stamp across the jyeswak fleet and
landing each repo at publish-ready OR triaged-to-fold/archive. This spec is
the design substrate that makes that direct work possible. Without a
documented stamp the fleet roll-out is hand-toil and drifts artifact-by-artifact.

## 3. Reference exemplar

**Source of truth:** `/Users/josh/Developer/skillos` (alpha engine; this is
the artifact set the rest of the fleet should resemble).

Measured 2026-05-11 from skillos repo head:

| Artifact | Lines | Public/Private | Anchor pattern |
|---|---:|---|---|
| README.md | 331 | Public | Mission-anchor blockquote + Quick Start + CLI Reference |
| ARCHITECTURE.md | 337 | Public | "Front door is README; this is how the building is wired" framing + mission re-anchor + Three-layer model |
| ROADMAP.md | 330 | Public | Phased buildout + Status legend (✅ shipped / 🟡 partial / 🚧 design) + mission re-anchor |
| AGENTS.md | 145 | **Private** (gitignored) | L-Rule schema reference + canonical-doctrine pointer |
| LICENSE | 7 | Public | All-Rights-Reserved alpha (no redistribution) |
| SECURITY.md | 5 | Public | `security@zeststream.ai` contact + no-public-issues clause |
| CONTRIBUTING.md | 5 | Public | "Private alpha; authorized internal collaborators only" + commit hygiene rules |
| .gitignore | 81 | Public | Internal-substrate exclusions + public-safe `.flywheel/` re-includes (`!` rules) |
| .flywheel/MISSION.md | 168 | **Private** | YAML frontmatter (schema_version + doc_type + locked_at + locked_by + rev + lock_hash + mission_anchor) |
| .flywheel/GOAL.md | 103 | **Private** | YAML frontmatter (links to MISSION via source_lock_hash) + Current Goal section |
| .flywheel/AGENTS-CANONICAL.md | 145 | **Private** (re-included via .gitignore `!` rules) | L-rule schema + GENERATED comment pointing at scripts/agents-md-shard-extract.sh |
| .flywheel/STATE.md | 1269 | **Private** | append-only state log; allow-large receipt cited |
| .flywheel/INCIDENTS.md | 31 | **Private** | Incident table with bead refs |
| .flywheel/PUBLISHABILITY-AUDIT.md | — | **Private** | Self-grade against this spec (the meta-receipt) |
| .flywheel/dispatch-log.jsonl | — | **Private** | JSONL append-only dispatch trail |
| .flywheel/lock-log.jsonl | — | **Private** | JSONL append-only lock trail |

**Substrate subdirs (all under `.flywheel/`, all gitignored except where `!`-re-included):**

| Subdir | Role |
|---|---|
| `doctrine/` | trauma-class doctrine snapshots; canonical-sync target |
| `handoffs/` | session-handoff artifacts (operator-only) |
| `launchd/` | macOS launchd plists for watchers |
| `rules/` | L*.md rule sources (the AGENTS.md generator inputs) |
| `scripts/` | repo-local automation (canonical-sync, validators, etc) |
| `STATE-archive/` | rotated STATE.md snapshots |
| `tmp/` | scratch space (operator-only; gitignored) |
| `validation-schema/` | v1 schema.json + parse.sh for callback validation |

## 4. Stamp template structure

The stamp is **one artifact catalog file + one composition algorithm**, not a
monolithic template. Each catalog entry names:

```yaml
artifact_id: <stable id>
target_path: <relative-to-repo-root>
required: <yes|no|conditional>
condition: <expr-when-conditional>
template_source: <stamp/templates/<id>.tmpl>
placeholder_set: <list>
shape_signature:
  min_lines: <int>
  max_lines: <int>
  anchor_grep: <regex>
public_face: <yes|no>
gitignore_class: <public|private-re-included|private-excluded>
post_apply_hook: <none|script-path>
```

### 4.1 Placeholder set (canonical)

Every template uses **only** these placeholders. Unknown placeholders are
a stamp-spec violation (validator rejects at lint time).

| Placeholder | Meaning | Example fill |
|---|---|---|
| `{{REPO_NAME}}` | repo basename | `skillos` |
| `{{REPO_TITLE}}` | display title | `skillos` |
| `{{REPO_REALPATH}}` | absolute path | `/Users/josh/Developer/skillos` |
| `{{MISSION_ANCHOR}}` | one-sentence mission lock | `skillos is ZestStream's Skills Operating System...` |
| `{{MISSION_ANCHOR_HASH}}` | sha256 of mission_anchor | `80a15c43...` |
| `{{COPYRIGHT_YEAR}}` | 4-digit year | `2026` |
| `{{COPYRIGHT_HOLDER}}` | legal entity | `ZestStream.ai` |
| `{{SECURITY_CONTACT}}` | email | `security@zeststream.ai` |
| `{{QUICK_START_BLOCK}}` | repo-specific copy-pasteable | (per-repo) |
| `{{CLI_NAME}}` | canonical CLI binary | `skillos` |
| `{{HERO_IMAGE_PATH}}` | optional brand asset | `assets/brand/yuzu-hero.jpg` |
| `{{ROADMAP_STATUS_TABLE}}` | per-repo phase table | (per-repo) |
| `{{ARCHITECTURE_THREE_LAYERS}}` | layered-model block | (per-repo) |

**Placeholder discipline rule:** every public-face artifact (README,
ARCHITECTURE, ROADMAP) MUST contain `{{MISSION_ANCHOR}}` exactly once at the
top blockquote. This makes the stamp's mission-coherence machine-checkable.

### 4.2 Template catalog (v0.1)

Lives at `stamp/catalog.yaml` (relative to wherever flywheel-stamp ships).

15 entries: 8 root-level public-face + 7 `.flywheel/` substrate. Plus 8 subdir
scaffolds (`.flywheel/doctrine/`, etc.) registered as `directory_only=true`.

## 5. Idempotent-apply algorithm

The stamp ships as a CLI:

```
flywheel-stamp \
  --target <repo-root> \
  --mission-anchor <string|@file> \
  --placeholders <key=val,...|@file.yaml> \
  [--dry-run | --apply] \
  [--catalog <path>] \
  [--json] \
  [--strict] \
  [--explain] \
  [--doctor] \
  [--help|-h]
```

**Exit codes:**
- 0 — clean (apply mode: all artifacts at-spec; dry-run mode: no diffs)
- 1 — diffs detected (dry-run) OR partial-apply (apply with some skipped)
- 2 — usage error
- 3 — strict-mode violation (placeholder lint failed, anchor regex missed)
- 4 — catalog missing/corrupt
- 5 — target not a git repo / unsafe target

**Schema declared in JSON output:** `flywheel-stamp-apply/v1`

### 5.1 Phases

```
1. RESOLVE   — load catalog + placeholders + canonicalize target path
2. DETECT    — for each catalog entry: classify state in target repo
3. DIFF      — compute idempotent diff per artifact
4. PLAN      — emit apply-plan JSON (dry-run terminates here)
5. APPLY     — atomic per-artifact stamp + verify + receipt
6. RECEIPT   — write run-id receipt under target/.flywheel/stamp-receipts/
```

### 5.2 Per-artifact state classification (Phase 2)

For each catalog entry, classify into exactly one of:

| State | Meaning | Apply action |
|---|---|---|
| `ABSENT` | file does not exist | write fresh from template |
| `IDENTICAL` | exists + matches expected shape (placeholders all bound) | skip (no-op, count as already-stamped) |
| `DRIFTED_BENIGN` | exists + anchor regex matches + body diverges within tolerance | leave alone; log `drifted-benign-tolerated` |
| `DRIFTED_BREAKING` | exists + anchor regex misses OR placeholder mid-fill broken | refuse to apply; emit BLOCKED row; require operator decision |
| `EXTRA_LOCAL` | file exists + not in catalog | leave alone (operator's substrate) |

**Idempotency property:** `apply` followed by `apply` with identical inputs
produces **zero file mutations on the second pass**. Verified via
content-hashed pre/post snapshot per run.

### 5.3 Diff computation (Phase 3)

For each `ABSENT` or `DRIFTED_BREAKING` entry:
1. Render template with placeholder fills → in-memory candidate
2. If target exists: compute unified diff (3-line context); store as
   `<run-id>/<artifact_id>.diff`
3. Plan row: `{artifact_id, target_path, action, pre_sha, post_sha, diff_path}`

### 5.4 Apply algorithm (Phase 5)

**Per artifact** (sequential, fail-fast unless `--continue-on-error`):
1. `cp -p <target> <undo-root>/<run-id>/backups/<artifact_id>.bak` (when target exists)
2. Atomic write candidate → `<target>.stamp-tmp` → `mv -f` to `<target>`
3. Verify `sha256(target) == sha256(candidate)`; abort + restore from backup if not
4. Append `intent.jsonl` + `applied.jsonl` rows (compatible with
   `flywheel-loop doctor undo <run-id>` byte-exact restore chain — see
   `flywheel-oxzyr.2.2`)

**Cross-link to flywheel-loop substrate:** the stamp's apply phase
routes mutations through the SAME chokepoint pattern that flywheel-loop
uses (`_flywheel_loop_mutate` style: 4-step intent-then-apply with content-hashed
backup chain). This means `flywheel-loop doctor undo <run-id>` can roll back
a stamp run byte-exact. **No new undo infrastructure required.**

### 5.5 Receipt format (Phase 6)

Written to `<target>/.flywheel/stamp-receipts/<run-id>.json`:

```json
{
  "schema_version": "flywheel-stamp-receipt/v1",
  "run_id": "stamp-2026-05-11-<short-sha>",
  "ts": "2026-05-11T...",
  "target_repo": "<realpath>",
  "stamp_spec_version": "v0.1",
  "catalog_sha": "<sha256-of-catalog.yaml>",
  "placeholders_sha": "<sha256-of-resolved-placeholder-map>",
  "artifacts": [
    {"artifact_id":"readme","state":"ABSENT","action":"stamped","pre_sha":null,"post_sha":"...","lines":331},
    {"artifact_id":"license","state":"IDENTICAL","action":"skipped","pre_sha":"...","post_sha":"...","lines":7}
  ],
  "summary": {"stamped":0,"skipped":0,"refused":0,"drifted_benign":0},
  "publish_readiness_score": "<N>/15"
}
```

## 6. Validation discipline

### 6.1 Pre-stamp validation (lint)

```bash
flywheel-stamp --doctor --catalog stamp/catalog.yaml --json
```

Checks:
- every template file referenced in catalog exists
- every placeholder used in any template appears in the canonical placeholder set (§4.1)
- every public-face artifact contains `{{MISSION_ANCHOR}}` exactly once
- catalog YAML parses + schema-valid

### 6.2 Post-stamp validation (round-trip)

```bash
flywheel-stamp --dry-run --target <repo>  # must return rc=0 (no diffs)
```

A clean stamped repo passes `--dry-run` with zero plan rows. This is the
**publish-readiness gate**.

### 6.3 Anchor regex per public-face artifact

| artifact_id | anchor_grep |
|---|---|
| readme | `^# \{\{REPO_TITLE\}\}` (post-render: `^# <repo>`) AND mission_anchor blockquote present |
| architecture | `^# .* — Architecture\b` |
| roadmap | `^# .* — Roadmap\b` + Status legend line |
| license | `^All Rights Reserved\b` |
| security | `^# Security\b` + `security@` literal |
| contributing | `^# Contributing\b` |
| gitignore | `^\.flywheel/\s*$` AND `^!\.flywheel/\s*$` (both rules present) |

## 7. Composition rules (what the stamp does NOT do)

Hard boundaries to keep v0.1 scope tight:

- **Does not generate ROADMAP phase tables.** Operator supplies
  `{{ROADMAP_STATUS_TABLE}}` per repo. Stamp only enforces shape (legend +
  mission anchor + Phased Buildout heading).
- **Does not auto-fill `{{MISSION_ANCHOR}}`.** Operator supplies via
  `--mission-anchor`. Mission selection is a Joshua-disposes decision per
  Axiom 5 (Taste is Human).
- **Does not auto-fill `{{QUICK_START_BLOCK}}` or `{{ARCHITECTURE_THREE_LAYERS}}`.**
  Per-repo specific; stamp enforces shape only.
- **Does not rotate AGENTS.md backups.** Existing
  `scripts/prune_agents_backups.sh` handles that.
- **Does not run `git add` / `git commit`.** Stamp is mutation-only;
  staging is operator's choice (and per `feedback_orchestrators_kill_panes_without_respawn` discipline).
- **Does not delete `EXTRA_LOCAL` files.** Stamp is additive +
  idempotent-replace; never destructive of files outside the catalog.
- **Does not handle multi-repo orchestration.** Single-target. Fleet roll-out
  is a separate driver script (out of v0.1).

## 8. Open questions (v0.1 → v0.2)

| # | Question | Default for v0.1 |
|---|---|---|
| 1 | Is `.flywheel/AGENTS-CANONICAL.md` synced from a central source-of-truth or stamped per-repo? | Stamped per-repo from `templates/AGENTS-CANONICAL.md.tmpl` (cross-repo sync deferred to v0.2; canonical-sync handles distribution today) |
| 2 | Should the stamp seed `.flywheel/rules/` with the canonical L-rule set? | NO in v0.1 — `.flywheel/rules/` left empty for operator; rules accrete via flywheel-loop substrate |
| 3 | Should the stamp create the `bin/<CLI_NAME>` entrypoint scaffold? | NO in v0.1 — CLI design is per-repo concern; stamp surface is artifact-only |
| 4 | Where does `flywheel-stamp` itself ship from? | candidate: `~/.claude/skills/.flywheel/bin/flywheel-stamp` (paired-jsm-import-patch like flywheel-loop); decision deferred |
| 5 | How does `flywheel-stamp` interact with `flywheel-loop init` (which already drops some `.flywheel/` substrate)? | Boundary: `flywheel-loop init` owns operational substrate (rules, scripts, validation-schema); `flywheel-stamp` owns public-face + mission-anchor artifacts. Overlap on `.flywheel/AGENTS-CANONICAL.md` → flywheel-stamp wins (it has the placeholder-aware template) |
| 6 | What's the publish-readiness score formula? | `(IDENTICAL + DRIFTED_BENIGN) / total_catalog_entries`; ≥13/15 = "publish-ready"; <13/15 = "needs work" |
| 7 | How does this interact with the fold/archive triage path? | Out of scope for the stamp; sibling tool `flywheel-triage` (separate bead) decides fold/archive vs stamp |

## 9. Mission coherence proof

Per Axiom 1 (Flywheel is Sacred), every loop must improve artifacts. This
spec improves the fleet-wide artifact substrate by:

1. Canonicalizing the publish-readiness shape (no more "what does a good
   ZestStream repo look like?" guesswork)
2. Making it machine-applyable (no hand-toil across 100+ repos)
3. Making it byte-exact reversible (composes with flywheel-loop doctor undo)
4. Making it auditable (receipts + publish-readiness score)

Mission anchor link: this spec is the **substrate enabling**
`project_flywheel_publish_readiness_every_jyeswak_repo_mission_2026_05_11`.
Without this spec, the directive ("every repo publish-ready or
fold/archive") devolves into ~100 hand-stamping toil-passes.

## 10. v0.1 acceptance for this design bead

The bead asks for: **catalog + template + idempotent-apply algorithm**. This
spec delivers:

- §3 — catalog of skillos exemplar artifacts (with measured shapes)
- §4 — stamp template structure (placeholder set + catalog entry schema)
- §5 — idempotent-apply algorithm (6 phases + state classification + diff +
  apply + receipt)
- §6 — validation discipline (pre + post + anchor regex)
- §7 — explicit non-goals (composition boundary)
- §8 — open questions for v0.2

Implementation of the `flywheel-stamp` CLI is **NOT** part of this bead.
Per META-RULE 2026-05-10 (decompose-by-natural-unit-not-bundle), separate
beads should follow for:
- `flywheel-mmjvg.1` — implement `flywheel-stamp` CLI (5-phase mutation pipeline)
- `flywheel-mmjvg.2` — author 15 templates in `stamp/templates/*.tmpl`
- `flywheel-mmjvg.3` — apply stamp to first 5 jyeswak repos (round-trip proof)
- `flywheel-mmjvg.4` — fleet roll-out across remaining ~95 repos (operator-tended)

These are noted as v0.2 follow-on work; not filed now per L52 (the spec
itself is the deliverable for this bead; v0.2 work surfaces in next
planning pass).
