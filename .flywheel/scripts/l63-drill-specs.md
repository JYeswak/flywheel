# L63 Fleet-Coherence Recovery Drill Specs

Date: 2026-05-03
Bead: `flywheel-375`
Status: design/spec artifact for the L63 gate

## Sources And Current State

- L63 text exists in `AGENTS.md.bak.20260501T144153Z` lines 451-457 and
  project memory, but current `AGENTS.md` currently stops at L59.
- Synthesis v2 acceptance source: `/tmp/plan_fleet_coherence_synthesis_v2.md`
  lines 218-226.
- Schema source: `.flywheel/specs/fleet-coherence-schema-v2.md`.
- Current drill runner: `~/.claude/skills/.flywheel/scripts/kill-recover-drill.sh`.
- Current runner implements legacy D2/D3 pane/session damage only; this spec maps
  the L63 fleet-coherence semantic drill gate on top of that substrate.

## L63 Acceptance Mapping

| Drill # | Damage class | Target | Mode | L63 acceptance criterion covered |
|---|---|---|---|---|
| 1 | D3 / killed daemon | `zeststream-v2` sacrificial pane | manual | Recovery primitive restores an agent pane after process death. |
| 2 | D5 / stale latest | `clutterfreespaces` cached state | manual | `drift-status` treats stale latest snapshot as non-ready and refresh proves recovery. |
| 3 | D2 / corrupt JSONL | `zeststream-v2` event log row | manual | Writer/status tolerate malformed history and emit usable latest state. |
| 4 | D2 / Agent Mail unavailable | `skillos` alert path | auto | L61 degrades when Agent Mail is unavailable; degraded is not counted as success. |
| 5 | D2 / NTM poke failure | `skillos` alert path | auto-idem | L61 degrades when NTM poke fails, then retries idempotently once transport recovers. |

L63 is green only when `~/.local/state/flywheel/recovery-drill.jsonl` contains
five `green=true` rows covering all five drill IDs below, and fleet-coherence
event/action rows cite those IDs in `l63.recovery_drill_ids` before any
auto-remediation action is marked ready.

## Shared Drill Row Schema

Append one JSON object per completed drill to
`~/.local/state/flywheel/recovery-drill.jsonl`:

```json
{
  "schema_version": 1,
  "record_type": "l63_recovery_drill",
  "drill_id": "l63-01-killed-daemon-20260503T000000Z",
  "bead_id": "flywheel-375",
  "l_rule": "L63",
  "ts": "2026-05-03T00:00:00Z",
  "target_session": "zeststream-v2",
  "target_pane": 1,
  "damage_class": "killed-daemon",
  "legacy_damage_class": "D3",
  "mode": "manual",
  "injection": {"command": "...", "rc": 0},
  "recovery": {"primitive": "ntm-respawn", "rc": 0, "elapsed_s": 30},
  "green": true,
  "evidence": {
    "pre_ref": "path-or-hash",
    "post_ref": "path-or-hash",
    "log_refs": ["path#line"],
    "status": "short human-readable proof"
  },
  "rollback": {"required": false, "performed": false, "ref": null},
  "notes": "No production fuckup-log rows written by drill."
}
```

Compatibility note: rows emitted by the existing `kill-recover-drill.sh` may
use its current compact schema (`drill_id`, `damage_class`, `primitive`,
`liveness_verified`, `pre_hash`, `post_hash`). Those rows count only when a
wrapper or findings note maps them to an L63 semantic drill ID.

## Drill 1: Killed Daemon / Pane Process Death

**Damage injection**

Use only a sacrificial non-client session. Do not target `alpsinsurance`,
`picoz`, or `skillos` for manual kill drills.

```bash
DRILL_LOG="$HOME/.local/state/flywheel/recovery-drill.jsonl" \
  /Users/josh/.claude/skills/.flywheel/scripts/kill-recover-drill.sh \
  --session zeststream-v2 \
  --pane 1 \
  --damage-class D3 \
  --primitive ntm-respawn
```

**Recovery procedure**

The runner injects D3 and invokes `ntm respawn <session> --panes=<pane> --force`.
Manual recovery is acceptable for this drill because it proves the primitive,
not auto-remediation policy.

**Green criteria**

- Runner exits 0.
- Row appended with `liveness_verified=true`.
- Pre/post snapshot hashes differ, and post snapshot shows live agent command via
  `ntm --robot-activity`.
- No protected session touched.

**Rollback**

The runner has trap-backed rollback state. If it fails, run:

