# Pilot lessons — daily-report-enabled-repos.sh canonical-cli + doctor-mode upgrade

Date: 2026-05-10
Pilot bead: `flywheel-jloib` (sub-effort)
Commit: `dab051e`
Pilot script: `.flywheel/scripts/daily-report-enabled-repos.sh`
Test: `tests/daily-report-enabled-repos-canonical-cli.sh`

## Headline

**~70% of the work is template-able. ~30% is per-surface judgment that
requires solid effort.** With purpose-built tooling, per-surface effort
drops from ~3-4 hours (manual) to ~30-60 min (templated). 234 P0 surfaces
becomes ~120-235 dispatched-worker hours, tractable in batched waves.

## Effort breakdown (this pilot)

| Phase | Lines | Time | Tooling-able? |
|---|---|---|---|
| usage() text | ~70 | 5 min | Yes (template per subcommand list) |
| emit_info() | ~30 | 5 min | Yes (parametric template) |
| emit_schema() per surface | ~80 | 15 min | 90% Yes (only schemas differ) |
| emit_examples() | ~15 | 5 min | Data-only (just curated invocations) |
| emit_quickstart() | ~15 | 5 min | Data-only |
| emit_topic_help() | ~70 | 15 min | Mostly data; structure templated |
| emit_completion() bash+zsh | ~40 | 5 min | Yes (parametric template) |
| audit_append() helper | ~15 | 5 min | Pure template (drop-in) |
| iso_now/sha_self | 2 | 1 min | Pure template (drop-in) |
| main dispatch | ~50 | 10 min | Yes (subcommand list driven) |
| **boilerplate subtotal** | **~387** | **~70 min** | **~85% template** |
| cmd_run (existing) | ~90 | 0 (preserved) | n/a |
| cmd_doctor (substrate-specific checks) | ~60 | 25 min | No — pure judgment |
| cmd_health (signal-specific) | ~30 | 10 min | No — judgment |
| cmd_repair (scope-specific actions) | ~75 | 30 min | No — judgment |
| cmd_validate_config (schema-specific) | ~30 | 15 min | No — judgment |
| cmd_audit (log reader) | ~20 | 5 min | Yes (template; just file path differs) |
| cmd_why (provenance-specific) | ~40 | 15 min | No — judgment |
| **per-surface subtotal** | **~345** | **~100 min** | **~10% template** |
| Bug-hunt + fix | (n/a) | 30 min | Lintable (see below) |
| Test (22 assertions) | 141 | 30 min | 70% template |
| **TOTAL** | **+726 lines** | **~3.5 hours** | — |

## Bugs hit during pilot (now lintable)

Each of these wasted 5-15 minutes of debugging. All are mechanically detectable.

1. **Chained local under set -u**:
   ```bash
   local x="$1" y="$x/foo"   # FAILS: $x is unbound when y evaluates
   ```
   Fix: split into separate locals.
   Lint: `grep -E '^\s*local\s+\w+="\$\w+"\s+\w+="\$' <script>`

2. **Enumerator function returning last test's status**:
   ```bash
   list_enabled() { for x; do is_y "$x" && echo "$x"; done; }
   # Returns 1 if last is_y returned 1 → kills `cmd $(list_enabled)` under
   # set -e + pipefail, even though stdout was correct.
   ```
   Fix: explicit `return 0` at function end.
   Lint: AST check for any function whose last statement is a conditional.

3. **`${N:-{}}` brace ambiguity**:
   ```bash
   local x="${3:-{}}"   # parses as ${3:-{} + literal }, leaves trailing }
   ```
   Fix: `local x="${3:-}"; [[ -n "$x" ]] || x='{}'`.
   Lint: `grep -E '\$\{[0-9]:-\{\}\}' <script>`

4. **`[[ ]] && X || Y` inside `set -e` helper**:
   When the test fails AND `Y` returns non-zero, the helper returns non-zero,
   tripping set -e in the caller.
   Fix: proper `if/then/elif/fi`.
   Lint: AST check for `[[ ]] && X || Y` patterns inside functions defined
   under `set -e`.

## Tooling proposal — three tiers, increasing leverage

### Tier 1: drop-in helper library (~50% boilerplate savings)

**Build**: `.flywheel/lib/canonical-cli-helpers.sh` containing:

```bash
cli_audit_append <action> <status> [<extra_json>]
cli_iso_now
cli_sha_self
cli_emit_info_template <name> <version> <schema_v> <subcommands_csv> <env_csv>
cli_emit_completion_bash <name> <subcommands_csv>
cli_emit_completion_zsh <name> <subcommands_csv>
cli_emit_quickstart_template <steps_jsonl_file>
cli_refuse_apply_without_idem_key <scope>
cli_dispatch_subcommand_help <subcommand> <topic_help_callback>
```

Per-surface usage: source the lib at the top, call helpers from each
subcommand. Saves ~150 lines/script.

**Effort to build**: ~4 hours (one bead).
**Savings per surface**: ~150 lines, ~30 min.
**Total fleet savings**: 234 × 30 min = ~117 hours.

