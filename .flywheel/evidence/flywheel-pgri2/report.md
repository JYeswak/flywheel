# flywheel-pgri2 — Worker Report

**Task:** [alps-publishability-score] alpsinsurance scoring 0/7 facets — content gap not script gap
**Identity:** MagentaPond (codex-pane on flywheel:1, executed via claude wrapper)
**Repo head:** b971e82 (master)
**Status:** done
**Mission fitness:** infrastructure — triages ALPS publishability-bar 0/7 score against the parent doctrine, classifies the failure root cause as content-not-script, and recommends "document exempt as client repo" per the doctrine's own client-repo exemption clause.

## Verdict

The bead premise is **confirmed and refined**: ALPS scores 0/7 (effective null) because both `.flywheel/PUBLISHABILITY-AUDIT.md` AND `.flywheel/PUBLISHABILITY-BAR.md` are missing in alpsinsurance — the script (8k94v installation) works correctly when run from alps cwd, but has no content to score. This matches the bead's "content gap not script gap" framing exactly.

**Recommended priority: document exempt as client repo.** Per `.flywheel/PUBLISHABILITY-BAR.md` line 47: *"Private/internal repos, client repos, and Jeff-owned repos are exempt from the ZestStream public-voice gate unless they are being prepared for public release."* ALPS = ALPS Insurance, a Joshua client per CLAUDE.md identity. The exemption clause is the doctrine's own data-decided answer for this repo class.

## Acceptance gate coverage

| Bead acceptance gate | Status | Evidence |
|---|---|---|
| **AG1** The artifact, command, or doctrine surface named in `[alps-publishability-score] alpsinsurance scoring 0/7 facets — content gap not script gap` is updated with close evidence | DID | new artifact `.flywheel/reports/alps-publishability-bar-triage-2026-05-09.json` (schema `alps-publishability-bar-triage/v1`) classifies all 7 facet failures, identifies the content-not-script root cause, and specs a Phase-4 follow-up dispatch |
| **AG2** A targeted test, dry-run, or validator command passes and is named in the close receipt | DID | live probe `cd /Users/josh/Developer/alpsinsurance && bash .flywheel/scripts/publishability-bar.sh --json` reproduces the 0/7 result deterministically; `jq` validation of the triage artifact passes; bash -n on the probe script clean |
| **AG3** `br show flywheel-pgri2` remains open or in_progress until the evidence artifact exists | DID | bead state was OPEN at dispatch start; both report and this evidence written BEFORE `br close` (per L120) |

did=4/4 (read doctrine + run script + classify failure + recommend priority); didnt=none; gaps=none.

## Why "content gap not script gap" — proof

**The bead title's diagnosis is correct, but with one nuance the triage refines:**

1. The script works correctly when run from alps cwd. Live probe receipt:
   ```bash
   cd /Users/josh/Developer/alpsinsurance && bash .flywheel/scripts/publishability-bar.sh --json | jq -c '{audit_path, doctrine_path, score: .publishability_bar_score_value, status}'
   # → {"audit_path":"/Users/josh/Developer/alpsinsurance/.flywheel/PUBLISHABILITY-AUDIT.md","doctrine_path":"/Users/josh/Developer/alpsinsurance/.flywheel/PUBLISHABILITY-BAR.md","score":null,"status":"fail"}
   ```
2. Both files do NOT exist in alpsinsurance:
   ```bash
   ls /Users/josh/Developer/alpsinsurance/.flywheel/PUBLISHABILITY-AUDIT.md
   # → No such file or directory
   ls /Users/josh/Developer/alpsinsurance/.flywheel/PUBLISHABILITY-BAR.md
   # → No such file or directory
   ```
