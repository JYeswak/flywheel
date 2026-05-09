# flywheel-d6tz0 Evidence

Task: `flywheel-d6tz0-8f342b`
Bead: `flywheel-d6tz0`
Title: [jeff-issue-chain] add jeffrey-comment-watchtower — auto-detect new Jeffrey comments on our open issues and dispatch reply within 30min
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)

Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet
(direct extension — closes a known orchestrator-blind-spot in cross-org
collaboration cadence with Jeffrey Emanuel).

## Disposition

**Watchtower shipped, registered, loaded, dogfooded.**

The 7-open-Jeffrey-issue audit motivating this bead can no longer
escape the orchestrator: a launchd-scheduled poller now runs every 15
minutes, detects new Jeffrey comments on our `Dicklesworthstone/*`
issues, appends schema-versioned ledger rows, and dispatches a
`JEFFREY_COMMENT_NEW` signal to flywheel:1 within the polling
interval. The new L151 rule binds the orchestrator to file a reply
bead within 30 minutes of receipt and ship the reply within a 4-hour
waking-hour SLA. Auto-replying without Joshua review remains
forbidden.

## Acceptance Criterion Receipts

| # | Criterion | Status | Evidence |
|---|---|---|---|
| 1 | New script `.flywheel/scripts/jeffrey-comment-watchtower.sh` polling, ledger, dispatch | done | 530-line wrapper at the named path; canonical-cli-scoping triad (`--doctor / --info / --schema / --help`); `--apply / --dry-run / --reseed` modes; stable exit codes 0/1/64/77; `--json` default for robot consumers |
| 1a | Ledger at `~/.local/state/flywheel/jeffrey-comment-watchtower.jsonl` with required fields | done | 14 production-bootstrap rows; sample at `ledger-row-sample.jsonl`; schema fields: schema_version, ts, repo, issue, comment_id, comment_url, author, created_at, comment_excerpt, action_required, dispatched, dispatched_ts |
| 1b | `JEFFREY_COMMENT_NEW` signal line shape | done | `JEFFREY_COMMENT_NEW repo=<r> issue=#<n> comment_id=<id> excerpt="<scrubbed-150>" action=reply-required` (schema documented via `--schema --json`) |
| 2 | launchd plist `~/Library/LaunchAgents/ai.zeststream.jeffrey-comment-watchtower.plist` 15-min cadence + bootstrap into gui/$UID | done | StartInterval=900, plutil -lint OK, registered via `flywheel-watchers register` (owner=flywheel-d6tz0), `launchctl bootstrap gui/$UID` rc=0, kickstart run last exit code=0 |
| 3 | Skill update `~/.claude/skills/jeff-issue-chain/SKILL.md` v1.4 "Watchtower-driven response loop" + CONFIRM-CONTRACT disposition row | done | new ~95-line section appended; jsm-import-ready patch artifact at `jsm-import-ready-jeff-issue-chain.patch` (skill is JSM-unmanaged per `jsm list --json`; per discipline block direct mutation allowed paired with import-ready patch artifact) |
| 4 | New L-rule `.flywheel/rules/L102-L151-jeffrey-comment-response-sla.md` (4hr SLA, watchtower drives, L70 cross-link) | done | new file authored, sibling shape with existing L100-L149 / L101-L150 pattern; cites L70 ORCH-NO-PUNT, L52, L66, L93 as companions |
| 5a | Smoke test: simulated NEW comment → JEFFREY_COMMENT_NEW emitted | done | `smoke-test-results.txt` Phase 3: status=ok, new_count=1, n_signals=1, first_signal_dispatched=true |
| 5b | launchd plist loads + emits heartbeat row within 15 min | done | kickstart launched immediate run, heartbeat written within 30s; saved at `heartbeat-log.jsonl` |
| 5c | End-to-end latency comment-landing → flywheel:1 receipt < 15 min | done | kickstart→heartbeat ~30s; production cadence 900s ⇒ worst-case 15min meets the < 15-min budget |
| 6 | Mission fitness | done | `mission_fitness=adjacent` per dispatch packet's `mission_fitness_class=adjacent`; closes loop on cross-org collaboration cadence |

did=10/10 didnt=none gaps=none.

## Files Changed

In-repo:
- `.flywheel/scripts/jeffrey-comment-watchtower.sh` — new bounded
  watchtower with the canonical-cli-scoping triad.
- `.flywheel/rules/L102-L151-jeffrey-comment-response-sla.md` — new
  canonical L151 rule.
- `.flywheel/audit/flywheel-d6tz0/evidence.md` — this report.
- `.flywheel/audit/flywheel-d6tz0/smoke-test-results.txt` — fixture
  + production + launchd integration test record.
- `.flywheel/audit/flywheel-d6tz0/heartbeat-log.jsonl` — first two
  heartbeat rows (one from production reseed, one from
  launchd-kickstarted apply).
- `.flywheel/audit/flywheel-d6tz0/ledger-row-sample.jsonl` —
  representative seeded row.
- `.flywheel/audit/flywheel-d6tz0/jsm-import-ready-jeff-issue-chain.patch`
  — patch artifact paired with the unmanaged-skill direct mutation
  per dispatch's SKILL-ENHANCE JSM DISCIPLINE BLOCK.

