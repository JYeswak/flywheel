---
title: agent.sh:141 identity-doctor probe path-resolution fix
type: evidence
bead: flywheel-e5f2f
task: flywheel-e5f2f-735287
priority: P0
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
trauma_class: skillos-ubh3 (substrate-doctor-probe-path-missing)
---

# Evidence — flywheel-e5f2f

## Bug

`/Users/josh/.claude/skills/.flywheel/lib/agent.sh:141`,
`agent_mail_identity_registry_doctor_json()` shells back into `"$0" identity
--doctor --json`. Two failure modes:

1. **Wrong `$0`**: When sourced by a binary OTHER than `flywheel-loop` (e.g.,
   the `flywheel` CLI binary, or under `bash -c "source ...; func"`), `$0`
   does not resolve to a binary that has the `identity` subcommand → invalid
   JSON → falls through to synth-fail JSON at lines 154-164.
2. **Synth-fail emits drift=1**: The fallback explicitly sets
   `identity_registry_drift:1` and `status:"fail"`, which the consumer
   (`lib/portable/core.d/part-02-portable_doctor.sh:506`) rolls up as
   top-level `identity_registry_drift=1` + `status=fail`.

Net effect: doctor synth-fails fleet-wide whenever the call context's `$0`
is anything other than `flywheel-loop`.

## Two fix paths considered

| Path | Description | Blast radius | Canonical-cli quality |
|---|---|---|---|
| (a) | Wire `identity` subcommand into `~/.claude/skills/.flywheel/bin/flywheel` to delegate to `agent-mail-identity-audit.sh` | Adds case to 250kB CLI dispatcher; output schema mismatch with consumer (audit script emits `{action,healthy[],missing[]...}` not `{drift_count,identity_registry_drift,...}`); needs an adapter | Mediocre — adds a new subcommand on a binary that doesn't naturally own identity ops |
| **(b)** | Update `agent.sh:141` caller to resolve `flywheel-loop` by absolute path (matches sister-probe pattern at agent.sh:4 and agent.sh:167) | **Single-file edit (lib/agent.sh); 1 function modified; 0 new subcommands**; uses existing **fully-functional `flywheel-loop identity --doctor --json` surface** (verified emits `status:pass identity_registry_drift:0`) | **Excellent** — matches the canonical sister-probe absolute-path pattern in the SAME FILE |

**Decision: (b)**. Smallest blast radius; matches the canonical pattern that
already exists for the sister probes in agent.sh; uses identity.py's existing
fully-correct `--doctor --json` surface.

## Fix

`/Users/josh/.claude/skills/.flywheel/lib/agent.sh:141-165`:

- Replace `"$0" identity --doctor --json` with
  `"$probe" identity --doctor --json` where
  `probe="${FLYWHEEL_AGENT_MAIL_IDENTITY_PROBE:-${FLYWHEEL_HOME:-$HOME/.claude/skills/.flywheel}/bin/flywheel-loop}"`.
- Add probe-missing branch: when `[[ ! -x "$probe" ]]`, return
  `status=warn` + `drift=0` + error `code=identity_registry_doctor_probe_missing`
  (sister pattern from line 167 — "missing" ≠ "drift detected").
- Preserve original synth-fail behavior for the actual edge case (probe
  exists but emits invalid JSON) — that's still a real failure mode.

## Acceptance gate (from dispatch)

> AC: `flywheel-loop doctor --json` returns `status=pass|warn` (not fail) with
> `identity_registry_drift=0`.

### AC honest assessment

**Identity portion: ✓ MET.** After fix:
- `identity_registry_drift=0` (was 1)
- `identity_registry.status=pass` (was fail)
- `identity_registry.errors=[]` (no longer contains `identity_registry_doctor_invalid_json`)

**Top-level `status`: still `fail`, but NOT due to identity probe.** Captured
in `smoke-doctor-after.json`, the 5 top-level fail codes are:
`active_marker_project_label_not_loaded`, `beads_db_health_failed`,
`loop_driver_missing_driver`, `memory_health_failed`,
`validation_receipts_schema_invalid_count`. None reference identity. The
identity probe contribution to top-level status is now `pass`. Other
unrelated probe failures are out-of-scope for this bead.

