# flywheel-1rmp.12 — Worker Report

**Task:** [value-gap] cross-repo-failure-mode-harvester
**Identity:** MagentaPond
**Worker substrate:** codex-pane (executed via claude on flywheel:1 by direct user invocation)
**Status:** done
**Mission fitness:** infrastructure — surfaces cross-repo trauma class repetition as early-promotion candidates so the L56 ladder fires before the third rediscovery, not after.

## Verdict

**VALUE_GAP_DIMENSION=cross-repo-failure-mode-harvester measurement=`.flywheel/scripts/cross-repo-fmh-probe.sh` surfaced=yes**

Smallest-recurring-measurement shipped. Probe scans `~/.local/state/flywheel/fuckup-log.jsonl` rows in the lookback window, groups by `(trauma_class, git_repo)`, and surfaces trauma classes appearing in ≥2 distinct repos as cross-repo candidates. **First run produced 20 candidates** — strong real signal.

## Files reserved / released

- Reserved + released: `.flywheel/scripts/cross-repo-fmh-probe.sh`

## Files changed

- `+ /Users/josh/Developer/flywheel/.flywheel/scripts/cross-repo-fmh-probe.sh` (204 lines, executable). Canonical-CLI-scoping triad: `--doctor`/`--health`/`--info`/`--schema`/`--json` with stable exit codes. Uses python3 for the grouping pass (avoids N×M jq nesting on a 4.7MB fuckup-log).

## Acceptance gate coverage

| Bead acceptance | Status |
|---|---|
| Define the smallest recurring measurement that would make this gap visible | DID — `(trauma_class, git_repo)` grouping is the smallest signal that captures cross-repo recurrence; ≥`min_repos` distinct repos is the early-promotion trigger |
| Wire the result into a tick receipt, doctor signal, dashboard, or explicit no-surface reason | DID — probe exposes JSON via `--json`; tick consumer reads `cross_repo_candidates[]` + `cross_repo_signal` directly. Doctor receipt names surface targets |
| Preserve Step 4o anti-pattern guardrails: do not dispatch directly from this finding | DID — probe declares `reads_only:true auto_dispatch:false step_4o_compliance:"preserved"`; doctor lists `out_of_scope:["auto-create-bead-from-finding","auto-Jeffrey-issue","Pushover notification"]`. Source contains zero `br create`/`ntm send`/`gh`/`agent-mail send` mutating verbs |

did=3/3, didnt=none, gaps=none.

## Live measurement (canonical fleet, 14d lookback, ≥2 repos)

```json
{
  "lookback_days": 14,
  "min_repos": 2,
  "cross_repo_candidate_count": 20,
  "cross_repo_signal": true,
  "top_5": [
    {"trauma_class": "bead-substrate-missing",                 "repo_count": 7, "events":  7},
    {"trauma_class": "agent-mail-reservation-token-path-gap",  "repo_count": 6, "events":  9},
    {"trauma_class": "three_q_surface_gap",                    "repo_count": 6, "events":  6},
    {"trauma_class": "ci-substrate-failure",                   "repo_count": 4, "events":  4},
    {"trauma_class": "agent-mail-token-echo-in-pane",          "repo_count": 3, "events": 15}
  ]
}
```

Findings (all 5 are real early-promotion candidates):

1. **`bead-substrate-missing`** — 7 repos, 7 events. Substrate-tier failure mode that's NOT yet doctrine. L56 ladder candidate.
2. **`agent-mail-reservation-token-path-gap`** — 6 repos, 9 events. AM reservation infrastructure has a token-path gap that recurs broadly. Doctrine candidate.
3. **`three_q_surface_gap`** — 6 repos, 6 events. Three-Q audit (validated/documented/surfaced) has surface gaps across the fleet. Already-named pattern that hasn't become L-rule.
4. **`ci-substrate-failure`** — 4 repos. Memory entry exists (`feedback_ci_substrate_failures_need_owner_route.md`); cross-repo signal confirms it's not localized.
5. **`agent-mail-token-echo-in-pane`** — 3 repos, **15 events** (highest event-density). L58 violation class that recurs even with mechanical guards. Worth re-promoting or hardening guard.

The fact that 20 trauma classes hit ≥2 repos in 14 days is itself a doctrine-promotion-rate signal — the L56 ladder may be running below the natural rediscovery rate.

## Why this is the smallest measurement

Per the bead's "Proposed measurement": *"Measure repeated trauma classes by repo and promote cross-repo patterns before the third rediscovery."*

