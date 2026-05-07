# USE-Row Callsite Verification - flywheel-7p45b

Generated: 2026-05-07

Project: `/Users/josh/Developer/flywheel`

Source inventory: `.flywheel/NTM-SURFACE-INVENTORY.md`

Earlier audit: `.flywheel/plans/ntm-surface-wire-in-USE-ISSUE-WRAP-2026-05-07/06-GAP-AUDIT-SPREADSHEET.md`

Measurement artifacts: `/tmp/flywheel-7p45b-use-row-measurements-final.json` and `/tmp/flywheel-7p45b-use-row-measurements.json`

## Section 1 - Headline numbers

- Total USE rows verified: 86
- VERIFIED-USE count: 24
- LATENT-USE count: 12
- CLAIMED-USE-NOT-WIRED count: 50
- Unique callsites measured: 255
- Literal `ntm <surface>` callsites measured: 213
- Socraticode searches run: 860 (86 surfaces * 10 K-search variants)
- Script/test files scanned: 660

Normalization note: the expanded 06 audit table contains 108 live NTM surfaces and 95 rows originally labeled USE because the spreadsheet embeds WRAP-territory and one `scrub` ISSUE/WRAP-pending row inside the USE label. To match the inventory target of 86 direct USE rows, this audit excluded the spreadsheet's eight named WRAP-territory subset (`approve`, `audit`, `checkpoint`, `metrics`, `policy`, `preflight`, `quota`, `serve`) plus `scrub`, which is already tracked by the redact/scrub follow-up. Broader post-audit wrapper candidates such as `rollback`, `rotate`, and `safety` are still measured here because they remain original USE rows with actual native callsites.

Classification rule: VERIFIED-USE means at least 3 executable/script/test callsites. LATENT-USE means 1-2 callsites. CLAIMED-USE-NOT-WIRED means 0 executable/script/test callsites. Markdown, JSONL, DB files, backups, and tmp/old files were excluded from pass/fail classification; they remain in the raw all-text artifact for auditability.

## Section 2 - Per-row verification table

