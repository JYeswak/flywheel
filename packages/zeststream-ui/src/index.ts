/**
 * @zeststream/ui — canonical ZestStream React component library
 *
 * 10 visual primitives from story-system.json, implemented in React.
 * Consumers: flywheel-docs, mobile-eats, clutterfreespaces
 *
 * Design sources (see package.json zeststream.design_sources):
 * - jeffreyemanuel.com — numbers over adjectives, dashboard-as-personal-site
 * - frankentui.com — telemetry aesthetic, build transparency as trust
 * - asupersync.com — architecture diagram as pitch, neologism strategy
 * - agentflywheel.com — methodology as product, pre-qualification copy
 *
 * Every component consumes --zs-* CSS custom properties from
 * @zeststream/story-system/tokens.css. Import that once in your root layout.
 */

export { ProofRail } from "./components/ProofRail"
export type { ProofItem, ProofRailProps, ProofState } from "./components/ProofRail"

export { ProofDrawer } from "./components/ProofDrawer"
export type { ProofDrawerProps, ProofReceipt } from "./components/ProofDrawer"

export { TelemetryBar } from "./components/TelemetryBar"
export type {
  TelemetryBarProps,
  TelemetryEntry,
  TelemetryVariant,
} from "./components/TelemetryBar"

export { WorkflowMap } from "./components/WorkflowMap"
export type {
  NodeRole,
  WorkflowEdge,
  WorkflowMapProps,
  WorkflowNode,
} from "./components/WorkflowMap"

export { TrustWorryMatrix } from "./components/TrustWorryMatrix"
export type { TrustWorry, TrustWorryMatrixProps } from "./components/TrustWorryMatrix"

export { OperatingRoomHero } from "./components/OperatingRoomHero"
export type { OperatingRoomHeroProps } from "./components/OperatingRoomHero"

export { SliceWorkbench } from "./components/SliceWorkbench"
export type { SliceSide, SliceWorkbenchProps } from "./components/SliceWorkbench"

export { YuzuMethodRail } from "./components/YuzuMethodRail"
export type {
  YuzuMethodRailProps,
  YuzuStage,
  YuzuStageId,
} from "./components/YuzuMethodRail"

export { LessonLedger } from "./components/LessonLedger"
export type { Lesson, LessonLedgerProps } from "./components/LessonLedger"

export { SafeContactPanel } from "./components/SafeContactPanel"
export type { SafeContactPanelProps, TrustAnchor } from "./components/SafeContactPanel"
