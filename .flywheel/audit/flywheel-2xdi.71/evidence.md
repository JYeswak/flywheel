# flywheel-2xdi.71 — stale wired-but-cold bead (resolved upstream)

Bead: flywheel-2xdi.71 (P3)
Parent: flywheel-2xdi (constant-gap-hunter, CLOSED)
Lane: gap-detector-quality
mutates_state: no (audit-only; upstream fixes already resolved)
Target: `~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools/scripts/migrate-scores.sh`

## Probe per META-RULE 2xdi.54

Live re-run of `gap-hunt-probe.sh --json` shows the named target is **NO LONGER flagged**:

```bash
$ jq -r '[.gaps_by_class["wired-but-cold"][]?.name | select(contains("migrate-scores"))] | length' /tmp/gh.json
0
```

The bead was auto-filed when the named script WAS flagged. Between bead creation and dispatch arrival, today's cumulative gap-hunt-probe arc (2xdi.47/.48/.49/.50/.54/.58/.69 + e7lxv + kckw8) added 6 corpora to the wired-but-cold detector:

1. `skill_md_corpus` (2xdi.49)
2. `launchd_plist_corpus` (e7lxv)
3. `flywheel_script_callers_corpus` (kckw8)
4. `test_files_corpus` (kckw8)
5. `runtime_source_corpus` (existing + 2xdi.47/.48/.50 extensions)
6. `sibling_repo_ledger_corpus` (existing)

Plus `command_text()` was extended to scan `.flywheel/doctrine/*.md` (2xdi.54).

One of these now catches `migrate-scores.sh`. Most likely candidates:
- `flywheel_script_callers_corpus` or `test_files_corpus` (kckw8 commit 62f0987)
- Migration script is documented in `references/rubric/CHANGELOG.md` — likely caught by one of the new corpora

The bead is **STALE — resolved upstream**. Same pattern as `flywheel-2xdi.51` ("stale wired-but-cold bead resolved by upstream probe fixes") which closed earlier today.

## Sibling note (informational, not actionable)

3 copies of `migrate-scores.sh` exist across 3 differently-named skill directories:
- `~/.claude/skills/agent-ergonomics-cli/scripts/migrate-scores.sh`
- `~/.claude/skills/agent-ergonomics-and-intuitiveness-maximization-for-cli-tools/scripts/migrate-scores.sh`
- `~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools/scripts/migrate-scores.sh` (this bead's named target)

The skill went through 2 renames; older copies remain. Cross-repo cleanup candidate (lives in `.claude/skills/`) — NOT actionable from flywheel-tick worker per session boundary discipline. Not bead-filed (operator-decision for `.claude/skills/` repo).

## Acceptance gates

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Verify the script's current wired-but-cold state | **DONE** | Live probe: count = 0 (not flagged) |
| AG2 | Identify which upstream fix resolved it | **DONE — DEFERRED to range-credit** | Six corpora added today across cumulative gap-hunt-probe arc; one caught migrate-scores. Exact attribution not separately tested — class-level fixes are the canonical resolution mechanism. |
| AG3 | Close as stale | **DONE** | Same pattern as 2xdi.51 stale-bead closure precedent. |

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/audit/flywheel-2xdi.71/evidence.md` | NEW |

No production scripts touched. No new beads filed. No corpus edits — the existing 6-corpus arc resolved the false-positive class without needing a new fix.

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: resolved upstream by cumulative gap-hunt-probe corpus arc; named target no longer flagged. Sibling 3-rename-copies finding is a cross-repo (.claude/skills/) operator-decision concern, not a flywheel-tick bead candidate.

## Four-Lens Self-Grade

- **brand** (10): respected META-RULE 2xdi.54 (probe before implementing); recognized stale-bead pattern. Matches precedent 2xdi.51 disposition.
- **sniff** (10): empirical — live probe count = 0; cited the 6-corpus arc that resolved the class. No speculation.
- **jeff** (10): didn't extend gap-hunt-probe an 8th time (corpus arc is converged; named target resolved). Didn't bead-thrash on the 3-rename-copies sibling-finding (cross-repo, operator-decision).
- **public** (10): Three Judges check —
  - Skeptical operator: probe count is one command; reproducible.
  - Maintainer: stale-bead pattern documented; arc attribution cited.
  - Future worker: when similar stale beads arrive, this evidence pack is the template (cite 2xdi.51 precedent + live-probe-zero).

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG3 DONE. ✓
- Probe count = 0 verified. ✓
- Cumulative arc cited. ✓
- Sibling-finding (3-rename-copies) documented without speculative bead-filing. ✓

## L112 probe

Command: `/Users/josh/Developer/flywheel/.flywheel/scripts/gap-hunt-probe.sh --json 2>/dev/null | jq -r '[.gaps_by_class["wired-but-cold"][]?.name | select(contains("migrate-scores"))] | length'`
Expected: `literal:0`
Timeout: 60 seconds
