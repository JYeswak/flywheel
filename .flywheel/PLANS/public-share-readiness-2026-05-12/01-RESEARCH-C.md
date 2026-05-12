# RESEARCH-C — Implementation Design

> Lane C of Phase 1. Specifies HOW the flywheel engine gets extracted, installed, and shipped. Design document, not implementation. Cross-references Lane A (PAI gap analysis) and Lane B (publishing standards) where relevant.

**Author:** flywheel:1 Phase 1 Lane C
**Created:** 2026-05-12
**Status:** Draft for Phase 2 REFINE

---

## 0. Naming convention used in this doc

- **Source repo** — current `/Users/josh/Developer/flywheel/` (private monorepo, mixed engine+overlay)
- **Public repo** — target `github.com/JYeswak/flywheel` (or `zeststream/flywheel`; final TBD). Public, MIT-licensed, developer audience.
- **Webpage** — `flywheel.zeststream.ai`. SMB-client audience.
- **Engine** — universal, de-personalized substrate (per `ENGINE-OVERLAY-BOUNDARY.md`)
- **Overlay** — instance-specific, private (per same)
- **Working extraction tree** — temporary scratch at `~/Developer/_flywheel-extract-<ts>/` used during extraction

---

## 1. Engine extraction script spec

### 1.1 Goal

Transform the source repo into a publishable public repo, deterministically and reversibly, with every engine artifact de-personalized at the byte level.

### 1.2 Architecture

The extraction is a **three-phase pipeline**, each phase atomic and resumable:

```
SOURCE REPO  →  [1] CLASSIFY  →  classification.jsonl    (in working tree)
                       ↓
                [2] DE-PERSONALIZE  →  staged/  (rewritten artifacts; one file per engine source)
                       ↓
                [3] ASSEMBLE  →  zeststream-flywheel/    (publishable; git-init fresh)
                       ↓
                [4] VERIFY  →  doctor reports pass on a fresh install from staged
```

Each phase writes its outputs to disk before the next phase runs. Phase 2 reads phase 1's manifest; phase 3 reads phase 2's staged tree. No cross-phase in-memory state.

### 1.3 Source → destination path mapping

| Source (in monorepo) | Destination (in public repo) | Rule |
|---|---|---|
| `.flywheel/doctrine/<name>.md` (engine class) | `engine/doctrine/<name>.md` | classify + de-personalize |
| `.flywheel/doctrine/<name>.md` (overlay class) | `<dropped>` | preserved in source only |
| `.flywheel/scripts/<name>.sh` (engine class) | `engine/scripts/<name>.sh` | classify + de-personalize + lint |
| `.flywheel/hooks/<name>.sh` | `engine/hooks/<name>.sh` | classify + de-personalize |
| `.flywheel/templates/<name>` | `engine/templates/<name>` | classify + parameterize |
| `~/.claude/projects/<this>/memory/*.md` (engine class) | `engine/universal-memory/<name>.md` | classify + de-personalize |
| `~/.claude/skills/<name>/` (engine class) | `engine/skills/<name>/` | classify + de-personalize |
| `~/.claude/hooks/<name>.sh` (engine class) | `engine/hooks/<name>.sh` | classify + de-personalize |
| `GOAL.md`, `MISSION.md`, `STATE.md` | `<dropped>` (overlay) | preserved in source only |
| `.flywheel/PLANS/<slug>/` (this arc and similar) | `<dropped>` (overlay history) | preserved in source only |
| `LICENSE`, `README.md`, `CHARTER.md` (new) | repo root | written fresh in phase 3 |
| `.github/`, `docs/`, `examples/` | repo root | written fresh in phase 3 |

### 1.4 Per-substrate classification rules

**Doctrine** (`.flywheel/doctrine/*.md`):
- Engine if: contains no proper noun, client name, project name, pane id, date, or path more specific than `~/Developer/<project>/`
- Engine after sweep if: contains those tokens but the *pattern* is universal once they are placeholder-substituted (e.g., `Joshua` → `{operator}`, `skillos:1` → `{peer-orch}`)
- Overlay if: removing tokens collapses the document to an empty stub

**Memory rules** (`~/.claude/projects/<this>/memory/*.md`):
- Same rule as doctrine. Apply the test in `ENGINE-OVERLAY-BOUNDARY.md` §"The classification rule"
- Expected ratio: ~30-50 of 183 memory rules classify engine after de-personalization

**Scripts** (`.flywheel/scripts/*.sh|*.py`):
- Engine if: parameterizes its inputs (no hardcoded `/Users/josh`, no hardcoded client names)
- Engine after sweep if: trivially parameterizable
- Overlay if: deeply coupled to one user's infrastructure (e.g., uses Infisical PIDs as constants)
- Expected ratio: ~80-120 of 411 scripts ship engine

**Hooks** (`~/.claude/hooks/*.sh`, `.flywheel/hooks/*.sh`):
- Engine if: behavior is universal (DCG, cross-repo guard, secret-redact)
- Overlay if: behavior anchors on operator-specific paths or names
- Expected: ~8-15 hooks ship engine

**Skills** (`~/.claude/skills/<name>/`):
- Engine if: a developer who is not Joshua can run it without editing
- Overlay if: hardcodes `chiefzester@gmail.com`, ZestStream brand, specific clients
- Expected: ~30-60 of ~400 skills ship engine in v0.2

**Templates** (`.flywheel/templates/*`, `~/.claude/skills/*/templates/*`):
- All templates are engine-class by design (they are scaffolding by definition)
- De-personalization is template-variable substitution

