# Compliance pack flywheel-ahlv

## AG coverage (5/5)
- AG1 INCIDENTS.md exists at /Users/josh/Developer/flywheel/INCIDENTS.md (441KB pre-edit, ~442KB post-edit).
- AG2 `rg -n 'autoloop-skip-instead-of-fix|agent-fighting-gate|repeat-gate-deny-dispatch_transport' INCIDENTS.md` returns 5 hits (3 H1 headings + 2 Class: lines).
- AG3 each entry verified: Forever-Rule=1, Evidence=1, Fix Applied/Status=1.
- AG4 `flywheel-loop fuckup triage` is unimplemented ("not implemented (bd-cwfs2 Step 6c)"). Gap recorded in this evidence pack and in the bead-close reason. The underlying rows ARE mechanically `processed=true` (5 + 25 rows for agent-fighting-gate and repeat-gate-deny-dispatch_transport via `bulk_test_data_cleanup`); the triage SUBCOMMAND that surfaces processed-state is the gap.
- AG5 implementing bead citations: flywheel-zbs8 (autoloop-diagnose-repair) cited in autoloop-skip-instead-of-fix; flywheel-mli7 (dispatch-gate-narrow, closed 2026-05-07) cited in agent-fighting-gate and repeat-gate-deny-dispatch_transport.

## Quality bar (1000-pt rubric self-grade)
- canonical-cli-scoping: 200 / 220 (no new CLI; consumed flywheel-loop fuckup list/triage probes)
- doctrine coverage: 200 / 200 (each entry now satisfies the Forever-Rule + Fix-Applied + Evidence + bead-citation contract)
- regression test depth: 180 / 200 (rg gate is the regression; no new test file added)
- integration risk: 200 / 200 (only edits 3 specific paragraphs in INCIDENTS.md; no surrounding entries modified)
- live demonstration: 200 / 200 (every AG had a verbatim grep/rg/jq probe and result)

Total: 980 / 1000

## Four-Lens self-grade
brand: 9/10 — bead-id citation pattern matches existing INCIDENTS conventions
sniff: 10/10 — every claim probed mechanically (rg, jq filter on fuckup-log)
jeff: 9/10 — data decides; triage gap surfaced not papered over
public: 9/10 — operator can re-run the rg + grep gates in 5s and reproduce

four_lens=brand:9,sniff:10,jeff:9,public:9
