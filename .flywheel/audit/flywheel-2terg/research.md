---
schema_version: github-profile-research/v1
bead: flywheel-2terg
authored_by: MagentaPond (flywheel:0.3)
authored_at: 2026-05-11
sources:
  - source_id: dicklesworthstone-profile-readme
    path: /Users/josh/Developer/Dicklesworthstone/README.md
    lines: 401
    fetched_at: 2026-05-11
  - source_id: jeff-repo-readmes-cohort
    paths:
      - /Users/josh/Developer/ntm/README.md (555 lines)
      - /Users/josh/Developer/beads_rust/README.md (794 lines)
      - /Users/josh/Developer/mcp_agent_mail/README.md (2608 lines)
      - /Users/josh/Developer/meta_skill/README.md (804 lines)
      - /Users/josh/Developer/destructive_command_guard/README.md (2226 lines)
      - /Users/josh/Developer/frankensqlite/README.md (2638 lines)
      - /Users/josh/Developer/coding_agent_session_search/README.md (2867 lines)
    fetched_at: 2026-05-11
  - source_id: jeff-substrate-inventory-memory
    path: /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/reference_jeff_substrate_inventory.md
    fetched_at: 2026-05-11
triangulation_check: pass (3 independent local-clone sources, no single-source claims per Axiom 22)
---

# Research: Jeff Emanuel (`@Dicklesworthstone`) Public-Github Storytelling Patterns

## Purpose

Catalog the storytelling/selling patterns Jeff Emanuel uses on his GitHub
profile + flagship-repo READMEs, so the ZestStream `jyeswak` profile can
adapt the structural moves to Joshua's voice without copying tone or claims.

## Why Jeff is the right exemplar

Per memory (`reference_jeff_substrate_inventory.md`, `reference_dicklesworthstone_stack_ntm.md`):

- 7 binaries the flywheel literally runs on (`dcg`, `ntm`, `br`, `cm`, `jsm`, `frankensqlite`, mcp-agent-mail)
- 177 public Dicklesworthstone repos cloned locally (2026-05-03 substrate inventory)
- Profile self-reports: 21k+ stars, 176 projects, 108,221 contributions in past year,
  2.5k+ followers, 43.7k X followers
- Recognized by Naval Ravikant, Matt Levine, Simon Willison, Steve Yegge
- Same engineering ecosystem ZestStream's `skillos` substrate composes onto

Jeff is the **closest peer exemplar by domain + tool-stack overlap**. Adapting
his structural moves is not imitation — it's pattern-borrow from the operator
in our literal supply chain.

## Profile-level pattern catalog (21 moves)