```bash
/Users/josh/.local/bin/ntm respawn zeststream-v2 --panes=1 --force
```

**JSONL row**

Use `drill_id=l63-01-killed-daemon-<ts>`,
`damage_class="killed-daemon"`, `legacy_damage_class="D3"`,
`mode="manual"`, `recovery.primitive="ntm-respawn"`, `green=true`.

## Drill 2: Stale Latest Snapshot

**Damage injection**

Operate on the cached fleet-coherence state, not live panes. Backup first:

```bash
state_dir="${FC_STATE_DIR:-$HOME/.local/state/flywheel}"
latest="$state_dir/fleet-coherence-latest.json"
backup="/tmp/l63-stale-latest.$(date -u +%Y%m%dT%H%M%SZ).json"
cp "$latest" "$backup"
tmp="$(mktemp "${TMPDIR:-/tmp}/fleet-coherence-latest.XXXXXX")"
jq '.ts="2000-01-01T00:00:00Z"
    | .detector_heartbeat_ts="2000-01-01T00:00:00Z"
    | .source_age_s=999999' "$latest" > "$tmp"
mv "$tmp" "$latest"
```

**Recovery procedure**

Run the single-cycle scanner/writer once when Phase 1c exists, or wait for the
launchd scanner tick when Phase 1b is live:

```bash
.flywheel/scripts/fleet-coherence-scan.sh --once
.flywheel/scripts/fleet-coherence-write.sh --refresh-latest --state-dir "$state_dir"
```

If those helpers do not exist yet, this drill is design-ready but execution is
blocked on Phase 1b/1c.

**Green criteria**

- `flywheel-loop drift-status --json` exits nonzero while the latest snapshot is
  stale.
- Refresh writes a valid latest snapshot atomically.
- `jq -e . "$latest"` succeeds after recovery.
- Status no longer reports stale detector/runtime error for `clutterfreespaces`.

**Rollback**

```bash
cp "$backup" "$latest"
```

**JSONL row**

Use `drill_id=l63-02-stale-latest-<ts>`,
`damage_class="stale-latest"`, `legacy_damage_class="D5"`,
`mode="manual"`, `green=true`, with `evidence.pre_ref=$backup` and
`evidence.post_ref=$latest`.

## Drill 3: Corrupt JSONL History

**Damage injection**

Append a single malformed row to the hot fleet-coherence event log after a
backup:

```bash
state_dir="${FC_STATE_DIR:-$HOME/.local/state/flywheel}"
events="$state_dir/fleet-coherence.jsonl"
backup="/tmp/l63-corrupt-jsonl.$(date -u +%Y%m%dT%H%M%SZ).jsonl"
cp "$events" "$backup"
printf '{"schema_version":2,"detector":"fleet-coherence","bad":\n' >> "$events"
```

**Recovery procedure**

The writer/status path must tolerate the corrupt historical row, emit or retain a
`detector_runtime_drift` observation, and still produce valid current latest
state:

```bash
.flywheel/scripts/fleet-coherence-write.sh --refresh-latest --state-dir "$state_dir"
/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop drift-status --json
```

If Phase 1c helpers do not exist yet, this drill is design-ready but execution is
blocked on the writer bead.

**Green criteria**

- No parser crash from malformed historical JSONL.
- Latest snapshot is valid JSON.
- The corrupt row is either ignored with a raw source ref or surfaced as
  `class="detector_runtime_drift"`.
- No synthetic rows are written to production fuckup-log.

**Rollback**

```bash
cp "$backup" "$events"
.flywheel/scripts/fleet-coherence-write.sh --refresh-latest --state-dir "$state_dir"
```

**JSONL row**

Use `drill_id=l63-03-corrupt-jsonl-<ts>`,
`damage_class="corrupt-jsonl"`, `legacy_damage_class="D2"`,
`mode="manual"`, `green=true`, and cite the bad row offset or backup path in
`evidence.log_refs`.

## Drill 4: Agent Mail Unavailable

**Damage injection**

Do not alter real tokens. Inject unavailability by pointing the auth probe or
alert sender at an empty temporary fleet-mail token vault/project:

```bash
tmp_project="$(mktemp -d "${TMPDIR:-/tmp}/fleet-mail-project.XXXXXX")"
tmp_vault="$(mktemp -d "${TMPDIR:-/tmp}/fleet-mail-tokens.XXXXXX")"
FLEET_MAIL_PROJECT_KEY="$tmp_project" \
FLEET_MAIL_TOKEN_DIR="$tmp_vault" \
  .flywheel/scripts/fleet-mail-auth-probe.sh --session skillos --json
```

