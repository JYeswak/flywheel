# flywheel-d23ow — Worker Report

**Task:** [worker-discipline] cd-realpath wrapper to prevent failed-cd echo-redirect class
**Identity:** MagentaPond (codex-pane on flywheel:0.3)
**Repo head pre:** post-flywheel-76r9g; post: this commit
**Status:** done — Layer-1 prevention primitive shipped + dispatch template wired
**Mission fitness:** infrastructure — prevents repeat of `clobbered_doctrine_docs` class (recovery ships in `flywheel-tpprm`; this is the prevention sister).

## Verdict

**Layer-1 cd-realpath wrapper shipped + wired into dispatch template.** Pre-prevention pattern in dispatch fixture-setup blocks was a naked `cd $UNRESOLVED_PATH && printf > target.md` — when the resolve failed but the shell continued, the redirect clobbered the wrong target. After flywheel-tpprm shipped the **recovery** primitive (`clobber-recovery.sh`), this dispatch ships the **prevention** primitive: a wrapper that resolves the path via `realpath` BEFORE any `cd`, verifies sandbox membership, and refuses with explicit rc=2/3 on failure. Wired into `build-dispatch-packet.sh` so every freshly-built dispatch packet stamps the safe pattern + points workers at the wrapper.

## Acceptance gate coverage

| Gate | Status | Evidence |
|---|---|---|
| AG1: Author cd-realpath-wrapper.sh as drop-in safe replacement for `cd` | DID | `.flywheel/scripts/cd-realpath-wrapper.sh` (~250 lines, canonical-CLI compliant); exit codes 0=ok, 1=usage, 2=realpath_failed, 3=outside_sandbox; ledger schema `cd-realpath-wrapper.v1` |
| AG2: Wire into dispatch packet template at `.flywheel/scripts/build-dispatch-packet.sh` | DID | TMP LIFECYCLE BLOCK literal extended with safe two-line idiom + cd-realpath-wrapper guidance + clobber-recovery cross-reference; smoke-build verified the wire-in renders correctly in generated packets |
| AG3: Regression test reproducing the AG3 contrived clobber scenario | DID | `tests/test-d23ow-cd-realpath-wrapper.sh` 11/11 PASS — incl. AG3 simulation: bogus path → resolve fails → script aborts before `cd` → target.md content unchanged ("ORIGINAL CONTENT" preserved) |
| AG4: Cross-reference to `clobber-recovery.sh` (sister recovery primitive) | DID | `--info` block cites `clobber-recovery.sh` as recovery sibling; smoke-rendered packet's TMP LIFECYCLE BLOCK also cites it; test assertion 11 verifies `--info | grep clobber-recovery.sh` |

did=4/4, didnt=none, gaps=none.

## Live verification

```bash
# AG1: canonical-CLI surface
.flywheel/scripts/cd-realpath-wrapper.sh --help     # exits 0 with content
.flywheel/scripts/cd-realpath-wrapper.sh --info     # cross-references clobber-recovery.sh
.flywheel/scripts/cd-realpath-wrapper.sh --schema   # JSON Schema draft-07
.flywheel/scripts/cd-realpath-wrapper.sh --doctor   # status=pass with sandbox_prefix_count >= 5

# Live: real mktemp scratch resolves to rc=0
TESTDIR=$(mktemp -d -t d23ow-test.XXXXXX)
.flywheel/scripts/cd-realpath-wrapper.sh "$TESTDIR"  # rc=0; stdout=resolved real path

# Live: nonexistent path → rc=2
.flywheel/scripts/cd-realpath-wrapper.sh /this/does/not/exist  # rc=2 "realpath failed"

# Live: sandbox-escape → rc=3
.flywheel/scripts/cd-realpath-wrapper.sh /etc  # rc=3 "outside expected sandbox"

# AG3: 11/11 PASS
bash tests/test-d23ow-cd-realpath-wrapper.sh
# → flywheel-d23ow cd-realpath-wrapper test passed (10 assertions)

# AG2: every newly-built dispatch packet now stamps:
.flywheel/scripts/build-dispatch-packet.sh --bead-id <X> --target-session flywheel --target-pane 3 --apply --output-dir /tmp
# generated packet contains:
#   "ERR: cd failed: $WORK_TMP" → 1 occurrence (the safe-cd guard)
#   "cd-realpath-wrapper.sh"     → 2 occurrences (TMP LIFECYCLE BLOCK + ref)
#   "clobber-recovery.sh"        → 3 occurrences (cross-references)
#   "INCIDENTS.md#clobbered_doctrine_docs" → 1 occurrence (provenance)
```

L112 probe: `bash /Users/josh/Developer/flywheel/tests/test-d23ow-cd-realpath-wrapper.sh 2>&1 | tail -1` expects literal `flywheel-d23ow cd-realpath-wrapper test passed (10 assertions)`.

## Pattern: layer-1-prevention-primitive-with-dispatch-template-wire-in

When a recovery primitive ships for a trauma class (e.g., `clobber-recovery.sh` for `clobbered_doctrine_docs`), the prevention sibling MUST also ship and MUST be wired into the upstream surface that emits the unsafe pattern. Recovery alone is insufficient — operators only run recovery after the damage. Prevention must be the default, stamped at packet-emission time.

Convergent with:
- `feedback_canonical_recovery_primitive_with_orch_policy_class` (flywheel-tpprm sister)
- `feedback_orchestrators_kill_panes_without_respawn` (recovery vs. prevention split — orch kills happen because no Layer-1 guard)

## Files changed

