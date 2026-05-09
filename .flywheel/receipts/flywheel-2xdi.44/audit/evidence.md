# flywheel-2xdi.44 — gap-hunt false-positive: pack validators are intentional on-demand

## Bead context

- ID: `flywheel-2xdi.44` (P3, OPEN at dispatch start, CLOSED at done)
- Title: `[gap-wired-but-cold] .claude/skills/.flywheel/data/skill-packs/ai-codebase-intelligence-pack/validate.sh`
- Auto-filed by: `gap-hunt-probe.sh` (parent `flywheel-2xdi`, P1, closed)
- Class: `wired-but-cold`

## Disposition: false-positive — on-demand-validator class

`~/.claude/skills/.flywheel/data/skill-packs/ai-codebase-intelligence-pack/validate.sh` (103 lines, mtime 2026-04-29T07:36Z) is NOT cold-by-drift. It is an **intentional on-demand validator**:

- Tracked substrate: `substrate-registry.json` carries an `ai-codebase-intelligence-pack-validate` row.
- Functional: `bash <path>` exits 0 and prints `OK:` lines for the pack's SKILL.md gates (socraticode skill: name, description length, trigger phrases, etc.).
- By design: invoked synchronously during pack scaffold, registry promotion (gated→active→monitoring), or audit. NOT cron-driven; cron-driving it would be an anti-pattern.
- No JSONL ledger writes: validators print to stderr/stdout, exit, done. No flywheel-ledger fingerprint to match.

The wired-but-cold detector's ledger-substring heuristic correctly classifies this as "no recent JSONL reference" but conflates that signal with "cold-by-drift". Two genuinely different classes share the same flag.

## Scale of the false-positive class

After flywheel-vmc7r's two-pass corpus fix (commit `7d57ddd`):

```
$ gap-hunt-probe.sh --dry-run --json | jq '.gaps_by_class["wired-but-cold"] | length'
20

$ ... | jq 'map(select(test("skill-packs/[^/]*/validate\\.sh"))) | length'
18
```

**18 of 20 (90%) wired-but-cold flags are pack validators**. The probe will keep filing one P3 promotion-candidate per pack until the detector recognizes the on-demand-validator pattern.

## L52 receipt: filed source-fix bead

`flywheel-2fw7v` — `[gap-hunt-probe] wired-but-cold detector flags on-demand pack validators as cold (18 false-positives)`. Proposes three fix options:

1. Pattern allowlist for `skill-packs/*/validate.sh` (smallest blast radius)
2. Substrate-registry awareness (single-source-of-truth; preferred)
3. Header marker (per-script annotation; loosely-coupled)

Recommended: option 2 — extend `probe_wired_but_cold` to consult `substrate-registry.json` and skip rows registered with manual-invocation kinds.

## Relationship to today's earlier gap-hunt-probe work

| Bead | Class | Disposition | Outcome |
|---|---|---|---|
| `flywheel-2xdi.41` | wired-but-cold (`lib/fuckup.sh`) | budget-cap false-positive | filed `flywheel-7h3om` (closed as superseded) |
| `flywheel-2xdi.42` | wired-but-cold (`lib/mission.sh`) | budget-cap false-positive | filed `flywheel-vmc7r`; vmc7r implemented two-pass corpus fix; both fuckup + mission no longer flagged |
| `flywheel-vmc7r` | source-fix (gap-hunt-probe) | implemented + 7/7 regression tests | shipped commit `7d57ddd` |
| `flywheel-2xdi.44` (this) | wired-but-cold (pack validator) | NEW false-positive class — on-demand-validator | filed `flywheel-2fw7v` |

The vmc7r fix solved the 4MB-budget false-positive. This bead surfaces the next-largest class (90% of remaining flags) as a separate doctrine-fix bead. Step 4n's signal-to-noise improves once `flywheel-2fw7v` lands.

## Acceptance criteria — implicit DoD

The bead body has no explicit acceptance gates. Same shape as `flywheel-2xdi.41`:

| Implicit gate | Done |
|---|---|
| Classify the gap (real cold? false-positive? cold-by-design?) | yes — false-positive: on-demand-validator class |
| Cite concrete wiring/intent evidence | yes — substrate-registry row + functional exit-0 + per-pack scaffold lifecycle |
| Explicit no-cold receipt OR fix the source | both — receipt + filed `flywheel-2fw7v` for source fix covering all 18 |

`did=3/3`

## Why no edit to ~/.claude/skills/...

The validator script `~/.claude/skills/.flywheel/data/skill-packs/ai-codebase-intelligence-pack/validate.sh` is in a foreign repo (`~/.claude/`) and editing it would only address 1 of 18 pack validators. The structural fix lives at `.flywheel/scripts/gap-hunt-probe.sh` (this repo) — that's what `flywheel-2fw7v` targets.

## Skill auto-routes

| Route | Status | Note |
|---|---|---|
| canonical-cli-scoping | n/a | Receipt-only disposition; no CLI surface mutated. |
| rust-best-practices | n/a | No Rust touched. |
| python-best-practices | n/a | gap-hunt-probe.sh is Python-in-bash, but the source-fix is filed as a follow-up bead, not implemented here. |
| readme-writing | n/a | No README touched. |

## Four-Lens Self-Grade

- **brand: 9** — Joshua-style "data decides" disposition; concrete count (18/20 = 90%) drives the fix scope.
- **sniff: 9** — receipt-only; no cross-repo edit; one structural follow-up bead covers all 18 affected packs.
- **jeff: 9** — single-source-of-truth: `substrate-registry.json` is canonical, the probe should consult it; option 2 in `flywheel-2fw7v` proposes exactly that.
- **public: 9** — Three Judges: skeptical operator (90% flag share is a clear signal), maintainer (3 fix options + acceptance gates with re-runnable verification), future worker (the on-demand-validator class is named so future similar classes can be recognized + filed against the same fix).

`four_lens=brand:9,sniff:9,jeff:9,public:9`

## Mission fitness

`infrastructure` — gap-hunt-probe is the orchestrator's paradigm-tier self-audit; a 90% false-positive class wastes orchestrator attention on phantom gaps and pollutes the L56 ladder with noise (`doctrine-ladder-promote.sh` will dispatch a promotion-candidate P3 for each one). Filing `flywheel-2fw7v` collapses 18 future dispatches into one fix.
