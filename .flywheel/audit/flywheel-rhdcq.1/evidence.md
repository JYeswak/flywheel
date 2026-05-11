# flywheel-rhdcq.1 — doctrine-sync.sh canonical-source regex fix (sharded layout)

Bead: flywheel-rhdcq.1 (P2)
Parent: flywheel-rhdcq (BLOCKED on 5-surface premise mismatch; this fixes surface 2)
Substrate boundary: Joshua-domain `.flywheel/scripts/doctrine-sync.sh` (in-repo, direct mutation)
mutates_state: yes (in-repo script edit)

## Probe (META-RULE 2xdi.54)

**Bead hypothesis:** `doctrine-sync.sh` regex `^## L<N>\b` expected inline format in `templates/flywheel-install/AGENTS.md`, but the canonical layout was sharded into `.flywheel/rules/L*.md` (104 files) by commit `a42e050e refactor(doctrine): shard canonical agents rules`.

**Empirical pre-fix verification:**
```
$ bash .flywheel/scripts/doctrine-sync.sh --version-stamp
{"canonical_sha":"6ba8a33","canonical_source":".../AGENTS.md","doctrine_version":"unknown.L0","highest_l_rule":"L0","shipped":"unknown"}

$ grep -c '^## L[0-9]' templates/flywheel-install/AGENTS.md
0

$ ls .flywheel/rules/L*.md | wc -l
104
```

Confirmed: inline regex finds nothing in canonical source; 104 shards exist; highest shard L-number is L153.

## Root-cause fix (3 surgical patches, additive)

### Patch 1 — `--version-stamp` heredoc shard fallback (lines 476-505)

Replace single-pass inline regex with two-pass: inline first (backward compat), shards on empty.

```python
inline_matches = list(re.finditer(r"(?m)^## (L(\d+))\b.*$", text))
if inline_matches:
    for match in inline_matches: ...   # unchanged
else:
    shards_dir = root / ".flywheel" / "rules"
    if shards_dir.is_dir():
        source_mode = "shards"
        for shard_path in sorted(shards_dir.glob("L*.md")):
            m = re.match(r"(?m)^## (L(\d+))\b.*$", shard_text)
            ...
```

Adds two new output fields: `source_mode` (inline|shards) + `rule_count` (deterministic verification anchor).

### Patch 2 — main heredoc `parse_rules_from_shards()` helper + canonical fallback (lines 555-617)

New function `parse_rules_from_shards(shards_dir)` reads each shard as one L-rule. Canonical-load now:

```python
canonical_rules, _ = parse_rules(canonical_source)     # try inline
canonical_mode = "inline"
shards_dir_canonical = root / ".flywheel" / "rules"
if not canonical_rules and shards_dir_canonical.is_dir():
    canonical_rules = parse_rules_from_shards(shards_dir_canonical)
    canonical_mode = "shards"
if not canonical_rules:
    raise SystemExit("ERR: canonical source has no L-rule headings (checked inline + shards)")
```

Target-surface parsing (`parse_rules(target/AGENTS.md)`) is UNCHANGED — preserves backward compat for any target still on inline format.

### Patch 3 — surface canonical_mode in payload (line 717 + provenance footer)

Adds `canonical_source_mode` + `canonical_rule_count` to receipt envelope. Provenance footer says `# Pulled from flywheel/.flywheel/rules/L*.md@<sha> (sharded canonical layout)` when sharded.

## Empirical post-fix verification

| Probe | Pre-fix | Post-fix |
|---|---|---|
| `--version-stamp` `.highest_l_rule` | `L0` | `L153` |
| `--version-stamp` `.rule_count` | (field absent) | `104` |
| `--version-stamp` `.source_mode` | (field absent) | `shards` |
| `doctor` `rules_dir.rule_count` | `104` (was working) | `104` (regression-fenced) |
| `--target-repo alpsinsurance --dry-run` `.canonical_source_mode` | (field absent + L0) | `shards` |
| `--target-repo alpsinsurance --dry-run` `.canonical_rule_count` | (field absent) | `104` |
| `--target-repo alpsinsurance --dry-run` `.highest_l_rule` | `L0` | `L153` |
| `--target-repo alpsinsurance --dry-run` `.proposed_doctrine_version` | `unknown.L0` | `2026-05-10.L153` |
| `--target-repo alpsinsurance --dry-run` `.provenance_footer` | `# Pulled from .../AGENTS.md@<sha>` | `# Pulled from .../rules/L*.md@<sha> (sharded canonical layout)` |

Backward-compat fence (AG6): synthetic inline-format AGENTS.md still parses inline (`L42`+`L77` → highest=`L77`).

## Regression test

`.flywheel/tests/test-rhdcq.1-doctrine-sync-shard-fallback.sh` — 6 ACs, 6/6 PASS:

```
PASS AG1 --version-stamp highest_l_rule=L153 (not L0)
PASS AG2 --version-stamp rule_count=104 (>= 100)
PASS AG3 --version-stamp source_mode=shards
PASS AG4 doctor rules_dir rule_count=104 (>= 100)
PASS AG5 alpsinsurance dry-run canonical_source_mode=shards canonical_rule_count=104 highest_l_rule=L153
PASS AG6 backward-compat inline parse returns L77 (highest of L42,L77)
6 passed, 0 failed
```

## Discovered gap (out-of-scope for rhdcq.1; surface for rhdcq.8 design)

