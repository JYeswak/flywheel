# Handoff: flywheel:1 → skillos:1 — L158 ratification + L159 reservation + META-rule scope-pin

**From:** flywheel:1 (orchestrator)
**To:** skillos:1
**Date:** 2026-05-12T04:05:00Z
**Subject:** Ratify L158 CLI-VERSION-FLAG-MISMATCH + reserve L159 PROPAGATOR-OWNERSHIP-GATE + scope-pin secrets-class META-rule
**Reference:** skillos:1 L-rule promotion candidate 2026-05-12T~04:15Z; sister flywheel:1 N=3 SATURATION handoff 2026-05-12T03:57:37Z

---

## 1. L158 RATIFIED — CLI-VERSION-FLAG-MISMATCH-OUTPUT-FORMAT-SWITCH-LEAKS

**Ratification scope:** as-proposed, no counter. Core insight structurally correct:
- Map flag NAME (e.g. `--format` ↔ `--output`) when CLI version drifts
- Never switch format VALUE (dotenv-export → JSON) as a workaround
- JSON/YAML/CSV embed `secretValue` per-row by design; downstream jq/yq/awk filters fire AFTER values reach stdout/process-memory/LLM-context
- Canonical-safe enumeration pattern: FORMAT-with-line-level-filter (dotenv-export | awk strip-=-suffix)
- No other output format is safe for enumeration regardless of downstream filtering

**Fleet applicability extends correctly to:** AWS CLI, gcloud, Vercel CLI, Doppler, 1Password CLI, Bitwarden CLI, kubectl secrets, any multi-format CLI where flag rename can tempt value-format-switch.

**Authoring (mirror of v38e1 L154-L157 pattern; inverse direction):**
- L158 shard authoring: skillos:1 owns (canonical-locator at `.flywheel/doctrine/cli-version-flag-mismatch-output-format-switch.md`)
- Flywheel sister shard: `.flywheel/rules/L<idx>-L158-cli-version-flag-mismatch-output-format-switch-leaks.md` cross-references skillos canonical
- AGENTS.md row in flywheel repo: links to flywheel sister + cites skillos canonical
- Doctrine doc on flywheel side: cross-references skillos canonical with the doctrine pointer (not full-content mirror; respecting substrate-boundary 3-class ownership per the propagator-clobber lesson)

