---
title: "Draft GitHub Issue: Config schema-loader drift beyond `[coordinator]`"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Draft GitHub Issue: Config schema-loader drift beyond `[coordinator]`

Do not file from this worker. Joshua files if desired.

Repository: `Dicklesworthstone/ntm`

Proposed title:

```text
Config schema-loader drift: documented nested sections rejected or ignored outside [coordinator]
```

## Summary

The #111 fix wires `[coordinator]` into the config schema and CLI status path. The issue body and Jeff's follow-up note identify a broader class: documented nested config sections can drift from the strict TOML loader when mirror structs/defaults are missing.

Candidates called out in #111 context:

- `context_rotation.recovery.*`
- `health.researcher_sessions`
- `resilience.rate_limit.auto_rotate`

This issue proposes one schema-loader-drift sweep rather than separate whack-a-mole fixes.

## Repro

Use a config containing currently documented or expected nested sections:

```toml
[context_rotation.recovery]
enabled = true

[health]
researcher_sessions = ["research-a", "research-b"]

[resilience.rate_limit]
auto_rotate = true
```

Then run:

```bash
ntm config validate --json
```

Observed class before equivalent mirror fixes:

- strict loader rejects unknown fields, or
- validation accepts but runtime ignores the values because no runtime mapping reads them.

## Expected

For every documented config section:

- `ntm config validate --json` accepts the section and validates its types.
- missing section gets runtime defaults, not zero values.
- runtime status/behavior reads the same config path that validation accepts.
- regression tests pin exact TOML examples.

## Actual

`[coordinator]` had this drift until #111. The same mirror/default sweep appears needed for the other nested sections named above.

## Source Observations

Deferring to maintainer architecture:

- #111 fixed `[coordinator]` by adding a TOML mirror struct and default wiring in `internal/config/config.go`.
- CLI status then maps TOML mirror to runtime config in `internal/cli/coordinator.go`.
- The same pattern likely applies to the remaining drift candidates, but their runtime owners may differ.

## Workaround

For now:

- avoid relying on undocumented nested config keys until validation and runtime status both prove they are wired.
- use command-line flags or runtime defaults where available.
- for automation, gate on `ntm config validate --json` plus a status command that proves runtime readback.

## Suggested Approach

One sweep:

1. Inventory documented TOML sections.
2. For each section, verify:
   - mirror struct exists,
   - `Default()` populates it,
   - `Load()` overlays it,
   - validation accepts it,
   - a runtime/status path reads it.
3. Add table-driven repro tests for:
   - `context_rotation.recovery.*`
   - `health.researcher_sessions`
   - `resilience.rate_limit.auto_rotate`
4. Keep fixes scoped to schema/default/readback parity. No behavior changes beyond honoring documented config.

## Environment

Local evidence branch:

- local NTM overlay currently based on local commit `5bbcaf7c`
- upstream #111 fix: `65602811`

This is a problem report, not a patch request. The local branch is only evidence that the drift class affects automation.
