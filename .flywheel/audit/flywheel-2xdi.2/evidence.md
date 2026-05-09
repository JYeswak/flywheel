# flywheel-2xdi.2 evidence

Task: resolve the auto-filed `wired-but-cold` gap for
`~/.claude/skills/.flywheel/lib/common.sh`.

## Result

Closed as stale / false-positive for this artifact class.

`lib/common.sh` is a shared shell helper library, not a direct event producer.
The original detector evidence was "not referenced by recent flywheel jsonl
ledgers modified in last 30d"; that is a weak signal for this file because the
library is consumed by live binaries and modules that write or read the ledgers.

## Load-Bearing Evidence

Direct source relationships found:

- `~/.claude/skills/.flywheel/bin/flywheel-loop` sources `"$LIB/common.sh"`.
- `~/.claude/skills/.flywheel/bin/flywheel` sources `"$FLYWHEEL_HOME/lib/common.sh"`.
- Adjacent flywheel binaries source the same helper, including
  `flywheel-refresh-source`, `flywheel-dashboard`, `flywheel-outcome`,
  `flywheel-quality`, `flywheel-verdict`, `flywheel-render-latest`,
  `flywheel-stale`, `flywheel-pattern`, and `flywheel-digest`.
- `flywheel-refresh-source.README.md`, `flywheel-verdict.README.md`, and
  `flywheel-lock-repair.README.md` name `lib/common.sh` as the shared DB,
  logging, and helper source.

Focused runtime proof:

```bash
bash -lc 'source /Users/josh/.claude/skills/.flywheel/lib/common.sh; test "$(fw_classify_source x:@zeststream)" = "x_user|zeststream"; test "$(fw_normalize_url x_search flywheel)" = "x:search:flywheel"; printf "OK_common_sh_load_bearing\n"'
```

Observed:

```text
OK_common_sh_load_bearing
```

Additional validation:

- `bash -n /Users/josh/.claude/skills/.flywheel/lib/common.sh /Users/josh/.claude/skills/.flywheel/bin/flywheel-loop` passed.
- Dispatch template audit passed for `/tmp/dispatch_flywheel-2xdi.2-e7bf93.md`.
- Socraticode query against `/Users/josh/Developer/flywheel` returned 10 chunks for common-library / wired-but-cold context.

## Decision

No code change is needed. The correct close action is to preserve the audit
evidence and close the gap bead, rather than wiring artificial JSONL references
for a helper library whose consumers are already live.

## Four-Lens Self-Grade

- brand: 8 - Keeps the gap system honest without creating fake telemetry.
- sniff: 8 - Uses source references plus a runtime function proof.
- jeff: 8 - Avoids overfitting a detector metric to the wrong artifact class.
- public: 8 - A skeptical operator, maintainer, and future worker can rerun the L112 probe.
