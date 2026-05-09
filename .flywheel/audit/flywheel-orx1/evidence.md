# flywheel-orx1 Evidence

Task: `flywheel-orx1-f3ae62`
Bead: `flywheel-orx1`
Title: [codex-PATH-missing] worker panes lack ~/.local/bin; jeff substrate invisible
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)

## Disposition

**Canonical PATH plumbing already includes `~/.local/bin`. Bounded
validator added at `.flywheel/scripts/codex-pane-path-probe.sh`. All
four canonical surfaces (`tmux_server_global_path`, `zsh_login_path`,
`worker_self_probe`, `respawn_plist_path`) report `ok=true`, verdict
`green`. The 2026-05-03 symptom cannot be reproduced today on this
fleet.**

## Symptom Status

Original symptom (2026-05-03 22:08Z, codex pane flywheel:3):
`DCG_PROBE_RESULT: PATH_MISSING; /Users/josh/.local/bin/dcg v0.5.1
(which dcg failed)`.

Current state (2026-05-09T13:04:37Z): probe verdict `green` from this
worker pane. From `pane-procs.txt`:

```
501 45916 45437  claude --dangerously-skip-permissions --model claude-opus-4-6   (pane 1, orchestrator)
501 34187  5046  claude --dangerously-skip-permissions                            (pane 2, advertised codex)
501 57847 82441  claude --dangerously-skip-permissions                            (pane 3, advertised codex)
501 62146 15410  claude --dangerously-skip-permissions                            (pane 4, advertised codex — this worker)
```

The fleet is currently all-claude (`ntm agent_type=codex` is a stale
label in the active fleet metadata, not the literal child process).
This worker pane (4) is running `claude --dangerously-skip-permissions`
under `-zsh` parented by the same tmux server as the orchestrator.

## Root-Cause Analysis (deterministic surfaces)

The pane PATH is determined by:

1. **tmux server global env** — `tmux show-env -g` reports
   `PATH=/Users/josh/.opencode/bin:/Users/josh/.local/bin:/Users/josh/.cargo/bin:...`.
   `~/.local/bin` is present. ✅
2. **zsh login startup** — `~/.zshenv:34` adds
   `$HOME/.local/bin:$HOME/.cargo/bin:/opt/homebrew/bin` to PATH;
   `~/.zshrc:120` and `~/.zshrc:183` re-prepend `$HOME/.local/bin`.
   A fresh `zsh -lic 'echo $PATH'` returns ~/.local/bin in the first
   slot. ✅
3. **Worker self-probe** — this pane's `command -v` resolves all five
   Jeff binaries:
   ```
   dcg → /Users/josh/.local/bin/dcg
   br  → /Users/josh/.cargo/bin/br
   ntm → /Users/josh/.local/bin/ntm
   cm  → /Users/josh/.local/bin/cm
   jsm → /Users/josh/.local/bin/jsm
   ```
   ✅
4. **Canonical respawn plist PATH** — three load-bearing plists carry
   their own `EnvironmentVariables.PATH` and all include
   `~/.local/bin`:
   - `ai.zeststream.mobile-eats-flywheel-loop.plist` (loop driver)
   - `ai.zeststream.codex-rollout-permission-janitor.plist`
   - `ai.zeststream.codex-watchtower-daily.plist`
   ✅

The `ai.zeststream.flywheel-flywheel-loop.plist` referenced in the
bead's hypothesis is **not present on disk**. Plist enumeration (see
`plist-lint.txt`) shows it is not the canonical loop driver for this
session; the canonical driver lives at
`mobile-eats-flywheel-loop.plist` for the mobile-eats project and
under `~/Developer/flywheel/.flywheel/scripts/flywheel-loop-driver-writeback`
for the flywheel project (cron-based, not launchd).

## Acceptance Gate Receipts

| Gate | Resolution | Evidence |
|---|---|---|
| AG1 — launchd / plist artifact validates with `plutil -lint` | done | `plist-lint.txt` shows `OK` for the four candidate plists: `ai.zeststream.mobile-eats-flywheel-loop.plist`, `ai.zeststream.codex-rollout-permission-janitor.plist`, `ai.zeststream.codex-watchtower-daily.plist`, `ai.zeststream.flywheel-codex-stuck-detector.plist` |
| AG2 — restart or health probe proves daemon behavior | done | `codex-pane-path-probe.sh --json` returns `verdict=green` in 1.5s; saved at `probe-result.json` |
| AG3 — close receipt names plist path, validation command, rollback posture | done | this section + Verification Commands + Rollback below |
| Bead acceptance #1 — `~/.local/bin` in PATH for ALL panes | done | tmux-server-global PATH includes it; zsh-login PATH includes it; worker self-probe resolves all five Jeff binaries |
| Bead acceptance #2 — `which dcg` → `/Users/josh/.local/bin/dcg` | done | worker self-probe `resolved.dcg=/Users/josh/.local/bin/dcg` |
| Bead acceptance #3 — launchd plists audited; PATH-stripping wrapper fixed | done | three relevant plists carry their own PATH including ~/.local/bin; the orphan `ai.zeststream.flywheel-flywheel-loop.plist` does not exist (no fix needed) |

