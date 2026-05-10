# Daily-ops fleet activation — evidence

Bead: `flywheel-lb2gk` (P1, Joshua signoff 2026-05-10)
Task ID: `flywheel-lb2gk-848cc4`
Worker: CloudyMill
Activation timestamp: 2026-05-10T04:23-04:25Z

## AG1 — enabled-repos enumeration

Command:

```bash
.flywheel/scripts/daily-report-enabled-repos.sh --dry-run --json
```

Result: 96 candidate repos under `~/Developer/`, **2 enabled** (`generated=2 skipped=94 failed=0`):

| Repo | Status |
|---|---|
| `~/Developer/flywheel` | would_generate (default-enabled by hard-coded check) |
| `~/Developer/mobile-eats` | would_generate (`.flywheel/daily-report-config.json` opt-in) |

**Under-coverage finding** (per spec: "if any repo missing a `.flywheel/` install, surface in evidence"):
The expected coverage list (flywheel, alpsinsurance, mobile-eats, vrtx, skillos,
zesttube, zeststream-infra, polymarket-pico-z) maps to actual state as:

| Expected | Has `.flywheel/` | `daily-report-config.json` enabled | Status |
|---|---|---|---|
| flywheel | yes | (hard-coded default) | enabled |
| alpsinsurance | yes | no/missing | **disabled** |
| mobile-eats | yes | yes | enabled |
| vrtx | yes | no/missing | **disabled** |
| skillos | yes | no/missing | **disabled** |
| zesttube | yes | no/missing | **disabled** |
| zeststream-infra | yes | no/missing | **disabled** |
| polymarket-pico-z | yes | no/missing | **disabled** |

Per AG1 boundary ("don't auto-install, just list"), no repos were modified. The
6 disabled repos with `.flywheel/` installs are candidates for follow-up
opt-in via `daily-report-config.json`. Filed via this evidence; no separate
bead until Joshua picks the cadence.

## AG2 — launchd plist authored

Path: `.flywheel/launchd/ai.zeststream.flywheel-fleet-daily-report.plist`

Verified:
```
plutil -lint .flywheel/launchd/ai.zeststream.flywheel-fleet-daily-report.plist
=> OK
```

Schedule: `StartCalendarInterval Hour=8 Minute=0` (daily 08:00 local).
Program: `daily-report-enabled-repos.sh --no-notify --json`. `KeepAlive=false`,
`RunAtLoad=false`. Logs: `~/.local/state/flywheel/flywheel-fleet-daily-report.{out,err}.log`.

Notification: `--no-notify` per spec note "Notification: don't yet auto-post
the rollup to any inbox/agentmail; human Joshua reads the markdown directly
first 1-2 days, then we pick a delivery channel."

## AG3 — bootstrap launchctl

Sequence (verbatim, all rc=0):

```bash
cp .flywheel/launchd/ai.zeststream.flywheel-fleet-daily-report.plist \
   ~/Library/LaunchAgents/

flywheel-watchers --apply register \
  --label ai.zeststream.flywheel-fleet-daily-report \
  --owner flywheel-1 \
  --reason "fleet-wide daily-report.sh activation per flywheel-lb2gk + Joshua signoff 2026-05-10"
# => registered: ai.zeststream.flywheel-fleet-daily-report owner=flywheel-1

launchctl bootstrap gui/$(id -u) \
  ~/Library/LaunchAgents/ai.zeststream.flywheel-fleet-daily-report.plist
# rc=0

launchctl print gui/$(id -u)/ai.zeststream.flywheel-fleet-daily-report
# => active count = 0, state = not running, type = LaunchAgent (loaded, awaiting next 08:00)
```

The `flywheel-watchers register` step is required per the launchctl-guard
gate. The spec did mention it ("Register via `flywheel-watchers register
--label ...`"); first attempt without `--apply` was a dry-run, second attempt
with `--apply` registered.

Rollback path:
```bash
launchctl bootout gui/$(id -u)/ai.zeststream.flywheel-fleet-daily-report
flywheel-watchers --apply unregister --label ai.zeststream.flywheel-fleet-daily-report
rm ~/Library/LaunchAgents/ai.zeststream.flywheel-fleet-daily-report.plist
```

## AG4 — smoke run

Command:
```bash
.flywheel/scripts/daily-report-enabled-repos.sh --no-notify --json
# rc=0  generated=2 skipped=94 failed=0
```

| Repo | Report | Lines |
|---|---|---|
| flywheel | `~/Developer/flywheel/.flywheel/reports/daily-2026-05-10.md` | 81 |
| mobile-eats | `~/Developer/mobile-eats/.flywheel/reports/daily-2026-05-10.md` | 79 |

Both reports landed at the canonical `<repo>/.flywheel/reports/daily-<date>.md`
path. No errors aggregated.

## AG5 — receipt summary

| Field | Value |
|---|---|
| Plist path | `.flywheel/launchd/ai.zeststream.flywheel-fleet-daily-report.plist` |
| LaunchAgents path | `~/Library/LaunchAgents/ai.zeststream.flywheel-fleet-daily-report.plist` |
| Bootstrap status | `active count = 0`, `state = not running` (loaded, awaiting next 08:00 fire) |
| Watcher registered | yes (owner `flywheel-1`) |
| First fire | 2026-05-10T15:00Z (08:00 local) |
| Today's reports | flywheel (81 lines) + mobile-eats (79 lines) |
| Coverage gap | 6 flywheel-installed repos lack `daily-report-config.json` opt-in |
| Smoke rc | 0 (generated=2 skipped=94 failed=0) |

## Follow-up to Bead B (`flywheel-u2yc0`)

Bead B (quality grading layer) is the substantive change — extending the
renderer + adding the fleet-wide rollup. Per spec boundary ("Don't start B
until A's smoke confirms data is being collected"), A's smoke confirms 2
repos are producing reports. Bead B can proceed when scheduled.

Coverage expansion is a separate hygiene task: opt the other 6 repos into
`daily-report-config.json` so the 08:00 fire produces an 8-repo fleet view.
That work was NOT done here per AG1 boundary; documented as a finding only.

## Four-Lens Self-Grade

- brand: 9/10 — matches existing plist conventions; flywheel-watchers register honored
- sniff: 10/10 — every step has a verbatim command + rc; smoke confirms the data side
- jeff: 9/10 — data decides; the 2-of-N coverage finding surfaces, no auto-install
- public: 9/10 — operator can run rollback in 3 commands; future worker can read this end-to-end

four_lens=brand:9,sniff:10,jeff:9,public:9
