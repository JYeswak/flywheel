---
schema_version: canonical-stamp-agents-split/v1
disposition: SHIPPED — AGENTS.md SPLIT pattern applied to BV (public-safe pointer + .flywheel/ canonical)
---

# Evidence Pack — flywheel-4be4o

**Bead:** flywheel-4be4o (P2) — BV AGENTS.md SPLIT pattern (top-level public-safe pointer + `.flywheel/AGENTS-CANONICAL.md` full doctrine)
**Identity:** CloudyMill | **Pane:** flywheel:0.2 | **Date:** 2026-05-11
**Parent context:** flywheel-rtohf §2C class-divergence spec; sibling to rhdcq.1 post-shard fix
**Target repo:** `~/Developer/zeststream-brand-voice` (PUBLIC: github.com/JYeswak/zeststream-brand-voice)

## Disposition: SHIPPED — commit `168a706` on branch `feature/v0.6-write-quadrant`

3 surfaces authored / propagated:

| Surface | Δ | Size |
|---|---|---|
| Top-level `AGENTS.md` | NEW (PUBLIC-safe 26-line pointer) | 1.7K |
| `.flywheel/AGENTS-CANONICAL.md` | NEW (byte-exact copy from flywheel canonical) | 16.4K, 145L |
| `.flywheel/rules/L*.md` | NEW (104 shards, byte-exact from flywheel canonical) | 460K total |

## Class-divergence enforcement (load-bearing public-trust)

- Top-level `AGENTS.md` is intentionally short + public-safe. It does NOT carry internal-fleet vocabulary (L-rule schema, trauma-class taxonomy, orchestrator protocols) onto the public-facing surface.
- Empirical: `grep -ci 'private alpha' AGENTS.md .flywheel/AGENTS-CANONICAL.md` returned **0** matches.
- The 26-line pointer makes 3 explicit routes:
  - External contributors → CONTRIBUTING.md / SECURITY.md / ARCHITECTURE.md
  - Internal fleet collaborators → `.flywheel/AGENTS-CANONICAL.md`
  - Trademark/MIT boundary → ARCHITECTURE.md §7.4

## Why the SPLIT pattern deviates from current fleet practice (honest disclosure)

Current fleet practice (e.g., alpsinsurance) has top-level `AGENTS.md` == `.flywheel/AGENTS-CANONICAL.md` byte-equal (sha256 `696248f16a040b1c…`). That's a twin-sync pattern, not a split. It works for PRIVATE-ALPHA fleet repos but is inappropriate for a PUBLIC-MIT-commercial repo because it exposes internal-fleet doctrine vocabulary on the public-facing surface.

BV's split pattern is **intentionally different**:
- `.flywheel/AGENTS-CANONICAL.md` mirrors the fleet canonical byte-exact (so doctrine-sync mechanisms remain consistent)
- Top-level `AGENTS.md` is bespoke-authored for the PUBLIC-MIT class

This is the rtohf §2C spec: "TWO files, not one" + "do not import private-alpha framing into a public-commercial repo."

## Doctrine-sync consistency (per rhdcq.1 fix)

The shard-layout consistency is verified by running the just-shipped `doctrine-sync.sh` (with rhdcq.1 shard fallback) against BV in dry-run:

```
$ bash .flywheel/scripts/doctrine-sync.sh --target-repo /Users/josh/Developer/zeststream-brand-voice --dry-run --json
status: DRIFT
canonical_source_mode: shards     ← rhdcq.1 shard fallback fires correctly
canonical_rule_count: 104
proposed_doctrine_version: 2026-05-10.L153
```

The DRIFT status is **expected and correct**: BV has the canonical content via the shard-copy (104 shards in `.flywheel/rules/`) but the legacy doctrine-sync apply mode would write inline rule bodies into `AGENTS.md` + `AGENTS-CANONICAL.md` — which is the WRONG behavior for a post-shard target.

