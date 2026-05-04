# Lane A — Problem-Space Inventory: agent-security-controls-fleet-wide

Plan: `agent-security-controls-fleet-wide-2026-05-04`
Phase: `1.RESEARCH`
Lane: `A — problem-space inventory`
Worker: `flywheel:2 codex`
Generated: `2026-05-04`

Lane A scope: enumerate the problem only. No settings edits, no hook edits, no commits, no bead closes.

## Evidence Ledger

- Intent packet: `.flywheel/plans/agent-security-controls-fleet-wide-2026-05-04/00-INTENT.md`
- Probe evidence: `/tmp/agent-security-lane-a-probes.json`
- Home Claude settings probe: `/Users/josh/.claude/settings.json` exists, `permissions.deny` count is `0`
- Fleet scope source: `.flywheel/scripts/sync-canonical-doctrine.sh --dry-run --json`
- Current fleet scope count observed: `18` repos, not the packet's older `17`; this is `17` non-source targets plus canonical source repo `flywheel`
- Socraticode survey: 3 searches against `/Users/josh/Developer/flywheel`
- Pane scrollback sample: `ntm copy <session>:<pane> --last 800 --output /dev/stdout --quiet --redact off --allow-secret`, counts only, no values printed
- Worktree check: `git status --short` showed pre-existing dirty state; Lane A only adds this plan artifact and generated `/tmp` probe evidence

## Skills Best-Practices Matches

Slash command requested: `/flywheel:skills-best-practices "agent security secrets deny rules" --top=10`.
In this Codex worker context I used the equivalent skill search MCP query for `agent security secrets deny rules`, then read the relevant skill bodies.

| Skill | Decision | Rationale |
|---|---:|---|
| `agent-security` | ADOPT | Primary framing: agents are attack surfaces; output filtering, audit logging, sandboxing, and credential management are baseline controls. |
| `mcp-secret-scanner` | ADOPT | Pattern catalog for detecting literal bearer/API tokens in Claude/Codex/MCP config surfaces without printing secret values. |
| `cryptography-and-auth` | ADOPT | Taxonomy reference for API keys, tokens, key lifecycle, vault use, and access-control blast radius. |
| `agent-sandboxing` | ADOPT | Isolation model for filesystem, egress, and short-lived secret injection. |
| `infisical-secrets` | EVALUATE | Vault context and local cache failure modes, especially `infisical-load --export` and cache files. |
| `infisical-rotation-ops` | EVALUATE | Rotation discipline: never auto-rotate without explicit approval; useful for Lane C rollback/remediation design. |
| `agent-mail` | ADOPT | Agent-mail registration tokens are a live orchestration credential class and already have L58 trauma context. |
| `secret-output-probe-error` | ADOPT | Existing trauma pattern for secrets escaping through command output, stderr, or test failure logs. |

## Socraticode Survey

Queries run against canonical path `/Users/josh/Developer/flywheel`:

1. `agent security secrets deny rules settings.json doctor signals secret scanner`
2. `settings_deny_rules env_in_gitignore pre_commit_secret_hook_present leaked_secret_pattern_count`
3. `secret leak runtime output pane scrollback receipt files agent mail tokens`

Relevant hits:

- `templates/josh-request-schema.md` already defines a scrubbed placeholder contract: `[SCRUBBED:<class>]` for classes including API keys, JWTs, bearer tokens, Slack tokens, and agent-mail token fields.
- `AGENTS.md` L58 already identifies agent-mail tokens in pane text as forbidden because pane scrollback is copied, searched, summarized, and logged.
- `AGENTS.md` L67 documents cached truth and stale pane capture risks, which directly applies to scrollback-based secret persistence.
- `templates/fuckup-heuristics.json` already treats token leakage in quoted command arguments as a promotion-worthy trauma class.

## A.1 Leak Vector Taxonomy

Zodchii's three base vectors are real and current:

1. Direct file read: `.env`, `.env.*`, `.pem`, `.key`, `secrets/`, `credentials/`, `.aws/`, `.ssh/`, MCP config, Codex config, Claude settings, launchd plists.
2. Runtime output capture: test failures, command stderr, HTTP error logs, database connection-string dumps, CLI `--debug` traces, stack traces.
3. Grep/search hits on config files: `rg`, `grep`, Socraticode indexing, code review tools, "find all env vars" tasks.

Additional vectors Lane A found or classifies as in-scope:

4. Pane scrollback and alternate-screen capture via `ntm copy`, health probes, death RCA, robot-tail logs, and worker evidence capture.
5. Agent-mail registration/sender tokens visible in callbacks, `send_message` args, pane text, or mail archive copies.
6. Infisical export/cache files: `infisical-load --export`, `~/.opencode/secrets/infisical-cache.env`, `~/.config/infisical/*-cache.env`.
7. Shell history and process argv: `export TOKEN=...`, `curl -H "Authorization: Bearer ..."` and tool command transcript logging.
8. Git history: deleted `.env` files, `.env.prod`, `.env.local`, or fixture files still present in commit history.
9. Pre-commit bypass: absent hooks or hooks not checking secrets let newly added tokens land silently.
10. Receipt files: validation receipts, doctor receipts, closeout receipts, and evidence ledgers that store raw stdout/stderr.
11. Doctor JSON and daily reports: health probes can surface raw env/config values if subprocess outputs are not scrubbed.
12. Cron/launchd inheritance: plists, `StandardErrorPath`, `StandardOutPath`, and inherited environment leaks.
13. Clipboard/pasteboard: `pbcopy`, copied pane text, browser paste, and transient token transfer between tools.
14. MCP / provider config files: `~/.claude/.mcp.json`, `~/.codex/config.toml`, `~/.mcp.json`, Cursor/Windsurf MCP settings.
15. Browser automation output: cookies, local storage, auth headers, screenshots of dashboards, and HTML error pages.
16. Docker/OrbStack/ComfyUI bind mounts: host secret files exposed inside containers or model/tool workdirs.
17. Vector indexes and corpora: Socraticode/Qdrant, Jeff corpus ingestion, copied issue payloads, and summaries can persist secrets.
18. Notification channels: `notify`, Pushover, mac alerts, Slack, or email bodies containing failed command output.
19. Test fixtures contaminated with realistic keys: `.env.example`, `.env.test`, seeded JWTs, mocked provider payloads.
20. Backup files: `.bak.<ts>`, generated migrations, old settings snapshots, and plan-space captured copies.
21. Private-key material in generic project files: PEM blocks, SSH keys, JWT signing keys, service account JSON.
22. Cross-orch directives: worker packets and callbacks carrying tokens between sessions or projects.
23. Upstream issue/report payloads: Jeff issue reproduction scripts, bug reports, and log excerpts that echo credentials.
24. Agent memory and doctrine surfaces: CASS, memory files, INCIDENTS, and L-rule evidence citations can capture raw examples.

## A.2 Current Exposure Across Flywheel-Installed Repos

Important count note: the dispatch says `17` flywheel-installed repos. Current `sync-canonical-doctrine.sh --dry-run --json` scope reports `18` repos. This matrix uses current discovered truth: `18` repos.

Global settings state:

- `/Users/josh/.claude/settings.json` exists.
- `permissions.deny` count: `0`.
- Home-level deny rules: none.
- Repo-level `.claude/settings.json` deny rules: every repo is either absent or count `0`.

Compliance matrix columns:

- `deny`: repo `.claude/settings.json` deny count; `absent` means no repo settings file.
- `env-ignore`: whether `.gitignore` has an `.env`-class pattern.
- `env-files`: root-level `.env*` files currently present.
- `fixture`: whether an `.env.example`, `.env.test`, or similar fixture exists.
- `prod-env`: whether a non-example `.env*` appears present at repo root.
- `secret-hook`: whether pre-commit surfaces appear to include secret detection.
- `git-env-history`: count of `.env*` paths observed in git history.
- `env-context-hits`: token-shaped references in root `.env*` files only.
- `repo-token-hits`: token-shaped strings from bounded repo-wide `rg`; these include docs/fixtures/false positives and require Lane C confirmation before rotation.