### 1.5 Where de-personalization happens

**Codemod, not manual.** A single de-personalization pass uses a deterministic substitution table:

```
de_personalization_table.yaml:
  literal:
    "Joshua Nowak":        "{operator}"
    "Joshua":              "{operator}"
    "josh":                "{operator-handle}"
    "chiefzester@...":     "{operator-email}"
    "ZestStream":          "{brand}"  # only for engine docs; webpage keeps it
    "Montana":             "<dropped>"
    "Blackfoot Telecom":   "{client-A}"
    "ALPS":                "{client-B}"
    "TerraTitle":          "{client-C}"
    "ElektraFi":           "{former-employer}"
    "CubCloud":            "{gpu-vendor}"
    "/Users/josh":         "$HOME"
    "skillos:1":           "{peer-orch-a}"
    "mobile-eats:1":       "{peer-orch-b}"
    # ... etc

  regex:
    "session [0-9a-z]{5,8}": "{session-id}"
    "(?i)20\\d\\d-\\d\\d-\\d\\d":                "{date}"
    "pane [0-9]+":             "{pane-id}"
    "([a-z]+-[0-9a-z]{5})":    "{bead-id}"  # bead id shape

  drop_lines_matching:  # entire line discarded
    - "Joshua-directive"
    - "chiefzester"
    - "/Users/josh/Developer/<private-project>/"
```

The table itself is checked into the source repo at `.flywheel/extraction/de-personalization-table.yaml`. It is the **single source of truth** for what counts as personal data.

**Pass-throughs and exceptions:** the table marks specific files as `verbatim_ok` (e.g., charter, license) where no substitution is desired. It also lists `manual_review` files where a human (Joshua or a worker) reads the rewritten output before assembly.

### 1.6 Procedural spec (worker-implementable)

```
extract-engine.sh <source-repo> <output-dir> [--resume PHASE]

Phase 1 — CLASSIFY
  for each candidate file in {doctrine, memory, scripts, hooks, skills, templates}:
    apply classification heuristic (regex + de-personalization-table)
    write {path, class, reason, manual_review_required} to classification.jsonl
  emit summary: N engine, N overlay, N manual-review

Phase 2 — DE-PERSONALIZE
  read classification.jsonl
  for each engine-class file:
    apply de-personalization-table substitution
    if regex flagged & manual_review_required: copy original alongside .pending
    write to staged/<destination-path>
  emit per-file substitution diffs to staged/.diffs/<path>.diff
  emit summary: N substitutions applied, N files flagged manual_review

Phase 3 — ASSEMBLE
  init fresh git repo at <output-dir>
  copy staged/* into <output-dir>/
  write README.md, LICENSE, CHARTER.md, .github/, docs/scaffolds from templates
  commit "Initial extraction from flywheel monorepo at <source-sha> via extract-engine.sh v<X>"

Phase 4 — VERIFY (calls test plan §6)
  run smoke test against <output-dir>
  if all pass: print success + path
  if fail: print which checks failed; do NOT clean up <output-dir>
```

Flags:
- `--dry-run` — runs phases 1-2 but does not assemble; writes a report
- `--resume <PHASE>` — restarts from a named phase, using prior phase's outputs from disk
- `--include <glob>` / `--exclude <glob>` — for partial extractions during development

### 1.7 Reversibility

The extraction script is **strictly additive**: it never modifies the source repo. Reversal is `rm -rf <output-dir> && rm -rf <working-extraction-tree>/<ts>/`.

The source repo's monorepo state is preserved indefinitely. The public repo is regenerable from the source repo + de-personalization table at any time.

If the de-personalization table is wrong, the fix is: edit the table, re-run extract, regenerate the public repo. The public repo's git history may be rewritten in pre-v1.0 versions (with explicit `--force-with-lease` and an announcement) but freezes at v1.0.

### 1.8 Verification step

Phase 4 runs the smoke test (see §6.1). Specifically:

1. Fresh `~/.flywheel/` does not exist (assert)
2. `cd <output-dir> && ./install.sh --dry-run` succeeds
3. `cd <output-dir> && ./install.sh` succeeds
4. `flywheel doctor --post-install` returns 0
5. The hello-world walkthrough completes
6. `flywheel uninstall` restores byte-equality

If any step fails, phase 4 prints which and exits non-zero. The output dir is preserved for inspection.

---

## 2. Installer architecture

### 2.1 Script structure

The installer is a single bash script (~300-500 lines) with the following top-level functions, each with a single responsibility:

```
main()
  parse_flags()              # --version, --prefix, --dry-run, --no-hooks, --quiet
  probe_dependencies()
  detect_existing_install()
  fetch_engine()
  create_runtime_dirs()
  install_hooks()
  edit_claude_settings()
  write_install_receipt()
  run_post_install_doctor()
  print_summary()
```

Each function:
- Returns 0 on success, non-zero on failure
- Logs to `${INSTALL_LOG:-~/.flywheel/install.log}`
- Writes a rollback hint to a shared `ROLLBACK_PLAN` array before mutating anything
- Calls `rollback_and_exit` on any non-zero downstream call

### 2.2 Dependency probe

Minimum supported versions (probed; not auto-installed):

| Dep | Min version | Why |
|---|---|---|
| `bash` | 4.0 | associative arrays in installer |
| `git` | 2.30 | sparse-checkout for engine fetch |
| `jq` | 1.6 | settings.json edits |
| `python3` | 3.10 | hook scripts assume f-strings, walrus |
| `curl` | 7.50 | TLS 1.2+ for fetch |
| `shasum` (BSD) or `sha256sum` (GNU) | any | verify hash |

