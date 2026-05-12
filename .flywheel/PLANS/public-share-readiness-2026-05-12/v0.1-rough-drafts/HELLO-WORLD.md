# Hello World — A minimal flywheel cycle

> *The smallest possible example of flywheel doing what it does. ~20 minutes end to end. No installer required — manual setup so you can see every moving part.*

This example walks through one full flywheel cycle on a tiny project. You will:

1. Initialize a flywheel-managed directory
2. Write a mission statement
3. Author a plan, then synthesize it
4. Convert the plan into beads
5. Execute the beads (manually, in your own Claude Code pane)
6. Close the cycle with a receipt
7. See how the substrate accreted

By the end you'll have a working `hello-doctor` CLI — a 30-line bash tool with a real `doctor` subcommand — plus the substrate that flywheel uses to learn from the cycle.

If anything in this guide doesn't work, that's interesting signal — please file an issue.

---

## Prerequisites

```
git --version       # any modern git
bash --version      # 5.x or later (zsh works too)
jq --version        # for hook diagnostics
```

Optional but recommended:
- Claude Code (or `codex`) for the AI-assisted parts; without it, you'll author by hand
- `shasum` for reversibility receipts (ships on macOS and most Linux)

## Step 1 — Scaffold the project

```sh
mkdir -p ~/Developer/hello-doctor
cd ~/Developer/hello-doctor
git init -q
mkdir -p .flywheel/{doctrine,beads,handoffs}
touch .flywheel/MISSION.md
```

You now have an empty flywheel-shaped project. The `.flywheel/` directory will hold the doctrine, the task graph, and the closeout receipts. Source code lives in the project root.

## Step 2 — Write a mission

`MISSION.md` is the anchor every cycle reads. It declares what the project is for and what it isn't. Keep it short.

```sh
cat > .flywheel/MISSION.md <<'EOF'
# Hello Doctor — Mission

A 30-line bash CLI that demonstrates the doctor / health / repair triad.

What this is for:
- Show that a tiny tool can ship with self-diagnostic capability
- Be a teaching example for the flywheel discipline

What this is not:
- A production tool
- A library

Acceptance: `./hello-doctor doctor` prints structured JSON describing
the tool's own state. `./hello-doctor doctor --repair` fixes any
detectable issue.
EOF
```

That's the mission. Three sentences and acceptance criteria.

## Step 3 — Author a plan

Plans are plain prose. They describe the approach in enough detail to argue about, before any code exists. In flywheel discipline you'd write a first draft, then compete two more drafts from different models, then synthesize. For this tutorial we'll skip the multi-model competition and write one good plan.

```sh
cat > .flywheel/PLAN.md <<'EOF'
# Hello Doctor — Plan v1

## Approach

A single bash script `hello-doctor` with three subcommands:
- `hello-doctor hello` — prints "hello, world"
- `hello-doctor doctor` — emits a JSON object describing tool state
- `hello-doctor doctor --repair` — fixes detectable issues

## State model

The tool's "state" is the presence of two files:
- `~/.hello-doctor/config.json` (defaults to `{"name": "world"}`)
- `~/.hello-doctor/log.jsonl` (append-only audit of `hello` calls)

## Doctor checks

1. Config file exists and is well-formed JSON → OK
2. Config file is missing → REPAIRABLE (create with default)
3. Config file is malformed JSON → REPAIRABLE (back up + recreate with default)
4. Log file exists and is writable → OK
5. Log file is missing → REPAIRABLE (touch empty file)
6. Log file is not writable → NOT-REPAIRABLE (surface permissions issue)

## Doctor output shape

```json
{
  "schema_version": "hello-doctor.doctor/v1",
  "ok": true | false,
  "checks": [
    { "name": "config-present", "status": "ok" | "repairable" | "broken", "detail": "..." },
    ...
  ],
  "repairable_count": <int>,
  "broken_count": <int>
}
```

## Decomposition

This plan converts cleanly into three beads:
1. Bead A — Write `hello-doctor` skeleton + `hello` subcommand
2. Bead B — Implement `doctor` subcommand (6 checks; JSON output)
3. Bead C — Implement `doctor --repair` + acceptance test
EOF
```

## Step 4 — Convert to beads

