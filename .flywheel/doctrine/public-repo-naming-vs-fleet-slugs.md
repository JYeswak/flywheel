# Public-repo naming vs. internal fleet slugs

Doctrine codified 2026-05-15 from a firsthand incident on the
ZestStream Public Launch arc.

## Rule

A public-facing GitHub repo name **must not embed any lowercase internal
fleet slug** (e.g. `skillos`, `alpsinsurance`, `vrtx`, `mobile-eats`,
`picoz`). Flywheel's public-surface gates are designed to reject those
slugs on every public doc and site page — so a repo named with one is
fundamentally incompatible with shipping a clean public release.

## Why — observed failure mode

2026-05-14 incident: an honest dead-link fix on `README.md` and the
site (`JYeswak/SkillOS` → `JYeswak/zeststream-skillos`, the actual
GitHub remote) introduced the lowercase substring `skillos` into the
public README. Two independent gates fired against the same line:

- `tests/public-top-level-files.sh` (depersonalization scan, table
  row `skillos-session-name`, action: `generalize` lowercase `skillos`
  to a placeholder). Handled-able via the allowlist mechanism.
- `tests/naming-conventions.sh:160`
  `reject_pattern "alpsinsurance|picoz|vrtx|mobile-eats|skillos" \
     "public surfaces reject private lowercase fleet slugs"`
  — `rg --case-sensitive`. **No allowlist mechanism exists.**

Allowlisting one gate was whack-a-mole; the second gate had no escape
hatch. The dead-link fix had to be reverted, restoring a (different)
known defect (the dead `JYeswak/SkillOS` link), because the *real* repo
name fundamentally cannot appear on a public surface.

## Resolution shape

The conflict is in the repo NAME, not the gate. Renaming the GitHub
repo to a non-slug name (e.g. `JYeswak/SkillOS` capitalized — the gate
is case-sensitive) resolves both the dead-link bug and the gate
conflict in one move, with no doctrine weakening required.

## What this codifies (for future repos)

When naming or renaming any repo that will ever go public:

1. Grep the candidate name against
   `tests/naming-conventions.sh` `reject_pattern` lists for fleet slugs
   AND superseded product names.
2. Grep against `de-personalization-table.yaml` for literal `private_value`
   matches.
3. If either matches the candidate name (case-sensitive — these gates use
   `rg --case-sensitive`), pick a different name. Do NOT weaken the gates;
   they encode a real public-surface boundary, and the public README +
   site pages would carry the slug forward indefinitely.

## Anti-patterns

- "Just allowlist it everywhere" — works for the depersonalization scan
  (has an allowlist file). Does NOT work for `naming-conventions.sh`
  (no allowlist). Asymmetric escape hatches mean some gates are
  fundamentally unallowlistable; the only fix is the repo name.
- "Weaken the `reject_pattern`" — those slugs encode multi-incident
  trauma rules ("public surfaces reject private lowercase fleet
  slugs"). Removing `skillos` from the list to accommodate one repo
  name breaks the protection for every other surface.

## See also

- `tests/naming-conventions.sh` (the rejecting gate)
- `tests/public-top-level-files.sh` (the depersonalization scan)
- `state/depersonalization-scan-allowlist.yaml` (the allowlist
  mechanism that exists for *some* gates only)
- Commits on 2026-05-14:
  `d85ced51 fix(links): correct skillos repo name SkillOS -> zeststream-skillos`
  → `272db585 fix(ci): allowlist zeststream-skillos repo name`
  → `64229a1d revert(links): restore SkillOS repo name pending naming decision`
