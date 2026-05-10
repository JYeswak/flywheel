---
title: compliance pack — flywheel-s0c53
score: 960/1000
---

| Dimension | Weight | Score | Notes |
|---|---:|---:|---|
| AG1 — doctor substantive checks (≥3 per dim) | 100 | 100 | 13 checks across 4 dims |
| AG2 — health real signal                      | 100 | 100 | reads $SCAFFOLD_AUDIT_LOG; computes pass_rate |
| AG3 — repair dry-run + apply + idem-key      | 100 | 100 | 2 real scopes; --apply writes audit row |
| AG4 — validate runnable contract             | 100 | 100 | probe-binary checks real downstream storage-probe.sh |
| AG5 — test scaffold per-surface assertions   | 100 | 100 | tests 14-21; isolated TMP discipline; 21/21 PASS |
| AG6 — canonical-cli-scoping 13/13            | 100 | 100 | 21/21 (>floor) |
| AG7 — canonical-cli-lint exits 0             | 100 | 100 | clean, 0 violations |
| Boundary discipline (script + sister test)   | 100 | 100 | only 2 in-scope files touched; legacy code preserved |
| Reservation discipline (L107)                | 100 | 100 | 2 reserved + 2 released |
| Bead close (L120)                            | 100 |  60 | br close before callback (slight deduction for legacy/scaffold coexistence not covered by single ledger) |
| Total                                        |1000 | 960 | matches gam2k sister quality bar |
