/**
 * @zeststream/ui — canonical ZestStream React component library
 *
 * Visual primitives from story-system.json, implemented in React.
 * Consumers: flywheel-docs, mobile-eats, clutterfreespaces
 *
 * Jeff Emanuel design principles throughout:
 * - Numbers over adjectives in ProofRail
 * - Telemetry aesthetic in TelemetryBar
 * - Architecture diagram as pitch in WorkflowMap
 */

export { ProofRail } from "./components/ProofRail"
export type { ProofItem, ProofRailProps, ProofState } from "./components/ProofRail"

export { TelemetryBar } from "./components/TelemetryBar"
export type { TelemetryBarProps, TelemetryEntry, TelemetryVariant } from "./components/TelemetryBar"

export { WorkflowMap } from "./components/WorkflowMap"
export type {
  NodeRole,
  WorkflowEdge,
  WorkflowMapProps,
  WorkflowNode,
} from "./components/WorkflowMap"
