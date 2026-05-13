# Public Release Runbook

This runbook is the command contract for a public Flywheel v0.2 evaluator. It
separates the required reduced-mode path from full substrate paths that depend
on local tools, accounts, and harnesses.

Use it when you need exact commands, expected output keys, failure branches, and
receipt locations.

## Support Tiers

| Path | Public status | What it proves |
|---|---|---|
| Reduced local mode | Required public path | Flywheel can initialize repo-local state, run doctor and tick, simulate dispatch, validate closeout, and show next action without private fleet substrate. |
| Full local substrate | Supported when installed | Flywheel can detect and use Beads, Agent Mail, NTM, Socraticode, DCG, and related substrate without silently assuming they exist. |
| Claude Code | Compatibility target | Registry-valid until a `flywheel.agent_lane_runtime_receipt.v0` receipt proves the isolated journey and private-state scan. |
| Codex CLI | Compatibility target | Registry-valid until a `flywheel.agent_lane_runtime_receipt.v0` receipt proves the isolated journey and private-state scan. |
| Gemini CLI | Compatibility target | Registry-valid until a `flywheel.agent_lane_runtime_receipt.v0` receipt proves the isolated journey and private-state scan. |
| OpenClaw | Compatibility target | Registry-valid until a `flywheel.agent_lane_runtime_receipt.v0` receipt proves the isolated journey and private-state scan. |

Do not upgrade a compatibility target to supported copy from docs alone. The
source of truth is `scripts/journey-smoke.sh`.
Use `scripts/agent-lane-probe.sh --json` to verify that command presence is not
being treated as runtime proof. Use `--receipt-dir receipts/agent-lanes` only
with receipts that include `private_state_scan.status=pass` and passing
`journey_stages[]` rows for preflight, init, doctor, tick,
dispatch-or-simulate, closeout, and inspect-next-action. Strict runtime
receipts must include exactly one passing row for each required stage and must
have no `private_state_scan.findings` rows.
Blocked receipts in the same directory can explain why a lane remains a
compatibility target, but `evidence=="blocker_receipt"` never permits supported
copy.

## 1. Preflight

Run:

```bash
scripts/preflight.sh --json > preflight.json
jq '{schema_version, mode, exit_code, summary, reduced_mode, next_action}' preflight.json
```

Expected keys:

| Key | Meaning |
|---|---|
| `schema_version` | Preflight contract version. |
| `mode` | `full`, `reduced`, `blocked`, or `docs-only`. |
| `exit_code` | Stable mode code for shell callers. |
| `summary.required_missing` | Dependencies that block the first loop. |
| `summary.full_mode_missing` | Optional full-mode substrate that routes to reduced mode when absent. |
| `summary.misconfigured` | Tools present but not ready. |
| `reduced_mode.available` | Whether reduced mode can continue. |
| `next_action.command` | The next command or guide anchor. |

Failure branches:

| Mode | Action |
|---|---|
| `blocked` | Install or repair `summary.required_missing`; do not run the loop yet. |
| `docs-only` | Read docs and stop before runtime commands. |
| `reduced` | Continue only through simulator-backed commands. |
| `full` | Continue through full mode, but keep harness support tied to receipts. |

Receipt location: `preflight.json`.

## 2. Reduced-Mode Journey

Run:

```bash
scripts/journey-smoke.sh --matrix reduced --dry-run --json > journey-reduced.json
jq '{status, summary, rows: [.rows[] | {id, support_tier, runtime_proven, dispatch_or_simulate}]}' journey-reduced.json
```

Expected result:

| Key | Expected value |
|---|---|
| `status` | `pass` |
| `summary.lanes` | `1` |
| `summary.runtime_proven` | `1` |
| `rows[0].id` | `reduced` |
| `rows[0].support_tier` | `required-fallback` |
| `rows[0].runtime_proven` | `true` |
| `rows[0].dispatch_or_simulate` | `pass` |

Stage keys to inspect:

```bash
jq '.rows[0].stages | keys' journey-reduced.json
```

Expected stages:

- `preflight`
- `init`
- `doctor`
- `tick`
- `dispatch_or_simulate`
- `closeout`
- `inspect_next_action`

Failure branches:

| Failing stage | Action |
|---|---|
| `preflight` | Use the preflight failure branch above. |
| `init` | Inspect `private_state_scan.findings`; any private-state copy is a release blocker. |
| `doctor` | Read `stable_codes`; fix stable failures before tick. |
| `tick` | Treat as loop-engine failure; file a Bead before changing behavior. |
| `dispatch_or_simulate` | Keep reduced mode blocked until simulator dispatch passes. |
| `closeout` | Inspect `failure_classes`; failed closeout is useful but not a successful first run. |
| `inspect_next_action` | The journey is incomplete until a next action is visible. |

