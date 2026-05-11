# flywheel-n4gt1 — canonical-cli-scoping SKILL.md bash-regex T9 wire-in (Joshua-authorized cross-repo execution)

Bead: flywheel-n4gt1 (P3)
Parent audit: flywheel-898ji (P3 CLOSED 2026-05-11)
META-RULE origin: flywheel-1hshd.37 (`validate receipt-ref` discovery)
Memory anchor: `feedback_bash_regex_no_brace_repetition.md`
Lane: cross-repo-wire-in / direct-mutation-with-patch-artifact
mutates_state: yes (target: `~/.claude/skills/canonical-cli-scoping/SKILL.md`; +patch artifact in flywheel.git)
Authorization: dispatch packet §"JOSHUA-AUTHORIZED CROSS-REPO MUTATION" (2026-05-11), precedent flywheel-2xdi.60.1

## Pre-flight verification

| Check | Result |
|---|---|
| Bead present in local DB | `present` |
| `br dep tree flywheel-n4gt1` | parent `flywheel-898ji` shown CLOSED |
| `jsm list \| grep canonical` | EMPTY (skill NOT registered) |
| `jsm show canonical-cli-scoping` | `Skill 'canonical-cli-scoping' not found.` |
| L107 reservation | RESERVED via `shared-surface-reservation-check.sh --reserve` |

Per dispatch packet authorization block: jsm-unmanaged → direct mutation ALLOWED
when paired with jsm-import-ready patch artifact. Confirmed; proceeding with
direct mutation.

## Mutation applied to `~/.claude/skills/canonical-cli-scoping/SKILL.md`

Three additive edits, no removals or reflows:

1. **Trap class table T9 row** (after T8 at line 786, before `### Stdin-only secret writes`):
   - Violating pattern: `[[ "$arg" =~ ^[A-Za-z0-9._/#:-]{4,256}$ ]]`
   - Canonical pattern: two-check form `(( len >= 4 && len <= 256 )) && [[ "$arg" =~ ^[A-Za-z0-9._/#:-]+$ ]]` with `observed_length:$len` in reject envelope
   - Why non-obvious: bash `=~` uses POSIX ERE which lacks `{N,M}`; runtime error `bash: invalid repetition count(s)`
   - Evidence cites: `feedback_bash_regex_no_brace_repetition.md` + `.flywheel/audit/flywheel-1hshd.37/evidence.md` + `.flywheel/scripts/idempotency-replay-guard.sh:280`

2. **New subsection** `### Bash regex \`=~\` no \`{N,M}\` repetition (canonical two-check form)`
   inserted after `### Codex chevron-template trap` and before `### \`br create\` body discipline`. Includes:
   - Side-by-side FORBIDDEN vs CANONICAL bash blocks
   - Three-bullet explanation of why operators step on this trap
   - Canonical JSON reject envelope shape mirroring `idempotency-replay-guard.sh:280`
   - Discovery + production reference + cross-link bead pointers

3. **Universal-class summary line update** (line 990): appended `bash \`=~\` \`{N,M}\` runtime trap (T9)` to the list of canonical trap classes covered by this skill.

Pre-edit hash: `d5dd78a4fd39739b0739007a666f806ee8617afc345690cdd2f4589ff945b15b`
Post-edit hash: `f34e58ee51d1f9b5435dfb4f25060441c508ae11d8342fae0e3139704f10d3b4`
Line count: 1040 → 1110 (+70 lines, well under §"File-Length Thresholds" 1500-line markdown threshold)

## Patch artifact (JSM-import-ready)

| Artifact | Purpose |
|---|---|
| `.flywheel/audit/flywheel-n4gt1/patches/SKILL.md.original` | Pre-mutation snapshot (hash `d5dd78a4…`) |
| `.flywheel/audit/flywheel-n4gt1/patches/SKILL.md.proposed` | Post-mutation snapshot (hash `f34e58ee…`) |
| `.flywheel/audit/flywheel-n4gt1/patches/SKILL.md.patch` | Unified diff (96 lines) |
| `.flywheel/audit/flywheel-n4gt1/patches/apply-instructions.md` | Replay + skillos-side commit guidance |

The patch artifact lives in flywheel.git so the change can be replayed if the
skillos working tree is reverted, OR imported into JSM if `canonical-cli-scoping`
later becomes managed.

## Cross-repo boundary

- Working-tree mutation happened in the skillos repo (`~/.claude/skills/`).
- Skillos repo currently shows `M canonical-cli-scoping/SKILL.md` (modified, uncommitted).
- Per `project_skillos_separated`, flywheel:1 does NOT commit to the skillos repo. Skillos:1 (or next `.claude/` worker session) owns the commit decision. Suggested commit message in `apply-instructions.md`.
- All audit + patch artifacts live in flywheel.git per orchestrator-owned-history discipline.

## Acceptance gates

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | SKILL.md updated with bash-regex gotcha callout | **DONE** | 3 additive edits applied; T9 row in trap table + dedicated subsection + universal-class summary line update. Verification probe passes (callout_present). |
| AG2 | Cite memory + origin bead evidence | **DONE** | T9 row Evidence column + subsection §"Discovery and references" cite: `feedback_bash_regex_no_brace_repetition.md` + `.flywheel/audit/flywheel-1hshd.37/evidence.md` + `.flywheel/scripts/idempotency-replay-guard.sh:280` (production load-bearing). |
| AG3 | (from packet §"Required deliverable") Verify with 2-check pattern probe | **DONE** | `grep -q "invalid repetition count" SKILL.md && grep -q "len >= " SKILL.md && echo callout_present` → `callout_present`. |
| AG4 | (from packet §"Required deliverable") Paired patch artifact | **DONE** | `.original` + `.proposed` + `.patch` + `apply-instructions.md` written under `.flywheel/audit/flywheel-n4gt1/patches/`. |
| AG5 | L107 reserve before mutation | **DONE** | Reservation logged via `shared-surface-reservation-check.sh --reserve /Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md`. Release post-commit. |

