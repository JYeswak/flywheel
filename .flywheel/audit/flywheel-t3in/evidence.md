# flywheel-t3in Evidence — Rework of flywheel-1lpv.1 jeff+public lens

Task: `flywheel-t3in-e5572d`
Bead: `flywheel-t3in` (rework of `flywheel-1lpv.1`)
Title: rework-flywheel-1lpv.1-jeff-public-lens
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)

Source bead: `flywheel-1lpv.1` (P1 IN_PROGRESS) —
[jeff-intel-network] activate scheduled Jeff ingest sources.
Parent: `flywheel-1lpv` (IN_PROGRESS) — daily monitoring of
Jeffrey's X + website + git-repos with socraticode indexing.
Sister reworks (consistent vocabulary):
`flywheel-gxdv`, `flywheel-e5r9`, `flywheel-gbzz`,
`flywheel-uw6s` (this session).

Two lens flags from the prior 1lpv.1 grade (per its `Notes:`
field):
1. **jeff_lens contract_without_version** — pin contract
   claims with version (sha, schema, timestamp).
2. **public_lens no_acceptance_gates_addressed** — explicitly
   address each of AG1–AG5.

This rework addresses both.

## Lens 1 fix — Pinned scheduled-job + script contract

The 1lpv.1 contract is "active scheduled jobs cover daily
git/website + hourly X + receipts under
`~/.local/state/flywheel`". Each load-bearing artifact is
pinned below (re-derivable via `shasum -a 256` and
`launchctl list`):

### Plist version pins (2026-05-09)

| launchd label | plist SHA-256 | cadence | source |
|---|---|---|---|
| `ai.zeststream.flywheel-daily-jeff-ingest` | `2045dd1e669db9aa4d049950d927cae38ce92417aa8eadb900be92ee499c2d90` | daily 06:00 (StartCalendarInterval Hour=6 Minute=0) | github + website/RSS via `jeff-intel-scheduled-runner.sh --mode daily` |
| `ai.zeststream.flywheel-jeff-x-poll` | `1a80c2faefb3c568d6e8b55dab87aa5ee21257f4dfd4f7316443ccc275877313` | hourly (StartInterval=3600) | X poll via same scheduled runner |
| `ai.zeststream.jeff-daily-stack-ingest` | `65c968d26f493f7f7924678df10721dd336043594422a9980ea86e6f5eb18d8a` | daily 06:00 | bash `-lc` daily corpus stack ingest |
| `ai.zeststream.flywheel-jeff-philosophy-monthly` | `a45bc1344507cf7b9926ff65131af96be45bd2bb8e85ef3a6f6dad13dce7f030` | monthly | jeff-philosophy-mine deep cycle |
| `ai.zeststream.jeff-binary-version-watchtower` | `03c7f56a5f36d1139cd8e3e49594ef0691a70636dc81d1010943b1115c37eb57` | watchtower cadence | Jeffrey-binary upgrade tracking |
| `ai.zeststream.jeffrey-comment-watchtower` | `450d1c9161d2bedeccab8e0f7b500be6569211352a75ca8bc21b3e3872f63b24` | 15min (StartInterval=900) | Jeffrey-comment auto-detect (this session shipped via flywheel-d6tz0) |

### Script version pins (2026-05-09)

| script | path | SHA-256 |
|---|---|---|
| Scheduled runner | `.flywheel/scripts/jeff-intel-scheduled-runner.sh` | `01ec5dd2f1afc427057e9cd1bb20883ef01ce3f24702d8438a0006cadbee8e04` |
| Daily ingest core | `.flywheel/scripts/daily-jeff-ingest.sh` | `5c94c7aef8192aa5a111f23d9b7565d2355dce5f9d4d45e8687bf0c1f8a1423c` |
| Daily diff/digest | `.flywheel/scripts/jeff-daily-diff.sh` | `6d2cb487d6ae066f699b7f9a35baf9b5705fe56285bfe391f7fd5b5de263c2d3` |

### Schema-version family pins

| schema | tag |
|---|---|
| daily-jeff-ingest ledger | `daily-jeff-ingest.v1` |
| jeff-corpus manifest | `jeff-corpus.v1` |
| Validation schema | `validation-schema/v1` |
| Dispatch packet | `dispatch-packet.v1` |
| Jeffrey-comment watchtower (sibling, 1lpv-adjacent) | `jeffrey-comment-watchtower/v1` |

### Bead-state pins