Receipt location: `journey-reduced.json`.

## 3. Full Matrix Probe

Run:

```bash
scripts/journey-smoke.sh --matrix claude,codex,gemini,openclaw,reduced --dry-run --json > journey-matrix.json
jq '{status, rows: [.rows[] | {id, support_tier, registry_valid, runtime_proven, evidence}]}' journey-matrix.json
scripts/agent-lane-probe.sh --json > agent-lanes.json
jq '{status, rows: [.rows[] | {id, cli_present, public_status, support_copy_allowed, evidence}]}' agent-lanes.json
scripts/agent-lane-probe.sh --receipt-dir receipts/agent-lanes --json > agent-lanes-with-receipts.json
```

Expected public interpretation:

| Row condition | Copy allowed |
|---|---|
| `id=="reduced"` and `runtime_proven==true` | Required fallback path. |
| Agent lane has `evidence=="runtime_receipt"` and `support_copy_allowed==true` | Supported copy allowed only after the strict receipt contract passes. |
| Agent lane has `evidence=="blocker_receipt"` | Compatibility target with an explicit blocker. |
| `registry_valid==true` and `runtime_proven!=true` | Compatibility target only. |
| `registry_valid!=true` | Do not advertise the lane. |
| `evidence=="source-gap"` or `evidence=="fixture-blocked"` | Name the blocker before support copy. |

Failure branch: if a lane is not runtime-proven, do not patch copy to call it
supported. If a lane appears runtime-proven in `journey-matrix.json` but stays
`compatibility-target` in `agent-lanes-with-receipts.json`, the receipt is
insufficient. Produce the required isolated journey/private-state receipt first
or keep the lane in the compatibility table. Duplicate required stage rows,
conflicting stage statuses, or any private-state findings make the receipt
insufficient.

Receipt location: `journey-matrix.json`.
Agent-lane receipt location: `agent-lanes.json`.

## 4. Installed CLI Smoke

Use a temporary prefix first:

```bash
tmp="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-install.XXXXXX")"
./install.sh --prefix "$tmp" --dry-run --json > install-dry-run.json
./install.sh --prefix "$tmp" --json > install.json
"$tmp/bin/flywheel" --help > flywheel-help.txt
"$tmp/bin/flywheel" quickstart --json > quickstart.json
```

Expected output:

| Receipt | Expected keys |
|---|---|
| `install-dry-run.json` | planned files and no writes outside `--prefix`. |
| `install.json` | installed file list, checksums, receipt path. |
| `flywheel-help.txt` | `preflight`, `init`, `doctor`, `tick`, `dispatch`, `validate-receipt`, and `inspect`. |
| `quickstart.json` | first command sequence for the installed binary. |

Failure branches:

| Failure | Action |
|---|---|
| Installer writes outside prefix | Release blocker. Stop. |
| Help omits reduced-mode commands | Release blocker. Fix CLI surface. |
| Quickstart names private substrate as required | Release blocker. Correct public copy. |

Receipt locations: the four files above plus the installer receipt path named
inside `install.json`.

## 5. Uninstall Smoke

Run:

```bash
./uninstall.sh --prefix "$tmp" --receipt "$tmp/share/flywheel/install-receipt.json" --confirm --json \
  > uninstall.json
find "$tmp" -type f -print > remaining-files.txt
```

Expected result:

| Receipt | Expected keys |
|---|---|
| `uninstall.json` | removed file count, checksum verification, skipped user-owned files. |
| `remaining-files.txt` | empty for a clean temporary prefix. |

Failure branches:

| Failure | Action |
|---|---|
| Checksum mismatch | Stop; do not remove user-modified files. |
| Files remain in a clean temp prefix | Fix uninstall receipt coverage. |
| User-owned files removed | Release blocker. |

Receipt locations: `uninstall.json` and `remaining-files.txt`.

## 6. Doctor Gate For Publication Work

Run:

```bash
FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
  flywheel doctor --repo "$PWD" --json > doctor.json
jq '{status, errors, warnings}' doctor.json
```

Expected result for release gating:

| Key | Expected value |
|---|---|
| `errors` | `[]` |
| `status` | `pass` or `warn` |
| `warnings` | Empty, fixed, or explicitly dispositioned in the release-blocker registry. |

Failure branches:

| Doctor result | Action |
|---|---|
| hard error | Fix or keep the registry row open. |
| warning without disposition | Add a registry row or a non-release evidence receipt. |
| warning with disposition | Keep it visible; do not hide the signal. |

Receipt location: `doctor.json`.

## 7. Public Surface Gates

Run:

```bash
bash tests/naming-conventions.sh
bash tests/public-surface-gap-scanner.sh
bash tests/public-links.sh
bash tests/installer-smoke.sh
bash tests/journey-smoke.sh
bash tests/preflight-fixtures.sh
bash tests/contact-routing.sh
bash tests/upstream-substrate-adoption.sh
bash tests/true-publication-registry-validate.sh
bash tests/cutover-receipts.sh
python3 scripts/depersonalize.py --scan-table --root docs --json
```

Expected results:

| Gate | Expected result |
|---|---|
| Naming conventions | `SUMMARY pass=... fail=0` |
| Public surface gap scanner | `SUMMARY pass=14 fail=0` |
| Public link checker | `SUMMARY pass=3 fail=0` and JSON `failure_count=0` for public docs/site links. |
| Installer smoke | `SUMMARY pass=10 fail=0` against a temporary prefix. |
| Journey smoke | `SUMMARY pass=7 fail=0` with reduced mode runtime-proven and agent lanes receipt-bound. |
| Preflight fixtures | Fixture-backed full, reduced, blocked, docs-only, and misconfigured modes pass. |
| Contact routing | Public mailto route uses `joshua@zeststream.ai` and subject `[Flywheel] Public site inquiry`; this proves routing, not delivery. |
| Upstream substrate adoption | Asupersync remains `gated-evaluation` until promotion gates and repo-local POC evidence pass. |
| Registry validator | `SUMMARY pass=6 fail=0` while rows remain open; coverage is derived from live readiness blockers and currently expects open TP-005/TP-017/TP-018 until release cutover. |
| Cutover receipt verifier | `SUMMARY pass=5 fail=0`; fixture proof shows saved receipt bundles replay, checksum drift is rejected, and stale signoff evidence is rejected. |
| Docs depersonalization | JSON status `pass` and zero findings. |

Failure branches:

| Failure | Action |
|---|---|
| private marker found | Remove, rewrite, or add reviewed allowlist only if it is truly public. |
| undispositioned TODO/gap found | Link a TP row, Bead id, or explicit non-release disposition. |
| registry release mode passes while rows are open | Fix the registry validator before release. |

Receipt locations: command output logs or CI job logs.

## 8. Closeout Receipt

Every loop closeout should end with a v2 receipt:

```bash
flywheel validate-receipt --repo "$PWD" --file .flywheel/last_closeout_receipt.json --json \
  > closeout-validation.json
```

Expected result:

| Key | Meaning |
|---|---|
| `status` | `pass` for a valid closeout receipt. |
| `failure_classes` | Empty for successful closeout. |
| `human_question` | Required only when the next owner is human. |
| `safe_local_work_remaining` | Must be false when handing work to a human. |

Failure branch: if validation fails, keep the work open. Do not replace the
receipt with a prose-only handoff.

Receipt location: `.flywheel/last_closeout_receipt.json` plus
`closeout-validation.json`.

## 9. Final Publication Readiness And Signoff

Run the non-fixture publication gate against the real remote and public web
surface:

```bash
python3 scripts/publication_readiness.py --json > publication-readiness.json
python3 scripts/publication_readiness.py --release --json > publication-readiness-release.json
```

Expected closure state:

| Check | Required evidence |
|---|---|
| GitHub repository | `JYeswak/flywheel` is public. |
| GitHub workflows | `CI`, `Installer Smoke`, `Release`, and `Site Deploy` exist on the remote. |
| Green runs | `CI` and `Installer Smoke` have successful remote runs on the remote default branch. |
| Installer smoke receipts | Each `Installer Smoke` OS leg uploads an `installer-smoke-<os>` artifact containing `installer-smoke-receipt.json`, install/uninstall receipts, reduced first-run receipts, and the closeout receipt. |
| User journey pack | `docs/runbooks/public-user-journey-pack.md` maps every public asset to persona lane, journey stage, entrypoint, visible wording, visual cue, CTA, proof refs, signoff status, and blocker/skip receipt reference. |
| GitHub release | `v0.2.0` exists and is neither draft nor prerelease. |
| Release assets | `install.sh`, `install.sh.sha256`, `SHA256SUMS`, `flywheel-v0.2.0.tar.gz`, and `flywheel-v0.2.0.tar.gz.sha256` are uploaded, non-empty, and expose `sha256:` digest metadata. |
| Website | `https://flywheel.zeststream.ai/` returns a successful status and contains the reviewed SMB/Yuzu journey markers. |
| Install proxy | `https://flywheel.zeststream.ai/install.sh` hashes to the value served at `https://flywheel.zeststream.ai/install.sh.sha256`. |
| External review | Two distinct non-Joshua reviewers approve or approve with follow-ups and cover every current public trust surface. |
| Joshua signoff | `.flywheel/PLANS/public-share-readiness-2026-05-12/release-signoff.json` exists and is approved. |

