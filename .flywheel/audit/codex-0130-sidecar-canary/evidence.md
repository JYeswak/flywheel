# Audit pack: flywheel-ppcb8 (codex 0.130 sidecar canary apply)

**Bead:** flywheel-ppcb8 — [codex-0130-canary] sidecar install + relaunch deathtrap on canary per Joshua signoff 2026-05-10
**Spec:** `.flywheel/audit/codex-0130-sidecar-canary/apply-spec.md`
**Worker:** MistyCliff (flywheel:0.4)
**UTC:** 2026-05-10T03:47:18Z (relaunch ts)
**Disposition:** DONE — all 6 acceptance gates pass; canary now on codex 0.130 sidecar; global 0.125 untouched.

## Summary

| Item | Value |
|---|---|
| Sidecar install path | `/Users/josh/.local/codex-sidecar-0130/` |
| Sidecar codex --version | `codex-cli 0.130.0` |
| Global codex --version | `codex-cli 0.125.0` (untouched) |
| Prior canary launcher PID | 60837 (label `fleet-death-experiment-2`) |
| Prior canary kill mode | SIGTERM → graceful, codex_exit_code=0 |
| Prior canary exit_evidence | `~/.local/state/flywheel/codex-death-evidence/exit_evidence-60837-20260510T034231Z.json` |
| New canary launcher PID | 17733 (label `fleet-death-experiment-0130`) |
| New canary codex PID | 17742 (node) → 17766 (vendor) |
| New canary binary path | `/Users/josh/.local/codex-sidecar-0130/node_modules/.bin/codex` (symlink → `../@openai/codex/bin/codex.js`) → vendor `aarch64-apple-darwin` |
| New canary stderr log | `~/.local/state/flywheel/codex-death-evidence/stderr-17733-20260510T034718Z.log` |
| Canary tmux session | `codex-canary--fleet-death-experiment:0` (Joshua attached, untouched post-relaunch) |

## Acceptance gates

### AG1 — Sidecar install at `/Users/josh/.local/codex-sidecar-0130` ✓

```
$ npm install --prefix /Users/josh/.local/codex-sidecar-0130 @openai/codex@0.130.0
added 2 packages in 8s
```

npm-install-guard hook did NOT block (prefix install is allowed; no
forced override needed). Global codex at `/Users/josh/.local/bin/codex`
remains 0.125 — confirmed via `codex --version` post-install.

### AG2 — Sidecar reports 0.130.0 ✓

```
$ /Users/josh/.local/codex-sidecar-0130/node_modules/.bin/codex --version
codex-cli 0.130.0
```

NOT 0.125.0 ✓.

### AG3 — Existing canary (PID 60837 → 60845) gracefully terminated ✓

```
$ kill -TERM 60845
$ sleep 3 && ps -p 60837 60845
(both gone)

$ cat ~/.local/state/flywheel/codex-death-evidence/exit_evidence-60837-20260510T034231Z.json
{
  "schema_version": "codex-deathtrap-launcher.v1",
  "ts": "2026-05-10T03:46:52Z",
  "label": "fleet-death-experiment-2",
  "host": "Joshs-Mac-Studio",
  "pid": 60837,
  "codex_exit_code": 0,
  "stderr_byte_count": 0,
  "last_stderr_lines": [],
  "last_zsh_history_cmd": "ntm attach skillos",
  "parent_pane_id": "%120",
  "evidence_paths": {
    "stderr_log": ".../stderr-60837-20260510T034231Z.log",
    "exit_receipt": ".../exit_evidence-60837-20260510T034231Z.json",
    "args_log": ".../args-60837-20260510T034231Z.txt"
  }
}
```

