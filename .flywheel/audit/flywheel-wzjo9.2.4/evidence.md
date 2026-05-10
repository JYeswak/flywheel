---
title: recovery-install-plist-alpsinsurance.sh canonical-CLI scaffold + 18-TODO fillin
type: evidence
bead: flywheel-wzjo9.2.4
task: flywheel-wzjo9.2.4-91ab0f
priority: P2
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
parent_wave: flywheel-wzjo9.2 (wave-2.0b)
sister_wave_2_0b_avg: 990 (3/9 closed)
family: recovery-install-plist-* (alpsinsurance, clutterfreespaces, mobile-eats, skillos)
followup_bead: flywheel-mbt3z (family canonical-cli extract — ~1800 lines duplication)
---

# Evidence — flywheel-wzjo9.2.4

## Surface

| Attribute | Value |
|---|---|
| Path | `.flywheel/scripts/recovery-install-plist-alpsinsurance.sh` |
| Lines (before) | 237 |
| Lines (after) | 663 |
| Pre status | canonical_cli_scoping=missing |
| Post status | canonical_cli_scoping=passing (full surface filled) |
| Verb collisions | NONE |
| Family member | 1 of 4 (sister: clutterfreespaces, mobile-eats, skillos) |

## Acceptance gates

| Gate | Result | Evidence |
|---|---|---|
| AG1: 18 TODO markers replaced | ✓ | TODO 18→0 (incl. meta-comment paraphrased) |
| AG2: bash -n exits 0 | ✓ | syntax-ok |
| AG3: lint exits 0 | ✓ | 0 violations |
| AG4: tests >= 13 PASS | ✓ | 19/19 PASS (13 baseline + 6 fillin) |
| AG5a: doctor 7 named probes | ✓ | python3, launchctl, launch_agents_dir_writable, repo_exists, ntm_executable, audit_script_executable, plist_label_valid |
| AG5b: health binds audit log | ✓ | tails $SCAFFOLD_AUDIT_LOG; >24h stale → warn |
| AG5c: repair scope-specific | ✓ | 2 scopes (log_dir, audit_log_dir); apply-contract enforced |
| AG5d: validate per-subject | ✓ | 3 subjects (plist-config, repo-path, audit-row) |
| AG5e: audit cli_emit_audit_tail | ✓ | path-then-schema positional order |
| AG5f: why provenance | ✓ | found / not_found / unavailable |

## Per-client identity preservation

The script is a per-client variant (alpsinsurance) of a 4-script family.
The fillin captures the per-client identity in:
- `doctor.session = "alpsinsurance"` (named output field)
- `validate plist-config` enforces label pattern `com.zeststream.<session>.watcher`
- `validate repo-path` defaults to `/Users/josh/Developer/alpsinsurance`
- Schema's `default` envelope notes the specific session purpose

A regression test (test 16) explicitly asserts `session=alpsinsurance` to
guard per-client identity going forward.

## Family-refactor follow-up

Per dispatch hint: 4 nearly-identical sister scripts (alpsinsurance,
clutterfreespaces, mobile-eats, skillos) at ~240 lines each + my ~300-line
fillin → ~2400 lines of near-duplicate canonical-cli code across the 4.
Filed **flywheel-mbt3z (P3)** to extract a shared helper at
`.flywheel/lib/recovery-install-plist-canonical-cli.sh` that takes per-client
config (label, session, default_repo, default_ntm, default_audit_script).
Estimated savings: ~1800 lines net + single point of fix.

The natural-unit META-RULE keeps THIS bead at one-surface scope; the family
extract is a follow-up that should activate when one worker takes ≥2 family
sister beads in one tick (or as standalone work).

## L112 verify probe

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/recovery-install-plist-alpsinsurance.sh \
  && grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/recovery-install-plist-alpsinsurance.sh | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/recovery-install-plist-alpsinsurance.sh \
  && bash tests/recovery-install-plist-alpsinsurance-canonical-cli.sh \
  && echo "AG1-5 PASS"
# expected: AG1-5 PASS + SUMMARY pass=19 fail=0
```