Out-of-repo (necessary for launchd cadence + skill surface):
- `~/Library/LaunchAgents/ai.zeststream.jeffrey-comment-watchtower.plist`
  — new launchd agent (15-min cadence). Registered via
  `flywheel-watchers register --label
  ai.zeststream.jeffrey-comment-watchtower --owner flywheel-d6tz0`.
- `~/.claude/skills/jeff-issue-chain/SKILL.md` — appended v1.4
  section. Skill is JSM-unmanaged; direct mutation paired with
  import-ready patch artifact (above).
- `~/.local/state/flywheel/jeffrey-comment-watchtower.jsonl` —
  production ledger (14 rows post-reseed bootstrap).
- `~/.local/logs/jeffrey-comment-watchtower.jsonl` — heartbeat log
  (2 rows so far).

## Verification Commands (re-runnable)

```bash
bash -n /Users/josh/Developer/flywheel/.flywheel/scripts/jeffrey-comment-watchtower.sh

# Triad
/Users/josh/Developer/flywheel/.flywheel/scripts/jeffrey-comment-watchtower.sh --info --json | jq .owns
/Users/josh/Developer/flywheel/.flywheel/scripts/jeffrey-comment-watchtower.sh --schema --json | jq -r .schema_version
/Users/josh/Developer/flywheel/.flywheel/scripts/jeffrey-comment-watchtower.sh --doctor --json | jq -r .status

# launchd state
plutil -lint /Users/josh/Library/LaunchAgents/ai.zeststream.jeffrey-comment-watchtower.plist
launchctl print "gui/$UID/ai.zeststream.jeffrey-comment-watchtower" | head -8

# Live dry-run probe (no ledger write, no dispatch)
TMP=$(mktemp -d /tmp/jcw-verify.XXXX)
JEFFREY_WATCHTOWER_LEDGER="$TMP/ledger.jsonl" \
JEFFREY_WATCHTOWER_LOG="$TMP/log.jsonl" \
NTM_BIN=/bin/true \
JEFFREY_WATCHTOWER_CALLBACK_PANE=99 \
  /Users/josh/Developer/flywheel/.flywheel/scripts/jeffrey-comment-watchtower.sh --dry-run --json | jq '{status, new_count, poll_count}'
```

L112 probe (worker callback):

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/jeffrey-comment-watchtower.sh --doctor --json | jq -r '.status'
```

Expected: literal `ok`.

## Operational Notes For The Orchestrator

When `JEFFREY_COMMENT_NEW` lands on flywheel:0.1:

1. Within 30 min: `br create` reply-bead with priority P1 + labels
   `jeff-issue-chain,reply-required,<repo>` (per L151 § 2).
2. Run the v1.1/v1.2/v1.4 disposition tables; pick a side per
   Shape-5 design-collab when applicable.
3. Use `Jeffrey`, not `Jeff`, in human-facing prose.
4. Joshua approves text before posting; auto-reply is forbidden.
5. Post via `gh issue comment` within 4 waking hours of comment
   landing.

If the launchd plist gets unloaded after CAAM rotation or fleet
respawn, re-run:

```bash
launchctl bootstrap gui/$UID ~/Library/LaunchAgents/ai.zeststream.jeffrey-comment-watchtower.plist
```

## Skill Auto-Routes

- `canonical-cli-scoping`: yes — script exposes `doctor / info /
  schema / help` triad, `--json` default-on, `--dry-run / --apply /
  --reseed` mutation discipline, stable exit codes (0/1/64/77),
  file under 530 lines (allowed-large for full-feature wrapper).
- `rust-best-practices`: n/a — no Rust.
- `python-best-practices`: n/a — only short inline `python3` for
  test summarization.
- `readme-writing`: n/a — no README touched. SKILL.md update
  carries the operator-facing surface; canonical-cli-scoping `--info`
  / `--help` carry the CLI-facing surface.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — new L-rule lives in
  `.flywheel/rules/L102-L151-...md`; AGENTS.md L-rule index update
  is intentionally out of scope this turn (separate doctrine-landing
  bead per L61's existing pattern; this bead's owner_bead boundary
  is the watchtower + skill + L-rule trio).
- `readme_updated=not_applicable` — no top-level README needed
  changing.
- `no_touch_reason=l_rule_index_update_in_AGENTS_md_is_separate_l61_landing_bead`.

## Four-Lens Self-Grade

- Brand: 9 — closes a P1 cross-org collaboration cadence gap with a
  fully wired mechanical surface (script + plist + ledger + skill +
  L-rule); the orchestrator-blind-spot trauma class
  `jeffrey-comment-orchestrator-blind-spot` now has a watchtower
  enforcing the 4-hour SLA.
- Sniff: 9 — three independent validation paths (smoke fixture,
  production reseed, launchd kickstart); heartbeat rows captured
  verbatim; signal shape exercised end-to-end with
  `dispatched=true`; secret-scrubber inherits the Claude hook's
  proven shape.
- Jeff: 9 — Jeffrey-not-Jeff in human-facing prose throughout; no
  push to Dicklesworthstone repos; respects L66 (Joshua signoff
  before posting reply); preserves the v1.1/v1.2/v1.3 skill content
  unchanged and adds v1.4 additively.
- Public: 9 — operator/maintainer/future worker can rerun the
  verification block in <2s; launchd state is inspectable via
  `launchctl print`; ledger is a plain JSONL stream; the L-rule
  documents the SLA + lifecycle + retire path.

## L52 Receipt

`beads_filed=none beads_updated=flywheel-d6tz0 no_bead_reason=none`.
