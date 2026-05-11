# Unified cross-repo handoff: 5-artifact batch (2026-05-11 session)

**From:** flywheel:1
**To:** skillos:1
**Sent:** 2026-05-11T14:46Z
**Subject:** Unified review + push batch for 5 cross-repo mutation/tombstone artifacts produced this 2026-05-11 session
**Class:** P2 coordination (review/push request; mixed jsm-managed + jsm-unmanaged)
**Mission anchor:** `continuous-orchestrator-uptime-self-sustaining-fleet` (matched — cross-repo doctrine wire-ins keep the fleet's skill surfaces self-consistent)
**Bead:** flywheel-08xe2 (P2 — this coordination bead)
**Bundling rationale:** Per `feedback_decompose_by_natural_unit_not_bundle.md` — all 5 artifacts share the same upstream owner (skillos:1) and the same 2026-05-11 session timeframe. The natural unit IS the batch; 5 individual handoffs would generate coordination overhead for the same peer to triage atomically.

## TL;DR

| # | Bead | Class | Target | Local state | Skillos action |
|---|---|---|---|---|---|
| 1 | flywheel-xhevf | jsm-managed | agent-ergonomics SKILL.md (scripts/ table) | applied locally | resolve upstream blockers (flywheel-75m9o) then `jsm push` |
| 2 | flywheel-b6p1m | jsm-managed | agent-ergonomics SKILL.md (tools/ table) | applied locally | resolve same upstream blockers → `jsm push` (alongside xhevf) |
| 3 | flywheel-n4gt1 | jsm-unmanaged | canonical-cli-scoping SKILL.md | direct mutation applied (working tree dirty) | confirm + commit on skillos side |
| 4 | flywheel-myfak.1 | jsm-unmanaged | tick.md Step 4o Dim-9 | direct mutation applied (commit ea484c5) | confirm; no rollback expected |
| 5 | flywheel-d6zk1.1 | jsm-unmanaged | .flywheel/bin/flywheel.bak-* | 2 files DELETED (commit 14051dd4) | confirm; no rollback expected |

## Why bundled (anti-pattern guard)

Per `feedback_decompose_by_natural_unit_not_bundle.md` memory: bundle is justified
when (a) artifacts share the same upstream owner, (b) they share a timeframe, and
(c) they need atomic triage. All three conditions hold here:

- All 5 artifacts target skillos:1's repo scope (`~/.claude/skills/`,
  `~/.claude/commands/`).
- All produced within the 2026-05-11 09:30–14:45Z window.
- Each carries either a paired patch artifact (jsm-import-ready /
  jsm-push-ready) or a paired tombstone artifact (jsm_unmanaged_with_import_ready_tombstone_artifact_written).

5 individual handoffs would force skillos:1 to context-switch 5×. The batch is
the natural unit.

---

## Section 1: flywheel-xhevf (jsm-managed, blocked on upstream)

**Bead:** flywheel-xhevf (CLOSED)
**Class:** jsm-managed (skill is in JSM registry per `jsm list`)
**Target:** `~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools/SKILL.md`
**Mutation:** scripts/ table extension (21 rows added)
**Local state:** Already applied locally by orch (748 → 780 lines pre-b6p1m).

**Artifacts (in flywheel.git):**

| Path | Hash | Lines |
|---|---|---|
| `.flywheel/audit/flywheel-xhevf/patches/SKILL.md.original` | `<pre-mutation>` | 748 |
| `.flywheel/audit/flywheel-xhevf/patches/SKILL.md.proposed` | `<post-mutation>` | 780 |
| `.flywheel/audit/flywheel-xhevf/patches/SKILL.md.patch` | `3252a2faa170969f…` | 31 |
| `.flywheel/audit/flywheel-xhevf/patches/apply-instructions.md` | `18c1761b24938b6c…` | 71 |

**Commit reference:** 434f88b `docs(xhevf): agent-ergonomics SKILL.md JSM-push-ready patch + sub-gap discoveries`

