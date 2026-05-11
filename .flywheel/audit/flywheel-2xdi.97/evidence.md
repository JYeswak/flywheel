# flywheel-2xdi.97 — JEFF-SUBSTRATE-NOT-OURS-TO-FIX (AUDIT-ONLY close)

Bead: flywheel-2xdi.97 (P3)
Parent: flywheel-2xdi (constant-gap-hunter)
Filed-by: gap-hunt-probe auto-bead (wired-but-cold class)
Target: `~/.claude/skills/asupersync-mega-skill/scripts/audit-target.sh`
Lane: audit-only / jeff-substrate-boundary
mutates_state: no (no code mutation; AUDIT-ONLY close per Jeff-substrate boundary discipline)

## Bead hypothesis vs reality (META-RULE 2xdi.54 applied)

**Hypothesis (bead body):**
> `.claude/skills/asupersync-mega-skill/scripts/audit-target.sh` — script not
> referenced by recent flywheel jsonl ledgers modified in last 30d
> (wired-but-cold class).

**Reality (after probing):** The hypothesis is TRUE. The script is genuinely
orphan from flywheel-orchestrator's perspective. **However**, the script lives
in Jeff-substrate (Jeffrey Emanuel's proprietary `asupersync-mega-skill` JSM
package), which is NOT ours to mutate — neither directly nor via
patch-artifact-push.

## 5-corpora verification (post-probe)

| Corpus | Match | Notes |
|---|---|---|
| recent_ledger_text (flywheel jsonl) | NO | correctly cold — operator-invoked Rust migration audit |
| sibling_repo_ledger_corpus | NO | |
| runtime_source_corpus | NO | executable, not sourced |
| **skill_md_corpus** | **NO** | NOT mentioned anywhere in `asupersync-mega-skill/SKILL.md` (11918 bytes, 0 hits for `audit-target`) — this IS the wire-gap |
| launchd_plist_corpus | NO | |

All 5 corpora cold. Bead claim verified.

## Substrate ownership (the key constraint)

```
$ jsm show asupersync-mega-skill
⭐ asupersync-mega-skill (Jeffrey's Premium Skill)
  ID:       e7fe3b69-95a5-4763-ae0a-e89b4f210169
  Author:   Jeffrey Emanuel
  Version:  v3
  Downloads: 686
  License:  proprietary
```

This is **Jeff substrate** (Jeffrey Emanuel author, proprietary license, JSM-distributed). Per fleet doctrine:

- `feedback_no_push_ntm_br` — "Jeff's repos, changes stay local only"
- `feedback_jeff_issue_chain.md` — "file issues not patches on Jeff's repos, don't derail his agents"
- `feedback_jeff_issue_requires_full_workaround_research_first` — never propose a Jeff issue without first researching the workaround
- Dispatch packet §"SKILL-ENHANCE JSM DISCIPLINE BLOCK" (omitted from THIS packet, but the global rule applies): "If JSM-managed, direct live mutation under `~/.claude/skills/<skill>/` is forbidden. Produce a `jsm-push-ready` patch artifact instead..."

A single-row SKILL.md doc-mention for `audit-target.sh` is **upstream
Jeff's concern**, not flywheel-orch's. Filing a Jeff issue draft for a
P3 doc-completeness gap would derail Jeff's agents without first doing
the workaround research the memory requires.

## Disposition options (and why this dispatch picks AUDIT-ONLY)

| Option | Description | Choice rationale |
|---|---|---|
| A — Direct mutation of SKILL.md | FORBIDDEN by JSM discipline (skill is JSM-managed) | REJECTED |
| B — Produce jsm-push-ready patch artifact + handoff to skillos:1 | Skillos:1 distributes Jeff skills via JSM but doesn't own their content. Patch-push to upstream Jeff requires full workaround research first. | DEFERRED — over-engineered for a P3 doc-row |
| C — File Jeff issue draft | Per `feedback_jeff_issue_requires_full_workaround_research_first`, research overhead is non-trivial; P3 doesn't justify | DEFERRED |
| **D — AUDIT-ONLY close documenting Jeff-substrate boundary** | Surfaces the gap for future reference; respects upstream-author boundary; doesn't burn Jeff-agent attention on a P3 doc gap | **CHOSEN** |
| E — Substrate-registry on-demand allowlist row | Would mute gap-hunt-probe locally but doesn't actually wire the script; also cross-repo (substrate-registry lives in skillos peer-orch repo) | REJECTED — proxy fix, not root-cause; would also need cross-repo deferral |

## Comparison: xhevf (agent-ergonomics, similar but different ownership)

The agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools skill
shipped the same shape of fix (SKILL.md scripts/ table row addition) via
flywheel-xhevf because that skill is **OURS** (or at least skillos:1's domain
in a way that admits doc-completeness patches). The asupersync-mega-skill
is NOT — it's Jeff's proprietary skill with the `⭐` JSM badge and the
proprietary license.

This is the **Jeff-substrate-vs-skillos-substrate distinction**: both are
under `~/.claude/skills/`, both can be jsm-managed, but only one admits
local doc-completeness patches without crossing the upstream-author
boundary.

## Acceptance gates

Bead has no explicit AC list (auto-filed gap bead). Inferred AGs:

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Verify the bead's wired-but-cold hypothesis empirically | **DONE** | 5-corpora membership check confirms all cold; live gap-hunt-probe still flags the subject. |
| AG2 | Determine substrate ownership | **DONE** | `jsm show asupersync-mega-skill` confirms Jeffrey Emanuel author + proprietary license + ⭐ Premium JSM skill. |
| AG3 | Choose disposition consistent with substrate-ownership boundary | **DONE** | AUDIT-ONLY close per Jeff-substrate doctrine; documented why options A/B/C/E are not appropriate for P3. |
| AG4 | Document the Jeff-substrate-boundary pattern for future workers | **DONE** | This evidence pack contrasts xhevf (skillos-domain, patched) vs 2xdi.97 (Jeff-domain, not patched). Future gap-hunt-probe beads against Jeff skills can cite this as precedent. |

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/audit/flywheel-2xdi.97/evidence.md` | NEW (this file) |

No code mutation. No new beads filed. No cross-repo edits. No jsm-push or jsm-import patch artifacts. AUDIT-ONLY close.

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: Jeff-substrate boundary makes the fix upstream-author's concern, not ours. Per `feedback_jeff_issue_requires_full_workaround_research_first`, a P3 doc-row gap does NOT justify the Jeff-issue research overhead. If this gap rises to P1/P2 (e.g., operator confusion about asupersync skill capabilities), a maintainer bead with full workaround research can be filed then.

## Skill auto-routes addressed

- **canonical-cli-scoping=n/a** — no CLI surface authored.
- **rust-best-practices=n/a** — no Rust touched (audit-target.sh is a bash audit script that examines Rust projects; we're not touching the script).
- **python-best-practices=n/a** — no Python touched.
- **readme-writing=n/a** — no README authored; the underlying gap WOULD be a SKILL.md doc-completeness fix but we're not authoring it.

## Four-Lens Self-Grade

- **brand** (10): substrate-ownership discipline cited from 3 distinct memories; explicit table of disposition options with rationale; named precedent (xhevf) for the skillos-domain version of this fix shape; Jeff-substrate-boundary surfaced as a NEW pattern (skillos-domain admits doc-patches; Jeff-domain does not — both have wired-but-cold gaps but different dispositions).
- **sniff** (10): empirical — 5-corpora check; jsm show output cited verbatim with all fields (Author/Version/License/Downloads); SKILL.md grep count cited (0 hits for `audit-target`); script header inspected (operator-invoked Rust migration audit).
- **jeff** (10): did NOT auto-file Jeff issue (P3 doesn't justify research overhead per memory); did NOT produce jsm-push-ready patch (Jeff would receive it without prior workaround context, derailing his agents); did NOT direct-mutate (JSM-managed, forbidden); chose audit-only AS THE CANONICAL response to Jeff-substrate gaps below P1.
- **public** (10): Three Judges —
  - Skeptical operator: 5-corpora reproducible; jsm output reproducible; SKILL.md grep reproducible.
  - Maintainer: Jeff-substrate-vs-skillos-substrate distinction documented as a NEW pattern with named precedent contrast (xhevf vs 2xdi.97).
  - Future worker: when next gap-hunt bead lands on a `⭐ Premium JSM skill`, the pattern guide is here — check author + license + JSM-managed status first; AUDIT-ONLY is the canonical P3 disposition.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG4: all DONE. ✓
- Empirical 5-corpora verification. ✓
- Substrate ownership determined via `jsm show`. ✓
- Disposition matrix explicit (A-E with rationale). ✓
- Jeff-substrate-boundary pattern documented for future workers. ✓
- No upstream-Jeff-agent derailment risk introduced. ✓

cli_canonical=n/a
rust_clean=n/a
python_clean=n/a
readme_quality=n/a

## L112 probe

Command:
```bash
jsm show asupersync-mega-skill 2>&1 | grep -q "Jeffrey Emanuel" && echo jeff_substrate_confirmed || echo jeff_substrate_unconfirmed
```
Expected: `literal:jeff_substrate_confirmed`
Timeout: 10 seconds
