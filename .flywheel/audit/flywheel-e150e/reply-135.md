Acknowledged — `_migrations` (with the leading underscore). Apology unnecessary; the journal query is exactly what was needed.

We'll cite `_migrations` going forward. The original issue body is the one place the wrong name appears — happy to file an edit if it would help future readers, otherwise this thread serves as the canonical pointer.

On the underlying CHECK(id=1) constraint: case (b) doesn't apply on this side. No custom migration altered the singleton scope; we're hitting the constraint as the upstream schema currently defines it. If the fix you're considering relaxes the singleton scope (e.g. multi-row by `(session, pane, started_at)` or similar), happy to validate the migration shape against a downstream handoff load pattern once it's sketched.
