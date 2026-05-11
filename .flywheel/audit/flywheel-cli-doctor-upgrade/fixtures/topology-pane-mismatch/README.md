# Fixture: topology-pane-mismatch

**Scenario:** topology says pane 3, but session-orchestrator-map says pane 4 - mismatch

**Round-trip contract (per repair-spec AG3):**

1. Start: `corrupt-topology.jsonl` (the broken before-state)
2. Apply: `flywheel-loop doctor --fix --scope topology-pane-mismatch`
3. Assert: result matches `expected-resolved.jsonl`
4. Undo: `flywheel-loop doctor undo <run-id>`
5. Verify: bytes restored byte-exact to `undo-original.bak`

**Files (stub-stage; pass-2 fills with real fixture data):**

- `corrupt-topology.jsonl` - corrupt input (broken before-state)
- `expected-resolved.jsonl` - expected after-fix state (target after-state)
- `undo-original.bak` - content-hashed backup of original (byte-exact restore source)

**Spec reference:** `.flywheel/audit/flywheel-cli-doctor-upgrade/flywheel-loop-pass-1-repair-spec.md`

**Status:** STUB (pass-1 deliverable per flywheel-oxzyr.1). Real fixture data + round-trip test = pass-2 deliverable.