| # | Pattern | Section | Where (line) | Mechanic |
|---|---|---|---|---|
| P1 | One-line identity anchor | header | L7 | `**Location** · Role · Prior credibility` (`New York · Builder & engineer · Former long/short equity analyst`) |
| P2 | Stack badges as visual identity | header | L9-18 | 10 language/tool badges, gray-themed, consistent style |
| P3 | Italic capability tagline | header | L20 | `*Building the tooling that lets dozens of AI agents ship complex projects in days.*` — one sentence that names the operating thesis |
| P4 | Quantified credibility badges | header | L22-26 | Stars 21k+, Repos 176, Contributions 108k+, Followers 2.5k+, X 43.7k — concrete numbers, not "lots of" |
| P5 | Product-property badges row | header | L28-37 | Every product website linked with its own badge (10 sites). Visual proof of shipping |
| P6 | Topic chips | header | L39 | Backtick-quoted topic taxonomy as last header line: `Multi-Agent Coordination · Agentic Coding · Rust CLI Tools · LLM Applications · Terminal UI · FrankenSuite` |
| P7 | Centered TOC | post-header | L43-45 | Pipe-separated `<a href>` jump links to every section. Lets a skim find the proof |
| P8 | Stats SVG pair | post-header | L47-58 | GitHub stats + top-languages SVGs side by side with light/dark preference |
| P9 | NOTE callout with magnetic claim | post-header | L60-62 | `> [!NOTE]` "108,221 contributions in the past year, powered by 52+ AI coding agent subscription accounts (~$12K/month)" — concrete + surprising + grounded in the toolkit below |
| P10 | Named ecosystem section | body | L65-108 | `## The Agentic Coding Flywheel` — proprietary methodology name. Each tool gets a row in Tool / Stars / Lang / Purpose table. 14 tools |
| P11 | Quick Install TIP callout | mid-section | L92-101 | `> [!TIP]` with curl one-liner. Lowers activation energy from read → try |
| P12 | "In Action" GIF block | mid-section | L103-107 | Animated screenshot showing the tool working. Visual proof, not just claims |
| P13 | Themed sub-collections | body | L111-133 | `## The FrankenSuite` — 17 reimplementations as a named family. Pattern: name + reuse + technical innovation per row |
| P14 | "What I'm Building Now" | body | L137-145 | 5 active-WIP projects. Shows momentum |
| P15 | Live Demos table | body | L147-201 | 9 live-demo thumbnails. Click-through to working products |
| P16 | Categorized open-source highlights | body | L205-292 | 6 sub-categories: AI & LLM / Systems & Rust / Research & Science / Developer Tools / Education & Visualization / More. Star badge + bold link + one-line description per row |
| P17 | Case-study credibility section | body | L296-319 | `## The Nvidia Short Thesis` — single high-leverage past hit with named-figure pull quotes (Naval / Matt Levine / Simon Willison). Proves judgment, not just shipping |
| P18 | Writing list | body | L323-335 | 9 essays linked from personal site. Shows depth-of-thought beyond code |
| P19 | GitHub Activity chart | body | L339-347 | Contribution heatmap + star-history chart for top repos. Visual momentum proof |
| P20 | Products | body | L351-361 | Emoji-prefixed product list (9 products, mix of free + paid). Mixes free OSS with paid SaaS naturally |
| P21 | Philosophy + Recognition + Connect + Background | tail | L365-401 | Closer trio: `> [!IMPORTANT]` thesis statement → recognition list → social/contact badges → one-line credentials |

## Repo-level pattern catalog (9 moves; from ntm/br/mcp_agent_mail/meta_skill/dcg/frankensqlite/cass)

| # | Pattern | Mechanic |
|---|---|---|
| R1 | Centered hero illustration | `<div align="center"><img src="*_illustration.webp">` at top — visual brand mark per repo |
| R2 | Centered badge row | CI / License / Lang / Status / Coverage badges grouped, centered |
| R3 | One-paragraph capability claim | First prose paragraph names the tool + what it does + key innovations, no fluff |
| R4 | Pipe-separated section TOC | `[Quick Start](#quick-start) \| [Commands](#commands) \| [FAQ](#faq)` |
| R5 | Centered Quick Install H3 | `<div align="center"><h3>Quick Install</h3>` + curl one-liner with `?$(date +%s)` cache-bust |
| R6 | "Why this exists" section | Problem framing before solution (mcp_agent_mail L17-25, ntm equivalent) |
| R7 | "TL;DR" Problem/Solution block | frankensqlite L23-29 — two-paragraph **Problem** / **Solution** with code-anchor citation (`wal.c:3698`) for technical credibility |
| R8 | MIT+Rider license tag | `MIT+OpenAI/Anthropic Rider` — distinctive license name signals operator awareness of AI-training implications |
| R9 | Status honesty | `Status: Under active development.` (mcp_agent_mail L13) — explicit alpha framing, not pretending shipped |

## Voice patterns

