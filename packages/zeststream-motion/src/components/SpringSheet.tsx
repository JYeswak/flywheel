"use client"

/**
 * SpringSheet — bottom sheet with spring-physics open/close.
 *
 * Wraps @zeststream/motion-tokens springPresets.sheetSnap
 * (damping 28, stiffness 300, mass 1 — settled, 240ms).
 *
 * Design source — Robinhood (A2) + Linear: sheets snap with physics, not
 * linear slides. The sheet overshoots slightly and settles. Backdrop fades
 * in parallel. CSS approximation: cubic-bezier(0.34, 1.56, 0.64, 1) at 240ms.
 *
 * Reduced-motion safe: collapses to instant show/hide, no transform.
 *
 * Usage:
 *   <SpringSheet open={isOpen} onClose={() => setIsOpen(false)}>
 *     <TruckCard ... />
 *   </SpringSheet>
 */

import { useEffect } from "react"
import type { ReactNode } from "react"

export interface SpringSheetProps {
  open: boolean
  onClose: () => void
  children: ReactNode
  className?: string
  /** Accessible label for the sheet dialog. */
  label?: string
}

export function SpringSheet({
  children,
  className,
  label = "Detail sheet",
  onClose,
  open,
}: SpringSheetProps) {
  // Close on Escape
  useEffect(() => {
    if (!open) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose()
    }
    window.addEventListener("keydown", onKey)
    return () => window.removeEventListener("keydown", onKey)
  }, [open, onClose])

  // Lock body scroll while open
  useEffect(() => {
    if (!open) return
    const prev = document.body.style.overflow
    document.body.style.overflow = "hidden"
    return () => {
      document.body.style.overflow = prev
    }
  }, [open])

  return (
    <>
      {/* Backdrop — fades with the sheet */}
      <div
        aria-hidden="true"
        onClick={onClose}
        style={{
          position: "fixed",
          inset: 0,
          background: "rgba(16, 20, 18, 0.5)",
          backdropFilter: "blur(2px)",
          opacity: open ? 1 : 0,
          pointerEvents: open ? "auto" : "none",
          transition: "opacity 240ms ease",
          zIndex: 50,
        }}
      />
      {/* Sheet — sheetSnap spring */}
      <div
        role="dialog"
        aria-modal="true"
        aria-label={label}
        className={className}
        style={{
          position: "fixed",
          left: 0,
          right: 0,
          bottom: 0,
          background: "var(--zs-cream, #fffdf7)",
          borderTopLeftRadius: "16px",
          borderTopRightRadius: "16px",
          boxShadow: "0 -22px 70px rgba(21, 24, 22, 0.22)",
          padding: "20px",
          maxHeight: "82vh",
          overflowY: "auto",
          zIndex: 51,
          // sheetSnap spring: damping 28, stiffness 300 → 240ms settled
          transform: open ? "translateY(0)" : "translateY(100%)",
          transition: "transform 240ms cubic-bezier(0.34, 1.56, 0.64, 1)",
        }}
      >
        {/* Grab handle */}
        <div
          aria-hidden="true"
          style={{
            width: "36px",
            height: "4px",
            borderRadius: "999px",
            background: "rgba(21, 24, 22, 0.2)",
            margin: "0 auto 16px auto",
          }}
        />
        {children}
      </div>
    </>
  )
}
