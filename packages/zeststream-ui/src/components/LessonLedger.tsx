"use client"

/**
 * LessonLedger — accretive learning display. Lessons that carry into the next build.
 *
 * Implements story-system.json "lesson-ledger" page section and the "remember"
 * story-arc stage.
 *
 * Core offer closing clause: "carry the lesson into the next build." The ledger
 * is the visible proof that ZestStream's work compounds — each engagement makes
 * the next one sharper. This is the flywheel made legible to the owner.
 *
 * Design source — agentflywheel.com: the methodology is the product. The ledger
 * shows the owner that they're not buying a one-off; they're buying a system
 * that gets better.
 *
 * Usage:
 *   <LessonLedger
 *     lessons={[
 *       { date: "2026-04", lesson: "Booking dedup needs a 24h window, not exact-match", appliedTo: "CRM route v2" },
 *       { date: "2026-05", lesson: "Owners want the approval step even when it's slower", appliedTo: "All routes" },
 *     ]}
 *   />
 */

export interface Lesson {
  /** YYYY-MM or any short date label. */
  date: string
  lesson: string
  /** Where this lesson was carried forward. */
  appliedTo: string
}

export interface LessonLedgerProps {
  lessons: Lesson[]
  className?: string
  title?: string
}

export function LessonLedger({
  className,
  lessons,
  title = "Lessons carried forward",
}: LessonLedgerProps) {
  if (lessons.length === 0) return null

  return (
    <section
      className={className}
      style={{ display: "flex", flexDirection: "column", gap: "12px" }}
      aria-label={title}
    >
      <div style={{ display: "flex", alignItems: "baseline", gap: "8px" }}>
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
          Remember
        </span>
        <h3
          style={{
            fontSize: "16px",
            fontWeight: 700,
            color: "#151816",
            fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
            margin: 0,
          }}
        >
          {title}
        </h3>
      </div>
      <ol
        style={{
          listStyle: "none",
          margin: 0,
          padding: 0,
          display: "flex",
          flexDirection: "column",
          gap: "2px",
        }}
      >
        {lessons.map((entry, i) => (
          <li
            key={`${entry.date}:${i}`}
            style={{
              display: "grid",
              gridTemplateColumns: "auto 1fr",
              gap: "14px",
              padding: "12px 0",
              borderBottom:
                i < lessons.length - 1
                  ? "1px solid rgba(21, 24, 22, 0.1)"
                  : "none",
            }}
          >
            <span
              style={{
                fontSize: "11px",
                fontWeight: 700,
                color: "#1f8f5f",
                fontFamily:
                  "var(--zs-font-mono, SFMono-Regular, Consolas, monospace)",
                whiteSpace: "nowrap",
                paddingTop: "1px",
              }}
            >
              {entry.date}
            </span>
            <div style={{ display: "flex", flexDirection: "column", gap: "3px" }}>
              <span
                style={{
                  fontSize: "14px",
                  fontWeight: 550,
                  color: "#151816",
                  lineHeight: 1.4,
                  fontFamily:
                    "var(--zs-font-sans, Inter, system-ui, sans-serif)",
                }}
              >
                {entry.lesson}
              </span>
              <span
                style={{
                  fontSize: "11px",
                  color: "#64706a",
                  fontFamily:
                    "var(--zs-font-mono, SFMono-Regular, Consolas, monospace)",
                }}
              >
                → carried into: {entry.appliedTo}
              </span>
            </div>
          </li>
        ))}
      </ol>
    </section>
  )
}