| Repo | deny | env-ignore | env-files | fixture | prod-env | secret-hook | git-env-history | env-context-hits | repo-token-hits |
|---|---:|---:|---|---:|---:|---:|---:|---:|---:|
| `alpsinsurance` | absent | yes | `.env.example`, `.env.local.example`, `.env.production.example` | yes | no | yes | 7 | 0 | 2204 |
| `cfs-expo` | absent | yes | `.env.example` | yes | no | no | 1 | 0 | 101 |
| `comfyui` | 0 | yes | `.env` | no | yes | no | 0 | 0 | 65 |
| `cubcloud-aaas` | 0 | yes | `.env`, `.env.example`, `.env.staging.example` | yes | yes | yes | 0 | 4 | 469 |
| `fleet-commander` | absent | yes | `.env`, `.env.example` | yes | yes | no | 1 | 2 | 67 |
| `flywheel` | absent | no | none | no | no | no | 0 | 0 | 480 |
| `gpu-optimization` | absent | yes | `.env.example` | yes | no | yes | 0 | 0 | 4698 |
| `josh-ops` | absent | no | none | no | no | no | 0 | 0 | 413 |
| `mobile-eats` | absent | yes | `.env.example`, `.env.local` | yes | yes | no | 2 | 1 | 183 |
| `polymarket-pico-z` | 0 | yes | `.env` | no | yes | no | 0 | 0 | 1491 |
| `skillos` | absent | no | none | no | no | no | 0 | 0 | 183 |
| `soundsoftheforest` | absent | no | none | no | no | yes | 0 | 0 | 62 |
| `terratitle` | absent | yes | `.env.example` | yes | no | no | 6 | 0 | 105 |
| `vrtx` | 0 | yes | `.env`, `.env.infisical` | no | yes | no | 0 | 5 | 701 |
| `zeststream-infra` | absent | no | none | no | no | no | 0 | 0 | 430 |
| `zeststream-procurement` | absent | no | none | no | no | no | 0 | 0 | 65 |
| `zeststream-v2-fresh` | 0 | yes | `.env.all`, `.env.dev`, `.env.example`, `.env.local`, `.env.preview` | yes | yes | no | 2 | 48 | 851 |
| `zesttube` | absent | yes | `.env` | no | yes | no | 0 | 1 | 1094 |

Immediate exposure observations:

- `18/18` repos have no effective Claude deny rules at repo level, because repo settings are absent or deny count is `0`.
- `1/1` home Claude settings file has deny count `0`, so no fleet-level deny backstop exists.
- `8/18` repos have no `.env` ignore pattern in the probed root `.gitignore`: `flywheel`, `josh-ops`, `skillos`, `soundsoftheforest`, `zeststream-infra`, `zeststream-procurement`, plus any repo whose ignore file is absent or incomplete.
- `7/18` repos currently show root non-example `.env*` files: `comfyui`, `cubcloud-aaas`, `fleet-commander`, `mobile-eats`, `polymarket-pico-z`, `vrtx`, `zeststream-v2-fresh`, `zesttube` (count is 8 if `.env.infisical` is treated as production-adjacent).
- `13/18` repos do not show a secret-detection pre-commit surface.
- `7/18` repos have `.env*` paths in git history.
- Repo-wide token-shaped hits are nonzero in every repo; these are not all confirmed live secrets, but they prove grep/search and indexing surfaces can encounter token-shaped material.

Token-shaped repo-wide counts by class:

| Class | Count |
|---|---:|
| `anthropic_key` | 5 |
| `xai_key` | 12 |
| `openai_key` | 367 |
| `stripe_live` | 10 |
| `stripe_test` | 14 |
| `aws_access_key` | 585 |
| `github_pat` | 14 |
| `slack_token` | 5 |
| `sendgrid_key` | 9 |
| `jwt` | 63 |
| `private_key_material` | 142 |
| `infisical_ref` | 11884 |
| `agent_mail_token_field` | 303 |
| `supabase_service_role` | 0 |
| `cloudflare_token_ref` | 249 |

