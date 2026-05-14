export const springPresets = {
  filterChip: {
    damping: 20,
    stiffness: 400,
    mass: 1,
    settleMs: 160,
    easing: "cubic-bezier(0.34, 1.56, 0.64, 1)",
  },
  sheetSnap: {
    damping: 28,
    stiffness: 300,
    mass: 1,
    settleMs: 240,
    easing: "cubic-bezier(0.34, 1.56, 0.64, 1)",
  },
  livePulse: {
    ringMs: 1200,
    cycleMs: 4000,
    easing: "ease-out",
  },
} as const

export const motionDurations = {
  instant: 0,
  fast: 120,
  filterChip: springPresets.filterChip.settleMs,
  sheetSnap: springPresets.sheetSnap.settleMs,
  livePulseRing: springPresets.livePulse.ringMs,
  livePulseCycle: springPresets.livePulse.cycleMs,
} as const
