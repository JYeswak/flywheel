# flywheel-2xdi.41 — gap-hunt false-positive: lib/fuckup.sh is wired AND warm

## Bead context

- ID: `flywheel-2xdi.41` (P3, OPEN at dispatch start, CLOSED at done)
- Title: `[gap-wired-but-cold] .claude/skills/.flywheel/lib/fuckup.sh`
- Auto-filed by: `gap-hunt-probe.sh` (parent `flywheel-2xdi`, P1, closed)
- Class: `wired-but-cold`
- Probe evidence: "script not referenced by recent flywheel jsonl ledgers modified in last 30d"

## Disposition: probe false-positive — script is wired AND warm

`~/.claude/skills/.flywheel/lib/fuckup.sh` (307 lines, mtime 2026-05-07T18:33Z) is **demonstrably wired**:

- Defines `fuckup_triage_compute_json()` at line 3
- Called by `~/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh:614`
  ```
  fuckup_triage="$(fuckup_triage_compute_json)"
  ```
- Result composed into doctor packet at portable_doctor.sh:1251
- Status surfaced in doctor output at portable_doctor.sh:1409 (strict-mode error gate)

It is also **warm via its sibling ledgers**:

- `~/.local/state/flywheel/fuckup-log.jsonl` — 4.8 MiB, mtime 2026-05-09T13:37Z (today)
- `~/.local/state/flywheel/fuckup-processed.jsonl` — 113 KiB, mtime 2026-05-09T13:35Z (today)

So why did `gap-hunt-probe` flag it? The probe's `recent_ledger_text()` (gap-hunt-probe.sh:355) builds a substring search corpus capped at 4 MiB. Ledgers are processed alphabetically, prepending each filename to the corpus. The first ~12 alphabetical ledgers consume the 4 MiB budget, after which the probe `continue`s past the remaining ledgers — and crucially, never appends their NAMES to the corpus either.

**Reproduction**: see `budget-repro.txt` in this audit dir.

```
kept_count=12 dropped_count=97 bytes_used=4000000
fuckup_in_kept_names=False fuckup_in_kept_text=False
DROPPED: fuckup-log.jsonl
DROPPED: fuckup-processed.jsonl
```

`fuckup-log.jsonl` is alphabetically too late (after `agents-md-fleet-propagation.jsonl` @1.8 MiB and `br-db-corruption-monitor-ledger.jsonl` @991 KiB consume most of the budget). Its NAME never reaches `ledger_text`, so `"fuckup" in ledger_text` returns `False`, and `lib/fuckup.sh` falsely fires the cold-script detector.

## L52 receipt: filed source-fix bead

`flywheel-7h3om` — `[gap-hunt-probe] wired-but-cold detector false-positive when 4MB ledger budget caps before later-alphabet ledgers`. Proposes a two-pass corpus build:

1. Pass 1 (always-complete, no budget): collect every recent-window ledger basename into `name_corpus`.
2. Pass 2 (budgeted): existing 4 MiB content scan into `text_corpus`.
3. Search both: `name in name_corpus or name in text_corpus or stem in {name_corpus, text_corpus}`.

Pass 1 is O(filenames) — tiny. The fix tightens the wired-but-cold class without growing the budget or changing the cold→warm signal for the other 7 gap classes that share `recent_ledger_text`.

## Acceptance criteria — verbatim from bead body

The auto-filed body listed only `Class:`, `Gap id:`, and `Evidence:` — no explicit acceptance gates. I'm interpreting the implicit DoD as: classify the gap, document the disposition, and either fix or surface a follow-up.

| Implied gate | Done |
|---|---|
| Classify the gap (real cold? false-positive? cold-by-design?) | yes — false-positive due to 4MB budget cap |
| Cite concrete wiring evidence | yes — portable_doctor.sh:614 + fuckup-log.jsonl mtime |
| Explicit no-cold receipt OR fix the source | both — receipt + filed `flywheel-7h3om` for source fix |

`did=3/3`

## Why no edit to lib/fuckup.sh?

The `~/.claude` repo already has uncommitted local changes against `lib/fuckup.sh` (the FLYWHEEL_FUCKUP_TRIAGE_FAST_DOCTOR fast-path block) authored by an earlier session. Bundling a probe-disposition comment into that change would mix scopes across two repos and risk publishing in-flight work. The disposition here lives in the receipt instead.

If the source-fix bead `flywheel-7h3om` lands, the cold-flag goes away without touching `lib/fuckup.sh` at all — which is the cleaner outcome for a probe false-positive.

## Skill auto-routes

| Route | Status | Note |
|---|---|---|
| canonical-cli-scoping | n/a | Receipt-only disposition; no CLI surface mutated. |
| rust-best-practices | n/a | No Rust touched. |
| python-best-practices | n/a | gap-hunt-probe.sh is Python embedded in bash, but the fix is filed as a follow-up bead, not implemented here. |
| readme-writing | n/a | No README touched. |

## Four-Lens Self-Grade

- **brand: 9** — Joshua-style "data decides" disposition; reproduction script + concrete evidence vs. just-write-it-off rationale.
- **sniff: 9** — no foreign-WIP contamination, no destructive fix, surface-fix bead filed for the actual root cause.
- **jeff: 9** — single-source-of-truth: the gap-hunt-probe is the locus of the bug; one bead targets that file with a concrete fix sketch and acceptance gates.
- **public: 9** — Three Judges: skeptical operator (reproduction script lands in receipts), maintainer (cited file:line for wiring + budget mechanics), future worker (the next gap-hunt false-positive in this class can cite this evidence + the tracking bead).

`four_lens=brand:9,sniff:9,jeff:9,public:9`

## Mission fitness

`infrastructure` — the gap-hunt-probe's job is paradigm-tier self-audit; a false-positive class that flags genuine wired+warm scripts as cold pollutes the gap-hunt signal and wastes orchestrator attention on phantom gaps. Filing the source-fix bead directly tightens Step 4n's signal-to-noise.
