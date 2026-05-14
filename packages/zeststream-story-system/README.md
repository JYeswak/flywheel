# ZestStream Story System

Schema: `zeststream.story_system_package.v0`
Status: `candidate-shared-foundation`

This package is the reusable public-story foundation for Flywheel-powered
frontend work. It packages the owner-facing message arc, trust objections, proof
states, visual primitives, and CSS tokens that should travel into Flywheel,
ClutterFreeSpaces, Mobile Eats, and later ZestStream site work.

It is intentionally small:

- `story-system.json` carries the page grammar and proof rules.
- `tokens.css` carries the public visual tokens.
- `scripts/validate_story_system_package.py` checks this package against the
  generated repo message pack and the static Flywheel site.

This is not a marketing copy dump. Public pages still need repo-local generated
trajectory evidence from `scripts/extract_git_story.py`.
