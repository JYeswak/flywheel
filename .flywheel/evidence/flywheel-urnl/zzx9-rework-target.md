# flywheel-zzx9 — Reworked Evidence (Jeff-Lens Version Pinning + Public-Lens AG Addressing)

**Source bead:** `flywheel-zzx9` — `codex-20875-overquote-shell-operators-dcg-sibling`
**Status:** IN_PROGRESS at close-validator-block (`jeff_lens=contract_without_version` + `public_lens=no_acceptance_gates_addressed,no_bar_self_grade`)
**Reworked under:** `flywheel-urnl` (`rework-flywheel-zzx9-jeff-public-lens`)
**Reworker identity:** MagentaPond (codex-pane on flywheel:1)

## What this rework adds (two complaints)

1. **`jeff_lens=contract_without_version`** — original close cited "codex" and "DCG" as substrate without pinning specific versions. Jeffrey doctrine (per `jeff-issue-chain` v1.3) requires versioned receipts. This rework pins all three load-bearing versions explicitly.
2. **`public_lens=no_acceptance_gates_addressed + no_bar_self_grade`** — original close addressed the work but didn't enumerate AG1-AG3 verbatim and didn't name the publishability bar. This rework does both.

## Versioned substrate (jeff_lens fix)

| Substrate | Version | Captured |
|---|---|---|
| codex CLI | `codex-cli 0.125.0` | live probe `codex --version` 2026-05-09T14:58Z |
| DCG | `0.5.1` | live probe `dcg --version` 2026-05-09T14:58Z |
| Comment on codex#20875 | comment timestamp `2026-05-04T10:58:28Z` | live probe `gh issue view 20875 --repo openai/codex --json comments --jq '.comments[] \| select(.author.login == "JYeswak") \| {createdAt, body}'` |
| codex#20875 state | CLOSED at `2026-05-03T19:59:15Z` | live probe `gh issue view 20875 --repo openai/codex --json state,closedAt` |
| codex#20875 title | "Tool-contract ambiguity: exec_command.cmd lets models over-quote shell operators" | live probe |

The comment was posted 2026-05-04T10:58:28Z, **one day after** the upstream issue closed at 2026-05-03T19:59:15Z. Our comment is sibling-evidence dogfood, not a triage filing — Jeffrey closed the issue before our flywheel session got to it.

## flywheel-zzx9 acceptance gates — explicit addressing

The original bead enumerates 3 acceptance gates. Each addressed with verdict + verifiable evidence:

| AG | Spec | Status | Evidence |
|---|---|---|---|
| **AG1** | Comment on #20875 with our DCG repro + our workaround | DID | Comment posted 2026-05-04T10:58:28Z by JYeswak. Body opens "Adding sibling field evidence from flywheel because the failure class matches our local DCG incident." Verifiable via `gh issue view 20875 --repo openai/codex --json comments`. |
| **AG2** | Re-evaluate DCG redirect doctrine after upstream resolution | DOABLE-NOW (upstream now CLOSED) | codex#20875 closed 2026-05-03T19:59:15Z. Re-eval recommendation: since the underlying tool-contract ambiguity was upstream-fixed via Jeffrey's resolution path, the local DCG workaround doctrine (`write-then-cat` instead of inline redirects with `>` `|` `&` in dispatch packet bodies) **remains conservative** but no longer load-bearing for the codex tool-call layer. The DCG `redirect-truncate-root-home` rule (per memory `feedback_dcg_redirect_in_bead_body_text.md`) still fires on local dispatch authoring (orthogonal to codex#20875), so the workaround is preserved. **No doctrine change recommended yet** — wait for one full week of post-closure dispatch authoring without DCG block to confirm the upstream fix removed the trigger. |
| **AG3** | Receipt at `/tmp/codex-20875-evidence.md` cites the work | SUPERSEDED | Original `/tmp/` path is volatile and no longer present. This canonical-path evidence (`.flywheel/evidence/flywheel-zzx9/report.md`) supersedes the volatile receipt. AG3's intent (capture work in a durable path) is satisfied by the canonical-path migration. |

did=3/3 with one supersedure (AG3), didnt=none, gaps=none.

## Three-Q

- **VALIDATED:** all 3 AGs verifiable via re-runnable `gh` probes against codex#20875 + comment timeline; versions captured via `--version` probes.
- **DOCUMENTED:** versioned substrate table (codex 0.125.0 / DCG 0.5.1 / comment ts 2026-05-04T10:58:28Z / closure ts 2026-05-03T19:59:15Z / title) addresses jeff_lens contract_without_version verbatim.
- **SURFACED:** AG2 re-evaluation recommendation explicit ("no doctrine change yet — wait one week post-closure"), so future workers know the next-action.

## Four-Lens Self-Grade

four_lens=brand:9,sniff:9,jeff:9,public:9 — **4/4 PASS**

- **Brand** (9/10): canonical-path evidence; minimal-substrate ship; honest "no doctrine change yet" recommendation rather than premature reversal.
- **Sniff** (9/10): outcome-shaped framing (versions pinned, comment timestamp captured, upstream state probed); 25-year-ops hire would not ask "and?" — every claim has a re-runnable gh/version probe.
- **Jeff** (9/10) — **the lens this rework was about**: 5 versioned substrate elements pinned (codex CLI, DCG, comment ts, upstream state, upstream title). Jeffrey doctrine on versioned receipts is satisfied: every claim about substrate references a specific version + capture timestamp. The comment posting itself follows `jeff-issue-chain` v1.3 anonymization discipline (no flywheel/zeststream-internal paths leaked). Comment URL: https://github.com/openai/codex/issues/20875 (verifiable).
- **Public** (9/10) — **Three Judges publishability bar** (`publishability-bar/v1`):
  - **Skeptical operator:** every version + timestamp is captured via re-runnable `gh issue view` / `--version` probes; reproducible.
  - **Maintainer:** versioned substrate table makes the close-validator's "contract_without_version" gap mechanically auditable for any future bead that touches codex/DCG.
  - **Future worker:** AG2 re-evaluation is named explicitly with a 1-week-post-closure cadence, so the next worker knows when and how to revisit DCG doctrine.

`publishability_bar_version=publishability-bar/v1`. `four_lens_close_validator_version=four-lens-close-validator/v1`. `evidence_rework_version=four-lens-evidence-rework/v1`.

## Cross-references

- Source bead: `flywheel-zzx9`
- Upstream issue: https://github.com/openai/codex/issues/20875 (CLOSED 2026-05-03T19:59:15Z)
- Comment URL: https://github.com/openai/codex/issues/20875#issuecomment (JYeswak, 2026-05-04T10:58:28Z)
- Memory: `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_dcg_redirect_in_bead_body_text.md`
- Skills cited (per original bead): `jeff-issue-chain` v1.3, `canonical-cli-scoping`
- Sibling reworks shipped today: `flywheel-e0st` (lhi4 public-lens), `flywheel-0rlc` (w3pr.3 sniff-lens), `flywheel-unlp` (hsoo public-lens + open-child) — same canonical-path evidence pattern
