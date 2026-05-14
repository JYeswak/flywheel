# @zeststream/motion

Schema: `zeststream.motion_package.v0`
Status: `candidate-shared-foundation`

Reusable React motion primitives with exported spring presets at
`@zeststream/motion/tokens`. Every component is reduced-motion safe — animations collapse to
instant under `prefers-reduced-motion`, no transform.

## Design sources

| Source | What we took |
|---|---|
| **Robinhood** | Spring physics budget (A2): damping 22-28, stiffness 300-400. "Responsive but settled" — elements overshoot slightly then correct, giving a sense of mass. |
| **Citizen** | Live-confirmation pulse (A3): one expanding ring, 1200ms expand, 4s cycle. Not a strobe. |
| **Linear** | Instant-snap menus — zero delay before motion starts, fast spring settle. |
| **AI-native 2025-2026** | Streaming text with cursor-first reveal, skeletons that match final layout, categorical (not percentage) confidence signals. |

## Exports

| Export | Purpose |
|---|---|
| `SpringChip` | Toggle/filter chip with spring physics on selection. filterChip preset (damping 20, stiffness 400 → snappy 160ms). Selected chips scale 1.04, press compresses to 0.97. |
| `SpringSheet` | Bottom sheet with spring open/close. sheetSnap preset (damping 28, stiffness 300 → settled 240ms). Backdrop fades in parallel. Escape closes, body scroll locks. |
| `ConfidenceBadge` | AI-native categorical confidence indicator. `verified / estimated / needs-review / stale` — not a percentage. A category tells the user how much to trust the output and what to do next. |
| `StreamingText` | Word-by-word reveal for AI-streamed content. Cursor blinks before the first token so the user knows generation is happening. Word-by-word, not character (character reads as retro typewriter). |
| `SkeletonMatch` | Skeleton loading state that matches the final layout exactly. Takes a `shape` describing final dimensions — no layout shift on load, because the skeleton dims matched. |
| `springPresets` | Self-contained spring budgets for filter chips, sheets, and live pulses. |
| `motionDurations` | Named duration values derived from the spring presets. |

## Installation

```bash
pnpm add @zeststream/motion @zeststream/story-system
```

## Usage

```tsx
import { SpringChip, ConfidenceBadge, StreamingText } from "@zeststream/motion"

// Filter chip with spring select
<SpringChip selected={mode === "open"} onSelect={() => setMode("open")}>
  Open now
</SpringChip>

// AI confidence — categorical, not a percentage
<ConfidenceBadge level="verified" detail="Owner-confirmed 12m ago" />

// Streaming AI text — cursor before first token
<StreamingText text={accumulatedTokens} streaming={!done} />
```

Per-component import paths: `@zeststream/motion/spring-chip`, etc.
Raw motion values are exported from `@zeststream/motion/tokens`.

## Reduced-motion safety

This is not optional. Every component:
- `SpringChip` / `SpringSheet` — transitions collapse to instant
- `StreamingText` — shows full text immediately, no reveal animation
- `SkeletonMatch` — pulse animation disabled, static placeholder

Tested against `(prefers-reduced-motion: reduce)`.

## Relationship to motion tokens

The raw layer lives inside this package as `@zeststream/motion/tokens`: spring
configs, durations, and easings as plain objects. Use the token export when
you're building a custom animated component; use the component exports when a
primitive already fits.

## Development

```bash
pnpm install      # installs @types/react for standalone typecheck
pnpm typecheck    # tsc --noEmit, must exit 0
```

## Companion packages

- **`@zeststream/ui`** — visual primitives (ProofRail, WorkflowMap, OperatingRoomHero, ...)
- **`@zeststream/story-system`** — brand voice schema + design tokens
