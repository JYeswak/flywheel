# Public-repo canonical-stamp class-divergence discipline

**Date:** 2026-05-11
**Origin:** flywheel-rtohf gap-analysis (zeststream-brand-voice deep-analyze; CloudyMill, four_lens 10/10/10/10)
**Skill discovery:** `public_repo_canonical_stamp_class_divergence_audit_pattern`
**Status:** ACTIVE doctrine; applies to every jyeswak public-repo stamping pass

## The rule

When stamping a canonical baseline from an exemplar repo into a target repo:
**stamp the SHAPE; rewrite the CONTENT to match the target's audience-class.**

Never copy substantive content verbatim across audience-class boundaries.

## The three audience-classes

| Class | Visibility | License | Audience | Voice |
|---|---|---|---|---|
| **PRIVATE-ALPHA** | github private | Any (often none) | Internal Joshua-fleet | Fleet-orch jargon, L-rules, doctrine refs OK |
| **PUBLIC-OSS** | github public | MIT/Apache | External evaluators + contributors | Plain language, no internal-doctrine refs, SLA promises |
| **PUBLIC-MIT-COMMERCIAL** | github public | MIT | Buyers / integrators / community | Above + competitive framing, receipts, commercial-asset signals |

## What goes wrong if you copy verbatim across class lines

Concrete cases observed at flywheel-rtohf:
- **skillos CONTRIBUTING.md** says *"private alpha repository. Contributions are limited to authorized internal collaborators."* Copying to a PUBLIC-MIT repo signals hostility to community.
- **skillos SECURITY.md** says *"private alpha software. Report to security@zeststream.ai."* Missing PUBLIC SLA + coordinated-disclosure guidance that external security researchers expect.
- **skillos AGENTS.md** contains fleet-orch internal doctrine (L-rule schema, trauma-class taxonomy). Publishing verbatim leaks coordination details + confuses external readers who lack context.

## The rewrite-by-class recipe

For each canonical-stamp file:

1. **Classify the target.** Public-OSS? Public-MIT-commercial? Private-alpha?
2. **Classify the exemplar.** Same?
3. **If divergent**, do NOT copy. Apply the rewrite-by-class table below.

### Rewrite table

| File | PRIVATE-ALPHA voice | PUBLIC-OSS rewrite | PUBLIC-MIT-COMMERCIAL rewrite |
|---|---|---|---|
| `README.md` | Internal mission + roadmap | + Quick-start, install path, basic API | + Receipts narrative, competitive framing, honesty box, AI-Assessment CTA |
| `ARCHITECTURE.md` | Fleet-internal "how the parts fit" | + Public extension points, phase status, safety doctrine map | + Commercial-use guidance, integrator stories |
| `ROADMAP.md` | Fleet horizons + L-rule deps | + Public release shape, phase status with shipped/partial/planned legend | + How to influence the roadmap (issue templates, voting, off-roadmap PRs) |
| `AGENTS.md` | Full L-rule + trauma-class doctrine | **SPLIT**: top-level thin pointer + `.flywheel/AGENTS-CANONICAL.md` full doctrine | Same split; external pointer cites CONTRIBUTING.md |
| `CONTRIBUTING.md` | "Internal only; ask Joshua" | Open contribution scope, PR style, review SLA (best-effort) | + Commercial-IP guidance, attribution clause, MIT-CLA implicit-grant note |
| `SECURITY.md` | "Report to security@zeststream.ai" | + 5-day-ack SLA, 30-day-critical-patch SLA, coordinated disclosure, scope/out-of-scope | Same + safe-default disclosure |
| `LICENSE` | Often missing or short | Full MIT/Apache canonical text + copyright | Same |
| `.gitignore` | Generic build artifacts | + Domain-aware patterns (drafts, secrets, scorecard logs) | Same |

## The split-file pattern for AGENTS.md

For any public repo that is also flywheel-onboarded (has `.flywheel/` substrate):

- **Top-level `AGENTS.md`** — PUBLIC-safe; ~30 lines max; says "Internal contributors follow flywheel canonical doctrine at `.flywheel/AGENTS-CANONICAL.md`. External contributors see CONTRIBUTING.md."
- **`.flywheel/AGENTS-CANONICAL.md`** — full L-rule + trauma-class + fleet-orch doctrine; propagated via `doctrine-sync.sh` (consistent with post-shard `.flywheel/rules/` layout per flywheel-rhdcq.1 fix 2026-05-11).

This preserves the fleet contract without polluting the public repo with fleet-jargon.

## Auditor checklist (apply before any public-repo stamping PR is opened)

- [ ] Target audience-class confirmed (PRIVATE-ALPHA / PUBLIC-OSS / PUBLIC-MIT-COMMERCIAL)
- [ ] For each canonical file, the file CONTENT (not just the shape) matches the target class
- [ ] No fleet-orch jargon leaked into public files
- [ ] No "private alpha" framing in PUBLIC-MIT-commercial repos
- [ ] AGENTS.md (if needed) follows the SPLIT pattern
- [ ] SECURITY.md (if PUBLIC) includes SLA + coordinated-disclosure section
- [ ] CONTRIBUTING.md (if PUBLIC) sets contribution scope explicitly

## Memory cross-references

- `feedback_class_divergence_public_mit_vs_private_alpha.md` — the META-RULE
- `project_flywheel_publish_readiness_every_jyeswak_repo_mission_2026_05_11.md` — the mission this serves
- `feedback_substrate_boundary_three_class_taxonomy.md` — sister discipline for substrate (vs audience)

## What this displaces

Replaces the implicit-default behavior of "copy skillos canonical files verbatim into public repos" — that default would have caused PRIVATE-ALPHA framing to leak into 36 KEEP-and-LIFT public-track repos.
