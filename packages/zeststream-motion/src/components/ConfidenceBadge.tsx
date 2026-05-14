"use client"

/**
 * ConfidenceBadge — AI-native categorical confidence indicator.
 *
 * Design source — AI-native UI patterns 2025-2026: confidence is communicated
 * as a CATEGORICAL signal, not a percentage number. "Verified" / "Estimated" /
 * "Needs review" — not "87%". A percentage implies false precision; a category
 * tells the user how much to trust the output and what to do next.
 *
 * Maps directly to ZestStream's proof-state vocabulary. The badge is the
 * lightweight inline cousin of @zeststream/ui's ProofRail.
 *
 * Usage:
 *   <ConfidenceBadge level="verified" />
 *   <ConfidenceBadge level="estimated" detail="Based on last 3 sightings" />
 *   <ConfidenceBadge level="needs-review" detail="No owner confirmation in 8h" />
 */

export type ConfidenceLevel = "verified" | "estimated" | "needs-review" | "stale"

export interface ConfidenceBadgeProps {
  level: ConfidenceLevel
  /** Optional one-line explanation of why this confidence level. */
  detail?: string
  className?: string
  /** Compact mode: dot + label only, no detail. */
  compact?: boolean
}

const LEVEL_CONFIG: Record<
  ConfidenceLevel,
  { label: string; symbol: string; color: string; bg: string }
> = {
  verified: {
    label: "Verified",
    symbol: "✓",
    color: "#1f8f5f",
    bg: "rgba(212, 243, 74, 0.14)",
  },
  estimated: {
    label: "Estimated",
    symbol: "≈",
    color: "#2a6fbb",
    bg: "rgba(42, 111, 187, 0.10)",
  },
  "needs-review": {
    label: "Needs review",
    symbol: "?",
    color: "#f08f3e",
    bg: "rgba(240, 143, 62, 0.12)",
  },
  stale: {
    label: "Stale",
    symbol: "○",
    color: "#64706a",
    bg: "rgba(100, 112, 106, 0.10)",
  },
}

export function ConfidenceBadge({
  className,
  compact = false,
  detail,
  level,
}: ConfidenceBadgeProps) {
  const cfg = LEVEL_CONFIG[level]

  return (
    <span
      className={className}
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: "5px",
        background: cfg.bg,
        border: `1px solid ${cfg.color}40`,
        borderRadius: "999px",
        padding: compact ? "2px 8px" : "3px 10px",
        fontSize: compact ? "10px" : "11px",
        fontWeight: 650,
        color: cfg.color,
        fontFamily: "var(--zs-font-mono, SFMono-Regular, Consolas, monospace)",
        letterSpacing: "0.02em",
        whiteSpace: "nowrap",
      }}
      title={detail}
      aria-label={
        detail ? `Confidence: ${cfg.label}. ${detail}` : `Confidence: ${cfg.label}`
      }
    >
      <span aria-hidden="true">{cfg.symbol}</span>
      <span>{cfg.label}</span>
      {!compact && detail && (
        <span
          style={{
            fontWeight: 400,
            opacity: 0.8,
            fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
            textTransform: "none",
            letterSpacing: "normal",
          }}
        >
          · {detail}
        </span>
      )}
    </span>
  )
}
