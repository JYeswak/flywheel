"use client"

/**
 * SliceWorkbench — before/after view of one bounded workflow slice.
 *
 * Implements story-system.json "slice-workbench" page section.
 *
 * Core offer: "improve one bounded slice." The workbench shows exactly what the
 * slice was before (manual, copy-chase-check) and after (one route, less work),
 * with the bounded scope made visually explicit so the owner sees this is NOT
 * a whole-system replacement.
 *
 * Design source — jeffreyemanuel.com: numbers over adjectives. The "after" side
 * carries the measurable delta, not an adjective.
 *
 * Usage:
 *   <SliceWorkbench
 *     sliceName="New booking → CRM contact"
 *     before={{ steps: ["Copy email", "Paste into CRM", "Tag manually", "Check for dupes"], cost: "~6 min each, 40+/week" }}
 *     after={{ steps: ["Booking arrives", "Route fires", "Human approves"], cost: "~20 sec review, 0 copy errors" }}
 *     scopeNote="This slice only. Invoicing and reporting stay manual until proven."
 *   />
 */

export interface SliceSide {
  steps: string[]
  cost: string
}

export interface SliceWorkbenchProps {
  sliceName: string
  before: SliceSide
  after: SliceSide
  scopeNote: string
  className?: string
}

function StepList({
  steps,
  tone,
}: {
  steps: string[]
  tone: "before" | "after"
}) {
  const dotColor = tone === "before" ? "#df5b46" : "#1f8f5f"
  return (
    <ol
      style={{
        listStyle: "none",
        margin: 0,
        padding: 0,
        display: "flex",
        flexDirection: "column",
        gap: "8px",
      }}
    >
      {steps.map((step, i) => (
        <li
          key={`${i}:${step}`}
          style={{
            display: "flex",
            alignItems: "flex-start",
            gap: "8px",
            fontSize: "13px",
            lineHeight: 1.4,
            color: "#2e3632",
            fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
          }}
        >
          <span
            style={{
              width: "6px",
              height: "6px",
              borderRadius: "50%",
              background: dotColor,
              marginTop: "6px",
              flexShrink: 0,
            }}
            aria-hidden="true"
          />
          {step}
        </li>
      ))}
    </ol>
  )
}

function SidePanel({
  label,
  side,
  tone,
}: {
  label: string
  side: SliceSide
  tone: "before" | "after"
}) {
  const accent = tone === "before" ? "#df5b46" : "#1f8f5f"
  const bg =
    tone === "before"
      ? "rgba(223, 91, 70, 0.05)"
      : "rgba(212, 243, 74, 0.08)"
  return (
    <div
      style={{
        background: bg,
        border: `1px solid ${tone === "before" ? "rgba(223,91,70,0.22)" : "rgba(31,143,95,0.28)"}`,
        borderRadius: "10px",
        padding: "16px",
        display: "flex",
        flexDirection: "column",
        gap: "12px",
      }}
    >
      <span
        style={{
          fontSize: "10px",
          fontWeight: 700,
          letterSpacing: "0.1em",
          textTransform: "uppercase",
          color: accent,
          fontFamily: "var(--zs-font-mono, SFMono-Regular, Consolas, monospace)",
        }}
      >
        {label}
      </span>
      <StepList steps={side.steps} tone={tone} />
      <span
        style={{
          fontSize: "12px",
          fontWeight: 650,
          color: accent,
          fontFamily: "var(--zs-font-mono, SFMono-Regular, Consolas, monospace)",
          paddingTop: "4px",
          borderTop: "1px dashed rgba(21, 24, 22, 0.14)",
        }}
      >
        {side.cost}
      </span>
    </div>
  )
}

export function SliceWorkbench({
  after,
  before,
  className,
  scopeNote,
  sliceName,
}: SliceWorkbenchProps) {
  return (
    <section
      className={className}
      style={{ display: "flex", flexDirection: "column", gap: "16px" }}
      aria-label={`Workflow slice: ${sliceName}`}
    >
      <div style={{ display: "flex", alignItems: "baseline", gap: "8px", flexWrap: "wrap" }}>
        <span
          style={{
            fontSize: "10px",
            fontWeight: 600,
            letterSpacing: "0.12em",
            textTransform: "uppercase",
            color: "#64706a",
            fontFamily: "var(--zs-font-mono, SFMono-Regular, Consolas, monospace)",
          }}
        >
          One slice
        </span>
        <h3
          style={{
            fontSize: "18px",
            fontWeight: 700,
            color: "#151816",
            fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
            margin: 0,
          }}
        >
          {sliceName}
        </h3>
      </div>
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "1fr auto 1fr",
          gap: "12px",
          alignItems: "center",
        }}
      >
        <SidePanel label="Before — by hand" side={before} tone="before" />
        <span
          aria-hidden="true"
          style={{
            fontSize: "20px",
            color: "#64706a",
          }}
        >
          →
        </span>
        <SidePanel label="After — one route" side={after} tone="after" />
      </div>
      <p
        style={{
          fontSize: "12px",
          lineHeight: 1.45,
          color: "#64706a",
          fontStyle: "italic",
          fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
          margin: 0,
          background: "rgba(21, 24, 22, 0.03)",
          borderLeft: "2px solid rgba(31, 143, 95, 0.4)",
          padding: "8px 12px",
        }}
      >
        {scopeNote}
      </p>
    </section>
  )
}
