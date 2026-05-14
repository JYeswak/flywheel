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
- Git-derived repo trajectory story pack, extractor, generated Flywheel
  trajectory evidence, embedded `zeststream.repo_story_message.v0` owner message
  pack, `zeststream.repo_story_dossier.v0` story brief,
  `zeststream.repo_frontend_story.v0` UI payload, and homepage trajectory rail
  so public story copy is grounded in commit history instead of one session's
  memory.
- Candidate `@zeststream/story-system` package with shared story grammar, proof
  states, visual primitives, excluded hype phrases, CSS tokens, and drift validator
  for Flywheel-powered frontend repos.
- Candidate `@zeststream/motion` package with reduced-motion-safe proof-surface
  motion primitives and exported spring presets for shared Next.js work.
- Candidate `@zeststream/ui` package with shared proof rails, workflow maps,
  trust-worry matrices, telemetry texture, and a reusable frontend quality gate
  for public Next.js proof surfaces.
- Staging review signoff packet that gives the reviewer one map for the live
  staging site, story trajectory, journey contract, evidence, developer path,
  agent-lane proof, and remaining public-release blockers.
- Publication goal completion audit and validator that map the active `/goal`
  to concrete artifacts while preserving the current not-complete verdict until
  live public readiness blockers clear.

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
- Latest extraction evidence: 14,752 files classified, 10,267 public-safe
  artifacts copied, 4,043 private/manual-review paths excluded, and 7,462
  review rows signed in the v0.2 publication lane.
