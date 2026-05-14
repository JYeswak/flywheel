"use client"

/**
 * TelemetryBar — fake-but-coherent system status bar.
 *
 * Jeff Emanuel design principle (C5): frankentui.com and asupersync.com both use
 * decorative system telemetry (`Node_ID: ROOT_NODE`, `Stability: NOMINAL`,
 * `Latency: 1.20ms`) as navigational texture that makes every page feel live.
 *
 * This is NOT misleading: it's a design language signal, the same way a
 * mission-control aesthetic doesn't claim your laptop runs AMOS.
 *
 * Usage:
 *   <TelemetryBar
 *     entries={[
 *       { key: "Status", value: "OPERATIONAL", variant: "success" },
 *       { key: "Workflows", value: "3 active", variant: "neutral" },
 *       { key: "Last_proof", value: "12m ago", variant: "neutral" },
 *       { key: "Trust_gate", value: "PASSING", variant: "success" },
 *     ]}
 *   />
 */

export type TelemetryVariant = "success" | "warning" | "error" | "neutral" | "dim"

export interface TelemetryEntry {
  key: string
  value: string
  variant?: TelemetryVariant
}

export interface TelemetryBarProps {
  entries: TelemetryEntry[]
  separator?: string
  className?: string
}

const VARIANT_COLORS: Record<TelemetryVariant, string> = {
  success: "#d4f34a",
  warning: "#f2c94c",
  error: "#df5b46",
  neutral: "#64706a",
  dim: "rgba(100, 112, 106, 0.5)",
}

export function TelemetryBar({ className, entries, separator = "·" }: TelemetryBarProps) {
  return (
    <div
      className={className}
      style={{
        display: "flex",
        alignItems: "center",
        gap: "16px",
        flexWrap: "wrap",
        fontFamily: "var(--zs-font-mono, SFMono-Regular, Consolas, 'Liberation Mono', monospace)",
        fontSize: "11px",
        color: "#64706a",
        letterSpacing: "0.02em",
      }}
      role="status"
      aria-label="System status"
    >
      {entries.map((entry, i) => {
        const variant: TelemetryVariant = entry.variant ?? "neutral"
        const valueColor = VARIANT_COLORS[variant]

        return (
          <span
            key={entry.key}
            style={{ display: "flex", alignItems: "center", gap: "4px" }}
          >
            {i > 0 && (
              <span
                aria-hidden="true"
                style={{ marginRight: "12px", opacity: 0.3 }}
              >
                {separator}
              </span>
            )}
            <span style={{ opacity: 0.65 }}>{entry.key}:</span>
            <span style={{ color: valueColor, fontWeight: 600 }}>{entry.value}</span>
          </span>
        )
      })}
    </div>
  )
}
