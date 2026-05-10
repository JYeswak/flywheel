# Audit pack: flywheel-t53xc (apply for flywheel-u4fmq)

**Bead:** flywheel-t53xc — [ntm-rebuild-apply] rebuild ntm binary + L87 sunset prep
**Parent:** flywheel-u4fmq (BLOCKED-deferred with 6-phase runbook; simplified to 4-step per Joshua signoff 2026-05-10)
**Spec:** `.flywheel/audit/flywheel-u4fmq/apply-spec.md`
**Worker:** MistyCliff (flywheel:0.4)
**UTC:** 2026-05-10T03:38:48Z
**Disposition:** DONE — all 4 acceptance gates pass; backup retained; one fuckup logged + recovery captured for skill discovery.

## Pre/post snapshot

| Metric | Pre | Post |
|---|---|---|
| `~/.local/bin/ntm` size | 54884370 | 40343840 |
| `~/.local/bin/ntm` mtime | May 7 18:24:48 2026 | May 9 21:38:41 2026 |
| `ntm version` | `dev / commit: none / built: unknown` | `v1.14.0-479-g7d1fc78e / commit: 7d1fc78e... / built: 2026-05-10T03:37:38Z` |
| commit metadata | `commit=none` | `7d1fc78ebf19af12b193c972d25016ec707d8f87` |
| `stale-error-auto-ping` | 7/7 PASS (baseline) | 7/7 PASS (post-swap) |

## Acceptance gates

### AG1 — Build with real commit metadata ✓

```
$ cd ~/Developer/ntm && make build
go build -trimpath -ldflags "-s -w -X .../cli.Version=v1.14.0-479-g7d1fc78e \
  -X .../cli.Commit=7d1fc78ebf19af12b193c972d25016ec707d8f87 \
  -X .../cli.Date=2026-05-10T03:37:38Z \
  -X .../cli.BuiltBy=make" -o ntm ./cmd/ntm

$ ~/Developer/ntm/ntm version
ntm version v1.14.0-479-g7d1fc78e
  commit:    7d1fc78ebf19af12b193c972d25016ec707d8f87
  built:     2026-05-10T03:37:38Z
  builder:   make
  go:        go1.25.6
  platform:  darwin/arm64
```

NOT `commit=none` ✓.

Spec drift note: spec referenced `dist/ntm` but the Makefile's
`-o ntm` writes to `~/Developer/ntm/ntm` (top level). Adapted to
the actual build output path; substantive content unchanged.

### AG2 — Backup + atomic swap; same commit post-swap ✓

```
backup_path=/Users/josh/.local/bin/ntm.bak.20260510T033805Z
backup_size=54884370 bytes
swap_ms=35  (well under spec's 100ms target)
```

**Fuckup logged: darwin/arm64 cp-over-binary breaks code signature.**

After the cp, `~/.local/bin/ntm version` returned exit 137 (SIGKILL)
with empty output despite identical shasum to the source. Cause:
macOS kernel killed the post-cp binary because the ad-hoc signature
became invalid relative to the new inode. Recovery:

```
$ codesign -f -s - /Users/josh/.local/bin/ntm
/Users/josh/.local/bin/ntm: replacing existing signature
$ ~/.local/bin/ntm version
ntm version v1.14.0-479-g7d1fc78e
  commit: 7d1fc78ebf19af12b193c972d25016ec707d8f87
```

Post-recovery commit matches `dist/ntm` (i.e., `~/Developer/ntm/ntm`)
commit ✓.

### AG3 — Regression check 7/7 PASS ✓

```
$ bash /Users/josh/Developer/flywheel/tests/stale-error-auto-ping.sh
PASS script syntax
PASS help exposes surface
PASS version emits v1
PASS info JSON
PASS dry-run finds only live stale-error candidates
PASS apply sends ping and recheck recovers
PASS fake ntm recorded no-cass-check sends
Summary: 7 passed, 0 failed
```

Full output snapshot: `stale-error-auto-ping-post-swap.txt`. No
rollback fired.

### AG4 — Receipt at `.flywheel/audit/flywheel-u4fmq-apply/evidence.md` ✓

This file. Plus regression log at
`stale-error-auto-ping-post-swap.txt`.

## Operation duration

- Pre-flight + AG1 (build): ~30s
- AG2 (backup + cp + codesign + verify): ~10s including the SIGKILL
  diagnosis + re-sign retry
- AG3 (regression): ~5s
- Total wall clock: ~3 minutes including investigation of the
  signature break

## Backup retention

- `/Users/josh/.local/bin/ntm.bak.20260510T033805Z`
- 54884370 bytes
- Rollback recipe: `cp ~/.local/bin/ntm.bak.20260510T033805Z ~/.local/bin/ntm && codesign -f -s - ~/.local/bin/ntm`
  (codesign step required for the same reason the swap needed it).

## Skill discovery: cp-over-running-darwin-arm64-binary breaks signature

This is a reusable pattern worth a skill entry — it will recur every
time anyone atomically swaps a darwin/arm64 binary. Filing as
`skill-discovery/v1` row:

- **kind:** `pattern-emerged`
- **trigger:** `darwin/arm64` + `cp <new> <existing-binary-path>` + binary fails on next exec with exit 137
- **fix:** `codesign -f -s - <path>` immediately after cp
- **why:** the kernel kills binaries with invalidated ad-hoc signatures; cp invalidates the signature on overwrite

This belongs in a future `binary-atomic-swap-darwin` skill or
amendment to existing operational runbooks. The current spec at
`.flywheel/audit/flywheel-u4fmq/apply-spec.md` should be amended (in
a follow-up bead) with a Step 2.5 calling for codesign -f -s - on
the destination after cp.

## Deferred (per spec, not in this bead's scope)

- L87 doctrine flip + binary_commit_pin — `not_before=2026-05-11`
  for 24h burn-in
- README stale-error fallback paragraph cleanup
- Followup bead `flywheel-u4fmq-doctrine` for above

## Files

- `.flywheel/audit/flywheel-u4fmq-apply/evidence.md` (this file)
- `.flywheel/audit/flywheel-u4fmq-apply/stale-error-auto-ping-post-swap.txt`
- `/Users/josh/.local/bin/ntm.bak.20260510T033805Z` (backup, outside repo)

## Four-Lens Self-Grade

- brand: 8 — clean spec adherence; spec drift on dist/ntm path
  reported transparently; signature recovery reported as fuckup not
  hidden.
- sniff: 9 — every claim verifiable; pre/post commit metadata, swap
  duration, and regression results all reproducible; backup +
  rollback recipe shipped.
- jeff: 8 — atomic single-binary swap with stop-on-error discipline,
  codesign recovery is the missing piece in the spec but evidence
  flags it as a future skill.
- public: 8 — three-judges check: skeptical operator can re-run
  `~/.local/bin/ntm version` and confirm commit; maintainer can read
  this evidence and spot the signature pitfall before re-doing the
  apply elsewhere; future worker can use the skill discovery to skip
  the SIGKILL detour.