| # | NTM surface | Callsites | Class | Top callsite | Action |
|---|---|---:|---|---|---|
| 1 | `activity` | 20 | VERIFIED-USE | `.flywheel/scripts/fleet-coherence-scan.sh:15` | keep; add to validation matrix |
| 3 | `adopt` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm adopt` or reclassify no-fit |
| 4 | `agents` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm agents` or reclassify no-fit |
| 5 | `analytics` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm analytics` or reclassify no-fit |
| 7 | `assign` | 6 | VERIFIED-USE | `.flywheel/scripts/dispatch-and-log.sh:81` | keep; add to validation matrix |
| 8 | `attach` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm attach` or reclassify no-fit |
| 11 | `bind` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm bind` or reclassify no-fit |
| 12 | `bugs` | 1 | LATENT-USE | `.claude/skills/.flywheel/bin/flywheel:204` | monitor; add focused regression probe |
| 13 | `cass` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm cass` or reclassify no-fit |
| 14 | `changes` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm changes` or reclassify no-fit |
| 16 | `cleanup` | 8 | VERIFIED-USE | `.flywheel/scripts/private-tmp-prune.sh:20` | keep; add to validation matrix |
| 17 | `completion` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm completion` or reclassify no-fit |
| 18 | `config` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm config` or reclassify no-fit |
| 19 | `conflicts` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm conflicts` or reclassify no-fit |
| 20 | `context` | 3 | VERIFIED-USE | `.flywheel/scripts/build-dispatch-packet.sh:43` | keep; add to validation matrix |
| 21 | `controller` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm controller` or reclassify no-fit |
| 22 | `coordinator` | 14 | VERIFIED-USE | `.flywheel/scripts/ntm-coordinator-shadow.sh:8` | keep; add to validation matrix |
| 23 | `copy` | 2 | LATENT-USE | `tests/unit/test_oom_killed_detector.bats:48` | monitor; add focused regression probe |
| 24 | `create` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm create` or reclassify no-fit |
| 25 | `dashboard` | 1 | LATENT-USE | `tests/test_apply_tmux_tuning.sh:68` | monitor; add focused regression probe |
| 26 | `deps` | 1 | LATENT-USE | `.flywheel/scripts/flywheel-onboard.sh:216` | monitor; add focused regression probe |
| 27 | `diff` | 2 | LATENT-USE | `.flywheel/scripts/recency-weighted-two-truth-classifier.sh:12` | monitor; add focused regression probe |
| 28 | `doctor` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm doctor` or reclassify no-fit |
| 29 | `ensemble` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm ensemble` or reclassify no-fit |
| 30 | `errors` | 11 | VERIFIED-USE | `.flywheel/scripts/codex-template-stuck-detector.sh:17` | keep; add to validation matrix |
| 31 | `extract` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm extract` or reclassify no-fit |
| 32 | `get-all-session-text` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm get-all-session-text` or reclassify no-fit |
| 33 | `git` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm git` or reclassify no-fit |
| 34 | `grep` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm grep` or reclassify no-fit |
| 35 | `guards` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm guards` or reclassify no-fit |
| 36 | `handoff` | 2 | LATENT-USE | `tests/jeff-issue.sh:60` | monitor; add focused regression probe |
| 37 | `health` | 19 | VERIFIED-USE | `.flywheel/scripts/team-pulse-heartbeat.sh:82` | keep; add to validation matrix |
| 39 | `history` | 6 | VERIFIED-USE | `.flywheel/scripts/dispatch-and-log.sh:90` | keep; add to validation matrix |
| 40 | `hooks` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm hooks` or reclassify no-fit |
| 41 | `init` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm init` or reclassify no-fit |
| 42 | `interrupt` | 3 | VERIFIED-USE | `.flywheel/scripts/recovery-escape-then-reprompt.sh:18` | keep; add to validation matrix |
| 43 | `kernel` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm kernel` or reclassify no-fit |
| 44 | `kill` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm kill` or reclassify no-fit |
| 45 | `level` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm level` or reclassify no-fit |
| 46 | `list` | 11 | VERIFIED-USE | `.flywheel/scripts/fleet-coherence-scan.sh:15` | keep; add to validation matrix |
| 49 | `logs` | 1 | LATENT-USE | `.claude/skills/.flywheel/scripts/kill-recover-drill.sh:750` | monitor; add focused regression probe |
| 50 | `mail` | 4 | VERIFIED-USE | `.flywheel/scripts/agent-mail-send-redacted.sh:51` | keep; add to validation matrix |
| 51 | `memory` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm memory` or reclassify no-fit |
| 52 | `message` | 2 | LATENT-USE | `.flywheel/scripts/build-dispatch-packet.sh:135` | monitor; add focused regression probe |
| 54 | `models` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm models` or reclassify no-fit |
| 55 | `modes` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm modes` or reclassify no-fit |
| 56 | `openapi` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm openapi` or reclassify no-fit |
| 57 | `overlay` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm overlay` or reclassify no-fit |
| 58 | `palette` | 1 | LATENT-USE | `tests/test_apply_tmux_tuning.sh:66` | monitor; add focused regression probe |
| 59 | `personas` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm personas` or reclassify no-fit |
| 60 | `profiles` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm profiles` or reclassify no-fit |
| 61 | `pipeline` | 1 | LATENT-USE | `.flywheel/scripts/ntm-pipeline-shadow.sh:8` | monitor; add focused regression probe |
| 62 | `plugins` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm plugins` or reclassify no-fit |
| 65 | `profile` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm profile` or reclassify no-fit |
| 66 | `quick` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm quick` or reclassify no-fit |
| 68 | `rebalance` | 3 | VERIFIED-USE | `.flywheel/scripts/peer-orch-blocker-watch.sh:13` | keep; add to validation matrix |
| 69 | `recipes` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm recipes` or reclassify no-fit |
| 71 | `replay` | 3 | VERIFIED-USE | `.flywheel/scripts/recovery-escape-then-reprompt.sh:18` | keep; add to validation matrix |
| 72 | `repo` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm repo` or reclassify no-fit |
| 73 | `respawn` | 26 | VERIFIED-USE | `.flywheel/scripts/dispatch-and-verify.sh:90` | keep; add to validation matrix |
| 74 | `resume` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm resume` or reclassify no-fit |
| 76 | `rollback` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm rollback` or reclassify no-fit |
| 77 | `rotate` | 10 | VERIFIED-USE | `.flywheel/scripts/caam-auto-rotate-on-usage-limit.sh:31` | keep; add to validation matrix |
| 78 | `safety` | 1 | LATENT-USE | `.flywheel/scripts/ntm-safety-dcg-sibling.sh:5` | monitor; add focused regression probe |
| 79 | `save` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm save` or reclassify no-fit |
| 80 | `scale` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm scale` or reclassify no-fit |
| 81 | `scan` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm scan` or reclassify no-fit |
| 83 | `search` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm search` or reclassify no-fit |
| 84 | `send` | 48 | VERIFIED-USE | `.flywheel/scripts/build-dispatch-packet.sh:132` | keep; add to validation matrix |
| 86 | `session-templates` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm session-templates` or reclassify no-fit |
| 87 | `sessions` | 7 | VERIFIED-USE | `.flywheel/scripts/fleet-coherence-scan.sh:16` | keep; add to validation matrix |
| 88 | `setup` | 2 | LATENT-USE | `.flywheel/scripts/flywheel-onboard.sh:16` | monitor; add focused regression probe |
| 89 | `shell` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm shell` or reclassify no-fit |
| 90 | `spawn` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm spawn` or reclassify no-fit |
| 91 | `status` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm status` or reclassify no-fit |
| 92 | `summary` | 5 | VERIFIED-USE | `.flywheel/scripts/team-pulse-heartbeat.sh:82` | keep; add to validation matrix |
| 93 | `support-bundle` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm support-bundle` or reclassify no-fit |
| 94 | `swarm` | 4 | VERIFIED-USE | `.flywheel/scripts/peer-orch-blocker-watch.sh:13` | keep; add to validation matrix |
| 95 | `template` | 3 | VERIFIED-USE | `.flywheel/scripts/build-dispatch-packet.sh:43` | keep; add to validation matrix |
| 96 | `timeline` | 3 | VERIFIED-USE | `.flywheel/scripts/dispatch-log-fitness-invariant.sh:17` | keep; add to validation matrix |
| 99 | `upgrade` | 3 | VERIFIED-USE | `.flywheel/scripts/jeff-binary-version-watchtower.sh:60` | keep; add to validation matrix |
| 100 | `version` | 4 | VERIFIED-USE | `.flywheel/scripts/jeff-binary-version-watchtower.sh:60` | keep; add to validation matrix |
| 101 | `view` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm view` or reclassify no-fit |
| 102 | `wait` | 14 | VERIFIED-USE | `.flywheel/scripts/worker-stall-alert-probe.sh:27` | keep; add to validation matrix |
| 103 | `watch` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm watch` or reclassify no-fit |
| 105 | `workflows` | 0 | CLAIMED-USE-NOT-WIRED | `-` | file bead: wire `ntm workflows` or reclassify no-fit |

## Section 3 - CLAIMED-USE-NOT-WIRED rows and proposed beads

50 rows have zero executable/script/test callsites. These are not verified USE rows yet; they are inventory claims awaiting either real wire-in or explicit reclassification.

- `adopt` (row 3): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `adopt`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `agents` (row 4): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `agents`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `analytics` (row 5): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `analytics`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `attach` (row 8): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `attach`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `bind` (row 11): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `bind`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `cass` (row 13): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `cass`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `changes` (row 14): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `changes`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `completion` (row 17): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `completion`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `config` (row 18): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `config`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `conflicts` (row 19): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `conflicts`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `controller` (row 21): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `controller`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `create` (row 24): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `create`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `doctor` (row 28): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `doctor`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `ensemble` (row 29): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `ensemble`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `extract` (row 31): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `extract`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `get-all-session-text` (row 32): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `get-all-session-text`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `git` (row 33): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `git`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `grep` (row 34): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `grep`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `guards` (row 35): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `guards`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `hooks` (row 40): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `hooks`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `init` (row 41): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `init`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `kernel` (row 43): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `kernel`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `kill` (row 44): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `kill`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `level` (row 45): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `level`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `memory` (row 51): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `memory`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `models` (row 54): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `models`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `modes` (row 55): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `modes`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `openapi` (row 56): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `openapi`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `overlay` (row 57): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `overlay`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `personas` (row 59): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `personas`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `profiles` (row 60): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `profiles`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `plugins` (row 62): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `plugins`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `profile` (row 65): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `profile`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `quick` (row 66): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `quick`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `recipes` (row 69): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `recipes`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `repo` (row 72): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `repo`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `resume` (row 74): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `resume`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `rollback` (row 76): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `rollback`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `save` (row 79): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `save`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `scale` (row 80): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `scale`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `scan` (row 81): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `scan`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `search` (row 83): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `search`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `session-templates` (row 86): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `session-templates`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `shell` (row 89): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `shell`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `spawn` (row 90): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `spawn`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `status` (row 91): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `status`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `support-bundle` (row 93): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `support-bundle`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `view` (row 101): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `view`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `watch` (row 103): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `watch`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.
- `workflows` (row 105): classification is aspirational under current callsite evidence. Proposed bead: [ntm-use-verify] wire or reclassify `workflows`; priority P1 for operational primitives (`doctor`, `grep`, `watch`, `spawn`, `status`), otherwise P2; expected output: one focused script/doctor/test callsite or an explicit no-fit receipt.

## Section 4 - LATENT-USE rows and monitoring notes

- `bugs` (row 12): 1 callsite(s), top `.claude/skills/.flywheel/bin/flywheel:204`. wired-but-thin; one narrow flow references it, but no broad regression matrix protects the surface yet. Action: add a focused validation probe before treating this as durable fleet-wide wiring.
- `copy` (row 23): 2 callsite(s), top `tests/unit/test_oom_killed_detector.bats:48`. wired-but-thin; one narrow flow references it, but no broad regression matrix protects the surface yet. Action: add a focused validation probe before treating this as durable fleet-wide wiring.
- `dashboard` (row 25): 1 callsite(s), top `tests/test_apply_tmux_tuning.sh:68`. wired-but-thin; one narrow flow references it, but no broad regression matrix protects the surface yet. Action: add a focused validation probe before treating this as durable fleet-wide wiring.
- `deps` (row 26): 1 callsite(s), top `.flywheel/scripts/flywheel-onboard.sh:216`. wired-but-thin; one narrow flow references it, but no broad regression matrix protects the surface yet. Action: add a focused validation probe before treating this as durable fleet-wide wiring.
- `diff` (row 27): 2 callsite(s), top `.flywheel/scripts/recency-weighted-two-truth-classifier.sh:12`. wired-but-thin; one narrow flow references it, but no broad regression matrix protects the surface yet. Action: add a focused validation probe before treating this as durable fleet-wide wiring.
- `handoff` (row 36): 2 callsite(s), top `tests/jeff-issue.sh:60`. wired-but-thin; one narrow flow references it, but no broad regression matrix protects the surface yet. Action: add a focused validation probe before treating this as durable fleet-wide wiring.
- `logs` (row 49): 1 callsite(s), top `.claude/skills/.flywheel/scripts/kill-recover-drill.sh:750`. wired-but-thin; one narrow flow references it, but no broad regression matrix protects the surface yet. Action: add a focused validation probe before treating this as durable fleet-wide wiring.
- `message` (row 52): 2 callsite(s), top `.flywheel/scripts/build-dispatch-packet.sh:135`. wired-but-thin; one narrow flow references it, but no broad regression matrix protects the surface yet. Action: add a focused validation probe before treating this as durable fleet-wide wiring.
- `palette` (row 58): 1 callsite(s), top `tests/test_apply_tmux_tuning.sh:66`. wired-but-thin; one narrow flow references it, but no broad regression matrix protects the surface yet. Action: add a focused validation probe before treating this as durable fleet-wide wiring.
- `pipeline` (row 61): 1 callsite(s), top `.flywheel/scripts/ntm-pipeline-shadow.sh:8`. wired-but-thin; one narrow flow references it, but no broad regression matrix protects the surface yet. Action: add a focused validation probe before treating this as durable fleet-wide wiring.
- `safety` (row 78): 1 callsite(s), top `.flywheel/scripts/ntm-safety-dcg-sibling.sh:5`. wired-but-thin; one narrow flow references it, but no broad regression matrix protects the surface yet. Action: add a focused validation probe before treating this as durable fleet-wide wiring.
- `setup` (row 88): 2 callsite(s), top `.flywheel/scripts/flywheel-onboard.sh:16`. wired-but-thin; one narrow flow references it, but no broad regression matrix protects the surface yet. Action: add a focused validation probe before treating this as durable fleet-wide wiring.

## Section 5 - VERIFIED-USE summary

- `activity` (row 1): 20 callsites; top evidence `.flywheel/scripts/fleet-coherence-scan.sh:15`, `.flywheel/scripts/fleet-coherence-scan.sh:16`, `.flywheel/scripts/codex-template-stuck-detector.sh:17`.
- `assign` (row 7): 6 callsites; top evidence `.flywheel/scripts/dispatch-and-log.sh:81`, `.flywheel/scripts/dispatch-and-log.sh:83`, `.flywheel/scripts/ntm-coordinator-shadow.sh:29`.
- `cleanup` (row 16): 8 callsites; top evidence `.flywheel/scripts/private-tmp-prune.sh:20`, `.flywheel/scripts/private-tmp-prune.sh:45`, `.flywheel/scripts/private-tmp-prune.sh:82`.
- `context` (row 20): 3 callsites; top evidence `.flywheel/scripts/build-dispatch-packet.sh:43`, `.flywheel/scripts/build-dispatch-packet.sh:102`, `.flywheel/scripts/build-dispatch-packet.sh:103`.
- `coordinator` (row 22): 14 callsites; top evidence `.flywheel/scripts/ntm-coordinator-shadow.sh:8`, `tests/test_ntm_coordinator_wire.sh:7`, `tests/test_ntm_coordinator_wire.sh:46`.
- `errors` (row 30): 11 callsites; top evidence `.flywheel/scripts/codex-template-stuck-detector.sh:17`, `.flywheel/scripts/frozen-pane-detector.sh:30`, `.flywheel/scripts/frozen-pane-detector.sh:31`.
- `health` (row 37): 19 callsites; top evidence `.flywheel/scripts/team-pulse-heartbeat.sh:82`, `.flywheel/scripts/fleet-coherence-scan.sh:15`, `.flywheel/scripts/fleet-coherence-scan.sh:16`.
- `history` (row 39): 6 callsites; top evidence `.flywheel/scripts/dispatch-and-log.sh:90`, `.flywheel/scripts/dispatch-delivery-verify.sh:12`, `.flywheel/scripts/dispatch-delivery-verify.sh:19`.
- `interrupt` (row 42): 3 callsites; top evidence `.flywheel/scripts/recovery-escape-then-reprompt.sh:18`, `.flywheel/scripts/recovery-escape-then-reprompt.sh:28`, `.flywheel/scripts/recovery-escape-then-reprompt.sh:29`.
- `list` (row 46): 11 callsites; top evidence `.flywheel/scripts/fleet-coherence-scan.sh:15`, `.flywheel/scripts/fleet-coherence-scan.sh:30`, `.flywheel/scripts/fleet-rotate-all-sessions.sh:84`.
- `mail` (row 50): 4 callsites; top evidence `.flywheel/scripts/agent-mail-send-redacted.sh:51`, `.flywheel/scripts/agent-mail-send-redacted.sh:52`, `.flywheel/scripts/agent-mail-send-redacted.sh:53`.
- `rebalance` (row 68): 3 callsites; top evidence `.flywheel/scripts/peer-orch-blocker-watch.sh:13`, `.flywheel/scripts/peer-orch-blocker-watch.sh:18`, `.flywheel/scripts/peer-orch-blocker-watch.sh:38`.
- `replay` (row 71): 3 callsites; top evidence `.flywheel/scripts/recovery-escape-then-reprompt.sh:18`, `.flywheel/scripts/recovery-escape-then-reprompt.sh:28`, `.flywheel/scripts/recovery-escape-then-reprompt.sh:29`.
- `respawn` (row 73): 26 callsites; top evidence `.flywheel/scripts/dispatch-and-verify.sh:90`, `.flywheel/scripts/peer-orch-freeze-monitor.sh:313`, `.flywheel/scripts/fleet-rotate-on-caam-swap.sh:8`.
- `rotate` (row 77): 10 callsites; top evidence `.flywheel/scripts/caam-auto-rotate-on-usage-limit.sh:31`, `.flywheel/scripts/caam-auto-rotate-on-usage-limit.sh:81`, `.flywheel/scripts/caam-auto-rotate-on-usage-limit.sh:93`.
- `send` (row 84): 48 callsites; top evidence `.flywheel/scripts/build-dispatch-packet.sh:132`, `.flywheel/scripts/build-dispatch-packet.sh:138`, `.flywheel/scripts/test-loop-driver-doctor.sh:67`.
- `sessions` (row 87): 7 callsites; top evidence `.flywheel/scripts/fleet-coherence-scan.sh:16`, `.flywheel/scripts/fleet-coherence-scan.sh:30`, `.flywheel/scripts/fleet-rotate-all-sessions.sh:4`.
- `summary` (row 92): 5 callsites; top evidence `.flywheel/scripts/team-pulse-heartbeat.sh:82`, `.flywheel/scripts/leverage-ceiling-probe.sh:22`, `.flywheel/scripts/leverage-ceiling-probe.sh:75`.
- `swarm` (row 94): 4 callsites; top evidence `.flywheel/scripts/peer-orch-blocker-watch.sh:13`, `.flywheel/scripts/peer-orch-blocker-watch.sh:18`, `.flywheel/scripts/peer-orch-blocker-watch.sh:37`.
- `template` (row 95): 3 callsites; top evidence `.flywheel/scripts/build-dispatch-packet.sh:43`, `.flywheel/scripts/build-dispatch-packet.sh:104`, `.flywheel/scripts/build-dispatch-packet.sh:105`.
- `timeline` (row 96): 3 callsites; top evidence `.flywheel/scripts/dispatch-log-fitness-invariant.sh:17`, `.flywheel/scripts/dispatch-log-fitness-invariant.sh:27`, `.flywheel/scripts/dispatch-log-fitness-invariant.sh:75`.
- `upgrade` (row 99): 3 callsites; top evidence `.flywheel/scripts/jeff-binary-version-watchtower.sh:60`, `.flywheel/scripts/jeff-binary-version-watchtower.sh:83`, `.flywheel/scripts/jeff-binary-version-watchtower.sh:100`.
- `version` (row 100): 4 callsites; top evidence `.flywheel/scripts/jeff-binary-version-watchtower.sh:60`, `.flywheel/scripts/jeff-binary-version-watchtower.sh:83`, `tests/jeff-binary-version-watchtower.sh:28`.
- `wait` (row 102): 14 callsites; top evidence `.flywheel/scripts/worker-stall-alert-probe.sh:27`, `.flywheel/scripts/worker-stall-alert-probe.sh:36`, `.flywheel/scripts/worker-stall-alert-probe.sh:43`.

## Section 6 - NTM-SURFACE-INVENTORY.md update proposal

No inventory patch was applied in this bead. The dispatch was audit-only. Proposed schema addition:

```diff
-| # | NTM surface | What it does | Decision | Action |
-|---|---|---|---|---|
+| # | NTM surface | What it does | Decision | Verification status | Callsites | Action |
+|---|---|---|---|---|---:|---|
+| 1 | `activity` | Show agent activity states | **USE** | VERIFIED-USE | 20 | Already canonical; keep in validation matrix. |
+| 3 | `adopt` | Adopt external tmux session | **USE** | CLAIMED-USE-NOT-WIRED | 0 | File bead to wire onboarding callsite or reclassify no-fit. |
+| 12 | `bugs` | View + manage UBS findings | **USE** | LATENT-USE | 1 | Add focused regression probe before claiming durable wiring. |
```

Recommended inventory invariant: every direct USE row must have `Verification status`, `Callsited by`, and `Regression probe` columns. Future PASS criteria should be `VERIFIED-USE` plus at least one test/doctor probe, not callsite count alone.
