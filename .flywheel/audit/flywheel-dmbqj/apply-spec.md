# flywheel-dmbqj — apply-spec

## Disposition: SUPERSEDED-BY-flywheel-x4e3s

flywheel-dmbqj asks for the same fix bundle that flywheel-x4e3s
already shipped at commit `a978da7` (2026-05-10 10:21 MDT). All
three bug IDs the bead enumerates (946sy + 52fox + gnfi3) are
already CLOSED. Bundle regression test
`tests/scaffold-canonical-cli-bugfix-bundle.sh` ships in the same
commit and passes 6/6.

This apply-spec documents the verification rather than re-doing the
work. Per the data-decides-not-meatpuppet discipline, the audit
finding (dup) is the disposition; reopening the same work would be
churn.

## Bug-by-bug verification (post-x4e3s state)

### Bug 1 — abs-path test scaffold double-slash (946sy + gnfi3)

**Symptom**: `emit_test_scaffold` prepended `$ROOT/` to all
target_rel values, producing `$ROOT//Users/...` for absolute paths
outside REPO_ROOT.

**Fix location**: `.flywheel/scripts/scaffold-canonical-cli.sh:515-519`
```
  if [[ "$target_rel" = /* ]]; then
    script_var_value="${target_rel}"
  else
    script_var_value="\$ROOT/${target_rel}"
  fi
```

**Verification probe**:
```
bash tests/scaffold-canonical-cli-bugfix-bundle.sh
```
PASS[1] absolute target emits literal SCRIPT= without double-slash.
PASS[1b] relative-path target retains $ROOT prefix (regression guard).

### Bug 2 — L4 short-circuit in generated stubs (946sy AG2)

**Symptom**: `cmd_doctor`/`cmd_health`/`cmd_validate` stubs lacked
a canonical pattern visible to operators filling TODOs. Operators
were writing `[[ ]] && X || Y` (forbidden by L4 lint) and ~8 manual
rewrites happened during waves jh5bb/aav72/hj4ip.

**Fix location**: `.flywheel/scripts/scaffold-canonical-cli.sh:380-389`
Stub generator embeds an exemplar comment:
```
# Canonical pattern (per L4 lint rule — NEVER use `[[ ]] && X || Y`
# as the last expression of a helper; use if/then/else/fi):
#   if [[ -d "$ROOT/.flywheel" ]]; then
#     printf '{"check":"flywheel-dir","status":"pass"}\n'
#   else
#     printf '{"check":"flywheel-dir","status":"fail"}\n'
#   fi
```

**Verification probe**:
```
bash tests/scaffold-canonical-cli-bugfix-bundle.sh
```
PASS[2] freshly-scaffolded stubs pass canonical-cli-lint --rule L4.
PASS[2b] exemplar if/then/else/fi pattern visible in stub TODO comments.

### Bug 3 — concurrent .bak collision (52fox)

**Symptom**: backup naming `bak.scaffold-<UTC-second>` collided when
2+ workers scaffolded concurrently. Real incident
2026-05-10T16:03:18-19Z: 8 backups overwritten.

**Fix location**: `.flywheel/scripts/scaffold-canonical-cli.sh:783-791`
```
local _ts_nanosecond _bak_pid _ts_token
_ts_nanosecond="$(date -u +%Y%m%dT%H%M%S%N 2>/dev/null)"
if [[ -z "$_ts_nanosecond" || "$_ts_nanosecond" =~ %N ]]; then
  _ts_nanosecond="$(date -u +%Y%m%dT%H%M%S)$(printf '%09d' "$RANDOM$RANDOM" | tail -c 9)"
fi
_bak_pid="$$"
_ts_token="${_ts_nanosecond}Z-${_bak_pid}"
backup_path="${target_abs}.bak.scaffold-${_ts_token}"
```

**Verification probe**:
```
bash tests/scaffold-canonical-cli-bugfix-bundle.sh
```
PASS[3] both concurrent backups survive (two distinct -<pid> suffixes
under the same UTC second).
PASS[3b] backup name ends with `-<pid>` suffix.

## Sister-bead status

| Bead | Status | Note |
|---|---|---|
| flywheel-x4e3s | CLOSED | Bundle commit `a978da7` |
| flywheel-946sy | CLOSED | Bug 1 + 2 |
| flywheel-52fox | CLOSED | Bug 3 |
| flywheel-gnfi3 | CLOSED | Bug 1 (cross-repo variant) |
| flywheel-dmbqj | this bead | superseded-by-x4e3s |

## Regression coverage (all currently green)

| Test | Result |
|---|---|
| `tests/scaffold-canonical-cli-bugfix-bundle.sh` | 6/6 PASS (5 assertion groups) |
| `tests/scaffold-canonical-cli-e2e.sh` | 20/20 PASS |
| `tests/scaffold-canonical-cli-shebang-guard.sh` | 9/9 PASS |

## Disposition action

`br close flywheel-dmbqj --reason "superseded-by-flywheel-x4e3s commit a978da7; all 3 bugs (946sy + 52fox + gnfi3) already fixed and regression-tested 6/6 + e2e 20/20 + shebang-guard 9/9. See .flywheel/audit/flywheel-dmbqj/apply-spec.md for verification."`

No code changes in this bead. Apply-spec is the artifact.

## Why this happened (root-cause for the duplicate)

Best read: dmbqj was filed before x4e3s closure propagated through
whatever queue the orch was reading. The data-decides discipline
catches it now: at audit time, the regression suite is the source of
truth, not the bead description. If the tests already PASS for the
bug, the bead is shipped regardless of what other beads were filed.

## Future protection

The session-memory rule for the canonical-cli campaign should be:
"Before scaffolding a bug-fix bead, grep regression tests for the
bug ID. If a test passes for the bug, file as `superseded-by-<id>`
not as new work."
