# Research — Agentic Issue ↔ Bead ↔ Commit ↔ Push Closed Loop

- **Bead:** `flywheel-wukwc` (P0)
- **Duty:** Mission Duty 4 (public-issues-watched) — "0 GitHub issues on JYeswak/* repos older than 48h without a linked bead"
- **Sister beads:** `flywheel-jrpfn` (auto-publish doctrine), `flywheel-k8pee` (doctrine-pull)
- **Quote:** "we need to have easy ways to turn issues into beads and beads into git saves — this needs to be similar to the way Jeff handles his repos — it's an automatic agentic ecosystem" (Joshua, 2026-05-20T19:00Z)
- **Author:** flywheel-orch (plan-space)
- **Sources cited:** Jeff repo probe (load-bearing), socraticode K=5, skills library scan, web/state internal corpus

---

## 1. Jeff/Dicklesworthstone Pattern — Deep Probe

### 1.1 Workflows present on `Dicklesworthstone/ntm`

`gh api /repos/Dicklesworthstone/ntm/actions/workflows` (fetched 2026-05-20):

| File | Purpose | Issue automation? |
|---|---|---|
| `.github/workflows/ci.yml` | Go CI | no |
| `.github/workflows/e2e-tests.yml` | E2E | no |
| `.github/workflows/notify-acfs.yml` | Notifies sibling repo of installer change | no |
| `.github/workflows/release.yml` | Release packaging | no |

`Dicklesworthstone/beads_rust`:

| File | Purpose | Issue automation? |
|---|---|---|
| `.github/workflows/audit.yml`, `ci.yml`, `conformance.yml`, `doctor.yml`, `e2e-full.yml`, `notify-acfs.yml`, `release.yml`, `update-package-manifests.yml`, `dependabot-updates` | quality + release | no |

**Finding 1 (load-bearing):** Jeff has **zero `.github/workflows/` files that touch issues**. There is no issue-bot, no issue-to-bead webhook, no auto-labeler, no triage bot. The "automatic agentic ecosystem" Joshua references is **not implemented via GitHub Actions**. It lives in the operator+CLI+commit-message contract.

### 1.2 The actual closure mechanism — commit-footer issue references

Probe of issue `Dicklesworthstone/ntm#155` (closed 2026-05-20T18:23:39Z) via `/repos/.../issues/155/timeline`:

```
event=referenced  commit=0fe72100  actor=Dicklesworthstone  2026-05-20T18:23:26Z
event=closed                       actor=Dicklesworthstone  2026-05-20T18:23:40Z
event=referenced  commit=76306f90  actor=Dicklesworthstone  2026-05-20T19:46:09Z
```

The closing commit `0fe72100`:

> `fix(spawn): don't hard-reject gpt-*-codex on ChatGPT logins; advise instead (#155)`
>
> *(body)* "...proven in ntm#155..."
>
> `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`

Key elements of the Jeff pattern, observed directly:

1. **Subject line ends with `(#NNN)`** — the literal PR/issue number in parens. GitHub's auto-link populates the `referenced` timeline event; the `closed` event is then a manual `gh issue close` 14 seconds later (Joshua-equivalent: Jeff hits the button on merge).
2. **Body cross-references sibling issues by short form** `ntm#148`, `ntm#155`. Multiple issues per commit are expected.
3. **`Co-Authored-By: Claude Opus 4.7 ...` trailer is canonical.** This is what makes the workflow agentic — a human reviews, but an LLM authored.
4. **Same-day, same-author follow-up commits** (`76306f90` 1h22m later: "Fresh-eyes pass on the #155 change") are visible — proves saturation-pass discipline, not "one-and-done".
5. **`AGENTS.md` at repo root** carries the behavioral contract for the LLMs. ntm's `AGENTS.md` (probed via `gh api .../contents/AGENTS.md`) opens with: "RULE 0 — THE FUNDAMENTAL OVERRIDE PREROGATIVE", "RULE 1 — NO FILE DELETION", git-branch single-`main` rule, toolchain rule. This is Jeff's `CLAUDE.md` equivalent — the operator-discipline doc the LLM reads before touching code.

### 1.3 Conclusion: the "Jeff agentic ecosystem" is operator-discipline + CLI + commit-footer, not GitHub Actions

The mechanism is:

