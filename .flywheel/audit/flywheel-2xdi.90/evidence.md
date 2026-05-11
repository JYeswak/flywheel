# flywheel-2xdi.90 — Evidence Pack

**Bead:** flywheel-2xdi.90 (P3)
**Title:** [gap-probe-without-receiver] operator-fatigue-probe.sh
**Mission fitness:** `adjacent` — probe receiver wire-in supports orchestrator-fatigue measurement signal

## Hypothesis vs root cause (N=14 bead-hypothesis META-rule)

**Bead hypothesis (auto-filed):** probe emits output but no receiver references it.

**Root cause (verified):** Probe exists at `.flywheel/scripts/operator-fatigue-probe.sh`, well-formed (canonical-cli surfaces work, schema_version `operator-fatigue-probe.v1` stable). No script in `.flywheel/scripts/`, no tick.md call site, no launchd plist, no test file references it. Genuine probe-without-receiver gap.

## Fix shape decision

Per the probe's design comment: "the orchestrator decides what to do with a fatigue_signal=true reading; this probe just measures." Two viable receivers:
1. **Tick wire-in** at `~/.claude/commands/flywheel/tick.md` — cross-repo into JSM-managed claude commands (would require patch-artifact discipline per cross-repo-consumer-vs-mutator doctrine just shipped in 2xdi.93)
2. **Regression test** at `tests/` — in-scope flywheel-repo edit; matches existing sister-probe pattern (cost-telemetry-token-burn-probe-canonical-cli.sh, cross-pane-git-probe-canonical-cli.sh)

Chose **option 2** (test wire-in): in-scope, follows established sister-pattern, provides genuine regression coverage, satisfies corpus #5 of `probe_without_receiver` check.

## Fix

Created `tests/operator-fatigue-probe-canonical-cli.sh` (9 assertions):
1. syntax check
2-5. canonical-cli surfaces (`--info`, `--schema`, `--doctor`, `--health`) emit operator-fatigue-probe.v1
6. default `--json` run mode emits measurement envelope
7. Step 4o anti-pattern preserved (no notification call sites — pushover/sendmail/osascript/notify-send)
8. READ-ONLY discipline (probe doesn't create its log files when paths don't exist)
9. Strict-mode failure on missing input log (loud ERR on stderr; correct for orch-decision signal)

Test name follows the canonical-cli convention so it matches gap-hunt-probe's `*-canonical-cli*.sh` corpus pattern (#5).

## Test design notes

Two iterations before clean PASS:
- **Test 7 (Step 4o)** initially used substring word-match regex; false-positive matched the word "email" inside an anti-pattern comment. Refined to call-site shape regex (`^\s*(curl ... pushover|sendmail|osascript -e display|notify-send )`) so the test asserts ACTUAL notification calls, not just word presence.
- **Test 9 (missing input)** initially asserted graceful degradation; probe actually fails LOUDLY when input log missing (correct strict-mode for an orch-decision signal). Test rewritten to assert `ERR:` on stderr.

This iteration illustrates the bead-hypothesis META-rule applied to TESTS as well: probe what's actually expected, not what's casually assumed.

## Acceptance gates

| # | Gate | Status |
|---|---|---|
| AG1 | Identify probe-without-receiver gap empirically | DONE — receiver scan found 0 callers across 5 corpora |
| AG2 | Wire receiver (test, tick, or launchd) | DONE — test file under canonical convention |
| AG3 | Verify gap cleared in fresh probe | DONE — fresh probe no longer flags operator-fatigue-probe.sh |

## Verification

```bash
$ bash tests/operator-fatigue-probe-canonical-cli.sh
SUMMARY pass=9 fail=0

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("probe-without-receiver.*operator-fatigue"))'
(empty)

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_class_distribution["probe-without-receiver"]'
19   # was 20 pre-fix; 1 cleared
```

## DID / DIDNT / GAPS

- **DID 3/3** — gap identified, receiver wired via test, gap verified cleared
- **DIDNT none**
- **GAPS none** — 19 other probe-without-receiver gaps remain but are out of scope for this bead

## Files Changed

- `tests/operator-fatigue-probe-canonical-cli.sh` (new, 9/9 PASS)
- `.flywheel/audit/flywheel-2xdi.90/evidence.md` (this file)
- `.flywheel/audit/flywheel-2xdi.90/compliance-pack.md`
- `.flywheel/audit/flywheel-2xdi.90/journey/diff.txt`

NO mutation of the probe script itself. NO cross-repo edits.

## L112 Probe

- `l112_probe_command`: `bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("probe-without-receiver.*operator-fatigue"))'`
- `l112_probe_expected`: `literal:` (empty output)
- `l112_probe_timeout_sec`: `60`

## Four-Lens Self-Grade

- **brand:** 9 — sister-pattern conformance; canonical-cli naming convention honored
- **sniff:** 10 — test iterations show genuine probe-vs-assume (Test 7 + Test 9 false-positives caught and refined before close)
- **jeff:** 9 — wires the probe into the corpus that gap-hunt-probe is already checking
- **public:** 9 — future operator gets 9 PASS assertions documenting probe contract + Step 4o discipline
