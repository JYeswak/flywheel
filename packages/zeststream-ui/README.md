# ZestStream UI

Schema: `zeststream.ui_package.v0`
Status: `candidate-shared-foundation`

This package carries React visual primitives for ZestStream public surfaces. It
is the component layer beside `@zeststream/story-system`: the story system names
the grammar, and this package renders proof states, workflow maps, owner trust
controls, and telemetry texture.

## Design sources

Every component traces to a studied next-gen reference. This is not generic
"best practices" — each pattern is sourced.

| Source | What we took |
|---|---|
| **jeffreyemanuel.com** | Numbers over adjectives. The dashboard-as-personal-site move — vanity metrics surfaced as proof-of-work. |
| **frankentui.com** | Telemetry aesthetic — fake-but-coherent system status makes a page feel like a live system. Build transparency as trust. |
| **asupersync.com** | Architecture diagram as the pitch — putting the diagram in the hero tells the reader if this is for them. Neologism strategy. |
| **agentflywheel.com** | Methodology as product. Pre-qualification copy — explicit "this is not" criteria build trust by turning away the wrong reader. |

## Exports

| Export | Purpose |
|---|---|
| `ProofRail` | Shows proven, blocked, skipped-with-reason, and private proof states. "7/9 proven" beats "most things work." Every item has a receipt URL slot. |
| `ProofDrawer` | Translates receipts into owner-readable proof detail on demand. Collapsed: verdict + headline number. Expanded: the receipts. |
| `WorkflowMap` | Shows the route between business systems and the selected workflow slice. Edge colors encode proof state. |
| `SliceWorkbench` | Defines one bounded improvement with before state, after state, and scope note. Makes "this slice only" visually explicit. |
| `TrustWorryMatrix` | Maps SMB owner worries to visible answers and proof behavior. Names the worry before the machinery. |
| `TelemetryBar` | Adds live-system texture without claiming fake runtime proof. |
| `OperatingRoomHero` | Opens inside the business workflow room instead of a generic SaaS hero. |
| `YuzuMethodRail` | Presents the Yuzu Method stages (recognize → bound → control → remember → act) as a visible operating sequence. |
| `LessonLedger` | Shows how lessons carry from one repo or workflow into the next — the flywheel made legible. |
| `SafeContactPanel` | Keeps the first CTA bounded to one inspectable workflow slice; carries the 4 trust anchors + "this is not" pre-qualification. |

## Installation

```bash
pnpm add @zeststream/ui @zeststream/story-system
```

Import the design tokens once in your root layout:

```tsx
import "@zeststream/story-system/tokens.css"
```

## Usage

```tsx
import { OperatingRoomHero, ProofRail } from "@zeststream/ui"

<OperatingRoomHero
  headline="Buy back the time hiding between your tools"
  subhead="Map one workflow. Improve one bounded slice. Prove what changed."
  tools={["Email", "CRM", "Calendar", "Invoice", "Docs", "Reports"]}
  activeRoute={["Email", "CRM"]}
  primaryCta={{ label: "Map my workflow", href: "/start" }}
/>

<ProofRail
  title="v0.2.0 Publication Evidence"
  items={[
    { label: "Install works", state: "proven", detail: "pass=10 fail=0" },
    { label: "Public repo", state: "blocked", detail: "Awaiting cutover auth" },
  ]}
/>
```

Per-component import paths are also exported (`@zeststream/ui/proof-rail`, etc.).

## Tokens

All components consume `--zs-*` CSS custom properties. If the tokens aren't
imported, components fall back to system fonts and a hardcoded brand palette —
they degrade gracefully, they don't break.

## Accessibility

Every component uses semantic HTML, carries `aria-label` on interactive and
image-role elements, and respects `prefers-reduced-motion`.

## Development

```bash
pnpm install      # installs @types/react for standalone typecheck
pnpm typecheck    # tsc --noEmit, must exit 0
```

The package typechecks standalone — no consuming-repo setup required.

## Quality gate

Frontends consuming this package are audited by the `zs-frontend-quality-gate`
skill (10 checks: fonts, tokens, motion, a11y, proof states, brand voice).
FQ-08 and FQ-10 check for `@zeststream/ui` adoption specifically. Run before
every deploy:

```bash
bash ~/.claude/skills/zs-frontend-quality-gate/scripts/zs-frontend-quality-gate.sh --repo <path> --strict
```

## Companion packages

- **`@zeststream/motion`** — motion primitives plus `@zeststream/motion/tokens` spring presets
- **`@zeststream/story-system`** — brand voice schema + design tokens (`tokens.css`)

## Status

Intentionally private until Flywheel 2.0 publication cutover is approved.
Downstream Next.js projects consume it through workspace or local package
wiring during staged review.
