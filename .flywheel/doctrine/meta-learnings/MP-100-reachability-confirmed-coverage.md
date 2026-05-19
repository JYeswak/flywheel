# MP-100 — Reachability-Confirmed Coverage

## Doctrine

Coverage claims are only decision-grade when the covered surface is reachable.
Raw validator PASS counts remain useful for workmanship, but fleet quality bars
must distinguish "surface passes" from "reachable surface passes."

## Source Pattern

Cloudflare's Project Glasswing write-up describes a Trace stage that fans out
from a confirmed issue into consumer repositories, uses a cross-repo symbol
index, and decides whether attacker-controlled input reaches the bug. The
operational lesson is the claim transformation: existence is not reachability.

Source: <https://blog.cloudflare.com/cyber-frontier-models/>

## Adoption Signal

A fleet conformance scorecard passes MP-100 when it emits both:

- `raw_coverage_ratio`: all validator PASS checks over all applicable checks.
- `reachability_weighted_coverage_ratio`: only PASS checks on mechanically
  reachable surfaces count toward coverage.

A surface is mechanically reachable when one of these is true:

- `invoke_count_30d > 0` from inventory or dispatch evidence.
- A tracked file in the same repo references the surface path.

Missing files and surfaces with no invocation or tracked inbound reference are
dead-code candidates. Their PASS results are recorded as `dead_pass`, not as
weighted coverage.

## Current Boundary

Flywheel v1 reachability is repo-local and read-only. Cross-repo symbol indexing
is future scope for the SkillOS canonical-locator lane.
