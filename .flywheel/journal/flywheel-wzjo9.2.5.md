# Journey entry — flywheel-wzjo9.2.5

**Bead**: P2 wave-2.0b-e (parent: flywheel-wzjo9.2, lane: flywheel-wzjo9). Second of install-plist family (2.4/2.5/2.6/2.7 — 4 near-identical per-client variants).
**Surface**: `.flywheel/scripts/recovery-install-plist-clutterfreespaces.sh` — bash wraps python3 heredoc; installs clutterfreespaces watcher plist + emits `recovery-session-watcher-install/v1` receipt without activating launchd.
**Sister wave-2.0b 3/9 closed avg 990**; sister 2.4 in flight pane 4.
**Result**: 26/26 in-bead PASS + 121 sister assertions clean; 1000/1000.

## Arc

1. **Inspect** — 236 lines: 2 bash lines (`set -euo pipefail`) + python heredoc. No canonical verbs natively → no-collision case.
2. **Scaffold + apply** — 236 → 482 lines, 18 TODOs, baseline 13/13.
3. **Pattern reuse** — sister 2.2 (recovery-baseline-snapshot) established the bash-wraps-python no-collision pattern. Reapplied directly with surface-specific substrate.
4. **Module state lift** — 13 RIPC_* vars + 3 lifted python constants (SESSION="clutterfreespaces", LABEL="com.zeststream.clutterfreespaces.watcher", STATUS_SCHEMA="recovery-session-watcher-install/v1"). Env names match the python's defaults so the scaffold and the runtime agree on substrate paths.
5. **Substantive fillin**:
   - 8 per-surface schemas incl. new `status` variant pinning the python's install-receipt schema verbatim
   - 7 single-printf topic_help bodies referencing concrete substrate paths
   - 12-probe doctor (python3 + jq + ntm_bin + ntm_config + plutil + launchctl + repo + plist_parent + audit_script + log_dir + helper + audit_log) with three-state aggregate
   - Health reads `$RIPC_STATUS` for last status; reports plist_installed + audit_log_stale
   - 3 repair scopes (log-dir / audit-log / status-receipt-dir) + none no-op; canonical refusal contract
   - 3 validate subjects (plist via real `plutil -lint`, audit-receipt via confidence threshold parsing, config inventory)
   - audit delegates to cli_emit_audit_tail (path-then-schema)
   - 6 why ids (label / audit / dry_run_pass / repo / watcher_race / install_flow) — each cites a concrete substrate fact
6. **`cli_audit_append`** wires at 5 terminal envelopes.
7. **Test extension** — 13 → 26. New: doctor 12 probes named, health structured fields, 2 live `mkdir` repair scopes, 3 validate subjects (including live `plutil -lint` test against a missing plist + JSON audit-receipt confidence parsing), `status` schema variant pin, 5-id why coverage + not_found, audit-append wired (doctor + repair).

## Discoveries

None this bead. The bash-wraps-python no-collision pattern was already established by sister 2.2. This bead is the second instance — proves the pattern replicates cleanly for the install-plist family. Beads 2.6 (mobile-eats) and 2.7 (skillos) can clone this template directly with surface-specific RIPC_* defaults swapped.

## Install-plist family pattern (established here for 2.6/2.7)

Reusable template (4 surfaces total, 2.4 in flight):

```
1. RIPC_SESSION="clutterfreespaces" → swap per client
2. RIPC_LABEL="com.zeststream.<session>.watcher" → swap per client
3. RIPC_REPO="/Users/josh/Developer/<session-or-repo>"
4. RIPC_PLIST="~/Library/LaunchAgents/com.zeststream.<session>.watcher.plist"
5. RIPC_STATUS="<repo>/.flywheel/receipts/recovery-install-<session>-status.json"
6. RIPC_AUDIT_RECEIPT="/tmp/preinstall-<session>.json"
7. Everything else (ntm, plutil, launchctl, log_dir, audit_script) identical
8. 12-probe doctor identical
9. 3-scope repair identical
10. 3-subject validate identical (with session name plumbed for confidence_per_session lookup)
11. 6 why ids identical
```

## Wave-2.0b status update

After this bead: **4/9 closed** (sisters 2.2 closed + 3 prior + this). Sister 2.4 (alpsinsurance) in flight pane 4 — likely converges on same template. 2.6 (mobile-eats) and 2.7 (skillos) ready to clone this pattern.

## Cross-bead patterns

| Pattern | Variant | Beads |
|---|---|---|
| Bash-wraps-python heredoc | scaffold above `python3 - "$@" <<'PY'` | 2.2 (baseline-snapshot), **2.5 (this)** |
| State-lift before scaffold | RIPC_* / RBS_* env-mirror vars | 2.2, **2.5** |
| 3 repair scopes for dir-creation | log-dir / audit-log / status-receipt-dir | **2.5 (first)** — likely 2.4/2.6/2.7 share this |
| Live `plutil -lint` validate subject | plist validation against real plutil | **2.5 (first)** |
| Confidence-threshold validate subject | audit-receipt JSON parsing + integer compare | **2.5 (first)** |
