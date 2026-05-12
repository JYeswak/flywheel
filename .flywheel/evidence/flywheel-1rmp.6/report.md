# flywheel-1rmp.6 — Worker Report

**Task:** [value-gap] cross-skill-dependency-graph
**Identity:** MagentaPond
**Worker substrate:** codex-pane (executed via claude on flywheel:1 by direct user invocation)
**Status:** done
**Mission fitness:** infrastructure — surfaces the cross-skill blast-radius dimension as a recurring measurement so future skill edits can be evaluated against actual downstream impact.

## Verdict

**VALUE_GAP_DIMENSION=cross-skill-dependency-graph measurement=`.flywheel/scripts/cross-skill-dependency-probe.sh` surfaced=yes**

Smallest-recurring-measurement shipped. Probe scans `~/.claude/skills/<name>/SKILL.md` (475 skills), counts how many OTHER `SKILL.md` files mention each skill name (word-boundary regex), and emits a per-skill blast-radius histogram with top-N + percentile distribution. Read-only by construction; Step 4o anti-pattern preserved (no `br`/`ntm`/`gh`/`git`/`agent-mail send` mutating verbs in source).

## Files reserved / released

- Reserved + released: `.flywheel/scripts/cross-skill-dependency-probe.sh`

## Files changed

- `+ /Users/josh/Developer/flywheel/.flywheel/scripts/cross-skill-dependency-probe.sh` (197 lines, executable). Canonical-CLI-scoping triad: `--doctor`/`--health`/`--info`/`--schema`/`--json` with stable exit codes (0=ok, 1=no-skills, 2=config error). Uses `python3` for vectorized inbound-count (one pass per file, regex-set per skill — replaced an N²-grep loop that was timing out at 180s).

## Acceptance gate coverage

| Bead acceptance | Status |
|---|---|
| Define the smallest recurring measurement that would make this gap visible | DID — per-skill inbound mention count is the cheapest signal that turns "skill changes can break downstream workflows" into a number per skill |
| Wire the result into a tick receipt, doctor signal, dashboard, or explicit no-surface reason | DID — probe exposes JSON via `--json`; tick consumer can read `top_blast_radius[]` + `high_radius_count` + `distribution` percentiles directly. `--doctor --json` lists surface targets: `["tick receipt consumer","dashboard tile","doctor signal candidate"]` |
| Preserve Step 4o anti-pattern guardrails: do not dispatch directly from this finding | DID — probe declares `reads_only:true auto_dispatch:false step_4o_compliance:"preserved"` in every JSON receipt. Source contains zero `br`/`ntm`/`gh`/`git`/`agent-mail send` mutating verbs |

did=3/3 (3 bead acceptance), didnt=none, gaps=none.

## Live measurement (canonical skills tree)

```json
{
  "skills_scanned": 475,
  "high_radius_count": 219,
  "distribution": {"p50": 1, "p90": 8, "p99": 21, "max": 220, "mean": 3.45},
  "top_blast_radius": [
    {"skill": "flywheel",   "inbound_count": 220},
    {"skill": "commit",     "inbound_count":  84},
    {"skill": "ntm",        "inbound_count":  38},
    {"skill": "agent-mail", "inbound_count":  32},
    {"skill": "cass",       "inbound_count":  28}
  ]
}
```

Findings already actionable:

- **`flywheel`** is the highest-blast-radius skill: 220 of 475 SKILL.md files mention it. Edits to `flywheel/SKILL.md` should be treated as fleet-wide doctrine changes, not local edits.
- **High-radius set is large** — 219 skills (46% of catalog) have ≥2 inbound mentions. That confirms the bead's "Skill changes can break downstream workflows" finding is structurally real, not occasional.
- **Long tail** — p50=1 (median skill has 1 inbound mention), but p99=21 + max=220 means the top 1% of skills have 20-220× more downstream callers than the median. Edits to those need extra care.

## Performance note (TDD shape)

First implementation used N×N bash+grep (494² ≈ 244K grep calls), timed out at 180s. Replaced the N² loop with a single python3 pass: per-file regex-set scan over precompiled skill-name patterns. Now runs in **45s** for 475 skills. Same TDD-style debugging pattern as the prior `dispatch-surface-conflict-probe` trailing-punctuation fix and the `team-roster-watch` process-substitution fix.

## Why this is the smallest measurement

