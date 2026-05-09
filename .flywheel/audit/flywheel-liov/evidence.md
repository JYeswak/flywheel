# flywheel-liov Evidence

Task: `flywheel-liov-b03ac5`
Bead: `flywheel-liov`
Title: [codex-watchtower] daily 2026-05-04 batch — 78 new / 16 relevant
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)

## Disposition

**16/16 issues triaged. ADOPT=0, EVALUATE=5, AVOID=11.**

Per `feedback_jeff_issue_chain` META-RULE this is upstream-issue
triage only — no patches filed against `openai/codex`, no
auto-bead creation. The 5 EVALUATE items are surfaced for Joshua;
the 11 AVOID items don't apply to our environment (macOS + codex
CLI in tmux, no Codex Desktop App in the flywheel automation
substrate, no Windows, no Slack MCP, no codex fork workflow).

Environment baseline: macOS, `codex` CLI at
`/Users/josh/.local/bin/codex`, Codex.app present at
`/Applications/Codex.app/` (Joshua personal use only — flywheel
fleet panes run `codex --dangerously-bypass-approvals-and-sandbox`
via tmux, not the Desktop App).

## Triage Table

| # | State | Title | Verdict | Reason |
|---|---|---|---|---|
| #20871 | OPEN | Codex CLI 401 on Linux VMs despite valid API key — auth.json not updated by `codex login` | EVALUATE | We're macOS native, but auth.json behaviour is cross-platform. Could affect any future headless server run; not blocking today. Track for fix. |
| #20873 | CLOSED | Chat flagged for possible cybersecurity risk | AVOID | Closed, no triage value. |
| #20875 | CLOSED | Tool-contract ambiguity: `exec_command.cmd` lets models over-quote shell operators | EVALUATE-CLOSED | Lessons-learned: closed but directly relevant — DCG already covers most over-quote risks, but the upstream fix prevents Codex tool-call surface from emitting ambiguous shell. Note for our DCG cross-check ledger. |
| #20880 | OPEN | App creates empty `~/Documents/Codex` folder on launch | AVOID | Codex Desktop App, not CLI. Flywheel fleet doesn't use the Desktop App. |
| #20887 | CLOSED | Initial new-chat conversation ignores selected model | AVOID | Closed + Codex App / chat surface. Flywheel uses CLI bypass-approvals only. |
| #20900 | OPEN | Windows Codex Desktop BusyHang on thread-overlay | AVOID | Windows Desktop App; n/a to macOS CLI. |
| #20906 | OPEN | Sandbox launcher unavailable when using `workspace-write` | EVALUATE | Sandbox-flag interaction. We use `--dangerously-bypass-approvals-and-sandbox` (different mode), but related code paths share validation. **Production-relevant if Joshua ever switches a pane to workspace-write.** |
| #20925 | OPEN | mcp-server: `notifications/cancelled` halts work but `tools/call` is never resolved | EVALUATE | We use MCP servers (mcp-agent-mail, plugin:supabase, browsirai, comfyui, ks, mcp-cf-access-shim, plugin_supabase_supabase, socraticode). **Production-relevant for any MCP tool-call that goes through `notifications/cancelled` flow.** Surface to Joshua. |
| #20929 | CLOSED | missing history for /goal | AVOID | Closed; per memory `reference_codex_0_129_goal_mode_2026_05_08`, 0.129 fixed /goal. |
| #20935 | OPEN | Mousing over right edge brings up unrelated dialog | AVOID | Desktop GUI. CLI not affected. |
| #20942 | OPEN | Windows: automations read-only when `sandbox_mode=danger-full-access` (parse_policy rejects DangerFullAccess) | AVOID | Windows-specific parse_policy. Our macOS CLI accepts the bypass flag. |
| #20945 | CLOSED | `codex fork --last` ignores default cwd filtering | AVOID-CLOSED | We don't use `codex fork` in flywheel. Closed already. |
| #20946 | OPEN | Codex App advertises bundled imagegen skill but does not materialize `$CODEX_HOME/skills/.system` | AVOID | Codex App + bundled-skill path. We use `~/.claude/skills/` and per-repo skills, not `$CODEX_HOME/skills/.system`. |
| #20959 | OPEN | Codex Mac App hides unarchived local threads | AVOID | Codex Mac App, not CLI. Joshua personal use only. |
| #20967 | OPEN | Codex App on Windows WSL responding very slow | AVOID | Windows WSL App. |
| #20970 | OPEN | `codex mcp get` shows Slack MCP server but `codex mcp remove slack` says it does not exist | EVALUATE | `codex mcp` CLI subcommand inconsistency. We don't actively manage Slack MCP, but the symmetry bug could affect any MCP we add/remove. **Production-relevant for MCP lifecycle.** Surface to Joshua. |

## Production-affecting items surfaced to Joshua (5 of 16)

The 5 EVALUATE items below are tracked but not auto-filed as
beads — Joshua dispositions whether to file local follow-ups
or wait for upstream fix:

1. **#20871** — auth.json not updated; could bite headless
   server / VM workflow if we ever spin one up.
2. **#20875** (CLOSED, lessons-learned) — Codex tool-call
   shell over-quoting; DCG covers most risks but worth a
   cross-check on our shell-execution surfaces.
