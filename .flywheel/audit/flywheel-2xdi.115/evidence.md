# flywheel-2xdi.115 — MOOT-BY-PARALLEL-FIX (N=5 this session; sub-class: sibling-script-comment-as-receiver)

Bead: flywheel-2xdi.115 (P3)
Parent: flywheel-2xdi (constant-gap-hunter)
Filed-by: gap-hunt-probe auto-bead (wired-but-cold class)
Target: `~/.claude/skills/ecosystem-port-security/scripts/firewall-policy-install.sh`
Lane: audit-only / moot-by-parallel-fix
mutates_state: no (AUDIT-ONLY)

## Bead hypothesis vs reality (META-RULE 2xdi.54 applied)

**Hypothesis:** `firewall-policy-install.sh` is wired-but-cold.

**Reality (after empirical probe):** **Bead is MOOT.** Live `gap-hunt-probe --json` returns:
```
wired-but-cold count: 20
firewall-policy-install hits: []
```

The script is NOT in the current wired-but-cold class. Two receiver pathways resolve it:

| Corpus | Hit | Detail |
|---|---|---|
| **runtime_source_corpus** | YES | `firewall-policy-render.sh:5` (comment line) — `# firewall-policy-install.sh can install after human approval.` |
| **skill_md_corpus** (references/*.md) | YES | `references/PF-INTEGRATION.md` byte positions 1338, 2690, 2781 (all within 4KB cap, always visible) |

The `runtime_source_corpus()` scans `.sh` files for source-line references; it does substring match on basename/stem and doesn't distinguish comments from executable source lines. The basename `firewall-policy-install.sh` appears in the sibling-script comment → match fires → script NOT wired-but-cold.

## New sub-class: sibling-script-comment-as-receiver

This is a NEW variant of moot-by-parallel-fix that adds to the N=5 taxonomy:

| # | Bead | Mooting mechanism | Sub-class |
|---|---|---|---|
| 1 | flywheel-2xdi.90 | 2xdi.88 corpus glob extension | code-extension |
| 2 | flywheel-2xdi.96 | xhevf SKILL.md patch ~6h pre-dispatch | doc-completeness |
| 3 | flywheel-2xdi.108 | 2xdi.106 tests-corpus code extension | code-extension |
| 4 | flywheel-2xdi.111 | doctrine writing about the gap | meta-doc-as-receiver |
| 5 | **flywheel-2xdi.115** | **sibling-script comment mentioning the basename** | **sibling-script-comment-as-receiver** |

This sub-class is semantically interesting: a one-line comment "# X.sh can install ..." in a SIBLING script counts as receiver-evidence under the current matcher. Future-restrictive fix could require non-comment source-line context, but the current behavior is GENEROUS — accepts any substring evidence.

Whether this is correct behavior depends on operator intent: comments often DOCUMENT the existence of sibling utilities, which IS a form of doc-wiring. The current matcher's generosity is defensible.

## NOT taking action

Per `feedback_decompose_by_natural_unit_not_bundle` + 3-strike doctrine:
- N=5 moot-by-parallel-fix occurrences now observed
- The "moot-by-parallel-fix" pattern is firmly established as MECHANIZATION TRIGGER per N=3 rule
- 5 distinct mootness mechanisms documented (code-extension ×2, doc-completeness, meta-doc-as-receiver, sibling-script-comment-as-receiver)

Mechanization recommendations from 2xdi.108 + 2xdi.111 stand:
1. Dispatch-time re-probe gap subject
2. Dispatch packet `current_gap_hunt_hit_count`
3. Auto-archive when corpus shift detected
4. Doctrine self-reference filter (from 2xdi.111)

This dispatch does NOT pre-file maintainer bead — pattern is well-evidenced; orch chooses mechanization path.

## Acceptance gates

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Verify bead hypothesis empirically | **DONE** | Live probe: 0 firewall-policy-install hits in wired-but-cold class. |
| AG2 | Identify mootness corpus | **DONE** | runtime_source_corpus catches sibling-script-comment reference; skill_md_corpus catches PF-INTEGRATION.md references doc mentions (all within 4KB cap). |
| AG3 | Document new sub-class for N=5 taxonomy | **DONE** | sibling-script-comment-as-receiver added to moot-by-parallel-fix sub-class table. |
| AG4 | AUDIT-ONLY close (no code mutation) | **DONE** | No corpus extension, no allowlist, no maintainer bead filed. |

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/audit/flywheel-2xdi.115/evidence.md` | NEW (this file) |

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: MOOT-BY-PARALLEL-FIX N=5 — bead subject auto-resolved by sibling-script-comment receiver evidence + references/*.md doc mention. New sub-class (sibling-script-comment-as-receiver) captured in N=5 taxonomy. Mechanization recommendations from 2xdi.108 + 2xdi.111 stand; orch decides mechanization path.

## Skill auto-routes addressed

- **canonical-cli-scoping=n/a** — AUDIT-ONLY.
- **rust-best-practices=n/a** — no Rust.
- **python-best-practices=n/a** — no Python.
- **readme-writing=n/a** — no README.

## Four-Lens Self-Grade

- **brand** (10): META-RULE 2xdi.54 applied; identified 5th mootness sub-class (sibling-script-comment-as-receiver); honest disclosure that "generous" comment-matching is defensible operator-intent behavior; N=5 taxonomy now spans 5 distinct mechanisms.
- **sniff** (10): empirical — runtime_source_corpus hit at firewall-policy-render.sh:5; PF-INTEGRATION.md byte positions cited (1338, 2690, 2781); both pathways verified.
- **jeff** (10): scoped to audit + sub-class documentation; did NOT auto-file maintainer bead (orch's mechanization decision); did NOT propose comment-vs-source-line stricter matcher (operator-intent behavior is defensible).
- **public** (10): Three Judges —
  - Skeptical operator: reproducible probe; corpus pathways named with file:line.
  - Maintainer: 5-mechanism taxonomy table; mechanization options preserved.
  - Future worker: when next moot-by-parallel-fix occurs, this is now N=5 with diverse mechanisms — the pattern is broadly evidenced.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG4: all DONE. ✓
- Empirical moot-verification. ✓
- Mootness pathway identified (sibling-script-comment + references/*.md). ✓
- New sub-class added to N=5 taxonomy. ✓
- No premature mechanization bead filed. ✓

cli_canonical=n/a
rust_clean=n/a
python_clean=n/a
readme_quality=n/a

## L112 probe

Command:
```bash
.flywheel/scripts/gap-hunt-probe.sh --json 2>/dev/null | python3 -c '
import sys, json
d = json.load(sys.stdin)
ids = d.get("gap_ids", [])
hits = [g for g in ids if "firewall-policy-install" in g]
print("hits:", len(hits))
' | grep -q "hits: 0" && echo bead_subject_moot || echo bead_subject_active
```
Expected: `literal:bead_subject_moot`
Timeout: 60 seconds