Root `.env*` context counts by repo where nonzero:

| Repo | Root `.env*` token-shaped classes |
|---|---|
| `cubcloud-aaas` | `openai_key=2`, `stripe_test=1`, `infisical_ref=1` |
| `fleet-commander` | `openai_key=2` |
| `mobile-eats` | `jwt=1` |
| `vrtx` | `jwt=1`, `infisical_ref=4` |
| `zeststream-v2-fresh` | `anthropic_key=3`, `xai_key=6`, `openai_key=3`, `stripe_test=3`, `github_pat=3`, `sendgrid_key=4`, `jwt=22`, `infisical_ref=4` |
| `zesttube` | `jwt=1` |

Pane scrollback token-shaped sample:

| Sample | Lines scanned | Token-shaped hits | Classes |
|---|---:|---:|---|
| `clutterfreespaces:0` | 338 | 0 | none |
| `clutterfreespaces:1` | 6 | 0 | none |
| `flywheel:1` | 822 | 3 | `openai_key`, `aws_access_key`, `agent_mail_token_field` |
| `flywheel:3` | 816 | 0 | none |
| `mobile-eats:1` | 825 | 6 | `agent_mail_token_field` |
| `mobile-eats:2` | 819 | 6 | `agent_mail_token_field`, `cloudflare_ref` |
| `skillos:1` | 820 | 0 | none |
| `skillos:2` | 813 | 2 | `agent_mail_token_field` |

Pane sample caveat: no values were printed. Regex classes can include false positives, but the nonzero counts prove the scrollback channel is not clean enough to treat as a safe evidence transport.

## A.3 Blast Radius Classification

| Secret type | Current evidence count | Blast radius | What a leak can enable |
|---|---:|---|---|
| Anthropic API keys (`sk-ant-`) | 5 repo-wide, 3 root `.env*` | HIGH | Billable model use, quota drain, prompt/data access through tool workflows, impersonated automation. |
| xAI/Grok keys | 12 repo-wide, 6 root `.env*` | HIGH | Billable model use, workload impersonation, provider account abuse. |
| OpenAI keys | 367 repo-wide, 7 root `.env*` | HIGH | Billable model use, data exfiltration through embeddings/completions, quota drain, automation impersonation. |
| Stripe live (`sk_live_`, `sk-live-`) | 10 repo-wide | CATASTROPHIC | Customer/payment data access, charges/refunds, subscription tampering, webhook abuse. |
| Stripe test | 14 repo-wide, 4 root `.env*` | LOW to MEDIUM | Test data exposure, fixture poisoning, false confidence if used in prod-like flows. |
| AWS access keys (`AKIA`) | 585 repo-wide | CATASTROPHIC | Infrastructure takeover, data access, compute spend, IAM persistence, secrets discovery. |
| GitHub PAT (`ghp_`, `gho_`, etc.) | 14 repo-wide, 3 root `.env*` | HIGH to CATASTROPHIC | Repo read/write, workflow secret access depending scopes, supply-chain mutation. |
| Slack tokens (`xox[bpors]-`) | 5 repo-wide | HIGH | Workspace data access, message impersonation, social engineering, webhook pivots. |
| SendGrid (`SG.`) | 9 repo-wide, 4 root `.env*` | HIGH | Email impersonation, phishing, domain reputation damage, recipient data exposure. |
| JWT (`eyJ...`) | 63 repo-wide, 25 root `.env*` | MEDIUM to CATASTROPHIC | Session impersonation if live, auth bypass, service-to-service access, replay. |
| Private key material | 142 repo-wide | CATASTROPHIC | SSH/service-account compromise, signing-key abuse, persistent infrastructure access. |
| Infisical refs | 11884 repo-wide, 9 root `.env*` | LOW alone, HIGH with token/cache | References reveal secret topology; paired with cache/token gives vault access paths. |
| Agent-mail tokens | 303 repo-wide, pane hits observed | HIGH | Agent impersonation, forged callbacks, message/file-reservation manipulation, cross-pane command injection. |
| Supabase service role keys | 0 observed | CATASTROPHIC if present | Full database bypass of RLS, data extraction/mutation, auth admin operations. |
| Cloudflare API tokens | 249 repo-wide refs/classes, pane class observed | CATASTROPHIC | DNS, access policy, tunnel, worker, and edge configuration takeover depending scopes. |

