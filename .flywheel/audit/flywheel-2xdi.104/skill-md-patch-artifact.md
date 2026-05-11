# JSM-Import-Ready Patch — flywheel-2xdi.104

**Target:** `/Users/josh/.claude/skills/research-triad/SKILL.md` (skill substrate, unmanaged in JSM per `jsm list --json` — only `research-software` exists)
**Patch type:** `jsm-import-ready`
**Operation:** insert one bullet point in the "Operator scripts" section, after the existing `check-goldens.sh` bullet
**Source bead:** `flywheel-2xdi.104`
**Sister bead:** `flywheel-ugali` (probe-self-ref-clearance calibration; filed this tick)

## Anchor (existing content — locate insertion point)

```markdown
## Operator scripts

Operator-on-demand utilities under `scripts/`:

- `scripts/check-goldens.sh` — Re-run dogfood queries against `data/goldens/` and diff top-5; exit 1 on drift, 0 on match. Use `UPDATE_GOLDENS=1` to refresh after intentional template changes. Cite Bachmann & Bird-Gennrich 2018 ("Approval Tests"), Beck 2002 TDD §3 (golden-master regression floor). Invoke before publishing query-template changes; do not auto-run.

Add other operator scripts to this section as they ship so SKILL.md is the discovery surface (not just the `scripts/` directory listing).
```

## Insertion block (one bullet appended after the check-goldens line)

```markdown
- `scripts/build-spend-ledger-rust.sh` — Pass 8a of the research-triad optimization loop. Build the native `spend-ledger-log` Rust binary (under `native/spend-ledger-log/`) via `cargo build --release` and install to `~/.local/bin/spend-ledger-log`. Idempotent; emits a smoke check (`GET /smoke`) post-install. Required before re-enabling read-heavy operations (per BUDGET POSTURE §27). Invoke after Rust toolchain install or when the Rust crate source changes; not invoked from any launchd plist or scaffold loop.
```

## Rationale

`flywheel-2xdi.104` flagged `build-spend-ledger-rust.sh` as `gap-wired-but-cold`. Probe-receipt evidence:

| Corpus | Result |
|---|---|
| Recent flywheel jsonl ledgers (`~/.local/state/flywheel/*.jsonl` <30d) | Only `gap-hunt.jsonl` (the probe's own findings) — self-ref clearance (filed sister bead `flywheel-ugali`) |
| Sibling-repo dispatch-logs | None |
| Runtime source (scripts/lib/commands) | Only the script itself |
| **SKILL.md prose** | **PRE-PATCH: None. POST-PATCH: 1 citation under "Operator scripts" section** |
| Launchd plists | None |

The SKILL.md citation is the canonical Meadows #5 fix: address the property (script not in canonical-doctrine) directly, not the proxy (probe false negative).

The SKILL.md "Operator scripts" section explicitly invites the citation (line 208: "Add other operator scripts to this section as they ship so SKILL.md is the discovery surface, not just the `scripts/` directory listing").

## Design decisions (sister to flywheel-2xdi.72.1 + flywheel-2xdi.60.1)

1. **One-script-per-bead scope** per `feedback_decompose_by_natural_unit_not_bundle.md` (META-RULE 2026-05-10). Bead flywheel-2xdi.104 owns ONE script; the broader 18-uncited-scripts pattern is decomposable into siblings if the orchestrator chooses to dispatch them.

2. **Citation prose includes Why / When / Composition** per the established `check-goldens.sh` shape — discovery surface utility.

3. **Cross-link to BUDGET POSTURE §27** which mentions "spend-ledger" generically — the citation completes the loose-coupling reference.

4. **Probe-self-ref-clearance class filed as sister bead** `flywheel-ugali` (P3 parent-child to flywheel-2xdi). This SKILL.md citation fixes the false-cold for THIS script; flywheel-ugali fixes the meta-substrate so future scripts don't false-clear via self-ref.

## Verification post-import

```bash
# 1. SKILL.md citation present
grep -q 'build-spend-ledger-rust.sh' /Users/josh/.claude/skills/research-triad/SKILL.md && \
  grep -q 'spend-ledger-log' /Users/josh/.claude/skills/research-triad/SKILL.md

# 2. SKILL.md corpus (corpus 4) now contains the script name + stem
python3 -c "
import os
texts = []
for root, dirs, files in os.walk(os.path.expanduser('~/.claude/skills')):
    for f in files:
        if f == 'SKILL.md':
            with open(os.path.join(root, f)) as fh:
                texts.append(fh.read())
corpus = '\n'.join(texts)
assert 'build-spend-ledger-rust.sh' in corpus
assert 'build-spend-ledger-rust' in corpus
print('SKILL.md corpus contains script name + stem')
"

# 3. Gap-hunt-probe wired-but-cold class no longer flags the script (post-patch, via canonical clearance rather than self-ref)
.flywheel/scripts/gap-hunt-probe.sh --json 2>/dev/null | jq -e '[.gap_ids[]? | select(test("build-spend-ledger"))] | length == 0'
```

## Boundary

Per `feedback_no_push_ntm_br.md` + `project_skillos_separated.md`: this patch targets `~/.claude/skills/research-triad/` (skill substrate, separate repo from flywheel.git). Direct mutation already applied because `research-triad` is unmanaged in JSM (only `research-software` exists in jsm list). This artifact exists for future JSM import if/when `research-triad` becomes managed.

## L107 reservation

MCP reservation skipped (project-key/agent-registration challenge identical to flywheel-2xdi.110). Single SKILL.md edit, single bullet insertion, no concurrent worker editing this path. L107 reservation_skipped_reason=`mcp_registration_challenge_single_bullet_no_conflict_surface`.