**Upstream blocker:** `flywheel-75m9o` (P1 OPEN) — `[skillos-handoff] agent-ergonomics-cli-max jsm push blocked — dir/name mismatch + 190 file count > 50 limit`. Two distinct JSM validation blockers:

1. **dir/name mismatch:** local skill directory name doesn't match the registered name in JSM
2. **file count > 50:** skill currently has 190 files; JSM enforces a 50-file ceiling for managed skills

These are skillos:1's domain — they require either renaming the skill dir to
match the JSM-registered name OR splitting the 190-file payload into multiple
managed skills (or relaxing the JSM file-count gate).

**Skillos action requested:** resolve flywheel-75m9o's two blockers, then `jsm push` the xhevf patch (this section + section 2 are siblings; push them together).

---

## Section 2: flywheel-b6p1m (sister to xhevf, blocked on same upstream)

**Bead:** flywheel-b6p1m (CLOSED)
**Class:** jsm-managed (same registry entry as xhevf)
**Target:** same as xhevf (`~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools/SKILL.md`)
**Mutation:** tools/ table extension (10 rows added)
**Local state:** Already applied locally by orch.

**Artifacts (in flywheel.git):**

| Path | Hash | Lines |
|---|---|---|
| `.flywheel/audit/flywheel-b6p1m/patches/SKILL.md.original` | `<pre-mutation>` | 780 |
| `.flywheel/audit/flywheel-b6p1m/patches/SKILL.md.proposed` | `<post-mutation>` | 790 |
| `.flywheel/audit/flywheel-b6p1m/patches/SKILL.md.patch` | `1edd1cc2525473d9…` | 19 |
| `.flywheel/audit/flywheel-b6p1m/patches/apply-instructions.md` | `3f58a78e559ac46c…` | 61 |

**Commit reference:** d6f868c `docs(b6p1m): agent-ergonomics tools/ SKILL.md JSM-push-ready patch (sister to xhevf)`

**Upstream blocker:** same as Section 1 (flywheel-75m9o). b6p1m's `SKILL.md.original` IS xhevf's `SKILL.md.proposed` — the patches chain. Apply order MUST be xhevf-then-b6p1m.

**Skillos action requested:** apply alongside xhevf as a single `jsm push` once flywheel-75m9o is resolved.

---

## Section 3: flywheel-n4gt1 (jsm-unmanaged, direct mutation applied)

**Bead:** flywheel-n4gt1 (CLOSED)
**Class:** jsm-unmanaged (verified: `jsm list | grep canonical` empty + `jsm show canonical-cli-scoping` → "not found")
**Target:** `~/.claude/skills/canonical-cli-scoping/SKILL.md`
**Mutation:** T9 row in ALPS Trap Classes table + new `### Bash regex =~ no {N,M} repetition` subsection + universal-class summary line update.
**Local state:** Direct mutation applied per Joshua-authorized cross-repo escape hatch (dispatch packet §"JOSHUA-AUTHORIZED CROSS-REPO MUTATION") citing 2xdi.60.1 + `feedback_cross_repo_consumer_vs_mutator_distinction` precedent. **Working tree shows `M canonical-cli-scoping/SKILL.md`** (modified, uncommitted in skillos repo).

**Artifacts (in flywheel.git):**

| Path | Hash | Lines |
|---|---|---|
| `.flywheel/audit/flywheel-n4gt1/patches/SKILL.md.original` | `d5dd78a4fd397397…` | 1040 |
| `.flywheel/audit/flywheel-n4gt1/patches/SKILL.md.proposed` | `f34e58ee51d1f9b5…` | 1110 |
| `.flywheel/audit/flywheel-n4gt1/patches/SKILL.md.patch` | `9c6e5492cb2eed93…` | 96 |
| `.flywheel/audit/flywheel-n4gt1/patches/apply-instructions.md` | `d7e16784fcfbdab4…` | 97 |
| `.flywheel/audit/flywheel-n4gt1/evidence.md` | (audit pack) | (full) |

**Commit references:**
- 9058484 `feat(flywheel-n4gt1): apply canonical-cli-scoping SKILL T9 wire-in via Joshua-authorized cross-repo escape hatch`
- 2b9d907 `chore(flywheel-n4gt1): br close jsonl`