## Files touched

| Path | Δ | Repo |
|---|---|---|
| `~/.claude/skills/canonical-cli-scoping/SKILL.md` | +70 lines (additive only) | skillos (peer-orch) |
| `.flywheel/audit/flywheel-n4gt1/evidence.md` | NEW | flywheel.git |
| `.flywheel/audit/flywheel-n4gt1/patches/SKILL.md.original` | NEW | flywheel.git |
| `.flywheel/audit/flywheel-n4gt1/patches/SKILL.md.proposed` | NEW | flywheel.git |
| `.flywheel/audit/flywheel-n4gt1/patches/SKILL.md.patch` | NEW | flywheel.git |
| `.flywheel/audit/flywheel-n4gt1/patches/apply-instructions.md` | NEW | flywheel.git |
| `.flywheel/lock-log.jsonl` | +2 rows (reserve + release) | flywheel.git |

`PICOZ_WORKER_FILES`:
```
/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md
/Users/josh/Developer/flywheel/.flywheel/audit/flywheel-n4gt1/evidence.md
/Users/josh/Developer/flywheel/.flywheel/audit/flywheel-n4gt1/patches/SKILL.md.original
/Users/josh/Developer/flywheel/.flywheel/audit/flywheel-n4gt1/patches/SKILL.md.proposed
/Users/josh/Developer/flywheel/.flywheel/audit/flywheel-n4gt1/patches/SKILL.md.patch
/Users/josh/Developer/flywheel/.flywheel/audit/flywheel-n4gt1/patches/apply-instructions.md
/Users/josh/Developer/flywheel/.flywheel/lock-log.jsonl
```

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: This bead IS the execution per packet §"Do NOT defer to sister bead". No follow-up bead filed; AG3 follow-up option (corpus-wide bash `{N,M}` lint) remains optional per parent flywheel-898ji evidence — not auto-filed.

## Skill auto-routes addressed

- **canonical-cli-scoping=yes** — this bead IS a `canonical-cli-scoping` SKILL.md edit. Compliance: SKILL.md stays under §"File-Length Thresholds" 1500-line markdown threshold (1110 lines). T9 row format matches T1-T8 column shape; subsection format matches existing trap-class subsections. `--info`/`--examples`/etc. unchanged. Edit is doctrine-additive only.
- **rust-best-practices=n/a** — no Rust code touched.
- **python-best-practices=n/a** — no Python code touched.
- **readme-writing=n/a** — not a README edit; SKILL.md is internal skill doctrine. Public-facing readme-quality discipline does not apply.

## Four-Lens Self-Grade

- **brand** (10): direct mutation paired with full JSM-import-ready patch artifact per dispatch packet authorization + 2xdi.60.1 precedent. No silent edit; pre/post snapshots + unified diff + apply-instructions. Boundary discipline: skillos-side commit deferred to skillos:1 (flywheel:1 doesn't write commits to peer-orch repo).
- **sniff** (10): empirical — jsm-unmanaged status verified (`jsm list \| grep canonical` empty + `jsm show canonical-cli-scoping` returned "not found"); pre/post hashes captured; verification grep run + passes; line-count compliance with own file-length doctrine verified.
- **jeff** (10): additive-only edit (no existing content removed or reflowed); no scope creep (didn't touch the optional corpus-wide bash lint follow-up); patch artifact is reversible (atomic replay path documented in apply-instructions).
- **public** (10): Three Judges —
  - Skeptical operator: verification probe is exact-match grep returning `callout_present`; pre/post hashes provided; patch is unified diff readable in any text editor.
  - Maintainer: apply-instructions.md documents replay path, skillos-side commit message, and JSM-import path; T9 row format consistent with T1-T8 column shape.
  - Future worker: T9 row is alphabetically/numerically ordered after T8; new subsection inserted between existing subsections preserves doctrine reading flow; universal-class summary line update means dispatch packets that cite "T1-T8" remain accurate when re-rendered against the updated skill.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1 SKILL.md mutation: DONE. ✓
- AG2 memory + origin citations: DONE. ✓
- AG3 verification probe passes: DONE (`callout_present`). ✓
- AG4 jsm-import-ready patch artifact: DONE (4 files). ✓
- AG5 L107 reserve+release: DONE. ✓
- File-length compliance with own skill: 1110 < 1500 mkdown threshold. ✓
- Patch artifact reversibility: pre/post hashes + apply-instructions. ✓
- Cross-repo boundary: skillos commit deferred to skillos:1. ✓

cli_canonical=yes
rust_clean=n/a
python_clean=n/a
readme_quality=n/a

## L112 probe

Command:
```bash
SKILL=/Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md; \
grep -q "invalid repetition count" "$SKILL" && grep -q "len >= " "$SKILL" && echo callout_present || echo callout_missing
```
Expected: `literal:callout_present`
Timeout: 5 seconds

## Replay verification (operator audit)

```bash
# Confirm working-tree hash matches .proposed snapshot
WT_HASH=$(shasum -a 256 /Users/josh/.claude/skills/canonical-cli-scoping/SKILL.md | cut -d' ' -f1)
SNAPSHOT_HASH=f34e58ee51d1f9b5435dfb4f25060441c508ae11d8342fae0e3139704f10d3b4
[ "$WT_HASH" = "$SNAPSHOT_HASH" ] && echo working_tree_matches_proposed || echo working_tree_drift
```
Expected: `literal:working_tree_matches_proposed`
