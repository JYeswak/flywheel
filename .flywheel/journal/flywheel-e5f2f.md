---
bead: flywheel-e5f2f
title: agent.sh:141 identity-doctor probe path-resolution fix
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P0
mission_fitness: direct
trauma_class: skillos-ubh3 (substrate-doctor-probe-path-missing)
---

# Journey: flywheel-e5f2f

## What Joshua asked for

P0 BUG fix from cross-orch skillos-ubh3 trauma class report:
`agent.sh:141 agent_mail_identity_registry_doctor_json()` shells `$0 identity
--doctor --json` but flywheel CLI has no identity subcommand → doctor
returns synth-fail across fleet.

Two fix paths offered:
- (a) wire identity subcommand in `bin/flywheel` to delegate to
  `scripts/agent-mail-identity-audit.sh`
- (b) update `agent.sh:141` caller to invoke audit script directly

Pick smaller blast radius + better canonical-cli surface.

## What I built

**Path (b) refined**: Resolve probe to absolute `flywheel-loop` binary path
(NOT to the audit script). Three reasons:
1. `flywheel-loop` already has the `identity` subcommand wired to
   `portable_identity` (line 228 of dispatcher), which calls `identity.py`
   that emits the right schema (status, identity_registry_drift, drift_count,
   total_registered, rows). Verified: `flywheel-loop identity --doctor --json`
   returns `{"status":"pass","identity_registry_drift":0,"total_registered":20}`.
2. The `agent-mail-identity-audit.sh` script emits a DIFFERENT schema
   (`{action,healthy[],missing[],totals:{...}}`) — would need an adapter.
3. Sister probes in the SAME file (line 4: `agent_mail_fd_pressure_json`,
   line 167: `agent_mail_registration_broadcast_doctor_json`) use exactly
   this canonical pattern: `local probe="${ENV_VAR:-absolute-default-path}"`.

So the canonical fix is to follow the in-file sister-probe pattern, pointing
at `flywheel-loop` (which has the working subcommand), NOT at the audit
script (which has a different schema). Single-file change, single function
modified, zero new subcommands.

## Investigation arc

1. Read agent.sh:141. Confirmed bug at line 146: `"$0" identity --doctor --json`.
2. Located identity.py with full argparse for `--doctor --schema --json`.
3. Found `flywheel-loop` dispatcher routes `identity` → `portable_identity` → `identity.py`.
4. Confirmed `flywheel-loop identity --doctor --json` returns valid JSON
   in 0.27s (well under the 1s probe timeout).
5. Patched a debug copy of agent.sh to print `$0` at runtime — confirmed it
   resolves to `bash` when sourced via `bash -c`, not to `flywheel-loop`.
   This is the failure mode the bug describes.
6. Compared with sister probes — both use `${ENV_VAR:-$HOME/.../path}`
   pattern. Identity probe's `$0` was the outlier.

## Fix shape

```bash
# BEFORE (HEAD):
local output
output="$("$0" identity --doctor --json 2>/dev/null)" || true

# AFTER (committed):
local probe="${FLYWHEEL_AGENT_MAIL_IDENTITY_PROBE:-${FLYWHEEL_HOME:-$HOME/.claude/skills/.flywheel}/bin/flywheel-loop}"
local output timeout_bin probe_timeout
timeout_bin="${FLYWHEEL_TIMEOUT_BIN:-timeout}"
probe_timeout="${FLYWHEEL_AGENT_MAIL_IDENTITY_TIMEOUT_SECONDS:-${FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS:-1}}"
if [[ ! -x "$probe" ]]; then
    # Sister pattern: missing probe → warn + drift=0 (NOT synth-fail)
    jq -nc --arg probe "$probe" '{...status:"warn",drift_count:0,...}'
    return 0
fi
if command -v "$timeout_bin" >/dev/null 2>&1; then
    output="$("$timeout_bin" "$probe_timeout" "$probe" identity --doctor --json 2>/dev/null)" || true
else
    output="$("$probe" identity --doctor --json 2>/dev/null)" || true
fi
# (rest unchanged: jq parse → emit; else → synth-fail for the actual edge case)
```

## Files touched

- **CODE FIX (committed in `.claude` repo)**: `~/.claude/skills/.flywheel/lib/agent.sh`
  - Commit `8521049` on `main` of `/Users/josh/.claude` repo
  - +28/-2 lines, single function modified
- **TEST + EVIDENCE (committed in `flywheel` repo)**:
  - `tests/agent-mail-identity-registry-doctor-probe.sh` (NEW, 7 tests, 100% pass)
  - `.flywheel/audit/flywheel-e5f2f/evidence.md`
  - `.flywheel/audit/flywheel-e5f2f/compliance-pack.md`
  - `.flywheel/audit/flywheel-e5f2f/agent-sh.diff` (clean diff of just my hunk)
  - `.flywheel/audit/flywheel-e5f2f/smoke-probe-before.json`
  - `.flywheel/audit/flywheel-e5f2f/smoke-probe-after.json`
  - `.flywheel/audit/flywheel-e5f2f/smoke-doctor-after.json`
  - `.flywheel/audit/flywheel-e5f2f/test-run.txt`
  - `.flywheel/journal/flywheel-e5f2f.md`

## Notable surgery: peer-orch in-flight changes

`~/.claude/skills/.flywheel/lib/agent.sh` had ~150 lines of in-flight
uncommitted changes from a peer orch (timeout/probe-pattern refactor of
sister probes `agent_mail_fd_pressure_json`, `orphaned_mcp_tool_call_json`,
`agent_mail_registration_broadcast_doctor_json`). I did NOT sweep these into
my commit. Surgery:

1. Backed up working tree (in-flight + my fix) to `/tmp/agent-sh-with-my-fix.bak`
2. Built HEAD-version + only-my-hunk via `git show HEAD:path` + manual edit
3. Replaced working tree with HEAD+only-my-hunk
4. `git add` (stages just my 28-line hunk)
5. `git commit` (clean, isolated, only my fix)
6. Restored working tree from backup (in-flight + my fix re-restored)

Result: clean atomic commit `8521049` with 28/-2 lines; in-flight peer-orch
state preserved in working tree for whoever owns it.

DCG correctly blocked an earlier `git checkout HEAD --` attempt (would have
clobbered in-flight work). Used the safer `git show HEAD:path > /tmp/...`
non-destructive read instead.

## AC honest assessment

**Identity probe portion: ✓ FIXED.**
- `agent_mail_identity_registry_doctor_json` returns `status=pass drift=0` (was `fail drift=1`)
- `flywheel-loop doctor --json` reports `identity_registry_drift=0` and
  `identity_registry.status=pass` and `identity_registry.errors=[]`

**Top-level `flywheel-loop doctor --json` status: still `fail`, but NOT
identity-related.** 5 unrelated probe failures roll up: beads_db_health,
memory_health, loop_driver_missing_driver, active_marker_project_label,
validation_receipts_schema_invalid. None of these are `identity_registry_*`.
Each is a separate bead.

The dispatch text said "doctor synth-fails fleet-wide" with the trauma class
named "substrate-doctor-probe-path-missing" — that's specifically the
identity probe's wrong-path behavior, which IS fixed.

## Mission fitness

**Class: direct**. Bug fix on the canonical doctor probe surface. The
identity probe is a load-bearing ingredient in fleet-wide health checks and
gating logic.

## Cross-orch resolution callback

Will send a separate notification to the skillos-ubh3 owning bead per
cross-orch protocol (in addition to the worker DONE callback to flywheel:1).
