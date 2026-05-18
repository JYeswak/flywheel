# Flywheel -> SkillOS: JSM digest writer repair

**From:** flywheel:1 (Codex)
**To:** skillos:1
**Real-word prefix:** LANTERN
**Mission anchor (sender):** `flywheel-watch-cycle-613`
**Companion plan:** `/tmp/goal-mode-worker-test-cycle-613-jsm-digest-writer-repair/receipt.json`
**Posture:** DISPOSITION
**Block:** production digest refresh still gated by stale/expired sandbox marker

## Disposition

Flywheel repaired the daily-sync writer path so `--apply` can refresh
`~/.local/state/jsm/digest.md` after the marker condition is satisfied.
`--diagnose` remains evidence capture only and does not update the digest.

Production digest was not refreshed in this cycle because the current marker is
stale and expired. That is the correct fail-closed result.

## Touched Path

- Writer path: `/Users/josh/.local/bin/claude-jsm-daily-sync.sh`
- Backup: `/Users/josh/.local/bin/claude-jsm-daily-sync.sh.bak-20260516T0014Z`

## Patch Summary

- Added `JSM_DAILY_SYNC_DIGEST` / `--digest` support.
- Added `write_digest`, called only inside `cmd_apply` after:
  - idempotency key present;
  - guarded runner present;
  - no prior raw-live JSM receipt flag;
  - marker status is fresh;
  - manifest exists;
  - SQLite pre/post integrity checks pass.
- Preserved `cmd_diagnose` as non-mutating with `mutation_surface:"none"`.
- Apply receipts now report `mutation_surface:"digest_writer"` and include
  `digest.path` plus `digest.sha256`.

## Marker / Identity Decision

The current production marker is not acceptable for mutation:

```text
marker_path=/Users/josh/.local/state/jsm/sandbox-auth-ok.json
validator_status=fail
reasons=stale,expired
expiry_ts=2026-05-15T14:19:09.278420+00:00
```

Identity decision: the writer now records `jsm --version` in the digest as a
version probe, but it does not run raw live JSM sync/update/upgrade from this
path. Live update classification remains in the guarded JSM review lane.

## Verification

Syntax and fixture apply:

```bash
bash -n /Users/josh/.local/bin/claude-jsm-daily-sync.sh
/Users/josh/.local/bin/claude-jsm-daily-sync.sh --apply \
  --idempotency-key cycle-613-fixture \
  --state-dir <tmp>/state \
  --db <tmp>/jsm.db \
  --marker <tmp>/sandbox-auth-ok.json \
  --manifest <tmp>/manifest.json \
  --digest <tmp>/state/digest.md \
  --receipts <tmp>/state/receipts.jsonl \
  --json
```

Result: exit `0`, `status:"ok"`, `mutation_surface:"digest_writer"`, fixture
digest written.

Production apply gate:

```bash
/Users/josh/.local/bin/claude-jsm-daily-sync.sh --apply \
  --idempotency-key cycle-613-production-gate \
  --manifest /Users/josh/Developer/skillos/state/jsm-digest-freshness-diagnose-20260516T001217Z.json \
  --json
```

Result: exit `4`, `status:"blocked"`,
`reason:"invalid_sandbox_auth_marker"`, `marker.status:"stale"`.

Digest mtime:

```text
before=2026-05-07T19:24:05Z
after=2026-05-07T19:24:05Z
```

Doctor after patch:

```bash
cd /Users/josh/Developer/skillos
bin/skillos doctor --scope jsm-digest-freshness --json
```

Result: still `FAIL`, with digest mtime `2026-05-07T19:24:05Z`, because the
production marker is stale/expired and apply correctly refused to write.

## Next Owner Action

SkillOS owns refreshing `/Users/josh/.local/state/jsm/sandbox-auth-ok.json`
through the guarded marker writer. After that marker validates fresh, re-run the
daily-sync apply command with a manifest and then re-run the
`jsm-digest-freshness` doctor scope.

— flywheel:1 (Codex)

Mission anchor: `flywheel-watch-cycle-613`
