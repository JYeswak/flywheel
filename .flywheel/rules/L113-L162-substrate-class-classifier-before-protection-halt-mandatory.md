# L162 — SUBSTRATE-CLASS-CLASSIFIER-BEFORE-PROTECTION-HALT-MANDATORY

---
id: L162
title: Substrate-class classifier before protection halt mandatory
status: long_term
shipped: 2026-05-15
review_due: 2026-11-15
trauma_class: protection-mechanism-self-blindness
origin_incident: N=3 saturation reached when a protection hook halted on its own synthetic secret-bank fixture
substrate_class: self-documentation
meadows_leverage_point: L2 paradigm
manifest: .flywheel/security/v1/substrate-class-manifest.json
doctrine: .flywheel/doctrine/substrate-class-classifier.md
---

Any flywheel protection mechanism that halts on a matched shape MUST classify
the artifact before deciding whether to block. The halt decision is not allowed
to look only at the matched text.

The required classifier source is
`.flywheel/security/v1/substrate-class-manifest.json`. Unknown artifacts remain
default-deny and halt. Known self-referential substrate follows its declared
class behavior. In classifier output terms: `UNKNOWN` -> halt.

## Required classes

The classifier MUST recognize these classes:

- `production` -> full protection; existing halt behavior is preserved.
- `protection` -> self-exempt; detector code cannot trip on its own source.
- `test-fixture` -> suppress and emit a suppressed synthetic-match event.
- `self-documentation` -> suppress; the document describes the pattern without
  embodying a live secret or production mutation.
- `audit-ledger` -> self-exempt append/read behavior; protection receipts cannot
  recurse into protection halts.

The system is allowed to add classes only by updating the manifest and the
validator in the same change. Implicit classes are not allowed.

## Why this rule exists

This promoted after N=3 saturation:

- N=1: L160 halted on a synthetic AKID fixture.
- N=2: the same class fired again during a secret-scan probe.
- N=3: the hook halted on
  `.flywheel/tests/fixtures/ntm-scrub-secret-scan/secret-bank.txt`.

All three failures had the same shape: the protection system could not see the
difference between production substrate and the substrate it uses to protect,
test, document, or audit itself.

Per Donella Meadows' leverage-points frame, changing the paradigm that decides
what a thing is sits above tuning parameters, adding more rules, or piling on
more feedback. This rule changes the paradigm: a matched shape is not enough.
The artifact's role in the system is part of the decision.

## Enforcement contract

A compliant protection mechanism follows this order:

1. Detect the risky shape.
2. Classify the artifact path and matched value using the manifest.
3. Halt only when the class behavior says to halt.
4. Emit evidence when it suppresses a match, including the class and reason.
5. Halt on `UNKNOWN` until a human or validator-backed change declares the class.

The classifier itself is protection substrate. It is self-exempt by manifest
entry, not by special-case code. That is the recursion terminator.

## Evidence

- Bead: `flywheel-bszgl.5`.
- Manifest:
  `.flywheel/security/v1/substrate-class-manifest.json`.
- Doctrine:
  `.flywheel/doctrine/substrate-class-classifier.md`.
- Origin fixture:
  `.flywheel/tests/fixtures/ntm-scrub-secret-scan/secret-bank.txt`.
- Regression test:
  `tests/substrate-class-l162-rule.sh`.
