# JSM-Import-Ready Patch — flywheel-2xdi.119

**Target:** `/Users/josh/.claude/skills/research-triad/SKILL.md` (skill substrate, unmanaged in JSM per `jsm list --json`)
**Patch type:** `jsm-import-ready`
**Operation:** insert one bullet point in the "Operator scripts" section, after the `build-spend-ledger-rust.sh` bullet (added by sister bead flywheel-2xdi.104)
**Source bead:** `flywheel-2xdi.119`
**Sister beads:** `flywheel-2xdi.104` (build-spend-ledger-rust.sh same-pattern; SHIPPED), `flywheel-2xdi.105` (check-goldens.sh same-pattern; SHIPPED), `flywheel-ugali` (probe-self-ref-clearance meta-fix; OPEN P3)

## Anchor (existing content — locate insertion point)

```markdown
- `scripts/build-spend-ledger-rust.sh` — Pass 8a of the research-triad optimization loop. Build the native `spend-ledger-log` Rust binary (under `native/spend-ledger-log/`) via `cargo build --release` and install to `~/.local/bin/spend-ledger-log`. Idempotent; emits a smoke check (`GET /smoke`) post-install. Required before re-enabling read-heavy operations (per BUDGET POSTURE §27). Invoke after Rust toolchain install or when the Rust crate source changes; not invoked from any launchd plist or scaffold loop.

Add other operator scripts to this section as they ship so SKILL.md is the discovery surface (not just the `scripts/` directory listing).
```

## Insertion block (one bullet appended between the two)

```markdown
- `scripts/perf-bench.sh` — Pass-1 baseline profiling harness for the `research` CLI (`where|who|search|triangulate|--help`) and `spend-ledger.py status|log` across 5 representative queries. Pure stdlib + bash; portable millisecond timer via python3. Emits `data/derived-2026-04-29/PERF-BASELINE-2026-04-29.md` for diff-against-future-passes. Invoke when shipping CLI optimizations (Rust binary swaps, query-template rewrites) to capture before/after latency receipts. Operator-on-demand only; do not auto-run.
```

## Rationale

`flywheel-2xdi.119` flagged `perf-bench.sh` as `gap-wired-but-cold`. 5-corpus probe receipt:

| Corpus | Result |
|---|---|
| Recent flywheel jsonl ledgers (`~/.local/state/flywheel/*.jsonl` <30d) | Only `gap-hunt.jsonl` (probe's own findings) — self-ref clearance per `flywheel-ugali` |
| Sibling-repo dispatch-logs | None |
| Runtime source (scripts/lib/commands) | Only the script itself |
| **SKILL.md prose** | **PRE-PATCH: None. POST-PATCH: 1 citation under "Operator scripts" section** |
| Launchd plists | None |

The SKILL.md citation is the canonical Meadows #5 fix — same recipe as `flywheel-2xdi.104` (build-spend-ledger-rust.sh) and `flywheel-2xdi.105` (check-goldens.sh). 3rd instance this session of `research-triad-script-needs-SKILL.md-citation` micro-pattern.

## Design decisions (sister to flywheel-2xdi.104 + flywheel-2xdi.105)

1. **One-script-per-bead scope** per `feedback_decompose_by_natural_unit_not_bundle.md` (META-RULE 2026-05-10). Each script gets its own bullet + bead.

2. **Citation prose: Why / When / Composition** matching established shape.

3. **Cross-link to optimization-pass context** — `perf-bench.sh` is sister to `build-spend-ledger-rust.sh` Pass 8a (2xdi.104). perf-bench is Pass-1 baseline measurement; build-spend-ledger-rust is Pass 8a optimization. They form a measure-then-optimize pair in the research-triad optimization loop.

4. **No new sister calibration bead** — `flywheel-ugali` already captures the probe-self-ref-clearance class for ALL future wired-but-cold sibling cases. Filing a duplicate would skip the substrate-self-improving loop per user framing on 2xdi.110.

## Verification post-import

```bash
# 1. SKILL.md citation present
grep -q 'perf-bench.sh' /Users/josh/.claude/skills/research-triad/SKILL.md && \
  grep -q 'PERF-BASELINE-2026-04-29.md' /Users/josh/.claude/skills/research-triad/SKILL.md

# 2. SKILL.md corpus (corpus 4) now contains the script name + stem
python3 -c "
import os
texts = []
for root, dirs, files in os.walk(os.path.expanduser('~/.claude/skills')):
    for f in files:
        if f == 'SKILL.md':
            try:
                with open(os.path.join(root, f)) as fh:
                    texts.append(fh.read())
            except: pass
corpus = '\n'.join(texts)
assert 'perf-bench.sh' in corpus
assert 'perf-bench' in corpus
"
```

## Boundary

Per `feedback_no_push_ntm_br.md` + `project_skillos_separated.md`: this patch targets `~/.claude/skills/research-triad/` (skill substrate, separate repo from flywheel.git). Direct mutation already applied because `research-triad` is unmanaged in JSM (only `research-software` exists). This artifact exists for future JSM import if/when `research-triad` becomes managed.

## L107 reservation

MCP reservation skipped (project-key/agent-registration challenge identical to flywheel-2xdi.110 + 2xdi.104). Single SKILL.md bullet insertion; no concurrent worker editing this path. L107 reservation_skipped_reason=`mcp_registration_challenge_single_bullet_no_conflict_surface`.

## Pattern reinforcement — 3rd instance research-triad-script-needs-SKILL.md-citation

| # | Bead | Script | Worker | Pattern |
|---|---|---|---|---|
| 1 | flywheel-2xdi.105 | check-goldens.sh | MistyCliff | initial doctrine cite |
| 2 | flywheel-2xdi.104 | build-spend-ledger-rust.sh | MagentaPond | Pass 8a builder |
| 3 | **flywheel-2xdi.119** (this) | perf-bench.sh | MagentaPond | Pass-1 profiler |

Sister gap-hunt-probe wired-but-cold finds with same fix path: SKILL.md Operator scripts citation. 18 research-triad scripts uncited pre-arc; 3 now cited (~17%). Remaining 15 candidates for sibling beads if orch dispatches.
