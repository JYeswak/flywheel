# Public Repo README — Message Architecture (flywheel + zeststream-skillos)

Decided 2026-05-14 by Joshua. Both repos go public so they are downloadable
and read as the package deal. Their READMEs are the front door — and right now
neither reads as the arc.

## The two problems

**flywheel/README.md** is written for *internal workers*, not the public study
audience. "New Worker Checklist," "Full-Substrate Operator Quickstart," "read
these in order," L120-L128 callback fields, `flywheel-codex-orient` — that is
contributor onboarding, not a public front door. It also leads "Why flywheel"
with a per-run export stat dump (14,759 / 10,274 / 4,043 / 7,465).

**zeststream-skillos/README.md** has good bones — the "marketing person walked
out the door" hook, the two anonymized client stories, heavy Jeffrey attribution,
an honest alpha boundary. But it is **stat-heavy, not arc-driven**: a 21-phase
rev-7/8/9 status spreadsheet, "145/101/30/365" counts, PR references (#46-50)
dominate the middle. That is the II-2a anti-pattern — pinned numbers from one
project instead of the arc.

## The shared standard

Both READMEs follow the same arc the site follows:

- **Study material, not a pitch** — structured, revisitable, real explanation.
  Someone lands, understands the whole thing, comes back to re-learn a piece.
- **II-2a — the arc, not the stats.** Lead with *why this exists and where it
  is going*: 25 years of operational discipline, now turned on AI-assisted
  software. Numbers serve the arc (make it concrete); they never replace it. No
  leading with per-run export counts or phase-status spreadsheets.
- **Jeffrey Emanuel's substrate, cited absolutely.** NTM, Agent Mail, beads, CASS,
  jsm, dcg, ubs are Jeffrey's (Dicklesworthstone) — every load-bearing piece named
  and credited. flywheel and skillos are Joshua's, *on top of* that substrate.
  (skillos already does this well — keep it.)
- **Honest alpha boundary.** What is real vs. aspirational, stated plainly. No
  overpromise. (skillos does this well — "the alpha boundary today is real" —
  flywheel must too.)
- **The give-it-away / trust-not-sales philosophy.** Jeffrey's rulebook: make it
  available, document the sharp edges, let the work earn trust. Soft close —
  a 20-minute Peel session, never a sales push.
- **First-person Joshua**, brand-voice gate as the floor, no banned words, no
  superlatives.
- **Public-first / contributor-below-the-fold.** The public study front door
  comes first. Internal operator/worker onboarding moves below the fold or to
  `CONTRIBUTING.md` / `AGENTS.md`. (skillos already does "For peer operators
  running Jeffrey's stack — Below the fold." flywheel must adopt the same split.)

## The README spine — section order, both repos

1. **What it is + the arc.** Open with *why this exists*. flywheel: the
   repo-local operating loop — 25 years of operations discipline turned on
   AI-assisted software. skillos: keep the "your company's skills are trapped"
   hook — it already lands. Lead with the why, not a quickstart, not a stat.

2. **The foundation — Jeffrey Emanuel's substrate.** Named and credited. What each
   piece does, where to get it.

3. **What this repo is.** The thing itself, explained study-grade. flywheel =
   the repo-local operating loop (mission/goal/state/tick/dispatch/beads/
   doctrine, reduced mode + full mode). skillos = the capability control plane
   (inventory, routing, JSM safety matrix, pack synthesis, validation). Keep
   skillos's three-layer diagram — it is good.

4. **How it works.** The architecture, study-grade and concrete.

5. **Honest state.** The alpha boundary — what is shipped, what is aspirational
   — in plain language. A *short* honest paragraph, not a phase spreadsheet.

6. **Take it.** Clone, install, run — written for the public-repos state.
   flywheel: `install.sh` (scoped to `~/.flywheel/engine`, dry-run capable).
   The two honest doors, same as the developer page.

7. **The deal.** Trust, not sales. Book a 20-minute Peel session.

8. **For operators / contributors — below the fold.** Everything internal:
   flywheel's worker checklist, full-substrate quickstart, callback contract,
   read-in-order index. skillos's peer-operator honesty box. This is where the
   contributor machinery lives — not at the top.

## Cuts

- **flywheel:** move "New Worker Checklist," "Full-Substrate Operator
  Quickstart," "Start Here / read these in order," and the L120-L128 callback
  detail to `CONTRIBUTING.md` (it exists) or below the fold. Drop the per-run
  export stat dump from "Why flywheel" — if the publication-evidence number is
  kept anywhere, it goes in the honest-state section as *one* line, framed as
  "the system turns a private substrate into an inspectable public one," not as
  a volume boast.
- **skillos:** compress the 21-phase rev-7/8/9 status spreadsheet to a 2-3 line
  honest "where it is" statement; the detail already lives in `ROADMAP.md` —
  link it, do not inline it. Cut the PR references (#46-50) from the README —
  internal, and meaningless to an outside reader. The "145/101/30/365" counts:
  verify each by running the cited command, then either weave the *survivors*
  into the arc as concrete proof or cut them — a count nobody verified is not a
  receipt.

## Grounding constraints — verify before public

- **Run the cited commands** for every count that stays: skillos's JSM surface
  count, shim count, pack count, indexed-project count. Anything that does not
  match its claim is cut, not shipped.
- **flywheel's per-run export numbers are volatile** — they change every export
  run. They are telemetry, not arc. Keep them out of the README front matter.
- **Client stories stay anonymized** — the gym and the insurance carrier are
  real (Joshua confirmed) but named-client-consent is per-surface; they remain
  "a regional gym," "a regional insurance carrier" unless Joshua gives explicit
  naming consent for the README surface.
- **Brand asset check:** skillos's README opens with `assets/brand/yuzu-hero.jpg`
  — give it the same scrutiny as the /about image; confirm it reads as the
  brand, or replace it.

## Relationship to the other spines

Fourth site/repo architecture doc, alongside the home/operator, developer, and
methodology spines. Same DNA: study-grade where the audience is technical, the
brand-voice gate as the floor, attribution absolute, II-2a (arc not stats),
Joshua's eye as the ceiling.
