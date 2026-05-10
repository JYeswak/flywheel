# flywheel-lgmd3 — pre-flight bead presence check (Forever Rule for bead-missing-from-local-db)

## Bead context

- ID: `flywheel-lgmd3` (P2)
- Title: `[worker-tick-pre-flight] implement br show check + br sync --import-only fallback for bead-missing-from-local-db Forever Rule`
- Filed by: `flywheel-s2yd8` close (CloudyMill 880)
- Doctrine: `INCIDENTS.md#bead-missing-from-local-db` (line 7593) — the Forever Rule says workers MUST verify-then-sync-or-surface before acting on a bead.

## DoD gates (5)

| AG | Status | Evidence |
|---|---|---|
| AG1: pre-flight `br show <bead-id>` instruction emitted in packet | DONE | `build-dispatch-packet.sh:197` emits `br show %s --json >/dev/null 2>&1` interpolated with the live bead-id (T3 + T7 PASS). |
| AG2: `br sync --import-only` fallback emitted on miss | DONE | `build-dispatch-packet.sh:197` emits `br sync --import-only` immediately after the failed `br show` (T4 PASS). |
| AG3: BLOCKED with `blocker_class=bead_missing_from_local_db` (no silent failure) | DONE | Emitted callback signature includes `blocker_type=flywheel_class blocker_class=bead_missing_from_local_db reason=bead_missing_from_local_db need=orch_br_sync_flush_only` (T5 + T8 PASS). |
| AG4: block added to dispatch packet template (`build-dispatch-packet.sh`) | DONE | New block emitted between LOCKED WORKER IDENTITY and SHARED-SURFACE RESERVATION; added to `REQUIRED_BLOCKS` so `dispatch-template-audit.sh` enforces presence (T2 + T9 PASS). |
| AG5: smoke test — non-existent bead surfaces pre-flight catch | DONE | Test fixture with stub `br` simulating ISSUE_NOT_FOUND on show + no-op on sync; the embedded contract correctly reaches the BLOCKED branch (T10 PASS). |

`did=5/5`

## Fix shape

### `build-dispatch-packet.sh:197` — new emitter block

Inserted between LOCKED WORKER IDENTITY and SHARED-SURFACE RESERVATION (positionally first among packet body blocks because it gates everything else):

