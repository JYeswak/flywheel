# Approved exclusion classes — flywheel-4rmc

Each of these line shapes contains a "jeff" substring AND would otherwise
match the `claim_line()` regex, but they're approved-exclusion classes
because they're either non-claim metadata or already-cited via an
alternative shape. Running this fixture through the probe should
produce `jeff_pattern_uncited_count: 0`.

## Class 1: Markdown section headers

## Jeff Pattern Import

The header above is structural metadata; the pattern citation appears in
the block beneath the header on a separate line, not on the header itself.

## Class 2: Sanitized historical excerpts

- **sanitized_excerpt:** "DONE woe-lane-b-codex jeff_patterns_adopted=8 evaluated=6 avoided=4"

The sanitized_excerpt prefix marks this as a captured historical state,
not a new pattern claim.

## Class 3: Skill citations (Jeff-derived skills, not Jeff source)

Source: jeff-convergence-audit Phase 1 (3 surfaces, 10 findings)

The text references a downstream skill named `jeff-convergence-audit`,
not a pattern adopted from a Jeff repository. Skill citations have their
own canonical-cli-scoping discoverability, so they don't need the
canonical prose template shown elsewhere in this fixture.

## Class 4: Structured-key Jeff evidence form

**Jeff convergence:** jeff_pattern_adopted=hash_linked_audit_chain_receipts; jeff_evidence_path=`$HOME/Developer/jeff-corpus/frankenterm/crates/frankenterm-core-policy-types/src/policy_audit_chain.rs:1-5`.

The structured-key shape (`jeff_evidence_path=<path>:<line-or-range>`)
provides the same file:line evidence as the canonical prose shape and
is approved by `valid_citation()` from bead flywheel-4rmc onward.

## Canonical (prose) citation — passes valid_citation strict shape

This sentence imports a pattern. Source: Jeff franken_node:scripts/check_chokepoint_false_positives.py:121 + {operator-company} adaptation.
