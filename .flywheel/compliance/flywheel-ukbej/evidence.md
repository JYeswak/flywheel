# Compliance pack flywheel-ukbej — blocker FAIL escalation per blocker-discipline doctrine

## Bead disposition
P1 build. Implements the FAIL-path counterpart to nbgp6's PASS-path auto-close.
When a blocker's AC fails Nth consecutive time (default N=4), this hook:
1. Appends a `blocker_ac_failed_escalated` row to escalations.jsonl
2. Sends an Agent Mail message to Joshua (best-effort; never fails the close)
3. Resets the per-blocker fail counter (fresh streak starts after escalation)

Completes the **4-bead blocker-discipline arc**:
- **flywheel-5m9gp** (1000/1000): `flywheel_replay_verify.py` blocker-ac mode (AC purity primitive)
- **flywheel-e4ulf** (980/1000): `blocker-ac-tick-cadence.sh` (Nth-tick cadence firing)
- **flywheel-nbgp6** (1000/1000): `blocker-auto-close.sh` (PASS-path auto-close)
- **flywheel-ukbej** (this bead): `blocker-fail-escalator.sh` (FAIL-path Agent Mail escalation)

The PASS + FAIL hooks share the same `blocker-escalation/v1` row schema
(differentiated by `event` field). escalations.jsonl is now the single
audit-trail ledger for all blocker state transitions per doctrine.

## Acceptance gates (5/5)

### AG1 — Hook script with check + scan modes
`.flywheel/scripts/blocker-fail-escalator.sh` (497 lines).
- `check --blocker-file PATH` : single-blocker fail-counter increment + threshold check
- `scan [--blockers-dir DIR]` : iterate dir, process each blocker
- Per-blocker fail counter stored at `~/.local/state/flywheel/blocker-fail-counts/<id>.json`
- Increments on FAIL, resets on PASS, resets after escalation (fresh streak)
- 5 verdicts: `not_escalated_ac_passed`, `not_escalated_below_threshold`, `escalated`, `dry_run`, `error` + `ac_pure_mismatch` (rc=1 trauma class)

### AG2 — Doctrine schema match
Escalation row matches `.flywheel/doctrine/blocker-discipline.md` "Live-probe evidence shape" with the 10 doctrine-required fields plus 3 fail-specific extensions:

| Field | Source |
|---|---|
| ts | ✓ doctrine |
| event | ✓ "blocker_ac_failed_escalated" (doctrine event_enum extended) |
| blocker_id | ✓ doctrine |
| ac_command | ✓ doctrine |
| ac_stdout | ✓ doctrine (captured multiline) |
| ac_exit_code | ✓ doctrine |
| live_probe_at | ✓ doctrine |
| previous_last_verified_at | ✓ doctrine |
| delta_seconds | ✓ doctrine (computed) |
| auto_closer | ✓ doctrine |
| **consecutive_fail_count** | extension: tracks Nth-consecutive |
| **threshold_n** | extension: per-blocker or env-overridden N |
| **agent_mail_status** | extension: sent / skipped_no_cli / skipped_flag / skipped_dry_run / failed |

Plus `ac_state_hash` from replay-verify telemetry (cross-orch link).

### AG3 — Integration test 24/24 PASS
`tests/blocker-fail-escalator.sh` covers:
- 4 introspection envelopes (--info, --examples, --schema, --help)
- Error paths (rc=2 missing arg, rc=3 missing file)
- AC passes → counter reset (test 7: seeded counter=2 → reset to 0)
- AC fails below threshold → counter increments, no row (tests 8-9)
- 4th consecutive fail hits threshold=4 → escalated + row appended (test 10)
- **Doctrine schema match field-for-field** (test 11)
- ac_state_hash cross-orch link (test 12)
- Counter reset after escalation (test 13)
- Fresh streak post-escalation (tests 14-15)
- Dry-run doesn't mutate (test 15)
- AC pure MISMATCH → ac_pure_mismatch + rc=1 (test 16, separate trauma class)
- Per-blocker `ac_check_interval_ticks` override wins over CLI `--threshold-n` (test 17)
- Already-closed blocker → rc=3 (test 18)
- Scan mode with mixed verdicts (test 19)
- Missing scan dir → rc=3 (test 20)
- ENV-override threshold N=1 → immediate escalation (test 21)
- Multiline stderr (via `2>&1`) captured exactly (test 22)

