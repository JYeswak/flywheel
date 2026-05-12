# Lock Comparison 2026-05-07

## Verdict

Use both surfaces, with different jobs.

- Use native `ntm lock`, `ntm locks`, and `ntm unlock` for ordinary Agent Mail file reservations. The NTM implementation is a real facade over MCP Agent Mail reservations, not a parallel lock system.
- Keep the flywheel L107 shared-surface wrapper for pane/task-scoped staging safety. Native NTM does not model `pane`, `task_id`, shared-surface check/release receipts, malformed ledger counts, or flywheel callback evidence.
- Filed Jeff issue `Dicklesworthstone/ntm#125`: `lock/unlock JSON failures exit 0`. NTM lock-family commands can emit `success:false` with process exit 0, which is unsafe for reservation automation.

## Sources

- Bead: `flywheel-7nn2a`
- NTM version observed: `v1.14.0-290-g99c67b31` (`99c67b310485d6ba9ca5d2823dc7b3fec99c39c3`)
- NTM repository surveyed: `/Users/josh/Developer/ntm`
- MCP Agent Mail repository surveyed: `/Users/josh/Developer/mcp_agent_mail`
- Prior W2 issue-body artifacts checked: `/tmp/ntm-wire-in-W2-*-2026-05-07-jeff-issue-body.md`
- Upstream issue filed: https://github.com/Dicklesworthstone/ntm/issues/125

## Socraticode Survey

K=10 was run across the NTM and MCP Agent Mail codebases.

| # | Project | Query focus | Evidence found |
|---|---|---|---|
| 1 | NTM | `ntm lock` command, patterns, ttl, shared, reason, JSON | `internal/cli/lock.go`, `tests/e2e/lock_unlock_test.go` |
| 2 | NTM | `ntm locks list/renew/force-release`, project and agent scope | `internal/cli/locks.go`, `internal/agentmail/tools.go` |
| 3 | NTM | `ntm unlock`, release by patterns and `--all` | `internal/cli/unlock.go`, e2e unlock tests |
| 4 | NTM | Agent Mail adapter and `file_reservation_paths` | `internal/agentmail/tools.go:459-493` |
| 5 | NTM | session-agent mapping and project key resolution | `internal/agentmail/session.go`, lock command callers |
| 6 | MCP Agent Mail | `file_reservation_paths` schema | `src/mcp_agent_mail/app.py:10718-10972` |
| 7 | MCP Agent Mail | release contract | `src/mcp_agent_mail/app.py:10974-11018` |
| 8 | MCP Agent Mail | renew and force-release | `src/mcp_agent_mail/app.py:11146-11515` |
| 9 | MCP Agent Mail | conflict detection | `src/mcp_agent_mail/app.py:4055-4087` |
| 10 | MCP Agent Mail | reservation DB fields and resource listing | `src/mcp_agent_mail/models.py:113-128`, `src/mcp_agent_mail/app.py:13036-13135` |

Indexed chunks observed: NTM `31740`, MCP Agent Mail `2725`.

## Native NTM Surface

`ntm lock <session> <patterns...>` supports:

- `--reason string`
- `--ttl string`, default `1h`
- `--shared`
- global `--json`

`ntm locks` supports:

- `list <session> --all-agents`
- `renew <session> <patterns...> --extend <minutes>`
- `force-release <session> <reservation-id> --note --no-notify --yes`
- global `--json`

`ntm unlock <session> [patterns...]` supports:

- path-pattern release
- `--all`
- global `--json`

Implementation evidence:

- `internal/agentmail/tools.go:459-493`: `ReservePaths` calls MCP Agent Mail `file_reservation_paths` with `project_key`, `agent_name`, `paths`, optional `ttl_seconds`, `exclusive`, and `reason`.
- `internal/cli/lock.go:52-61`: JSON result fields are `success`, `session`, `agent`, `granted`, `conflicts`, `ttl`, `expires_at`, and `error`.
- `internal/cli/unlock.go:40-47`: JSON result fields are `success`, `session`, `agent`, `released`, and `error`.
- `internal/cli/locks.go:71-80`: JSON result fields are `success`, `session`, `agent`, `project_key`, `reservations`, `count`, and `error`.
- `tests/e2e/lock_unlock_test.go:127-392`: e2e coverage exercises lock conflicts, holder reporting, unlock, and unlock-all.

