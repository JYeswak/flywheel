# flywheel-2xdi.36 Compliance Pack

Task: `flywheel-2xdi.36-78a509`
Bead: `flywheel-2xdi.36` (P3)
Decision: DONE
Compliance score: 870/1000

## Final receipt

```
gap_class=wired-but-cold
target=~/.claude/skills/.flywheel/lib/doctor.d/part-03-security-posture.sh
fix=self-logging block matching lib/autoloop-executor.sh (flywheel-2xdi.32 precedent)
ledger=$HOME/.local/state/flywheel/security-posture.jsonl
ledger_test_emit=YES (1 row written; basename "part-03-security-posture.sh" present in ledger text)
files_reserved=~/.claude/skills/.flywheel/lib/doctor.d/part-03-security-posture.sh
```

## Finding

`gap-hunt-probe` flagged `part-03-security-posture.sh` as
**wired-but-cold**: the script's basename was not present in any
`$HOME/.local/state/flywheel/*.jsonl` ledger modified in the last 30
days, despite the script being invoked via `doctor.sh` /
`portable_doctor.sh` (the function `security_posture_doctor_json`
is called as part of every doctor pass).

The wired-but-cold class is not "the code is unused" but "the gap
probe can't see it being used because it doesn't self-log under its
basename." The canonical fix established by flywheel-2xdi.32 (for
`lib/autoloop-executor.sh`) is to add a small self-logging block
that emits a JSONL row under the script's path on each function-entry,
making the basename visible to gap-hunt-probe's text-grep sampling.

## Repair

Patched `~/.claude/skills/.flywheel/lib/doctor.d/part-03-security-posture.sh`
with a 22-line self-logging block (matches autoloop-executor pattern):

```bash
SECURITY_POSTURE_LEDGER="${SECURITY_POSTURE_LEDGER:-$HOME/.local/state/flywheel/security-posture.jsonl}"
SECURITY_POSTURE_SCRIPT_PATH="${BASH_SOURCE[0]:-...}"

security_posture_log_entry() {
    local mode="${1:-doctor_json}"
    local ledger="$SECURITY_POSTURE_LEDGER"
    mkdir -p "$(dirname "$ledger")" 2>/dev/null || return 0
    if command -v jq >/dev/null 2>&1; then
        jq -nc \
            --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            --arg script "$SECURITY_POSTURE_SCRIPT_PATH" \
            --arg mode "$mode" \
            --arg schema "security-posture.entry.v1" \
            '{ts:$ts, schema_version:$schema, script:$script, mode:$mode}' \
            >> "$ledger" 2>/dev/null || true
    fi
}

security_posture_doctor_json() {
    security_posture_log_entry "doctor_json"   # ← new first-line self-log
    ...
}
```

The block is **defensive-by-default**:
- Mkdir uses `2>/dev/null || return 0` so log dir creation can't fail the doctor
- `command -v jq` guards against missing-jq environments
- `>> "$ledger" 2>/dev/null || true` makes append failures silent
- Self-logging is at function-entry, not exit, so partial doctor runs still mark the script as warm

`SECURITY_POSTURE_LEDGER` is env-tunable for test harnesses that want
to redirect the ledger to a fixture path.

## Acceptance Gate Map

| # | Gate | Status |
|---|------|--------|
| AG1 (implicit) | Identified script is being invoked but invisible to gap-hunt-probe basename sampling | ✓ Function `security_posture_doctor_json` is called from doctor.sh; basename was absent from `*.jsonl` 30d corpus per gap-hunt-probe |
| AG2 (implicit) | Add self-logging matching established autoloop-executor pattern | ✓ 22-line block added; same shape, schema, defensive-by-default semantics |
| AG3 (implicit) | Verify ledger emission lands the basename | ✓ Live test invocation: ledger went 0 lines → 1 line; tail -1 shows `"script":"/Users/josh/.claude/skills/.flywheel/lib/doctor.d/part-03-security-posture.sh"`; grep -c basename = 1 |
| AG4 (implicit) | Bash syntax pass on the patched script | ✓ `bash -n` returns 0 |

did=4/4

## Evidence

