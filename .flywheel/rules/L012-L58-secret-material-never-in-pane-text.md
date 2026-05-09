## L58 — SECRET-MATERIAL-NEVER-IN-PANE-TEXT

---
id: L58
title: Secret material never in pane-visible text
status: long_term
shipped: 2026-05-02
review_due: 2026-11-02
trauma_class: secret-leak
---

**Rule:** Secret material MUST never be placed in visible pane commands, dispatch packets, callbacks, reports, copied transcript evidence, or doctrine examples. This includes Agent Mail registration tokens, Infisical secret values, API keys, bearer tokens, private keys, password-like values, and any token-shaped fragment long enough to authenticate. Use MCP-native token fields, vault-backed helpers, `~/.flywheel/bin/infisical-safe`, or non-visible sinks; redact before pane capture.

**Why:** Pane scrollback is operational substrate. It is copied by `ntm`, searched by workers, summarized into callbacks, and reused as evidence. Once a `registration_token`, Infisical `secretValue`, or token-shaped fragment is rendered into that substrate, the exposure has already happened before server-side redaction or report hygiene can protect it. This class fired 13 times in 24h across ALPS, skillos, and mobile-eats, then recurred in ALPS through raw Infisical table output. Rule vigilance failed; wrapper, DCG, doctor, and aggregator topology are load-bearing.

**How to apply:**
- Prefer MCP Agent Mail tools with structured token parameters over shell-visible commands or prose snippets containing `registration_token`.
- Prefer `~/.flywheel/bin/infisical-safe` over raw `infisical` for any command that can enumerate or read secrets; key-only listing uses `secrets list --silent --output=json | jq -r '.[].secretKey'`.
- Store and load reusable Agent Mail tokens through vault-backed helpers; do not paste tokens into dispatch packets or callback examples.
- When pane evidence is required, capture through a redacting filter first and report only "token-shaped text observed", never the value.
- Before closing secret-adjacent work, grep changed files and intended reports for `registration_token`, `secretValue`, `--plain`, and long token-shaped fragments.
- Do not rotate tokens solely because a pane showed token-shaped text; Joshua must explicitly ask for token rotation.

**Forbidden outputs:**
- Shell examples that include `registration_token=<value>` or equivalent token material.
- Callback lines, reports, or findings that repeat a token-shaped value from pane scrollback.
- Raw `ntm copy` excerpts from panes known to contain Agent Mail token arguments.
- Dispatch packets that instruct workers to paste registration tokens into terminal commands.
- Raw `infisical secrets list`, `infisical secrets get`, `infisical run`, or `infisical export` in pane-visible command paths; route through `infisical-safe` or a reviewed non-visible sink.
- Automatic "rotate token" recommendations without Joshua's explicit instruction.

**Detection and recovery:**
1. Search pane/report evidence for `registration_token`, `sender_token`, `secretValue`, `--plain`, raw `infisical secrets`, and long token-shaped fragments before relaying.
2. If a hit exists, stop using the raw capture; regenerate a redacted excerpt.
3. Verify repo files and `/tmp` reports are clean; then run `flywheel-loop doctor --json` and inspect `secret_leak_count_1h`, `secret_leak_oldest_age_seconds`, and `.secret_leaks[]`.
4. Log or update the fuckup row with the path/line of the exposure, not the value.
5. Continue with MCP/vault-mediated or `infisical-safe` operations once output hygiene is restored.

**Guard surfaces:** DCG blocks raw value-bearing Infisical command shapes before execution; `infisical-safe` rejects unsafe output formats; `flywheel-loop doctor` auto-pauses on fresh `secret-leak` lock-log rows; `cross-repo-trauma-aggregator.sh` writes class-only global trauma rows without copying free-text secret material. Transcript/output filtering remains a follow-up, not a substitute for these guards.

**Evidence:** `~/.local/state/flywheel/fuckup-log.jsonl` lines 173, 174, 176, 179, 180, 181, 182, 183, 184, 188, 189, 191, and 205; `~/.claude/skills/agent-mail/references/INCIDENTS.md#2026-05-02--agent-mail-token-echo-in-pane-promoted-after-13-transcript-exposures`; `~/.local/state/flywheel/fuckup-processed.jsonl` row 2026-05-02T16:34:16Z; `/tmp/flywheel-secret-leak-foundational-fix.md` lines 14-20 and 24-30.

**Companion rules:** L51 requires Agent Mail reservations before edits; L53 records trauma rows; L56 defines this promotion ladder; the secrets reference (`~/.claude/references/claude-md-secrets.md`) forbids displaying secrets in chat or logs.


