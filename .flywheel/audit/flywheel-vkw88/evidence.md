# flywheel-vkw88 Evidence — L87 fallback-status documented; sunset gated on binary rebuild

Task: `flywheel-vkw88-830174`
Bead: `flywheel-vkw88` (P2 OPEN → CLOSED this turn)
Title: [ntm#118 absorb] retire L87 stale-error workaround after fixed ntm binary verified
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=infrastructure` — paves the path to
sunset L87 by documenting the upstream fix + binary verification gap;
actual retirement is gated to a follow-up bead because the binary
swap is fleet-impacting.

## Headline finding — Path 2 (document why L87 remains as fallback)

The bead acceptance offered two paths:
1. Rebuild + verify + retire L87/README workaround copy.
2. Document why L87 remains as fallback.

**Path 2 was chosen** because the verification chain is broken: the
installed binary at `/Users/josh/.local/bin/ntm` reports
`commit: none / built: unknown`, so even though the local clone HEAD
contains Jeffrey's fix `4c176e92`, no observation can prove the running
binary includes it. Rebuilding would replace the 54MB fleet-shared
binary that every active pane uses — that is fleet-impacting substrate
maintenance, owner-coordinated per the Joshua-disposes axiom and per
`feedback_calling_in_sick_policy_flywheel_owns_orch_failures.md`.

The dispatch's headline gate ("do not retire L87 ... until the
installed binary can prove it includes the fix") is therefore honored
verbatim.

## What changed

| File | Action |
|---|---|
| `/Users/josh/Developer/flywheel/.flywheel/rules/L041-L87-stale-error-text-auto-ping-recovery.md` | Appended `**Status update 2026-05-09 (flywheel-vkw88):**` paragraph naming the upstream fix (`4c176e92`), the local-clone-HEAD ancestry proof, the binary verification gap, and the gated follow-up bead. Status field unchanged (`status: temporary`); sunset_when unchanged. |
| `/Users/josh/Developer/flywheel/README.md` | Replaced the "Until upstream `ntm` resolves that classifier edge case" sentence (now factually inaccurate — Jeffrey did resolve it) with the post-fix narrative: upstream fix landed, fix is in local clone, installed binary cannot prove it, recovery layer remains as fallback, see L87 + `flywheel-vkw88` audit pack for sunset checklist. The `bash` recipe block is preserved verbatim. |
| `/Users/josh/Developer/flywheel/.beads/issues.jsonl` | Filed `flywheel-u4fmq` — Joshua-gated rebuild + L87 sunset checklist with 8 explicit steps. |

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — substrate updated with close evidence | DID | this evidence pack at `.flywheel/audit/flywheel-vkw88/` (evidence.md + ntm-version-evidence.txt + fallback-test-output.txt + pinned-shas.txt) |
| AG2 — targeted test/dry-run/validator passes and is named | DID | `bash tests/stale-error-auto-ping.sh` returns `7 passed, 0 failed`; `git merge-base --is-ancestor 4c176e92 HEAD` exits 0 in `/Users/josh/Developer/ntm`; `ntm version` captured in `ntm-version-evidence.txt` |
| AG3 — `br show flywheel-vkw88` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |
| Bead AC: install/build ntm with commit including 4c176e92 | DID-via-Path-2 | rebuild is fleet-impacting and routes to follow-up bead `flywheel-u4fmq` (8-step Joshua-gated checklist); ancestry of `4c176e92` in local clone HEAD verified |
| Bead AC: run robot-activity stale-error fixture or equivalent | DID-via-fallback-test | `tests/stale-error-auto-ping.sh` 7/7 PASS against the current binary (the fixture exercises the FALLBACK path — it does not require the upstream fix to be present, which is the point of Path 2: the fallback is still functional regardless of binary state) |
| Bead AC: retire L87/README copy OR document why fallback remains | DID-via-Path-2 | both surfaces now carry the post-fix narrative + sunset gating; status unchanged because the verification chain is broken |

did=6/6 didnt=none gaps=none.

## Pinned artifact SHAs (post-edit)

| Artifact | Path | SHA-256 |
|---|---|---|
| L87 doctrine | `.flywheel/rules/L041-L87-stale-error-text-auto-ping-recovery.md` | `c5e147fd8d51f6fd3236371ae3ffda0fe938e42c6d4d39a1fab6bce454b66970` |
| README | `README.md` | `690ef767febc50ec97f0adbca4f430eb2e8d03314c51a5794ec7055a0bf487de` |
| installed ntm | `/Users/josh/.local/bin/ntm` | `916bdafbe3f8b37019dc5df6d1baf26c777c4b3ce20e28b068be02a489efe8a7` (still version=dev commit=none) |

## ntm version + ancestry receipts (verbatim from `ntm-version-evidence.txt`)

```
== ntm version (installed) ==
ntm version dev
  commit:    none
  built:     unknown
  builder:   unknown
  go:        go1.25.6
  platform:  darwin/arm64

== local clone HEAD ==
7d1fc78e feat(ensemble): add pi agent support
7d1fc78ebf19af12b193c972d25016ec707d8f87

== 4c176e92 ancestry ==
4c176e92 IS ancestor of HEAD

== fix commit ==
commit 4c176e92666551d4bc167d69e8f207f3624282aa
Author: Dicklesworthstone <jeff141421@gmail.com>
Date:   Mon May 4 15:15:10 2026 -0400
    fix(robot/activity): debounce CategoryError to live-window when an idle prompt is present (#118)
```

The fix's three regression tests (`TestFilterErrorToLive*`) are present
in the local clone but cannot be exercised against the running binary
without a rebuild.

## Follow-up bead — `flywheel-u4fmq`

Joshua-gated 8-step checklist to actually retire L87:

1. Coordinate with peer orchs that no active worker is mid-dispatch on `/Users/josh/.local/bin/ntm`.
2. `cd /Users/josh/Developer/ntm && make build`.
3. Verify `dist/ntm version` reports a real commit hash matching HEAD.
4. Install `dist/ntm` to `/Users/josh/.local/bin/ntm` with prior-binary backup.
5. Re-run `bash tests/stale-error-auto-ping.sh` and confirm 7/7 still pass.
6. Replay a stale-error fixture in a controlled pane to confirm the debounce kicks in.
7. Flip L87 `status: temporary` → `status: deprecated`, add `sunset_at` and `binary_commit_pin`.
8. Reduce README block to a deprecated migration note.

## Verification commands (re-runnable)

```bash
# Confirm fallback test still passes
bash /Users/josh/Developer/flywheel/tests/stale-error-auto-ping.sh

# Confirm 4c176e92 is in local clone HEAD ancestry
cd /Users/josh/Developer/ntm \
  && git merge-base --is-ancestor 4c176e92 HEAD \
  && echo ok || echo missing

# Confirm installed binary still cannot prove the fix
/Users/josh/.local/bin/ntm version | grep -E "commit:|built:"
# Expected: "commit: none" and "built: unknown" (until u4fmq applies)

# Confirm doctrine + README carry the status update
grep -c "Status update 2026-05-09 (flywheel-vkw88)" \
  /Users/josh/Developer/flywheel/.flywheel/rules/L041-L87-stale-error-text-auto-ping-recovery.md
grep -c "4c176e92" /Users/josh/Developer/flywheel/README.md
# Expected: 1 and >=1
```

## L112 probe (worker callback)

```bash
test -f /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-vkw88/fallback-test-output.txt \
  && grep -q "7 passed, 0 failed" /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-vkw88/fallback-test-output.txt \
  && grep -q "4c176e92 IS ancestor of HEAD" /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-vkw88/ntm-version-evidence.txt \
  && echo ok || echo missing
```

Expected (literal): `ok`.

## Boundary

- **No binary swap.** `/Users/josh/.local/bin/ntm` SHA unchanged
  (`916bdafbe3f8b37019dc5df6d1baf26c777c4b3ce20e28b068be02a489efe8a7`).
- **No L87 status flip.** Frontmatter `status: temporary`, `sunset_when:
  flywheel-pp1g`, `review_due: 2026-06-04` all preserved verbatim. Only
  added a body paragraph; the rule's "How to apply" / "Forbidden outputs"
  / "Evidence" / "Companion rules" sections are unchanged.
- **No upstream patch.** No edit to any Jeffrey-owned repo
  (`/Users/josh/Developer/ntm` is read-only here per
  `feedback_no_push_ntm_br.md`).
- **No fallback test removal.** `tests/stale-error-auto-ping.sh` and
  `.flywheel/scripts/stale-error-auto-ping.sh` are unchanged; both stay
  on for fallback continuity.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=yes` — README block updated with: factual upstream
  status (Jeffrey's fix landed), explicit binary verification gap,
  pointer to L87 doctrine + `flywheel-vkw88` audit pack, copy-pasteable
  recipe block preserved. Quick-Start contract intact.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — AGENTS.md L87 row at line 79 still points
  at the canonical doctrine doc; the doc body now carries the status
  update so AGENTS.md is correct as-is.
- `readme_updated=yes` — README block at lines 1218-1240 was updated
  to reflect post-fix narrative + binary verification gap + sunset
  gating pointer.
- `no_touch_reason=AGENTS_already_routes_to_canonical_doctrine_doc_which_carries_the_status_update`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes AG1/AG2/AG3 and the bead body's three sub-ACs
  via Path 2 with explicit reasoning for choosing Path 2 over Path 1.
- **Sniff: 9** — every claim is shell-checkable; the
  `git merge-base --is-ancestor` ancestry probe is the canonical
  ground-truth for "is the fix in this tree", and the binary
  `commit: none` is the canonical ground-truth for "is the fix in the
  running binary". Path 2 follows from those two probes mechanically.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; no upstream
  patch; pinned commit hashes for every load-bearing artifact; small
  surface (one doctrine paragraph + one README block + one follow-up
  bead); explicit citation of `pp1g` close-out note authoring this
  follow-up.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: one bash command reruns the
    fallback test; one shell line confirms ancestry; one grep confirms
    the binary still reports commit=none.
  - **maintainer (extending later)**: 8-step checklist on
    `flywheel-u4fmq` is grep-friendly so the actual sunset can run
    cleanly when Joshua signs off.
  - **future worker (LLM agent)**: bar named, Path-1-vs-Path-2
    decision template documented, the gating rule ("don't retire
    until binary proves the fix") is reusable for the next
    upstream-fix-vs-binary-drift pair.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=flywheel-u4fmq beads_updated=flywheel-vkw88
no_bead_reason=path_2_chosen_documentation_only_actual_sunset_routes_to_joshua-gated_followup`.
