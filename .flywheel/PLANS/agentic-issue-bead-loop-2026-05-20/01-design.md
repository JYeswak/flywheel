# Design — Agentic Issue ↔ Bead ↔ Commit ↔ Push Closed Loop

- **Bead:** `flywheel-wukwc` (P0)
- **Companion docs:** `00-research.md` (Jeff-pattern probe + sources)
- **Prototype:** `.flywheel/scripts/github-issue-bead-sync-prototype.sh` (read-only-against-github)
- **Scope:** v1 = polling, one-way GitHub→bead; v2 (follow-up beads) = bidirectional close, webhook-mode, template-bootstrap

---

## 1. End-to-end flow (v1)

```
┌─────────────────────────┐
│ User/Joshua/agent files │
│ issue on JYeswak/<repo> │
└─────────────┬───────────┘
              │
              ▼
   ┌──────────────────────┐
   │ launchd cron (5min)  │
   │ github-issue-bead-   │
   │ sync.sh              │
   └─────────────┬────────┘
                 │ for each JYeswak repo:
                 │   gh issue list --state open --json ...
                 │   diff vs registry (external_ref)
                 ▼
       ┌────────────────────┐
       │ for each new issue:│
       │  br create         │
       │   --external-ref   │
       │     <issue-url>    │
       │   --slug gh-<repo> │
       │     -<num>         │
       │   --description    │
       │     <issue-body>   │
       │   --labels         │
       │     <gh-labels>    │
       │   --priority P2    │
       └─────────┬──────────┘
                 │ bead-id minted
                 ▼
   ┌──────────────────────────┐
   │ append to registry JSONL │
   │ ~/.local/state/flywheel/ │
   │ issue-bead-sync/         │
   │ registry.jsonl           │
   └─────────────┬────────────┘
                 │
                 ▼
   ┌──────────────────────────┐
   │ orch picks up bead via   │
   │ existing /flywheel:loop  │
   │ → dispatch to worker     │
   └─────────────┬────────────┘
                 │
                 ▼
   ┌──────────────────────────┐
   │ worker implements,       │
   │ commits with footer:     │
   │   Fixes JYeswak/<repo>   │
   │     #<num>               │
   │ + Co-Authored-By trailer │
   └─────────────┬────────────┘
                 │
                 ▼
   ┌──────────────────────────┐
   │ push to origin (existing │
   │ auto-push-ledger flow)   │
   └─────────────┬────────────┘
                 │
                 ▼
   ┌──────────────────────────┐
   │ on PR merge to main:     │
   │ GitHub auto-closes issue │
   │ via "Fixes #N" footer    │
   └─────────────┬────────────┘
                 │
                 ▼
   ┌──────────────────────────┐
   │ next sync tick:          │
   │ issue state=closed       │
   │ → close-reconciler       │
   │ verifies commit pushed   │
   │ → br close <bead-id>     │
   │   --reason "GH issue     │
   │   #N closed via <SHA>"   │
   └──────────────────────────┘
```

---

## 2. Schema — `bead.external_link` representation

For v1 we **do not add a new column**; we use the existing `br create --external-ref <URL>` flag. The URL itself encodes everything we need.

### 2.1 External-ref URL conventions

| Source | URL form | Parse |
|---|---|---|
| GitHub issue | `https://github.com/<owner>/<repo>/issues/<num>` | regex `^https://github\.com/([^/]+)/([^/]+)/issues/(\d+)$` |
| GitHub PR | `https://github.com/<owner>/<repo>/pull/<num>` | regex `^https://github\.com/([^/]+)/([^/]+)/pull/(\d+)$` |
| (future) GitLab/Gitea | `https://gitlab.com/...` | follow-up bead |

### 2.2 Bead labels propagated

Every bead minted from a GitHub issue carries these synthetic labels (in addition to whatever labels the GH issue carries):

- `source:github`
- `source:gh-issue` (vs `source:gh-pr` for PRs filed against us)
- `repo:<owner>-<repo>` (e.g. `repo:JYeswak-flywheel`)

These let `bv` triage filter by source class.

### 2.3 Registry JSONL (one row per minted bead)

