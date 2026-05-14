# Troubleshooting

Start with JSON output. Flywheel commands are meant to explain their own failure
class.

| Symptom | First check |
|---|---|
| Preflight returns `blocked` | Read `summary.required_missing` and install the named dependency. |
| Preflight returns `reduced` | Continue through reduced mode; do not claim full substrate behavior. |
| Doctor returns `repo_not_initialized` | Run `flywheel init --repo "$PWD" --json`. |
| Tick cannot choose work | Inspect `.flywheel/STATE.md` and the latest doctor output. |
| Dispatch is simulated | Treat it as reduced-mode evidence, not full harness proof. |
| Receipt validation fails | Read `failure_classes` and fix the receipt producer before release. |
| Publication readiness is blocked | Read `blockers`; each release blocker needs real public evidence. |

If a command does not produce JSON where the docs say it should, file or update
a Bead before widening the public support claim.
