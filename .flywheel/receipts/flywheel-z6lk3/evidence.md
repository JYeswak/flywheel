# flywheel-z6lk3 Evidence

Task: `flywheel-z6lk3-8bb174`
Worker identity: `MagentaPond`
Status: `BLOCKED`
Reason: AG3 is not complete; bead should remain open.

## Skill And Survey

- Skills used: `codex-watchtower`, `canonical-cli-scoping`.
- Socraticode queries: 4.
- Indexed chunks observed: 1535.
- Relevant findings:
  - `tests/codex-watchtower.sh` is the local watchtower regression surface.
  - `INCIDENTS.md` contains the Codex CLI upstream mapping and local recovery doctrine.
  - AGENTS L120 allows `br_close_executed=not_applicable` only for BLOCKED/DECLINED.
  - AGENTS L137 says normal workers should not hold long-lived `.beads/` reservations for standard `br` mutation lanes.

## Acceptance Gates

### AG1: PASS

Rollout permission janitor is loaded and healthy.

Evidence commands:

```bash
launchctl list | rg 'ai\.zeststream\.codex-rollout-permission-janitor'
plutil -lint /Users/josh/Library/LaunchAgents/ai.zeststream.codex-rollout-permission-janitor.plist
tail -n 5 /Users/josh/.local/state/flywheel/codex-rollout-permission-ledger.jsonl | jq -c '.'
find /Users/josh/.codex/sessions -type f -name '*.jsonl' ! -perm 600 -print | head -20
find /Users/josh/.codex/sessions -type f -name '*.jsonl' | wc -l | tr -d ' '
```

Observed:

- LaunchAgent row: `- 0 ai.zeststream.codex-rollout-permission-janitor`.
- Plist lint: `OK`.
- Last five ledger rows: `fixed_count=0`, latest `2026-05-09T00:49:33Z`.
- Non-0600 rollout JSONL matches: none.
- Rollout JSONL count observed: 1234.

### AG2: PASS

No pre-existing ALPS ACK was found initially for `#21620` / `workspace-write` / `agents/`, so a coordination request was sent to `alpsinsurance:1`. ALPS ACKed after checking the repo.

Evidence commands:

```bash
/Users/josh/.local/bin/ntm health alpsinsurance --json
/Users/josh/.local/bin/ntm grep '#21620|workspace-write|agents/' alpsinsurance -C 3 -n 2000
/Users/josh/.local/bin/ntm logs alpsinsurance --panes=1 --limit=200 --filter '#21620|workspace-write|agents|ACK|CoralRaven'
```

Observed:

- `alpsinsurance:1` is live and is the Claude orchestrator pane.
- No matching prior ACK was present.
- Sent coordination request:

```bash
/Users/josh/.local/bin/ntm send alpsinsurance --pane=1 --no-cass-check "COORDINATION flywheel-z6lk3: Please ACK codex-cli issue #21620 risk class for ALPS: Codex workspace-write may fail when writing inside repo subdirectory agents/. Proposed workaround until upstream fix: dispatch Codex workers with absolute paths or alternate non-agents/ write targets for any ALPS work touching agents/. Reply ACK #21620 with accepted/adjusted workaround plan. - MagentaPond"
```

Delivery proof:

```bash
/Users/josh/.local/bin/ntm grep 'COORDINATION flywheel-z6lk3|ACK #21620|workspace-write may fail' alpsinsurance -C 2 -n 200
```

Observed request visible at `alpsinsurance/alpsinsurance__cc_1:198-203`.

ACK evidence:

```bash
/Users/josh/.local/bin/ntm grep 'ACK #21620|accepted workaround|adjusted workaround|workspace-write|agents/' alpsinsurance -C 5 -n 340
```

Observed:

- `alpsinsurance:1` wrote `/tmp/alps-flywheel1-ack-21620-T2500Z.md`.
- ACK body includes `ACK accepted, workaround plan adopted.`
- ALPS exposure: top-level `<repo>/agents/` exists, but in-flight Q11/UHF2-12/UHF2-13 dispatches do not target it.
- Forward workaround: prefer non-`agents/` paths such as `.flywheel/agents-config/`, `docs/agents/`, or `backend/src/agents/`; use absolute paths if top-level `agents/` is definitionally required.
- ACK delivery to `flywheel:1` was reported by ALPS at pane lines 337-340.

### AG3: BLOCKED

Codex CLI is still pinned and no next watchtower high re-triage ledger exists yet.

Evidence commands:

```bash
codex --version
ls -1 /Users/josh/.local/state/flywheel/codex-watchtower/daily-*.jsonl | tail -10
test -f /Users/josh/.local/state/flywheel/codex-watchtower/daily-2026-05-09.jsonl || echo NO_2026_05_09_LEDGER
/Users/josh/.local/bin/codex-watchtower-daily.sh --doctor --json | jq -c '.'
/Users/josh/.local/bin/codex-watchtower-daily.sh --summary --json | jq -c '{ts,kind,status,codex_watchtower_status,codex_pinned_version,codex_new_issues_24h,codex_relevant_issues,codex_warnings,ledger}'
```

Observed:

- `codex-cli 0.125.0`.
- Latest daily ledger remains `/Users/josh/.local/state/flywheel/codex-watchtower/daily-2026-05-08.jsonl`.
- No `daily-2026-05-09.jsonl` exists at verification time.
- Watchtower doctor success true, latest daily is 2026-05-08.

## Verification

```bash
br show flywheel-z6lk3
br dep tree flywheel-z6lk3
/Users/josh/.local/bin/ntm grep 'COORDINATION flywheel-z6lk3|ACK #21620|workspace-write may fail' alpsinsurance -C 2 -n 200
```

Result:

- Bead remains `OPEN`.
- No dependencies.
- ALPS coordination request delivered and ACK observed.

## Four-Lens Self-Grade

- brand: 8
- sniff: 9
- jeff: 8
- public: 8

Three Judges check: a skeptical operator, maintainer, and future worker can rerun the listed commands and see why close is blocked.

## L52 / L53

- `no_bead_reason`: existing bead `flywheel-z6lk3` already tracks AG3 pending; no new gap was discovered.
- `fuckups_logged`: `codex-watchtower-close-gate-pending`, `tmp-cleanup-dcg-blocked`.
- `tmp_dir_released`: false. DCG blocked both recursive scratch cleanup and preserving the ALPS pane snapshot via move from `/var/folders`; temp path remains at `/var/folders/d0/09qgt_0n1m1ff8nyzbxppx9c0000gn/T/flywheel-z6lk3.XXXXXX.dcBfUKX1V0` with one saved pane snapshot. I did not bypass the guard.