Path: `~/.local/state/flywheel/issue-bead-sync/registry.jsonl`

```json
{
  "schema_version": "flywheel.issue_bead_sync.v1",
  "ts": "2026-05-20T20:15:00Z",
  "github_issue_url": "https://github.com/JYeswak/flywheel/issues/12",
  "github_issue_number": 12,
  "github_repo": "JYeswak/flywheel",
  "github_state_at_mint": "open",
  "github_created_at": "2026-05-20T19:55:00Z",
  "github_labels": ["bug","p1"],
  "bead_id": "flywheel-gh-flywheel-12-a3f9",
  "bead_priority": "P2",
  "minted_by": "github-issue-bead-sync.sh@cron",
  "minted_at": "2026-05-20T20:15:00Z"
}
```

Append-only. Doctor probes `tail -n 1` mtime to compute freshness (`last_poll_ts`).

### 2.4 Last-poll-ts state file

Path: `~/.local/state/flywheel/issue-bead-sync/state.json`

```json
{
  "schema_version": "flywheel.issue_bead_sync_state.v1",
  "last_poll_ts": "2026-05-20T20:15:00Z",
  "repos_synced": ["JYeswak/flywheel","JYeswak/zesttube", "..."],
  "minted_this_tick": 2,
  "already_present": 14,
  "skipped_pr": 1
}
```

Overwritten each tick (not append). Atomic via tmpfile+rename.

---

## 3. Dispatch packet additions

When orch dispatches a bead that was minted from an issue, the dispatch packet (the JSON sent to the worker pane) gains these fields:

```json
{
  "bead_id": "flywheel-gh-flywheel-12-a3f9",
  "issue_url": "https://github.com/JYeswak/flywheel/issues/12",
  "issue_number": 12,
  "github_repo": "JYeswak/flywheel",
  "pr_target_branch": "main",
  "pr_title_template": "fix: {bead.title} (#{issue.number})",
  "commit_footer_required": "Fixes JYeswak/flywheel#12",
  "close_issue_on_merge": true,
  "co_author_trailer": "Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
}
```

These are **derived from `bead.external_ref`** by `flywheel:dispatch`, not stored separately. No new dispatch substrate file.

---

## 4. Worker contract additions

Workers MUST honor the following when closing a bead whose `external_ref` matches the GitHub-issue URL pattern:

1. **Commit message subject** ends with ` (#<num>)`.
2. **Commit message body** contains a `Fixes <owner>/<repo>#<num>` footer on its own line.
3. **Commit message trailer** includes the canonical `Co-Authored-By:` line for the LLM that authored the change (matches Jeff's `0fe72100` exemplar).
4. **Push to origin** completes before `br close` is invoked. `auto-push-ledger.jsonl` line is the proof.
5. **`br close --reason`** cites the issue URL + commit SHA, e.g. `"GH JYeswak/flywheel#12 closed via abc1234 pushed to origin/main"`.

Enforcement: `flywheel:_shared:close-handler` (already exists as a slash-skill) gains a pre-close validator that, when `bead.external_ref` matches the GH-issue regex, asserts (1)+(2)+(3)+(4)+(5) before proceeding.

---

## 5. Polling cron

### 5.1 Cadence

Every **5 minutes**, via `/flywheel:cron`-managed launchd job named `com.zeststream.flywheel.issue-bead-sync`. 5 min = 1/10 of the 48h Duty 4 budget; comfortable safety margin.

### 5.2 Repo discovery

```
gh repo list JYeswak --limit 100 --json name,isArchived \
  | jq -r '.[] | select(.isArchived==false) | "JYeswak/\(.name)"'
```

Cached for 1 hour at `~/.local/state/flywheel/issue-bead-sync/repos-cache.json`. Allowlist override file: `~/.local/state/flywheel/issue-bead-sync/repos-allowlist.txt` (one repo per line, presence triggers strict allowlist mode).

### 5.3 Per-tick logic

```
for repo in $(discover_repos); do
  gh issue list --repo "$repo" --state open --limit 100 \
    --json number,title,body,labels,createdAt,updatedAt,url,state
done
```

For each issue:
1. Compute key = `<url>`.
2. Lookup in `registry.jsonl` (read whole file, build set of `github_issue_url`).
3. If present, **skip** (idempotent).
4. Else, `br create ... --external-ref <url> --json`, parse bead id, append registry row.

### 5.4 Rate-limit guard

`gh api rate_limit` probed once per tick. If `remaining < 50`, abort tick with `skipped_rate_limit_guard` in state.json. Cron retries next tick.

### 5.5 Doctor

`.flywheel/scripts/issue-bead-sync-doctor.sh` (follow-up bead) checks:
- `state.json` mtime < 7 minutes (next tick due);
- `registry.jsonl` parse-clean;
- For every open issue on JYeswak/* repos with `created_at < now() - 48h`, there exists a registry row.

The third probe is exactly the Duty 4 metric.

---

## 6. Repair / reconcile paths

`.flywheel/scripts/issue-bead-sync-repair.sh` (follow-up bead): for any registry row whose bead is missing (`br show <id>` fails), re-mint. For any open GH issue older than 48h with no registry row, force-sync.

---

## 7. Why polling first (not webhook)

- **Setup cost:** webhook requires public URL (cloudflared tunnel + Access policy + secret rotation) × 20 repos. Polling: 1 cron file.
- **Failure mode:** webhook can silently drop on Cloudflare 502 / `cloudflareaccess.com` redirect drift (we've trauma-classed this in `cloudflare-api` skill); polling self-heals next tick.
- **Latency budget:** 5 min vs 48h duty SLO. 576× over-headroom.
- **Doctrine:** memory rule `feedback_orch_wake_event_driven_not_time_based.md` argues for event-driven orch — but **discovery** (an issue exists) is fine as polled; **dispatch** of the resulting bead is event-driven by the existing flywheel loop. Polling only covers the discovery edge.

Webhook is a v2 follow-up bead (`flywheel-issue-sync-webhook`).

---

## 8. Surface scoping (canonical-cli-scoping doctrine)

The eventual CLI (post-prototype) will be `.flywheel/scripts/issue-bead-sync` with subcommands:

| Subcommand | Owner | Description |
|---|---|---|
| `sync` | mutator | poll + mint missing beads |
| `doctor` | reader | freshness + duty-4 metric |
| `repair` | mutator | re-mint missing, force-sync stragglers |
| `validate` | reader | schema-check registry rows |
| `audit` | reader | report `bead.external_ref` vs `gh issue view` divergence |
| `why` | reader | given a bead-id, explain which issue minted it + when |

Per `canonical-cli-scoping` skill discipline. Tracked as polish bead `flywheel-issue-sync-cli` after prototype proves the shape.

---

## 9. Trauma classes this design closes

- **substrate-drift-after-release-ship** (memory N=2): once an issue is filed against a public JYeswak repo, drift between "issue exists" and "internal bead system thinks it doesn't" is the exact class. Sync collapses it.
- **frozen-projection-of-mutable-state** (memory): static issue inventory in a Markdown table is forbidden; the registry JSONL is reconciled live every 5 minutes against `gh issue list`.
- **named-client-consent-per-surface** (memory): GitHub-visible content stays public-class; sync MUST NOT copy issue bodies that name internal clients into the bead description without re-running the public-voice gate. **Constraint:** issue body is copied verbatim to bead description, BUT bead is internal-class by default and never re-published outward; the GH→bead direction is import-only, no re-export.

---

## 10. Follow-up beads to file after this lands

1. `flywheel-issue-sync-cli` — wrap the prototype into a canonical-scoped CLI with doctor/repair/validate/audit/why.
2. `flywheel-issue-sync-close-reconciler` — the "issue closed via merged commit → bead close" half of bidirectional sync.
3. `flywheel-issue-sync-webhook` — v2 webhook mode for sub-5-min latency.
4. `flywheel-issue-sync-template-bootstrap` — `.github/ISSUE_TEMPLATE/*.md` defaults across JYeswak/* repos so issues arrive with the labels + structure the sync expects.
5. (optional) `flywheel-issue-sync-launchd` — wire the 5-min cron via `/flywheel:cron`.

---

**Done — prototype next.**