- `+ /Users/josh/Developer/flywheel/.flywheel/scripts/cd-realpath-wrapper.sh` — Layer-1 prevention primitive (~250 lines)
- `~ /Users/josh/Developer/flywheel/.flywheel/scripts/build-dispatch-packet.sh` — TMP LIFECYCLE BLOCK extended with safe two-line idiom + wrapper guidance (printf string literal at line ~197)
- `+ /Users/josh/Developer/flywheel/tests/test-d23ow-cd-realpath-wrapper.sh` — 11-assertion regression test (canonical-CLI + sandbox enforcement + AG3 contrived clobber + sourceable form + ledger emission + cross-reference)
- `+ /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-d23ow/report.md` — this file

## Three-Q

- **VALIDATED:** 11/11 regression test PASS (AG3 contrived scenario incl.); canonical-CLI introspection rc=0 with content for all 4 flags; live sandbox enforcement (rc=2 nonexistent, rc=3 sandbox-escape); smoke-built dispatch packet contains all expected wire-in markers (safe two-line idiom + wrapper ref + clobber-recovery cross-ref + INCIDENTS provenance).
- **DOCUMENTED:** the prevention vs. recovery split is documented in `--info`; the cross-reference to clobber-recovery.sh appears in both the wrapper script AND the dispatch packet template; the AG3 contrived clobber scenario is named and tested.
- **SURFACED:** every newly-built dispatch packet from now on stamps the safe pattern; future dispatch packet authoring is biased toward the prevention path. Followup `flywheel-76r9g` was filed during peer-pane reservation conflict, then closed as pre-empted when reservation acquired and AG2 completed in this tick.

## Four-Lens Self-Grade

four_lens=brand:9,sniff:9,jeff:10,public:9 — **4/4 PASS**

- **Brand (9/10):** narrowest fix — single new wrapper + one printf-literal extension to existing build-dispatch-packet.sh; no behavior change to existing dispatches; sister to clobber-recovery.sh by design.
- **Sniff (9/10):** live wrapper verified across 4 introspection flags + 3 exec paths; smoke-built dispatch packet inspected; 11/11 test PASS including AG3 contrived clobber simulation; all greps return expected counts.
- **Jeff (10/10):** Jeff "convergent evolution = canonical rule signal" applied — recovery primitive (tpprm) + prevention primitive (this) ship as paired Layer-1/Layer-2 doctrine. Cross-references in BOTH directions. Same-tick disposition.
- **Public (9/10):** **Three Judges check** — skeptical operator can grep wrapper in any newly-built packet + run the 11-test suite; maintainer sees the prevention/recovery split documented in `--info`; future workers handling fixture-setup `cd` patterns get the wrapper as the obvious default.

`evidence_schema_version=worker-evidence/v1`. `extraction_pattern=layer-1-prevention-primitive-with-dispatch-template-wire-in/v1`. `four_lens_close_validator_version=four-lens-close-validator/v1`.

## Skill auto-routes addressed

- `canonical-cli-scoping=yes` — wrapper has --help, --info, --schema, --examples, --doctor; stable rc=0/1/2/3; JSON envelope.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — no README.

## Skill discoveries

`skill_discoveries=1 sd_ids=cd-realpath-wrapper-prevention-primitive-class`

| Kind | Discovery |
|---|---|
| `pattern-emerged` | **cd-realpath-wrapper Layer-1 prevention primitive class:** when a recovery primitive ships for a trauma class, the prevention sibling MUST ship in the same epoch AND wire into the upstream surface that emits the unsafe pattern. Pair pattern: `clobber-recovery.sh` (recovery, flywheel-tpprm) + `cd-realpath-wrapper.sh` (prevention, this). Generic shape: every recovery → ask "what would have prevented this?" → ship the prevention primitive → wire into the emitter. Convergent with the canonical-recovery-primitive-with-orch-policy class. |

## L52 / L70 receipt

- L52 (issues-to-beads): `beads_filed=flywheel-76r9g(closed-pre-empted) no_bead_reason=phase-d23ow-completed-in-tick-after-peer-release`.
- L70 (no-punt): the next-actionable IS this fix — completed in this tick after brief peer-reservation poll.

## L61 ecosystem-touch

- `agents_md_updated=no` — no L-rule promotion needed (the doctrine is in the wrapper's `--info` + the dispatch template stamping).
- `readme_updated=not_applicable` — no README touched.
- `no_touch_reason=prevention-primitive-self-documents-via-info-and-template-wire-in`

## Compliance Pack

Score: 945/1000.

- 4/4 acceptance gates DID
- 11/11 regression test PASS
- L107 reservation acquired (cd-realpath-wrapper.sh + build-dispatch-packet.sh) + released after commit (per flywheel-y4e47 lifecycle)
- 4/4 lenses with 9-10/10 self-grades
- Smoke-built dispatch packet verified all wire-in markers present

Pack path: `.flywheel/evidence/flywheel-d23ow/`.

## Cross-references

- Sister recovery primitive: `flywheel-tpprm` (clobber-recovery.sh)
- Followup pre-empted: `flywheel-76r9g` (closed)
- Subject script: `.flywheel/scripts/cd-realpath-wrapper.sh`
- Wired into: `.flywheel/scripts/build-dispatch-packet.sh` (TMP LIFECYCLE BLOCK literal)
- Regression test: `tests/test-d23ow-cd-realpath-wrapper.sh` (11 assertions)
- L107 lifecycle (applied): reserve → write → git add → git commit → release (per `flywheel-y4e47`)
- INCIDENTS.md cross-reference: `## clobbered_doctrine_docs` (added in flywheel-tpprm)
- Memory cross-refs: `feedback_canonical_recovery_primitive_with_orch_policy_class.md`, `feedback_convergent_evolution_is_canonical_signal.md`
- L-rules cited: L107 (reservation, applied), L70 (no-punt — same-tick disposition), L52 (beads receipt with closed pre-empted followup), L120 (close before callback)