If the release blocker gate is blocked, inspect `.next_actions[]`. Each row
names the blocker code as both `code` and `blocker_code`, plus the owner,
action, and verification command for the
remaining cutover step.

The public cutover checklist is:

[`release-cutover-authorization.md`](release-cutover-authorization.md)

It maps every live readiness code to the exact operator command and receipt to
capture.
It is not release approval. Agents must not make the repository public, push the
release tag, deploy the site, or create an approved signoff unless Joshua
explicitly authorizes the cutover.

Create the signoff only after the real checks above pass:

```bash
cp .flywheel/PLANS/public-share-readiness-2026-05-12/release-signoff.template.json \
  .flywheel/PLANS/public-share-readiness-2026-05-12/release-signoff.json
```

Then edit `release-signoff.json` with:

| Field | Required value |
|---|---|
| `status` | `approved` |
| `approver` | `Joshua Nowak` exactly; aliases are rejected by `scripts/publication_readiness.py`. |
| `remote` | `JYeswak/flywheel` |
| `tag` | `v0.2.0` |
| `signed_at` | ISO-8601 UTC timestamp of the approval |

Failure branches:

| Failure | Action |
|---|---|
| Any publication readiness blocker remains | Do not create an approved signoff. Keep TP-005, TP-017, or TP-018 open. |
| Signoff exists before real remote/web checks pass | Treat it as invalid; reset to `pending` or remove the file. |
| External review has fewer than two valid reviewers or omits any current public trust surface | Keep TP-015 and B11.6 open. |

Receipt locations: `publication-readiness.json`,
`publication-readiness-release.json`, `user-journey-pack-validation.json`,
`repo-view.json`,
`remote-workflows.json`, `remote-runs.json`, `release-view.json`,
`external-review-release.json`, `release-signoff.receipt.json`,
`website-head.txt`, `live-site-probe.json`, `website-probe.json`, `install-probe.json`,
`install-sha256-probe.json`, `install-sha256.actual`,
`install-sha256.expected`, `publication-readiness-replay.json`,
`cutover-receipts-validation.json`,
`.flywheel/PLANS/public-share-readiness-2026-05-12/release-signoff.json`, and
`docs/evidence/external-review-log.jsonl`. First run
`python3 scripts/validate_user_journey_pack.py --json >
user-journey-pack-validation.json`; it must report `status=pass`, zero errors,
and the expected `flywheel.public_user_journey_pack.v0` schema. Replay the saved
deployed-site link proof with `python3 scripts/live_site_probe.py --base-url
https://flywheel.zeststream.ai/ --json > live-site-probe.json`; it must report
`status=pass` and `failure_count=0`. The saved `website-probe.json` must contain
the reviewed SMB/Yuzu homepage markers so `publication_readiness.py` can report
`website_content_current`. Replay the saved
receipt bundle with `python3 scripts/publication_readiness.py --release --json --repo-view-json
repo-view.json --workflows-json remote-workflows.json --runs-json
remote-runs.json --release-json release-view.json --review-json
external-review-release.json --website-probe-json website-probe.json
--install-probe-json install-probe.json --install-sha256-probe-json
install-sha256-probe.json --signoff-json release-signoff.receipt.json >
publication-readiness-replay.json`; it must report `status=pass` with an empty
open-item list. Then run `python3 scripts/validate_cutover_receipts.py --receipt-dir
. --release --json > cutover-receipts-validation.json`; it must report
`status=pass` and zero errors. The private working review log at
`.flywheel/PLANS/public-share-readiness-2026-05-12/review-log.jsonl` is the
source of the public evidence copy. Review rows must cover `README.md`,
`CHARTER.md`, `docs/getting-started/first-run.md`,
`docs/evidence/publication-evidence.md`,
`docs/evidence/publication-blocker-coverage.md`,
`docs/runbooks/release-cutover-authorization.md`, and
`docs/runbooks/public-release-runbook.md`.
