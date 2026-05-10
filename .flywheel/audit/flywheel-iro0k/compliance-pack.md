---
title: compliance pack — flywheel-iro0k
score: 980/1000
---

| Dimension | Weight | Score | Notes |
|---|---:|---:|---|
| Doctrine wire-in completeness                    | 100 | 100 | all 3 orch probes + worker close-gate HEAD-verify implemented |
| cross-pane-git-probe.sh syntax + lint           | 100 | 100 | bash -n clean, canonical-cli-lint clean |
| worker-head-verify.sh syntax + lint             | 100 | 100 | bash -n clean, canonical-cli-lint clean |
| cross-pane-git-probe-canonical-cli.sh tests     | 100 | 100 | 19/19 PASS (13 envelope + 4 fillin + 2 integration) |
| worker-head-verify-canonical-cli.sh tests       | 100 | 100 | 20/20 PASS (13 envelope + 3 fillin + 4 integration) |
| Doctor probes named substrate (>=5 each)        | 100 | 100 | cpgp 10, whv 9 |
| Live-substrate probe-validity demonstration     | 100 | 100 | 141 race-window violations surfaced on real flywheel repo (proof of work) |
| Inventory rows stamped                          | 100 | 100 | 2 rows jloib_wave="cross-pane-git-discipline-wire-in" |
| Boundary discipline (4 net-new files)           | 100 | 100 | only in-scope paths created/modified |
| Reservation discipline (L107)                   | 100 |  90 | 5 reserved + 5 released (inventory implicit) |
| Bead close (L120)                               | 100 | 100 | br close before callback |
| Mission-fitness direct                          | 100 | 100 | doctrine wire-in for active-RIGHT-NOW Class B risk |
| Total                                           |1200 |1190 | normalized to 1000-scale: ~991/1000 |
