# flywheel-mv2th — Evidence Pack

**Bead:** flywheel-mv2th (P2; Phase 1 of flywheel-38u3d chain)
**Title:** flywheel docs init subcommand + project-type detection
**Mission fitness:** `adjacent` — adds new canonical-cli surface to flywheel binary
**Sister chain:** mv2th → ti46c (Phase 2) → sjr9e (Phase 3) → ll107 (Phase 4)
**Substrate class:** Class 1 (`.flywheel` is jsm-unmanaged)

## Acceptance gates (5/5)

| # | Gate | Status |
|---|---|---|
| AG1 | `flywheel docs init` subcommand added to bin/flywheel with canonical-cli L1-L9 compliance | DONE — `scaffold_cmd_docs` + `scaffold_cmd_docs_init` added; wired into `scaffold_main` case + `_scaffold_is_canonical_arg` allowlist; matches existing 9-subcommand surface |
| AG2 | Project-type detection per PROJECT-TYPES.md heuristics (5 archetypes) | DONE — `scaffold_docs_detect_project_type` returns rust-lib / python-lib / ts-lib / frontend-spa / backend-service or unknown |
| AG3 | Regression test: `flywheel docs init --help` shows usage + project-type detection returns one of 5 archetypes | DONE — 18/18 PASS in `tests/flywheel-docs-canonical-cli.sh` |
| AG4 | `flywheel --help` enumerates `docs` subcommand | DONE — usage text updated (line 41 of scaffold_usage); topic-help list also updated |
| AG5 | Class 1 paired jsm-import-ready patch artifact | DONE — `.flywheel/audit/flywheel-mv2th/patches/` with flywheel.original (4712L) + flywheel.proposed (4894L) + flywheel.patch (217L diff) + apply-instructions.md |

## What I shipped

### Direct mutation (Class 1)

`~/.claude/skills/.flywheel/bin/flywheel` — 4 new functions added + 3 wire-in changes:

1. `scaffold_docs_detect_project_type()` — pure-bash heuristic
2. `scaffold_docs_usage()` — usage block with cross-refs
3. `scaffold_cmd_docs_init()` — Phase 1 implementation (detection-only; `mutates_state=false`)
4. `scaffold_cmd_docs()` — subcommand dispatcher
5. Wired into `scaffold_main` case statement (between `why` and `quickstart`)
6. Wired into `_scaffold_is_canonical_arg` allowlist
7. Updated `scaffold_usage` text + topic-help list

Net: 4712 → 4894 lines (+182).

### Paired patch artifact

`.flywheel/audit/flywheel-mv2th/patches/`:
- `flywheel.original` (4712 lines pre-mutation)
- `flywheel.proposed` (4894 lines post-mutation)
- `flywheel.patch` (217-line unified diff)
- `apply-instructions.md` (apply + verify + rollback + phase-chain context)

### Regression test

`tests/flywheel-docs-canonical-cli.sh` (170 lines, 18/18 PASS):
- Syntax check
- `--help` enumerates docs subcommand
- `docs --help` shows init + archetype info
- `docs init --help` shows usage
- 5 archetype detection fixtures (rust-lib, python-lib, ts-lib, frontend-spa, backend-service)
- nonexistent dir → unknown
- `--archetype` override skips detection
- unknown arg rejection
- Phase 1 `mutates_state=false` assertion
- JSON envelope cites parent + phase + next_phase chain
- **3 no-regression sanity checks** (doctor / health / audit subcommands still work)

## Verification

```bash
$ bash -n ~/.claude/skills/.flywheel/bin/flywheel && echo SYNTAX_OK
SYNTAX_OK

$ ~/.claude/skills/.flywheel/bin/flywheel --help | grep "docs <subcommand>"
  docs <subcommand>        documentation scaffold (init: detect project type)

$ ~/.claude/skills/.flywheel/bin/flywheel docs init --target /tmp/nonexistent | jq -r '.archetype'
unknown

$ bash tests/flywheel-docs-canonical-cli.sh | tail -1
SUMMARY pass=18 fail=0
```

## DID / DIDNT / GAPS

- **DID 5/5** — all 5 acceptance gates met
- **DIDNT none** (Phase 1 scope is intentionally narrow; Phase 2-4 deliverables tracked by sub-beads ti46c/sjr9e/ll107)
- **GAPS none**

## Files Changed

- `~/.claude/skills/.flywheel/bin/flywheel` (+182 lines net)
- `tests/flywheel-docs-canonical-cli.sh` (new, 170 lines, 18/18 PASS)
- `.flywheel/audit/flywheel-mv2th/patches/{flywheel.original,flywheel.proposed,flywheel.patch,apply-instructions.md}`
- `.flywheel/audit/flywheel-mv2th/{evidence.md,compliance-pack.md}`
- `.flywheel/journal/flywheel-mv2th.md`

## L112 Probe

- `l112_probe_command`: `bash /Users/josh/Developer/flywheel/tests/flywheel-docs-canonical-cli.sh | tail -1`
- `l112_probe_expected`: `grep:pass=18 fail=0`
- `l112_probe_timeout_sec`: `60`

## Pattern note

This is the **first phase of a 4-phase chain** filed via decline-with-decomposition (flywheel-38u3d). Phase 1 establishes the canonical-cli surface; subsequent phases wire actual scaffolding + dogfood + multi-repo rollout.

The `mutates_state=false` field in the Phase 1 JSON envelope is a deliberate signal — Phase 1 is detection-only; Phase 2 (ti46c) will flip this to true when the actual scaffold-nextra.sh invocation lands.

Filed `no_direct_skill_mutation_reason=jsm_unmanaged_with_paired_jsm_import_ready_patch_artifact_written`.

## Four-Lens Self-Grade

- **brand:** 10 — Class 1 discipline preserved (direct mutation + paired patch); 5-archetype taxonomy matches bead-body spec
- **sniff:** 10 — 18/18 test PASS including 3 no-regression sanity checks; synthetic fixtures cover all 5 archetypes
- **jeff:** 9 — Class 3 read-class consumer pattern preserved (cites `scaffold-nextra.sh` + `PROJECT-TYPES.md` paths without consuming them in Phase 1)
- **public:** 10 — future Phase 2 worker has clear handoff: same surface, just wire `scaffold-nextra.sh` invocation through the existing `scaffold_cmd_docs_init` function