| # | Pattern | Example |
|---|---|---|
| V1 | Concrete numbers everywhere | "108,221 contributions", "52+ AI coding agent subscription accounts (~$12K/month)", "850K+ lines of Rust", "$600 billion in market cap evaporated" |
| V2 | Direct technical claims with code-anchor proof | "A single lock byte (`WAL_WRITE_LOCK` at `wal.c:3698`) serializes all writers" |
| V3 | Refusal to puff timeline | "Started October 2025", "shipping cadence accelerates with every addition" — honest about how new the work is |
| V4 | Punchy product taglines | `"It's like gmail for your coding agents!"` |
| V5 | Quote-the-experts social proof | Pull quotes from named figures with photo badges |
| V6 | Italic vision statements | `*Building the tooling that lets dozens of AI agents ship complex projects in days.*` |
| V7 | Tables for scannability | 5+ major tables, every row has star count + lang badge + 1-line purpose |
| V8 | Emoji as visual taxonomy | Product list uses 🌐 💰 📝 ⚡ 📬 🖥️ 🗄️ 🔬 for instant categorical recognition |

## Selling structure (the spine)

```
HOOK (header: identity + tagline + stats badges)
  → SOCIAL PROOF (stats SVGs + NOTE callout)
    → ECOSYSTEM (named methodology + 14-tool table)
      → CURRENT WORK ("Building Now" + Live Demos)
        → DEEP CATALOG (FrankenSuite + categorized OSS)
          → CASE STUDY (Nvidia Short Thesis with pull quotes)
            → WRITING (essays beyond code)
              → PRODUCTS (mix free + paid, emoji-tagged)
                → PHILOSOPHY (IMPORTANT callout: one-sentence thesis)
                  → RECOGNITION (who-cited-me)
                    → CONNECT (social/contact badges)
                      → BACKGROUND (credentials in 4 bullets)
```

This is a **13-stage funnel** from "who is this person" to "I want to follow
them / hire them / use their tools." Each stage adds one new piece of
evidence and lowers the trust threshold for the next.

## What NOT to copy

| Anti-pattern | Reason |
|---|---|
| Fake stats | Joshua isn't at 21K stars or 43K X followers; copying the visual format with fabricated numbers destroys credibility (Sniff lens 0) |
| FrankenSuite naming | Jeff's brand mark; ZestStream needs its own visual taxonomy |
| Hero illustrations on every repo | Requires real asset production; defer until v0.2 + branded asset library |
| Animated GIF showcases | Same — defer until tools are ready to demo |
| Naval/Matt-Levine-tier pull quotes | Earn them, don't fake them. Use real client outcomes (Blackfoot/ALPS/TerraTitle) instead |
| Nvidia-short-thesis case study | Joshua doesn't have a parallel past-prediction headline. Lead with the engine + clients instead |
| Light-mode / dark-mode SVG pair | Cost/benefit doesn't favor it at v0.1 — defer until measurable traffic |

## What TO copy (high-leverage)

| Pattern | Adapt to ZestStream |
|---|---|
| P1 one-line identity anchor | `**Montana** · Founder, ZestStream.ai · MBA, 12 yrs ZIRKEL` |
| P3 italic capability tagline | `*Building the agentic coding infrastructure that runs my company — and my clients'.*` |
| P5 product-property badges | Real products: ZestStream.ai · skillos (when public) · AI Assessment landing · client outcomes |
| P6 topic chips | Domain taxonomy: `Agentic Coding Flywheel · ISP Operations · AI Assessment · NestJS · PostgreSQL · Skill Engineering` |
| P7 centered TOC | Navigation discipline |
| P10 named ecosystem section | `## The ZestStream Agentic Stack` — flywheel + skillos + ALPS reference architecture |
| P11 Quick Install TIP | `> [!TIP]` for the AI Assessment landing or skillos install (once public) |
| P16 categorized highlights | Adapt categories to ZestStream surface area |
| P17 case-study credibility | Replace Nvidia-short with a real client outcome (when one is publishable + signed off) |
| P21 Philosophy / Recognition / Connect / Background | Closer trio with Joshua's actual voice |
| R3 one-paragraph capability claim | Discipline applies to every ZestStream repo README |
| R4 pipe-separated TOC | Universal pattern |
| R6 "Why this exists" | Universal pattern |
| R9 status honesty | "Internal alpha; npm publish gated by paying-customer-pull" matches `project_publish_decision_internal_proof_first_no_npm_v01_2026_05_11` |
| V1 concrete numbers | Joshua has real numbers (client count, ALPS data scale, etc.) — use them when publishable |
| V3 timeline honesty | "ZestStream founded 2025; flywheel locked-in October 2025" |

