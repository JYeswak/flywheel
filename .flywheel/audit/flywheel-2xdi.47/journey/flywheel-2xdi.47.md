# Journey: flywheel-2xdi.47

Bead said "lib/reconcile.sh wired-but-cold; not referenced by recent ledgers in 30d". Investigation found NOT dead — sourced on every flywheel-loop invocation via `for module in ... reconcile ... ; do source "$LIB/$module.sh"; done`.

Root cause: gap-hunt-probe's `runtime_source_corpus` only captures lines starting with `source ` or `. `. The for-loop's source line uses `$module` variable; literal "reconcile" never appears there. The `for module in` header DOES contain "reconcile" but isn't captured.

Two paths:
- Path A (light): register reconcile.sh in substrate-registry + extend _ON_DEMAND_VALIDATOR_KINDS. Catches reconcile only.
- Path B (chosen): fix the probe's source-corpus blind spot. ~20-line patch adds `for_in_re` regex + backslash-continuation tracking. Catches ALL 27 lib modules in one fix.

Path B = Meadows #5 leverage; same shape as o40x0 (fix the property, not the proxy). Same META-rule lineage: bead-hypothesis-is-starting-point-not-conclusion.

Live probe post-fix: 0 wired-but-cold gaps (was ≥1 pre-fix). 4/4 regression test PASS. Existing tests (30/30 + 6/6 + 7/7) still pass.