### Tier 2: scaffolder (~70% savings)

**Build**: `.flywheel/scripts/scaffold-canonical-cli.sh` that:

- Takes a script path
- Detects existing main + arg parsing
- Emits a unified diff that:
  - Wraps existing logic into a `cmd_run` function
  - Inserts canonical surface emitters (--info, --schema, --examples,
    quickstart, help, completion)
  - Inserts doctor/health/repair/validate stubs with `# TODO(operator):`
    markers naming the per-surface logic to fill in
  - Inserts a main dispatch with the canonical subcommand list
- Default `--dry-run`; `--apply --idempotency-key KEY` to write
- Generates a sibling `tests/<name>-canonical-cli.sh` test stub

Operator then fills in the TODO markers (~150 lines per surface, the
judgment work).

**Effort to build**: ~12 hours (one bead).
**Savings per surface**: ~250 lines + ~70 min, leaving ~150 lines/30min
of pure surface-specific judgment.
**Total fleet savings**: 234 × 70 min = ~273 hours.

### Tier 3: linter (~10% savings on bug debugging)

**Build**: `.flywheel/scripts/canonical-cli-lint.sh` checking:

- `local x; x="$(...)"` chained set-e gotchas
- Missing `return 0` in enumerator functions
- `${N:-{}}` brace ambiguity
- `[[ ]] && X || Y` patterns inside `set -e` helpers
- `--apply` paths that don't refuse without `--idempotency-key`
- Missing `set -euo pipefail`
- Missing `# flywheel-cli-surface: true` magic comment

Wire as pre-commit + into the canonical-cli regression test runner.

**Effort to build**: ~6 hours (one bead).
**Savings per surface**: ~10-30 min of debugging avoided.

## Recommended bead-2 decomposition

Replace single `flywheel-jloib` (234 surfaces) with sub-bead chain:

```
flywheel-jloib.0a  Build canonical-cli-helpers.sh lib                    [~4h]
flywheel-jloib.0b  Build scaffold-canonical-cli.sh                        [~12h]
flywheel-jloib.0c  Build canonical-cli-lint.sh + wire pre-commit          [~6h]
flywheel-jloib.0d  Refactor pilot (daily-report-enabled-repos.sh) to use
                   the new helper lib — proves the tooling against the
                   first real surface                                     [~2h]

# Then process P0 surfaces by lane, using the tooling:
flywheel-jloib.1   storage lane (7 surfaces)                              [~5h]
flywheel-jloib.2   beads lane (9 surfaces)                                [~6h]
flywheel-jloib.3   agent-mail lane (10 surfaces)                          [~7h]
flywheel-jloib.4   doctrine lane (8 surfaces)                             [~5h]
flywheel-jloib.5   testing lane (6 surfaces)                              [~3h]
flywheel-jloib.6   mission lane (5 surfaces)                              [~3h]
flywheel-jloib.7   recovery lane (37 surfaces)                            [~22h]
flywheel-jloib.8   dispatch lane (24 surfaces)                            [~15h]
flywheel-jloib.9   jeff-corpus lane (17 surfaces)                         [~10h]
flywheel-jloib.10  general lane wave 1 (~25 of 103, after re-classifying) [~15h]
flywheel-jloib.11  general lane wave 2 (~25 of 103)                       [~15h]
... etc
```

**Total estimated effort with tooling**: ~125-150 hours dispatched
worker time across 12-15 sub-beads.

**Same effort without tooling**: ~400-500 hours.

**Tooling investment ROI**: ~24 hours of build effort saves ~250-350
hours of per-surface effort. ~10-15× leverage.

## Lane priority recommendation

Process lanes by **mission-criticality × surface count**, not just
count alone:

1. **dispatch (24)** — load-bearing for fleet productivity. High signal.
2. **recovery (37)** — frozen panes are the #1 fleet failure mode.
3. **agent-mail (10)** — cross-orch coordination substrate.
4. **beads (9)** — bead state mutation is foundational.
5. **mission (5)** — anchor enforcement.
6. **storage (7)** — disk pressure incident class.
7. **doctrine (8)** — promotion + sync paths.
8. **jeff-corpus (17)** — daily-poll substrate.
9. **testing (6)** — meta layer.
10. **general (103)** — re-classify first; defer until tooling matures.

## Bead 3 (doctor-mode upgrade) implications

The pilot already implements ~80% of the world-class-doctor-mode rubric:
- Detect-then-fix invariant: ✅ (doctor → repair, never doctor that mutates)
- Single mutate() chokepoint: ✅ (only `cmd_repair --apply` mutates)
- Content-hashed backups: ⚠️ partial (audit log records sha256 of script,
  not file-level backups; would add for state mutations beyond mkdir)
- Byte-exact `doctor undo <run-id>`: ❌ not implemented (would require
  per-action inverse log; deferred to bead 3)