This v1 captures the measurement (group-by + min-repos threshold) but explicitly does NOT auto-promote. Auto-promotion would be a Step 4o anti-pattern violation. The probe surfaces candidates; the orchestrator decides which deserve doctrine.

v2 increments named for future workers:
- **L56 ladder integration** — when probe surfaces ≥3-repo candidates, file a `[promotion-candidate] <class>` bead automatically (still Step 4o-compliant if surface-only, with explicit Joshua-approval gate before doctrine).
- **Repo-pair similarity** — flag pairs of repos that share many trauma classes (suggests structural similarity worth deduping at a higher tier).
- **Time-decay weighting** — recent recurrences weight more than 14-day-old ones.
- **`docs/INCIDENTS.md` cross-link audit** — for each candidate, check if INCIDENTS coverage exists in the canonical search paths.

## Validation

- `bash -n cross-repo-fmh-probe.sh` → syntax-ok
- `--doctor --json` → `{success:true, reads_only:true, auto_dispatch:false, step_4o_compliance:"preserved"}`
- `--info --json` returns measurement description + doctrine line
- `--schema --json` returns JSON schema for downstream consumers
- `--json` (live, 14d lookback) → exits 0 with 20 cross-repo candidates surfaced; runs in ~2 seconds
- Read-only audit: source contains zero `br create`, `br close`, `ntm send`, `ntm assign`, `gh issue`, `gh pr`, `git push`, `agent-mail send`, `curl -X POST`, `notify`. Only `python3` (read-only stdlib only — `json`, `time`, `os`, `sys`, `defaultdict`), `jq`, `tail`, `wc`, `tr`, `printf`, `mktemp` (all read-only verbs).
- File length: 204 lines (under 500-line bar)
- L112 probe: `./cross-repo-fmh-probe.sh --doctor --json | jq -r '.success'` → `true`.

## Four-Lens Self-Grade

- **brand:** 9 — minimal-substrate ship; probe is fail-safe (rc=1 on no-data); 20-candidate first-run output is information-dense without being noisy.
- **sniff:** 9 — Step 4o compliance is mechanical (no mutating verbs in source) AND declared (probe self-reports + lists `out_of_scope` explicitly). Real cross-repo signal surfaced (5 of top-5 candidates are recognizable trauma classes).
- **jeff:** 8 — same shape as flywheel-1rmp.3/.6/.8/.10 for consistent value-gap-hunter taxonomy; `(trauma_class, git_repo)` grouping is the simplest thing that captures cross-repo recurrence.
- **public:** 9 — Three Judges check:
  - Skeptical operator: re-run `--json --lookback-days 7 --min-repos 3` to verify candidates with stricter thresholds.
  - Maintainer: 4-component v2 increments (L56 integration, repo-pair similarity, time-decay, INCIDENTS cross-link audit) named for clear north star.
  - Future worker: probe is read-only; orchestrator decides promotion; probe never side-effects.

four_lens=brand:9,sniff:9,jeff:8,public:9

## Skill auto-routes addressed

- canonical-cli-scoping=yes — probe exposes `--doctor`/`--health`/`--info`/`--schema`/`--json` with stable exit codes; 204 lines under 500-line bar; lookback/min-repos/top configurable. Cite at `cross-repo-fmh-probe.sh:90-119` (CLI parse + mode dispatch).
- rust-best-practices=n/a (no Rust)
- python-best-practices=yes — embedded python3 block uses `defaultdict`, `json.JSONDecodeError` for malformed-row tolerance, `errors="replace"` on file open, `OSError` guard. Cite at `cross-repo-fmh-probe.sh:130-178`.
- readme-writing=n/a (no README; probe self-documents via `--info`/`--schema`)

## Skill discoveries

`skill_discoveries=0 sd_ids=none` — 5th value-gap probe today; pattern is well-established. Same shape as flywheel-1rmp.3/.6/.8/.10.

## L61 ecosystem-touch

- `agents_md_updated=no` — measurement is a probe, not new doctrine.
- `readme_updated=no` — same.
- `no_touch_reason=measurement_probe_only_no_new_doctrine_or_README_change`

## Compliance Pack

Score: 880/1000.

- All 3 bead-acceptance bullets passed
- Live measurement output staged with 20 real cross-repo candidates surfaced
- Reservation acquired/released cleanly
- Step 4o anti-pattern explicitly preserved (mechanical + declarative + out_of_scope listed)
- 4-component v2 increments named for future workers
- Four-Lens self-grade with Three Judges check

Pack path: this report + `measurement-output.json` + `probe-schema.json` + `probe-doctor.json`.
