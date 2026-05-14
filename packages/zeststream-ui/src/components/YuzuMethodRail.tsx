"use client"

/**
 * YuzuMethodRail — the methodology rail showing the five story-arc stages.
 *
 * Implements story-system.json "story_arc_stages": recognize → bound → control
 * → remember → act.
 *
 * Design source — agentflywheel.com: the methodology IS the product. Don't
 * describe tools; argue for a development epistemology. The rail makes the
 * abstract process legible as a sequence the owner can see themselves moving
 * through.
 *
 * The Yuzu Method ™ is a ZestStream mark — U.S. application SN 99572208 is
 * pending (not yet registered), so render with ™, not ®. Switch to ® only
 * when the registration certificate issues.
 *
 * Usage:
 *   <YuzuMethodRail
 *     currentStage="control"
 *     stages={[
 *       { id: "recognize", label: "Recognize", detail: "Name the workflow that hurts" },
 *       { id: "bound",     label: "Bound",     detail: "Pick one slice, not the whole system" },
 *       { id: "control",   label: "Control",   detail: "Human-approved, visible stop conditions" },
 *       { id: "remember",  label: "Remember",  detail: "The lesson carries into the next build" },
 *       { id: "act",       label: "Act",       detail: "Ship the proven slice" },
 *     ]}
 *   />
 */

export type YuzuStageId = "recognize" | "bound" | "control" | "remember" | "act"

export interface YuzuStage {
  id: YuzuStageId
  label: string
  detail: string
}

export interface YuzuMethodRailProps {
  stages: YuzuStage[]
  /** Which stage the owner is currently in. Stages before it render as done. */
  currentStage?: YuzuStageId
  className?: string
  showMark?: boolean
}

function StageNode({
  stage,
  position,
  isLast,
}: {
  stage: YuzuStage
  position: "done" | "current" | "upcoming"
  isLast: boolean
}) {
  const dotColor =
    position === "done"
      ? "#1f8f5f"
      : position === "current"
        ? "#d4f34a"
        : "rgba(100, 112, 106, 0.35)"
  const labelColor = position === "upcoming" ? "#64706a" : "#151816"

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        gap: "8px",
        flex: 1,
        minWidth: "120px",
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: "0" }}>
        <span
          style={{
            width: "14px",
            height: "14px",
            borderRadius: "50%",
            background: dotColor,
            border:
              position === "current"
                ? "2px solid #1f8f5f"
                : "2px solid transparent",
            flexShrink: 0,
            boxShadow:
              position === "current"
                ? "0 0 0 4px rgba(212, 243, 74, 0.3)"
                : "none",
          }}
          aria-hidden="true"
        />
        {!isLast && (
          <span
            style={{
              flex: 1,
              height: "1.5px",
              background:
                position === "done"
                  ? "#1f8f5f"
                  : "rgba(100, 112, 106, 0.25)",
            }}
            aria-hidden="true"
          />
        )}
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: "2px" }}>
        <span
          style={{
            fontSize: "13px",
            fontWeight: position === "current" ? 700 : 600,
            color: labelColor,
            fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
          }}
        >
          {stage.label}
        </span>
        <span
          style={{
            fontSize: "11px",
            lineHeight: 1.4,
            color: "#64706a",
            fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
          }}
        >
          {stage.detail}
        </span>
      </div>
    </div>
  )
}

export function YuzuMethodRail({
  className,
  currentStage,
  showMark = true,
  stages,
}: YuzuMethodRailProps) {
  if (stages.length === 0) return null

  const currentIndex = currentStage
    ? stages.findIndex((s) => s.id === currentStage)
    : -1

  return (
    <section
      className={className}
      style={{ display: "flex", flexDirection: "column", gap: "16px" }}
      aria-label="The Yuzu Method"
    >
      {showMark && (
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
          The Yuzu Method ™
        </span>
      )}
      <div
        style={{
          display: "flex",
          gap: "4px",
          flexWrap: "wrap",
        }}
      >
        {stages.map((stage, i) => {
          let position: "done" | "current" | "upcoming" = "upcoming"
          if (currentIndex >= 0) {
            if (i < currentIndex) position = "done"
            else if (i === currentIndex) position = "current"
          }
          return (
            <StageNode
              key={stage.id}
              stage={stage}
              position={position}
              isLast={i === stages.length - 1}
            />
          )
        })}
      </div>
    </section>
  )
}
