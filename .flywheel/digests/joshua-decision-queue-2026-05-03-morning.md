# Joshua Decision Queue Digest — 2026-05-03 Morning

Purpose: collapse tonight's scattered Joshua-decision queue into one morning read. No decisions were applied while preparing this digest.

## Recommended Disposal Order

Ranked by leverage x reversibility:

1. `flywheel-rzk3` — mobile-eats canonical receipt mirror: approve Path A.
2. `flywheel-478g` — R1 cross-session loop INCIDENTS promotion: approve Location A.
3. `flywheel-rx1t` — distribute canonical INCIDENTS scope from `flywheel-loop init`: approve selected-rule distribution.
4. `flywheel-ntaf.1` — Agent Mail FD doctor + launchd maxfiles: approve apply with restart window.
5. `flywheel-syfq` — JSM publish `agent-fleet-management`: defer push until safe publisher wrapper/redacted flow.

Consolidated approve path:

- **Approve 1A + 2A + 3B**: mirror mobile-eats canonical receipt, promote R1 incident to canonical flywheel INCIDENTS, and distribute selected canonical INCIDENTS entries via init. These are independent and reversible.
- **Approve 4A with restart window**: apply Agent Mail maxfiles + doctor helper, accepting a brief local Agent Mail restart.
- **Approve 5C**: do not push `agent-fleet-management` directly; build/use a redacted publish path first.

Estimated Joshua time if agreeing with recommendations: 10 minutes.

## 1. Mobile-Eats Canonical Receipt Mirror (`flywheel-rzk3`)

**WHAT:** Decide whether mobile-eats should write the canonical `~/.local/state/flywheel-loop/last_tick_mobile-eats.json` receipt or make canonical probes read product-specific receipts.

**WHY:** Mobile-eats is live and dispatching every 5 minutes, but flagship/cold-loop probes can classify it as cold because the canonical receipt path is absent.

**OPTIONS:**
- A. Add post-tick wrapper that runs the product tick, then atomically mirrors bridge JSON to `last_tick_mobile-eats.json`.
- B. Teach canonical probes to read mobile-eats product-specific paths directly.
- C. Defer and keep current mismatch.

**RECOMMENDED:** A. It preserves the canonical contract and isolates the change to one product loop.

**BLAST RADIUS:** Reversible. Mutates one launchd ProgramArguments entry and adds one wrapper script; rollback restores the plist backup and removes the wrapper. Risk is a brief loop reload.

**TIME-TO-DISPOSE:** 2 minutes to approve; about 10 minutes to apply and verify two tick intervals.

**Source drafts:** `/tmp/mobile-eats-receipt-mirror-DRAFT-A.md`, `/tmp/mobile-eats-receipt-mirror-DRAFT-B.md`.

## 2. R1 Cross-Session Loop INCIDENTS Promotion (`flywheel-478g`)

**WHAT:** Choose where to promote the R1 skillos -> FoggyBear -> LavenderGlen -> flywheel loop doctrine entry.

**WHY:** This is the first complete cross-session reinforcing loop that turned routed decisions into validated skill updates; if it stays only in receipts, the pattern will be rebuilt from scratch.

**OPTIONS:**
- A. Write to `~/.claude/skills/.flywheel/INCIDENTS.md`.
- B. Write to `/Users/josh/Developer/flywheel/INCIDENTS.md`.
- C. Write to `~/.claude/skills/dicklesworthstone-stack/INCIDENTS.md`.
- D. Defer.

**RECOMMENDED:** A. The rule is canonical flywheel operating doctrine; Agent Mail is substrate, not the owning domain.

**BLAST RADIUS:** Reversible documentation/doctrine append. Rollback is removing one INCIDENTS entry. No runtime mutation.

**TIME-TO-DISPOSE:** 1 minute to approve; about 5 minutes to append and sanity-check.

**Source draft:** `/tmp/r1-loop-canonical-incidents-DRAFT.md`.

## 3. Canonical INCIDENTS Distribution From Init (`flywheel-rx1t`)

**WHAT:** Decide what `flywheel-loop init` should distribute when canonical INCIDENTS entries, such as mission-anchor-drift, are supposed to reach repo-local flywheels.

