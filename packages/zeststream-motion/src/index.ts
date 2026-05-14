/**
 * @zeststream/motion — ZestStream motion primitives
 *
 * Reusable React motion components built on @zeststream/motion-tokens spring
 * presets. All components are reduced-motion safe.
 *
 * Design sources (see package.json zeststream.design_sources):
 * - Robinhood — spring physics budget (A2)
 * - Citizen — live-confirmation pulse (A3)
 * - Linear — instant-snap menus
 * - AI-native 2025-2026 — streaming text, skeleton-matches-layout, categorical confidence
 *
 * Components consume --zs-* CSS custom properties from
 * @zeststream/story-system/tokens.css.
 */

export { SpringChip } from "./components/SpringChip"
export type { SpringChipProps } from "./components/SpringChip"

export { SpringSheet } from "./components/SpringSheet"
export type { SpringSheetProps } from "./components/SpringSheet"

export { ConfidenceBadge } from "./components/ConfidenceBadge"
export type { ConfidenceBadgeProps, ConfidenceLevel } from "./components/ConfidenceBadge"

export { StreamingText } from "./components/StreamingText"
export type { StreamingTextProps } from "./components/StreamingText"

export { SkeletonMatch } from "./components/SkeletonMatch"
export type { SkeletonElement, SkeletonMatchProps } from "./components/SkeletonMatch"
