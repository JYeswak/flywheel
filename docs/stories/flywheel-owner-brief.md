# Flywheel Owner Story Brief

Schema: `zeststream.repo_owner_story_brief.v0`

Show the proof, not the dream. Lead with the owner's stuck workflow, then show the controlled path forward.

## Headline

Buy back the time hiding between your tools.

Map the manual route between tools, improve one bounded slice, prove what changed, and carry the lesson forward.

## Owner Problem

The business already has systems. The waste sits between them: copying, chasing, checking, remembering, and wondering what changed.

Safe first step: Start with one workflow map before broader access, automation, or claims.

## The Yuzu Method

| Stage | Visible wording | Visual cue |
|---|---|---|
| recognize | Your business already has the data. The work is just hidden between tools. | A workflow map with disconnected systems and one highlighted manual route. |
| bound | A slice is one bounded workflow improvement: useful enough to feel, small enough to inspect, and clear enough to stop if the proof is not there. | The selected slice is pulled out of the map and placed on a workbench. |
| control | If a claim is not proven, it stays blocked. | A proof rail with proven, blocked, skipped-with-reason, and private states. |
| remember | The repo history shows the pivots, blockers, and lessons that survived contact with reality. | A trajectory rail that connects foundation, friction, proof loop, reuse, and current arc. |
| act | Map one workflow before sending secrets, customer data, or system access. | A safe intake room with redacted examples and a direct operator route. |

## Trust Answers

| Owner worry | Visible answer | Proof behavior |
|---|---|---|
| AI will make a mess. | The map comes before automation. | The first slice must have a named boundary and stop condition. |
| I will not know what changed. | Every slice has a proof rail. | Each claim links to evidence or stays blocked. |
| My data will leak. | Private work stays private. | Public proof is redacted, consented, generated, or replaced. |
| AI makes things up. | Blocked is better than bluffing. | Unsupported claims show as blocked instead of becoming copy. |
| This will replace people before it understands the work. | The first slice is small on purpose. | Human approval remains part of the workflow slice. |
| My tools already do not talk to each other. | The operating map starts with the disconnected tools the owner already uses. | Integration starts with one workflow path, not the whole company. |
| Every consultant has a framework. | The method is visible enough to inspect. | Runbooks, tests, receipts, and blockers sit behind the story. |
| AI changes too fast. | Fast tools go through a controlled loop. | Tool claims require current receipts before promotion. |
| If it fails, I will be stuck. | Stop conditions are named up front. | Failed proof does not become a public claim. |
| I do not want to become an AI expert. | The owner approves the slice; the operator manages the machinery. | Technical proof is available but not required to understand the offer. |

## Page Rooms

| Room | Component | Owner job | Proof source |
|---|---|---|---|
| `operating-room-hero` | `OperatingRoomHero` | Make the owner feel the trapped work between tools before naming AI. | message_pack.story_arc[recognize] |
| `owner-tension-room` | `OwnerTensionRoom` | Name the ten reasons SMB owners hesitate and show the control beside each one. | message_pack.trust_objections |
| `slice-workbench` | `SliceWorkbench` | Define a slice as the safe unit of work: useful, inspectable, stoppable. | message_pack.story_arc[bound] |
| `proof-theater` | `ProofRail` | Show proven, blocked, skipped, and private states without forcing raw receipt reading. | message_pack.proof_translation |
| `trajectory-room` | `TrajectoryRail` | Convert git history into origin, friction, proof loop, reuse, and current arc. | chapters |
| `lesson-ledger` | `LessonLedger` | Show which lessons became shared checks, copy, tokens, components, or runbooks. | chapters[reuse] |
| `decision-room` | `ProofDrawer` | Let technical reviewers inspect artifacts after the owner story lands. | docs/evidence/publication-evidence.md |
| `safe-contact-room` | `SafeContactPanel` | Ask for a redacted workflow example, not secrets or broad access. | message_pack.story_arc[act] |

## Proof Summary

- Commit span: `2026-04-30 to 2026-05-14`
- Commits inspected: `1509`
- Friction signals: `226`
- Proof-loop signals: `805`
- Reuse signals: `667`
- Owner translation: The repo shows origin, friction, proof, reuse, and story work as a path a reviewer can inspect.

## Evidence Refs

- `docs/evidence/repo-trajectory.json`: The message comes from work history, not a fresh pitch.
- `docs/stories/repo-trajectory.md`: A reviewer can inspect the path from origin to current state.
- `packages/zeststream-story-system/story-system.json`: The wording and visual grammar are reusable across projects.
- `scripts/zs-frontend-quality-gate.sh --json --strict`: A page cannot pass as a generic card stack with unsupported claims.
- `@zeststream/ui`: The proof story has shared UI primitives instead of one-off copy.

## CTA

Primary: `Map my workflow`

Secondary: `Inspect the proof`