**WHY:** A disposable test repo got AGENTS/MISSION/GOAL/STATE but no `.flywheel/INCIDENTS.md`; the mission-anchor-drift rule stayed only in global canonical state, so new repos miss the recovery doctrine.

**OPTIONS:**
- A. Copy full `~/.claude/skills/.flywheel/INCIDENTS.md` into every initialized repo.
- B. Distribute selected canonical INCIDENTS entries marked as repo-relevant, starting with mission-anchor-drift.
- C. Fold the rule into `AGENTS-CANONICAL.md` or doctrine-sync only.
- D. Defer.

**RECOMMENDED:** B. Full INCIDENTS is too noisy; AGENTS-only collapses the L56 ladder. Selected distribution preserves the incident layer with lower repo clutter.

**BLAST RADIUS:** Reversible template/init behavior. Rollback removes generated `.flywheel/INCIDENTS.md` or narrows the selected entry list. Needs a disposable-repo test before fleet sync.

**TIME-TO-DISPOSE:** 2 minutes to approve option; about 20-30 minutes to implement and validate.

**Source bead:** `flywheel-rx1t`.

## 4. Agent Mail FD Doctor + Launchd Maxfiles (`flywheel-ntaf.1`)

**WHAT:** Decide whether to apply the drafted Agent Mail launchd `NumberOfFiles` limits plus local FD doctor/restart helpers.

**WHY:** Live draft doctor reports `FAIL`: 262 total FDs, 224 numeric FDs, 199 lock FDs, launchd soft maxfiles 256, and no plist file limits. File reservations can wedge again.

**OPTIONS:**
- A. Apply plist maxfiles patch, install doctor/restart helpers, restart Agent Mail, then verify reservation call.
- B. Install doctor only and defer launchd mutation.
- C. Defer everything and rely on manual restart when Agent Mail wedges.

**RECOMMENDED:** A with an explicit restart window. The current service is already in FAIL territory; the draft is scoped and reversible.

**BLAST RADIUS:** Reversible but runtime-affecting. Brief local Agent Mail restart; rollback restores plist backup and removes helper scripts. Biggest risk is interrupting in-flight file reservations.

**TIME-TO-DISPOSE:** 2 minutes to approve; about 15 minutes to apply, restart, doctor, and smoke one reservation.

**Source draft dir:** `/tmp/agent-mail-fd-doctor-DRAFT/`.

## 5. JSM Publish `agent-fleet-management` (`flywheel-syfq`)

**WHAT:** Decide whether to publish the locally authored `~/.claude/skills/agent-fleet-management/` skill through `jsm push`.

**WHY:** The skill is validated and load-bearing for fleet leverage, but direct `jsm push` has prior signed-upload-URL echo risk and should not publish ZestStream-authored skills without explicit scope.

**OPTIONS:**
- A. Push now with strict redaction of command output.
- B. Keep local only for now.
- C. Build/use a safe redacted publisher wrapper, then push.

**RECOMMENDED:** C. The skill should likely publish, but not through an unguarded path that can echo signed URLs.

**BLAST RADIUS:** External publication is less reversible than a local doc append. Keeping local is zero-risk; wrapper-first costs one small implementation step.

**TIME-TO-DISPOSE:** 2 minutes to choose; 5 minutes if keeping local, 20-30 minutes if wrapper-first.

**Current publish state:** `jsm validate ~/.claude/skills/agent-fleet-management --json` passes; `jsm search agent-fleet-management --json` returns no remote skill row.

## Regex Matches That Are Not Morning Decisions

These matched `Joshua|decision|apply|promote|publish` in open P1/P2 beads, but are not decision asks:

- `flywheel-z4s3` — flagship skillos anchor epic; contains "publishes" in the title. No morning decision in this digest.
- `flywheel-gcaf` — R1 completion measurement bead. It feeds decision `flywheel-478g`.
- `flywheel-mdry` — routed decisions processed measurement. It feeds R1 evidence.
- `flywheel-cmov` — FoggyBear vault/routing measurement. It feeds R1 evidence.

## One-Breath Reply Template

If Joshua agrees with the recommendations:

```text
Approve mobile-eats Path A, R1 Location A, INCIDENTS init selected-distribution B, Agent Mail FD apply A with restart window, and JSM publish path C wrapper-first.
```

Shorter:

```text
Approve 1A 2A 3B 4A 5C.
```