While verifying AG5 against alpsinsurance, the dry-run reported `missing_l_rules_count=104` — i.e., the script thinks ALL 104 shards are missing from the target's AGENTS.md. Probe:

```
$ grep -c '^## L[0-9]' /Users/josh/Developer/alpsinsurance/AGENTS.md
0
$ ls /Users/josh/Developer/alpsinsurance/.flywheel/rules/L*.md | wc -l
104
$ head -30 /Users/josh/Developer/alpsinsurance/.flywheel/AGENTS-CANONICAL.md
... <!-- GENERATED: edit .flywheel/rules/L*.md, then run .flywheel/scripts/agents-md-shard-extract.sh --apply -->
```

**Target's `AGENTS.md` + `AGENTS-CANONICAL.md` are ALSO sharded.** The canonical sync model has changed from inline-append to shard-to-shard + regenerate-via-shard-extract. The current `doctrine-sync.sh` apply path (append rule bodies to target's AGENTS.md) is incompatible with this layout — it would write 104 inline rule bodies into a target that's expected to read from `.flywheel/rules/` shards.

This is the right-sized fix for rhdcq.1 (the regex). But **rhdcq.8 (the actual propagation dispatch) needs a redesigned sync model: copy shard files target-side, or invoke `agents-md-shard-extract.sh` after shard-copy**. Surfacing as `gaps=rhdcq.9_shard_to_shard_sync_model_needed` so orch can either decompose further or fold into rhdcq.8 design scope.

## Files touched

| Path | Δ | Reason |
|---|---|---|
| `.flywheel/scripts/doctrine-sync.sh` | +35 lines (3 patches) | Shard fallback |
| `.flywheel/tests/test-rhdcq.1-doctrine-sync-shard-fallback.sh` | NEW (6 ACs, 6/6 PASS) | Regression coverage |
| `.flywheel/audit/flywheel-rhdcq.1/evidence.md` | NEW | This file |

L107 reservation: doctrine-sync.sh reserved + released.

## Acceptance gates

Bead body is empty; gates inferred from title ("regex fix — read sharded .flywheel/rules/L*.md (104 files)"):

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | `--version-stamp` no longer returns L0 | DONE | returns L153 |
| AG2 | shard-fallback reads all 104 shards | DONE | rule_count=104 |
| AG3 | source_mode indicates shards | DONE | source_mode=shards |
| AG4 | doctor regression-fenced | DONE | rules_dir.rule_count=104 unchanged |
| AG5 | Real-target dry-run produces meaningful payload (not L0) | DONE | alps dry-run shows L153 / shards / 104 |
| AG6 | Backward-compat: inline source still parses inline | DONE | synthetic L42+L77 parses correctly |

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: gap surfaced as `gaps=rhdcq.9_shard_to_shard_sync_model_needed` for orch to decompose/fold; will not pre-file since rhdcq.8 may want to fold it in.

## L61 ecosystem-touch

- `agents_md_updated`: not_applicable
- `readme_updated`: not_applicable
- `no_touch_reason`: substrate-script fix; no doctrine/INCIDENTS/canonical/L-rule edits.

## Skill auto-routes

- **canonical-cli-scoping=yes** — doctrine-sync.sh is a canonical-CLI surface; `--version-stamp` envelope shape preserved + extended with `source_mode` + `rule_count` (additive, no breakage). `--json`, schema, exit-code behavior unchanged. `--apply` + `--idempotency-key` discipline preserved.
- **rust-best-practices=n/a**
- **python-best-practices=n/a** (inline python heredocs only; no module changes)
- **readme-writing=n/a**

## Four-Lens Self-Grade

- **brand** (10): surgical fix scoped to canonical-source-load path. Did NOT touch target-surface parsing (would have been scope-creep). Surfaced target-side gap honestly as `gaps=` for orch decomposition rather than silently extending scope. Backward-compat path explicitly tested.
- **sniff** (10): 9 empirical probes pre/post (8 verification rows + 1 backward-compat fence). 6/6 regression test PASS. AG5 uses real target (alpsinsurance), not synthetic, for production-equivalent proof.
- **jeff** (10): scoped to 3 patches in 1 file + 1 new test + 1 audit doc (3 file classes). Did NOT bundle the target-surface shard-fix (proper rhdcq.8 scope). Did NOT silently change `provenance_footer` semantics — explicitly different string when sharded.
- **public** (10): Three Judges —
  - Skeptical operator: 6-AG test is single `bash <path>` re-runnable; pre/post table has explicit jq paths.
  - Maintainer: 3 patches are minimal-touch; new helper `parse_rules_from_shards` mirrors `parse_rules` shape for review parity; comment block explains shard-vs-inline decision.
  - Future worker: when target-side regression surfaces (rhdcq.8 or rhdcq.9), the canonical-side is fixed and verified; they inherit a known-good upstream.

Per Donella Meadows #5 (rules of the system): the canonical-source parse RULE is fixed to recognize sharded layout — leverage point at the substrate's READ interface, not its WRITE interface (which is rhdcq.8's scope). Per `feedback_decompose_by_natural_unit_not_bundle`: held to the natural unit (regex fix), did not bundle the shard-to-shard sync model redesign.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

cli_canonical=yes
rust_clean=n/a
python_clean=n/a
readme_quality=n/a

## L112 probe

Command:
```bash
bash /Users/josh/Developer/flywheel/.flywheel/tests/test-rhdcq.1-doctrine-sync-shard-fallback.sh
```
Expected: `grep:6 passed, 0 failed`
Timeout: 20 seconds.