```
[GitHub issue filed by Jeff or user]
   │
   ▼
[LLM (in Jeff's terminal swarm) reads AGENTS.md + issue body]
   │
   ▼
[LLM proposes patch + commit with `(#NNN)` footer + Co-Authored-By trailer]
   │
   ▼
[Jeff reviews, pushes; GitHub auto-references the issue from the commit]
   │
   ▼
[Jeff (or commit `Fixes #NNN` footer on merge) closes the issue]
```

There is no daemon, no webhook, no Actions job that does this. The agentic-ness is **inside the dev loop**, not in GitHub infrastructure.

**Implication for our duty:** we don't need a webhook to match Jeff. We need:

- (a) a poll OR push path to detect open issues across `JYeswak/*` and turn each into a bead with a back-link;
- (b) a bead-close contract that emits a commit/PR carrying the `(#NNN)` footer and `Fixes JYeswak/<repo>#NNN`;
- (c) discipline (an `AGENTS.md`-equivalent — we have `CLAUDE.md` per project).

That is what Duty 4 actually requires.

### 1.4 Sample volume

`gh repo list JYeswak --limit 20` returns 20 repos (zesttube, flywheel, mobile-eats, zeststream-cast, SkillOS, alps-insurance, ClutterFreeSpaces, josh-claude-config, vrtx, zeststream-cast-docs, ZestStream-v2, zeststream-platform, n8n-deploy-kit, JYeswak, polymarket-pico-z, zeststream-procurement, zeststream-brand-voice, zeststream-pipeline, josh-connect-ui-zeststream, zeststream-infra). `gh issue list --repo JYeswak/flywheel --state all --limit 50` returns **0** today. Baseline is clean; the duty is about *keeping* it clean as issues arrive.

---

## 2. Source (a) — Skills library scan

Skills present today (`ls ~/.claude/skills/ | grep -iE 'github|issue|gh-'`):

- `gh-actions`, `gh-cli`, `gh-coding-agent`, `gh-mcp-server`, `gh-models`, `gh-og-share-images`
- `gh-triage-ru` (+ its `.old_*` backup) — Jeff-style triage skill
- `jeff-issue-chain` — Jeff issue submission protocol skill
- `flywheel:file-jeff` slash command — files a Jeff-style issue against upstream Dicklesworthstone repos

Local scripts in `.flywheel/scripts/`:

- `jeff-issue.py` — phased Jeff issue gate (canonical-cli-scoping: passing). Header reveals it submits outbound issues to Dicklesworthstone/*; **opposite direction** of what we need (we need inbound issues on JYeswak/* → beads).
- `jeff-issue-rubric.py` — quality rubric
- `jeff-issue-response-poll.sh` — polls **Jeff's** responses (inbound from Dicklesworthstone responses on issues we filed)
- `jeff-issues-status-probe.sh` — status reads

**Gap:** all existing tooling is outbound-to-Dicklesworthstone or status-read. There is **no inbound-issue-to-bead sync for JYeswak/* repos**. That gap is what `flywheel-wukwc` exists to close.

**Reusable pieces:**

- `jeff-issue.py`'s state-dir layout (`~/.local/state/flywheel/jeff-issue/`) + registry JSONL pattern is the right shape for our last-poll-ts marker file.
- `gh-triage-ru` flow has a "scan issues → triage → emit beads" shape we can mirror.

---

## 3. Source (b) — Socraticode K=5 against the flywheel index

Query: `github issue webhook handler create bead` (limit 5, project `/Users/josh/Developer/flywheel`):

1. `tests/bead-quality-mining.sh:19-26` — canonical `br create` pattern:
   ```
   br create "$title" --type task --priority 1 --description "$desc" --json \
     | jq -r '.id // .issue.id'
   ```
   Confirms our prototype's create-and-extract-id contract.
2. `tests/stale-in-progress-reaper.sh:51-59` — variant with `--assignee` + `--status in_progress`. Useful when we want the issue-bead to land directly assigned.
3. `INCIDENTS.md:4951+` — "Forever-Rule: Jeff response-triage epics must close from a live reconciliation: canonical issue URLs from triage beads, `gh issue view` current state, and a dedup pass by URL." **This is the contract our sync must satisfy on the close side**: live reconciliation, not static inventory.
4. `state/public-share-n8n-webhook-registration-repair-...json` — irrelevant (n8n webhooks, not GitHub issue webhooks).
5. `tests/test_bead_isolation_source_repo_backfill.sh` — shows `--external-ref` is not exercised in any current test; we are first.

`br create --help` confirms the schema we need is already present:

- `--external-ref <EXTERNAL_REF>` — **this is the field** for the GitHub issue URL link.
- `--slug <SLUG>` — embed the repo+issue number in the bead id (e.g. `--slug gh-flywheel-12` ⇒ `flywheel-gh-flywheel-12-<hash>`).
- `--labels <LABELS>` — propagate GitHub labels.
- `--description <DESC>` — issue body.
- `--json` — receipt for the registry write.

Bead JSONL fields already include `source_repo`, `labels`, `comments`. The Rust beads engine has not yet exposed an `external_ref` field on JSONL export at the row level — to be verified during implementation bead.

---

## 4. Source (c) — Internal corpus + memory rules

- **MEMORY rule** `feedback_orchestrator_validates_callbacks` and `feedback_orchestrator_must_dispatch.md`: when issues arrive, orch's job is to *dispatch a bead*, not ask Joshua. The sync daemon must not gate on Joshua.
- **MEMORY rule** `feedback_two_truth_sources_before_decide.md`: before closing a bead-from-issue, verify both (a) the GitHub issue is closed AND (b) the linked commit is pushed. Either alone is insufficient.
- **MEMORY rule** `feedback_dispatch_post_send_verify_for_silent_deaf.md`: after sync emits beads, must verify `br show` returns them (write-then-read confirmation).
- **MEMORY rule** `feedback_no_push_ntm_br.md`: pushes to `Dicklesworthstone/ntm` and `Dicklesworthstone/beads_rust` are FORBIDDEN. The sync MUST NOT attempt to write back to those upstream repos — only JYeswak/* are write-targets.
- **MEMORY rule** `feedback_audit_findings_are_data_decided_not_joshua_gated.md`: discovery (issue exists) ⇒ bead is data-decided, not Joshua-gated. Sync proceeds autonomously.
- **MEMORY rule** `feedback_canonical_cli_at_dispatch.md`: any new CLI surface must follow `canonical-cli-scoping` (doctor/repair/validate/audit/why).
- **Project file** `~/Developer/flywheel/.flywheel/MISSION.md` — Duty 4 metric pinned at 0 issues older than 48h without a linked bead.

---

## 5. Decision matrix — webhook vs polling

| Axis | Webhook | Polling (recommended for v1) |
|---|---|---|
| Latency | seconds | 5 min (cron interval) |
| Setup | requires public URL + secret + per-repo `gh api .../hooks` registration on 20 repos | `gh issue list` from cron, no GitHub config |
| Auth | per-hook secret rotation | inherits `gh` CLI login (already operational) |
| Failure mode | silent drop on misconfig | retry next tick |
| Scale | unbounded fan-in | bounded by cron cadence |
| Doctor-able | needs deliveries probe (`gh api /repos/.../hooks/<id>/deliveries`) | `last_poll_ts < now() - 6min` is the doctor signal |
| Trauma-class | "phantom-webhook-not-registered" (already seen in n8n) | none new — same shape as existing cron jobs |

**v1 = polling.** Webhook is a v2 bead (`flywheel-wukwc.followup-webhook`) when latency budget tightens below 5 min, OR when issue volume exceeds 50/day.

---

## 6. Findings summary (load-bearing for design doc)

1. **Jeff has zero issue-automation workflows in GitHub.** The pattern is operator-discipline + LLM-authored commits with `(#NNN)` footers and `Co-Authored-By` trailers, governed by `AGENTS.md`. We already have this layer (`CLAUDE.md` + commit-craftsman skill).
2. **The "automatic agentic ecosystem" missing piece on our side is the inbound translator**: GitHub issue → bead with `external_ref = <issue URL>`. Once a bead exists, the existing dispatch/swarm/close flywheel does the rest.
3. **`br create --external-ref` is already the schema field.** No new column needed in the bead model for v1.
4. **Polling (5-min cron) is the right v1.** 20 repos × `gh issue list` = ~20 API calls per tick = within rate budget.
5. **The bead-close → commit-footer link must be enforced by worker contract**, not by post-hoc audit. Workers closing a bead with `external_ref` must commit a `Fixes <owner>/<repo>#<num>` footer; close-handler validates this before `br close`.
6. **Two-truth-source close rule** (from internal memory): bead closes only when (a) `gh issue view <issue>` reports `state=closed` AND (b) the closing commit is pushed to origin. Either alone is insufficient.

---

## 7. Open questions for the design doc

- Where does the last-poll-ts file live? `~/.local/state/flywheel/issue-bead-sync/state.json` (mirrors `jeff-issue.py`'s pattern).
- Do we want a bead per issue, or epic-with-child-tasks? **Bead-per-issue** for v1 (simpler reconciliation).
- Closure direction: does a bead-close auto-close the GitHub issue? **No for v1** — leave issue closure to commit-footer `Fixes #N` on merge to `main`. v2 bead can add explicit `gh issue close` if footer-trigger proves insufficient.
- Per-repo opt-in? Default-opt-in for all `JYeswak/*` repos discovered via `gh repo list JYeswak`. Allowlist override via `~/.local/state/flywheel/issue-bead-sync/repos.txt`.

---

**Next:** `01-design.md` for the flow + schema + cron contract. `github-issue-bead-sync-prototype.sh` for the read-only-against-github prototype.
