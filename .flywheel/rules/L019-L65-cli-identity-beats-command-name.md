## L65 — CLI-IDENTITY-BEATS-COMMAND-NAME

---
id: L65
title: CLI identity beats command name
status: long_term
shipped: 2026-05-03
review_due: 2026-11-09
trauma_class: cli-identity-drift
---


Command names are not proof of substrate identity. Any tick, doctor, or worker
probe that depends on a short binary name with known collision risk MUST verify
the resolved executable identity before trusting output.

**Reason:** 2026-05-03 vc-relive found `~/.local/bin/vc` correctly symlinked to
Vibe Cockpit, but bare `vc` still resolved first to Homebrew's Vercel CLI through
`/opt/homebrew/bin/vc`. The binary was current, the symlink was correct, and the
operator-facing command was still wrong. Symlink checks alone are markers, not
driver truth.

**How to apply:**
- For collision-prone commands, record both `command -v <name>` and
  `realpath "$(command -v <name>)"` in the probe ledger.
- Validate semantic identity with a robot/help/version probe, not just filename.
  Example: `vc-observability-probe.sh` requires `vc --help` to contain
  `Vibe Cockpit` before reading status surfaces.
- If the command is shadowed, install or repair a front-of-PATH shim and keep the
  canonical absolute path in tick scripts until the shell path is proven.
- Receipt fields that cite a tool must include the resolved binary path when
  feasible (`vc_bin`, `ntm_bin`, `br_bin`, etc.).

**Forbidden outputs:**
- "Binary is installed" based only on `ls ~/.local/bin/<name>` while
  `command -v <name>` resolves elsewhere
- "Symlink correct" as a substitute for command identity proof
- Running collector/doctor probes through bare names without canonical scope when
  the name is shared by another ecosystem tool

**Evidence:** bead `flywheel-8q2x`; `/tmp/vc-relive-phases-2-6_findings.md`;
`/Users/josh/bin/vc -> /Users/josh/.cargo/bin/vc` shim added after
`which vc` resolved to `/opt/homebrew/bin/vc` (Vercel CLI); probe script
`.flywheel/scripts/vc-observability-probe.sh` version `2026-05-03.2`.

**Companion rules:** L57 (markers are not driver truth), L60 (liveness proven by
output), canonical-cli-scoping skill, and L61 (new doctrine must wire into
AGENTS.md + README).