## A.4 Failure Modes Catalog

1. Claude/agent reads `.env` directly and echoes full content in a response.
2. Runtime command fails and stderr includes provider key, DB URL, bearer token, or JWT.
3. Agent uses `rg`/`grep` over config files and pastes matching lines into chat.
4. Worker dispatch copies secrets into another pane or agent-mail body.
5. Pane scrollback is captured for RCA or evidence and persisted with tokens.
6. Cross-orch directive carries a token-shaped string between sessions.
7. Doctor signal includes raw command output containing secrets.
8. Validation or closeout receipt stores raw stdout/stderr with secrets.
9. Cron/launchd environment inheritance leaks through plist, stdout, stderr, or `launchctl print`.
10. MCP config contains literal bearer tokens and scanner only checks Claude, not Codex.
11. Codex config or tool transcript includes secrets outside Claude hook coverage.
12. `.env.example` or `.env.test` contains realistic production-shaped secrets.
13. Pre-commit hook absent or non-secret-aware allows accidental commit.
14. `.gitignore` ignores current `.env` but git history still retains older `.env.prod` paths.
15. Infisical export/cache file is copied by a support command or indexed by tooling.
16. Shell history stores `export TOKEN=...` or `curl -H Authorization: Bearer ...`.
17. Process list exposes token passed as CLI arg.
18. Browser automation captures dashboard page, request headers, cookies, local storage, or HTML error page.
19. Docker/OrbStack/ComfyUI bind mount exposes host secret file to tool/plugin runtime.
20. Socraticode or Jeff corpus indexes token-shaped files, making future semantic search a leak vector.
21. Backup files `.bak.<ts>` preserve pre-scrubbed settings or env content.
22. Notification body includes failed-command output with secret material.
23. Private key or service account JSON lives in repo-local `credentials/`, `.ssh/`, or generic config path.
24. Agent memory, INCIDENTS, or doctrine evidence cites raw tokens as examples.
25. Auto-fix tool files a bead containing raw failure transcript with token-shaped lines.
26. Secret detector over-redacts fixtures and agents work around it by using real values in tests.
27. Secret detector under-redacts newer provider formats and gives false PASS.
28. Local cache refresh writes secrets to world-readable or repo-indexed path.
29. `ntm copy --allow-secret` used for legitimate counting later gets reused in prose evidence flow.
30. Upstream GitHub issue report includes reproduction script with live environment values.

## A.5 Criticality Matrix

Legend:

- `NO DEFENSE`: current fleet has no observed canonical deny rule and no consistent repo-local control for this cell.
- `PARTIAL`: some repos have `.gitignore` or pre-commit coverage, but not fleet-wide.
- `CONTROL GAP`: class exists in evidence and a defense substrate exists elsewhere, but it is not wired fleet-wide.

