# Canonical Doctrine Drift Research - 2026-05-06

Task: `canonical-doctrine-drift-research-2026-05-06`  
Bead: `flywheel-2l9en`  
Status: research_complete_blocked_on_joshua_decision

## A. What `canonical_doctrine_drift_local` Measures

Source inspected: `/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop`.

`canonical_doctrine_state()` compares the canonical source from
`canonical_doctrine_path()` with this repo's `.flywheel/AGENTS-CANONICAL.md`.
The default source is `/Users/josh/Developer/flywheel/AGENTS.md`, overridable by
`FLYWHEEL_CANONICAL_DOCTRINE_PATH`. It does not compare `.flywheel/doctrine/`.

Method: whole-file SHA-256. If source and snapshot hashes match, state is
`canonical_doctrine_synced`. If either file is absent, state is
`canonical_doctrine_missing`. If the local snapshot SHA differs from the most
recent `.flywheel/lock-log.jsonl` row for `.flywheel/AGENTS-CANONICAL.md`, state
is `canonical_doctrine_drift_local`. Otherwise, an optional
`# source_sha256:` header decides upstream-vs-local drift; when the header is
missing, the function falls back to `canonical_doctrine_drift_upstream`.

Observed hashes:

- source `AGENTS.md`: `305b882b4f3836be3de0994b5b1548c08b5152bc492494c938b2c75db3d766a2`
- local snapshot `.flywheel/AGENTS-CANONICAL.md`: `0dc83e25088d032cbca91e1cf9ab2aca84658a96ea9f8be94067be1867a77941`
- lock-log snapshot SHA: `b9cdc7ab838c3d41f3aaee82f86542cd84fd2c667ce4998ab2a5222e5493b6a9`
- local snapshot header source SHA: absent

So `drift_local` means the local snapshot was edited or generated outside its
last lock-log render, not merely that upstream moved. The doctor also runs
`.flywheel/scripts/doctrine-3-surface-divergence-probe.sh`, which separately
compares L-rule ID sets across `AGENTS.md`, `.flywheel/AGENTS-CANONICAL.md`,
and `templates/flywheel-install/AGENTS.md`.

## B. Live Drift Surface

Full primary unified diff, no omitted hunks:

```diff
diff --git a/AGENTS.md b/.flywheel/AGENTS-CANONICAL.md
index 3d1a864..6a81f4d 100644
--- a/AGENTS.md
+++ b/.flywheel/AGENTS-CANONICAL.md
@@ -10,0 +11,5 @@ Domain rules (what we're building, not how we operate) belong in CLAUDE.md.
+Fleet propagation cross-link: `.flywheel/scripts/agents-md-fleet-propagator.sh`
+audits installed-repo AGENTS.md drift, and `flywheel-loop doctor --scope
+agents-md-fleet-propagation --json` exposes the drift count, drift repos, and
+last propagation apply health.
+
@@ -1151,0 +1157,10 @@ the same session: "I can't have this being a constant problem."
+**Counter cross-link:** `.flywheel/scripts/l70-ticks-punted-counter.sh` writes
+`~/.local/state/flywheel/l70-ticks-punted.jsonl`; `flywheel-loop doctor --scope
+l70-ticks-punted --json` exposes `l70_ticks_punted_24h`,
+`l70_ticks_punted_rate_pct`, and `l70_ticks_punted_top_signal`.
+`.flywheel/scripts/tick-hook-firing-verifier.sh` audits L70 and sibling
+tick-close hooks with ledger-backed firing evidence; `flywheel-loop doctor
+--scope tick-hook-firing --json` exposes `tick_hook_primitives_audited`,
+`tick_hook_primitives_firing`, `tick_hook_primitives_invisibly_broken`, and
+`tick_hook_primitives_invisibly_broken_names`.
+
@@ -3113,0 +3129,3 @@ callbacks missing those fields.
+- Validator path: `.flywheel/scripts/callback-envelope-schema-validator.sh`;
+  scoped doctor:
+  `flywheel-loop doctor --repo <repo> --scope callback-envelope-schema --json`.
@@ -3197,5 +3215,11 @@ canonical pre-flight before `/flywheel:respawn` targets a peer
-**Doctor contract:** `flywheel-loop doctor --scope peer-orch-recovery --json`
-MUST expose `peer_orch_recovery_count_24h`, `last_peer_orch_recovery_ts`,
-`peer_orch_recovery_targets_top`, and
-`peer_orch_recovery_self_refuse_count_24h`. Status is `warn` when recovery
-count exceeds 5 in 24h and `fail` when self-refuse count is nonzero.
+**Doctor contract:**
+
+`flywheel-loop doctor --scope peer-orch-recovery --json` MUST expose:
+
+- `peer_orch_recovery_count_24h`
+- `last_peer_orch_recovery_ts`
+- `peer_orch_recovery_targets_top`
+- `peer_orch_recovery_self_refuse_count_24h`
+
+Status is `warn` when `peer_orch_recovery_count_24h > 5`; status is `fail` when
+`peer_orch_recovery_self_refuse_count_24h > 0`.
@@ -3220 +3244,5 @@ validated recovery of `skillos:1` at 2026-05-05T04:39Z; permit gate
-**Cross-references:** L48, L57, L70, L75, L80, L82, L101, L107, and L110.
+**Cross-references:** L48 (substrate exhaustion), L57 (loop state marker is not
+a driver), L70 (same-tick chain-forward), L75 (peer-orch blocker
+coordination), L80 (DID/DIDNT/GAPS callbacks), L82 (canonical CLI scoping),
+L101 (continuous fleet productivity), L107 (shared-surface reservations), and
+L110 (substrate primitives declare self-repair loop).
@@ -3267,5 +3295,15 @@ For fleet shutdown/reboot recovery, the canonical repo-local state path is
-**Doctor contract:** `flywheel-loop doctor --scope tick-driver --json` MUST
-expose `tick_driver_daemon_loaded`, `tick_driver_last_exit_status`,
-`tick_driver_last_fire_ts`, `tick_driver_fires_24h_count`,
-`tick_driver_expected_fires_24h`, `tick_driver_fire_rate_pct`, and
-`tick_driver_stalled_class_emitted_count_24h`.
+**Doctor contract:**
+
+`flywheel-loop doctor --scope tick-driver --json` MUST expose:
+
+- `tick_driver_daemon_loaded`
+- `tick_driver_last_exit_status`
+- `tick_driver_last_fire_ts`
+- `tick_driver_fires_24h_count`
+- `tick_driver_expected_fires_24h`
+- `tick_driver_fire_rate_pct`
+- `tick_driver_stalled_class_emitted_count_24h`
+
+Status is `error` when the daemon is not loaded, when the latest fire is older
+than two intervals, or when the normalized fire rate is below 50%. Status is
+`warn` when the normalized fire rate is below 80%.
@@ -3288,2 +3326,4 @@ expose `tick_driver_daemon_loaded`, `tick_driver_last_exit_status`,
-**Cross-references:** L57, L70, L102, L110, L111, L115, and pbt55
-`tick-hook-firing-verifier.sh`.
+**Cross-references:** L57 (loop-state marker is not driver), L70 (same-tick
+chain-forward), L102 (META-RULE cache refresh on tick), L110 (substrate
+self-repair primitive), L111 (quality bar), L115 (peer-orch recovery), and
+pbt55 `tick-hook-firing-verifier.sh`.
@@ -3313,3 +3353,11 @@ is run with `--apply`, `PEER_ORCH_AUTO_RESPAWN=1` is present, and
-MUST expose `monitor_last_fire_ts`, `mttr_p95_seconds`,
-`false_recovery_count_24h`, `permit_gate_refusals_24h`, `recoveries_24h`, and
-`monitor_alive`.
+MUST expose:
+
+- `monitor_last_fire_ts`
+- `mttr_p95_seconds`
+- `false_recovery_count_24h`
+- `permit_gate_refusals_24h`
+- `recoveries_24h`
+- `monitor_alive`
+
+Status is `fail` when false recoveries are nonzero, `warn` when the monitor is
+missing or stale, and `pass` only when recent monitor fire evidence exists.
@@ -3330,47 +3378,3 @@ MUST expose `monitor_last_fire_ts`, `mttr_p95_seconds`,
-**Cross-references:** L57, L110, L111, L115, L116, and pbt55
-`tick-hook-firing-verifier.sh`.
-
-## L118 — STABLE-FAILURE-REASON-CODES-BEFORE-PROSE
-
----
-id: L118
-title: Stable failure reason codes before prose
-status: long_term
-shipped: 2026-05-05
-review_due: 2026-11-05
-trauma_class: prose-only-failure-taxonomy
----
-
-Every agent-readable failure surface MUST carry a stable, machine-parseable
-reason code before or beside prose. Human explanation is useful, but a loop,
-validator, or downstream worker needs a durable enum to route the failure
-without re-parsing English.
-
-**How to apply:**
-- New doctor, probe, validator, callback, and repair JSON that can report
-  `warn`, `fail`, `blocked`, or `refuse` MUST expose `reason_code` or a named
-  equivalent field such as `failed_signal`, `violation.class`, `trauma_class`,
-  or `blocked_by`.
-- Prefer lowercase snake_case or kebab-case codes already used by the substrate;
-  introduce a new enum only when no existing code captures the failure.
-- When prose changes but the operational class is unchanged, keep the code
-  stable. When a code changes meaning, ship a schema or migration note.
-- Beads filed from failures SHOULD include the code in the title or labels so
-  repeated failures group mechanically.
-
-**Forbidden outputs:**
-- Routing a recurring failure from prose-only strings like "still broken" or
-  "could not validate".
-- Adding a new validator or doctor field whose failure classes cannot be
-  counted with `jq` or `rg` without natural-language parsing.
-- Renaming an existing failure code without a compatibility alias or migration
-  note.
-
-**Evidence:** Source: Jeff frankensearch:frankensearch/frankensearch/src/index_builder.rs:176 + ZestStream adaptation.
-The code-shaped failure pattern appears in the philosophy catalog as
-`failure-taxonomy-reason-codes`; flywheel adopts it
-for callbacks, doctor JSON, validators, and Beads routing so L52/L53 findings
-group by substrate class instead of prose.
-
-**Cross-references:** L50, L52, L53, L56, L60, L64, L71, L80, L111, and
-`dicklesworthstone-stack`.
+**Cross-references:** L57 (loop-state marker is not driver), L110 (substrate
+self-repair primitive), L111 (quality bar), L115 (peer-orch recovery), L116
+(tick is process), and pbt55 `tick-hook-firing-verifier.sh`.
```