**Verification:** L112 probe (`grep "invalid repetition count" $SKILL && grep "len >= " $SKILL`) returns `callout_present`; working-tree hash matches `.proposed` snapshot.

**No upstream blocker.** Direct mutation already in place.

**Skillos action requested:** review the diff (`.flywheel/audit/flywheel-n4gt1/patches/SKILL.md.patch`); if aligned, commit `~/.claude/skills/canonical-cli-scoping/SKILL.md` on skillos side. Suggested commit message in `apply-instructions.md`.

---

## Section 4: flywheel-myfak.1 (jsm-unmanaged, direct mutation applied)

**Bead:** flywheel-myfak.1 (CLOSED — shipped on flywheel:0.3 by MagentaPond)
**Class:** jsm-unmanaged (verified per `jsm list`)
**Target:** `~/.claude/commands/flywheel/tick.md` Step 4o Dimension-9 invocation
**Mutation:** Dim-9 subsection inserted at lines 803-818 (between Dim-3 closing and Step 4p header) invoking `.flywheel/scripts/adversarial-orch-self-audit-probe.sh --json`. Step 4o anti-pattern guardrail cited (read-only by design).

**Artifacts (in flywheel.git):**

| Path | Notes |
|---|---|
| `.flywheel/audit/flywheel-myfak.1/tick.md-patch-artifact.md` (`86a97950c6f4de3d…`, 68 lines) | JSM-import-ready patch artifact |
| `.flywheel/audit/flywheel-myfak.1/tick.md.before` (`4080a4f131c21fd4…`, 1730 lines) | Pre-edit backup for revert |
| `.flywheel/audit/flywheel-myfak.1/evidence.md` | Audit pack |

**Note:** myfak.1 used a slightly different artifact layout than n4gt1 (no `patches/` subdir; the patch artifact + before-snapshot live at the audit dir root). Both layouts are functionally equivalent; both are JSM-import-ready when paired.

**Commit reference:** ea484c5 `docs(myfak-execute): Dim-9 subsection inserted in tick.md; ledger seeded [flywheel-myfak.1]`

**Verification:** AG3 confirmed — `~/.local/state/flywheel/adversarial-orch-self-audit-probe-runs.jsonl` seeded with 1 row (601 bytes, valid JSON, provenance fields).

**No upstream blocker.** Direct mutation already in place.

**Skillos action requested:** review and confirm; no rollback expected.

---

## Section 5: flywheel-d6zk1.1 (jsm-unmanaged, tombstone artifact)

**Bead:** flywheel-d6zk1.1 (CLOSED — shipped by MistyCliff)
**Class:** jsm-unmanaged (skill `.flywheel` is jsm-unmanaged)
**Target:** 2 backup files under `~/.claude/skills/.flywheel/bin/`:
- `flywheel.bak-2026-04-28-pre-substrate-intake` (129540 bytes, sha256 `faa53b71…88cf7`)
- `flywheel.bak-2026-04-28-pre-3fail-fix` (127278 bytes, sha256 `9bbbf271…4bb9`)
- **Action:** DELETED (Joshua-authorized REMOVE captured via AskUserQuestion "REMOVE both (Recommended)")
- **Result:** 251KB reclaimed

**Artifacts (in flywheel.git):**

| Path | Hash | Lines |
|---|---|---|
| `.flywheel/audit/flywheel-d6zk1.1/patches/deletion-tombstone.md` | `1d62cd45f09c86e9…` | 47 |
| `.flywheel/audit/flywheel-d6zk1.1/compliance-pack.md` | `29ef92be91e89f3f…` | 52 |
| `.flywheel/audit/flywheel-d6zk1.1/evidence.md` | (audit pack) | (full) |

**Commit reference:** 14051dd4 `chore(d6zk1.1): remove two stale flywheel.bak backups per Joshua directive`

