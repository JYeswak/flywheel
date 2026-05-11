---
title: "Test-Receiver Wire-In Recipe (canonical-CLI test as probe-without-receiver clearance)"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# Test-Receiver Wire-In Recipe

Version: `test-receiver-wire-in-recipe/v1`
Owner: orchestrator + workers handling `gap-probe-without-receiver` AND `gap-wired-but-cold` beads
Status: canonical, shipped 2026-05-11 (N=3 recurrence threshold met)
Source bead: flywheel-eq9wv (P2 skill-promotion-N3)

## TL;DR

When `gap-hunt-probe` flags a script with `probe-without-receiver` OR
`wired-but-cold` class AND the script has no existing test referencing
its CLI surface, the canonical fix is a **canonical-CLI test wire-in**
at `tests/<script-name>-canonical-cli.sh` (or `.flywheel/tests/test_<script>.sh`)
exercising N≥5 surface commands. The test serves as receiver-evidence
under the corpus extension shipped by flywheel-2xdi.88
(`*-canonical-cli*.sh` glob added to `test_files_corpus`). Probe finds
the test via the corpus → script no longer flagged.

This recipe sits alongside sister recipes:
- `cluster-maintainer-pattern.md` (flywheel-r9pri, N=3 cluster fix)
- `forward-link-doctrine-doc-recipe.md` (flywheel-pmg3c, N=4 memory wire-in)
- `test-receiver-wire-in-recipe.md` (flywheel-eq9wv, N=3 test-receiver wire-in — THIS doc)

All three are substrate-self-improvement N=3+ promotions converging
on the same family: **auto-injected canonical recipes for routine
gap-hunt class clearance**.

## Recurrence threshold (N=3 MET)

| # | Bead | Subject | Disposition |
|---|---|---|---|
| 1 | flywheel-2xdi.87 | fleet-canonical-rule-freshness-probe.sh | doctrinally-canonical-but-not-invoked subclass (probe-without-receiver baseline) |
| 2 | flywheel-2xdi.144 | canonical-cli-lint-precommit-installer.sh | `flywheel_cli_surface` registry allowlist + canonical-CLI test wired |
| 3 | flywheel-2xdi.146 | codex-pane-path-probe.sh | 10/10 PASS test receiver wire-in, double-class clearance (wired-but-cold + probe-without-receiver) |

Per `feedback_convergent_evolution_is_canonical_signal` 3-strike rule:
N=3 fires the mechanization trigger. This doctrine doc is the canonical
write-up.

## Recipe (5 steps)

When you see a `[gap-probe-without-receiver]` or `[gap-wired-but-cold]`
bead for `<script>.sh`:

### Step 1 — Identify canonical CLI surface

Inspect the script for its canonical-cli-scoping triad shape:
- `<script>.sh doctor [--json]`
- `<script>.sh health [--json]`
- `<script>.sh repair --scope <s> [--dry-run|--apply]`
- `<script>.sh validate <subject> [value]`
- `<script>.sh audit [N]`
- `<script>.sh why <id>`
- `<script>.sh --info | --examples | quickstart | help <topic> | completion <shell> | schema`

If the script lacks canonical-cli scaffolding entirely, **STOP**: this
recipe doesn't apply. Either scaffold the script first
(`.flywheel/scripts/scaffold-canonical-cli.sh`) or pick a different
disposition (cluster-maintainer-pattern.md if the skill has a
doc-completeness gap, or AUDIT-ONLY if Jeff Premium).

### Step 2 — Write the test file at canonical path

```bash
# Location: tests/ (or .flywheel/tests/ for script tests)
# Naming: <script-basename-without-.sh>-canonical-cli.sh
test_path="tests/<script>-canonical-cli.sh"
cat > "$test_path" <<'EOF'
#!/usr/bin/env bash
# tests/<script>-canonical-cli.sh — canonical-CLI surface tests
# Filed by flywheel-<bead-id> per test-receiver-wire-in-recipe/v1
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/<script>.sh"
pass=0; fail=0
p() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
f() { fail=$((fail+1)); printf 'FAIL %s\n' "$1" >&2; }
# Exercise N≥5 canonical-cli commands:
"$SCRIPT" doctor --json | jq -e '.checks' >/dev/null && p "doctor" || f "doctor"
"$SCRIPT" --info --json | jq -e '.name' >/dev/null && p "info" || f "info"
"$SCRIPT" --examples --json | jq -e '.examples | length > 0' >/dev/null && p "examples" || f "examples"
"$SCRIPT" schema --json | jq -e '.envelope' >/dev/null && p "schema" || f "schema"
"$SCRIPT" --help 2>&1 | grep -q 'usage' && p "help" || f "help"
printf '%d passed, %d failed\n' "$pass" "$fail"
exit "$fail"
EOF
chmod 755 "$test_path"
```

### Step 3 — Verify probe re-classification