The 3-surface probe adds: `missing_in_canonical=["L118"]`,
`missing_in_template=["L111"]`, `doctrine_3_surface_divergent_count=2`.

## C. Drift Class Taxonomy

Primary diff categorized 130 changed content lines:

| Class | Count | Lines |
|---|---:|---|
| additive_local | 36 | Fleet propagation cross-link; L70 counter cross-link; L111 validator path; added explicit L116/L117 status contracts and descriptive cross-reference text. |
| stale_local | 47 | L118 exists in `AGENTS.md` but is absent from `.flywheel/AGENTS-CANONICAL.md`. |
| mutually_exclusive | 0 | No hunk asserts incompatible rules; all conflict is missing/additive/format. |
| formatting_only | 47 | L115-L117 doctor contract lists and cross-reference expansions preserve the same fields while changing layout. |

Secondary 3-surface taxonomy: template is missing L111 as an L-rule ID; the
root-vs-template `-U0` diff is 132 lines, including 112 L111 lines and 13 older
L93/L94 prose-note lines. That diff is printed by the dry-run script.

## D. Cascading-Effect Probe

`.flywheel/scripts/fleet-l-rule-lag-probe.sh --json` found one laggard:
`/Users/josh/Developer/alpsinsurance-celery-fix`.

It is missing L98, L100, L101, L102, L103, L104, L105, L106, L107, L108, L110,
L111, L115, L116, and L117 from its root `AGENTS.md`.

If local doctrine ships upstream, this laggard does not auto-cure. The lag probe
reads source `.flywheel/AGENTS-CANONICAL.md` and compares peer root
`AGENTS.md`; a peer propagation apply is still required. Adding L118 to the
canonical snapshot would likely increase the laggard's missing set until sync
runs.

## E. Reconciliation Options Matrix

| Option | Move | Blast radius | Reversible | Joshua decision |
|---|---|---|---|---|
| Forward-flow | Promote local snapshot additions into root `AGENTS.md`, then update template/canonical together. | Changes canonical doctrine source and future installs. | Git revertable. | Yes, because additive lines become canonical. |
| Reverse-flow | Restore `.flywheel/AGENTS-CANONICAL.md` from root `AGENTS.md`; add L111 to template only if approved by 3-surface gate. | Local snapshot/template only. | Git revertable. | Yes, because it deletes local-only additions unless preserved elsewhere. |
| Hybrid | Preserve additive operational links if approved, restore formatting-only hunks to root style, add L118 to canonical, add L111 to template. | Most precise; touches all doctrine surfaces in follow-up. | Git revertable but requires careful pathspec commit. | Yes. |
| No-op | Keep drift documented and defer mutation. | None now; drift remains. | N/A. | Yes, if doctrine churn risk is higher than drift risk today. |

## F. Recommended Option

Recommend Hybrid. L118 missing from canonical and L111 missing from template are
real stale surface gaps. The fleet/L70/validator/status additions look useful,
but they should not become canonical by accident from a drifted snapshot. Hybrid
separates "promote useful local additions" from "restore stale surfaces" and
keeps L96's three-surface rule intact.

Joshua-decision-needed: true.

## G. Dry-Run Reconciliation Script

Artifact: `/tmp/canonical-doctrine-reconcile-dry-run-2026-05-06.sh`.

It prints source hashes, rule-set drift, root-vs-canonical and root-vs-template
unified diffs, and the three options above. It performs no writes and makes no
doctrine mutations.

