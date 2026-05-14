# ZestStream Story System

Schema: `zeststream.story_system_package.v0`
Status: `candidate-shared-foundation`

This package is the reusable public-story foundation for Flywheel-powered
frontend work. It packages the owner-facing message arc, trust objections, proof
states, owner language bank, page blueprint, Next.js targets, visual quality
gates, and CSS tokens that should travel into Flywheel, ClutterFreeSpaces,
Mobile Eats, and later ZestStream site work.

It is intentionally small:

- `story-system.json` carries the page grammar, proof rules, audience truths,
  owner language bank, and frontend blueprint.
- `tokens.css` carries the public visual tokens.
- `scripts/validate_story_system_package.py` checks this package against the
  generated repo message pack, generated story dossier, and the static Flywheel
  site.
- `scripts/render_repo_owner_brief.py` turns the generated trajectory JSON into
  the owner-facing brief a Next.js page should satisfy before visual work starts.

This is not a marketing copy dump. Public pages still need repo-local generated
trajectory evidence from `scripts/extract_git_story.py`, then a designed
surface that renders the workflow, slice, proof path, trajectory, and lesson
ledger in the product itself.
