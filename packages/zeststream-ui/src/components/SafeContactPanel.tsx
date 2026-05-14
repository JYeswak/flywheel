"use client"

/**
 * SafeContactPanel — the contact CTA with trust signals built in.
 *
 * Implements story-system.json "safe-contact-room" page section.
 *
 * Audience truth: "Trust comes from human approval, narrow scope, privacy
 * clarity, and visible stop conditions." This panel makes the contact action
 * feel safe by naming those four trust anchors right at the point of decision.
 *
 * Design source — agentflywheel.com "Is This For You?": explicit inclusion and
 * exclusion criteria. Pre-qualifying reduces churn and builds trust. The panel
 * states what the engagement IS and ISN'T before the owner commits.
 *
 * Voice rule: "make blockers visible because hidden risk is the trust killer."
 *
 * Usage:
 *   <SafeContactPanel
 *     headline="Map your first workflow"
 *     cta={{ label: "Start with one slice", href: "/start" }}
 *     trustAnchors={[
 *       { anchor: "Human approval", detail: "Every route has an approval step you control" },
 *       { anchor: "Narrow scope", detail: "One slice. Not your whole system." },
 *       { anchor: "Privacy clarity", detail: "Your data stays in your tools. No training, no resale." },
 *       { anchor: "Visible stop conditions", detail: "Blocked is shown, never hidden." },
 *     ]}
 *     notFor={["A full AI transformation", "Replacing your team", "Black-box automation"]}
 *   />
 */

export interface TrustAnchor {
  anchor: string
  detail: string
}

export interface SafeContactPanelProps {
  headline: string
  cta: { label: string; href: string }
  trustAnchors: TrustAnchor[]
  /** What this engagement is explicitly NOT — pre-qualification. */
  notFor?: string[]
  className?: string
}

export function SafeContactPanel({
  className,
  cta,
  headline,
  notFor,
  trustAnchors,
}: SafeContactPanelProps) {
  return (
    <section
      className={className}
      style={{
        background: "linear-gradient(165deg, #101412 0%, #18201c 100%)",
        borderRadius: "16px",
        padding: "32px",
        display: "flex",
        flexDirection: "column",
        gap: "24px",
      }}
      aria-label="Contact"
    >
      <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
        <span
          style={{
            fontSize: "10px",
            fontWeight: 600,
            letterSpacing: "0.12em",
            textTransform: "uppercase",
            color: "#d4f34a",
            fontFamily: "var(--zs-font-mono, SFMono-Regular, Consolas, monospace)",
          }}
        >
          Act
        </span>
        <h2
          style={{
            fontSize: "clamp(24px, 3vw, 32px)",
            fontWeight: 800,
            lineHeight: 1.15,
            letterSpacing: "-0.01em",
            color: "#fffdf7",
            fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
            margin: 0,
          }}
        >
          {headline}
        </h2>
      </div>

      {/* Trust anchors grid */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
          gap: "12px",
        }}
      >
        {trustAnchors.map((item) => (
          <div
            key={item.anchor}
            style={{
              background: "rgba(255, 253, 247, 0.06)",
              border: "1px solid rgba(255, 253, 247, 0.12)",
              borderRadius: "8px",
              padding: "12px 14px",
              display: "flex",
              flexDirection: "column",
              gap: "4px",
            }}
          >
            <span
              style={{
                fontSize: "13px",
                fontWeight: 700,
                color: "#d4f34a",
                fontFamily:
                  "var(--zs-font-sans, Inter, system-ui, sans-serif)",
              }}
            >
              {item.anchor}
            </span>
            <span
              style={{
                fontSize: "12px",
                lineHeight: 1.4,
                color: "rgba(255, 253, 247, 0.78)",
                fontFamily:
                  "var(--zs-font-sans, Inter, system-ui, sans-serif)",
              }}
            >
              {item.detail}
            </span>
          </div>
        ))}
      </div>

      {/* CTA */}
      <a
        href={cta.href}
        style={{
          background: "#d4f34a",
          color: "#101412",
          padding: "14px 24px",
          borderRadius: "8px",
          fontSize: "15px",
          fontWeight: 700,
          textDecoration: "none",
          textAlign: "center",
          fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
          alignSelf: "flex-start",
        }}
      >
        {cta.label}
      </a>

      {/* Not-for pre-qualification */}
      {notFor && notFor.length > 0 && (
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            gap: "6px",
            paddingTop: "8px",
            borderTop: "1px solid rgba(255, 253, 247, 0.12)",
          }}
        >
          <span
            style={{
              fontSize: "10px",
              fontWeight: 600,
              letterSpacing: "0.1em",
              textTransform: "uppercase",
              color: "rgba(255, 253, 247, 0.5)",
              fontFamily:
                "var(--zs-font-mono, SFMono-Regular, Consolas, monospace)",
            }}
          >
            This is not
          </span>
          <ul
            style={{
              listStyle: "none",
              margin: 0,
              padding: 0,
              display: "flex",
              flexWrap: "wrap",
              gap: "8px",
            }}
          >
            {notFor.map((item) => (
              <li
                key={item}
                style={{
                  fontSize: "12px",
                  color: "rgba(255, 253, 247, 0.6)",
                  fontFamily:
                    "var(--zs-font-sans, Inter, system-ui, sans-serif)",
                }}
              >
                <span aria-hidden="true" style={{ color: "#df5b46" }}>✗</span>{" "}
                {item}
              </li>
            ))}
          </ul>
        </div>
      )}
    </section>
  )
}
