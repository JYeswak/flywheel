# Changelog

All notable changes to Flywheel are documented here.

This project follows Keep a Changelog structure and uses semantic versioning for
public releases. There are no public git tags yet; `0.2.0` is the first planned
public release line.

## [0.2.0] - Unreleased

### Added

- Public charter, first-run journey, reduced/full-mode support matrix, and
  SkillOS capability-boundary handoff for the initial publication lane.
- Extraction assembly tooling that classifies source material, excludes private
  state, emits a staging manifest, and preserves a manual-review queue.
- Review-queue reduction tooling with explicit evidence strings for
  manually-signable rows.
- Public top-level repository files: license, contributing guide, security
  reporting, support path, code of conduct, and changelog.
- Support-tier language that marks reduced mode as the required public path,
  full mode as substrate-dependent, and Claude, Codex, Gemini, and OpenClaw as
  supported only when strict agent-lane runtime receipts prove the isolated
  journey and private-state scan.
- Public release cutover authorization runbook covering live readiness codes,
  operator commands, stop conditions, release assets, website/install
  checksum verification, and final signoff boundaries.
- SkillOS-compatible public user journey pack and validator requiring every
  public asset to map persona lane, journey stage, visible wording, visual cue,
  CTA, proof refs, signoff status, and blocker/skip receipt refs before signoff.

### Changed

- README now presents Flywheel as a public installable engine with a concrete
  extraction metric instead of private-operator-only orientation.
- Public release guidance now links the general release runbook to the cutover
  authorization checklist so external operators can see the final gate without
  reading private plan state.
- Contribution workflow now requires DCO `Signed-off-by` trailers.

### Security

- Public surfaces document reduced-mode boundaries, secret discipline, and
  dispatch-safety reporting without requiring access to private fleet state.

### Evidence

- Public evidence index added at `docs/evidence/publication-evidence.md` to map
  v0.2 trust claims to local verifiers and live evidence still required.
- Latest extraction evidence: 14,677 files classified, 10,195 public-safe
  artifacts copied, 4,040 private/manual-review paths excluded, and 7,432
  review rows signed in the v0.2 publication lane.
