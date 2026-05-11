# Evidence: flywheel-47jde — Jeff signal triage no-action disposition

**Bead**: flywheel-47jde (P3) | **Task ID**: flywheel-47jde-366aba | **Identity**: MistyCliff
**Signal**: github-repos detector @ 2026-05-10T12:04:06Z classified `letter_learning_game` as `new-tool`.

## Outcome: NO-ACTION (signal misclassification — same class as flywheel-j6z2e)

The repo is a **single-page educational web app for children** (Find Letters / Word Builder / Tracing Practice modes; uses SpeechSynthesis API + localStorage). Primary language HTML (545,667 bytes — single index.html file). `package.json` build script: `"echo 'Static site - no build needed'"`.

Per 4-hypothesis evaluation matrix: mirror=NO, doctrine=NO, substrate=NO, skill=NO.

## Convergent finding with flywheel-j6z2e (CLOSED earlier same session)

Same detector false-positive class: `github-repos` `new-tool` classifier files single-file static web apps (HTML-primary, no build pipeline, no scripts directory) as `new-tool`. **N=2 convergent false positives in the SAME detector batch (2026-05-10T12:04:06Z)** — strong signal to retune the classifier.

Anti-pattern signature for classifier:
```
primary_language == "HTML"
  AND package.json contains "Static site - no build needed"
  AND no scripts/bin/cmd directory exists
  → classify as `static-content`, NOT `new-tool`
```

## Memory rules applied

- `feedback_bead_hypothesis_starting_point_not_conclusion` (o40x0 META-RULE 2026-05-11): bead's apply-to-flywheel hypothesis = Bayesian prior; investigation produced the posterior (NO actionable path).
- `feedback_convergent_evolution_is_canonical_signal` (2026-05-06): N=2 convergent false positives = canonical-rule signal; recommend detector classifier fix instead of triaging case-by-case forever.

## L112 verify probe

`jq -r '.primaryLanguage.name' .flywheel/audit/flywheel-47jde/upstream-repo-metadata.json`
Expected: `grep:HTML`
