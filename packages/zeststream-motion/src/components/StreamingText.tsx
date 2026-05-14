"use client"

/**
 * StreamingText — word-by-word reveal for AI-streamed content.
 *
 * Design source — AI-native UI patterns 2025-2026: show the cursor blinking
 * BEFORE the first token arrives so the user knows generation is happening.
 * Reveal word-by-word (not character-by-character — that reads as retro
 * typewriter). Don't use a spinner: a spinner communicates "waiting", a
 * cursor communicates "generating".
 *
 * Two modes:
 * - Controlled: pass `text` that grows as tokens stream in; component reveals
 *   the delta smoothly.
 * - Demo: pass `text` complete + `animate` to replay the reveal.
 *
 * Reduced-motion safe: shows full text immediately, no reveal animation.
 *
 * Usage:
 *   // Streaming from an API:
 *   <StreamingText text={accumulatedTokens} streaming={!done} />
 *
 *   // Replay a complete string:
 *   <StreamingText text="Here's what I found..." animate />
 */

import { useEffect, useState } from "react"

export interface StreamingTextProps {
  text: string
  /** True while tokens are still arriving — shows the cursor. */
  streaming?: boolean
  /** Replay the full text with a reveal animation (demo mode). */
  animate?: boolean
  /** Ms between word reveals in animate mode. */
  wordDelayMs?: number
  className?: string
}

function prefersReducedMotion(): boolean {
  if (typeof window === "undefined") return false
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches
}

export function StreamingText({
  animate = false,
  className,
  streaming = false,
  text,
  wordDelayMs = 40,
}: StreamingTextProps) {
  const [revealedCount, setRevealedCount] = useState(animate ? 0 : Infinity)

  const words = text.split(/(\s+)/) // keep whitespace tokens

  useEffect(() => {
    if (!animate) {
      setRevealedCount(Infinity)
      return
    }
    if (prefersReducedMotion()) {
      setRevealedCount(Infinity)
      return
    }
    setRevealedCount(0)
    let i = 0
    const timer = setInterval(() => {
      i += 1
      setRevealedCount(i)
      if (i >= words.length) clearInterval(timer)
    }, wordDelayMs)
    return () => clearInterval(timer)
  }, [animate, text, wordDelayMs, words.length])

  const shown =
    revealedCount === Infinity ? text : words.slice(0, revealedCount).join("")

  return (
    <span
      className={className}
      style={{
        fontFamily: "var(--zs-font-sans, Inter, system-ui, sans-serif)",
        lineHeight: 1.5,
        color: "#151816",
      }}
      aria-live={streaming ? "polite" : "off"}
    >
      {shown}
      {streaming && (
        <span
          aria-hidden="true"
          style={{
            display: "inline-block",
            width: "2px",
            height: "1em",
            marginLeft: "1px",
            verticalAlign: "text-bottom",
            background: "#1f8f5f",
            animation: "zs-streaming-cursor 1s steps(2) infinite",
          }}
        />
      )}
      {/* Cursor blink keyframes — injected once, scoped by name */}
      <style>{`
        @keyframes zs-streaming-cursor {
          0%, 100% { opacity: 1; }
          50% { opacity: 0; }
        }
        @media (prefers-reduced-motion: reduce) {
          [style*="zs-streaming-cursor"] { animation: none !important; opacity: 1 !important; }
        }
      `}</style>
    </span>
  )
}
