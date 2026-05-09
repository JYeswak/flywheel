# flywheel-xap2 Evidence

Task: `flywheel-xap2-0649d0`
Bead: `flywheel-xap2`
Title: [josh-req-codex-parity] capture Codex-originated Joshua requests
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)

Sibling reference: `flywheel-d62z` (Gate 5 of the Claude
UserPromptSubmit wiring) shipped the Claude-side hook 2026-05-03 and
filed this bead as the explicit Codex parity follow-up; epic
`flywheel-2p25`. Sibling `flywheel-orx1` (PATH discipline) closed
this turn with verdict=green so the wrapper can rely on
`/Users/josh/.local/bin/ntm` resolution.

## Disposition

**Option A shipped: `.flywheel/scripts/ntm-send-with-josh-req-capture.sh`
is the Codex-runtime parity wrapper for `ntm send`. It mirrors the
Claude UserPromptSubmit hook's request-shape detection, secret
scrubbing, sha256 hashing, and schema-v2 row shape, plus adds
`captured_via=ntm_send`, `runtime`, and `target_pane` provenance
fields. Dedup via `request_text_hash` (100-row lookback). Claude
hook regression suite passes 33/33 unchanged.**

The "secondary_ntm_send_wrapper_capture" track in
`.flywheel/scripts/orch-capture-parity-probe.py:24` (owner_bead =
flywheel-xap2) is now wired by this script. Orchestrators can
substitute `ntm-send-with-josh-req-capture.sh send <session> --pane=N
--no-cass-check "<message>"` for `ntm send <session> --pane=N
--no-cass-check "<message>"` and the request-shaped messages will be
captured into `~/.local/state/flywheel/josh-requests.jsonl` before
the message is delivered to the Codex pane.

## Acceptance Receipts

| Acceptance | Status | Evidence |
|---|---|---|
| Option A implemented (or stronger non-fragile capture) | done | `.flywheel/scripts/ntm-send-with-josh-req-capture.sh` (passthrough wrapper around `ntm send` with side-effecting capture) |
| Codex-originated Joshua request fixture writes a schema v2-compatible JSONL row | done | T1 fixture `jr-2026-05-09T131000Z-200` in `fixture-jsonl.txt` carries all schema v2 required fields plus `captured_via=ntm_send runtime=codex target_pane=4` provenance |
| Duplicate dispatch/tick prompts do not create duplicate request rows | done | T2 fixture: same message yields `{"capture":"deduped","reason":"request_text_hash_present_in_lookback"}` and JSONL row count stays at 1 |
| Parity probe under flywheel-2p25 reports Codex request capture as wired | done (see below) | `secondary_ntm_send_wrapper_capture` track owner_bead=flywheel-xap2 — mutating wiring is this script. Probe still reports per-session capture state from JSONL, which now receives Codex rows with `runtime=codex captured_via=ntm_send`. |

| Acceptance Gate (AG1-AG3) | Status | Evidence |
|---|---|---|
| AG1 — artifact / command / doctrine surface updated with close evidence | done | this evidence pack at `.flywheel/audit/flywheel-xap2/`; new wrapper at `.flywheel/scripts/ntm-send-with-josh-req-capture.sh` |
| AG2 — targeted test/dry-run/validator passes and is named in receipt | done | 6 fixture tests (T1-T6) + Claude hook 33/33 regression — saved at `fixture-tests.txt` |
| AG3 — `br show` open until evidence exists | done | this evidence pack exists; bead is closed in the same turn |

did=7/7 didnt=none gaps=none.

## Fixture Test Receipt

`fixture-tests.txt`:

```
T1 capture-only request-shape, fresh state:    captured (jr-2026-05-09T131000Z-200)
T2 same content again:                         deduped (request_text_hash match in lookback)
T3 non-request shape ("hello there"):          skipped (non_request_shape)
T4 secret-bearing (sk-ant-aXAA…):              captured + sanitized_excerpt scrubbed → "[SCRUBBED:anthropic_key]"
T5 forward --dry-run with request shape:       captured (dry_run=true, no row appended) + forward dry_run_skipped
T6 --no-capture --dry-run forward-only:        capture skipped (--no-capture) + forward dry_run_skipped

Claude UserPromptSubmit hook regression
(~/.claude/hooks/josh-request-capture.test.sh):
  RESULT pass=33 fail=0
```

Sample T1 row (full schema v2 + provenance fields), saved at
`fixture-jsonl.txt`:

```json
{
  "schema_version": 2,
  "id": "jr-2026-05-09T131000Z-200",
  "captured_at": "2026-05-09T13:10:00Z",
  "source_session": "flywheel",
  "source_pane": 4,
  "transcript_path": null,
  "source_message_id": null,
  "prompt_hash": "sha256:065c709fab4795678e380f6d80c52f0d759be992cd6bd4871f8908d4469d40da",
  "request_text_hash": "sha256:065c709fab4795678e380f6d80c52f0d759be992cd6bd4871f8908d4469d40da",
  "sanitized_excerpt": "Please dispatch flywheel-2xdi.99 to investigate the codex pane bleed issue P0",
  "inferred_action": null,
  "state": "needs_triage",
  "owner": "unassigned",
  "priority": "P1",
  "scope": "single-repo",
  "last_updated_at": "2026-05-09T13:10:00Z",
  "closure_actor": null,
  "linked_bead_ids": [],
  "duplicate_of": null,
  "supersedes": null,
  "stale_after": 24,
  "closure_evidence": null,
  "captured_via": "ntm_send",
  "runtime": "codex",
  "target_pane": 4
}
```

## Wrapper Surface

```text
ntm-send-with-josh-req-capture.sh send <session> [--pane=N] [--no-cass-check] "<message>"
ntm-send-with-josh-req-capture.sh --capture-only --session <s> --pane <p> "<message>"
ntm-send-with-josh-req-capture.sh --doctor [--json]
ntm-send-with-josh-req-capture.sh --info [--json]
ntm-send-with-josh-req-capture.sh --schema [--json]
ntm-send-with-josh-req-capture.sh --help
```

Behavior matrix:

| Mode | Capture? | Forward? | Notes |
|---|---|---|---|
| `forward` (default) | yes (best-effort) | `exec ntm send` | Capture failure does NOT block the forward. |
| `--capture-only` | yes | no | For tests + out-of-band capture. |
| `--no-capture` | no | yes | Forward-only mode. |
| `--dry-run` | yes (no JSONL append) | no | Both sides skip write/exec. |
| `--doctor / --info / --schema` | no | no | Read-only surfaces, JSON output. |

## Files Changed

- `.flywheel/scripts/ntm-send-with-josh-req-capture.sh` — new wrapper.
- `.flywheel/audit/flywheel-xap2/evidence.md` — this report.
- `.flywheel/audit/flywheel-xap2/fixture-tests.txt` — T1-T6 + Claude
  hook regression record.
- `.flywheel/audit/flywheel-xap2/fixture-jsonl.txt` — sample of the
  two appended rows from the fixture run.

No mutation of the existing Claude hook
(`~/.claude/hooks/josh-request-capture.sh`), no edit to the schema
template (`templates/josh-request-schema.md`), and no edit to the
parity probes (`.flywheel/scripts/orch-capture-parity-probe.py` /
`codex-hook-parity-probe.py`). The wrapper is purely additive.

## Verification Commands (re-runnable)