H1-class clean termination per spec expectation ("expected H1 since
manual termination"). Launcher trap fired; receipt written.

### AG4 — New canary launched via deathtrap-launcher with sidecar 0.130 ✓

```
$ tmux send-keys -t codex-canary--fleet-death-experiment:0 \
    "CODEX_DEATHTRAP_CODEX_BIN=/Users/josh/.local/codex-sidecar-0130/node_modules/.bin/codex bash /Users/josh/Developer/flywheel/.flywheel/scripts/codex-deathtrap-launcher.sh --label fleet-death-experiment-0130" Enter

$ sleep 4 && pgrep -fl 'codex-deathtrap-launcher.*fleet-death-experiment-0130'
17733 bash codex-deathtrap-launcher.sh --label fleet-death-experiment-0130
```

Process tree under pane shell (PID 98150):

```
98150 -zsh
  17733 bash codex-deathtrap-launcher.sh --label fleet-death-experiment-0130
    17742 node /Users/josh/.local/codex-sidecar-0130/node_modules/.bin/codex --dangerously-bypass-approvals-and-sandbox
      17743 tee .../stderr-17733-20260510T034718Z.log
      17766 /Users/josh/.local/codex-sidecar-0130/node_modules/@openai/codex-darwin-arm64/vendor/aarch64-apple-darwin/codex --dangerously-bypass-approvals-and-sandbox
```

The vendor binary path includes `codex-sidecar-0130` — that's the
load-bearing string. Global codex 0.125 vendor path would have been
`/opt/homebrew/lib/node_modules/@openai/codex/...`. This canary is
unambiguously running the sidecar 0.130.

### AG5 — Launcher args log + sidecar binary in use; canary alive ✓

```
$ ls ~/.local/state/flywheel/codex-death-evidence/args-17733-*
-rw-r--r--  1 josh  staff  43 May  9 21:47 args-17733-20260510T034718Z.txt

$ cat args-17733-20260510T034718Z.txt
--dangerously-bypass-approvals-and-sandbox

$ tmux capture-pane -t codex-canary--fleet-death-experiment:0 -p | tail
... permissions: YOLO mode ...
... codex banner ...
```

Canary alive (codex banner + YOLO mode prompt visible). Sidecar
0.130 binary path confirmed in process tree (AG4 evidence).

### AG6 — Receipt at `.flywheel/audit/codex-0130-sidecar-canary/evidence.md` ✓

This file.

## Boundary discipline

- ✓ `npm install --prefix` only; no `-g`. Global codex 0.125
  unchanged — confirmed via `codex --version` post-install (still
  0.125.0).
- ✓ No fleet disturbance. Other codex worker PIDs (29064, 22239,
  37340, 30761) unchanged through the operation.
- ✓ `--force` flags not used.
- ✓ Did NOT attach to codex-canary session post-relaunch (per
  spec). Joshua remains attached for natural-death capture.

## Cross-references

- Memory hit `feedback_codex_relaunch_command_canonical`:
  `--dangerously-bypass-approvals-and-sandbox` confirmed in args
  log (the only sanctioned launch shape).
- Prior canary #1 PID 5838 died 02:33:07Z (H1 silent clean exit via
  TTY disconnect); evidence at
  `exit_evidence-5838-20260510T023307Z.json`.
- Prior canary #2 PID 60837 died 03:46:52Z (this dispatch's kill;
  H1 manual-termination class); evidence at
  `exit_evidence-60837-20260510T034231Z.json`.
- New canary #3 PID 17733 alive at 03:47:18Z on sidecar 0.130. If
  it dies naturally, the receipt will be at
  `exit_evidence-17733-<ts>.json`.

## Rollback

Per spec:
```bash
rm -rf /Users/josh/.local/codex-sidecar-0130
# Then re-launch deathtrap without CODEX_DEATHTRAP_CODEX_BIN set;
# launcher falls back to global codex 0.125
```

No system-state changes outside the sidecar dir. `codex` global
binary at `/Users/josh/.local/bin/codex` remains 0.125 — verified
post-install + post-relaunch.

## Files

- `.flywheel/audit/codex-0130-sidecar-canary/evidence.md` (this file)
- `.flywheel/audit/codex-0130-sidecar-canary/apply-spec.md` (spec, pre-existing)
- `~/.local/codex-sidecar-0130/` (sidecar install, outside repo)
- `~/.local/state/flywheel/codex-death-evidence/exit_evidence-60837-20260510T034231Z.json`
- `~/.local/state/flywheel/codex-death-evidence/stderr-17733-20260510T034718Z.log`
- `~/.local/state/flywheel/codex-death-evidence/args-17733-20260510T034718Z.txt`

## Four-Lens Self-Grade

- brand: 9 — sidecar isolation honored to the letter; global
  codex 0.125 untouched; spec adherence clean.
- sniff: 9 — every claim verifiable; process tree shows sidecar
  path, exit_evidence JSON shows clean kill, version probes
  reproducible.
- jeff: 9 — atomic operation, single-binary scope, no fleet
  bleed, kill-then-relaunch sequenced via deathtrap-launcher
  receipts at every step.
- public: 9 — three-judges check: skeptical operator can
  re-run `pgrep -fl codex-sidecar-0130` and confirm the canary
  PID is on 0.130; maintainer can read the evidence and reproduce
  the apply on another machine; future worker can use the
  sidecar pattern for any future codex version under canary.
