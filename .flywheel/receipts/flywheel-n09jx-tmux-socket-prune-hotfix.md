# flywheel-n09jx tmux socket prune hotfix receipt

Task: `flywheel-n09jx-f5a22f`
Identity: `CloudyMill`
Date: 2026-05-09

## Summary

`tmp-aggressive-prune.sh` now excludes IPC roots before candidate deletion by:

- explicit IPC names: `tmux-*`, `launchd-*`, `sshd-*`, `com.googlecode.*`
- service-owned UID suffixes: `<service>-<uid>`
- actual socket-bearing directories detected with `find -type s`

The script also accepts `--root PATH` so the destructive path can be exercised
against a synthetic fixture instead of live `/private/tmp`.

## Affected Artifact

- `.flywheel/scripts/tmp-aggressive-prune.sh`
- `tests/test-tmp-aggressive-prune.sh`

## Command Output

```text
$ bash tests/test-tmp-aggressive-prune.sh
PASS script_syntax
PASS dry_run_root_fixture
PASS only_ordinary_old_planned
PASS tmux_socket_dir_protected
PASS apply_deletes_only_unprotected
PASS protected_survives/tmux-501
PASS protected_survives/agentmail-501
PASS protected_survives/generic-socket-dir
PASS protected_survives/launchd-fixture
PASS ordinary_old_removed
PASS tmp_socket_ipc_guard: 10 checks
```

```text
$ .flywheel/scripts/tmp-aggressive-prune.sh --max-mtime-days 1 --dry-run --json
status=ok apply=false root=/private/tmp candidates_count=2 protected_count=18
```

## Residual Risk

No new bead filed. The covered incident class is now blocked by script behavior
and a synthetic fixture. Residual risk is unknown third-party IPC directories
that neither use a service-UID directory name nor contain filesystem-visible
socket nodes; those require a future observed example before adding a broader
rule.

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:9,jeff:9,public:9`

Public lens: a skeptical operator can re-run the fixture, a maintainer can read
the narrow deny-list logic, and a future worker has a live-safe probe command.