3. **#20906** — workspace-write sandbox launcher; related to
   our `--dangerously-bypass-approvals-and-sandbox` code path.
4. **#20925** — mcp-server notifications/cancelled halts work
   without resolving tools/call. **Highest production impact**
   given our MCP usage breadth (8+ MCP servers active).
5. **#20970** — `codex mcp get / remove` symmetry bug; could
   affect MCP lifecycle management on any future server we add.

The other 11 are AVOID-class for the flywheel automation
substrate (macOS CLI in tmux, not Desktop App; not Windows; not
Slack MCP).

## Acceptance Receipts

| Gate | Status | Evidence |
|---|---|---|
| AG1 — artifact / command / doctrine surface updated with close evidence | done | this evidence pack at `.flywheel/audit/flywheel-liov/`; `issues.json` carries the 16-issue snapshot from `gh issue view` |
| AG2 — targeted test, dry-run, or validator command passes and is named in close receipt | done | `gh issue view` per issue cross-checked state + title against the ledger entries; `jq` verifies 16/16 match the ledger's relevant set |
| AG3 — `br show` open until evidence artifact exists | done | this evidence pack exists; bead is closed in the same turn |
| Triage 16 relevant via /flywheel:jeff-issue protocol | done | per-issue verdicts in the table above; no upstream filing this turn (issues belong to `openai/codex`, not Jeffrey's repos; the META-RULE `feedback_jeff_issue_chain` says file issues not patches — we file no upstream PR; codex is OpenAI not Jeffrey) |
| ADOPT/EVALUATE/AVOID verdict per issue | done | 16/16 verdicts assigned (0 ADOPT, 5 EVALUATE, 11 AVOID) |
| Surface production-affecting items to Joshua | done | top 5 EVALUATE items called out in their own section above |

did=6/6 didnt=none gaps=none.

## Files Changed

- `.flywheel/audit/flywheel-liov/evidence.md` — this report.
- `.flywheel/audit/flywheel-liov/issues.json` — 16-issue
  snapshot from `gh issue view --json number,state,title,closedAt`.

No source surface, doctrine, INCIDENTS, canonical, L-rule, or
skill artifact was edited. No upstream issue filed. No PR
against openai/codex. Per `feedback_jeff_issue_chain` META-RULE
discipline: triage stays in the audit dir; production-relevant
items surface to Joshua via this evidence; he disposes whether
to file local follow-up beads.

## Verification Commands (re-runnable)

```bash
# Re-fetch all 16 issue states + titles
for n in 20871 20873 20875 20880 20887 20900 20906 20925 20929 20935 20942 20945 20946 20959 20967 20970; do
  gh issue view "$n" --repo openai/codex --json number,state,title 2>/dev/null
done | jq -s 'length, [.[] | {number, state}]'

# Confirm OPEN-state count
jq '[.[] | select(.state == "OPEN")] | length' \
   /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-liov/issues.json

# Cross-check against ledger
jq -s 'map(select(.relevance == "HIGH")) | length' \
   /Users/josh/.local/state/flywheel/codex-watchtower/daily-2026-05-04.jsonl
```

L112 probe (worker callback):

```bash
jq 'length' /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-liov/issues.json
```

Expected: literal `16`.

## Boundary

- This bead delivers TRIAGE only. The 5 EVALUATE items are NOT
  auto-filed as flywheel beads; Joshua disposes whether to track
  any of them locally.
- No upstream activity (openai/codex is not Jeffrey's repo, but
  same META-RULE applies: file issues not patches; today's
  finding is "no new issue needed — these are already filed
  upstream").
- Codex CLI 0.125.0 pin baseline noted in the bead description;
  current ntm version reports `dev` per earlier session probe;
  any of the EVALUATE items may already be fixed in newer
  releases — re-triage when Joshua next rotates the codex CLI.

## Skill Auto-Routes

- `canonical-cli-scoping`: n/a — no CLI authored or extended.
- `rust-best-practices`: n/a.
- `python-best-practices`: n/a — only `jq`.
- `readme-writing`: n/a.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no`.
- `readme_updated=not_applicable`.
- `no_touch_reason=triage_only_no_doctrine_or_canonical_surface_mutated`.

## Four-Lens Self-Grade

- Brand: 8 — closes a P2 triage cleanly with concrete verdicts
  and a small, well-defined surface (5 EVALUATE items) for
  Joshua to disposition.
- Sniff: 9 — every verdict cites concrete environment criteria
  (macOS vs Windows, CLI vs Desktop App, MCP server presence);
  closed-issue rejections cite memory or upstream fix-shipped
  evidence.
- Jeff: 9 — `feedback_jeff_issue_chain` META-RULE respected
  (no upstream patch, no premature filing); Jeffrey-not-Jeff
  in human-facing prose where applicable (this is openai/codex,
  not Dicklesworthstone, but the META-RULE umbrella applies).
- Public: 9 — operator/maintainer/future worker can rerun the
  verification block in <5s; the 16-issue snapshot is grep-able;
  Three Judges check passes.

## L52 Receipt

`beads_filed=none beads_updated=flywheel-liov
no_bead_reason=triage_only_5_evaluate_items_surfaced_to_joshua_no_local_followup_filed_today_per_feedback_jeff_issue_chain_meta_rule`.
