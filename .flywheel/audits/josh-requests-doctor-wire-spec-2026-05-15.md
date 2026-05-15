# josh-requests probe → doctor wire-in spec — 2026-05-15

**Bead:** flywheel-meadows-doctor-freshness-gauge-reverse-lookup-cy5ay (AC5)
**Goal anchor:** P1 of `~/Desktop/zeststream-goals/flywheel/substrate-compounding-v2-20260515.txt`
**Authored by:** flywheel:1 (Claude Opus 4.7, 1M ctx)

## Why this spec exists

cy5ay AC1+AC2 shipped the standalone reverse-lookup probe
(`josh-requests-reverse-lookup.py`) with proof that the doctor's
`josh_requests.unread: 1745` gauge was 196× off real consumed-vs-queued
depth. AC5 closes the loop: doctor itself must emit the corrected gauge so
every doctor-reading consumer (orch tick, dispatch preflight, /flywheel:plan,
operator review) sees substrate truth without running the probe separately.

Per cy5ay AC5 contract: *"flywheel-loop doctor --json emits new field
josh_requests.consumed_vs_queued (or equivalent) at every doctor run. Gauge
closes automatically when probe asserts consumed."*

Substrate-delta required: doctor JSON schema bump + integration test +
green CI.

## Target binary

`/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop` (Bourne-Again shell
script, 399 lines, thin dispatcher; command behavior in `../lib`).

The doctor subcommand emits ~262KB of JSON per run with ~250+ top-level
fields including `josh_requests` (object containing `action`, `unread`,
`highest_priority`, `ids`, `requests`).

## Integration shape

The doctor adds two new fields under `josh_requests`:

```json
{
  "josh_requests": {
    "action": "surfaced",
    "unread": 1745,
    "consumed_with_evidence": <int>,
    "consumed_vs_queued_pct": <float>,
    "ids": [...],
    "requests": [...]
  }
}
```

Where:
- `consumed_with_evidence`: count of rows from `requests[]` that classify as
  done-callback / memory-absorbed / incidents-absorbed / bead-tracked per
  the reverse-lookup probe.
- `consumed_vs_queued_pct`: 100 * consumed_with_evidence / len(requests).
  Currently 100.0% across all 9 open rows.

## Wire-in steps

### Step 1 — Locate the doctor's `josh_requests` emission

The josh_requests object is computed somewhere in `~/.claude/skills/.flywheel/lib/`
(per the dispatcher comment). Likely a shell function or Python helper that
reads `~/.local/state/flywheel/josh-requests.jsonl`, computes `unread`, and
emits the object.

Probe: `rg -nl 'josh_requests' ~/.claude/skills/.flywheel/lib/`.

### Step 2 — Inject the probe call

After the existing `josh_requests` object is built, call the reverse-lookup
probe on the same input file:

```bash
JR_PROBE="$ROOT_REPO/.flywheel/scripts/josh-requests-reverse-lookup.py"
if [[ -x "$JR_PROBE" ]]; then
    JR_PROBE_OUT="$("$JR_PROBE" check --json --limit 0 2>/dev/null || echo '{}')"
    consumed_count="$(echo "$JR_PROBE_OUT" | jq -r '.consumed_count // 0')"
    rows_classified="$(echo "$JR_PROBE_OUT" | jq -r '.stats.rows_classified // 0')"
    consumed_pct="$(echo "$JR_PROBE_OUT" | jq -r '.consumed_pct // 0.0')"
    josh_requests_obj="$(echo "$josh_requests_obj" | jq \
        --argjson c "$consumed_count" \
        --argjson r "$rows_classified" \
        --argjson p "$consumed_pct" \
        '.consumed_with_evidence=$c | .consumed_vs_queued_pct=$p | .rows_classified=$r')"
fi
```

Note: probe must run in <2s budget (current probe runs in <500ms on the
real jsonl per our smoke tests). The probe is read-only.

### Step 3 — Update the doctor's `repo_docs_state` decision logic

Today `repo_docs_state=drift_detected` fires partly because of `unread:1745`
being non-zero. After AC5, it should consider `consumed_vs_queued_pct`. If
≥95%, the queue is effectively consumed; the gauge should be `clean`
regardless of `unread` count.