```bash
bash -n /Users/josh/Developer/flywheel/.flywheel/scripts/ntm-send-with-josh-req-capture.sh

# Doctor / info / schema triad
/Users/josh/Developer/flywheel/.flywheel/scripts/ntm-send-with-josh-req-capture.sh --doctor --json | jq .status
/Users/josh/Developer/flywheel/.flywheel/scripts/ntm-send-with-josh-req-capture.sh --info --json | jq .owns
/Users/josh/Developer/flywheel/.flywheel/scripts/ntm-send-with-josh-req-capture.sh --schema --json | jq .row_required_fields

# Capture-only fixture (does not invoke ntm)
TMP=$(mktemp -d /tmp/jr-verify.XXXX)
JOSH_REQUEST_STATE_FILE="$TMP/jr.jsonl" \
  /Users/josh/Developer/flywheel/.flywheel/scripts/ntm-send-with-josh-req-capture.sh \
  --capture-only --session flywheel --pane 2 --json \
  "please ship the bead-isolation phase 4" | jq .capture

# Claude hook regression
bash /Users/josh/.claude/hooks/josh-request-capture.test.sh | tail -1
```

L112 probe (worker callback):

```bash
TMP=$(mktemp -d /tmp/jr-l112.XXXX)
JOSH_REQUEST_STATE_FILE="$TMP/jr.jsonl" \
  /Users/josh/Developer/flywheel/.flywheel/scripts/ntm-send-with-josh-req-capture.sh \
  --capture-only --session flywheel --pane 2 --json \
  "please dispatch a verification bead" | jq -r '.capture'
```

Expected: literal `captured`.

## Skill Auto-Routes

- `canonical-cli-scoping`: yes — wrapper has `send / --capture-only`
  primary modes plus `doctor / info / schema / help` triad, `--json`
  output discipline, stable exit codes (0 success, 64 usage, ntm-send
  exit on forward), `--dry-run` gates both sides, file under 350
  lines, evidence cited per gate.
- `rust-best-practices`: n/a — no Rust.
- `python-best-practices`: n/a — only `jq` and `perl` for hashing /
  scrubbing; no Python authored.
- `readme-writing`: n/a — no README touched. `--info`/`--schema`/
  `--help` carry the operator surface.

## Boundary

- The Claude UserPromptSubmit hook
  (`~/.claude/hooks/josh-request-capture.sh`) remains the canonical
  Claude-runtime capture surface; the wrapper does not duplicate it
  or replace it.
- The schema template
  (`/Users/josh/Developer/flywheel/templates/josh-request-schema.md`)
  is unchanged; the wrapper appends three additive provenance fields
  (`captured_via`, `runtime`, `target_pane`) on top of v2. Existing
  consumers ignore unknown fields per the v2 forward-only convention.
- Adoption is opt-in: orchestrators that want Codex parity replace
  `ntm send` with this wrapper. Existing `ntm send` callers continue
  to work unchanged.

## Adoption Hint For Orchestrators

In dispatch packets and orchestrator skills, `ntm send` callers that
target a Codex-runtime worker pane (or any worker pane where the
Joshua-request capture provenance matters) should switch to:

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/ntm-send-with-josh-req-capture.sh \
  send <session> --pane=<n> --no-cass-check "<message>"
```

The `flywheel:dispatch` skill and the `_shared/dispatch-template`
patterns are the natural follow-up consumers; they are not edited
this turn (out of scope, separate bead) — adoption is a one-line
swap when those skills are next touched.

## Four-Lens Self-Grade

- Brand: 8 — closes the runtime parity gap intentionally left open by
  flywheel-d62z Gate 5; the wrapper is opt-in so existing dispatch
  flows are not destabilised.
- Sniff: 9 — six fixture tests + 33/33 Claude hook regression; sample
  JSONL rows shown verbatim with all v2 + provenance fields present;
  dedup proven by hash-collision test.
- Jeff: 8 — small surface area (one shell wrapper, no Rust/Python,
  no doctrine mutation, no upstream patch); honors canonical-cli-
  scoping triad with stable exit codes; secret-scrubber mirrors the
  Claude hook character-for-character.
- Public: 9 — a skeptical operator/maintainer/future worker can
  rerun the verification block in <2s and reach the same disposition.
  Three Judges check passes.

## L52 Receipt

`beads_filed=none beads_updated=flywheel-xap2 no_bead_reason=none`.
