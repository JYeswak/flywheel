"use client"

import type { ProofState } from "./ProofRail"

export interface TrustWorry {
  worry: string
  visibleAnswer: string
  proofBehavior: string
  state?: ProofState
  receiptUrl?: string
}

export interface TrustWorryMatrixProps {
  items: TrustWorry[]
  className?: string
  title?: string
}

const STATE_STYLE: Record<ProofState, { label: string; color: string; background: string }> = {
  proven: {
    label: "Proven",
    color: "#1f8f5f",
    background: "rgba(212, 243, 74, 0.12)",
  },
  blocked: {
    label: "Blocked",
    color: "#df5b46",
    background: "rgba(223, 91, 70, 0.10)",
  },
  "skipped-with-reason": {
    label: "Scoped",
    color: "#64706a",
    background: "rgba(242, 201, 76, 0.14)",
  },
  private: {
    label: "Private",
    color: "#64706a",
    background: "rgba(21, 24, 22, 0.06)",
  },
}

function stateLabel(state: ProofState) {
  const cfg = STATE_STYLE[state]
  return (
    <span
      style={{
        alignSelf: "flex-start",
        background: cfg.background,
        borderRadius: "999px",
        color: cfg.color,
        fontFamily: "var(--zs-font-mono, SFMono-Regular, Consolas, monospace)",
        fontSize: "10px",
        fontWeight: 700,
        letterSpacing: "0.04em",
        padding: "3px 8px",
        textTransform: "uppercase",
      }}
    >
      {cfg.label}
    </span>
  )
}

function TrustCard({ item }: { item: TrustWorry }) {
  const state = item.state ?? "proven"
  const content = (
    <article
      style={{
        background: "rgba(255, 253, 247, 0.78)",
        border: "1px solid rgba(21, 24, 22, 0.14)",
        borderRadius: "8px",
        boxShadow: "0 16px 48px rgba(21, 24, 22, 0.08)",
        display: "flex",
        flexDirection: "column",
        gap: "10px",
        minHeight: "190px",
        padding: "16px",
      }}
    >
      {stateLabel(state)}
      <div style={{ display: "grid", gap: "6px" }}>
        <p
          style={{
            color: "#151816",
            fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
            fontSize: "15px",
            fontWeight: 700,
            lineHeight: 1.25,
            margin: 0,
          }}
        >
          {item.worry}
        </p>
        <p
          style={{
            color: "#1f8f5f",
            fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
            fontSize: "14px",
            fontWeight: 650,
            lineHeight: 1.35,
            margin: 0,
          }}
        >
          {item.visibleAnswer}
        </p>
      </div>
      <p
        style={{
          color: "#64706a",
          fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
          fontSize: "13px",
          lineHeight: 1.45,
          margin: 0,
        }}
      >
        {item.proofBehavior}
      </p>
    </article>
  )

  if (!item.receiptUrl) return content
  return (
    <a
      href={item.receiptUrl}
      rel="noopener noreferrer"
      style={{ color: "inherit", textDecoration: "none" }}
      target="_blank"
      aria-label={`Inspect proof for ${item.worry}`}
    >
      {content}
    </a>
  )
}

export function TrustWorryMatrix({ className, items, title = "Owner worries" }: TrustWorryMatrixProps) {
  if (items.length === 0) return null

  return (
    <section className={className} aria-label={title}>
      <div
        style={{
          display: "grid",
          gap: "12px",
          gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
        }}
      >
        {items.map((item) => (
          <TrustCard key={`${item.worry}:${item.visibleAnswer}`} item={item} />
        ))}
      </div>
    </section>
  )
}
