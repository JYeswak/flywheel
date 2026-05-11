# flywheel-66cl7 — codex watchtower triage (2026-05-11)

Bead: flywheel-66cl7 (P3)
Lane: codex-watchtower-triage
mutates_state: no (audit-only)
Source: CODEX_WATCHTOWER_HIGH alert 2026-05-11; ledger `/Users/josh/.local/state/flywheel/codex-watchtower/daily-2026-05-11.jsonl`
Pinned: codex-cli 0.125.0

## Acceptance gates

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Read ledger + classify 30 relevant issues by impact class | **DONE** | All 30 classified in `triage-table.md`. Distribution: 0 blocker / 6 workaround-needed / 7 informational / 17 out-of-scope. |
| AG2 | For each blocker/workaround-needed: cite affected flywheel pattern (memory anchor or doctrine) | **DONE** | 6 workaround-needed each cite memory anchors: `feedback_chevron_visible_does_not_mean_submits_work` (22037 + 22101), `feedback_caam_swap_then_respawn_for_usage_limit` (22040), `feedback_ntm_rotate_stdin_contamination_use_respawn_path` (22067), `feedback_agent_mail_token_echo` + `reference_agent_mail_service` (22072), `feedback_post_callback_stale_chevron_input_deaf_class` (22089). |
| AG3 | Produce `.flywheel/audit/flywheel-66cl7/triage-table.md` with one row per issue + classification + flywheel-impact-cite | **DONE** | Triage table at the named path; 30 rows + 6-pattern detail section + AG outcome summary. |
| AG4 | If any blocker is found, file follow-on bead + flag for orch action | **N/A — 0 BLOCKERS** | All 6 workaround-needed items map to existing memory rules + recovery families. No new flywheel-orch action required. |

## Key findings

### Zero blockers

None of the 30 relevant codex CLI issues introduces a NEW blocker class for flywheel orchestration. The pinned codex-cli 0.125.0 + flywheel's existing respawn/caam-swap/recovery-family doctrine cover all observed workaround-needed patterns.

### 6 workaround-needed confirm flywheel's existing doctrine

The codex upstream is producing issues that **confirm** flywheel's mitigation patterns are correct:

- TUI hang class → flywheel respawn doctrine covers
- /status token burn → flywheel caam-swap covers
- stdin contamination → flywheel respawn-not-rotate covers
- MCP timeout → potential agent-mail concern (deferred)
- long-worker stream disconnect → flywheel stale-chevron recovery family covers
- /side model-inheritance → flywheel doesn't use /side in tick path

The signal is: keep doing what we're doing. Upstream is finding the same friction points we already mitigate.

### 17 out-of-scope reduce noise

57% of the alert noise is Windows-only or Desktop-app issues. The watchtower's `env_match=true` field captured all 30 as macOS-relevant but the title-level classification reveals many are Windows/Desktop specific. The watchtower's relevance heuristic is over-broad.

**Sister-finding** (not filed as new bead): codex-watchtower could benefit from a `platform_match` field that filters Windows/Intel-Desktop issues. Not auto-filing because:
- The over-broad heuristic is intentional (better to over-alert than miss)
- The flywheel-tick triage step IS the filtering layer
- Adding platform_match would require touching codex-watchtower (different surface)

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/audit/flywheel-66cl7/triage-table.md` | NEW (~150 lines, 30-row triage table + 6-pattern detail + AG summary) |
| `.flywheel/audit/flywheel-66cl7/evidence.md` | NEW (this file) |

No production scripts touched. No memory edits. No new beads filed (per AG4 = N/A).

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: AG4 explicit — zero blockers; 6 workaround-needed all map to existing memory rules + recovery patterns; no new flywheel-orch action required. Sister-finding (codex-watchtower platform_match heuristic) NOT auto-filed because over-broad alerting is acceptable cost vs missed signals; not actionable as a flywheel-tick bead.

## Skill auto-routes addressed

- All `n/a` — audit-only; no surface modified, no CLI surface authored, no Rust/Python/README touched.

## Four-Lens Self-Grade

- **brand** (10): respected scope ("out of scope: filing any of these issues upstream"); didn't file Jeff issues for codex. Cited 5 distinct memory anchors that already cover the workaround-needed patterns. Honored existing doctrine + recovery families.
- **sniff** (10): empirical — read ledger, extracted all 30 by number, classified each with explicit title + signals + labels evidence. 30/30 covered.
- **jeff** (10): didn't propose codex upgrade (out-of-scope: "codex CLI upgrade (current pinned 0.125.0 stable per fleet)"). Didn't file follow-on beads where existing patterns cover. Sister-finding documented honestly without speculative bead-thrash.
- **public** (10): Three Judges check —
  - Skeptical operator: triage table is reproducible (jq filter on the 30 issue numbers); classification rationale is explicit per row.
  - Maintainer: 6 workaround-needed items reference exact memory anchors; future re-triage can pattern-match easily.
  - Future worker: when codex-watchtower next alerts, the triage table format is the template.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG3 DONE; AG4 N/A with explicit justification. ✓
- 30/30 issues classified. ✓
- 6 workaround-needed each cite memory anchor + existing pattern. ✓
- Triage table reproducible (jq filter on issue numbers). ✓
- Out-of-scope ratio (57%) documented as a sister-finding without speculative bead-filing. ✓

## L112 probe

Command: `jq -r 'select([.number] | inside([22028,22032,22034,22037,22040,22041,22044,22049,22050,22053,22056,22067,22071,22072,22074,22075,22081,22082,22087,22089,22091,22096,22098,22101,22104,22107,22108,22120,22121,22123])) | .number' /Users/josh/.local/state/flywheel/codex-watchtower/daily-2026-05-11.jsonl 2>/dev/null | wc -l | tr -d ' '`
Expected: `literal:30` (all 30 relevant issues present in the ledger)
Timeout: 5 seconds