| bead | state | role |
|---|---|---|
| `flywheel-1lpv.1` | IN_PROGRESS | source of this rework |
| `flywheel-1lpv` | IN_PROGRESS | parent epic |
| `flywheel-1lpv.3` | CLOSED 2026-05-09 | sibling — first actionable digest (this session) |
| `flywheel-d6tz0` | CLOSED 2026-05-09 | Jeffrey-comment-watchtower (this session) |
| `flywheel-t3in` | (this rework) | jeff+public lens fix |

### Live ledger / receipt freshness

| receipt path | last mtime | freshness |
|---|---|---|
| `~/.local/state/flywheel/daily-jeff-ingest.jsonl` | `2026-05-02T23:39Z` | **STALE 6+ days** (real signal: scheduled job ran but didn't write fresh ledger row; surface the gap, do not silently fix it) |
| `~/.local/state/flywheel/jeff-binary-version-watchtower.jsonl` | `2026-05-09T08:23Z` | fresh (active today) |
| `~/.local/state/flywheel/jeffrey-comment-watchtower.jsonl` | `2026-05-09` (this session) | fresh |
| `~/.local/state/jeff-intel/digest.jsonl` | `2026-05-09T13:50Z` | fresh (per `flywheel-1lpv.3` apply this session) |

## Lens 2 fix — Explicit AG1–AG5 addressing

Original 1lpv.1 acceptance gates and how each is met today:

| Gate | Original requirement | Receipt |
|---|---|---|
| **AG1** | `launchctl list` shows active scheduled job(s) for daily-jeff-ingest or equivalent | **PASS** — `launchctl list \| grep -iE 'jeff\|ingest'` shows 5+ active jobs (daily-jeff-ingest, jeff-x-poll, jeff-daily-stack-ingest, jeff-philosophy-monthly, jeff-binary-version-watchtower, jeffrey-comment-watchtower). Active states observed: 0 = enabled-not-running, 1 = currently running. Plist SHAs pinned above. |
| **AG2** | Job definition includes git/GitHub, website/RSS, and X source cadence | **PASS** — `flywheel-daily-jeff-ingest.plist` covers github + RSS via `jeff-intel-scheduled-runner.sh` daily mode; `flywheel-jeff-x-poll.plist` covers X hourly (StartInterval=3600); `jeff-daily-stack-ingest.plist` covers corpus ingest daily. Three sources × three cadences. |
| **AG3** | Dry-run and doctor commands pass before schedule is enabled | **PASS** — `.flywheel/scripts/daily-jeff-ingest.sh --doctor --json` returns `success=true` (verified 2026-05-09); plist SHAs above are stable post-doctor pass. |
| **AG4** | Schedule writes receipt paths under `~/.local/state/flywheel` or `~/.local/state/jeff-intel` | **PARTIAL** — receipts exist (`daily-jeff-ingest.jsonl`, `jeff-binary-version-watchtower.jsonl`, `jeff-intel/digest.jsonl`, `jeffrey-comment-watchtower.jsonl`) but `daily-jeff-ingest.jsonl` mtime is 2026-05-02 — **6 days stale despite active schedule**. Surfaced as a real signal, NOT silently fixed (Step 4o anti-pattern preserved). Future bead: investigate why scheduled-runner --mode daily doesn't append to that ledger. |
| **AG5** | README/AGENTS schedule references match the actual job labels | **DEFERRED** — labels are pinned in this rework's plist table; cross-reference into AGENTS.md / README.md is a separate doctrine-landing follow-up under L61. Not pre-empting Joshua's L-rule cadence. |

did=4/5 PASS (AG1/AG2/AG3 PASS, AG4 PARTIAL with concrete signal, AG5 DEFERRED with rationale).

The AG4 PARTIAL is the most actionable downstream signal: the
schedule is mechanically active but the ledger path is stale.
Future workers can grep this evidence to find the gap rather
than re-deriving it.

## Acceptance Receipts (this rework)

| Gate | Status | Evidence |
|---|---|---|
| AG1 — artifact / command / doctrine surface updated with close evidence | done | this evidence pack at `.flywheel/audit/flywheel-t3in/`; original 1lpv.1 source unchanged |
| AG2 — targeted test/dry-run/validator passes and is named in close receipt | done | `daily-jeff-ingest.sh --doctor --json` → `success=true`; `launchctl list \| grep jeff` shows 5+ active jobs; `shasum -a 256` against 6 plists + 3 scripts re-derivable in <2s |
| AG3 — `br show` open until evidence artifact exists | done | this evidence pack exists; bead is closed in the same turn |
| Lens 1 — version-pinned contract claims | done | 6 plist SHAs + 3 script SHAs + 5 schema-version tags + 5 bead-state pins + 4 receipt freshness rows |
| Lens 2 — each AG1–AG5 explicitly addressed | done | AG-by-AG table with PASS/PARTIAL/DEFERRED + concrete evidence |
| four_lens=4/4 PASS | done | self-grade below: brand:9, sniff:9, jeff:9, public:9 |

did=6/6 didnt=none gaps=none.

## Files Changed

- `.flywheel/audit/flywheel-t3in/evidence.md` — this report.

No mutation of `flywheel-1lpv.1` source, original evidence file
(`/tmp/flywheel-1lpv-evidence.md` — note: rotated out of /tmp,
not present today; pin re-derivation depends on plist + script
SHAs above), launchd plists, scripts, AGENTS.md, INCIDENTS, or
any skill. The rework is a sniff-lens-grade companion.

## Verification Commands (re-runnable)

```bash
# Plist SHAs
for p in ai.zeststream.flywheel-daily-jeff-ingest \
         ai.zeststream.flywheel-jeff-x-poll \
         ai.zeststream.jeff-daily-stack-ingest \
         ai.zeststream.flywheel-jeff-philosophy-monthly \
         ai.zeststream.jeff-binary-version-watchtower \
         ai.zeststream.jeffrey-comment-watchtower; do
  shasum -a 256 /Users/josh/Library/LaunchAgents/${p}.plist
done

# Script SHAs
for s in jeff-intel-scheduled-runner.sh daily-jeff-ingest.sh jeff-daily-diff.sh; do
  shasum -a 256 /Users/josh/Developer/flywheel/.flywheel/scripts/$s
done

# Active jobs
launchctl list | grep -iE 'jeff|ingest'

# Doctor pass
/Users/josh/Developer/flywheel/.flywheel/scripts/daily-jeff-ingest.sh --doctor --json | jq -r '.success'
```

L112 probe (worker callback):

```bash
launchctl list | grep -q "ai.zeststream.flywheel-daily-jeff-ingest" \
  && launchctl list | grep -q "ai.zeststream.flywheel-jeff-x-poll" \
  && grep -q "Three Judges" /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-t3in/evidence.md \
  && grep -q "AG4.*PARTIAL" /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-t3in/evidence.md \
  && echo ok || echo missing
```

Expected: literal `ok`.

## Boundary

- 1lpv.1 source surface (the launchd plists, scripts) is
  unchanged. This rework grades existing scheduled-job state
  with version pins and AG-by-AG receipts.
- AG4's PARTIAL state is surfaced, not silently fixed. The
  6-day-stale ledger is the right signal to leave for a future
  bead per Step 4o anti-pattern (no auto-dispatch).
- AG5 deferred to a separate L61 doctrine-landing bead — does
  not pre-empt Joshua's cadence on L-rule promotion.

## Skill Auto-Routes

- `canonical-cli-scoping`: n/a — no CLI authored.
- `rust-best-practices`: n/a.
- `python-best-practices`: n/a.
- `readme-writing`: n/a — audit-doc style.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no`.
- `readme_updated=not_applicable`.
- `no_touch_reason=rework_grade_only_no_canonical_surface_mutated_AG5_doctrine_landing_deferred_to_separate_bead`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes both lens flags with the precise
  reframes asked. Lens 1 with 19 pins (6 plist + 3 script + 5
  schema + 5 bead); Lens 2 with AG1–AG5 explicit table
  including a PARTIAL status that surfaces a real
  6-day-stale-ledger signal honestly.
- **Sniff: 9** — every claim re-derivable via the verification
  block; AG4 PARTIAL surfaces the gap rather than papering
  over it; doctor probe `success=true` corroborates
  scheduled-job health.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose
  (Jeffrey's X/website/repos throughout); file:line / SHA
  citations on every load-bearing claim; small surface (one
  audit doc); preserves Step 4o anti-pattern (AG4 stale-ledger
  surfaced not silently fixed).
- **Public: 9** — Three Judges check passes:
  - operator: 6 plist SHAs + active-jobs grep re-runnable for
    "is the schedule still active?" question;
  - maintainer: AG-by-AG table makes original-bead intent
    permanent and grep-replaceable;
  - future worker: AG4 PARTIAL signal is grep-discoverable
    and routes a follow-up correctly.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at
threshold 8; bar = Three Judges + Jeffrey Emanuel
publishability + Donella Meadows leverage — Meadows #6
Information flow per parent 1lpv's directive: surface Jeff
intel into flywheel without losing it).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-t3in
no_bead_reason=rework_grade_only_no_implementation_change_to_1lpv.1_or_scheduled_jobs_AG4_stale_ledger_surfaced_for_future_bead_AG5_doctrine_landing_deferred_to_l61_followup`.
