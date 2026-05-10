# Codex #21869 — post-push ref-drift rule (2026-05-10)

**Source**: openai/codex#21869 (filed upstream, 2026-05-09).

## The bug shape

When a Codex CLI session runs with `sandbox = workspace-write`
**and** `network_access = true`, the sandbox can let `git push`
contact the remote and update the remote branch successfully —
and then **fail to update `.git/refs/remotes/origin/<branch>`
locally**. The push exits 0 (or appears to) but the local
remote-tracking ref is silently out-of-sync with what's actually
on the remote.

Effect: any subsequent local logic that compares
`origin/<branch>` SHA against an expected SHA will see the OLD
remote SHA and either re-push (clobbering whatever was just
pushed by another writer), report "branch is behind" wrongly,
or treat a successful push as not-yet-shipped.

## Fleet exposure (as of 2026-05-10)

**Currently zero exposure.** The flywheel fleet's worker lane
runs Codex under `codex --dangerously-bypass-approvals-and-sandbox`
(per `feedback_codex_relaunch_command_canonical`), which is
**full-access mode**, not `workspace-write`. The 21869 bug only
manifests in the `workspace-write + network_access=true` path.

Additional defenses already in place:

1. **No worker-driven `git push` surface exists** in
   `.flywheel/scripts/`. Workers commit locally; Joshua handles
   pushes manually or via `gh pr create` / GitHub Actions.
   Verified by the
   `tests/codex-21869-post-push-ref-drift-guard.sh` regression
   (Test 1).

2. **DCG `core.git` pack** blocks `push --force` (long + short
   forms) at execution time. Standard `git push` is permitted
   but workers don't invoke it.

3. **Memory rules** explicitly forbid pushes to specific repos
   (`feedback_no_push_ntm_br`: "Jeff's repos, changes stay
   local only").

## The rule

**Any future flywheel worker lane that enables Codex
`workspace-write + network_access=true` MUST add a post-push
reconciliation probe before treating `git push` as complete.**

The probe MUST:

1. Capture the remote branch SHA via `git ls-remote
   <remote> <branch>` (this contacts the remote directly,
   bypassing local tracking refs).
2. Compare against the local `HEAD` sha.
3. Compare against the local `refs/remotes/<remote>/<branch>`
   sha.
4. If `ls-remote` agrees with HEAD but the local
   remote-tracking ref disagrees → **explicit
   `git fetch <remote> <branch>` repair before declaring
   success**.
5. Emit a structured receipt (suggested schema:
   `codex-post-push-reconcile/v1` with fields `remote_sha`,
   `local_head_sha`, `local_tracking_sha`, `reconcile_action`,
   `success`).

If the worker lane cannot guarantee `git fetch` after every
push (e.g., sandboxed network access doesn't permit
re-fetching), the lane MUST refuse to use `workspace-write +
network_access=true` for any operation that reads the remote
tracking ref afterward. Use `danger-full-access` (the canonical
flywheel worker mode) instead.

## When this rule fires

This rule is **dormant** while the fleet has zero
workspace-write+network workers. The regression test
(`tests/codex-21869-post-push-ref-drift-guard.sh`) wakes it up
the moment a worker lane introduces such a configuration.

## Evidence

- Upstream issue: `https://github.com/openai/codex/issues/21869`
- Triage: `.flywheel/receipts/flywheel-z6lk3/triage-receipt.md`
  (#21869 row classified `fleet-affecting`, interim workaround
  documented).
- Source bead: `flywheel-ie2en` (this rule).
- Regression: `tests/codex-21869-post-push-ref-drift-guard.sh`.
- Canonical worker mode citation:
  `feedback_codex_relaunch_command_canonical.md` (memory).
- Sandbox detail: `~/.codex/config.toml` (no fleet-wide
  `sandbox = workspace-write` directive).

## Why doctrine, not L-rule

Per the bead's acceptance criteria, the disposition is "an
explicit rule for post-push local ref consistency" — a
DOCTRINE entry (this file) plus a regression test. No new
numbered L-rule is created because:

1. The rule is dormant (no current fleet exposure).
2. L-rule numbering is reserved for canonical, recurring
   behaviors. This rule activates only on a future
   configuration change.
3. The regression test enforces the dormancy invariant; the
   rule itself only kicks in when the test starts failing.