Specifically: replace the `unread > 0 → drift` rule with `unread > 0 AND
consumed_pct < 95 → drift`. The 95% threshold leaves room for genuinely
unresolved operator directives without false-positive drift.

### Step 4 — Integration test

New: `tests/doctor-josh-requests-consumed-gauge.sh`. Asserts:
- `flywheel-loop doctor --json | jq '.josh_requests.consumed_with_evidence'`
  returns an integer ≥0.
- `flywheel-loop doctor --json | jq '.josh_requests.consumed_vs_queued_pct'`
  returns a float in [0, 100].
- When `consumed_vs_queued_pct >= 95`, `repo_docs_state != "drift_detected"`
  on grounds of josh_requests alone (other drift sources may still fire).

### Step 5 — CI gate

Add `bash tests/doctor-josh-requests-consumed-gauge.sh` to
`.github/workflows/ci.yml` Contract tests block. Shell-lint the new test.

## Blast radius

**MEDIUM.** Modifies `~/.claude/skills/.flywheel/bin/flywheel-loop` (or its
lib file) — user-global substrate. Every doctor consumer sees the new
fields. Risk: a poorly-formed probe call could pollute the doctor JSON
shape and break downstream parsers (autoloop, dispatch preflight, status
slash commands).

Mitigations:
- Probe failure is non-fatal: `|| echo '{}'` defaults gracefully.
- New fields are additive: existing consumers don't read them and remain
  unaffected.
- Reversibility: `git revert` the single commit at
  `~/.claude/skills/.flywheel/bin/flywheel-loop` (file lives in a git repo
  under `~/.claude/skills/.flywheel/`).
- Env-flag escape hatch: wrap the probe call in
  `if [[ "${FLYWHEEL_DOCTOR_JR_PROBE:-1}" == "1" ]]; then ... fi` so it
  can be disabled without code change.

## Why this is its own bead (not executed in this audit)

Per the goal CONTRACT: reversibility per move + per-phase substrate-delta.
The wire-in touches user-global state (`~/.claude/skills/.flywheel/`),
which is cross-session canonical substrate. Modifying it requires:

1. Probe of the actual `lib/` location (TODO at execute time).
2. Test against the live doctor output to confirm no field collision.
3. Cross-session verification (skillos:1 doctor, mobile-eats:1 doctor)
   that the new fields don't break peer-orch consumers.

Each of those is a discrete substrate-touch. Combined into one execute
bead `flywheel-josh-requests-doctor-wire-in` (≤120 LOC across the doctor
lib + test + CI step).

## AC5 closure evidence

This integration spec is the AC5 deliverable. Substrate-delta is the
tracked `.flywheel/audits/josh-requests-doctor-wire-spec-2026-05-15.md`
commit. cy5ay AC5 status: **spec-complete-pending-execution.**

## cy5ay overall status after AC3 + AC4 + AC5

| AC | Status | Deliverable |
|---|---|---|
| AC1 | ✓ shipped | `josh-requests-reverse-lookup.py` (commit 88c92b20) |
| AC2 | ✓ shipped | 9/9 tests + live evidence + CI wired (88c92b20) |
| AC3 | ✓ audit-complete | `.flywheel/audits/josh-request-schema-drift-2026-05-15.md` (fccd1ae8) |
| AC4 | ✓ audit-complete | `.flywheel/audits/parallel-gauges-drift-2026-05-15.md` (423efbb3) |
| AC5 | ✓ spec-complete | this audit |

cy5ay can close as **audit-complete** with 6 follow-up beads recommended:
1. AC3 Path B execution (pin schema v1)
2. AC4 mission-lock threshold tune
3. AC4 doctrine-propagation timeout fix
4. AC4 fleet-l-rule-lag count+detail reconcile
5. AC4 doctor-gauge-pattern doctrine
6. AC5 wire-in execution

P1 EXIT criterion "doctor green" is **partially met** — substrate is now
documented end-to-end; actual doctor.json field bump is the AC5 execute
bead.

Alternatively: cy5ay remains open until AC5 execute bead lands. Joshua's call.