Optional but recommended:

| Dep | Why |
|---|---|
| `claude` (Claude Code CLI) | the agent flywheel runs on |
| `codex` | alternative agent runtime |
| `ntm` | multi-pane orchestration |
| `br` (beads_rust) | task graph |

Probe shape:

```bash
probe_dependency() {
  local cmd="$1" min_version="$2" required="$3"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    if [[ "$required" == "true" ]]; then
      die_with_remediation "$cmd not found" "$(remediation_for "$cmd")"
    else
      RECOMMENDED_MISSING+=("$cmd")
      return 0
    fi
  fi
  local actual; actual=$("$cmd" --version 2>&1 | extract_semver)
  version_compare "$actual" "$min_version" || die_version_old "$cmd" "$actual" "$min_version"
}
```

`remediation_for()` returns OS-specific install commands (homebrew on macOS, apt/yum/pacman on Linux). Never executes them.

### 2.3 File-creation transaction model

**Visible-state atomicity, not write atomicity.** The installer:

1. Builds the complete intended state in a staging dir: `~/.flywheel-stage-<ts>/`
2. Validates the staged state passes a pre-flight check (jq parses each json, bash -n each script, etc.)
3. **Renames** the staging dir into place: `mv ~/.flywheel-stage-<ts> ~/.flywheel`
4. For each hook file: `cp` into staging, then `mv` into `~/.claude/hooks/` one at a time
5. For settings.json: copy current → backup, write new to `.tmp`, fsync, rename `.tmp` → settings.json

If any step fails before step 3, `rm -rf ~/.flywheel-stage-<ts>` leaves the system byte-identical. After step 3, rollback consults the `ROLLBACK_PLAN` array to reverse hook copies and the settings.json swap.

### 2.4 settings.json edit logic

The edit is **additive, idempotent, with backup**:

```
edit_claude_settings()
  if not exists ~/.claude/settings.json:
    write minimal flywheel-only settings.json
    record "created" in install receipt
    return

  # parse-validate
  jq empty ~/.claude/settings.json || die "settings.json malformed; aborting"

  # backup
  cp ~/.claude/settings.json ~/.claude/settings.json.flywheel-backup-${TS}
  ROLLBACK_PLAN+=("mv ~/.claude/settings.json.flywheel-backup-${TS} ~/.claude/settings.json")

  # idempotency: detect existing flywheel hook entries by marker command
  EXISTING=$(jq '[.hooks.PreToolUse[]?.hooks[]?.command]
               | map(select(test("\\.flywheel/engine/hooks/")))
               | length' ~/.claude/settings.json)

  if [ "$EXISTING" -gt 0 ]; then
    print "flywheel hooks already registered; skipping"
    return 0
  fi

  # additive merge using jq
  jq --slurpfile additions <(echo "$FLYWHEEL_HOOK_BLOCK") '
    .hooks.PreToolUse  = ((.hooks.PreToolUse  // []) + $additions[0].PreToolUse)
    | .hooks.PostToolUse = ((.hooks.PostToolUse // []) + $additions[0].PostToolUse)
  ' ~/.claude/settings.json > ~/.claude/settings.json.tmp

  jq empty ~/.claude/settings.json.tmp || rollback "merged settings.json malformed"
  mv ~/.claude/settings.json.tmp ~/.claude/settings.json
```

The matcher commands themselves are the idempotency markers — they all contain `.flywheel/engine/hooks/` so re-runs detect prior installs.

### 2.5 Byte-equality backup

For every file the installer modifies (settings.json is the only one in v0.2), it produces:

```
<file>.flywheel-backup-<ts>     # cp -p preserves mtime, permissions
<file>.flywheel-backup-<ts>.sha256   # shasum -a 256 of pre-state
```

Uninstall verifies the backup's sha256 matches the captured value before restoring. If it doesn't match, uninstall refuses to overwrite and prints both paths for manual reconciliation.

### 2.6 Post-install verification

```
flywheel doctor --post-install
```

Returns 0 if and only if every check passes. Checks:

| Check | What |
|---|---|
| `engine_present` | `~/.flywheel/engine/bin/flywheel` exists & is executable |
| `engine_version_matches` | `flywheel --version` matches install receipt |
| `hooks_present` | each expected hook file exists & is executable |
| `hooks_registered` | jq query of settings.json finds each hook entry |
| `hooks_self_test` | each hook runs against mock input and returns expected exit code |
| `settings_valid_json` | jq empty passes |
| `runtime_dirs_present` | `~/.flywheel/private/`, etc. exist |
| `receipt_present` | install-receipt-*.json exists |
| `optional_deps_detected` | NTM, br, claude noted absent/present |

Output mode is **machine-readable + human summary**: each check emits a JSON line; the summary prints a table.

### 2.7 Uninstaller

Symmetric to installer. Single function per file/edit it created or modified:

```
remove_engine_dir()
  rm -rf ~/.flywheel/engine

remove_installed_hooks()
  for hook in $(jq -r ... install-receipt.json); do
    rm -f "$hook"
  done

revert_settings_json()
  verify_backup_sha256 || abort "backup tampered; refusing to restore"
  mv ~/.claude/settings.json.flywheel-backup-${TS} ~/.claude/settings.json

preserve_user_data()
  # do NOT touch ~/.flywheel/private/, ~/.flywheel/config.yaml,
  # ~/.flywheel/cross-repo-authorized-writes.json
  print "preserved: <list>; remove with --purge"
```