## Joshua voice anchors (from skillos README — `reference_jeff_substrate_inventory.md` calibration)

Lines 1-15 of `/Users/josh/Developer/skillos/README.md`:

```
# skillos
> **Mission anchor (locked):** *skillos is ZestStream's Skills Operating System...*
I'm Joshua. I build things that work.
This is the engine I run my company on. Receipts over promises.
```

ZestStream brand voice from this calibration:
- **First person + name** ("I'm Joshua")
- **Plain-English credibility** ("I build things that work")
- **Operating-system claim** ("the engine I run my company on")
- **Anti-puff mantra** ("Receipts over promises")
- **Mission-anchor blockquote** for every public-face artifact

This voice is **less rhetorical** than Jeff's (Jeff: "Building the tooling that
lets dozens of AI agents ship complex projects in days"; Joshua: "I build
things that work"). Jeff is more polished/marketing-tone; Joshua is more
operator-direct. The jyeswak profile must preserve Joshua's terseness while
adopting Jeff's **structural** moves.

## Adaptation principles for jyeswak v0.1

1. **Adopt structure, not tone** — borrow Jeff's 13-stage funnel; keep Joshua's terse-operator voice
2. **Honest at v0.1** — no fabricated stats; lead with what exists + state alpha status
3. **Client work is the case study** — replace Nvidia-short-thesis with a "Clients" section naming Blackfoot/ALPS/TerraTitle (with their permission)
4. **Mission-anchor blockquote** — every public-face artifact opens with one, per skillos pattern
5. **Receipts over promises mantra** — recurring thread
6. **AI Assessment as commercial pull** — substitute for Jeff's paid SaaS products row (per `project_zeststream_ai_assessment_north_star_2026_05_11`)
7. **Internal-proof-first** — explicit "not on npm; gated by paying-customer-pull" status badge or note (per publish-decision memory)
8. **Skill over scale** — surface skillos + flywheel + L-rule discipline as the differentiated craft; resist trying to claim Jeff-scale tool count
9. **No fake hero illustrations** — text-first at v0.1; add brand assets in v0.2
10. **Topic chips honestly chosen** — name what's actually proven, not aspirational

## Sources cited (Axiom 22 compliance: ≥2 independent sources, source-id + fetch-ts)

| Source ID | Path | Fetched-at |
|---|---|---|
| dicklesworthstone-profile-readme | /Users/josh/Developer/Dicklesworthstone/README.md | 2026-05-11 |
| jeff-repo-readmes-cohort (7 repos) | /Users/josh/Developer/{ntm,beads_rust,mcp_agent_mail,meta_skill,destructive_command_guard,frankensqlite,coding_agent_session_search}/README.md | 2026-05-11 |
| jeff-substrate-inventory-memory | ~/.claude/projects/-Users-josh-Developer-flywheel/memory/reference_jeff_substrate_inventory.md | 2026-05-11 |
| skillos-readme-voice-calibration | /Users/josh/Developer/skillos/README.md | 2026-05-11 |
| zeststream-mission-memory | project_zeststream_ai_assessment_north_star_2026_05_11.md, project_publish_decision_internal_proof_first_no_npm_v01_2026_05_11.md | 2026-05-11 |

`triangulation=pass` — 5 independent sources, no single-source claims.
