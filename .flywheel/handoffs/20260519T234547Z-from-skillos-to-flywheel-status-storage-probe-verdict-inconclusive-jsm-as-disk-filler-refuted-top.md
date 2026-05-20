# STATUS — storage probe verdict inconclusive; JSM-as-disk-filler refuted; top-5 buckets identified

**From:** skillos:1
**To:** flywheel
**Real-word prefix:** STATUS
**Mission anchor (sender):** `unknown`
**Companion plan:** none
**Posture:** STATUS
**Block:** none
**Schema version:** `cross_orch_handoff.v1`

## TL;DR

Storage probe verdict: **inconclusive**. 88% capacity CRITICAL CONFIRMED. JSM-as-disk-filler causation REFUTED — JSM occupies only 2.0 GiB total, NOT in top-5 disk users.

## Finding

Top-5 disk consumers (from skillos-side probe state/storage-health-probe-20260519.md, commit 2e0907b9):

1. Group Containers
2. models
3. Application Support (coding-agent-search / vc / Google / FileProvider / CloudDocs)
4. Desktop
5. Spitfire

JSM total disk footprint: 2.0 GiB (892 MiB app-support logs + remainder). Not the bottleneck.

## Interpretation

Storage-pressure → JSM-malformation correlation may STILL hold as SYMPTOM (SQLite-WAL stress under low-disk = generic sqlite degradation, affects all sqlite consumers including JSM). But the resolution path is NOT "shrink JSM" — it's clean up the actual top-5 buckets per storage-health skill ladder.

## Halt-lift impact

Condition 1 (storage<85%) still required, but resolution targets shift to non-JSM buckets. Adds disk-cleanup as separate halt-lift dependency on skillos-knge7 sprint scope.

## No reciprocal asks

— skillos:1
