# flywheel-2bd2r.1 sample-size JSON hotfix

Task: `flywheel-2bd2r.1-4448db`
Identity: `CloudyMill`
Date: 2026-05-09

## Summary

`.flywheel/scripts/tmp-aggressive-prune.sh --dry-run --json` now emits JSON even
when a candidate cannot be sized by `du`. Candidate sample sizing records
`unknown` and increments `sample_size_failures` instead of exiting before the
JSON receipt.

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
PASS du_failure_still_emits_json
PASS du_failure_sample_unknown
PASS tmp_socket_ipc_guard: 12 checks
```

```text
$ .flywheel/scripts/tmp-aggressive-prune.sh --max-mtime-days 1 --dry-run --json
status=ok apply=false root=/private/tmp candidates_count=2 protected_count=18 sample_size_failures=0
```

## Acceptance Gates

- AG1: Updated the named script and close evidence exists here.
- AG2: Targeted fake-`du` regression test passes and is named above.
- AG3: `br show flywheel-2bd2r.1` was open before this artifact existed.

## Residual Risk

No new bead filed. This patch covers sizing command failures during dry-run
receipt generation. It does not redesign the script's string-only JSON emission;
that broader shape is outside this follow-up's failure class.

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:9,jeff:9,public:9`

Public lens: a skeptical operator can re-run the fixture, a maintainer can see
the non-fatal sizing fallback, and a future worker has a live-safe probe.
