"use client"

/**
 * WorkflowMap — visual architectural diagram for a ZestStream workflow slice.
 *
 * Implements the story-system.json "WorkflowMap" visual primitive.
 *
 * Jeff Emanuel design principle applied (asupersync.com hero):
 * "Putting an architecture diagram in the hero makes an implicit claim:
 * if you can't read this, this isn't for you." The diagram IS the pitch.
 *
 * Usage:
 *   <WorkflowMap
 *     title="Email → CRM → Invoice"
 *     nodes={[
 *       { id: "email", label: "Email", role: "source", system: "Gmail" },
 *       { id: "crm", label: "CRM", role: "transform", system: "HubSpot" },
 *       { id: "invoice", label: "Invoice", role: "sink", system: "QuickBooks" },
 *     ]}
 *     edges={[
 *       { from: "email", to: "crm", label: "contact sync", proofState: "proven" },
 *       { from: "crm", to: "invoice", label: "deal close", proofState: "blocked" },
 *     ]}
 *   />
 */

import type { ProofState } from "./ProofRail"

export type NodeRole = "source" | "transform" | "sink" | "gate" | "human"

export interface WorkflowNode {
  id: string
  label: string
  role: NodeRole
  system?: string
  proofState?: ProofState
}

export interface WorkflowEdge {
  from: string
  to: string
  label?: string
  proofState?: ProofState
}

export interface WorkflowMapProps {
  title?: string
  nodes: WorkflowNode[]
  edges: WorkflowEdge[]
  className?: string
  compact?: boolean
}

const NODE_ROLE_STYLE: Record<
  NodeRole,
  { bg: string; border: string; label: string; symbol: string }
> = {
  source: {
    bg: "rgba(31, 143, 95, 0.08)",
    border: "rgba(31, 143, 95, 0.3)",
    label: "Source",
    symbol: "→",
  },
  transform: {
    bg: "rgba(42, 111, 187, 0.08)",
    border: "rgba(42, 111, 187, 0.3)",
    label: "Transform",
    symbol: "⟳",
  },
  sink: {
    bg: "rgba(108, 74, 182, 0.08)",
    border: "rgba(108, 74, 182, 0.3)",
    label: "Destination",
    symbol: "✓",
  },
  gate: {
    bg: "rgba(242, 201, 76, 0.08)",
    border: "rgba(242, 201, 76, 0.3)",
    label: "Gate",
    symbol: "◉",
  },
  human: {
    bg: "rgba(240, 143, 62, 0.08)",
    border: "rgba(240, 143, 62, 0.3)",
    label: "Human",
    symbol: "👤",
  },
}

const PROOF_EDGE_COLORS: Record<ProofState, string> = {
  proven: "#1f8f5f",
  blocked: "#df5b46",
  "skipped-with-reason": "#f2c94c",
  private: "#64706a",
}

function WorkflowNode({ node, compact }: { node: WorkflowNode; compact: boolean }) {
  const style = NODE_ROLE_STYLE[node.role]
  return (
    <div
      style={{
        background: style.bg,
        border: `1px solid ${style.border}`,
        borderRadius: "8px",
        padding: compact ? "8px 12px" : "12px 16px",
        display: "flex",
        flexDirection: "column",
        gap: "2px",
        minWidth: compact ? "80px" : "110px",
        textAlign: "center",
      }}
    >
      <span
        style={{
          fontSize: compact ? "11px" : "13px",
          fontWeight: 600,
          color: "#151816",
          fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
        }}
      >
        {node.label}
      </span>
      {node.system && !compact && (
        <span
          style={{
            fontSize: "9px",
            color: "#64706a",
            fontFamily: "var(--zs-font-mono, SFMono-Regular, Consolas, monospace)",
            letterSpacing: "0.04em",
            textTransform: "uppercase",
          }}
        >
          {node.system}
        </span>
      )}
    </div>
  )
}

function EdgeArrow({ edge, compact }: { edge: WorkflowEdge; compact: boolean }) {
  const color = edge.proofState ? PROOF_EDGE_COLORS[edge.proofState] : "#64706a"
  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: "2px",
        padding: "0 4px",
      }}
    >
      <div
        style={{
          width: compact ? "32px" : "48px",
          height: "1px",
          background: color,
          position: "relative",
        }}
      >
        <span
          style={{
            position: "absolute",
            right: "-1px",
            top: "-5px",
            color,
            fontSize: "10px",
            lineHeight: 1,
          }}
        >
          ▶
        </span>
      </div>
      {edge.label && !compact && (
        <span
          style={{
            fontSize: "9px",
            color,
            fontFamily: "var(--zs-font-mono, SFMono-Regular, Consolas, monospace)",
            letterSpacing: "0.03em",
            maxWidth: "60px",
            textAlign: "center",
            lineHeight: 1.3,
          }}
        >
          {edge.label}
        </span>
      )}
    </div>
  )
}

export function WorkflowMap({ className, compact = false, edges, nodes, title }: WorkflowMapProps) {
  // Build ordered node sequence from edges for linear display
  const edgeMap = new Map(edges.map((e) => [e.from, e]))
  const nodeMap = new Map(nodes.map((n) => [n.id, n]))

  // Find start node (not a target of any edge)
  const targets = new Set(edges.map((e) => e.to))
  const startId = nodes.find((n) => !targets.has(n.id))?.id ?? nodes[0]?.id

  // Build ordered sequence following edges
  const ordered: { node: WorkflowNode; edge?: WorkflowEdge }[] = []
  let current = startId
  const visited = new Set<string>()
  while (current && !visited.has(current)) {
    visited.add(current)
    const node = nodeMap.get(current)
    if (!node) break
    const edge = edgeMap.get(current)
    ordered.push({ node, edge })
    current = edge?.to ?? ""
  }

  if (ordered.length === 0) return null

  return (
    <div className={className} style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
      {title && (
        <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
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
            Workflow
          </span>
          <span
            style={{
              fontSize: "12px",
              fontWeight: 500,
              color: "#151816",
              fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
            }}
          >
            {title}
          </span>
        </div>
      )}
      <div
        style={{
          display: "flex",
          alignItems: "center",
          overflowX: "auto",
          gap: "4px",
          paddingBottom: "4px",
        }}
        role="img"
        aria-label={title ? `Workflow diagram: ${title}` : "Workflow diagram"}
      >
        {ordered.map(({ edge, node }, i) => (
          <div
            key={node.id}
            style={{ display: "flex", alignItems: "center", gap: "4px" }}
          >
            <WorkflowNode node={node} compact={compact} />
            {edge && i < ordered.length - 1 && (
              <EdgeArrow edge={edge} compact={compact} />
            )}
          </div>
        ))}
      </div>
    </div>
  )
}
