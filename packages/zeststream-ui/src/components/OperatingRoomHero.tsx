"use client"

/**
 * OperatingRoomHero — the hero section for ZestStream public surfaces.
 *
 * Implements the story-system.json "operating-room-hero" page section.
 *
 * Design sources:
 * - asupersync.com: architecture diagram in the hero IS the pitch — if you can't
 *   read it, this isn't for you. The precision is the filter.
 * - jeffreyemanuel.com: numbers over adjectives. The hero states the deliverable,
 *   not the category.
 *
 * The "operating room" metaphor: the owner's tools (Email, CRM, Calendar, Invoice,
 * Docs, Reports) are laid out like instruments on a tray. The product maps ONE
 * route between two of them. Mapped before motion.
 *
 * Usage:
 *   <OperatingRoomHero
 *     headline="Buy back the time hiding between your tools"
 *     subhead="Map one workflow. Improve one bounded slice. Prove what changed."
 *     tools={["Email", "CRM", "Calendar", "Invoice", "Docs", "Reports"]}
 *     activeRoute={["Email", "CRM"]}
 *     primaryCta={{ label: "Map my workflow", href: "/start" }}
 *   />
 */

export interface OperatingRoomHeroProps {
  headline: string
  subhead: string
  tools: string[]
  /** Two tool labels that the active route connects. */
  activeRoute?: [string, string]
  primaryCta: { label: string; href: string }
  secondaryCta?: { label: string; href: string }
  className?: string
}

function ToolNode({
  label,
  isActive,
}: {
  label: string
  isActive: boolean
}) {
  return (
    <div
      style={{
        background: isActive
          ? "rgba(212, 243, 74, 0.16)"
          : "rgba(255, 253, 247, 0.7)",
        border: isActive
          ? "1.5px solid rgba(31, 143, 95, 0.5)"
          : "1px solid rgba(21, 24, 22, 0.14)",
        borderRadius: "8px",
        padding: "10px 14px",
        fontSize: "13px",
        fontWeight: isActive ? 700 : 500,
        color: "#151816",
        fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
        boxShadow: isActive
          ? "0 8px 32px rgba(31, 143, 95, 0.14)"
          : "0 4px 16px rgba(21, 24, 22, 0.06)",
        transition: "all 240ms cubic-bezier(0.34, 1.56, 0.64, 1)",
      }}
    >
      {label}
    </div>
  )
}

export function OperatingRoomHero({
  activeRoute,
  className,
  headline,
  primaryCta,
  secondaryCta,
  subhead,
  tools,
}: OperatingRoomHeroProps) {
  return (
    <section
      className={className}
      style={{
        display: "grid",
        gap: "32px",
        gridTemplateColumns: "minmax(0, 1.1fr) minmax(0, 0.9fr)",
        alignItems: "center",
        padding: "48px 0",
      }}
      aria-label="Hero"
    >
      {/* Left: copy */}
      <div style={{ display: "flex", flexDirection: "column", gap: "20px" }}>
        <h1
          style={{
            fontSize: "clamp(36px, 5vw, 56px)",
            fontWeight: 800,
            lineHeight: 1.08,
            letterSpacing: "-0.02em",
            color: "#151816",
            fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
            margin: 0,
          }}
        >
          {headline}
        </h1>
        <p
          style={{
            fontSize: "clamp(16px, 2vw, 19px)",
            lineHeight: 1.5,
            color: "#2e3632",
            fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
            margin: 0,
            maxWidth: "44ch",
          }}
        >
          {subhead}
        </p>
        <div style={{ display: "flex", gap: "12px", flexWrap: "wrap", marginTop: "4px" }}>
          <a
            href={primaryCta.href}
            style={{
              background: "#151816",
              color: "#fffdf7",
              padding: "12px 22px",
              borderRadius: "8px",
              fontSize: "15px",
              fontWeight: 650,
              textDecoration: "none",
              fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
            }}
          >
            {primaryCta.label}
          </a>
          {secondaryCta && (
            <a
              href={secondaryCta.href}
              style={{
                background: "transparent",
                color: "#151816",
                padding: "12px 22px",
                borderRadius: "8px",
                fontSize: "15px",
                fontWeight: 550,
                textDecoration: "none",
                border: "1px solid rgba(21, 24, 22, 0.24)",
                fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
              }}
            >
              {secondaryCta.label}
            </a>
          )}
        </div>
      </div>

      {/* Right: operating room scene */}
      <div
        style={{
          background: "linear-gradient(160deg, #f2eadc 0%, #fbfaf4 100%)",
          border: "1px solid rgba(21, 24, 22, 0.12)",
          borderRadius: "16px",
          padding: "24px",
          display: "flex",
          flexDirection: "column",
          gap: "16px",
        }}
        role="img"
        aria-label={`Workflow tools: ${tools.join(", ")}${activeRoute ? `. Active route: ${activeRoute[0]} to ${activeRoute[1]}` : ""}`}
      >
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
          Your operating room
        </span>
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(2, 1fr)",
            gap: "10px",
          }}
        >
          {tools.map((tool) => (
            <ToolNode
              key={tool}
              label={tool}
              isActive={Boolean(activeRoute?.includes(tool))}
            />
          ))}
        </div>
        {activeRoute && (
          <div
            style={{
              fontSize: "11px",
              color: "#1f8f5f",
              fontFamily: "var(--zs-font-mono, SFMono-Regular, Consolas, monospace)",
              display: "flex",
              alignItems: "center",
              gap: "6px",
            }}
          >
            <span style={{ fontWeight: 700 }}>{activeRoute[0]}</span>
            <span aria-hidden="true">→</span>
            <span style={{ fontWeight: 700 }}>{activeRoute[1]}</span>
            <span style={{ opacity: 0.7, marginLeft: "4px" }}>
              · one route, mapped before motion
            </span>
          </div>
        )}
      </div>
    </section>
  )
}
