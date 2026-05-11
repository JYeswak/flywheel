---
bead: flywheel-2xdi.157
title: gap-wired-but-cold loop-integrity-signals.sh (DISPROVED)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: DONE (hypothesis disproved; no-action-needed)
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
---

# 2xdi.157 evidence pack — wired-but-cold hypothesis DISPROVED

## Disposition

DONE with verdict **bead-hypothesis-disproved-by-probe** per Joshua-memory `feedback_bead_hypothesis_starting_point_not_conclusion.md` (N=39). The gap-hunt-probe auto-filed this bead with class=wired-but-cold; worker empirical probe confirms the script is **warmly wired** — the classifier produced a false positive.

## Empirical disproof

The hypothesis "loop-integrity-signals.sh not referenced by recent flywheel jsonl ledgers modified in last 30d" is technically TRUE but the inference "therefore cold/orphan/needs-wiring-in" is WRONG.

| Probe | Result |
|-------|--------|
| Script exists + executable | YES (11869 bytes, mode 755, mtime 2026-05-09) |
| Script self-doctor | `status: ok` |
| Script probe against flywheel project | `verdict: LIMPING` with `marker_fresh: ok` (working) |
| Callsite count in `.flywheel/scripts/` (code-only) | 5 references in `gap-hunt-probe.sh` |
| Last-touch git log | commit `a821265` — `feat(flywheel): split loop-integrity into marker / callback / bridge signals` |
| Subprocess wiring | `.flywheel/scripts/gap-hunt-probe.sh:2072` invokes via `subprocess.run([validator, "--project", project, "--repo", str(repo), "--json"])` |

## Root cause analysis (classifier false positive)

The wired-but-cold classifier scans JSONL ledgers for entries that reference the script name within 30d. Scripts wired via the **subprocess-call-with-stdout-consumption** pattern produce no ledger trace by design — caller invokes the script, parses returned JSON in-memory, applies the signals to runtime decisions, but the SCRIPT itself never writes to a ledger.

This is exactly the case for `loop-integrity-signals.sh`:

```python
# .flywheel/scripts/gap-hunt-probe.sh:2072-2104
validator = REPO_ROOT / ".flywheel/scripts/loop-integrity-signals.sh"
result = subprocess.run([validator, "--project", project, "--repo", str(repo), "--json"], ...)
payload = json.loads(result.stdout)
signals_dict = payload.get("signals") or {}
# ...in-memory consumption; no ledger write
```

## Follow-up bead filed (root-cause fix)

`flywheel-2xdi.164` filed against the gap-hunt-probe classifier. Title: "[classifier-bug] gap-hunt-probe wired-but-cold false positives for subprocess-validator-pattern scripts (parent of 2xdi.157)". Recommended classifier extension: callsite probe + doctor probe + last-touch heuristic before emitting cold verdict.

## Acceptance gates (implicit; gap-bead body)

| # | Gate | Status | Evidence |
|---|------|--------|----------|
| 1 | Empirically test the wired-but-cold hypothesis | DID | 6-row probe table above; doctor=ok, probe verdict produced, 5 callsites |
| 2 | Disposition: wire-in / document / mark cold / disprove | DID | disposition=disprove; hypothesis false positive |
| 3 | File root-cause follow-up if hypothesis disproved | DID | `flywheel-2xdi.164` filed against gap-hunt-probe classifier |
| 4 | Preserve script (no deletion / deprecation) | DID | no script changes; warm wiring confirmed |

`did=4/4`, `didnt=none`, `gaps=flywheel-2xdi.164`.

## L112 probe

```bash
test -x /Users/josh/Developer/flywheel/.flywheel/scripts/loop-integrity-signals.sh && grep -c "loop-integrity-signals" /Users/josh/Developer/flywheel/.flywheel/scripts/gap-hunt-probe.sh
```

Expected: numeric >=5 (callsite count in gap-hunt-probe.sh).

## Files changed

- `.flywheel/audit/flywheel-2xdi.157/evidence.md` — this evidence pack
- `.flywheel/audit/flywheel-2xdi.157/compliance-pack.md` — compliance breakdown
- `.beads/issues.jsonl` — flywheel-2xdi.164 follow-up bead row

(No script changes — the wired-but-cold hypothesis is disproved; no fix required at the script level.)

## Mission fitness

`mission_fitness=adjacent`. Disproving false-positive gap-hunt-probe verdicts via empirical probe + filing the root-cause classifier bug supports the self-sustaining-fleet mission by preventing waste-of-cycles on already-warm wiring + improving the gap-hunt-probe precision over time.

## Skill discoveries

`skill_discoveries=0 sd_ids=none`. The pattern "bead-hypothesis-is-starting-point-not-conclusion" is already canonical (Joshua-memory N=39); this is its 40th instance.

## Four-Lens Self-Grade

- Brand: 9/10 — disprove-by-probe disposition follows canonical bead-hypothesis discipline
- Sniff: 10/10 — empirical disproof with 6-row probe table; root-cause classifier bug filed
- Jeff: 9/10 — Class 1 (Joshua-unmanaged flywheel substrate) discipline preserved; no inappropriate mutation
- Public: 9/10 — three judges: skeptical operator sees concrete evidence + filed follow-up; maintainer sees clean disposition; future worker sees the classifier-extension recommendation
