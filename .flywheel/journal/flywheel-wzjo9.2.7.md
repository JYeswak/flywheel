# Journey entry — flywheel-wzjo9.2.7

**Bead**: P2 wave-2.0b-g (parent: flywheel-wzjo9.2). Last of install-plist family (2.4-2.7).
**Surface**: `.flywheel/scripts/recovery-install-plist-skillos.sh` — bash wraps python3 heredoc; installs skillos watcher plist + emits `recovery-session-watcher-install/v1` receipt.
**Sister wave-2.0b 5/9 closed avg 992**. Family pattern from sister 2.5 (clutterfreespaces).
**Result**: 27/27 in-bead PASS + 128 sister assertions clean; 1000/1000.

## Arc

1. **Inspect** — 224 lines; bash-wraps-python; identified 2 skillos-specific defaults beyond family core: `DEFAULT_JSM`, `DEFAULT_SKILLS_FLYWHEEL`. These map to a `readiness.skillos_management` clause in the python (line 96).
2. **Scaffold + apply** — 224 → 470 lines, 18 TODOs, baseline 13/13.
3. **Family template clone** — copied sister 2.5's `RIPC_*` shape to `RIPS_*` with skillos defaults.
4. **Skillos extras** — 2 new module vars (`RIPS_JSM_BIN`, `RIPS_SKILLS_FLYWHEEL`) + 2 new doctor probes (jsm_bin_executable, skills_flywheel_readable) + new validate subject `skillos-management` + new why id `skillos_management`. Cleanly 1:1 with python's per-client readiness clause.
5. **Substantive fillin** identical to 2.5 + skillos delta:
   - 14-probe doctor (12 family + 2 extras)
   - 4 validate subjects (3 family + 1 skillos-management)
   - 7 why ids (6 family + 1 skillos_management)
   - 3 repair scopes (identical to family)
   - Schema status variant uniquely declares `skillos_management:{type:"object"}` field
6. **Test extension** — 13 → 27. New tests include 3 skillos-unique: skillos-management subject envelope, skillos-management with missing jsm → fail, why-skillos_management cites both "jsm" and "skills-flywheel" substrings.
7. **Verify** — AG1-5 PASS, 27/27 in-bead, 128 sister assertions clean.

## Discoveries

None this bead. Pattern was established by 2.5; this bead proves the family-template-with-per-client-deltas approach replicates cleanly for variants with extra substrate. Legal no-discovery reason: task stayed inside existing canonical-cli-scoping + scaffold-canonical-cli skills.

## Family pattern formalized

The install-plist family (2.4 alpsinsurance, 2.5 clutterfreespaces, **2.7 skillos**, plus likely future 2.6 mobile-eats etc) demonstrates a reusable approach:

```
Family core (verbatim across all family members):
- 13 RIP*_* env-mirror vars (session/label/repo/plist/status/audit/etc)
- 6 schemas + status variant
- 7 topic_help bodies
- 12 doctor probes
- 3 repair scopes (log-dir/audit-log/status-receipt-dir)
- 3 validate subjects (plist/audit-receipt/config)
- 6 why ids (label/audit/dry_run_pass/repo/watcher_race/install_flow)
- 5 cli_audit_append wires

Per-client deltas (varies):
- Any extra DEFAULT_* python constants → extra RIP*_* vars
- One doctor probe per extra dependency
- Optional validate subject named after the per-client readiness clause
- Optional why id explaining the per-client rationale
- 2-3 extra test assertions per delta
```

Total fillin time after the first family member: ~30-45 min (vs 30-60 min for the template-establisher).

## Wave-2.0b status update

After this bead: **6/9 closed** (2.2, 2.5, 2.7, plus 3 prior). 2.4 in flight pane 4 (alpsinsurance — also install-plist family). Remaining: 2.6, 2.8, 2.9 non-install-plist work.

## Cross-bead patterns

| Pattern | Variant | Beads |
|---|---|---|
| Install-plist family template | bash-wraps-python no-collision | 2.5 (clutterfreespaces), **2.7 (skillos)** |
| Per-client delta extension | extra doctor probes + validate subject + why id | **2.7 (skillos: jsm + skills-flywheel)** |
| 1:1 python-readiness-clause → bash-validate-subject | python's compound readiness → bash subject | **2.7 (formalized)** |