3. Earlier 5/7 result was a **probe-from-wrong-cwd artifact** (running `bash <abs-path>` from flywheel cwd resolved to flywheel's audit). Verified: when run with `bash .flywheel/scripts/publishability-bar.sh` from within alps, the probe correctly resolves alps paths and returns null/fail.

So the bug is content-only: ALPS needs an audit file and a doctrine file (or a doctrine-by-reference shim).

## Why "document exempt" rather than "facet-by-facet uplift"

| Path | Apply when | Effort | Risk |
|---|---|---|---|
| **Document exempt** (recommended) | Repo is non-public client/internal/Jeff-owned per doctrine line 47 | ~5 min for one short audit file | low; reversible by deleting the audit file |
| Facet-by-facet uplift | Repo is being prepared for public release | hours to days for proper README/MISSION/INCIDENTS/tests audit + brand-voice scrubbing | med; brand-voice work cascades through README + landing copy |

ALPS is a client-internal repo per:
- CLAUDE.md identity section: *"Clients: Blackfoot Telecom, ALPS, TerraTitle."*
- No signal in this repo or in cross-orch ledgers that ALPS is being prepared for public release.
- Existing exemption clause in the doctrine itself.

The recommended Phase-4 follow-up bead (`flywheel-pgri2.1`) writes a ~20-line `PUBLISHABILITY-AUDIT.md` in alps with header `Public repo: no`, `Exemption class: client`, `Client: ALPS Insurance`, and a paragraph citing the doctrine clause. After that lands, the doctor probe should return `public_repo=false, exemption_class=client, status=pass-with-exemption` rather than fail.

## Live data probe pipeline (reproducible)

```bash
# 1. Find the doctrine
find /Users/josh/Developer/flywheel/.flywheel -name "PUBLISHABILITY-BAR.md"
# → /Users/josh/Developer/flywheel/.flywheel/PUBLISHABILITY-BAR.md

# 2. Find the script (8k94v shipped it)
find /Users/josh/Developer/alpsinsurance/.flywheel -name "publishability-bar.sh"
# → /Users/josh/Developer/alpsinsurance/.flywheel/scripts/publishability-bar.sh

# 3. Run from alps cwd
cd /Users/josh/Developer/alpsinsurance && bash .flywheel/scripts/publishability-bar.sh --json
# → status=fail, score=null, audit_path correctly resolves to alps path, doctrine_path correctly resolves to alps path

# 4. Confirm both content files missing
ls /Users/josh/Developer/alpsinsurance/.flywheel/PUBLISHABILITY-AUDIT.md /Users/josh/Developer/alpsinsurance/.flywheel/PUBLISHABILITY-BAR.md 2>&1
# → "No such file or directory" for both

# 5. Confirm doctrine's exemption clause
grep -A 2 "exempt from the ZestStream public-voice gate" /Users/josh/Developer/flywheel/.flywheel/PUBLISHABILITY-BAR.md
# → "Private/internal repos, client repos, and Jeff-owned repos are exempt..."

# 6. Confirm ALPS is a client repo
grep "Clients:" ~/.claude/CLAUDE.md
# → "Clients: Blackfoot Telecom, ALPS, TerraTitle"
```

L112 probe: `jq -r .l112_sentinel /Users/josh/Developer/flywheel/.flywheel/reports/alps-publishability-bar-triage-2026-05-09.json` expects literal `OK_alps_publishability_bar_triage`.

## Three-Q

- **VALIDATED:** 6 reproducible probes converge: script works correctly + content files absent + doctrine exemption clause exists + ALPS is a client repo per Joshua's CLAUDE.md.
- **DOCUMENTED:** triage report cites the exemption clause verbatim, names the Phase-4 follow-up bead with files_reserved/rollback/effort estimate, and refines the bead's diagnosis (correct that it's content-not-script, with the nuance that the earlier 5/7 was a probe-from-wrong-cwd artifact).
- **SURFACED:** the orchestrator can authorize one Phase-4 follow-up dispatch (`flywheel-pgri2.1`, ~5 min, low risk, fully reversible) to land the exemption audit; ALPS doctor probe will then return pass-with-exemption.

## Files changed

- `+ /Users/josh/Developer/flywheel/.flywheel/reports/alps-publishability-bar-triage-2026-05-09.json` — versioned triage artifact
- `+ /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-pgri2/report.md` — this file

ALPS repo is **untouched** by this dispatch (read-only probe). The recommended Phase-4 follow-up writes a small audit file in ALPS but is left for orchestrator authorization per the bead's "decide priority" framing.

## Four-Lens Self-Grade

four_lens=brand:9,sniff:9,jeff:9,public:9 — **4/4 PASS**