Flags: `--purge` removes user overlay too (with confirmation); `--keep-hooks` removes engine but leaves hooks registered (rare).

### 2.8 Signing pipeline

At release time (a GitHub Actions release workflow):

1. Tag a version: `git tag v0.2.0 && git push --tags`
2. CI builds the release artifact set:
   - `install.sh` (the curl-piped script; pinned to the release tag)
   - `install.sh.sha256` (sha-256 of install.sh)
   - `engine.tar.gz` (engine subtree as released)
   - `engine.tar.gz.sha256`
   - `SHA256SUMS` (collected hashes; one file users can verify against everything)
3. The release workflow publishes a GitHub Release with these artifacts attached
4. The webpage `flywheel.zeststream.ai/install.sh` is served by a Cloudflare Worker (or static file from Vercel) that proxies the latest release's install.sh
5. The script's first 10 lines self-declare its sha256 (asserted equal to the published one)

User verification path:

```
EXPECTED=$(curl -sSL https://flywheel.zeststream.ai/install.sh.sha256)
ACTUAL=$(curl -sSL https://flywheel.zeststream.ai/install.sh | shasum -a 256 | awk '{print $1}')
test "$EXPECTED" = "$ACTUAL" && echo "verified" || echo "MISMATCH — do not run"
```

The script's own internal hash line is informational; the actually-trusted hash is the `.sha256` companion file, which is served as a static asset from the same origin.

**Signing limits in v0.2:** TLS to the origin is the trust anchor. No PGP keys, no minisign, no cosign in v0.2. Add at v0.3 if there is demand or after the first non-Joshua adopter ships an issue asking for it.

### 2.9 Versioning

Semver with a strict reading:

- `0.x` — pre-1.0; minor bumps may break behavior, but always with migration notes
- `1.x` — backward-compatible feature additions only
- `2.x` — breaking changes; explicit opt-in

`flywheel update` behavior:

```
flywheel update [--dry-run] [--to VERSION] [--major]

  1. Read current install receipt
  2. Fetch latest release index from github.com/JYeswak/flywheel/releases
  3. Compute target version:
       --to VERSION wins;
       else: latest within same MAJOR;
       --major: latest including MAJOR bumps (asks confirmation)
  4. Snapshot current state to ~/.flywheel/backups/<current-version>-<ts>/
  5. Diff staged-new-version against current; show summary
  6. Confirm (unless --yes)
  7. Replace ~/.flywheel/engine atomically (stage + rename)
  8. Re-run settings.json merge (additive; new hooks may exist)
  9. Run `flywheel doctor --post-update`
  10. Write update receipt
```

Downgrade: `flywheel update --to 0.2.0 --downgrade` (with confirmation). Same path in reverse.

---

## 3. Public repo structure

Target tree for `github.com/JYeswak/flywheel` at the v0.2.0 launch tag:

```
flywheel/
├── README.md                       # 5-min overview; the developer's first impression
├── LICENSE                         # MIT
├── CHARTER.md                      # mission + values; what flywheel is and isn't
├── CHANGELOG.md                    # semver-tagged history
├── CODE_OF_CONDUCT.md              # Contributor Covenant v2.1
├── CONTRIBUTING.md                 # how to contribute; PR conventions; DCO
├── SECURITY.md                     # how to report vulnerabilities; supported versions
├── install.sh                      # the curl-piped installer; the trust boundary
├── install.sh.sha256               # released hash (regenerated each release)
├── uninstall.sh                    # symmetric to installer
│
├── engine/                         # everything the installer puts under ~/.flywheel/engine/
│   ├── bin/
│   │   ├── flywheel                # the CLI entry (probably bash for v0.2)
│   │   ├── flywheel-doctor         # doctor/health/repair triad
│   │   └── ...
│   ├── doctrine/                   # universal doctrines (~30-50 .md after sweep)
│   ├── rules/                      # universal L-rules (~25 .md after sweep)
│   ├── hooks/                      # the safety hooks (cross-repo, DCG, secret-redact)
│   ├── scripts/                    # universal scripts (cleaner, helper)
│   ├── skills/                     # the engine-class skills
│   ├── templates/                  # files-the-user-instantiates (MISSION.md scaffold, etc.)
│   ├── universal-memory/           # de-personalized memory rules (~30-50 .md)
│   └── VERSION                     # semver string; consulted by `flywheel --version`
│
├── docs/                           # Nextra source for the docs site
│   ├── package.json
│   ├── theme.config.tsx
│   ├── next.config.mjs
│   ├── pages/
│   │   ├── index.mdx               # landing
│   │   ├── _meta.json
│   │   ├── getting-started.mdx     # the install + hello-world walkthrough
│   │   ├── architecture.mdx        # the 9-petal cycle, three spaces
│   │   ├── concepts/
│   │   │   ├── _meta.json
│   │   │   ├── plan-bead-code.mdx
│   │   │   ├── trauma-promotion.mdx
│   │   │   ├── substrate-classes.mdx
│   │   │   ├── cross-orch-protocol.mdx
│   │   │   └── doctor-health-repair.mdx
│   │   ├── reference/
│   │   │   ├── _meta.json
│   │   │   ├── cli.mdx             # every command + flag
│   │   │   ├── hooks.mdx           # what each hook does + how to disable
│   │   │   ├── doctrine.mdx        # index of universal doctrines
│   │   │   └── memory.mdx          # index of universal memory rules
│   │   ├── guides/
│   │   │   ├── _meta.json
│   │   │   ├── single-pane.mdx
│   │   │   ├── multi-pane.mdx
│   │   │   ├── adding-a-doctrine.mdx
│   │   │   └── writing-a-skill.mdx
│   │   └── about/
│   │       ├── _meta.json
│   │       ├── inspirations.mdx    # PAI, NTM, beads_rust, Aider, Meadows
│   │       └── faq.mdx
│   └── public/
│       └── og-cards/
│
├── examples/
│   ├── hello-doctor/               # `flywheel doctor` walkthrough in 5 commands
│   │   ├── README.md
│   │   └── expected-output.txt
│   ├── first-bead/                 # author + close one bead
│   │   ├── README.md
│   │   └── ...
│   └── multi-pane-mini/            # 1 orch + 1 worker minimal example
│       ├── README.md
│       └── ...
│
├── scripts/                        # repo maintenance, not shipped to users
│   ├── release.sh                  # builds the release artifact set
│   ├── compute-sha256.sh
│   ├── extract-from-source.sh      # if we keep regenerating from the monorepo
│   ├── lint-docs.sh
│   └── update-changelog.sh
│
├── tests/
│   ├── installer/
│   │   ├── test_dry_run.bats
│   │   ├── test_idempotent.bats
│   │   ├── test_rollback.bats
│   │   └── test_uninstall_byte_equality.bats
│   ├── hooks/
│   │   ├── fixtures/
│   │   └── test_*.bats
│   ├── doctor/
│   │   └── test_self_test.bats
│   └── smoke/
│       └── hello-world-smoke.sh
│
├── .github/
│   ├── workflows/
│   │   ├── ci.yaml                 # lint + tests on every PR
│   │   ├── docs.yaml               # build + deploy docs to Vercel
│   │   ├── release.yaml            # tag-driven release artifact build
│   │   └── installer-smoke.yaml    # nightly run of installer on macos/ubuntu runners
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug-report.yaml
│   │   ├── feature-request.yaml
│   │   ├── doctrine-proposal.yaml
│   │   └── config.yml
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── CODEOWNERS
│   ├── dependabot.yaml
│   └── FUNDING.yml                 # blank/disabled at v0.2; can add later
│
├── .gitignore
├── .editorconfig
├── .gitattributes
└── .git-blame-ignore-revs          # so the extraction commit doesn't dominate blame
```