```text
$ # Bash syntax pass:
$ bash -n /Users/josh/.claude/skills/.flywheel/lib/doctor.d/part-03-security-posture.sh && echo OK
OK

$ # Pre-fix ledger absence:
$ ls /Users/josh/.local/state/flywheel/security-posture.jsonl 2>&1
ls: ...: No such file or directory   # (ledger didn't exist)

$ # Post-fix test invocation:
$ source /Users/josh/.claude/skills/.flywheel/lib/doctor.d/part-03-security-posture.sh
$ security_posture_log_entry test_invoke_from_flywheel-2xdi.36
$ tail -1 /Users/josh/.local/state/flywheel/security-posture.jsonl
{"ts":"2026-05-09T17:54:14Z","schema_version":"security-posture.entry.v1","script":"/Users/josh/.claude/skills/.flywheel/lib/doctor.d/part-03-security-posture.sh","mode":"test_invoke_from_flywheel-2xdi.36"}

$ # gap-hunt-probe text-grep simulation:
$ grep -c "part-03-security-posture.sh" /Users/josh/.local/state/flywheel/security-posture.jsonl
1   # ← basename now visible to gap-hunt-probe

$ # Pattern parity with autoloop-executor (flywheel-2xdi.32 precedent):
$ grep -c "log_entry\|LEDGER" /Users/josh/.claude/skills/.flywheel/lib/autoloop-executor.sh
6   # original
$ grep -c "log_entry\|LEDGER" /Users/josh/.claude/skills/.flywheel/lib/doctor.d/part-03-security-posture.sh
8   # newly patched (uses similar field count)
```

## Scope

- Edits: 1 source file + 3 audit-dir files
  - `~/.claude/skills/.flywheel/lib/doctor.d/part-03-security-posture.sh`
    (22-line self-logging block prepended; 2 line additions inside
    `security_posture_doctor_json` for the entry-call; 236 → 261 lines)
  - `.flywheel/audit/flywheel-2xdi.36/ledger-sample.jsonl` (live ledger
    sample showing emission)
  - `.flywheel/audit/flywheel-2xdi.36/edit-evidence.txt` (line-count
    delta + patched header preview)
  - `.flywheel/audit/flywheel-2xdi.36/compliance-pack.md` (this file)
- Files reserved/released: 1 — `part-03-security-posture.sh` (will
  release before callback)
- Out of scope:
  - Adding self-logging to OTHER `lib/doctor.d/part-*.sh` scripts
    (they will have their own gap-hunt-probe beads filed; one-script-
    per-bead worker scope discipline)
  - Modifying gap-hunt-probe's sampling regex (not the bug; the script's
    self-logging gap was the actual issue)

## L52 / L80 / L120 / L61

- DIDNT: applying the same pattern to other cold scripts (separate
  per-script gap-hunt-probe beads handle each individually)
- GAPS: none new
- beads_filed: none
- beads_updated: none
- no_bead_reason: per-script-cold-gap-handled-orch-files-other-scripts-as-they-trigger
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: not_applicable
- shared_surface_reservations_checked: yes
- shared_surface_reservations_released: yes (will release before callback)
- flywheel_orch_action_required: none (gap-hunt-probe will auto-file
  follow-up beads for any remaining cold scripts; this dispatch's
  scope is the named target only)

## Skill Auto-Routes

- canonical-cli-scoping: addressed=yes — self-logging emits stable
  schema_version (`security-posture.entry.v1`); JSON output discipline
  (jq -nc); env-tunable surface (`SECURITY_POSTURE_LEDGER`); pattern
  matches autoloop-executor.sh canonical idiom
- rust-best-practices: n/a — no Rust touched
- python-best-practices: n/a — no Python touched
- readme-writing: n/a — no README touched

## Four Lens

- Brand: 9 (data-decides discipline applied — gap-hunt-probe's
  basename-grep mechanism understood and addressed at the correct
  layer; ZestStream brand voice "structure-level over symptom-level"
  honored — the fix doesn't paper over the probe; it makes the
  script self-document its own warmth)
- Sniff: 9 (every claim grounded in concrete evidence: pre-fix
  ledger absent, post-fix ledger 1 row, grep -c basename = 1;
  bash -n pass; pattern parity citation to autoloop-executor.sh)
- Jeff: 8 (no Jeffrey-substrate touch; the self-logging pattern is
  flywheel-internal infrastructure; .flywheel skill is NOT
  JSM-managed per earlier verification — direct edit allowed)
- Public: 9 (Three-Judges check: an operator can run the doctor and
  see the ledger grow; a maintainer 6 months from now sees the
  precedent citation `flywheel-2xdi.32` and understands WHY the
  pattern is canonical; a future worker fixing another cold script
  can copy this self-logging block verbatim with placeholder rename)

## L112 Probe

```
grep -c "part-03-security-posture.sh" \
  /Users/josh/.local/state/flywheel/security-posture.jsonl 2>/dev/null
```
Expected: `grep:^[1-9]` (basename appears at least once in the
ledger — proves gap-hunt-probe's text-grep sampling will find it).
At capture time the count is 1; future invocations will increment.
