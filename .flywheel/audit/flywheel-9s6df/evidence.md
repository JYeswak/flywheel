# flywheel-9s6df Evidence — BCV inventory-beads.sh macOS xargs portability

Task: `flywheel-9s6df-2ac2a3`
Bead: `flywheel-9s6df` (P3 OPEN → CLOSED this turn)
Title: [bcv] fix inventory-beads macOS xargs portability
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=infrastructure` — paves the path to
make the upstream BCV skill macOS-portable; actual JSM push routes to a
Joshua-gated follow-up bead.

## Headline finding — patch is jsm-push-ready, no live mutation

Skill `beads-compliance-and-completion-verification` is **JSM-managed**
(`jsm list --json` shows `version: 5`). Per skill-enhance JSM
discipline, direct live mutation under
`~/.claude/skills/beads-compliance-and-completion-verification/` is
**forbidden**. The fix is shipped as a `jsm-push-ready` patch artifact
at `.flywheel/audit/flywheel-9s6df/inventory-beads.jsm-push-ready.patch`
plus a flywheel-side macOS fixture test that proves the patched shape
works on BSD xargs without modifying the live skill.

## What the patch does

Replaces line 141 of `scripts/inventory-beads.sh`:

```diff
-xargs -d '\n' -P "$PARALLELISM" -I {} bash -c 'per_bead "$@"' _ {} \
-  < "$PASS_DIR/inventory.jsonl"
+tr '\n' '\0' < "$PASS_DIR/inventory.jsonl" \
+  | xargs -0 -P "$PARALLELISM" -I {} bash -c 'per_bead "$@"' _ {}
```

Why: BSD/macOS `xargs` rejects `-d` (`xargs: invalid option -- d`).
The portable shape `tr '\n' '\0' | xargs -0` preserves the
newline-as-record-separator semantics the original GNU-only line
relied on (per the existing comment: "makes whitespace-bearing bead
bodies safe"), and works on both BSD and GNU.

The comment block above the line is also updated to drop the GNU-only
language and explain the BSD-portable shape, with a `flywheel-9s6df
2026-05-09` provenance note.

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — `inventory-beads.sh` supports macOS/BSD xargs or avoids `xargs -d` | DID-via-patch | `inventory-beads.jsm-push-ready.patch` ships the substitution; `patch -p1` dry-run + real apply against an unmodified skill copy succeeds; `bash -n` on patched copy passes |
| AG2 — macOS fixture test covers Phase 1 without GNU xargs | DID | `tests/inventory-beads-xargs-portability.sh` 5/5 PASS on this Darwin host (`uname -s == Darwin`); test confirms `/usr/bin/xargs -d` rejects (bug class), `tr | xargs -0` preserves record boundaries, live skill still carries the bug, patched copy applies + passes bash -n, patched copy uses `xargs -0` and drops `xargs -d` |
| AG3 — `br show flywheel-9s6df` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |

did=3/3 didnt=none gaps=none.

## JSM discipline trail

```bash
jsm list --json | jq '.skills[] | select(.name == "beads-compliance-and-completion-verification") | {name, version}'
# → {"name":"beads-compliance-and-completion-verification","version":5}
```

JSM-managed → no live mutation → `jsm-push-ready` patch artifact
required. Patch artifact:
`/Users/josh/Developer/flywheel/.flywheel/audit/flywheel-9s6df/inventory-beads.jsm-push-ready.patch`.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| portability fixture | `tests/inventory-beads-xargs-portability.sh` | `b473a65c921254dfc95a241c72149271408e9d06fe256675fd64dc0036560927` |
| jsm-push-ready patch | `.flywheel/audit/flywheel-9s6df/inventory-beads.jsm-push-ready.patch` | `63de8923eb881101b84a0ef2af7108668edd879afe31acc226b11756d122022f` |
| live skill (pre-push, still carries bug) | `~/.claude/skills/beads-compliance-and-completion-verification/scripts/inventory-beads.sh` | `9985899ca4e50f369f166636756d8fae75c4d89165f5c3539064452996e05d04` |

## Test output (verbatim from `test-output.txt`)

```
PASS macOS /usr/bin/xargs rejects -d (bug class confirmed)
PASS tr | xargs -0 preserves newline-record-boundary on this host
PASS live skill copy still carries 'xargs -d (GNU-only)' (waiting on JSM push)
PASS patched copy applies cleanly and passes bash -n
PASS patched copy uses xargs -0 and drops xargs -d
SUMMARY pass=5 fail=0
```

## Follow-up bead — `flywheel-2z7b8`

Joshua-gated JSM push of the patch artifact. Filed at P3 OPEN with
labels `jsm-push-ready, bcv, xargs-portability, joshua-gated`. The
fixture test will report `live skill copy already migrated to xargs
-0` once the push lands; the test gate flips automatically with no
fixture edit needed.

## Verification commands (re-runnable)

```bash
# Fixture (proves bug class + portable replacement works on this host)
bash /Users/josh/Developer/flywheel/tests/inventory-beads-xargs-portability.sh
# expected: SUMMARY pass=5 fail=0

