# flywheel-2xdi.32 Compliance Pack

Task: `flywheel-2xdi.32-cf3252`
Bead: `flywheel-2xdi.32`
Decision: DONE
Compliance score: 870/1000

## Finding

`gap-hunt-probe.sh probe_wired_but_cold()` (lines 415-440) flagged
`~/.claude/skills/.flywheel/lib/autoloop-executor.sh` because its
basename / stem doesn't appear in any
`~/.local/state/flywheel/*.jsonl` modified in the last 30 days.

`autoloop-executor.sh` is library code (Phase 3 controlled-executor
module sourced by `bin/flywheel-autoloop`); 17 functions implement
candidate routing, whitelist gates, no-op-ladder, decision-tree
mode, etc. The library IS exercised in production
(`flywheel-autoloop` calls `autoloop_executor_main` at lines 1319
and 2616 of the binary), but the library was never named in the
JSONL state ledgers — only the binary's name showed up.

## Repair

Edited the library to self-log on every `autoloop_executor_main()`
call:

- Added `AUTOLOOP_EXECUTOR_LEDGER` env-overridable path (default
  `$HOME/.local/state/flywheel/autoloop-executor.jsonl`)
- Added `autoloop_executor_log_entry()` helper that writes a
  schema-versioned JSON row (`autoloop-executor.entry.v1`) with
  `ts`, `script`, `mode` fields on every entry
- Inserted the call at the top of `autoloop_executor_main()`
  (line 296, before arg parsing)

This matches the same fix shape as flywheel-2xdi.22's
`agent-mail-identity-audit.sh` self-logging fix: library/script
self-records its name to a JSONL ledger so gap-hunt-probe's
`recent_ledger_text()` finds the basename.

## Acceptance Gate Map

The bead's only test gate is implicit: re-run gap-hunt-probe and
confirm `wired-but-cold:.claude-skills-.flywheel-lib-autoloop-executor.sh`
is no longer in `gap_ids`.

- AG1: post-edit gap-hunt-probe re-run returns empty for the
  cited gap id. ✓ (the original `wired-but-cold` for this script
  is eliminated)

did=1/1

## Evidence

```text
$ bash -n ~/.claude/skills/.flywheel/lib/autoloop-executor.sh
(no output = OK)

$ # Live trigger via decision-tree mode (safe, read-only):
$ ( source ~/.claude/skills/.flywheel/lib/autoloop-executor.sh \
    && autoloop_executor_main --decision-tree --state /tmp/nonexistent ) 2>&1 | head -1
{"schema_version":"flywheel-autoloop.decision-tree.v1","status":"error","reason":"state_missing_or_invalid"}

$ # Ledger row landed:
$ tail -1 ~/.local/state/flywheel/autoloop-executor.jsonl | jq '.'
{
  "ts": "2026-05-09T16:11:40Z",
  "schema_version": "autoloop-executor.entry.v1",
  "script": "/Users/josh/.claude/skills/.flywheel/lib/autoloop-executor.sh",
  "mode": "main"
}

$ # Original wired-but-cold gap gone:
$ bash .flywheel/scripts/gap-hunt-probe.sh \
  | jq -r '.gap_ids[]' | grep -E "wired-but-cold.*autoloop-executor.sh"
(no output — gap eliminated)
```

## Surfaced gap (recommended sibling, not auto-filed per worker scope)

The probe now reports a NEW finding for the ledger file I just
created:

```
cross-source-silos:autoloop-executor.jsonl
```

This is a different gap class (`cross-source-silos`) firing on
the new ledger because no other source surface cites the
`autoloop-executor.jsonl` filename. The natural follow-up is to
add a tick.md / status.md mention of the ledger as one of the
autoloop-substrate canonical paths, OR to add a canonical-paths
entry. That's a separate cross-link concern, not in this bead's
wired-but-cold scope.

Recommended sibling-bead title:
`[autoloop-substrate] cross-link autoloop-executor.jsonl into
canonical paths / tick observability`

## Scope

- Edits: 2 files
  - `~/.claude/skills/.flywheel/lib/autoloop-executor.sh` (added
    self-logging helper + call site)
  - `.flywheel/audit/flywheel-2xdi.32/compliance-pack.md` (this file)
- Files reserved/released: the lib script
- Out of scope: cross-linking the new ledger (recommended sibling
  bead); editing the binary `flywheel-autoloop` (the library's
  self-log fires regardless of which caller invokes it)

## L52 / L80 / L120 / L61

- DIDNT: none
- GAPS: 1 surfaced — `cross-source-silos:autoloop-executor.jsonl`
  (recommended sibling above; not auto-filed per worker scope)
- beads_filed: none
- beads_updated: none
- no_bead_reason: surfaced-cross-link-gap-recommended-for-orch-filing-not-worker-scope
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: not_applicable

## Four Lens

- Brand: 8 (matches the flywheel-2xdi.22 self-logging fix shape;
  inline comment cites this bead as the fix-source for future
  maintainers)
- Sniff: 9 (live trigger via `decision-tree` mode produces ledger
  row; original wired-but-cold gap eliminated; new ledger
  schema-versioned and structured)
- Jeff: 7 (no Jeff-substrate touch)
- Public: 8 (a future operator can replay the trigger + see the
  ledger row + understand the self-logging discipline; the
  inline comment makes the fix self-documenting)

## Skill Auto-Routes

- canonical-cli-scoping: n/a — no CLI surface added
- rust-best-practices: n/a — no Rust
- python-best-practices: n/a — no Python
- readme-writing: n/a — no README

## L112 Probe

```
test -f ~/.local/state/flywheel/autoloop-executor.jsonl \
  && grep -c "autoloop-executor.entry.v1" ~/.local/state/flywheel/autoloop-executor.jsonl
```
Expected: `literal:>=1` (at least one entry-row in the new ledger
proves the self-log path is live).
