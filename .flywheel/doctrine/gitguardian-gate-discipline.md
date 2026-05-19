---
title: "GitGuardian Gate Discipline"
type: doctrine
created: 2026-05-19
frontmatter_source: gitguardian-tier-4.5-gate
---

# GitGuardian Gate Discipline

Status: v0.1 gate authored for `flywheel-rlmqw`.
Scope: auto-push canonical substrate Tier 4.5.

## Tier Placement

Tier 4.5 runs after local-act CI and before any remote `git push`.
It is a hard gate: clean scan permits push; detected leaks, missing
credentials, missing `ggshield`, or GitGuardian server errors block push.

Canonical command:

```bash
.flywheel/scripts/gitguardian-pre-push-gate.sh --json
```

For a pre-push hook:

```bash
#!/usr/bin/env bash
exec .flywheel/scripts/gitguardian-pre-push-gate.sh --mode pre-push "$@"
```

The hook-native mode delegates to `ggshield secret scan pre-push`. The
auto-push substrate may call the default mode directly before push; it scans
the commit range from the upstream merge-base to `HEAD`.

## Secret Load Contract

Canonical Infisical handle:

```text
instance: ZestStream Infisical
key: GITGUARDIAN_API_KEY
path: /GITGUARDIAN_API_KEY
loader: cf-secret GITGUARDIAN_API_KEY
preflight: infisical-load --status
```

The gate loads exactly one secret just-in-time into the `ggshield` subprocess
environment. It never enumerates Infisical, never writes the key to disk, never
passes the key in argv, never echoes the key, and unsets the shell variable
after `ggshield` returns.

Missing key is not a warning. If `infisical-load --status`, `cf-secret`, or the
key lookup fails, the gate exits `1` with
`reason=gitguardian_api_key_unavailable`.

## Scanner Contract

The wrapper uses GitGuardian's current CLI shapes:

- `ggshield secret scan commit-range RANGE` for auto-push range scans.
- `ggshield secret scan pre-push` when installed as a git hook.
- `ggshield secret scan changes` or `path` only when explicitly requested.

The wrapper forces JSON output into a temporary file and emits only a sanitized
summary: status, reason, branch, commit range, finding count, and severity.
Matched secret values and raw `ggshield` output are not copied to ledgers or
pane text.

## Leak Ledger

On any finding, append one row to:

```text
.flywheel/runtime/secret-leak-detected.jsonl
```

Required row fields:

- `ts`
- `branch`
- `commit_range`
- `finding_count`
- `severity`
- `scan_mode`

This row is for escalation tailing. It is intentionally value-free.

## Fail-Closed Rule

Secrets-class trauma promotes at N=1. A missing scanner is equivalent to a
failed scanner. A missing API key is equivalent to a failed scanner. A
GitGuardian server error is equivalent to a failed scanner. No auto-push path
may downgrade Tier 4.5 to a silent skip.

## Auto-Push Policy Shape

The codesigned auto-push policy should carry:

```yaml
gates:
  local_act_ci: true
  gitguardian_secret_scan: true
  gitguardian_api_key_source: infisical
  fail_closed_on_missing_key: true
  ggshield_scan_command: "secret scan commit-range <upstream-merge-base>..HEAD"
```