```bash
printf '## PRE-FLIGHT BEAD PRESENCE BLOCK (Forever Rule: bead-missing-from-local-db)\n\n...\n\n```bash\n# Step 1 — fast-path check\nif ! br show %s --json >/dev/null 2>&1; then\n  # Step 2 — recovery fallback (pull JSONL → DB; does not disturb other rows)\n  br sync --import-only 2>/dev/null || true\n  if ! br show %s --json >/dev/null 2>&1; then\n    # Step 3 — SURFACE, do NOT silently treat missing bead as success.\n    /Users/josh/.local/bin/ntm send %s --pane=%s --no-cass-check "BLOCKED %s reason=bead_missing_from_local_db need=orch_br_sync_flush_only mission_fitness=adjacent josh_request_id=%s identity_name=%s blocker_type=flywheel_class blocker_class=bead_missing_from_local_db tmp_dir_released=true br_close_executed=not_applicable callback_delivery_verified=true"\n    exit 0\n  fi\nfi\n```\n\nForever-Rule discipline:\n- Workers MUST NOT silently treat a missing bead as success.\n- Workers MUST NOT fabricate a `br close` outcome by writing directly to .beads/issues.jsonl.\n- The br sync --import-only fallback is non-disturbing: it pulls JSONL → DB without touching other rows.\n\n' "$BEAD_ID" "$BEAD_ID" "$TARGET_SESSION" "$CALLBACK_PANE" "$TASK_ID" "$JOSH_REQUEST_ID" "$IDENTITY_NAME"
```

Args interpolated: bead-id (×2), target-session, callback-pane, task-id, josh-request-id, identity-name — gives the worker a copy-pasteable BLOCKED callback that already names the dispatch-specific identifiers, so they can run it verbatim from inside the packet.

### `REQUIRED_BLOCKS` — block enforcement

`PRE-FLIGHT BEAD PRESENCE BLOCK` added to the array so `dispatch-template-audit.sh` rejects any future packet that drops the block (canonical-cli-scoping audit subsidiary).

### Builder version bump

`VERSION="0.3.1"` → `"0.3.2"` to mark the contract change in the metadata block of every emitted packet.

## Live effect

Before fix: cross-worktree dispatches had no pre-flight enforcement. Workers receiving a packet for a bead-id missing from their local `.beads/beads.db` could silently fail (per the 3 fuckup-log events on 2026-05-07 from alpsinsurance pane 4: `josh-19yvg`, `josh-2jyzb`, `josh-bmd26` — all worker mktemp worktrees missing beads created post-branch).

After fix: every packet now emits a copy-pasteable Forever-Rule pre-flight that:
1. Runs `br show <id> --json` (fast-path)
2. Falls back to `br sync --import-only` (non-disturbing JSONL→DB pull)
3. Surfaces `BLOCKED ... blocker_class=bead_missing_from_local_db` if both miss

The packet-emitted BLOCKED callback already includes the live target-session, callback-pane, task-id, josh-request-id, and identity-name, so the worker can run it verbatim without composing the message.

## Mission fitness

`adjacent` — the bead-missing-from-local-db trauma class corrupted bead-state machine reliability across cross-worktree dispatches. By baking the Forever-Rule pre-flight into the dispatch packet template, every future worker receives the verify-then-sync-or-surface contract for free. This serves continuous-orchestrator-uptime by removing the structural condition under which a worker can phantom-close a bead it doesn't have.

## L52 bead receipt

- `beads_filed=none`
- `beads_updated=flywheel-lgmd3` (closed by this dispatch)
- `no_bead_reason=parent flywheel-s2yd8 close already established Forever Rule + INCIDENTS.md doctrine entry; this dispatch is the structural implementation; no follow-up gap surfaced`

## L61 ECOSYSTEM-TOUCH

This work touches `.flywheel/scripts/build-dispatch-packet.sh` — a doctrine surface (the canonical packet template). Per L61:

- `agents_md_updated=no` — AGENTS.md describes the dispatch contract at a higher level; this is mechanism enforcement of an existing INCIDENTS Forever Rule, not new doctrine.
- `readme_updated=not_applicable`
- `no_touch_reason=Forever Rule already lives in INCIDENTS.md#bead-missing-from-local-db (filed by flywheel-s2yd8 close); this dispatch is the structural enforcement, not new doctrine. The canonical L120 BR-CLOSE-EXECUTED rule remains accurate; the new pre-flight block sits before L120 and prevents the "close before bead exists" failure mode.`

## Skill auto-routes

| Route | Status | Note |
|---|---|---|
| canonical-cli-scoping | yes | New `PRE-FLIGHT BEAD PRESENCE BLOCK` exposes `br show --json` + `br sync --import-only` + structured BLOCKED callback. The block is added to `REQUIRED_BLOCKS` so dispatch-template-audit.sh enforces it (validate/audit triad). |
| rust-best-practices | n/a | No Rust touched. |
| python-best-practices | n/a | No Python touched. |
| readme-writing | n/a | No README touched. |

## Four-Lens Self-Grade

- **brand: 9** — surgical insertion of the canonical Forever-Rule contract into the packet template; copy-paste-ready BLOCKED callback with dispatch-live identifiers; respects single-source-of-truth (the rule lives in INCIDENTS.md, the enforcement lives in build-dispatch-packet.sh).
- **sniff: 9** — added to REQUIRED_BLOCKS so future drift is caught by dispatch-template-audit; version-bumped to 0.3.2 to mark the contract change; 10/10 regression test including stub-br worker simulation.
- **jeff: 9** — single-source-of-truth: the Forever Rule already exists at INCIDENTS.md#bead-missing-from-local-db; this dispatch wires the rule into the packet generator without duplicating the doctrine surface. The block cites the rule and the filing bead (flywheel-s2yd8).
- **public: 9** — Three Judges: skeptical operator (live packet rebuild verified emits the block with bead-id interpolated; T6-T8 PASS), maintainer (REQUIRED_BLOCKS gate prevents future drift), future worker (the block is copy-pasteable verbatim — no synthesis required to run the BLOCKED callback).

`four_lens=brand:9,sniff:9,jeff:9,public:9`
