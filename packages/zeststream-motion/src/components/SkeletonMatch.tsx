"use client"

/**
 * SkeletonMatch — skeleton loading state that matches the final layout.
 *
 * Design source — AI-native UI patterns 2025-2026: the critical detail is that
 * the skeleton must have the SAME DOM structure as the loaded state — same
 * grid, same padding, same heading heights. Otherwise layout shift on load
 * undermines the whole point. A skeleton that doesn't match is worse than a
 * spinner.
 *
 * SkeletonMatch takes a `shape` describing the final layout and renders
 * pulse-animated placeholders at the exact dimensions. When `ready`, it renders
 * children instead — no layout shift because the dims matched.
 *
 * Reduced-motion safe: pulse animation disabled, static placeholder shown.
 *
 * Usage:
 *   <SkeletonMatch
 *     ready={!!data}
 *     shape={[
 *       { kind: "line", width: "60%", height: 20 },   // heading
 *       { kind: "line", width: "100%", height: 14 },  // body
 *       { kind: "line", width: "100%", height: 14 },
 *       { kind: "block", width: "100%", height: 120 }, // card
 *     ]}
 *   >
 *     <ActualContent data={data} />
 *   </SkeletonMatch>
 */

import type { ReactNode } from "react"

export interface SkeletonElement {
  kind: "line" | "block" | "circle"
  width: string | number
  height: string | number
  /** Gap below this element. */
  marginBottom?: number
}

export interface SkeletonMatchProps {
  ready: boolean
  shape: SkeletonElement[]
  children: ReactNode
  className?: string
  /** Accessible label while loading. */
  loadingLabel?: string
}

function dim(value: string | number): string {
  return typeof value === "number" ? `${value}px` : value
}

export function SkeletonMatch({
  children,
  className,
  loadingLabel = "Loading",
  ready,
  shape,
}: SkeletonMatchProps) {
  if (ready) {
    return <>{children}</>
  }

  return (
    <div
      className={className}
      role="status"
      aria-label={loadingLabel}
      aria-busy="true"
      style={{ display: "flex", flexDirection: "column" }}
    >
      {shape.map((el, i) => (
        <div
          key={i}
          aria-hidden="true"
          style={{
            width: dim(el.width),
            height: dim(el.height),
            marginBottom: dim(el.marginBottom ?? 10),
            borderRadius:
              el.kind === "circle"
                ? "50%"
                : el.kind === "block"
                  ? "10px"
                  : "4px",
            background:
              "linear-gradient(90deg, " +
              "rgba(21,24,22,0.06) 0%, " +
              "rgba(21,24,22,0.12) 50%, " +
              "rgba(21,24,22,0.06) 100%)",
            backgroundSize: "200% 100%",
            animation: "zs-skeleton-pulse 1.4s ease-in-out infinite",
          }}
        />
      ))}
      <style>{`
        @keyframes zs-skeleton-pulse {
          0% { background-position: 200% 0; }
          100% { background-position: -200% 0; }
        }
        @media (prefers-reduced-motion: reduce) {
          [style*="zs-skeleton-pulse"] {
            animation: none !important;
            background: rgba(21,24,22,0.08) !important;
          }
        }
      `}</style>
    </div>
  )
}