Live probe:

```text
ntm lock flywheel .flywheel/research/lock-comparison-2026-05-07.md --json --reason probe
rc=0
{"success":false,"session":"flywheel","agent":"GrayCreek","ttl":"","error":"Agent Mail server unavailable"}

ntm locks list flywheel --json
rc=0
{"success":false,"session":"flywheel","agent":"GrayCreek","project_key":"/Users/josh/Developer/flywheel","reservations":null,"count":0,"error":"Agent Mail server unavailable"}

ntm unlock flywheel .flywheel/research/lock-comparison-2026-05-07.md --json
rc=0
{"success":false,"session":"flywheel","agent":"GrayCreek","released":0,"error":"Agent Mail server unavailable"}
```

That live probe is the upstream bug filed as `Dicklesworthstone/ntm#125`.

## MCP Agent Mail Surface

`mcp__mcp-agent-mail__file_reservation_paths` accepts:

- `project_key`
- `agent_name`
- `paths`
- `ttl_seconds`, default `3600`, minimum `60`
- `exclusive`, default `true`
- `reason`

It returns:

- `granted[]`: `id`, `path_pattern`, `exclusive`, `reason`, `expires_ts`
- `conflicts[]`: path and holders

Important semantics from `src/mcp_agent_mail/app.py`:

- `10731-10772`: file reservations are advisory; overlapping active exclusive reservations are conflicts; glob matching is symmetric; JSON artifacts are written under `file_reservations/<sha1(path)>.json`; server-side enforcement applies to mail archive paths, while code repo enforcement is via pre-commit guard.
- `10859-10865`: archive write lock plus `BEGIN IMMEDIATE` prevent stale reads and duplicate exclusive holders.
- `10896-10924`: conflict holders are calculated before grant.
- `10974-11018`: release supports all-active release when no filters are provided, or restriction by paths / reservation ids.
- `11146-11515`: force-release and renew are first-class tools.
- `3963-4054`: stale reservations expire before reservation operations.
- `4055-4087`: conflict matching skips released rows, skips same-agent rows, skips shared-vs-shared conflicts, and uses exact / virtual / pathspec / fnmatch symmetric matching.

MCP tests cover lifecycle, exclusive/shared conflicts, shared/shared non-conflicts, path overlap, specific release, force-release stale, same-agent re-reserve update, and concurrent writes.

## Field-by-Field Contract Diff

