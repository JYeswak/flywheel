# flywheel-2xdi.22 Compliance Pack

Task: `flywheel-2xdi.22-6636c5`
Bead: `flywheel-2xdi.22`
Decision: DONE
Compliance score: 870/1000

## Finding

`gap-hunt-probe.sh probe_wired_but_cold()` (lines 415-440) iterates every
`*.sh` under `~/.claude/skills` and `<repo>/.flywheel/scripts`, and flags any
script whose basename or stem doesn't appear in
`recent_ledger_text()` — the union of all `~/.local/state/flywheel/*.jsonl`
files modified in the last 30 days
(`gap-hunt-probe.sh:355-376`).

`agent-mail-identity-audit.sh` is documented as load-bearing in three
canonical surfaces:

- `/Users/josh/.claude/commands/flywheel/status.md:70` — Step 4b "Agent Mail
  identities" runs the script and renders a dashboard line
- `/Users/josh/.claude/commands/flywheel/respawn.md:210` — post-respawn
  identity audit hook
- `/Users/josh/.claude/skills/.flywheel/INCIDENTS.md:145` — names the script
  as the canonical mechanism for retired/missing identity recovery

But none of those invocations were producing JSONL state ledger rows, so
the cold-wire probe couldn't see them. The script ran fine — its callers
just didn't log it to a sampled surface.

## Repair

Edited the script to self-log on every invocation:

- Added `LEDGER` env-overridable path (default
  `$HOME/.local/state/flywheel/agent-mail-identity-audit.jsonl`)
- Added `emit_and_log()` helper that enriches the existing JSON output
  with `ts`, `script`, `schema_version="agent-mail-identity-audit.v1"`
  before appending to the ledger, and still prints the unenriched JSON
  to stdout so existing consumers (`/flywheel:status`, `/flywheel:respawn`)
  see the same shape they had before
- Replaced all four output paths (no_token_dir noop, db_unreadable noop,
  missing-jq-or-sqlite3 error, completed result) with the
  `emit_and_log` wrapper

The bead's gap is closed because:
1. The next time `/flywheel:status` runs Step 4b, the ledger row is
   appended.
2. The script's basename (`agent-mail-identity-audit.sh`) and stem
   (`agent-mail-identity-audit`) now appear in the ledger that
   `recent_ledger_text()` samples.
3. The gap-hunt-probe will not re-file `wired-but-cold:.claude-skills-.flywheel-scripts-agent-mail-identity-audit.sh`
   so long as the script ran at least once in the last 30 days.

## Acceptance Gate Map

The bead's only test gate is implicit: the gap-hunt-probe should no longer
surface `wired-but-cold:.claude-skills-.flywheel-scripts-agent-mail-identity-audit.sh`.

- AG1: post-edit gap-hunt-probe re-run returns empty for that gap id. ✓
  (`hits=[]`)

did=1/1

## Evidence

```text
$ bash -n /Users/josh/.claude/skills/.flywheel/scripts/agent-mail-identity-audit.sh
(no output = OK)

$ ls -la ~/.local/state/flywheel/agent-mail-identity-audit.jsonl
ls: ... No such file or directory       # pre-edit / pre-run

$ /Users/josh/.claude/skills/.flywheel/scripts/agent-mail-identity-audit.sh
{"action":"completed","healthy":["LavenderGlen","RubyCreek"],...,
 "dashboard_line":"Identities: 2/2 healthy, 2 retired (auto=0 peer=2)"}

$ ls -la ~/.local/state/flywheel/agent-mail-identity-audit.jsonl
-rw-r--r-- 1 josh staff 477 May 9 07:07
                                        # post-run: ledger exists, 1 row

$ tail -1 ~/.local/state/flywheel/agent-mail-identity-audit.jsonl | jq '.ts, .script, .schema_version'
"2026-05-09T13:07:..."
"/Users/josh/.claude/skills/.flywheel/scripts/agent-mail-identity-audit.sh"
"agent-mail-identity-audit.v1"

$ bash .flywheel/scripts/gap-hunt-probe.sh \
  | python3 -c 'import json,sys; d=json.load(sys.stdin);
                hits=[g for g in d.get("gap_ids",[])
                      if "agent-mail-identity-audit" in g];
                print("post-fix hits:", hits)'
post-fix hits: []
```

## Scope

- Edits: 1 file (`/Users/josh/.claude/skills/.flywheel/scripts/agent-mail-identity-audit.sh`,
  165 → 187 lines = +22 lines for self-logging)
- Files reserved/released: that path
- Out of scope: the 20 other `wired-but-cold` gaps that the same
  gap-hunt-probe run reports — those are separate scripts with their
  own beads. Doing them in this dispatch would be scope creep.

## L52 / L80 / L120 / L61

- DIDNT: none
- GAPS: none new (the 20 other wired-but-cold gaps pre-existed and are
  out of this bead's scope)
- beads_filed: none
- beads_updated: none
- no_bead_reason: single-script-self-log-no-followup-needed
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable — script-level self-log is not
  doctrine surface; the doctrine surfaces (status, respawn, INCIDENTS)
  already cite the script and don't need editing
- readme_updated: not_applicable

## Four Lens

- Brand: 8 (self-logging convention matches the doctrine the script is
  load-bearing for; ledger schema versioned at v1 so future probes can
  evolve without breaking)
- Sniff: 9 (pre/post evidence: ledger absent before, present after with
  enriched timestamped row; gap-probe re-run confirms; bash -n clean;
  stdout shape preserved)
- Jeff: 7 (no Jeff-substrate touch)
- Public: 8 (a future maintainer reading the script header sees the
  fix-bead reference `flywheel-2xdi.22` and the wired-but-cold rationale;
  the LEDGER env var is overridable for tests)

## Skill Auto-Routes

- canonical-cli-scoping: n/a — script's surface (no flags, json-on-stdout)
  unchanged; no new CLI added
- rust-best-practices: n/a — no Rust
- python-best-practices: n/a — no Python touched (script is bash)
- readme-writing: n/a — no README touched

## L112 Probe

```
test -f /Users/josh/.local/state/flywheel/agent-mail-identity-audit.jsonl \
  && jq -e '.script == "/Users/josh/.claude/skills/.flywheel/scripts/agent-mail-identity-audit.sh"' \
       /Users/josh/.local/state/flywheel/agent-mail-identity-audit.jsonl
```
Expected: `jq:.script=="<script-path>"` returns `true` on the latest
ledger row. Equivalent simpler probe:

```
grep -c "agent-mail-identity-audit" /Users/josh/.local/state/flywheel/agent-mail-identity-audit.jsonl
```
Expected: `literal:>=1`.
