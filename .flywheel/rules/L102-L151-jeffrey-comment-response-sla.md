## L151 — JEFFREY-COMMENT-RESPONSE-SLA

---
id: L151
title: Jeffrey-comment response SLA — watchtower-driven, 4hr waking-hour budget
status: long_term
shipped: 2026-05-09
review_due: 2026-11-09
trauma_class: jeffrey-comment-orchestrator-blind-spot
---

When `jeffrey-comment-watchtower` emits a `JEFFREY_COMMENT_NEW` signal,
the flywheel orchestrator MUST file a reply-bead within 30 minutes of
signal receipt and ship the reply within a 4-hour waking-hour SLA.
Watchtower drives — never wait for human surfacing.

**Reason:** Joshua directive 2026-05-09 ("I need to ensure that EVERY
response to ANY of our [Jeffrey] issues gets immediate attention — we
need to update our jeff-issue-chain process to keep the conversations
going."). Today's worker-flow only caught the 7 open Jeffrey issues
(ntm#126, 127, 128, 129, 134, 135 + beads_rust#285) because Joshua
manually surfaced "is anything we need to add?" — that is not the
system. Cross-org collaboration cadence with Jeffrey Emanuel is a
relationship asset that decays without rapid reciprocation.

**How to apply:**

1. **Watchtower cadence (mechanical).** launchd plist
   `ai.zeststream.jeffrey-comment-watchtower` runs the polling script
   every 15 minutes. Default mode is `--apply`: append unseen Jeffrey
   comments to `~/.local/state/flywheel/jeffrey-comment-watchtower.jsonl`
   AND dispatch a `JEFFREY_COMMENT_NEW` signal to flywheel:1.

2. **Orchestrator file-on-receipt (L70 cross-link).** Within 30 minutes
   of receiving a `JEFFREY_COMMENT_NEW` signal, the flywheel
   orchestrator must `br create` a reply-bead with priority P1 and
   labels `jeff-issue-chain,reply-required,<repo>`. The bead title
   names the issue and the comment id. Same tick, not next tick (per
   L70 ORCH-NO-PUNT).

3. **Reply ship within 4 hours waking-hour budget.** Reply must be
   drafted, run through `jeff-issue-chain` Phase 4 disposition table
   (APPROVE / REFINE / REJECT / NEEDS_RESEARCH / RESHAPED-OUR-SCOPE /
   CONFIRM-CONTRACT), and posted via `gh issue comment` within 4
   waking hours of comment landing. If the comment lands outside
   waking hours, the SLA window starts at the next waking hour.

4. **Joshua approves text before posting.** Auto-replying without
   human review is forbidden (per bead `flywheel-d6tz0` Out of Scope
   §1). The watchtower DETECTS and DISPATCHES; Joshua disposes the
   reply text.

5. **Watchtower cadence preserved across rotations.** When CAAM
   profile rotation or fleet respawn happens, the launchd plist
   remains loaded; watchtower continues polling. Recovery: re-run
   `launchctl bootstrap gui/$UID
   ~/Library/LaunchAgents/ai.zeststream.jeffrey-comment-watchtower.plist`
   if the plist gets unloaded.

**Forbidden outputs:**

- Auto-posting a reply to Jeffrey's comment without Joshua review.
- Polling other authors' comments through this watchtower (Jeffrey-only
  per current scope; other authors require a separate bead).
- Allowing a `JEFFREY_COMMENT_NEW` signal to wait > 30 minutes without
  a reply-bead filed (failure mode = `jeffrey-comment-orchestrator-blind-spot`).
- Reseeding the ledger silently to skip an unhandled comment
  (`--reseed` is bootstrap only; logged in heartbeat as
  `mode=reseed`).

**Evidence:** Joshua directive 2026-05-09T13:30Z;
bead `flywheel-d6tz0` (this rule's owning bead);
audit `~/Developer/flywheel/.flywheel/audit/flywheel-d6tz0/` with
end-to-end probe receipts;
script `.flywheel/scripts/jeffrey-comment-watchtower.sh` (canonical-cli-scoping
triad: doctor / info / schema / help with `--json` output and stable
exit codes 0/1/64/77);
plist `~/Library/LaunchAgents/ai.zeststream.jeffrey-comment-watchtower.plist`
(15-minute interval, gui/$UID load, plutil-lint OK);
skill update `~/.claude/skills/jeff-issue-chain/SKILL.md` §
"Watchtower-driven response loop";
sister pattern `codex-watchtower-daily.sh` /
`ai.zeststream.codex-watchtower-daily` (same shape, different cadence).

**Companion rules:** L70 ORCH-NO-PUNT (sibling — next actionable runs
same tick, not next tick); L52 ISSUES-TO-BEADS-OR-EXPLICIT-NO-BEAD-RECEIPT
(reply-bead is the L52 expression of the comment-as-gap); L66
OUTBOUND-JEFF-ISSUES-USE-PHASED-COMMAND-GATE (Phase 5 Joshua signoff
discipline applies to reply text, not to the watchtower's automatic
ledger writes); L93 JEFF-ISSUE-REQUIRES-WORKAROUND-RESEARCH-FIRST
(applies when reply requires a new follow-up issue).
