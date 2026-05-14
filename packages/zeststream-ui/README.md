# ZestStream UI

Schema: `zeststream.ui_package.v0`
Status: `candidate-shared-foundation`

This package carries React visual primitives for ZestStream public surfaces. It
is the component layer beside `@zeststream/story-system`: the story system names
the grammar, and this package renders proof states, workflow maps, owner trust
controls, and telemetry texture.

Current exports:

| Export | Purpose |
|---|---|
| `ProofRail` | Shows proven, blocked, skipped-with-reason, and private proof states. |
| `WorkflowMap` | Shows the route between business systems and the selected workflow slice. |
| `SliceWorkbench` | Defines one bounded improvement with before state, after state, and scope note. |
| `TrustWorryMatrix` | Maps SMB owner worries to visible controls and proof behavior. |
| `TelemetryBar` | Adds live-system texture without claiming fake runtime proof. |
| `OperatingRoomHero` | Opens inside the business workflow room instead of a generic SaaS hero. |
| `YuzuMethodRail` | Presents the Yuzu Method stages as a visible operating sequence. |
| `ProofDrawer` | Translates receipts into owner-readable proof detail on demand. |
| `LessonLedger` | Shows how lessons carry from one repo or workflow into the next. |
| `SafeContactPanel` | Keeps the first CTA bounded to one inspectable workflow slice. |

The package is intentionally private until Flywheel 2.0 publication cutover is
approved. Downstream Next.js projects can still consume it through workspace or
local package wiring during staged review.