**Recovery procedure**

The fleet-coherence alert path must automatically degrade rather than counting
the alert as L61-complete:

```bash
FLEET_MAIL_PROJECT_KEY="$tmp_project" \
FLEET_MAIL_TOKEN_DIR="$tmp_vault" \
  .flywheel/scripts/fleet-coherence-alert.sh \
  --fixture-event .flywheel/fixtures/fleet-coherence-fixtures.jsonl \
  --session skillos \
  --dry-run
```

Then rerun with normal project/token environment and verify the same event can
complete through the real authenticated path.

**Green criteria**

- Unavailable Agent Mail produces `l61_pairing_status="degraded"`, never
  `"complete"`.
- `degraded_reason` names the Agent Mail leg.
- NTM leg is still attempted if policy permits degraded fallback.
- Recovered rerun produces a paired Agent Mail message ID plus NTM result.

**Rollback**

Remove temp project/vault:

```bash
rm -rf "$tmp_project" "$tmp_vault"
```

**JSONL row**

Use `drill_id=l63-04-agent-mail-unavailable-<ts>`,
`damage_class="agent-mail-unavailable"`, `legacy_damage_class="D2"`,
`mode="auto"`, `target_session="skillos"`, `green=true`.

## Drill 5: NTM Poke Failure / Idempotent Retry

**Damage injection**

Inject a failing NTM binary for the alert sender only; do not damage the real
`ntm` binary or sessions:

```bash
fake_ntm="$(mktemp "${TMPDIR:-/tmp}/ntm-fail.XXXXXX")"
cat > "$fake_ntm" <<'SH'
#!/usr/bin/env bash
printf 'synthetic ntm failure for L63 drill\n' >&2
exit 42
SH
chmod +x "$fake_ntm"
NTM_BIN="$fake_ntm" \
  .flywheel/scripts/fleet-coherence-alert.sh \
  --fixture-event .flywheel/fixtures/fleet-coherence-fixtures.jsonl \
  --session skillos \
  --dry-run
```

**Recovery procedure**

Restore real `NTM_BIN` and rerun the same event/dedupe key. The sender must
avoid duplicate durable Agent Mail spam and converge to exactly one complete
alert ledger for the event:

```bash
unset NTM_BIN
.flywheel/scripts/fleet-coherence-alert.sh \
  --fixture-event .flywheel/fixtures/fleet-coherence-fixtures.jsonl \
  --session skillos \
  --dry-run
```

**Green criteria**

- First run records NTM leg failure as degraded, not complete.
- Second run records `l61_pairing_status="complete"`.
- Ledger keeps one logical event/dedupe key, with retry metadata instead of a
  second independent alert.
- Callback pane comes from `session-topology.jsonl`, not hardcoded pane numbers.

**Rollback**

```bash
rm -f "$fake_ntm"
```

**JSONL row**

Use `drill_id=l63-05-ntm-poke-failure-<ts>`,
`damage_class="ntm-poke-failure"`, `legacy_damage_class="D2"`,
`mode="auto-idem"`, `target_session="skillos"`, `green=true`.

## Cross-Check Against flywheel-2am Execution

`flywheel-2am` planned sequence:

1. `zeststream-v2` D3 manual
2. `clutterfreespaces` D3 manual
3. `zeststream-v2` D2 manual
4. `skillos` D2 wait-for-daemon
5. `skillos` D2 idempotency

That sequence overlaps the L63 gate but does not prove all five semantic
fleet-coherence criteria unless the produced rows explicitly map to this spec:

- It can satisfy Drill 1 if the `zeststream-v2` D3 row is green.
- It may provide useful primitive evidence for Drill 3, 4, and 5, but D2 alone
  does not prove corrupt JSONL, Agent Mail unavailability, or NTM poke failure.
- It does not cover Drill 2 stale latest unless a stale cached latest is actually
  injected and recovered.

At the time this spec was authored, `/tmp/flywheel-2am_findings.md` and
`~/.local/state/flywheel/recovery-drill.jsonl` were absent. Next tick must
cross-check any 2am rows by `drill_id`, semantic `damage_class`, target, and
green criteria before counting them toward L63.

## Final Gate

Phase 3b auto-remediation remains blocked until all five drill IDs above are
green and cited from fleet-coherence event/action rows as
`l63.recovery_drill_ids`.
