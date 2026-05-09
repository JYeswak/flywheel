# flywheel-z6lk3 Codex Watchtower Triage Receipt

Task: `flywheel-z6lk3-530e3b`
Bead: `flywheel-z6lk3`
Date: 2026-05-09
Pinned local CLI: `codex-cli 0.125.0`
Latest observed upstream release: `rust-v0.130.0`, published 2026-05-08T23:09:55Z

## Acceptance Gates

| Gate | Result | Evidence |
|---|---|---|
| AG1 rollout permission janitor loaded and healthy | PASS | `launchctl print gui/$(id -u)/ai.zeststream.codex-rollout-permission-janitor`; janitor ledger latest runs `fixed_count=0`; no group/world-readable rollout files found under `~/.codex/sessions`. |
| AG2 ALPS ACK on #21620 workaround | PASS | `alpsinsurance:1` ACK captured in `/tmp/flywheel-z6lk3-alps-pane1.txt`; ALPS adopted no-new-`agents/` dispatches plus absolute path / alternate target workaround. |
| AG3 re-triage on next high watchtower event | PASS | 2026-05-09 `CODEX_WATCHTOWER_HIGH` re-triaged all 21 relevant issues from `daily-2026-05-09.jsonl`. |

## Sources Checked

- `~/.local/bin/codex-watchtower-daily.sh --doctor --json`
- `~/.local/bin/codex-watchtower-daily.sh --summary --json`
- `/Users/josh/.local/state/flywheel/codex-watchtower/daily-2026-05-09.jsonl`
- `gh issue view <id> -R openai/codex --json number,title,state,labels,url,body`
- `/Users/josh/.claude/skills/codex-cli-tracker/references/UPSTREAM-ISSUES.md`
- `/tmp/flywheel-z6lk3-alps-pane1.txt`

## 2026-05-09 Relevant Issue Triage

| Issue | Classification | Disposition |
|---|---|---|
| #21811 | fleet-affecting | Tmux split can hide the last message. Workaround: rely on durable evidence files, callbacks, and `ntm copy`; avoid scrollback-only proof before resizing/splitting panes. No new bead because existing receipt discipline covers the operational risk. |
| #21814 | fleet-affecting/observe | Org API key request hit TPM/request-size behavior on 0.129.0. Workaround: shrink prompts/context and use capacity gates for API-key lanes. No local action for the pinned ChatGPT CLI fleet. |
| #21824 | fleet-irrelevant | Closed Desktop Browser Use disappearance issue. No CLI/NTM action. |
| #21827 | fleet-affecting/observe | Closed review/tool-call corruption class. Existing tool-scope validation and imagegen policy cover local risk. No new bead. |
| #21828 | fleet-irrelevant/observe | 0.129.0 cursor flicker under Emacs Eat; local fleet is pinned 0.125.0 and does not use Eat. |
| #21836 | fleet-affecting/observe | Closed web-search flood UI issue. Existing durable evidence and scrollback discipline cover local risk. No new bead. |
| #21839 | fleet-irrelevant | Closed Desktop app approval issue. No CLI action. |
| #21841 | fleet-irrelevant | Desktop theme/sidebar issue. No action. |
| #21851 | fleet-irrelevant/observe | Desktop Chrome connection timeout. Observe for browser-automation lanes only. |
| #21858 | fleet-irrelevant/observe | Feature request for mission-entropy bounded subagents; aligned with flywheel doctrine but not an upstream blocker. |
| #21864 | fleet-irrelevant | Desktop pet resize request. No action. |
| #21869 | fleet-affecting | `workspace-write + network_access=true` can push remote changes before local remote-tracking ref update fails. Filed follow-up bead `flywheel-ie2en`. Interim workaround: do not treat sandboxed network git push as complete without post-push local ref reconciliation; prefer full-access/manual push lanes when consistency matters. |
| #21878 | fleet-irrelevant | Windows Desktop Chrome timeout. No action. |
| #21879 | fleet-irrelevant/observe | macOS Desktop Chrome timeout. Observe for browser-automation lanes only. |
| #21880 | fleet-irrelevant | Windows Desktop startup reconnecting issue. No action. |
| #21882 | fleet-irrelevant | Desktop project path/display-name divergence. If Desktop is used later, symlink path workaround may apply; no CLI action. |
| #21883 | fleet-irrelevant | Desktop PR feedback cards issue. No CLI/NTM action. |
| #21900 | fleet-irrelevant/observe | Desktop Chrome bridge unavailable after sleep/wake. Observe for browser automation only. |
| #21902 | fleet-irrelevant | Desktop pet reduced-motion issue. No action. |
| #21903 | fleet-affecting/observe | CLI MCP Streamable HTTP/n8n handshake failure. Workaround: direct endpoint probes or non-Streamable transport for n8n until reproduced locally. No bead because current fleet does not depend on n8n Streamable HTTP MCP. |
| #21908 | fleet-irrelevant/observe | Desktop Chrome plugin backend timeout. Observe for browser automation only. |

## Follow-Up Beads

- Filed `flywheel-ie2en`: `Codex #21869 post-push ref verification gate`.

## Residual Risk

- Local Codex remains pinned to `0.125.0`; upstream `0.130.0` exists, but the codex-watchtower skill forbids upgrading until tracker gates pass.
- Desktop and Chrome-plugin issues remain watch-only for this CLI/NTM fleet unless a future dispatch explicitly targets those surfaces.

## Four-Lens Self Grade

- Brand: 8
- Sniff: 8
- Jeff: 8
- Public: 8