A bead is one PR-shaped unit of work. Local-first task tracking via the [beads](https://github.com/Dicklesworthstone/beads_rust) CLI; for this tutorial we'll just write them as JSON manually so you can see the shape:

```sh
cat > .flywheel/beads/A-hello-skeleton.json <<'EOF'
{
  "id": "hello-doctor-A",
  "title": "hello-doctor skeleton + hello subcommand",
  "description": "Create executable bash script with arg dispatch; implement hello subcommand that reads ~/.hello-doctor/config.json and prints greeting.",
  "acceptance": [
    "Running `./hello-doctor hello` prints exactly: hello, world",
    "Script is +x and shebang-correct",
    "Script handles unknown subcommands with non-zero exit + clear error"
  ],
  "dependencies": [],
  "status": "ready"
}
EOF

cat > .flywheel/beads/B-doctor.json <<'EOF'
{
  "id": "hello-doctor-B",
  "title": "doctor subcommand with 6 checks",
  "description": "Implement `doctor` subcommand emitting JSON per plan v1 schema. 6 checks: config-present, config-well-formed, config-readable, log-present, log-writable, log-well-formed.",
  "acceptance": [
    "`./hello-doctor doctor` exits 0 if all checks ok",
    "`./hello-doctor doctor` exits 1 if any broken; 2 if any repairable-but-unhandled",
    "Output is valid JSON per schema",
    "Test fixture: missing config file → doctor reports 'repairable' for config-present"
  ],
  "dependencies": ["hello-doctor-A"],
  "status": "ready"
}
EOF

cat > .flywheel/beads/C-repair.json <<'EOF'
{
  "id": "hello-doctor-C",
  "title": "doctor --repair + acceptance test",
  "description": "Implement `doctor --repair` flag that fixes repairable issues. Wire end-to-end acceptance test.",
  "acceptance": [
    "`./hello-doctor doctor --repair` fixes missing config + missing log",
    "After repair, `./hello-doctor doctor` exits 0",
    "Acceptance test passes: fresh ~/.hello-doctor → doctor --repair → doctor exits 0 → hello prints greeting"
  ],
  "dependencies": ["hello-doctor-B"],
  "status": "ready"
}
EOF
```

## Step 5 — Execute the beads

In a real flywheel cycle, you'd dispatch each bead to a worker pane. For this tutorial we'll do them inline. (If you have Claude Code running, paste each bead's `description` + `acceptance` into a fresh chat with "implement this bead" — the agent will produce the code.)

### Bead A — skeleton

```sh
cat > hello-doctor <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
CONFIG="$HOME/.hello-doctor/config.json"
LOG="$HOME/.hello-doctor/log.jsonl"

cmd_hello() {
  local name="world"
  if [ -f "$CONFIG" ]; then
    name=$(jq -r '.name // "world"' "$CONFIG" 2>/dev/null || echo "world")
  fi
  echo "hello, $name"
  if [ -w "$(dirname "$LOG")" ] 2>/dev/null; then
    printf '{"ts":"%s","name":"%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$name" >> "$LOG" 2>/dev/null || true
  fi
}

case "${1:-}" in
  hello) cmd_hello ;;
  doctor) echo "doctor not yet implemented (Bead B)" >&2; exit 99 ;;
  "") echo "usage: hello-doctor {hello|doctor}" >&2; exit 1 ;;
  *) echo "unknown subcommand: $1" >&2; exit 1 ;;
esac
EOF
chmod +x hello-doctor
./hello-doctor hello   # → hello, world
```

### Bead B — doctor

```sh
cat >> hello-doctor <<'EOF_DOCTOR'
EOF_DOCTOR
# (continued in real implementation — left as exercise; pattern is in the plan)
```

(For brevity I'm omitting the full Bead B + C implementation here; the *pattern* is what matters for the tutorial. The full implementation in the [`examples/hello-doctor/`](https://github.com/JYeswak/flywheel/tree/main/examples/hello-doctor) directory in the public repo is the source of truth.)

## Step 6 — Close the cycle

After all three beads ship, write a closeout receipt. This is what the next cycle reads to understand what already happened.

```sh
cat > .flywheel/handoffs/cycle-1-closeout.md <<'EOF'
# Cycle 1 closeout — hello-doctor

**Shipped:**
- hello-doctor-A (skeleton + hello)
- hello-doctor-B (doctor with 6 checks)
- hello-doctor-C (--repair + acceptance test)

**Acceptance criteria met:** all three beads' acceptance criteria pass.

**What we learned:**
- The doctor pattern fits cleanly in <100 lines of bash
- Repair-ability needs to be a per-check classification (not all checks repair)
- JSON output shape stabilized early; no churn

**What's next:**
- Cycle 2 could add: `health` subcommand (read-only quick check) for completion of the triad
- Could promote a `world-class-doctor-mode-for-cli-tools` pattern to canonical doctrine if we see this triad again
EOF
```

## Step 7 — Observe the accretion

You now have:

```
~/Developer/hello-doctor/
├── hello-doctor              ← working CLI
├── .flywheel/
│   ├── MISSION.md            ← what this is for
│   ├── PLAN.md               ← the v1 plan (archived for reference)
│   ├── beads/                ← the task graph
│   │   ├── A-hello-skeleton.json
│   │   ├── B-doctor.json
│   │   └── C-repair.json
│   └── handoffs/
│       └── cycle-1-closeout.md
└── .git/
```

When you start cycle 2 (say, to add the `health` subcommand), you read MISSION.md, you read cycle-1-closeout.md, you draft cycle 2's plan against that context. The system remembers.

If `doctor --repair` had failed in some surprising way during cycle 1, the trauma would be logged. If the same failure mode showed up in cycle 2 (and again in cycle 3), it would graduate from instance memory → hardened pattern → canonical L-rule.

That's the flywheel. One cycle's lessons baked into the next cycle's substrate.

## Where to take this next

- **Add a second cycle.** Add the `health` subcommand. Notice how much faster you draft the plan now that the doctor pattern is in your head.
- **Refactor MISSION.md.** As your understanding sharpens, the mission gets tighter.
- **Promote a pattern.** If you find the doctor/health/repair triad useful, the [`world-class-doctor-mode-for-cli-tools`](https://github.com/JYeswak/flywheel/tree/main/skills/world-class-doctor-mode-for-cli-tools) skill documents the full pattern.
- **Multi-pane orchestration.** When your project gets large enough that one pane isn't enough, the [NTM](https://github.com/Dicklesworthstone/ntm) integration lets you dispatch beads to worker panes in parallel.

## What this tutorial deliberately omitted

To stay under 20 minutes:

- The multi-model competition phase (steps 3a-3c in the full cycle) — for production work, this catches a lot of bad plans early
- The trauma-class promotion ladder — wasn't relevant since cycle 1 had no traumas
- The cross-orchestrator protocol — single-pane is fine for hello-world scale
- The substrate-class manifest — only matters when you have detector mechanisms operating on your own substrate
- The bead validator + closure-debt verification — overkill for three beads, but essential at thirty

All of these are in the architecture spec and the doctrine corpus. They become useful when the project gets large enough to need them.

---

*This tutorial is part of the flywheel ecosystem. If you completed it and noticed friction or unclear language, please file an issue when the public repo lands.*