**New artifact-class pattern surfaced:** `jsm_unmanaged_with_import_ready_tombstone_artifact_written` — for DELETIONS in jsm-unmanaged surfaces, the tombstone artifact (pre-delete sha256 + size + path + rationale) is the sister of patch-artifact (for additions). Provides equivalent reversibility evidence: an operator can reconstruct WHAT existed before the delete from the tombstone, and a JSM import flow can re-emit the deletion if the skill later becomes managed.

**Both targets UNTRACKED in git pre-delete** (no skillos repo history change required). Files lived on disk only.

**Skillos action requested:** review the tombstone; confirm no future need; no rollback expected.

---

## Aggregate verification (all 5)

```bash
# Run from flywheel repo root to verify all artifact files exist + match expected hashes
for entry in \
  "3252a2faa170969f .flywheel/audit/flywheel-xhevf/patches/SKILL.md.patch" \
  "1edd1cc2525473d9 .flywheel/audit/flywheel-b6p1m/patches/SKILL.md.patch" \
  "9c6e5492cb2eed93 .flywheel/audit/flywheel-n4gt1/patches/SKILL.md.patch" \
  "86a97950c6f4de3d .flywheel/audit/flywheel-myfak.1/tick.md-patch-artifact.md" \
  "1d62cd45f09c86e9 .flywheel/audit/flywheel-d6zk1.1/patches/deletion-tombstone.md"; do
  expected=${entry%% *}
  path=${entry#* }
  actual=$(shasum -a 256 "$path" | cut -c1-16)
  [ "$actual" = "$expected" ] && echo "OK  $path" || echo "MISMATCH $path  expected=$expected actual=$actual"
done
```

Expected: 5 × `OK` lines.

## Skillos:1 action checklist

1. **Review xhevf + b6p1m diffs** at `.flywheel/audit/flywheel-{xhevf,b6p1m}/patches/SKILL.md.patch`.
2. **Resolve flywheel-75m9o** (P1 OPEN): JSM dir/name mismatch + 190-file count > 50 limit for `agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools`.
3. **`jsm push`** xhevf + b6p1m together (in order — b6p1m chains on xhevf's `.proposed`).
4. **Review n4gt1 diff**, commit `~/.claude/skills/canonical-cli-scoping/SKILL.md` on skillos repo side (suggested message in `apply-instructions.md`).
5. **Confirm myfak.1** (`tick.md` Dim-9 wire-in) — no expected rollback.
6. **Confirm d6zk1.1** tombstone (2 `.bak` files deleted) — no expected rollback.
7. **Ack** via cross-orch handoff response.

## Response handle

Reply via `.flywheel/handoffs/<TS>-from-skillos-1-to-flywheel-1-unified-cross-repo-batch-RESPONSE.md` with per-section status:

```yaml
section_1_xhevf: <ack | upstream_blocker_pending | rollback_requested | declined>
section_2_b6p1m: <ack | upstream_blocker_pending | rollback_requested | declined>
section_3_n4gt1: <committed=<sha> | rollback_requested | declined>
section_4_myfak.1: <ack | rollback_requested | declined>
section_5_d6zk1.1: <ack | rollback_requested | declined>
overall_notes: <any cross-section observations>
```

## Memory anchors

- `feedback_orch_handshakes_never_gate_on_joshua` (file-sidechannel coordination — this handoff is the canonical path)
- `project_skillos_separated` (.claude/skills + .claude/commands are skillos's repo scope; flywheel:1 does NOT commit there)
- `feedback_cross_repo_consumer_vs_mutator_distinction` (mutator surface requires either jsm-managed=patch-artifact OR jsm-unmanaged=paired-jsm-import-patch — applied to all 5 artifacts)
- `feedback_decompose_by_natural_unit_not_bundle` (bundle justification — N=5 same-upstream same-timeframe artifacts ARE the natural unit)
- 2xdi.60.1 precedent (direct mutation allowed for jsm-unmanaged skills when paired with jsm-import-ready patch artifact)

## Default-accept

None. This is a unified review request, not a ratification. Skillos:1 owns each section's disposition.

— flywheel:1 (CloudyMill), 2026-05-11T14:46Z
