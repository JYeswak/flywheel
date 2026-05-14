"use client"

/**
 * ProofRail — evidence rail for workflow slice proof states.
 *
 * Implements the ZestStream proof state taxonomy from story-system.json:
 * proven / blocked / skipped-with-reason / private
 *
 * Jeff Emanuel design principles:
 * - Numbers over adjectives: "7/9 proven" not "most things work"
 * - Build transparency as trust: every claim has a receipt URL
 * - Telemetry aesthetic: status reads like a live system, not a checklist
 *
 * Usage:
 *   import { ProofRail } from "@zeststream/ui/proof-rail"
 *
 *   <ProofRail items={[
 *     { label: "Email → CRM", state: "proven", detail: "12 runs, 0 errors", receiptUrl: "/receipts/..." },
 *     { label: "Invoice send", state: "blocked", detail: "Awaiting DocuSign key" },
 *     { label: "Reporting", state: "skipped-with-reason", detail: "Out of scope for v1" },
 *   ]} />
 */

export type ProofState = "proven" | "blocked" | "skipped-with-reason" | "private"

export interface ProofItem {
  label: string
  state: ProofState
  detail?: string
  receiptUrl?: string
}

export interface ProofRailProps {
  items: ProofItem[]
  className?: string
  showCount?: boolean
  title?: string
}

const STATE_CONFIG: Record<
  ProofState,
  { symbol: string; label: string; dotColor: string; bgColor: string; borderColor: string; textColor: string }
> = {
  proven: {
    symbol: "✓",
    label: "Proven",
    dotColor: "#d4f34a",
    bgColor: "rgba(212, 243, 74, 0.08)",
    borderColor: "rgba(212, 243, 74, 0.28)",
    textColor: "#1f8f5f",
  },
  blocked: {
    symbol: "✗",
    label: "Blocked",
    dotColor: "#df5b46",
    bgColor: "rgba(223, 91, 70, 0.08)",
    borderColor: "rgba(223, 91, 70, 0.28)",
    textColor: "#df5b46",
  },
  "skipped-with-reason": {
    symbol: "→",
    label: "Scoped out",
    dotColor: "#f2c94c",
    bgColor: "rgba(242, 201, 76, 0.08)",
    borderColor: "rgba(242, 201, 76, 0.28)",
    textColor: "#64706a",
  },
  private: {
    symbol: "●",
    label: "Private",
    dotColor: "#64706a",
    bgColor: "rgba(21, 24, 22, 0.04)",
    borderColor: "rgba(21, 24, 22, 0.12)",
    textColor: "#64706a",
  },
}

function ProofCard({ item }: { item: ProofItem }) {
  const cfg = STATE_CONFIG[item.state]

  const content = (
    <div
      style={{
        background: cfg.bgColor,
        border: `1px solid ${cfg.borderColor}`,
        borderRadius: "8px",
        padding: "8px 12px",
        display: "flex",
        flexDirection: "column",
        gap: "4px",
        minWidth: "140px",
        flex: "1 1 140px",
        maxWidth: "240px",
        cursor: item.receiptUrl ? "pointer" : "default",
        transition: "box-shadow 150ms ease",
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
        <span
          style={{
            width: "6px",
            height: "6px",
            borderRadius: "50%",
            backgroundColor: cfg.dotColor,
            flexShrink: 0,
          }}
          aria-hidden="true"
        />
        <span
          style={{
            fontSize: "12px",
            fontWeight: 500,
            color: "#151816",
            fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
            overflow: "hidden",
            textOverflow: "ellipsis",
            whiteSpace: "nowrap",
          }}
        >
          {item.label}
        </span>
      </div>
      {item.detail && (
        <p
          style={{
            fontSize: "11px",
            color: cfg.textColor,
            fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
            lineHeight: 1.4,
            margin: 0,
          }}
        >
          {item.detail}
        </p>
      )}
      <span
        style={{
          fontSize: "9px",
          fontWeight: 600,
          letterSpacing: "0.08em",
          textTransform: "uppercase",
          color: cfg.textColor,
          fontFamily: "var(--zs-font-mono, SFMono-Regular, Consolas, monospace)",
        }}
      >
        {cfg.symbol} {cfg.label}
      </span>
    </div>
  )

  if (item.receiptUrl) {
    return (
      <a
        href={item.receiptUrl}
        target="_blank"
        rel="noopener noreferrer"
        style={{ display: "flex", flex: "1 1 140px", maxWidth: "240px", textDecoration: "none" }}
        aria-label={`Receipt: ${item.label}`}
      >
        {content}
      </a>
    )
  }

  return content
}

export function ProofRail({ className, items, showCount = true, title }: ProofRailProps) {
  if (items.length === 0) return null

  const provenCount = items.filter((i) => i.state === "proven").length

  return (
    <div
      className={className}
      style={{ display: "flex", flexDirection: "column", gap: "8px" }}
    >
      <div
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
        }}
      >
        <span
          style={{
            fontSize: "10px",
            fontWeight: 600,
            letterSpacing: "0.1em",
            textTransform: "uppercase",
            color: "#64706a",
            fontFamily: "var(--zs-font-mono, SFMono-Regular, Consolas, monospace)",
          }}
        >
          {title ?? "Evidence"}
        </span>
        {showCount && (
          <span
            style={{
              fontSize: "11px",
              color: "#64706a",
              fontFamily: "var(--zs-font-mono, SFMono-Regular, Consolas, monospace)",
            }}
          >
            <span style={{ fontWeight: 600, color: "#1f8f5f" }}>{provenCount}</span>
            {" / "}
            {items.length}
            {" "}
            <span style={{ fontSize: "9px", textTransform: "uppercase", letterSpacing: "0.06em" }}>
              proven
            </span>
          </span>
        )}
      </div>
      <div style={{ display: "flex", flexWrap: "wrap", gap: "8px" }}>
        {items.map((item) => (
          <ProofCard key={item.label} item={item} />
        ))}
      </div>
    </div>
  )
}