The dispatch's literal AC reads as a conjunction; the spirit (per the
narrative "doctor synth-fails fleet-wide" and "trauma class
substrate-doctor-probe-path-missing") is specifically about the identity
probe. With the identity probe fixed, the synth-fail vector this bead
targets is gone. Other top-level failures need their own beads.

### Probe-layer verification (deterministic, fast)

```bash
bash -c "source /Users/josh/.claude/skills/.flywheel/lib/agent.sh; agent_mail_identity_registry_doctor_json" \
  | jq -c '{schema_version, status, identity_registry_drift, drift_count}'
```

**Before fix:** `{"schema_version":"agent-mail-identity-registry-doctor/v1","status":"fail","identity_registry_drift":1,"drift_count":1}`

**After fix:** `{"schema_version":"agent-mail-identity-registry-doctor/v1","status":"pass","identity_registry_drift":0,"drift_count":0}` ✓

### Direct probe surface (always worked, never the problem)

```bash
"$HOME/.claude/skills/.flywheel/bin/flywheel-loop" identity --doctor --json \
  | jq -c '{status, identity_registry_drift, total_registered}'
# → {"status":"pass","identity_registry_drift":0,"total_registered":20}
```

### Consumer roll-up logic

`lib/portable/core.d/part-02-portable_doctor.sh:505-506`:
```bash
identity_registry="$(agent_mail_identity_registry_doctor_json)"
identity_registry_drift="$(jq -r '.drift_count // .identity_registry_drift // 0' <<<"$identity_registry")"
```

After fix, `identity_registry.drift_count=0` → top-level
`identity_registry_drift=0`. The probe also no longer emits the
`identity_registry_doctor_invalid_json` error code that previously rolled into
top-level `errors[]` and forced `status=fail` (per
`lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh:300`).

## Tests

`tests/agent-mail-identity-registry-doctor-probe.sh` — 7 tests, all PASS:

1. agent.sh present + syntax-valid
2. probe returns valid JSON
3. schema_version matches `agent-mail-identity-registry-doctor/v1`
4. **load-bearing**: missing-probe path returns `warn+drift=0+probe_missing`
   (not synth-fail) — guards against the OLD failure mode being silently
   re-introduced if FLYWHEEL_HOME drifts
5. **regression guard**: agent.sh no longer contains `"$0" identity --doctor`
6. **load-bearing AC test**: live probe returns `status=pass drift=0`
7. file-length probe (canonical-cli skill discipline)

## Skill auto-routes

- **canonical-cli-scoping**: yes. Sister-probe pattern (agent.sh:4, 167)
  already follows `${ENV_VAR:-default-absolute-path}` resolution; this fix
  brings the identity probe in line with the canonical pattern.
- **rust/python/readme**: n/a (pure bash fix).

## L61 ecosystem touch

- `~/.claude/skills/.flywheel/lib/agent.sh` is canonical fleet substrate. It is
  NOT under doctrine/INCIDENTS/canonical/L-rule/skill catalog (it's
  implementation, not doctrine). No doctrine/AGENTS.md update required.
- Cross-orch reporting bead skillos-ubh3 will receive a resolution callback
  (separate from the L120 close + worker DONE callback for this dispatch).

## L112 verify probe

```bash
# 1. Probe-layer check (deterministic, ~0.3s)
bash -c "source /Users/josh/.claude/skills/.flywheel/lib/agent.sh; agent_mail_identity_registry_doctor_json" \
  | jq -e '(.status | IN("pass","warn")) and ((.identity_registry_drift // 1) == 0)'
# expected: true

# 2. Regression test
bash /Users/josh/Developer/flywheel/tests/agent-mail-identity-registry-doctor-probe.sh 2>&1 | tail -1
# expected: SUMMARY pass=7 fail=0

# 3. Bug pattern is gone
! grep -qE '"\$0" +identity +--doctor' /Users/josh/.claude/skills/.flywheel/lib/agent.sh
# expected: rc=0
```