```bash
.flywheel/scripts/gap-hunt-probe.sh --json | python3 -c "
import sys, json
d = json.load(sys.stdin)
ids = d.get('gap_ids', [])
hits = [g for g in ids if '<script>' in g]
print('hits remaining:', hits)
"
# Expected: hits remaining: []
```

Per flywheel-2xdi.88, `test_files_corpus()` includes
`*-canonical-cli*.sh` glob; the test's reference to the script via
`SCRIPT="$ROOT/.flywheel/scripts/<script>.sh"` is receiver-evidence.

Per flywheel-2xdi.140, `wired-but-cold` detector also consults
`test_files_corpus()` (in addition to `probe-without-receiver`), so
both classes clear with a single test wire-in.

### Step 4 — Commit with double-class-clearance disposition

```text
test(<script>): canonical-cli receiver wire-in [flywheel-<bead-id>]

5-command test exercises script's canonical-CLI surface; serves as
receiver-evidence under flywheel-2xdi.88 (test_files_corpus glob
*-canonical-cli*.sh) + flywheel-2xdi.140 (wired-but-cold corpus
extends to test_files_corpus). Double-class clearance:
  probe-without-receiver: cleared
  wired-but-cold:         cleared

four_lens=brand:10,sniff:10,jeff:10,public:10
```

### Step 5 — `br close` with disposition tag

```bash
br close flywheel-<bead-id>
# Implicit disposition: double-class-clearance via canonical-cli test
# wire-in per test-receiver-wire-in-recipe/v1
```

## What this is NOT

- **NOT a substitute for canonical-cli scaffolding.** If the script
  doesn't already implement the canonical-cli triad, scaffold first
  (`.flywheel/scripts/scaffold-canonical-cli.sh`) — don't ship a test
  that documents a non-existent surface.
- **NOT applicable to Jeff Premium skills.** Per
  `feedback_no_push_ntm_br` + Jeff-substrate AUDIT-ONLY discipline
  (canonical at N=3: 2xdi.97/130/138), don't write tests for Jeff
  scripts as a Jeff-issue-chain shortcut.
- **NOT a substitute for cluster-maintainer-pattern.md.** When the
  underlying issue is doc-completeness across multiple scripts in a
  skill, the cluster-maintainer recipe is the canonical fix
  (per flywheel-r9pri); this test-receiver recipe is for SINGLE-script
  surface coverage.
- **NOT a substitute for forward-link-doctrine-doc-recipe.md.** When
  the underlying issue is memory-without-cross-link, the forward-link
  recipe is canonical; this test-receiver recipe is for script-class
  gaps.

## When to apply

| Gap class | Script has CLI surface? | Disposition |
|---|---|---|
| probe-without-receiver | YES | **THIS recipe** (test-receiver wire-in) |
| probe-without-receiver | NO | scaffold first via scaffold-canonical-cli.sh |
| wired-but-cold | YES, plus no doc | **THIS recipe** (double-class clearance) |
| wired-but-cold | YES, doc gap is in SKILL.md | cluster-maintainer-pattern.md (skill-wide doc fix) |
| memory-without-cross-link | n/a (memory, not script) | forward-link-doctrine-doc-recipe.md |
| Jeff Premium target | n/a | AUDIT-ONLY per Jeff-substrate boundary |

## Substrate-self-improvement family (3-recipe convergence)

Per recurrence taxonomy:

| Recipe | N | Bead | Class |
|---|---|---|---|
| cluster-maintainer-pattern | 3 | flywheel-r9pri | skill-wide doc-completeness |
| forward-link-doctrine-doc-recipe | 4 | flywheel-pmg3c | memory-without-cross-link |
| **test-receiver-wire-in-recipe** | **3** | **flywheel-eq9wv** | **probe-without-receiver + wired-but-cold (per-script)** |

All three are auto-injection candidates for dispatch packets (Option B
in flywheel-eq9wv's decision matrix). The forward-link recipe is
already auto-injected via `.flywheel/scripts/inject-forward-link-recipe.sh`;
a parallel injection for this recipe is a natural follow-up if N≥1
recurrence is observed within the next ~1 week. Not auto-filed —
let the next gap-probe-without-receiver dispatch surface the need
empirically.

## Cross-references

- Source bead: flywheel-eq9wv (P2 skill-promotion-N3, shipped 2026-05-11)
- N=3 trigger beads: flywheel-2xdi.87 + flywheel-2xdi.144 + flywheel-2xdi.146
- Receiver-corpus extensions: flywheel-2xdi.88 (test_files_corpus glob) + flywheel-2xdi.140 (wired-but-cold +tests)
- Sister recipe: `.flywheel/doctrine/cluster-maintainer-pattern.md`
- Sister recipe: `.flywheel/doctrine/forward-link-doctrine-doc-recipe.md`
- Canonical-cli scaffold: `.flywheel/scripts/scaffold-canonical-cli.sh`
- META-RULE: `.flywheel/doctrine/bead-hypothesis-starting-point.md`
- 3-strike memory: `feedback_convergent_evolution_is_canonical_signal.md`