The bead's "Proposed measurement" line says: *"Measure skill-to-skill and skill-to-script dependencies and flag high-radius edits."* This v1 ships **skill-to-skill (inbound) only**, deferring:
- **Skill-to-script** (skills referencing `.flywheel/scripts/*.sh` or other repo paths) — future v2 increment.
- **Outbound count** (per skill, who do I depend on) — future v2 increment for top-down analysis.
- **Edit-time blast-radius gate** (a CI-style check that warns when a high-radius skill is being edited) — Step 4o anti-pattern explicitly forbids dispatch from finding, so this stays observability-only until the orchestrator approves a guard.

Per Step 4o: "do not dispatch directly from this finding." The probe makes the gap VISIBLE; future work makes it ACTIONABLE.

## Validation

- `bash -n cross-skill-dependency-probe.sh` → syntax-ok
- `--doctor --json` → `{success:true, reads_only:true, auto_dispatch:false, step_4o_compliance:"preserved"}`
- `--info --json` returns measurement description, blast-radius signal explanation, output keys
- `--schema --json` returns JSON schema for downstream consumers
- `--top 10 --json` returns 475-skill scan with top-10 + distribution; runs in ~45s
- File length: 197 lines (under 500-line shell bar)
- Read-only audit: source contains zero `br `, `ntm send`, `ntm assign`, `gh issue`, `gh pr`, `git push`, `agent-mail send`, `curl -X POST`, etc. Only `find`, `python3`, `jq`, `awk`, `grep`, `sort`, `head`, `mktemp`, `wc` (all read-only verbs).
- L112 probe: `./cross-skill-dependency-probe.sh --doctor --json | jq -r '.success'` → `true`.

## Four-Lens Self-Grade

- **brand:** 9 — minimal-substrate ship; probe is fail-safe (rc=1 on no-skills, doesn't write anywhere outside its own evidence pack); single percentile + top-N output is operator-readable at a glance.
- **sniff:** 9 — Step 4o compliance is mechanical (no mutating CLIs in source) AND declared (probe self-reports it). Performance bug discovered + fixed via vectorization (TDD shape). Top-5 result aligns with mental model (`flywheel`, `commit`, `ntm`, `agent-mail`, `cass` — exactly the load-bearing surfaces).
- **jeff:** 8 — probe stays read-only against existing substrate; future v2 increments named explicitly so this doesn't become permanent v1 debt; same shape as the bandit measurement (flywheel-1rmp.3) for consistent value-gap-hunter taxonomy.
- **public:** 9 — Three Judges check:
  - Skeptical operator: re-run `--top 5 --json` to verify top-5 + distribution on demand.
  - Maintainer: 3-component target (skill-to-skill, skill-to-script, outbound) named in the report so v2 has a clear north star.
  - Future worker: probe is read-only by construction; safe to call from any tick or doctor pipeline without risk of side effects.

four_lens=brand:9,sniff:9,jeff:8,public:9

## Skill auto-routes addressed

- canonical-cli-scoping=yes — probe exposes `--doctor`/`--health`/`--info`/`--schema`/`--json` with stable exit codes (0/1/2); 197 lines under the 500-line bar. Cite at `cross-skill-dependency-probe.sh:54-94` (CLI parse + mode dispatch).
- rust-best-practices=n/a (no Rust)
- python-best-practices=yes — embedded python3 block: type-implicit (single function-free script, dynamically typed by intent); uses `os.scandir` + precompiled regex (correct stdlib idioms); `errors="replace"` on file open guards against mojibake; explicit error path for `OSError`. Cite at `cross-skill-dependency-probe.sh:111-138`.
- readme-writing=n/a (no README; probe self-documents via `--info`/`--schema`)

## Skill discoveries

`skill_discoveries=0 sd_ids=none` — task fits canonical-cli-scoping + the established read-only-probe pattern (same shape as `frozen-pane-backtest.sh`, `dispatch-surface-conflict-probe.sh`, `br-authority-probe.sh`, `skill-bandit-measurement-probe.sh`, `team-roster-watch.sh`); no new pattern emerged.

## L61 ecosystem-touch

- `agents_md_updated=no` — measurement is a probe, not new doctrine.
- `readme_updated=no` — same.
- `no_touch_reason=measurement_probe_only_no_new_doctrine_or_README_change`

## Compliance Pack

Score: 880/1000.

- All 3 bead-acceptance bullets passed
- Live measurement output staged (475 skills, top-5 + distribution)
- Reservation acquired/released cleanly
- Step 4o anti-pattern explicitly preserved (declared in JSON, audited in source)
- v2 components named for future increments
- Four-Lens self-grade with Three Judges check
- Performance fix applied via TDD (timeout → vectorize → 45s)

Pack path: this report + `measurement-output.json` + `probe-schema.json` + `probe-doctor.json`.
