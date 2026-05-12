# Flywheel Adaptation

## Why Skillos Owns This

The Jeff matrix found a reusable pattern, not a single-repo patch. Flywheel
should stage the request and evidence; skillos should own final skill authoring,
hardening, versioning, and publication. This keeps consumer sessions from
polluting a universal skill with one repo's incident details.

## L60 Mapping

Every triad-bearing substrate declares:

| Field | Flywheel meaning |
|---|---|
| `producer` | CLI, script, hook, or tick driver that emits doctor/health data |
| `measurement` | Counter or status the doctor exposes |
| `consumer` | Tick, close gate, worker, route, or skillos process that acts |
| `promotion_trigger` | Frequency or severity threshold for bead/incident/skill promotion |
| `repair_owner` | Actor allowed to run apply mode |
| `receipt` | Append-only proof that action, no-op, refusal, or owner route occurred |

## Canonical CLI Scoping Alignment

The draft explicitly addresses:

- doctor / health / repair triad
- validate / audit / why subsidiary triad
- `--json` output, schema versions, and stable exit codes
- `--dry-run` / `--apply` mutation discipline
- repair refusal as a first-class outcome

## Non-Mutation Boundary

This request does not install a live skill and does not run `jsm push`. It
provides a skillos-owned draft package under `.flywheel/skillos-requests/` so
the orchestrator can review and route it to skillos.

## Review Questions For Skillos

1. Should this be one universal skill or a section inside canonical CLI scoping?
2. Should repair receipts be a shared schema across skillos skills?
3. Which existing skills should compose with this first: canonical CLI scoping,
   failure taxonomy receipts, mutation safety contract, or validation fixture
   contract?
