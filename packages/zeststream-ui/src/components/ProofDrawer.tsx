"use client"

/**
 * ProofDrawer — expandable drawer that shows proof without forcing the owner
 * to read raw receipts.
 *
 * Implements story-system.json "proof-theater" page section.
 *
 * Voice rule: "show proof without forcing the owner to read raw receipts."
 * The drawer collapsed shows a verdict + headline number. Expanded, it reveals
 * the receipt detail for those who want it. The owner stays in control of how
 * deep they go.
 *
 * Design source — frankentui.com "Built in 5 Days": build transparency as a
 * trust signal. The receipts exist and are one click away — but they don't
 * block the casual reader.
 *
 * Usage:
 *   <ProofDrawer
 *     verdict="proven"
 *     headline="12 runs, 0 errors over 3 weeks"
 *     receipts={[
 *       { label: "Run log", detail: "2026-04-22 → 2026-05-13, 12 executions", url: "/receipts/run-log.json" },
 *       { label: "Error rate", detail: "0/12 — no manual corrections needed" },
 *     ]}
 *   />
 */

import { useState } from "react"
import type { ProofState } from "./ProofRail"

export interface ProofReceipt {
  label: string
  detail: string
  url?: string
}

export interface ProofDrawerProps {
  verdict: ProofState
  headline: string
  receipts: ProofReceipt[]
  className?: string
  defaultOpen?: boolean
}

const VERDICT_CONFIG: Record<
  ProofState,
  { symbol: string; label: string; color: string; bg: string }
> = {
  proven: { symbol: "✓", label: "Proven", color: "#1f8f5f", bg: "rgba(212,243,74,0.10)" },
  blocked: { symbol: "✗", label: "Blocked", color: "#df5b46", bg: "rgba(223,91,70,0.08)" },
  "skipped-with-reason": {
    symbol: "→",
    label: "Scoped out",
    color: "#64706a",
    bg: "rgba(242,201,76,0.10)",
  },
  private: { symbol: "●", label: "Private", color: "#64706a", bg: "rgba(21,24,22,0.04)" },
}

export function ProofDrawer({
  className,
  defaultOpen = false,
  headline,
  receipts,
  verdict,
}: ProofDrawerProps) {
  const [open, setOpen] = useState(defaultOpen)
  const cfg = VERDICT_CONFIG[verdict]

  return (
    <div
      className={className}
      style={{
        background: cfg.bg,
        border: `1px solid ${cfg.color}33`,
        borderRadius: "10px",
        overflow: "hidden",
      }}
    >
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-expanded={open}
        style={{
          width: "100%",
          background: "transparent",
          border: "none",
          padding: "14px 16px",
          display: "flex",
          alignItems: "center",
          gap: "10px",
          cursor: "pointer",
          textAlign: "left",
          fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
        }}
      >
        <span
          style={{
            fontSize: "11px",
            fontWeight: 700,
            letterSpacing: "0.06em",
            textTransform: "uppercase",
            color: cfg.color,
            fontFamily: "var(--zs-font-mono, SFMono-Regular, Consolas, monospace)",
            flexShrink: 0,
          }}
        >
          {cfg.symbol} {cfg.label}
        </span>
        <span
          style={{
            fontSize: "14px",
            fontWeight: 600,
            color: "#151816",
            flex: 1,
          }}
        >
          {headline}
        </span>
        <span
          aria-hidden="true"
          style={{
            fontSize: "12px",
            color: "#64706a",
            transform: open ? "rotate(180deg)" : "rotate(0deg)",
            transition: "transform 200ms ease",
          }}
        >
          ▾
        </span>
      </button>
      {open && (
        <div
          style={{
            padding: "0 16px 14px 16px",
            display: "flex",
            flexDirection: "column",
            gap: "8px",
          }}
        >
          {receipts.map((receipt) => {
            const row = (
              <div
                style={{
                  background: "rgba(255, 253, 247, 0.7)",
                  border: "1px solid rgba(21, 24, 22, 0.1)",
                  borderRadius: "6px",
                  padding: "8px 10px",
                  display: "flex",
                  flexDirection: "column",
                  gap: "2px",
                }}
              >
                <span
                  style={{
                    fontSize: "11px",
                    fontWeight: 700,
                    color: "#151816",
                    fontFamily:
                      "var(--zs-font-mono, SFMono-Regular, Consolas, monospace)",
                  }}
                >
                  {receipt.label}
                  {receipt.url && (
                    <span style={{ color: cfg.color, marginLeft: "6px" }}>↗</span>
                  )}
                </span>
                <span
                  style={{
                    fontSize: "12px",
                    color: "#2e3632",
                    fontFamily:
                      "var(--zs-font-sans, Inter, system-ui, sans-serif)",
                    lineHeight: 1.4,
                  }}
                >
                  {receipt.detail}
                </span>
              </div>
            )
            return receipt.url ? (
              <a
                key={receipt.label}
                href={receipt.url}
                target="_blank"
                rel="noopener noreferrer"
                style={{ textDecoration: "none" }}
              >
                {row}
              </a>
            ) : (
              <div key={receipt.label}>{row}</div>
            )
          })}
        </div>
      )}
    </div>
  )
}
