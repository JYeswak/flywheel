"use client"

/**
 * SpringChip — toggle/filter chip with spring physics on selection.
 *
 * Wraps @zeststream/motion-tokens springPresets.filterChip
 * (damping 20, stiffness 400, mass 1 — snappy, 160ms settle).
 *
 * Design source — Robinhood (A2): spring physics for state changes, not
 * duration curves. The chip snaps when selected, giving it a sense of mass.
 * CSS approximation: cubic-bezier(0.34, 1.56, 0.64, 1) at 160ms.
 *
 * Reduced-motion safe: collapses to instant toggle.
 *
 * Usage:
 *   <SpringChip selected={mode === "open"} onSelect={() => setMode("open")}>
 *     Open now
 *   </SpringChip>
 */

import type { ReactNode } from "react"

export interface SpringChipProps {
  children: ReactNode
  selected: boolean
  onSelect: () => void
  className?: string
  "aria-label"?: string
}

export function SpringChip({
  children,
  className,
  onSelect,
  selected,
  "aria-label": ariaLabel,
}: SpringChipProps) {
  return (
    <button
      type="button"
      onClick={onSelect}
      aria-pressed={selected}
      aria-label={ariaLabel}
      className={className}
      style={{
        appearance: "none",
        cursor: "pointer",
        borderRadius: "999px",
        padding: "6px 14px",
        fontSize: "13px",
        fontWeight: selected ? 650 : 500,
        fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
        background: selected ? "#151816" : "rgba(255, 253, 247, 0.8)",
        color: selected ? "#fffdf7" : "#2e3632",
        border: selected
          ? "1.5px solid #151816"
          : "1px solid rgba(21, 24, 22, 0.2)",
        // filterChip spring: damping 20, stiffness 400 → 160ms snappy
        transition:
          "transform 160ms cubic-bezier(0.34, 1.56, 0.64, 1), " +
          "background 160ms ease, color 120ms ease, " +
          "border-color 120ms ease, font-weight 0ms",
        transform: selected ? "scale(1.04)" : "scale(1)",
      }}
      onMouseDown={(e) => {
        ;(e.currentTarget as HTMLButtonElement).style.transform = "scale(0.97)"
      }}
      onMouseUp={(e) => {
        ;(e.currentTarget as HTMLButtonElement).style.transform = selected
          ? "scale(1.04)"
          : "scale(1)"
      }}
      onMouseLeave={(e) => {
        ;(e.currentTarget as HTMLButtonElement).style.transform = selected
          ? "scale(1.04)"
          : "scale(1)"
      }}
    >
      {children}
    </button>
  )
}