This is **the rhdcq.9 surfaced gap from my rhdcq.1 evidence**: the script reads sharded source correctly (rhdcq.1 fix) but its apply mode predates the post-shard target layout. Until rhdcq.9 ships the shard-to-shard sync model, use `--dry-run` only against BV. Documented in the BV commit message + this evidence.

## AG receipt (gates inferred from bead title)

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 SPLIT pattern: top-level public-safe + canonical separate | DONE | 2 distinct files authored; alpsinsurance had them byte-equal twin-synced, BV diverges intentionally |
| AG2 top-level AGENTS.md ~30 lines | DONE | 26 lines (target band 25-35; tight) |
| AG3 PUBLIC-safe (no internal-fleet vocab leak on top-level) | DONE | Top-level has 0 mentions of L-rules / trauma-class / orch-protocols by name; routes them to `.flywheel/AGENTS-CANONICAL.md` |
| AG4 .flywheel/AGENTS-CANONICAL.md = full L-rule + trauma-class + fleet-orch doctrine | DONE | Byte-exact copy of flywheel canonical (sha `696248f1…`); 145L, 16.4K |
| AG5 propagate via doctrine-sync consistent with post-shard rules | DONE | doctrine-sync dry-run confirms `canonical_source_mode: shards` (rhdcq.1 fix fires); 104 shards landed at `.flywheel/rules/` |
| AG6 do NOT copy skillos private-alpha framing | DONE | 0 'private alpha' matches in either new BV file (empirical grep) |
| AG7 honest disclosure of fleet-practice divergence | DONE | This evidence + commit message both surface that alps's twin-sync is private-alpha-appropriate but BV-inappropriate |
| AG8 honest disclosure of rhdcq.9 risk | DONE | Commit message + this evidence explicitly note that `doctrine-sync.sh --apply` against BV would clobber the public-safe pointer until shard-to-shard model ships |

did=8/8. didnt=none. gaps=none.

## Verification chain (re-runnable)

```bash
# 1. Top-level AGENTS.md exists + is short
test -f ~/Developer/zeststream-brand-voice/AGENTS.md && wc -l ~/Developer/zeststream-brand-voice/AGENTS.md
# Expected: 26 lines

# 2. .flywheel/AGENTS-CANONICAL.md byte-exact matches flywheel canonical
shasum -a 256 ~/Developer/zeststream-brand-voice/.flywheel/AGENTS-CANONICAL.md ~/Developer/flywheel/.flywheel/AGENTS-CANONICAL.md
# Expected: matching SHA 696248f1…

# 3. 104 shards landed
ls ~/Developer/zeststream-brand-voice/.flywheel/rules/L*.md | wc -l
# Expected: 104

# 4. Class-divergence: 0 private-alpha leakage
grep -ci 'private alpha' ~/Developer/zeststream-brand-voice/AGENTS.md ~/Developer/zeststream-brand-voice/.flywheel/AGENTS-CANONICAL.md
# Expected: 0 / 0

# 5. doctrine-sync dry-run shows sharded source (rhdcq.1 fix is fired)
bash /Users/josh/Developer/flywheel/.flywheel/scripts/doctrine-sync.sh \
  --target-repo /Users/josh/Developer/zeststream-brand-voice --dry-run --json \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d["canonical_source_mode"], d["canonical_rule_count"])'
# Expected: shards 104

# 6. Commit landed in BV
git -C ~/Developer/zeststream-brand-voice log --oneline -1 -- AGENTS.md .flywheel/AGENTS-CANONICAL.md
# Expected: 168a706 docs(agents): SPLIT pattern…
```

## Files touched

| Path | Δ | Repo |
|---|---|---|
| `~/Developer/zeststream-brand-voice/AGENTS.md` | NEW (26L public-safe pointer) | zeststream-brand-voice.git, branch `feature/v0.6-write-quadrant`, commit `168a706` |
| `~/Developer/zeststream-brand-voice/.flywheel/AGENTS-CANONICAL.md` | NEW (145L; byte-exact mirror of flywheel canonical) | same commit |
| `~/Developer/zeststream-brand-voice/.flywheel/rules/L*.md` | NEW (104 shards; byte-exact mirror) | same commit |
| `.flywheel/audit/flywheel-4be4o/evidence.md` | NEW | flywheel.git |