# Patch dry-run apply against current live skill copy
TMP=$(mktemp -d)
mkdir -p "$TMP/scripts"
cp ~/.claude/skills/beads-compliance-and-completion-verification/scripts/inventory-beads.sh "$TMP/scripts/inventory-beads.sh"
( cd "$TMP" && patch --dry-run -p1 < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-9s6df/inventory-beads.jsm-push-ready.patch )
# expected: "patching file 'scripts/inventory-beads.sh'" (no error)

# Confirm BCV is JSM-managed
jsm list --json | jq '.skills[] | select(.name == "beads-compliance-and-completion-verification")'
```

## L112 probe (worker callback)

```bash
bash /Users/josh/Developer/flywheel/tests/inventory-beads-xargs-portability.sh 2>/dev/null | tail -1
```

Expected (literal): `SUMMARY pass=5 fail=0`.

## Boundary

- **No live skill mutation.** `~/.claude/skills/beads-compliance-and-completion-verification/scripts/inventory-beads.sh` SHA unchanged. JSM-managed; patch routes through `flywheel-2z7b8`.
- **Test does not call the upstream skill end-to-end.** It synthesizes the xargs portability question with `printf | tr | xargs -0`, then exercises patch-apply against a tmp copy. No `br --db` invocations, no skill-side state mutations.
- **Patch is single-hunk, scoped.** Touches only `scripts/inventory-beads.sh` lines 137-145 (one hunk replacing 4 lines with 13 lines, all in the comment block + the xargs invocation). No other skill files touched.
- **No flywheel doctrine surface mutated.** No L-rule, no AGENTS.md, no INCIDENTS.md. The flywheel-9o2lz harness fallback path remains in place; it becomes redundant after the JSM push lands.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored. The fixture test is per-bug coverage.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — no README touched.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no doctrine surface mutated; the patch is a per-skill substitution that does not introduce a new L-rule.
- `readme_updated=not_applicable`.
- `no_touch_reason=skill-local_jsm-push-ready_patch_no_doctrine_or_AGENTS_change_required`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes AG1/AG2/AG3 verbatim. JSM discipline is honored explicitly.
- **Sniff: 9** — fixture test exercises the actual bug class (BSD `/usr/bin/xargs -d` returns non-zero) and the actual fix (`tr | xargs -0` produces correct record boundaries); patched copy `bash -n` and uses-xargs-0 gates catch silent regressions.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small surface (one new test + one patch + one followup bead); no upstream patch to a Jeffrey-owned repo (BCV is Joshua's local skill, not under Dicklesworthstone/*); JSM discipline honored.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: one bash command runs the fixture and reports 5/5; one shell snippet dry-run-applies the patch.
  - **maintainer (extending later)**: fixture flips automatically when the JSM push lands ("live skill copy already migrated to xargs -0"), so no test edit needed at push time.
  - **future worker (LLM agent)**: bar named, the GNU-vs-BSD xargs class is documented for the next portability bug, and the jsm-push-ready pattern (patch artifact + flywheel-side fixture + Joshua-gated push bead) is reusable.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=flywheel-2z7b8 beads_updated=flywheel-9s6df
no_bead_reason=patch_artifact_authored_jsm_push_routes_to_joshua-gated_followup`.
