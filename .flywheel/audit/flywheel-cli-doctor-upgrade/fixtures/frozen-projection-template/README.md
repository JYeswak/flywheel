# Fixture: frozen-projection-template

**Scenario:** template contains hard-coded literal path instead of HOME env or template var

**Round-trip contract (per repair-spec AG3):**

1. Start: `corrupt-tmpl-with-literal.tmpl` (the broken before-state)
2. Apply: `flywheel-loop doctor --fix --scope frozen-projection-template`
3. Assert: result matches `expected-source-named.tmpl`
4. Undo: `flywheel-loop doctor undo <run-id>`
5. Verify: bytes restored byte-exact to `undo-original.bak`

**Files (stub-stage; pass-2 fills with real fixture data):**

- `corrupt-tmpl-with-literal.tmpl` - corrupt input (broken before-state)
- `expected-source-named.tmpl` - expected after-fix state (target after-state)
- `undo-original.bak` - content-hashed backup of original (byte-exact restore source)

**Spec reference:** `.flywheel/audit/flywheel-cli-doctor-upgrade/flywheel-loop-pass-1-repair-spec.md`

**Status:** STUB (pass-1 deliverable per flywheel-oxzyr.1). Real fixture data + round-trip test = pass-2 deliverable.