| Contract field | MCP Agent Mail reservation | NTM lock-family surface | Parity | Notes |
|---|---|---|---|---|
| Project identity | Explicit `project_key` | Resolved from NTM session/project scope | Partial | NTM is safer for pane operators; MCP is more explicit for automation. |
| Holder identity | Explicit `agent_name` | Resolved session agent | Partial | NTM hides identity selection behind session-agent registry. Good operator ergonomics, weaker for scripts that need exact holder control. |
| Path patterns | `paths[]` | positional `<patterns...>` | Full | Both flow to Agent Mail path patterns. |
| Exclusive/shared | `exclusive: true/false` | default exclusive; `--shared` for non-exclusive | Full | Same underlying model. |
| TTL | `ttl_seconds` | `--ttl` duration string, converted before MCP call | Full | NTM default is `1h`; MCP default is `3600`. |
| Reason | `reason` | `--reason` | Full | NTM forwards reason to MCP. |
| Grant receipt | `granted[]` with ids and expiries | JSON includes `granted[]` | Full | NTM preserves reservation ids in JSON. |
| Conflict receipt | `conflicts[]` with holders | JSON includes `conflicts[]`; e2e checks holder shape | Full | NTM uses MCP conflict model. |
| Same-agent re-reserve | Updates/extends existing active reservation | Inherited through MCP | Full | Covered in MCP tests; NTM does not add special behavior. |
| Release by path | `release_file_reservations(paths=[...])` | `ntm unlock <patterns...>` | Full | Same behavior for path-filtered release. |
| Release by id | `release_file_reservations(file_reservation_ids=[...])` | No `unlock --id`; force-release takes id | Partial | Ordinary owner release by id remains MCP-only. |
| Release all | omit filters in MCP release | `ntm unlock <session> --all` | Full | NTM exposes the common form. |
| Renew | `renew_file_reservations(paths|ids, extend_seconds)` | `ntm locks renew <patterns...> --extend <minutes>` | Partial | NTM is path-oriented and minute-oriented; MCP also renews by ids. |
| Force release | `force_release_file_reservation(id, note, notify_previous)` | `ntm locks force-release <reservation-id>` | Full enough | NTM surfaces the operator path. |
| List active reservations | Resource + DB-backed listing | `ntm locks list`; `--all-agents` | Full enough | NTM preserves holder visibility for operator use. |
| Stale expiry | Server expires stale rows before operations | Inherited | Full | NTM relies on Agent Mail server behavior. |
| Advisory artifact | JSON artifact in Agent Mail archive | Inherited indirectly | Full | NTM does not bypass MCP storage. |
| Transaction safety | MCP archive lock + immediate transaction | Inherited | Full | NTM gets this because it calls MCP. |
| Backend unavailable | Tool call would fail/raise at MCP layer | NTM JSON emits `success:false`, but exits 0 | Broken | Filed `Dicklesworthstone/ntm#125`. |
| Stable JSON exit code | Tool error should be programmatically visible | `success:false` can still exit 0 | Broken | This is the dangerous partial-parity gap. |
| Pane identity | Not modeled | Session/pane agent registry exists, but not L107 pane field | Partial | NTM can infer agent, not L107 pane/task proof. |
| Task id | Not modeled | Not modeled | None | L107 needs `task_id` to prove dispatch-owned staging. |
| Reserve/check/release receipt | MCP DB rows and artifacts | NTM JSON for native reservation commands | Partial | L107 wrapper emits specific callback-compatible shared-surface receipts. |
| Check-only local ledger audit | Not part of Agent Mail reservation API | Not present | None | Flywheel wrapper checks local shared-surface reservation state. |
| Doctor probe for wrapper bypass | Not part of Agent Mail | Not present | None | Flywheel doctor should assert L107 surfaces use the wrapper, not only NTM locks. |

## Decision

### Keep NTM for native reservation workflows

`ntm lock`, `ntm locks`, and `ntm unlock` should be the default operator interface for file reservations inside an NTM-managed session. They preserve the important MCP semantics: project scope, holder identity, path patterns, exclusivity, TTL, reason, conflict receipt, release, renew, force-release, stale expiry, and listing.

### Keep L107 flywheel wrapper

The flywheel shared-surface wrapper still carries value not covered by native NTM:

- explicit `--pane`
- explicit `--task-id`
- reserve/check/release callback evidence
- local malformed-ledger and collision checks
- dispatch-specific shared-surface discipline before staging commit-touched files

Deletion tripwire: delete the L107 wrapper only after NTM ships a first-class command that records pane/task-scoped reservation intent, exposes reserve/check/release receipts, supports JSON failure with non-zero exit status, and has a flywheel doctor probe proving dispatch surfaces call that command rather than bypassing it.

### File Jeff issue

Filed `Dicklesworthstone/ntm#125` because the exit-code behavior is upstream-generic and safety-critical:

```text
lock/unlock JSON failures exit 0
https://github.com/Dicklesworthstone/ntm/issues/125
```

The prior W2 bodies were not filed as-is because they contain flywheel-specific paths and L-rule context. The filed issue was scrubbed to a generic NTM contract bug per `jeff-issue-chain` v1.1 doctrine.

## Gaps

1. NTM needs non-zero exit status whenever lock-family JSON returns `success:false`.
2. NTM e2e should include a JSON exit-code assertion for backend unavailable, conflict, missing session agent, and unlock-zero cases.
3. Flywheel doctor should add a probe proving L107 commit-staging surfaces call `.flywheel/scripts/shared-surface-reservation-check.sh` or a future equivalent NTM pane/task command.
4. If NTM grows explicit `--agent`, `--project-key`, `--task-id`, and pane-aware receipt fields, re-evaluate whether direct MCP wrapper calls remain necessary.

## Acceptance Mapping

- K=10 Socraticode against NTM + MCP Agent Mail: complete.
- Field-by-field comparison: complete.
- Verdict: both native NTM and L107 wrapper, with clear boundaries.
- Output artifact: this file.
- Jeff issue: filed as `Dicklesworthstone/ntm#125` with anonymized body.

## Four-Lens Self-Grade

- brand: 9
- sniff: 9
- jeff: 9
- public: 9