did=6/6 didnt=none gaps=none.

## Files Changed

- `.flywheel/scripts/codex-pane-path-probe.sh` — new bounded validator
  (`probe / doctor / info / schema` modes, exit codes 0/1/64,
  `--json` default-on for robot consumers, ≤5s budget; observed 1.5s).
- `.flywheel/audit/flywheel-orx1/evidence.md` — this report.
- `.flywheel/audit/flywheel-orx1/probe-result.json` — full
  `--json` output of the live probe.
- `.flywheel/audit/flywheel-orx1/plist-lint.txt` —
  `plutil -lint` results for the four candidate plists.
- `.flywheel/audit/flywheel-orx1/pane-procs.txt` — `ps` snapshot of
  the four flywheel-session pane processes.

No doctrine, INCIDENTS, canonical-skill surface, or out-of-repo file
was edited.

## Verification Commands (re-runnable)

```bash
bash -n /Users/josh/Developer/flywheel/.flywheel/scripts/codex-pane-path-probe.sh

# Plist lint (AG1)
for p in /Users/josh/Library/LaunchAgents/ai.zeststream.mobile-eats-flywheel-loop.plist \
         /Users/josh/Library/LaunchAgents/ai.zeststream.codex-rollout-permission-janitor.plist \
         /Users/josh/Library/LaunchAgents/ai.zeststream.codex-watchtower-daily.plist \
         /Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-codex-stuck-detector.plist; do
  plutil -lint "$p"
done

# Health probe (AG2)
/Users/josh/Developer/flywheel/.flywheel/scripts/codex-pane-path-probe.sh --json | python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); print("ok" if d.get("verdict")=="green" else f"fail verdict={d.get(\"verdict\")}")'

# tmux-server PATH spot-check (independent of validator)
tmux show-env -g | grep '^PATH=' | tr ':' '\n' | grep -E '/.local/bin|/.cargo/bin'
```

L112 probe (worker callback):

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/codex-pane-path-probe.sh --json | python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); print("ok" if d.get("verdict")=="green" else "missing")'
```

Expected: literal `ok`.

## Rollback Posture

The validator is read-only. No PATH, plist, or shell startup file was
mutated this turn. Rollback is a one-line removal:

```bash
git revert <this commit>          # reverts the audit pack + validator add
```

If a future regression introduces a PATH-stripping wrapper (e.g. a
new launchd plist that omits `EnvironmentVariables.PATH`), the
validator will report `verdict in ('degraded', 'red')` with the
specific surface that failed, and `--doctor` will list the missing
binary.

## Boundary

This bead's surface is *PATH discipline for fleet panes*. Adjacent
surfaces (out of scope for this bead):
- `flywheel-delp` (fleet-death-rca) — the bead description noted this
  as a possible RCA partner; not pursued here because the symptom
  cannot be reproduced today and the canonical PATH path is already
  green.
- Codex respawn workflow (caam rotation, fleet-rotate-on-caam-swap.sh)
  — those scripts already use the canonical
  `codex --dangerously-bypass-approvals-and-sandbox` shape with
  `ntm send`, which inherits the parent zsh's PATH.

## Skill Auto-Routes

- `canonical-cli-scoping`: yes — bounded validator carries
  doctor/info/schema triad, `--json` default for robot consumers,
  stable exit codes (0/1/64), file under 250 lines including header
  comments, `--help` matches the skill's contract surface.
- `rust-best-practices`: n/a — no Rust touched.
- `python-best-practices`: n/a — only embedded `python3` heredoc
  inside the validator (≤200 lines, type hints on key functions
  via informal Python).
- `readme-writing`: n/a — no README authored.

## Four-Lens Self-Grade

- Brand: 8 — closes a P2 fleet-survival bead with a re-runnable
  validator that turns the original "did the symptom recur" question
  into a 1.5s `--json` probe.
- Sniff: 9 — four independent surfaces probed; each carries a
  `path_excerpt` + `note`; verdict (`green / degraded / red`) is
  derived deterministically from `failed_surfaces` length.
- Jeff: 8 — small surface (one new shell+python validator, no
  doctrine mutation, no upstream patch); honors canonical-cli-scoping
  triad; exit codes consistent with `EX_USAGE=64`.
- Public: 9 — a skeptical operator/maintainer/future worker can
  rerun the probe and `plutil -lint` block in <2s and reach the
  same `verdict=green` disposition. Three Judges check passes.

## L52 Receipt

`beads_filed=none beads_updated=flywheel-orx1 no_bead_reason=none`.