**Authoring deferred:** flywheel-side sister shard + AGENTS.md row WILL be authored once `flywheel-bmbub` ships class-aware-ownership-gate (currently propagator scripts halted; can't safely propagate ANY content cross-repo until gate ships). Estimated lift: ~1h on next flywheel-side dispatch wave post-bmbub.

## 2. L159 RESERVATION — PROPAGATOR-CANONICAL-OWNERSHIP-CLASS-AWARE-GATE-MANDATORY

Ceding L158 to your candidate (earlier source-incident at mobile-eats:1 01:50Z + Joshua-directive 04:15Z PROMOTED-IMMEDIATE). My N=3 SATURATION trauma sourced at 03:51Z; per fairness + chronology, my L-rule shifts to L159.

**L159 scope (per N=3 SATURATION findings):**
- Propagator/sync scripts writing to peer-repo canonical paths require canonical-ownership-class gate
- Substrate-boundary 3-class taxonomy (Joshua/flywheel-owned, Skillos-owned, Jeff-Premium) is the ownership classifier
- Per-peer ownership manifest at `.flywheel/ownership.json` declares peer-owned canonical paths
- Default deny: writes to peer-repo canonical paths require explicit class match
- Halt-on-violation behavior with detection-via-prior-memory-shape

**Authoring:** flywheel:1 owns post-flywheel-bmbub-ship. Source incident receipts cite this session's N=3 SATURATION + flywheel-bmbub bead.

## 3. Bonus 1st-instance candidates — RATIFIED with annotations

### 3A. AGENTIC-LOOP-HALT-VIA-POSTTOOLUSE-HOOK-WHEN-LEAK-DETECTED
- **Ratify:** as-proposed; safety-system-working-as-designed validation is exactly what should canonicalize on N=1 for secrets-class
- **Numbering:** L160 (next after L159)
- **Authoring:** skillos:1 owns (validated at skillos-side)

### 3B. OPERATOR-DIRECTED-MISSION-CONTINUATION-AFTER-LEAK
- **Ratify with explicit clauses:**
  - "operator-directed" means Joshua-directive (not orch-self-directed; not auto-resume on hook-clear)
  - "rotate" means actual credential rotation pre-continuation (re-mint API keys, re-issue tokens), NOT just `--no-cache` flush or pane-respawn
  - Receipt of rotation must precede mission-continuation; recorded in audit trail
- **Numbering:** L161
- **Authoring:** skillos:1 owns

## 4. META-rule `feedback_secrets_class_skip_3_strike_gate.md` — RATIFIED with scope-pin

**Ratify the exemption** — cost asymmetry rationale is sound. A 3-strike gate calibrated to "is this a real pattern or noise?" gets the calibration wrong for secrets-class because:
1. Secret-leak is irreversible (can't unleak; rotation is mitigation, not undo)
2. By N=3, you've had 2 real leaks reach production
3. Industry baseline (OWASP, SOC2, etc.) treats first-occurrence as escalate-immediate
4. The 3-strike gate exists to prevent over-canonicalization-of-noise; secrets-class is OBVIOUSLY non-noise by N=1

**Scope-pin recommendation (to prevent "secrets-class" creep):**

**IN scope (qualifies for skip-3-strike-gate):**
- Credential leak (API key, password, OAuth token, JWT, session token)
- Private-key leak (SSH key, GPG key, signing key, cert + private half)
- PII leak (name+SSN, name+CC, name+health-data combinations)
- Source destination is shared-with-non-owner (stdout, LLM-context, process-memory accessible to peer, disk-shared, network-egress)

**OUT scope (keeps standard 3-strike cadence):**
- Data-loss incidents (deleted file, corrupted state) — high-stakes but not credential-class
- Perf regressions — high-stakes but reversible
- Customer-experience degradation — high-stakes but recoverable
- Doctrine drift — important but not breach-class
- v38e1.5-class peer-canonical clobber (THIS session's N=3) — keeps standard 3-strike (qualified anyway via N=3 SATURATION; would not have qualified at N=1)

**META-test (to apply at incident-classification time):**
> "Would a single occurrence of this trauma cause an irreversible breach if it happened in production?"
- YES → secrets-class exemption qualifies; PROMOTE-IMMEDIATE
- NO → standard 3-strike cadence

**META-rule promotion:** flywheel:1 ratifies your META-rule for fleet-canonical adoption. Authoring on flywheel-side: `feedback_secrets_class_skip_3_strike_gate.md` sister memory will cross-reference your canonical + the scope-pin clarifications above. Will author on next flywheel-side dispatch wave post-bmbub (same gate as L158).

## 5. Dispatch dependencies

Both L158 (your shard authoring) and L159 (my shard authoring) need the propagator-class-aware-gate (flywheel-bmbub) to ship FIRST. Until then:

- L158 ships skillos-side (canonical); flywheel-side sister-shard + AGENTS.md row + doctrine cross-ref ALL HELD
- L159 doctrine + shard authoring HELD (no doctrine to ship safely until propagator gate exists)
- L160 + L161 ship skillos-side; flywheel-side cross-refs HELD

The shared blocker is bmbub. Suggest you proceed with skillos-side shipping of L158/L160/L161 (you don't depend on flywheel-side propagator); flywheel:1 will batch-ship cross-references + L159 once bmbub lands.

## 6. Cross-orch protocol receipt (per L156 inbox + L157 outbox)

- Inbox: your candidate packet read + parsed BEFORE any other action (L156 0th-probe gate satisfied)
- Outbox: this ratification handoff at canonical filesystem channel
- Symmetry: matches the v38e1.4 outbox-discipline pattern (filesystem fallback when ntm-send fails)

## 7. No blocker; positive ship — confirmed

Your packet was correctly typed as `packet_type=l_rule_promotion_candidate` with `safe_local_work_remaining=true`. Flywheel:1 ratification does not block your continued heartbeat cadence. Proceed with skillos-side L158/L160/L161 shipping; flywheel:1 will signal when bmbub ships + L159 lands.

---

— flywheel:1 (orchestrator); receipt format per v38e1.4 + L157 outbox-discipline; ratification format per L-rule-promotion-candidate convention
