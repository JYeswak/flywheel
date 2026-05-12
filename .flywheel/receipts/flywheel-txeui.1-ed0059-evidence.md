# flywheel-txeui.1-ed0059 evidence

## Scope

Bead: `flywheel-txeui.1`
Task: `[ntm-upstream] review-queue needs L85 idle-state schema before idle-state-probe replacement`

## Close Evidence

Filed upstream issue:

`https://github.com/Dicklesworthstone/ntm/issues/134`

Issue title:

`review-queue needs strict robot JSON and L85 idle-state schema`

## Verification

L85 canonical classifier remains local:

- `.flywheel/scripts/idle-state-probe.sh`
- `tests/idle-state-probe.sh`
- L85 in `AGENTS.md`

Passed:

```bash
bash tests/idle-state-probe.sh
```

Observed local L85 probe fields:

```json
{
  "schema_version": "idle-state-probe/v1",
  "status": "pass",
  "has_idle_state_class": true,
  "has_config_path": true,
  "has_config_loaded": true,
  "has_dispatch_over_threshold": true
}
```

Observed native `review-queue` gap:

```bash
ntm review-queue flywheel --json
```

- exit code: `0`
- stdout: INFO lines plus human report
- strict `jq` parse: fails

Observed native `review-queue --format json` gap:

```bash
ntm review-queue flywheel --format json
```

- exit code: `0`
- stdout: INFO lines before JSON object
- strict `jq` parse: fails
- JSON object keys after stripping logs: `generated_at`, `session`, `idle_agents`, `suggestions`

Missing L85-compatible fields in native JSON:

- `idle_state_class`
- `idle_state_summary`
- `idle_dispatching_over_threshold_count`
- `idle_state_config_path`
- `idle_state_config_loaded`
- `thresholds`
- cooldown remaining seconds
- ready P0/P1 counts
- `disabled_class`
- `not_waiting`
- `capture_provenance`

## Verdict

`ntm review-queue` remains ISSUE, not USE/WRAP, for replacing `.flywheel/scripts/idle-state-probe.sh` until upstream issue #134 is resolved.

## Canonical CLI Checklist

- doctor / health / repair triad: not applicable; no flywheel CLI authored or changed.
- validate / audit / why triad: not applicable; this is upstream issue filing and local evidence.
- `--json`, schema output, stable exit-code behavior: addressed by probes showing the current native gap.
- `--dry-run` / `--apply`: not applicable; no local mutating command surface changed.
- file-length threshold: not applicable.

## Four-Lens Self-Grade

- brand: 8
- sniff: 8
- jeff: 8
- public: 8

Three Judges check: skeptical operator sees a concrete upstream issue URL, maintainer sees exact missing fields, future worker sees why idle-state-probe remains canonical until #134 lands.