| Leak vector | Affected secret types | Current observed defense | Lane A verdict |
|---|---|---|---|
| Direct file read of `.env*` | Anthropic, xAI, OpenAI, Stripe, GitHub PAT, SendGrid, JWT, Infisical refs | Home deny count `0`; repo deny count absent/`0`; `.gitignore` partial | NO DEFENSE for agent read/echo; PARTIAL for git ignore |
| Direct file read of private-key paths | Private keys, SSH, service accounts | No canonical deny rules observed | NO DEFENSE |
| Runtime stderr/stdout capture | All token/API key classes, DB URLs, JWTs | Scrub contract exists in template, not proved fleet-wide on command output | CONTROL GAP |
| Grep/search over repo files | All token/API key classes; repo-wide counts nonzero in all repos | No canonical deny rules; no observed search scrubber | NO DEFENSE |
| Pane scrollback capture | Agent-mail tokens, API keys, Cloudflare refs, copied callbacks | L58 doctrine exists; pane sample still has token-shaped hits | CONTROL GAP |
| Agent-mail message/callback payload | Agent-mail tokens, API keys, command outputs | Some redacted sender scripts exist in flywheel, not fleet-wide | CONTROL GAP |
| Infisical export/cache | Vault tokens, provider keys, DB URLs | Skill doctrine exists; no fleet doctor signal in this plan yet | CONTROL GAP |
| Git commit path | `.env*`, keys, fixtures, provider tokens | 5/18 repos show secret-detection hook; 13/18 no observed hook | PARTIAL |
| Git history | Historical `.env*` and fixtures | `.gitignore` cannot repair history; no current historical scanner signal | NO DEFENSE |
| Receipt files | All command-output leaks | Validation schema exists, but secret-scrub enforcement not observed in Lane A | CONTROL GAP |
| Doctor/daily report JSON | All command-output leaks | Existing doctor fields do not include secret detector field for this plan | CONTROL GAP |
| Cron/launchd logs | Env vars, tokens in stdout/stderr | No fleet-wide probe observed in Lane A | NO DEFENSE |
| MCP/Codex/Claude config | Bearer tokens, API keys | `mcp-secret-scanner` skill exists; no mandatory fleet scan observed | CONTROL GAP |
| Vector/corpus indexing | Any token in indexed repo/corpus | Socraticode used; no confirmed secret-exclusion proof in Lane A | NO DEFENSE until Lane B/C verify |
| Notification output | Any token in alert text | Notify doctrine says use sparingly; no scrubber proof | CONTROL GAP |

Highest-risk unprotected cells:

1. Direct `.env*` read × live provider/API keys × HIGH/CATASTROPHIC.
2. Grep/search × AWS/private keys/Stripe live/GitHub PAT × CATASTROPHIC.
3. Runtime stderr/stdout × DB URLs/JWT/API keys × HIGH/CATASTROPHIC.
4. Pane scrollback × agent-mail tokens × HIGH.
5. Git history × formerly committed `.env*` paths × HIGH/CATASTROPHIC if values were real.
6. Vector/corpus indexing × any secret type × HIGH because persistence and retrieval are indirect.

## A.6 Three-Q Audit

VALIDATED:

- Per-repo compliance claims are checked from filesystem and git probes in `/tmp/agent-security-lane-a-probes.json`.
- Home settings deny count is checked with `jq` against `/Users/josh/.claude/settings.json`.
- Fleet scope is checked through `.flywheel/scripts/sync-canonical-doctrine.sh --dry-run --json`.
- Pane scrollback claims are checked through `ntm copy` count-only samples; no matched values were printed.
- Repo-wide token counts are token-shaped pattern counts, not assertions of live credentials.

DOCUMENTED:

- Evidence paths are listed in the evidence ledger.
- Matrix rows include each repo's deny state, `.env` ignore status, root env files, fixture presence, pre-commit secret hook presence, git-history env paths, and token-shaped counts.
- Skill and Socraticode sources are cited with one-line rationale.

SURFACED:

- Lane B should design the control pattern: settings deny rules, scanner scope, scrubber points, and ecosystem fit.
- Lane C should design implementation: canonical deny block, root/repo propagation, doctor field, pre-commit hook, fixture policy, pane/receipt scrub probes.
- Critical cells to prioritize: direct `.env*` reads, grep/search output, runtime output capture, pane scrollback, git history, vector/corpus indexing.

## A.7 Ladder Check

Read-only discipline:

- No source implementation files edited.
- No settings files edited.
- No hooks edited.
- No commits made.
- No beads closed.
- Output artifact written: `.flywheel/plans/agent-security-controls-fleet-wide-2026-05-04/01-RESEARCH-A.md`.
- Supporting evidence file generated under `/tmp`: `/tmp/agent-security-lane-a-probes.json`.

Ladder verdict: `ladder_passed=yes`.

L70 chain-forward:

- `ntm health flywheel --json` shows `flywheel:3` is a running idle Codex pane.
- Lane A does not have the Lane B packet body; queue recommendation is to dispatch Lane B to `flywheel:3` with this artifact as required reading.
