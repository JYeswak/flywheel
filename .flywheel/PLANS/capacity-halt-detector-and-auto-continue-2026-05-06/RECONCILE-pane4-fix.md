# Reconcile: pane 4 capacity-halt fix plus M1 lease closure

Task: `capacity-halt-production-path-reconcile-2026-05-06`
Bead: `flywheel-capacity-halt-production-path-reconcile-2026-05-06`
Verdict: PASS

## Live Probe Verification

Command:

```bash
.flywheel/scripts/codex-template-stuck-detector.sh --fixture .flywheel/tests/fixtures/capacity-halt-live --dry-run --json
```

Observed:

```json
{"status":"stuck","stuck_count":1,"dry_run":true,"subclass":"model_at_capacity_halt","recommended_recovery":"auto_continue","hash_stable":true}
```

The detector exits `1` because it correctly found a stuck pane fixture. The production classifier path returns `subclass=model_at_capacity_halt` and `recommended_recovery=auto_continue`, matching pane 4's closeout claim.

## Plist Verification

Command:

```bash
launchctl list | grep -E "worker-auto-respawn|flywheel-codex-stuck"
```

Observed:

```text
-       0       ai.zeststream.worker-auto-respawn-watchdog
76251   1       ai.zeststream.flywheel-codex-stuck-detector
```

Both required LaunchAgents are visible. The stuck detector has a nonzero recent exit code in `launchctl list`, but the dispatch only required plist presence for this reconcile bead. No plist mutation was performed.

## Lease Primitive Verification

Artifact: `.flywheel/scripts/capacity-halt-lease-primitive.sh`

Shape:
- Bash strict mode wrapper.
- Canonical verbs: `--info`, `--help`, `--examples`, `--json`, `--acquire`, `--release`, `--list`.
- Exit codes: `0=acquired-or-query-ok`, `1=already-held`, `2=malformed`, `3=read-error`.
- Ledger: `~/.local/state/flywheel/capacity-halt-lease.jsonl`.
- Key: `(session, pane, scrollback_digest)`.
- TTL default: 90 seconds.
- Release is append-only; historical acquire rows are never mutated.

Test command:

```bash
bash .flywheel/tests/test_capacity_halt_lease_primitive.sh
```

Observed: `18 passed, 0 failed`.

Covered cases:
- Fresh acquire returns exit `0` and appends one acquire row.
- Duplicate acquire within TTL returns exit `1` and appends no second acquire row.
- Expired lease reacquires and appends a new acquire row.
- Same session/pane with a different digest acquires independently.
- Release appends a release row with result outcome.
- Malformed digest returns exit `2` without a ledger write.

## Watchdog Integration

Artifact: `.flywheel/scripts/worker-auto-respawn-watchdog.sh`

The capacity-halt branch now:
1. Reads `scrollback_digest` from the classifier, using the last 30 live scrollback lines for live panes.
2. Calls `capacity-halt-lease-primitive.sh --acquire --session <S> --pane <P> --digest <D> --ttl 90 --json` before `auto_continue`.
3. Refuses duplicate fires with action `auto_continue_lease_held`.
4. Appends a release row after the `continue` send attempt with `result=success|failure`.

Regression command:

```bash
bash .flywheel/tests/test_worker_auto_respawn_watchdog.sh
```

Observed: `34 passed, 0 failed`.

The added M1 case pre-acquires the same `(session, pane, digest)` lease, reruns the watchdog, and verifies no `continue` send or respawn occurs.

## M1 Closure

Audit finding M1: duplicate watchers/ticks can send repeated `continue` for the same stable screen.

Closure mechanism: the auto-continue branch is now gated by a per-pane/digest lease. Same stuck screen within the 90-second TTL is refused before transport send. A changed stuck screen produces a different digest and can proceed through the existing hourly budget path.

Donella read: #5 Rules. The lease is the system rule preventing duplicate fire, with a JSONL information flow for later doctor/ledger beads.

## Reconciliation Verdict

PASS. Pane 4's production classifier fix holds against the live-pattern fixture, the required LaunchAgents are visible, and M1 is closed by a tested append-only lease primitive integrated directly before the auto-continue send path.
