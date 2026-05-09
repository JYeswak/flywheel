# flywheel-2xdi.10 compliance pack

Task: `flywheel-2xdi.10-94b069`
Bead: `flywheel-2xdi.10`
Identity: `CloudyMill`
Date: 2026-05-09

## Scope

Fix for `[gap-cross-source-silos] gap-hunt-false-positives.jsonl`.

The gap-hunt probe had learned from `/Users/josh/.local/state/flywheel/gap-hunt-false-positives.jsonl` but still let the cross-source-silos scan classify that tuning ledger as an orphan. This made the false-positive suppression ledger itself generate a gap.

## Change

Updated `.flywheel/scripts/gap-hunt-probe.sh` so `probe_cross_source_silos` skips both:

- `gap-hunt.jsonl`
- `gap-hunt-false-positives.jsonl`

This preserves cross-source-silos detection for ordinary state ledgers while preventing the probe's own feedback/tuning ledger from being re-filed as an orphan.

## Evidence

| Claim | Evidence |
|---|---|
| Source ledger exists | `/Users/josh/.local/state/flywheel/gap-hunt-false-positives.jsonl` exists with 4 rows. |
| Ledger is consumed by probe logic | `.flywheel/scripts/gap-hunt-probe.sh:523-565` implements the suppressions described by the false-positive ledger. |
| Root defect existed | Before patch, `probe_cross_source_silos` skipped only `gap-hunt.jsonl` and could emit `cross-source-silos:gap-hunt-false-positives.jsonl`. |
| Patch is narrow | Only the skip set in `probe_cross_source_silos` changed. |
| Target gap no longer appears | `GAP_HUNT_AUTO_BEAD_CAP=0 .flywheel/scripts/gap-hunt-probe.sh --dry-run --json | jq -e '([.gaps_by_class["cross-source-silos"][]?.id] | index("cross-source-silos:gap-hunt-false-positives.jsonl") | not)'` returned `true`. |

## Acceptance Gates

AG1: Pass. Confirmed the ledger exists and the auto-filed gap was a false positive against the probe's own tuning ledger.

AG2: Pass. Patched the source that emitted the false positive.

AG3: Pass. Ran syntax, dry-run probe, dispatch-template audit, and L112 probe.

## Verification Commands

```bash
bash -n .flywheel/scripts/gap-hunt-probe.sh
GAP_HUNT_AUTO_BEAD_CAP=0 .flywheel/scripts/gap-hunt-probe.sh --dry-run --json | jq -e '([.gaps_by_class["cross-source-silos"][]?.id] | index("cross-source-silos:gap-hunt-false-positives.jsonl") | not)'
bash .flywheel/receipts/flywheel-2xdi.10/l112-probe.sh
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-2xdi.10-94b069.md
```

## Skill Auto-Routes

`canonical-cli-scoping=n/a`: the patch does not change CLI flags, JSON shape, mutation semantics, or command help.

`rust-best-practices=n/a`: no Rust files changed.

`python-best-practices=n/a`: embedded Python behavior changed inside an existing shell probe; no standalone Python module/API changed.

`readme-writing=n/a`: no README changed.

## L61 Surface

No doctrine, canonical L-rule, skill, AGENTS, README, or `INCIDENTS.md` source was modified. `agents_md_updated=not_applicable`, `readme_updated=not_applicable`, `no_touch_reason=probe_fix_only_no_doctrine_or_public_readme_surface`.

## L52 / L53

No new bead was filed. The current bead directly owned the false-positive gap and the patch resolves it.

No fuckup row was logged.

## Four-Lens Self-Grade

`four_lens=brand:8,sniff:8,jeff:8,public:8`

Brand: reduces noisy self-filed gaps in the constant gap hunter.

Sniff: proves the target gap is absent from current dry-run JSON rather than relying on prose.

Jeff: keeps the feedback ledger as useful tuning data instead of deleting or hiding it.

Public: a skeptical operator, maintainer, and future worker can rerun the probe and see the target ID is absent.

## Compliance Score

`820/1000`

The change is narrow, source-backed, and verified with the script's own JSON output.
