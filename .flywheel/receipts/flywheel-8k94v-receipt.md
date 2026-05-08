# flywheel-8k94v Receipt

Bead: `flywheel-8k94v`
Source: ALPS tick `alps_loop_20260508T012545Z`
ALPS repo: `/Users/josh/Developer/alpsinsurance`

## Probe Results

- Canonical probe found: `/Users/josh/Developer/flywheel/.flywheel/scripts/publishability-bar.sh`.
- Canonical doctrine found: `/Users/josh/Developer/flywheel/.flywheel/PUBLISHABILITY-BAR.md`.
- ALPS missing confirmed before install: `/Users/josh/Developer/alpsinsurance/.flywheel/scripts/publishability-bar.sh` did not exist.
- ALPS real path confirmed from memory: `/Users/josh/Developer/alpsinsurance`, not Desktop or cloud-synced aliases.
- Propagation mechanism status: `broken`. `templates/flywheel-install` is the repo-local install template surface and already carries `.flywheel/scripts/` members, while L88 names `publishability-bar.sh` as canonical evidence. The template did not include the probe.

## Decision

Decision: `propagation_fix`.

Action taken:
- Installed the canonical probe at `/Users/josh/Developer/alpsinsurance/.flywheel/scripts/publishability-bar.sh`.
- Added ALPS `.flywheel/canonical-paths.txt` entries for the installed probe and canonical rubric source.
- Added the same canonical probe to `templates/flywheel-install/.flywheel/scripts/publishability-bar.sh` so future flywheel-installed repos inherit the probe instead of waiting for one-off repair.

Joshua-lens: a real ops team should not rely on a person noticing this missing probe repo by repo. The local ALPS install removes today's known blind spot, but the template fix is the durable move: a future maintainer who never saw this bead still gets the script through the install substrate. That is the difference between a brittle cleanup task and an operating discipline that survives turnover.

## Validation

Commands run:
- `bash /Users/josh/Developer/alpsinsurance/.flywheel/scripts/publishability-bar.sh --help`
- `bash -n /Users/josh/Developer/alpsinsurance/.flywheel/scripts/publishability-bar.sh`
- `bash /Users/josh/Developer/alpsinsurance/.flywheel/scripts/publishability-bar.sh --schema --json | jq -e '.title == "publishability-bar/v1"'`
- `cmp -s /Users/josh/Developer/flywheel/.flywheel/scripts/publishability-bar.sh /Users/josh/Developer/alpsinsurance/.flywheel/scripts/publishability-bar.sh`
- `cmp -s /Users/josh/Developer/flywheel/.flywheel/scripts/publishability-bar.sh /Users/josh/Developer/flywheel/templates/flywheel-install/.flywheel/scripts/publishability-bar.sh`
- `bash /Users/josh/Developer/flywheel/tests/publishability-bar.sh`
- `bash /Users/josh/Developer/flywheel/templates/flywheel-install/tests/test_render.sh`

Result: all validation passed.

## Socraticode Survey

Queries: 5.

Findings:
- Flywheel L88 names `.flywheel/PUBLISHABILITY-BAR.md`, `.flywheel/PUBLISHABILITY-AUDIT.md`, `.flywheel/scripts/publishability-bar.sh`, and the three-judges prompt as the canonical publishability evidence set.
- `templates/flywheel-install/AGENTS.md` carries the same doctrine, proving this is intended fleet-wide install substrate.
- `templates/flywheel-install` did not carry the probe script before this bead.
- ALPS had the canonical doctrine text through `AGENTS.md`, but no local probe script.

## ALPS Cross-Ref

The installed probe currently reports missing local `.flywheel/PUBLISHABILITY-AUDIT.md` when run in doctor mode. That is expected visibility, not a failed install: this bead installs the probe that makes the missing audit mechanically observable.

Follow-up bead filed: `none`.
