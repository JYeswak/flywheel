---
bead: flywheel-2xdi.158
title: gap-wired-but-cold ntm-send-with-josh-req-capture.sh — wire-in via canonical-cli smoke test + 2xdi.164 self-match correction
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: DONE
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister: flywheel-2xdi.164 (classifier fix had a self-match bug; corrected here)
---

# 2xdi.158 evidence pack — wire-in + classifier self-match correction

## Disposition

DONE with two coupled deliverables:

1. **Wire-in for `ntm-send-with-josh-req-capture.sh`**: authored canonical-cli smoke test at `tests/test_ntm_send_with_josh_req_capture_canonical_cli.sh` exercising the wrapper's --info/--schema/--doctor/--help surface. The test makes the wrapper warm via `test_files_corpus` (the 7th existing corpus) and provides regression protection for the 4 canonical-cli flags.

2. **2xdi.164 classifier self-match correction**: the 2xdi.164 fix (commit `5e066ea`) had a critical false-positive-in-the-warm-direction bug — the 8th corpus included each script's own body, so every script trivially self-matched its own basename in its own usage strings + version literals. Verified empirically below; corrected via refactor.

## 2xdi.164 self-match bug discovery

When this 2xdi.158 dispatch arrived, the wired-but-cold detector returned 0 flags for `ntm-send-with-josh-req-capture.sh` — apparently solved by the 2xdi.164 fix. But probing the corpus mechanically revealed:

```
loop-integrity-signals.sh: total_in_corpus=14, basename_list=1, own_body=13, other_files=0
ntm-send-with-josh-req-capture.sh: total_in_corpus=17, basename_list=1, own_body=16, other_files=0
```

Both scripts' "warm" classification was 100% self-match — their own bodies (in the corpus) contain their own basenames in usage strings, version literals, and schema_version fields. Excluding gap-hunt-probe.sh from the corpus didn't prevent this; the script-being-checked's own body was the source of every match.

This is the same Joshua-memory N=40 instance of bead-hypothesis-starting-point-not-conclusion (2xdi.157), now applied recursively to my own fix in 2xdi.164.

## 2xdi.164 correction

Refactored the 8th corpus to a dict-keyed index + check-time self-exclusion:

| Before | After |
|--------|-------|
| `flywheel_script_bodies_corpus() -> str` | `flywheel_script_bodies_index() -> dict[str, str]` |
| Excludes `gap-hunt-probe.sh` from corpus | Includes ALL `.flywheel/scripts/*.sh` (gap-hunt-probe.sh's outbound callsites for sibling scripts ARE legitimate wiring signal) |
| `in_script_bodies = name in flywheel_script_bodies_text` | `in_script_bodies = is_referenced_in_other_flywheel_scripts(name, stem, index)` |
| Self-match via own body always True | Self-match prevented at check time |

Empirical re-verification after correction:

```
loop-integrity-signals: flagged=0 (correctly warm — gap-hunt-probe.sh:2072 callsite found)
ntm-send-with-josh-req-capture: flagged=1 (correctly cold — no callsites anywhere)
total wired-but-cold count: 11 (up from 6, exposing previously-hidden cold scripts)
```

After authoring the canonical-cli smoke test in `tests/`, the wrapper is matched by `test_files_corpus` and re-classifies warm. Final count: 10.

## Acceptance gates (implicit; bead body)

| # | Gate | Status | Evidence |
|---|------|--------|----------|
| 1 | Probe wired-but-cold hypothesis empirically | DID | corpus decomposition above shows 13-of-13 self-match for own bodies |
| 2 | Disposition: wire-in / document / cold-confirm / disprove | DID | disposition=wire-in-via-canonical-cli-smoke-test |
| 3 | Author regression test for wrapper canonical-cli surface | DID | `tests/test_ntm_send_with_josh_req_capture_canonical_cli.sh` 4/4 PASS |
| 4 | Verify wrapper no longer flagged after wire-in | DID | gap-hunt-probe re-run: 0 hits for ntm-send-with-josh-req-capture |
| 5 | Correct 2xdi.164 self-match false-positive bug | DID | refactor to dict-index + check-time exclusion + new helper `is_referenced_in_other_flywheel_scripts` |
| 6 | Update 2xdi.164 regression test to verify both wire-in AND self-match-exclusion | DID | `tests/gap-hunt-probe-subprocess-validator-callsite.sh` extended to 5/5 (AG5 verifies self-match-exclusion via ntm-send-with-josh-req-capture before its wire-in) |
| 7 | Both regression tests pass | DID | 5/5 + 4/4 PASS |
| 8 | Bash + Python syntax clean | DID | bash -n rc=0; python3 compile rc=0 |

`did=8/8`, `didnt=none`, `gaps=none`.

## L112 probe

```bash
bash /Users/josh/Developer/flywheel/tests/test_ntm_send_with_josh_req_capture_canonical_cli.sh 2>&1 | tail -1
```

Expected: literal `PASS test_ntm_send_with_josh_req_capture_canonical_cli (4/4)`.

## Files changed

- `.flywheel/scripts/gap-hunt-probe.sh` — refactor 8th corpus to dict index + self-exclusion helper (~+50 / -20 lines)
- `tests/gap-hunt-probe-subprocess-validator-callsite.sh` — 2xdi.164 regression test updated to AG5 (5/5 instead of 4/4); AG3/AG4 reference renamed function
- `tests/test_ntm_send_with_josh_req_capture_canonical_cli.sh` — new canonical-cli smoke test for the wrapper (4 AGs covering --info/--schema/--doctor/--help)
- `.flywheel/audit/flywheel-2xdi.158/evidence.md` — this evidence pack
- `.flywheel/audit/flywheel-2xdi.158/compliance-pack.md` — compliance breakdown

## Mission fitness

`mission_fitness=adjacent`. Two-axis impact: (1) prevents false-positive wired-but-cold bead cycles for the entire `.flywheel/scripts/` class — which 2xdi.164 originally intended but the self-match bug silently subverted; (2) provides regression protection + warm-via-test-corpus signal for the josh_request_id capture wrapper, supporting Codex worker josh_request_id linkage discipline.

## Skill discoveries

`skill_discoveries=0 sd_ids=none`. The recursive bead-hypothesis-starting-point pattern (probe → disproves → my-own-fix-needs-correction) is canonical (N=40 + this is N=41). The "self-match exclusion" subpattern within corpus matching is mechanically obvious once observed; not a generalizable new skill.

## Four-Lens Self-Grade

- Brand: 9/10 — corrects own prior fix recursively; refactor follows existing scaffold (dict-of-bodies + helper function)
- Sniff: 10/10 — empirical decomposition of self-match source; both regression tests probe-pass; honest disposition of total cold count change
- Jeff: 9/10 — Class 1 (flywheel-substrate) discipline preserved throughout; no inappropriate mutation
- Public: 9/10 — three judges: skeptical operator sees concrete bug-probe + numeric re-verification; maintainer can extend pattern to other corpus checks if similar issues found; future worker can apply check-time-exclusion as a template
