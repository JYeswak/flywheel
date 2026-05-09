## L148 — PUBLIC-READY-DEFAULT

---
id: L148
title: Public-ready default
status: long_term
shipped: 2026-05-09
review_due: 2026-11-09
trauma_class: private-status-as-quality-exemption
---

Every Joshua-owned or ZestStream-owned repo is audited and scored as if it may
be made public tomorrow, regardless of current private hosting status. Private
status is not a quality exemption; it only describes current visibility.

**How to apply:**
- Publishability and ZestStream voice scanners must run for private/internal
  repos unless the audit carries an explicit exemption class.
- The only canonical score-bypass classes are `EXEMPT_CLIENT_OWNED` and
  `EXEMPT_PUBLIC_FACING`.
- `private_internal`, `EXEMPT_INTERNAL`, `EXEMPT_PRIVATE_INTERNAL`, and
  `Public repo: no` are stale close reasons. Re-audit any close that used them
  as the reason the public-ready bar did not run.
- Client-owned and public-facing exemptions stay intact; do not convert them
  into ZestStream voice failures.
- Fleet doctrine propagation must carry this rule through the normal
  `agents-md-fleet-propagator` / doctrine-sync cadence.

**Forbidden outputs:**
- Closing a publishability or voice bead with `private_internal` as the bypass.
- Skipping `.flywheel/scripts/publishability-bar.sh` because a repo is private.
- Failing client-owned repos for not using Joshua/ZestStream first-person voice.

**Evidence:** bead `flywheel-uzhd3`; re-audit bead `flywheel-sib04`; scanner
`.flywheel/scripts/publishability-bar.sh`; public push gate
`.flywheel/scripts/zeststream-public-prepublish-hook.sh`; regressions
`tests/publishability-bar.sh` and `tests/zeststream-public-prepublish-hook.sh`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

**Cross-references:** L50, L51, L61, L88, L89, L96, and L120.