### Justifications (one sentence each)

- `README.md` — the first impression every visitor gets; carries the elevator pitch and the install command.
- `LICENSE` — MIT chosen for maximum adoption (per Joshua's class-divergence rule MEMORY 2026-05-11; this is public-MIT, distinct from private-alpha).
- `CHARTER.md` — declares mission, values, and what flywheel is NOT, so contributors and users self-select.
- `CHANGELOG.md` — semver discipline is part of the trust pitch; users see we take versioning seriously.
- `CODE_OF_CONDUCT.md` — table-stakes for any serious open-source project in 2026.
- `CONTRIBUTING.md` — drops the activation energy for outside PRs; explains DCO/sign-off if we require it.
- `SECURITY.md` — without this, security researchers don't know where to send disclosures.
- `install.sh` at repo root — single canonical artifact; webpage proxies this exact file.
- `engine/` — everything the installer puts under `~/.flywheel/engine/` is in this subtree; one-to-one mapping makes the installer trivially auditable.
- `docs/` — Nextra-based docs site; published to `flywheel.zeststream.ai/docs` (separate from the SMB landing).
- `examples/` — every claim in the README has at least one runnable example; "show, don't tell."
- `scripts/` — for repo maintainers, not for users; never shipped into installed state.
- `tests/` — bats tests that run on every PR; gives potential adopters confidence that the project is actually tested.
- `.github/` — CI, issue templates, dependabot; signals "real project."
- `.git-blame-ignore-revs` — the initial extraction commit dumps thousands of files; without this, `git blame` always points to that one commit and never to actual authors.

---

## 4. Webpage architecture — `flywheel.zeststream.ai`

Audience: SMB clients (Joshua's clarification). Different from the docs audience. The webpage's job is to build trust in Joshua, ZestStream, and the work — not to teach developers how to run `flywheel doctor`.

### 4.1 Site structure

**Multi-page** (not single-page), because:
- SMB clients need to scan, not scroll
- SEO benefits from page-per-topic
- An "About" page that builds trust in Joshua needs to exist independently

Pages:

1. `/` — landing
2. `/what-is-flywheel` — the explainer for non-developers
3. `/for-developers` — bridge to the github repo + docs site
4. `/case-studies` — proof (initially: the flywheel itself, run on flywheel)
5. `/about` — who Joshua is, what ZestStream is, why this exists
6. `/contact` — how to engage Joshua (the conversion page)
7. `/install.sh` — Cloudflare-Worker-proxied or static; the install endpoint
8. `/install.sh.sha256` — companion hash
9. `/docs` — Nextra docs site mounted as a subpath (or subdomain `docs.flywheel.zeststream.ai`)

### 4.2 Content map

**`/` (landing)**

```
┌────────────────────────────────────────────────────────────┐
│ HEADER: ZestStream logo · flywheel · For developers · Docs │
│         · Contact                                          │
├────────────────────────────────────────────────────────────┤
│                                                            │
│   HERO                                                     │
│     Headline: "AI development that compounds."             │
│     Subhead:  one sentence that says: this is how we       │
│               build AI systems that get better with use,   │
│               not just more verbose.                       │
│     Primary CTA: "See how it works" → /what-is-flywheel    │
│     Secondary CTA: "Work with us" → /contact               │
│                                                            │
├────────────────────────────────────────────────────────────┤
│   THE THREE-SPACE FRAME                                    │
│     Plan (cheap) · Bead (5x) · Code (25x)                  │
│     One-line each. Trust signal: this is an opinionated    │
│     methodology with named tradeoffs.                      │
│                                                            │
├────────────────────────────────────────────────────────────┤
│   WHY THIS MATTERS FOR SMBs                                │
│     Three short blocks: "Compounds over time" / "Auditable │
│     by design" / "Built on durable artifacts not chats."   │
│                                                            │
├────────────────────────────────────────────────────────────┤
│   CASE STUDY TEASE                                         │
│     One headline metric (after Phase 2 collects one)       │
│     → /case-studies                                        │
│                                                            │
├────────────────────────────────────────────────────────────┤
│   ABOUT BLOCK                                              │
│     Photo + 80-word bio of Joshua. Trust through specifics │
│     (MBA, 12 years ZIRKEL, current clients only if their   │
│     per-surface consent is captured — see memory rule      │
│     2026-05-11 named-client-consent).                      │
│                                                            │
├────────────────────────────────────────────────────────────┤
│   FINAL CTA                                                │
│     "Have a problem worth flywheeling? Let's talk." →      │
│     /contact                                               │
├────────────────────────────────────────────────────────────┤
│ FOOTER: github · docs · contact · ZestStream.ai            │
└────────────────────────────────────────────────────────────┘
```

**`/what-is-flywheel`** — written for an SMB owner, not a dev. The 9-petal diagram, but the language is "intent → plan → tested plan → executed plan → learning." Three reasoning spaces with cost framing. Closes with "this is how we'd run a project for you."

**`/for-developers`** — short bridge page. The github repo URL, the install command, "if you've heard of PAI, NTM, beads_rust — flywheel composes ideas from all three." Link to docs.

**`/case-studies`** — at v0.2 launch this can ship with one case study: flywheel itself. The PAI gap analysis, the public-share-readiness arc, the cross-orchestrator coordination — show the meta-application. When client-named studies become possible (per the per-surface-consent rule), they go here.

**`/about`** — Joshua's story. MBA, 12 years ZIRKEL, Montana, left ElektraFi 2025-12-31 for full ZestStream focus. What ZestStream does (AI infra, consulting, agentic media, AaaS). Why flywheel exists.

**`/contact`** — a form (Cal.com embed or simple form to `chiefzester@gmail.com`), with three intake options: "AI assessment" / "Project consult" / "Other." Mirrors the AI Assessment ladder (memory rule 2026-05-11 north star).

### 4.3 Calls-to-action

The page has **two CTAs, never competing on the same fold**:

1. **Primary (commercial):** "Work with us" / "Book an AI Assessment" → `/contact`
2. **Secondary (technical):** "Read the docs" / "Install flywheel" → docs / github

SMB clients land on `/`, are pulled toward `/contact`. Developers land on `/for-developers` (e.g., from a Hacker News post linking there), and pulled toward github + docs.

### 4.4 Cross-references

- Repo's README links to the webpage as the "official home" but doesn't require it (the repo is self-contained for developers).
- Webpage's `/for-developers` links to github with a one-liner.
- Webpage hosts `/install.sh` and `/install.sh.sha256` (Cloudflare-Worker or Vercel static, serving the github release artifacts).
- Webpage's docs subpath (or subdomain) is the Nextra build from `docs/` in the public repo.

### 4.5 Tech stack recommendation

**Next.js 14 (app router)** on **Vercel**, because:
- Joshua's existing skill set + memory (`vercel`, `tanstack`, `react-best-practices` skills already canonical)
- ZestStream brand has existing Vercel infrastructure
- Image optimization out of the box
- Nextra (for `/docs`) lives natively inside Next.js

**Astro is the runner-up** if the team decides static-first matters more than dynamic content (no contact-form server logic in v0.2). Decision deferred to Phase 2; default to Next.js.

**Hosting:** Vercel (production) for the page; Cloudflare DNS for `flywheel.zeststream.ai`. `install.sh` served as a Vercel static asset OR a Cloudflare Worker that proxies github raw. Decide in Phase 2.

### 4.6 Information architecture summary

```
flywheel.zeststream.ai/
├── /                    (landing; SMB conversion focus)
├── /what-is-flywheel    (concept explainer; no jargon)
├── /for-developers      (bridge to github + docs)
├── /case-studies        (proof; v0.2 ships with one)
├── /about               (Joshua + ZestStream story)
├── /contact             (the conversion page; intake form)
├── /install.sh          (proxied install script)
├── /install.sh.sha256   (companion hash)
└── /docs/               (Nextra docs site; developer audience)
```

---

## 5. Preliminary bead DAG

15 beads. Priority and effort estimates assume one orchestrator + 2-3 worker panes. **These are placeholders** for Phase 4 DECOMPOSE.

| ID  | Title | Acceptance | Deps | Pri | Effort |
|-----|-------|------------|------|-----|--------|
| B1  | Author de-personalization-table.yaml | (a) all proper nouns & paths from source repo enumerated; (b) reviewed by Joshua; (c) checked into source repo at `.flywheel/extraction/` | — | P0 | M |
| B2  | Implement classification pass (Phase 1 of extract-engine.sh) | (a) emits classification.jsonl over source corpus; (b) summary report (N engine / N overlay / N manual-review); (c) tested on a 20-file fixture | B1 | P0 | M |
| B3  | Implement de-personalization pass (Phase 2 of extract-engine.sh) | (a) staged/ tree built; (b) per-file diffs emitted; (c) manual-review queue surfaced; (d) idempotent (running twice == once) | B1, B2 | P0 | L |
| B4  | Implement assembly pass (Phase 3 of extract-engine.sh) | (a) fresh public-repo tree assembled at output dir; (b) git history initialized with extraction-source-sha noted; (c) README/LICENSE/CHARTER scaffolds present | B3 | P0 | M |
| B5  | Author the engine CLI (`flywheel`, `flywheel doctor`) | (a) `flywheel --version` returns engine VERSION; (b) `flywheel doctor --post-install` runs all checks in §2.6; (c) 0/1 exit codes correct | B4 | P0 | L |
| B6  | Author the installer (install.sh) | (a) probes deps; (b) edits settings.json idempotently with backup; (c) writes install receipt; (d) atomic-at-visible-state; (e) `--dry-run` works | B5 | P0 | L |
| B7  | Author the uninstaller (uninstall.sh) | (a) reverses every file installer created; (b) verifies backup sha256 before restoring settings.json; (c) preserves user overlay unless `--purge`; (d) byte-equality reversibility test passes | B6 | P0 | M |
| B8  | Author the release pipeline (.github/workflows/release.yaml) | (a) tag-triggered; (b) emits install.sh.sha256, engine.tar.gz, SHA256SUMS; (c) drafts GitHub Release with these attached; (d) tested on v0.2.0-rc1 dry tag | B6 | P0 | M |
| B9  | Author the smoke-test CI workflow (installer-smoke.yaml) | (a) runs install→doctor→uninstall on a fresh macOS runner; (b) repeats on a ubuntu-22.04 runner; (c) asserts byte-equality post-uninstall | B6, B7 | P0 | M |
| B10 | Run extraction end-to-end + manual-review queue | (a) extract-engine.sh runs over real source repo; (b) every manual-review file resolved (substituted or kept); (c) output dir is git-clean | B3, B4 | P0 | L |
| B11 | Author public repo top-level files | (a) README.md, LICENSE (MIT), CHARTER.md, CONTRIBUTING.md, SECURITY.md, CODE_OF_CONDUCT.md, CHANGELOG.md all written; (b) each reviewed against Lane B's publishing standards | B10 | P0 | M |
| B12 | Author Nextra docs site under docs/ | (a) all pages in §3 tree exist with first-draft content; (b) site builds locally; (c) deploys to Vercel preview from a PR | B10, B11 | P1 | L |
| B13 | Build flywheel.zeststream.ai landing page | (a) all six SMB-facing pages in §4 exist with first-draft content; (b) deployed to Vercel; (c) DNS pointed; (d) contact form routes to chiefzester@gmail.com | B11 | P1 | L |
| B14 | Wire webpage→github cross-references | (a) install.sh + .sha256 served from flywheel.zeststream.ai; (b) docs subpath mounted; (c) repo README links to webpage as official home | B12, B13 | P1 | S |
| B15 | Publish v0.2.0 release + announcement | (a) tag v0.2.0; (b) release artifacts attached; (c) install via curl on a clean macOS works; (d) Joshua signs off "I'd direct a developer here" | B8, B9, B10, B11, B12, B13, B14 | P0 | M |

**Total:** 15 beads. Critical path B1→B2→B3→B4→B5→B6→B7→B10→B11→B15 is roughly L+M+L+M+L+L+M+L+M+M ≈ 9 medium-large units of work.

Likely Phase 4 expansions: B3 splits into per-substrate-class passes (doctrine / memory / scripts / hooks / skills), B5 splits into doctor + repair, B11 splits per top-level file, B12 splits per docs section, B13 splits per page.

---

## 6. Test plan

### 6.1 Smoke test — hello-doctor walkthrough

Located at `examples/hello-doctor/`. Five steps:

```bash
# 1. Install
curl -sSL https://flywheel.zeststream.ai/install.sh | bash

# 2. Verify doctor passes
flywheel doctor

# 3. Run repair (should be no-op on a fresh install)
flywheel doctor --repair --dry-run

# 4. Read the post-install receipt
cat ~/.flywheel/install-receipt-*.json | jq .

# 5. Uninstall
curl -sSL https://flywheel.zeststream.ai/uninstall.sh | bash
```

The expected output of each is checked into `examples/hello-doctor/expected-output.txt` (with timestamps and machine-specific paths placeholdered). A test script at `tests/smoke/hello-world-smoke.sh` runs this end-to-end on CI and asserts substring-match against the expected output.

### 6.2 Doctor self-test

`flywheel doctor --self-test` runs each check function with mock inputs and asserts the right exit code:

| Mock scenario | Expected check result |
|---|---|
| settings.json with flywheel hooks registered | hooks_registered = pass |
| settings.json without flywheel hooks | hooks_registered = fail |
| Hook script missing | hooks_present = fail |
| Hook script present but not executable | hooks_present = fail |
| Engine bin missing | engine_present = fail |
| Receipt file present + valid json | receipt_present = pass |
| Receipt file present + malformed | receipt_present = fail |

Run as part of CI on every PR.

### 6.3 Reversibility test (byte-equality)

```bash
# Capture pre-install state
PRE=$(find ~/.claude ~/.flywheel -type f 2>/dev/null | xargs shasum -a 256 | sort)

# Install
./install.sh

# Uninstall
./uninstall.sh

# Capture post-uninstall state
POST=$(find ~/.claude ~/.flywheel -type f 2>/dev/null | xargs shasum -a 256 | sort)

# Strictly equal (modulo allowed-noise: install-receipt-*.json is preserved by design,
# but uninstall removes it; assert against the explicit allowlist)
diff <(echo "$PRE") <(echo "$POST") || fail "byte-equality violated"
```

This runs in `tests/installer/test_uninstall_byte_equality.bats` and on every release candidate. **Reversibility receipt** at `~/.flywheel/install-receipt-<ts>.json` is the authoritative diff; the byte-equality test asserts the uninstaller honors that receipt.

### 6.4 Cross-platform considerations

**v0.2 target: macOS + Ubuntu 22.04 LTS.** This covers Joshua's environment + the most common Linux dev environment. Windows (via WSL2) is best-effort — we test on it in CI but don't block v0.2 on regressions there.

Platform-conditional logic in the installer:
- `sha256sum` on Linux vs `shasum -a 256` on macOS — wrap in a helper
- `realpath` on Linux vs `realpath` (homebrew coreutils, may be absent) on macOS — use `cd <dir> && pwd -P` instead
- `readlink -f` on Linux vs `readlink` on macOS — same workaround
- `~/.config/claude/` vs `~/.claude/` — Claude Code uses `~/.claude/` on both; no branching needed
- jq, python3, bash 4+ — all required and dependency-probed

Excluded for v0.2: native Windows, FreeBSD, NixOS, anything that ships bash 3.

### 6.5 CI workflow shape

`.github/workflows/ci.yaml`:

```yaml
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-22.04
    steps:
      - actions/checkout
      - shellcheck on every .sh
      - bats --tap tests/installer/*.bats (dry-run only)
      - jq-lint settings.json templates
      - eslint + tsc for docs/

  smoke-macos:
    runs-on: macos-14
    steps:
      - actions/checkout
      - sandbox install + doctor + uninstall under $HOME
      - assert install-receipt valid
      - assert byte-equality on uninstall

  smoke-ubuntu:
    runs-on: ubuntu-22.04
    steps:
      - (same as smoke-macos but ubuntu)

  docs-build:
    runs-on: ubuntu-22.04
    steps:
      - actions/checkout
      - cd docs && pnpm i && pnpm build
      - upload artifact
```

`.github/workflows/release.yaml`:

```yaml
on:
  push:
    tags: ['v*.*.*']
jobs:
  release:
    runs-on: ubuntu-22.04
    steps:
      - actions/checkout
      - build install.sh.sha256, engine.tar.gz, engine.tar.gz.sha256, SHA256SUMS
      - run smoke test against the built artifacts
      - create GitHub Release (draft); attach artifacts
      - notify maintainer
```

`.github/workflows/installer-smoke.yaml`:

```yaml
on:
  schedule: [cron: '0 9 * * *']   # nightly
jobs:
  smoke-fresh-mac:
    runs-on: macos-14
    steps:
      - curl -sSL .../install.sh | bash
      - flywheel doctor
      - curl -sSL .../uninstall.sh | bash
      - assert byte-equality
```

---

## 7. Open design questions for Phase 2 to resolve

These are decisions Phase 2 REFINE should converge on before Phase 4 DECOMPOSE produces the canonical bead DAG:

1. **Final repo name and org.** `github.com/JYeswak/flywheel` vs `github.com/zeststream/flywheel`. Org-level naming has implications for future ZestStream products that may also live there.

2. **CLI implementation language.** Bash for v0.2 is the cheap path; Rust (matching beads_rust / NTM) is the durable path. Choose now or commit-to-rewrite later.

3. **Docs site host path.** Subpath (`flywheel.zeststream.ai/docs`) vs subdomain (`docs.flywheel.zeststream.ai`). Affects SEO and Nextra deploy shape.

4. **Whether `~/.flywheel/engine/` is a git clone or a tarball extract.** Clone gives users `git pull` to update; tarball is simpler. Both work; pick one.

5. **Telemetry stance at v0.2.** Installer design says "no telemetry"; whether to add opt-in anonymous version-check (so we know who has stale installs) is a v0.3 question but the v0.2 README should say something.

6. **Signing approach beyond TLS.** PGP, minisign, cosign — any of these add real trust for security-conscious users at the cost of one more command in the install verification path. Defer to Phase 2.

7. **DCO / CLA for contributors.** Memory rule per Forrest Chang reference. DCO sign-off (lightweight) vs CLA (heavier process) — choose before opening the repo to outside PRs.

8. **The CHANGELOG format at v0.2 launch.** Keep-a-changelog spec vs conventional-commits-generated. Phase 2 chooses; B11 implements.

9. **What goes in `/case-studies` at v0.2 launch.** If only "flywheel itself" exists, is that enough trust signal, or do we wait for a client-named case study (gated by per-surface consent rule)?

10. **Whether the v0.2 release blocks on the webpage being live, or ships the github repo first and the webpage lands at v0.2.1.** Affects critical path and B15 acceptance.

11. **Pre-1.0 git history rewrite policy.** Public repos that allow `--force-with-lease` on `main` pre-1.0 are common; we should declare the policy explicitly so adopters know what to expect.

12. **Skill ownership boundary with `~/.claude/skills/`.** Some skills are clearly engine; some are clearly overlay; some currently live globally and would need to split. Where does the boundary cut, and does v0.2 ship any skills at all (vs deferring to v0.3)?

---

*Lane C output complete. Cross-references: Lane A's PAI gap analysis informs which engine artifacts close which gaps (B10 + B11 should consume that). Lane B's publishing standards inform B11's top-level file content. Phase 2 REFINE reconciles all three lanes.*
