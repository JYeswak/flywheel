---
title: "Additive API Compat: Both-Empty / Either-Empty Preservation"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# Additive API Compat: Both-Empty / Either-Empty Preservation

Version: `api-additive-compat-both-empty-either-empty/v1`
Owner: any flywheel script/CLI/callback envelope author who extends a
stateful API with a new optional argument
Status: canonical, shipped 2026-05-11
Source bead: flywheel-2xdi.127 (memory-without-cross-link wire-in)

## TL;DR

When you add a new optional path/scope/workspace argument to an existing
API surface, **only reject when BOTH sides have non-empty values that
disagree**. Both-empty and either-empty cases MUST pass through unchanged
so legacy callers still work.

Anti-pattern: rejecting when the new field is empty. That breaks every
caller that hasn't been upgraded yet — instantly.

## Canonical memory source

This doctrine summarizes
`feedback_legacy_compat_both_empty_either_empty.md` — the META-RULE
memory (2026-05-08) documenting the discipline. Read the memory for
Jeff-precedent quotes (ntm#131 working_dir validation, ntm#132 CM
workspace scoping) and the cross-references to flywheel's own
additive contracts.

## The rule (formal)

For a new optional field `B` extending an API that previously only saw
`A`:

```text
if A != "" && B != "" && canonicalize(A) != canonicalize(B):
    REJECT (with explicit reason citing both values)
else:
    ACCEPT (pass through unchanged)
```

Where `canonicalize()` is the appropriate normalization for the field's
type (e.g., `filepath.Clean(filepath.Abs(x))` for paths;
`strings.ToLower(x)` for case-insensitive ids; etc.).

## How to apply (checklist)

1. **Default behavior post-extension equals pre-extension behavior.**
   A legacy caller passing nothing in the new field gets exactly the
   same outcome it got before.
2. **Legacy clients without the field → server MUST NOT reject.**
   Treat the missing field as "scope unknown, accept."
3. **Comparison logic:** `if a != "" && b != "" && norm(a) != norm(b) { reject }`
4. **HTTP/JSON envelopes:** elide empty fields from request body so older
   endpoints don't see unexpected keys.
5. **Audit surface:** include the new field on the response/audit envelope
   so callers can SEE the gating decision (accepted-empty vs
   accepted-matching vs rejected-disagree).
6. **Reject reason includes both values** (the disagreement is the load-bearing
   detail; just "rejected" is non-actionable).

## Jeff-precedent (canonical exemplars)

- **ntm#131** (commit 4d1b14bc — checkpoint `working_dir` validation):
  > "Both-empty / either-empty cases are preserved (legacy data still
  > loads); only two non-empty paths that disagree (after `filepath.Abs`
  > + `Clean`) are rejected."

- **ntm#132** (commit cb0a98de — CM workspace scoping):
  > HTTP request body field "is elided when empty so older daemons that
  > don't recognize the field aren't confused."

Both precedents shipped the discipline explicitly. Adopt their exact shape
for any new flywheel additive contract.

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| Reject when new field is empty | Breaks every legacy caller instantly; deploy-order coupling |
| Always require new field on both sides | Forces synchronous rollout of caller + callee; no graceful degradation window |
| Hide the gating decision | Caller can't audit why something was accepted or rejected; bug-triage takes 3× longer |

## Flywheel applications

- **`/flywheel:respawn`** (`flywheel-k4aeu`): recovery envelope includes
  `checkpoint.working_dir`; both-empty/either-empty paths still load legacy
  checkpoints; only mismatched non-empty paths reject.
- **m482 dispatch lint** (additive contract): workers without the new
  field don't have closes rejected for missing-field — only
  mismatch-with-evidence rejects.
- **nvny skill-discovery callback fields** (additive contract): same
  discipline — empty `sd_ids` accepted as `none`; explicit value
  required only when `skill_discoveries > 0`.

## Sister doctrine + memory

- `feedback_legacy_compat_both_empty_either_empty` memory (this doctrine's
  canonical source)
- Sister memories that codify additive-contract patterns:
  - `feedback_dispatch_post_send_verify_for_silent_deaf` (envelope
    field discipline)
  - `feedback_callback_first_dispatch` (callback contract minimums)

## Conformance

A flywheel API extension proves conformance via:
- Schema or doctring documents the new field as optional
- Default behavior in absence of the field is unchanged from pre-extension
- Reject path lists both values + canonicalization rule applied
- Audit/response envelope surfaces the gating decision

## Lifecycle

This is a HARD RULE for any future additive contract. It is the difference
between an extension that ships smoothly and one that breaks every existing
deploy until callers are upgraded. Jeff treats this as table stakes; flywheel
inherits the discipline.
