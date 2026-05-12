# Jeff Evidence

Source matrix:
`.flywheel/jeff-corpus/v1/learnings/06-skill-enhancement-matrix.md`.

The matrix lists `doctor-repair-triad` under "Needs New Sibling Skill" and
states the gap: several operational skills mention doctor, health, and repair,
but no sibling skill owns the observer/classifier/dry-run/apply repair contract.

Doctrine cluster evidence:
`.flywheel/jeff-corpus/v1/learnings/01-doctrine-cluster.md` classifies
`doctor-health-repair-triad` as operational tooling that exposes state
inspection, structured health, and dry-run/apply repair paths instead of
prose-only troubleshooting.

Code pattern evidence:
`.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md` gives the pattern a
preliminary `EXTEND` verdict for flywheel. It says to import doctor signal
templates with `check`, `why`, and `repair --dry-run` siblings before automated
promotion.

Cross-pattern dedupe:
The same code-pattern file says doctor observes, repair dry-runs/applies, and
migrations are a repair subclass. The skill draft therefore keeps doctor,
health, and repair separate rather than collapsing them into one command.

Flywheel adaptation:
The new skill must preserve flywheel callback fields. A repair receipt can be
evidence for `DONE`, but it cannot replace `DID/DIDNT/GAPS`,
`mission_fitness`, or callback delivery verification.
