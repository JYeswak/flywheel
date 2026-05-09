## L63 — JEFF-INTEL-NETWORK-IS-CANONICAL-SUBSTRATE-DEPENDENCY

---
id: L63
title: Jeff intel network is canonical substrate dependency
status: long_term
shipped: 2026-05-03
review_due: 2026-11-09
trauma_class: jeff-intel-substrate-drift
---


The flywheel ecosystem depends on Jeff Emanuel's substrate (ntm, br, dcg,
frankensqlite, cass, jsm, agent-mail, socraticode, vibe_cockpit) — at least
9 canonical binaries. The ecosystem MUST run a daily intel-network covering:
(1) Jeff's X account, (2) Jeff's website, (3) Jeff's git repos (cloned + indexed),
(4) Jeff's GitHub activity, (5) Jeff's jsm/skills catalog drift. Without intel
network, every Jeff release surprises us at use time and his WIP is invisible
until it breaks our deps.

**Reason:** Joshua observed 2026-05-03 ~09:35Z that despite Jeff being our
#1 substrate dependency, we had ZERO local clones of his repos and ZERO
monitoring of his X/website. We had to manually re-discover his fixes each
session via `gh issue view` (auth-fragile). Same paradigm-tier failure as L62
applied to a different latent-signal source.

**How to apply:**
- `~/Developer/flywheel/.flywheel/scripts/jeff-intel-network.sh` (canonical-cli-scoping)
  pulls all 5 sources daily; auto-clones any missing Jeff repos to `~/Developer/<repo>`;
  auto-indexes each clone via `mcp__socraticode__codebase_index`
- `/flywheel:jeff-intel` is the operator wrapper for doctor/health/repair,
  validation, audit, and dry-run pull/x-poll actions; `daily-jeff-ingest.sh`
  and `jeff-intel-scheduled-runner.sh` remain implementation helpers behind
  that canonical surface.
- Cadences: hourly X-poll, daily everything else
- Active launchd labels:
  `ai.zeststream.flywheel-daily-jeff-ingest` for daily GitHub/git,
  website/RSS, X, JSM, and mirror ingest; `ai.zeststream.flywheel-jeff-x-poll`
  for hourly @doodlestein X capture.
- launchd plists per source; receipts at
  `~/.local/state/jeff-intel/scheduled-runs.jsonl`,
  `~/.local/state/jeff-intel/x-poll.jsonl`, and
  `~/.local/state/flywheel/daily-jeff-ingest.jsonl`
- Cross-link new Jeff commits with existing flywheel doctrine; surface in tick
  receipt via Step 4r
- High-signal new artifact (release, blog post, X-thread referencing one of our
  deps) → file P3 bead with link + suggested integration path
- Every Jeff fix-commit applied via jeff-fixes-puller MUST be cross-linked to
  the originating intel-network artifact for provenance

**Forbidden outputs:**
- Calling `jeff-fixes-puller` "complete" without intel-network confirming HEAD
  per repo
- Manually `gh issue view`-ing Jeff repos when intel-network has the fetch
  cached locally
- Re-cloning a Jeff repo we already have without first checking
  `~/Developer/<repo>` (idempotency)
- Indexing flywheel-managed repos via socraticode while Jeff's substrate repos
  remain unindexed (Jeff's are the load-bearing dependency)

**Evidence:** Joshua directive 2026-05-03 ~09:35Z;
audit confirming 0/9 Jeff repos cloned locally; bead `flywheel-1lpv`
([jeff-intel-network] daily monitoring epic);
`reference_jeff_substrate_inventory` memory listing 7+ canonical binaries we
depend on; `feedback_jeff_substrate_version_drift` META-RULE that this rule
mechanizes.

**Companion rules:** L62 (latent-signal-substrate paradigm); L61 (ecosystem
wire-in); L11 Live API Truth (Jeff's repos ARE the live truth for our
substrate calls); `feedback_jeff_issue_chain` (file issues not patches);
`feedback_use_codex_workers` (worker dispatch shape for the daily pull cron).