- Idempotence: ✅ (verified by test 07c)
- Crash recovery: ❌ not exercised (single-shot CLI; if killed mid-mkdir,
  no recovery needed because mkdir is atomic)
- Concurrency: ⚠️ not tested (audit log append is concurrent-safe;
  apply path has no inter-invocation race)
- Metamorphic: ❌ not implemented
- Fixture suite: ⚠️ partial (22 assertions; not yet 1-per-FM)
- Cross-FM: ❌ not implemented

Bead 3 (`flywheel-oxzyr`) on this pilot would add:
- doctor-undo log + revert subcommand
- fixture-suite expansion (~5 more FMs)
- WCDM scorecard.py run

**With tooling, bead 3 per-surface effort drops to ~1-2 hours
(WCDM verify-* helpers reused).**

---

## flywheel-jloib.0d measurements (2026-05-10)

Replaces the bead-2 estimates above with measured deltas from refactoring
the pilot script (`daily-report-enabled-repos.sh`) to source the helper
lib (`canonical-cli-helpers.sh` from jloib.0a).

| Metric | Value |
|---|---|
| Pilot before refactor | 817 lines |
| Pilot after refactor | 706 lines |
| Helper lib (jloib.0a) | 382 lines |
| Topic-map JSON sidecar | 9 lines |
| **Net delta per script** | **111 lines saved** |
| % saved | 13.6% |
| Projected savings × 234 P0 surfaces | 25,974 lines |
| Regression test | 22/22 PASS, zero test modifications |
| canonical-cli-lint.sh | 0 violations |

### Verdict

Net delta = **111 lines/script**, in the 100-149 band. The spec's two
thresholds disagree on this band:

- **Absolute lines bar (>=150 → validated):** missed.
- **Percentage bar (>=30% → validated):** missed (13.6%).

Both thresholds say "lib needs further work before bead 2.x lane work."
A lib-revision followup bead has been filed naming three concrete
extraction targets that would push savings past 150/script:

1. **`cli_emit_schema_dispatch <surface_map>`** — replace the 80-line
   `case "$surface" in default|run) ;; doctor) ;; ...` schema dispatcher
   with a JSON-driven helper. Expected savings: ~60-80 lines/script.
2. **`cli_dispatch_help <topic_help_fn>`** — extend the existing
   `cli_dispatch_subcommand_help` to also intercept `<cmd> --help`
   requests, removing the per-cmd `--help` boilerplate. Expected
   savings: ~10-20 lines/script.
3. **`cli_emit_audit_tail <audit_log> <limit>`** — extract the
   `tail -n N | jq -s ...` pattern from the per-surface `audit`
   subcommand. Expected savings: ~15-25 lines/script.

Combined target: 196-236 lines/script saved (24-29% of pilot baseline),
which clears both thresholds.

### What worked (kept in jloib.0a)

- Time + identity: `cli_iso_now`, `cli_sha_self` — clean drop-in.
- Audit primitive: `cli_audit_append` — handles dirname creation,
  bad-JSON fallback, sha256 attribution. Replaces ~12 lines with one
  call.
- Refusal envelope: `cli_refuse_apply_without_idem_key` — exits 3 with
  canonical envelope; replaces 5-line block with 1-line call.
- Info / examples / quickstart envelope generators: substantial
  savings on emit blocks (~16 / ~5 / ~10 lines respectively).
- Completion generators: bash + zsh in one helper each; replaces ~45
  lines with 2 case branches calling helpers.
- Topic-map JSON sidecar: replaces 62-line `case` statement with 1-line
  `cli_emit_topic_help` call + 9-line JSON file.

### What didn't work / wasn't extracted

- Schema dispatcher (`emit_schema`) — per-surface schemas are too
  caller-specific to move into the lib without hurting clarity.
  Punted to followup-bead Recommendation #1 (a JSON-driven dispatcher
  helper would resolve this).
- Per-surface `usage()` — every script has its own help body;
  shouldn't be in the lib.
- Subcommand --help dispatch (`cli_dispatch_subcommand_help`) — the
  helper exists in jloib.0a but isn't widely consumed in this pilot
  because the script's help routing happens at top-level case rather
  than per-subcommand. Followup-bead Recommendation #2 closes this
  gap.

### Pilot lessons → bead 2.x lane work

- Sourcing the lib via symlinked invocation (the canonical-cli-scoping
  checker installs symlinks in `$TMP/bin/`) requires a `readlink`
  resolver in the caller before computing `ROOT`. Documented in the
  pilot script and should be part of the helper-lib sourcing
  boilerplate going forward.
- The 22/22 regression test passing UNCHANGED is the hard gate; any
  helper that breaks behavioral equivalence under the regression test
  is rejected.
- The lib's `canonical-cli-helpers/v1` schema version is correct —
  callers continue to emit their own `<surface>.<command>/v1` and the
  lib never overrides.

Source bead: `flywheel-3wxzi`. Apply spec:
`.flywheel/audit/flywheel-jloib.0d/apply-spec.md`. Pilot reference:
`dab051e`.