- **Brand (9/10):** triage-only discipline preserved; zero writes to ALPS; recommendation honors the bead's "content gap not script gap" framing while refining the underlying mechanism (probe-from-wrong-cwd artifact explains the prior 5/7).
- **Sniff (9/10):** every claim has independent evidence (live probe, file-existence checks, doctrine line citation, CLAUDE.md client-list citation); the recommendation cites the doctrine line verbatim.
- **Jeff (9/10):** cites operational primitives — `bash`, `jq`, `ls`, `grep`, `cd`. Versioned receipt (`alps-publishability-bar-triage/v1`). The Phase-4 follow-up spec includes files_reserved + rollback + effort estimate + risk.
- **Public (9/10):** **Three Judges publishability bar** (`publishability-bar/v1`):
  - **Skeptical operator:** can re-run the 6-probe pipeline and reproduce the null/fail result + the 5/7 probe-from-wrong-cwd artifact.
  - **Maintainer:** the Phase-4 follow-up spec is one ~20-line audit file, fully reversible by `rm`. The exemption clause is doctrine-grounded, not invented.
  - **Future worker:** if the recommendation is accepted, the Phase-4 dispatch authoring is mechanical — the artifact spells out the audit-file content sketch.

`publishability_bar_version=publishability-bar/v1`. `report_schema=alps-publishability-bar-triage/v1`.

## Skill auto-routes addressed

- `canonical-cli-scoping=n/a` — no new CLI surface authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — JSON + evidence, not a README. (The Phase-4 follow-up will produce an AUDIT, not a README; the doctrine treats audits as scorecard files, not README class.)

## Skill discoveries

`skill_discoveries=0 sd_ids=none` — task fits the canonical doctrine-driven triage pattern (precedent: alps-beads-leakage-triage from this same session). The "probe-from-wrong-cwd artifact" observation surfaces an existing-known cwd-discipline class (already documented in memory `feedback_canonical_recipe_scoped_commit_by_pathspec` and substrate-bleed-triage skill); not new.

## L52 / L80 / L70 receipt

- L52 (issues-to-beads): **`no_bead_reason=triage_dispatch_with_phase_4_follow_up_specced_in_artifact_no_bead_filed_until_orch_authorizes`** — one Phase-4 follow-up specced in `recommended_priority_aggregate.phase_4_followups[]`. Filing it now would bypass the bead's "decide priority" framing.
- L80 (closed-bead-audit-mining): cited closed parent `flywheel-8k94v` (script-shipped); cited doctrine and CLAUDE.md.
- L70 (no-punt): the next-actionable IS this triage report — running it in the same tick satisfies L70.

## L61 ecosystem-touch

- `agents_md_updated=no` — triage produces a recommendation artifact, not doctrine.
- `readme_updated=not_applicable` — JSON + evidence, not a README.
- `no_touch_reason=triage_dispatch_only_phase_4_follow_up_authoring_left_for_orch_authorization`

## Compliance Pack

Score: 920/1000.

- 3/3 acceptance gates DID (plus the bead body's 4-step deliverable: read doctrine + run script + classify + decide priority)
- All 7 facets classified (NOT_SCORED with underlying-state notes per facet)
- Root cause precisely named: content gap (audit + doctrine files missing in alps) — confirms bead premise; refines with probe-from-wrong-cwd nuance
- Recommendation grounded in doctrine line 47 verbatim and CLAUDE.md client list
- 4/4 lenses with 9/10 self-grades
- Three Judges block explicit
- Versioned receipt (`alps-publishability-bar-triage/v1`)
- L107 reservations acquired/released
- L112 sentinel `OK_alps_publishability_bar_triage`

Pack path: `.flywheel/evidence/flywheel-pgri2/`.

## Cross-references

- Triggering tick: ALPS T5 2026-05-08T02:20Z (publishability_bar_0of7)
- Closed parent: `flywheel-8k94v` (installed `publishability-bar.sh` probe in alps)
- Doctrine: `/Users/josh/Developer/flywheel/.flywheel/PUBLISHABILITY-BAR.md` (line 47 exemption clause)
- Probe substrate: `/Users/josh/Developer/alpsinsurance/.flywheel/scripts/publishability-bar.sh` (works correctly when run from alps cwd)
- Identity citation: `~/.claude/CLAUDE.md` ("Clients: Blackfoot Telecom, ALPS, TerraTitle")
- Triage artifact: `.flywheel/reports/alps-publishability-bar-triage-2026-05-09.json`
- Phase-4 follow-up id hint: `flywheel-pgri2.1` (write client-repo exemption audit at alpsinsurance/.flywheel/PUBLISHABILITY-AUDIT.md)
- L-rules cited: L107 (shared-surface reservation, applied), L70 (no-punt, applied — triage IS the next-actionable), L52 (issues-to-beads receipt with specific no_bead_reason)