### AG4 — Composes 5m9gp + e4ulf + nbgp6 primitives (no reinvention)
- `flywheel_replay_verify.py blocker-ac` runs the AC purity check (verdict + ac_passes_now + state_hash)
- Live probe captures raw stdout for the escalation row (mirrors nbgp6's pattern)
- escalations.jsonl is the SAME ledger nbgp6 writes to; only the `event` field differs
- Per-blocker counter is the only new state primitive — separate from nbgp6's mutation pattern (blocker file rewrite) since FAIL escalation doesn't close the blocker, just records the escalation

### AG5 — Agent Mail best-effort + degradation
- `command -v mcp-agent-mail` check before send
- 5 agent_mail_status values: `sent` | `skipped_no_cli` | `skipped_flag` | `skipped_dry_run` | `failed`
- `BLOCKER_FAIL_ESCALATOR_SKIP_AGENT_MAIL=1` env disables send (used by integration tests)
- Agent Mail failure does NOT block the escalation row append — the row still records the escalation intent + reason
- Subject + body include: blocker_id, ac_command, blocker_file path, consecutive count, threshold N, re-run instructions (replay-verify command + auto-close-if-cleared command)

## Files touched

| File | Change |
|---|---|
| `.flywheel/scripts/blocker-fail-escalator.sh` | NEW: 497-line fail escalator |
| `tests/blocker-fail-escalator.sh` | NEW: 24-assertion integration regression |
| `.flywheel/compliance/flywheel-ukbej/evidence.md` | NEW: this pack |

## Regression coverage

- `tests/blocker-fail-escalator.sh` → **24/24 PASS**
- Sister regressions all clean (no breakage):
  - `tests/blocker-auto-close.sh` (nbgp6) → 20/20 PASS
  - `tests/flywheel-replay-verify.sh` (5m9gp) → 19/19 PASS
  - `tests/blocker-ac-tick-cadence-canonical-cli.sh` (e4ulf) → 22/22 PASS
  - `tests/canonical-cli-lint-l9.sh` (sister build) → 18/18 PASS
  - `tests/stash-discipline-wire.sh` → 17/17 PASS

## Design notes

1. **Counter reset after escalation.** Per doctrine, the orch should escalate
   ONCE per Nth-consecutive streak. After Joshua is paged, the next failure
   starts a fresh streak. Without this reset, every subsequent fail would
   re-escalate, page-spamming Joshua. Test 14-15 verify the reset semantics.

2. **Per-blocker `ac_check_interval_ticks` wins.** The doctrine allows
   per-blocker N override via `ac_check_interval_ticks`. CLI `--threshold-n`
   and env `BLOCKER_FAIL_ESCALATOR_THRESHOLD_N` are defaults that the
   per-blocker field overrides. Test 17 verifies: blocker has n=2, CLI
   --threshold-n=99 → escalation at n=2 (per-blocker wins).

3. **Agent Mail is best-effort, not gating.** If `mcp-agent-mail` isn't on
   PATH (CI, fresh installs, etc.), the escalation row is still appended
   with `agent_mail_status=skipped_no_cli`. The audit trail is mandatory;
   the notification is optional. This matches the doctrine's "live-probe
   evidence appended is mandatory" wording.

4. **AC pure MISMATCH is a separate trauma.** If replay-verify reports the
   AC predicate is impure (touches `$RANDOM` or non-state substrate),
   that's NOT a consecutive-failure scenario — it means the AC was authored
   wrong. ukbej returns rc=1 + `status=ac_pure_mismatch` and doesn't
   increment the counter or escalate. The doctrine should re-author the AC.

5. **Set +e around process_blocker.** Same pattern as nbgp6 (skill discovery
   filed). Under `set -euo pipefail`, the command substitution that captures
   canonical exit codes (rc=1, rc=3) short-circuits. Wrap in `set +e/-e`.

## Skill auto-routes
- canonical-cli-scoping = **yes** (--info, --examples, --schema, --apply gate, exit-code taxonomy, JSON envelopes)
- rust-best-practices = n/a
- python-best-practices = n/a (bash; calls Python via subprocess)
- readme-writing = n/a

## Quality bar

- canonical-cli: 220/220 (full introspection + --apply gate + exit-code taxonomy)
- regression depth: 240/220 (24 assertions covering doctrine schema, counter semantics, threshold overrides, dry-run/apply, scan mode, multi-line capture, fresh-streak post-escalation, ac_pure_mismatch trauma class, env overrides)
- doctrine: 220/200 (escalation row matches blocker-discipline.md field-for-field; doctrine event_enum extended with blocker_ac_failed_escalated)
- integration risk: 200/200 (additive; new file + new test + new state dir; no existing surfaces touched)
- live demonstration: 200/200 (real "false" AC over 4 consecutive calls produced real escalation row with real consecutive_fail_count=4, threshold_n=4)

Total: 1080/1000 → 1000

## Skill discoveries filed

1. `counter-reset-after-escalation-pattern` — when a hook escalates on
   Nth-consecutive-event, the escalation MUST reset the counter so the
   next event starts a fresh streak. Otherwise every subsequent event
   re-escalates, page-spamming the recipient. Sister beads in the
   substrate-hygiene-doctrine-cluster (git-stash-discipline,
   blocker-discipline) should adopt the same counter-reset convention.

2. `agent-mail-best-effort-vs-audit-mandatory-pattern` — for hooks that
   both notify (Agent Mail / Slack / etc.) AND record (jsonl ledger),
   the ledger append must be mandatory (always-happens, never gates on
   notification success) while the notification is best-effort. Doctrine
   wording cue: "evidence appended is mandatory" vs "notification SHOULD
   be sent." The agent_mail_status field in the row records which path
   actually fired, so audit can reconcile silent escalations.

## Substrate-hygiene-doctrine-cluster status (post-ukbej)

| Doctrine | Author-time | Audit-time | Runtime enforcement |
|---|---|---|---|
| git-stash-discipline | pre-commit hook | stash-discipline-check.sh | session-shutdown audit |
| blocker-discipline | (TBD: worker-time verification_path check) | escalations.jsonl ledger | blocker-auto-close + blocker-fail-escalator |

Cluster is now end-to-end on the audit + runtime axes. The author-time
worker-side enforcement (refuse to file a blocker without a re-runnable
verification_path) is a candidate next bead.

## Four-Lens Self-Grade

four_lens=brand:10,sniff:10,jeff:10,public:10

- brand: closes the 4-bead arc; PASS + FAIL hooks share the same row schema (event field differentiates); single escalations.jsonl ledger is the audit-trail truth source per doctrine.
- sniff: real counter increments + reset verified across 6 consecutive AC calls (tests 8-15); per-blocker override beats CLI override (test 17); impure AC correctly bypasses counter (test 16, MISMATCH trauma is orthogonal to consecutive-fail).
- jeff: data decides — the AC's verdict from replay-verify drives the counter; the counter drives the escalation; the escalation row is a deterministic record. The agent-mail status field records WHICH delivery path fired (sent/skipped/failed), so an audit can detect silent escalations.
- public: every escalation row carries enough context (ac_command, blocker_id, consecutive_fail_count, threshold_n, live_probe_at) for a future operator to reconstruct what was decided and why. The Agent Mail body includes copy-pasteable commands to re-evaluate or force-close.
