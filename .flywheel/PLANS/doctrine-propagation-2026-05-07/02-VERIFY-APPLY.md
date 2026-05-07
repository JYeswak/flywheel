# Doctrine Sync Apply Verification — 2026-05-07

Read-only verification of the 20:00Z apply pass across:
`alpsinsurance`, `mobile-eats`, `zesttube`, and `polymarket-pico-z`.

## Section 1 — Per-repo verification

| Repo | append_position_correct | markdown_integrity | stamp_present | three_surface_clean | receipt_valid | overall |
|---|---|---|---|---|---|---|
| alpsinsurance | yes — tail `L125,L126`; footer present | yes — root/canonical `75/75`, fences `6/6`, no duplicate headings | yes — `2026-05-07.L126` | yes — watchdog `pass`, drift `0` | yes — key `sync-2026-05-07T20-00Z`, appended `2/2` | PASS |
| mobile-eats | yes — tail `L119-L126`; footer present | no — root/canonical `142/75`; root has 67 duplicate L headings; fences even `12/6` | yes — `2026-05-07.L126` | partial — root/canonical clean; optional local template stale by 8 rules | yes — key `sync-2026-05-07T20-00Z`, appended `8/8` | WARN |
| zesttube | yes — tail `L119-L126`; footer present | no — root/canonical `138/75`; root has 63 duplicate L headings; fences even `12/6` | yes — `2026-05-07.L126` | yes — watchdog `pass`, drift `0` | yes — key `sync-2026-05-07T20-00Z`, appended `8/8` | WARN |
| polymarket-pico-z | yes — tail `L119-L126`; footer present | no — root/canonical `138/75`; root has 63 duplicate L headings; fences even `12/6` | yes — `2026-05-07.L126` | yes — watchdog `pass`, drift `0` | yes — key `sync-2026-05-07T20-00Z`, appended `8/8` | WARN |

Notes:

- The appended L-rule cohort is correctly ordered in all four repos. The full canonical sequence is historically not globally numeric (`L48` precedes `L29`), so this check was scoped to the newly appended tail as requested by the examples `L119-L126` and `L125-L126`.
- No unclosed code fences were found. All fence counts are even.
- No heading-bleed pattern was observed from the L-heading parse; each appended heading parsed as its own L-rule block.
- Provenance footer on each touched surface: `# Pulled from flywheel/templates/flywheel-install/AGENTS.md@11d3153`.

## Section 2 — Issues discovered

1. Repo: `mobile-eats`
   Surface: root `AGENTS.md`
   What's wrong: root has 142 L-rule headings while `.flywheel/AGENTS-CANONICAL.md` has 75. Duplicate headings cover 67 IDs, `L29` through `L118`. This is consistent with the known thin-root-vs-full-canonical drift class, not with the 20:00Z append tail; appended `L119-L126` are positioned correctly.
   Severity: medium
   Proposed remediation: file a follow-up bead to thin root `AGENTS.md` to repo-local content plus canonical pointer, preserving `.flywheel/AGENTS-CANONICAL.md` as the full canonical snapshot.

2. Repo: `mobile-eats`
   Surface: `templates/flywheel-install/AGENTS.md`
   What's wrong: optional local install template is stale by 8 L-rules under `canonical-meta-rules/sync.sh --check-three-surface`. Root and `.flywheel/AGENTS-CANONICAL.md` are clean.
   Severity: low
   Proposed remediation: file a follow-up bead to decide whether peer repos should carry install templates at all; if yes, propagate `L119-L126` to the local template in a separate reviewed pass.

3. Repo: `zesttube`
   Surface: root `AGENTS.md`
   What's wrong: root has 138 L-rule headings while `.flywheel/AGENTS-CANONICAL.md` has 75. Duplicate headings cover 63 IDs, `L29` through `L111`. The append tail `L119-L126` is correct.
   Severity: medium
   Proposed remediation: file a follow-up bead to thin root `AGENTS.md` to repo-local content plus canonical pointer.

4. Repo: `polymarket-pico-z`
   Surface: root `AGENTS.md`
   What's wrong: root has 138 L-rule headings while `.flywheel/AGENTS-CANONICAL.md` has 75. Duplicate headings cover 63 IDs, `L29` through `L111`. The append tail `L119-L126` is correct.
   Severity: medium
   Proposed remediation: file a follow-up bead to thin root `AGENTS.md` to repo-local content plus canonical pointer.

No same-day destructive remediation is recommended. The apply pass did not corrupt the appended cohort, receipts, or doctrine stamps.

## Section 3 — Confidence assessment

The four repos are safe to leave as-is until tomorrow's session.
The doctrine appends and `STATE.json` stamps landed correctly; no receipt, fence, or appended-tail ordering failure was found.
Tomorrow's continuation should handle root `AGENTS.md` duplication as cleanup/planning work before broadening to the skillos cohort.

## Section 4 — Skillos pre-cohort baseline

No modifications were made to skillos.

| Surface | Exists | Lines | L-rule count | Last L-rule | Duplicate headings | Code fences | Doctrine stamp |
|---|---:|---:|---:|---|---:|---:|---|
| `AGENTS.md` | no | n/a | n/a | n/a | n/a | n/a | n/a |
| `.flywheel/AGENTS-CANONICAL.md` | yes | 650 | 67 | `L117` at line 646 | 0 | 0 | n/a |
| `.flywheel/STATE.json` | no | n/a | n/a | n/a | n/a | n/a | absent |

Skillos baseline implication: it is not ready for blind bulk apply. It lacks root
`AGENTS.md`, lacks `.flywheel/STATE.json`, and its canonical snapshot currently
ends at `L117`.

## Evidence commands

```bash
grep -c '^## L[0-9]' <repo>/AGENTS.md
grep -c '^## L[0-9]' <repo>/.flywheel/AGENTS-CANONICAL.md
awk '/^```/' <surface> | wc -l
jq '.doctrine_version' <repo>/.flywheel/STATE.json
/Users/josh/.flywheel/canonical-meta-rules/sync.sh --check-three-surface --target <repo> --json
jq '{status,apply,appended,state:.state_json,missing_l_rules_count,missing_l_rules,provenance_footer}' <repo>/.flywheel/receipts/doctrine-sync/sync-2026-05-07T20-00Z.json
```