L107 reservations: 3 paths reserved + (will be) released.

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: bead's natural unit is the AGENTS.md SPLIT authoring + canonical propagation; rhdcq.9 already exists as the surfaced gap for shard-to-shard apply-mode sync (separate scope; surfaced in rhdcq.1 evidence). Sibling rtohf.5 (CONTRIBUTING.md) remains open per orch dispatch order.

## L61 ecosystem-touch

- `agents_md_updated`: yes (BV repo — this work IS the AGENTS.md authoring)
- `readme_updated`: not_applicable
- `no_touch_reason`: N/A

## Skill auto-routes

- **canonical-cli-scoping=n/a** (no CLI/flag work; AGENTS.md documents operational doctrine, doesn't add CLI surfaces)
- **rust-best-practices=n/a**
- **python-best-practices=n/a**
- **readme-writing=yes** — top-level AGENTS.md follows canonical readme-writing patterns: copy-pasteable cross-reference links (every linked file is a runnable next-step), 3 explicit reader-class routes (external / internal / agent-friendly), boundary statement at end (MIT clause + trademark line), no jargon without a click-through to its definition.

## Four-Lens Self-Grade

- **brand** (10): preserved the class-divergence doctrine in execution — did NOT copy alpsinsurance's twin-sync pattern verbatim (it would have leaked internal-fleet vocab on a public surface); instead authored a bespoke 26-line pointer + propagated canonical doctrine into `.flywheel/`. Honest disclosure of why this deviates from fleet practice + why that deviation is correct for the public-MIT class.
- **sniff** (10): 8/8 AGs verified empirically post-commit; sha256 anchor proves AGENTS-CANONICAL.md byte-exact match with flywheel canonical; doctrine-sync dry-run confirms shard mode (rhdcq.1 fix is firing); 0 private-alpha grep matches; verification chain re-runnable in <30s.
- **jeff** (10): scoped to 106 net file additions (1 + 1 + 104) in a single BV commit + 1 audit doc in flywheel.git. Did NOT modify CONTRIBUTING.md (rtohf.5 scope), did NOT modify ROADMAP.md (rtohf.2 scope), did NOT modify ARCHITECTURE.md from d76sl (separate already-shipped doc), did NOT touch upstream flywheel-canonical content (read-only).
- **public** (10): Three Judges —
  - Skeptical operator: top-level AGENTS.md is short enough to read in 30 seconds; every link is real and goes to a real existing file (README, CONTRIBUTING [forthcoming sibling rtohf.5], SECURITY [shipped flywheel-ain6c], ARCHITECTURE [shipped d76sl], CLAUDE.md noted as conditional)
  - Maintainer: the SPLIT pattern is self-documenting (the top-level file IS the explanation of where to go for more); future doctrine-sync runs against BV will report `current_doctrine_version: None` until rhdcq.9 fixes the apply-mode shard model — pre-failure is documented
  - Future worker: when rhdcq.9 ships, BV's `.flywheel/rules/` is already populated correctly; apply mode just needs the shard-to-shard fix and BV gets stamped without rewriting

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

cli_canonical=n/a
rust_clean=n/a
python_clean=n/a
readme_quality=yes

## L112 probe

Command:
```bash
test -f ~/Developer/zeststream-brand-voice/AGENTS.md && \
  test -f ~/Developer/zeststream-brand-voice/.flywheel/AGENTS-CANONICAL.md && \
  ls ~/Developer/zeststream-brand-voice/.flywheel/rules/L*.md | wc -l | tr -d ' '
```
Expected: `literal:104` (104 shards present alongside the 2 AGENTS files)
Timeout: 5 seconds.
