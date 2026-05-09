## L89 — ZESTSTREAM-VOICE-PUBLIC-REPO-CANONICAL

---
id: L89
title: ZestStream voice public repo canonical
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: public-work-without-joshua-voice
---

Public ZestStream-owned repos must read as Joshua's work, not generic agency or
anonymous engineering output. The Joshua judge in L88 is bound to the
`zeststream-brand-voice` skill, the `zesttube` reference repo, and the live
ZestStream website voice.

**How to apply:**
- ZestStream-owned repos are public-ready by default. Private/internal status is
  metadata, not an exemption from the voice gate.
- README, MISSION, and landing copy must carry a scorecard row from
  `zeststream-brand-voice` with composite >=95 before public publish or private
  close.
- Readiness fails when `brand_voice_composite < 90`,
  `banned_words_count > 0`, or `ungrounded_claims_count > 0`.
- The doctor signal exposes `publishability_bar_score` as an object containing
  `score`, `brand_voice_composite`, `banned_words_count`, and
  `ungrounded_claims_count`.
- Public pushes use `.flywheel/scripts/zeststream-public-prepublish-hook.sh` or
  an equivalent hook before `git push public`.
- Only explicit `Exemption: EXEMPT_CLIENT_OWNED` or
  `Exemption: EXEMPT_PUBLIC_FACING` in `.flywheel/PUBLISHABILITY-AUDIT.md`
  bypasses the ZestStream scorecard. Client-owned repos use the client brand
  config instead of ZestStream voice. Jeff-owned repos keep Jeff's voice and
  attribution.

**Forbidden outputs:**
- Saying "this embodies Joshua" without a scorecard log or explicit exemption.
- Shipping public README/MISSION copy with banned ZestStream words or ungrounded
  factual claims.
- Attributing Jeff Emanuel's tools to Joshua.
- Applying ZestStream first-person rules to client-owned or Jeff-owned repos.
- Treating `Public repo: no` or `private_internal` as a voice-gate exemption.

**Evidence:** bead `flywheel-06zn`; `zeststream-brand-voice` skill;
`~/Developer/zesttube`; `.flywheel/PUBLISHABILITY-BAR.md`;
`.flywheel/scripts/publishability-bar.sh`;
`.flywheel/scripts/zeststream-public-prepublish-hook.sh`; tests
`tests/publishability-bar.sh` and `tests/zeststream-public-prepublish-hook.sh`.

**Companion rules:** L52 (gap beads for failed facets), L61 (doctrine wire-in),
L71 (validate-and-redispatch), L88 (publishability bar), and the
`zeststream-brand-voice` hard-reject rules.

