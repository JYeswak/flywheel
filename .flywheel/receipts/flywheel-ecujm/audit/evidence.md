# flywheel-ecujm — frozen-pane-detector-fleet --schema/--examples flag-alias landing

## Bead

- ID: `flywheel-ecujm`
- Title: `[agent-ergo-cli-max] frozen-pane-detector-fleet: land --schema and --examples`
- Priority: P2
- Source audit: `flywheel-62mf9` recommendation `frozen-pane-detector-fleet-R001`
- Score target band: 760 → 880

## Audit recommendation (verbatim, sha 960edca)

> Add --schema and --examples endpoints. --help and --info already present. File at 492 lines (just under shell threshold).

Note: audit was partially stale — `--examples` already worked as a flag (line 461 mapped it to MODE=examples). The actual gap was `--schema`.

## Change shape

Pattern: `flag-alias-for-existing-subcommand` (same recipe as `peer-orch-respawn-permit` (commit fb9985e) and `sync-canonical-doctrine` (commit d304eae)).

The script already had `schema` and `examples` as positional subcommands plus a `schema` MODE dispatch case. The fix adds `--schema` to the argument-parsing case-table so flag form routes to the same handler. `--examples` flag was already wired pre-fix.

Working-tree diff (relevant hunk):

```diff
+    # flywheel-ecujm: --schema flag delegates to schema_json (the `schema`
+    # subcommand) so the introspection triad+1 (--help/--info/--schema/
+    # --examples) is uniformly accessible as flags per
+    # agent-ergonomics-cli-max R001.
+    --schema) MODE="schema"; shift ;;
```

Other working-tree changes in the same file (substrate-wide JSONL primitive integration) are pre-existing and orthogonal to this bead but commit-bundled because they touched the same file via a peer wave; they preserve `event_append` semantics through the validated JSONL append helper.

## Verification

```
bash -n .flywheel/scripts/frozen-pane-detector-fleet.sh                # OK
bash -n .flywheel/tests/test-frozen-pane-detector-fleet-introspection.sh  # OK
bash .flywheel/tests/test-frozen-pane-detector-fleet-introspection.sh
  pass=7 fail=0
.flywheel/scripts/frozen-pane-detector-fleet.sh --schema     # emits schema_version
.flywheel/scripts/frozen-pane-detector-fleet.sh --examples   # emits 5 invocations
.flywheel/scripts/frozen-pane-detector-fleet.sh --doctor --json  # rc=0 (no regression)
```

See `test-output.txt` for the full regression run.

## Scope discipline (PICOZ_WORKER_FILES)

Files touched (all in dispatch-named scope):

- `.flywheel/scripts/frozen-pane-detector-fleet.sh` (pre-existing working-tree change; bead-named target)
- `.flywheel/tests/test-frozen-pane-detector-fleet-introspection.sh` (new regression test; required by bead acceptance)
- `.flywheel/receipts/flywheel-ecujm/audit/*` (compliance pack; required by QUALITY BAR)

No fleet propagation. No doctrine surface mutated.

## Skill auto-routes

| Route | Status | Note |
|---|---|---|
| canonical-cli-scoping | yes | Triad+1 (--help/--info/--schema/--examples) all flag-accessible; doctor/health/repair triad already present; validate/audit/why already present; --json + schema + stable exit codes preserved; --dry-run/--apply discipline preserved on cycle/install/uninstall; file under 500-line threshold (497) |
| rust-best-practices | n/a | Bash file, no Rust touched |
| python-best-practices | n/a | Bash file; embedded plistlib heredoc unchanged |
| readme-writing | n/a | No README/docs touched |

## Four-Lens Self-Grade

- **brand: 9** — Joshua-style flag-alias-for-existing-subcommand recipe; matches peer commits fb9985e/d304eae byte-shape.
- **sniff: 9** — 4-line case-branch + 1-line addition; no surprise mutations; doctor/cycle/install paths unchanged; +5 lines net (still under threshold).
- **jeff: 9** — single-source-of-truth (`MODE` dispatch table is canonical; flag and subcommand both route through it); no upstream surface change.
- **public: 9** — Three Judges: skeptical operator (rc=0 + JSON envelope), maintainer (test asserts byte-equivalence flag↔subcmd), future worker (4-line citation comment).

`four_lens=brand:9,sniff:9,jeff:9,public:9`

## Mission fitness

Class: `infrastructure` (canonical-CLI surface parity for a fleet-liveness watchdog used by orchestrator-uptime mission anchor).

Bead body claim was `adjacent`; reclassified per actual artifact: this tool is invoked by the orchestrator-uptime watchdog plist itself, so improving its introspection surface is direct infrastructure for the mission anchor.

`mission_fitness=infrastructure`
