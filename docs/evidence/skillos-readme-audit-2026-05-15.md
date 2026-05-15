# skillos README audit — 2026-05-15

Coverage backfill of `https://github.com/JYeswak/SkillOS/blob/main/README.md`
against flywheel's public-surface doctrine, captured as part of the
accretive watch (cycle 9). SkillOS went public on 2026-05-15 via
`gh repo rename zeststream-skillos → SkillOS` + visibility flip.

Audit run against skillos local checkout at `~/Developer/skillos/README.md`
(commit `364777c` at audit time, ~198 lines).

## Mechanical gates

| Gate | Result |
|---|---|
| Banned words (brand-voice voice.yaml `banned_words` + `banned_phrases`) | **0 hits** ✓ |
| Fleet slugs other than `skillos` itself (`alpsinsurance\|picoz\|vrtx\|mobile-eats`) | **0 hits** ✓ |
| Jeffrey Emanuel attribution presence (`Jeffrey Emanuel`, `Dicklesworthstone`, `jeffreyemanuel.com`) | **9 refs** ✓ |
| Anthropic Agent Skills standard attribution | 1 ref (line 21) ✓ |
| First-person singular voice (`I` count vs banned `we/our/we built`) | **9 first-person `I`** hits, **0 banned-pronoun** hits ✓ |
| Numeric claims (numbers/percentages/currency) that need grounding | **0** — README makes no metric claims requiring `capabilities-ground-truth.yaml` entries |

## Editorial findings

- **Hero opens on a concrete scene** ("Last month, your marketing person walked out the door") — passes II-1 (narrative transportation).
- **Customer-as-hero framing** consistent throughout — "the problem skillos is built around is the problem of the company knowledge in someone's head that walks out the door"; passes I-1.
- **Stakes before solution** — the marketing-person-leaves scene establishes stakes before introducing skillos's mechanics. Passes I-4.
- **Receipts surface present** — line 92 cites "145 mapped rows in `state/jsm-surface-mapping.jsonl`" and "103 `skillos-jsm-*` shim executables." Those are repo-local receipts (grep-verifiable). Not numbers in `capabilities-ground-truth.yaml` because they're skillos-local-state receipts, not external claims — appropriate.
- **Three explicit attributions** to Jeffrey Emanuel's stack (`jsm`, `br`, `ntm`, `cm`/`cass`, `caam`, `dcg`, `ubs`, Agent Mail, Frankensuite) with link.

## Notes

- The `skillos` lowercase fleet-slug *would* trip flywheel's
  `naming-conventions.sh` if scanned there — but flywheel's gates scan
  flywheel's public surfaces, not the skillos repo. skillos has its own
  CI/gates. The fleet-slug appears in skillos's own repo name and
  README everywhere by design (this is its product/project name).
- No skillos-specific public-surface gate at audit time examines the
  skillos README the way flywheel's `public-top-level-files.sh` does
  flywheel's. This could be a future gate-hardening item if skillos
  adds public-surface tests.

## Outcome

skillos README is **clean against flywheel's brand-voice + public-surface
doctrine at the audit time.** Safe to ship publicly without README copy
changes. Operator-photo gap noted but tracks to /about, not README.
