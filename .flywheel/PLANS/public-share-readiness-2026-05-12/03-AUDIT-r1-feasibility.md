# 03-AUDIT-r1-feasibility.md — Phase 3 AUDIT (Feasibility Lens)

**Phase:** 3 AUDIT
**Lens:** Feasibility — can this actually be built in the time and effort the plan claims?
**Author:** flywheel:1 / Phase-3 audit lane (feasibility)
**Audited:** `02-REFINE-r4.md` (594 lines, 2026-05-12T~20:00Z)
**Cross-referenced:** `01-RESEARCH-A.md` (substrate inventory), `01-RESEARCH-C.md` (implementation design)
**Authored:** 2026-05-12

---

## 1. Lens summary

The plan is **structurally sound** but **temporally optimistic in three load-bearing places** and **silent on five hidden blockers** that materially affect whether v0.2 ships as scoped. The 40-60 worker-hour extraction estimate is itself a refinement *upward* from CLASSIFICATION-PLAYBOOK's original (Lane A measured 3-5× the original); this audit finds the total *project* envelope is similarly under-estimated because installer/repo/webpage/CI/docs work was not aggregated against the same hour budget.

Critical-path beads (B5 engine CLI, B6 installer, B7 uninstaller, B12.* docs, B13.* webpage) are each L-class on top of the 40-60h extraction. When aggregated, total realistic envelope is **90-130 worker-hours**, not the implied 40-60h. At Joshua's stated agent-supervision cadence (4-5 productive hours/day), that is 18-30 working days — **closer to 6 weeks than the implied 3-4 weeks** for v0.2.

The plan ships as-is **with adjustments**; re-plan is not required. The adjustments are scope-trimming choices (defer skills entirely; ship webpage at v0.2.1 if calendar tightens; recruit first adopter post-launch as already planned) that the plan has anticipated as Joshua-flippable decisions. The verdict below reflects "ship with adjustments."

---

## 2. Findings register

### F1 — Total effort envelope undercounted (HIGH)

**Plan location:** §1 Executive summary ("Realistic extraction effort is **40-60 worker-hours**"); §10.6 DAG table.

**Concern:** The 40-60h figure is the *extraction sweep only* (B3.1-B3.5). The DAG table assigns L-effort to B5 (CLI), B6 (installer), B7 is M but symmetric to B6, B12.* (3 docs beads, M each), B13.* (6 webpage beads, M each + B13.7 deploy), B11 (top-level files, M), B11.5 (case-study redaction, L), B10 (extraction end-to-end, L), B0 (CHARTER, M), B1 (table, M), B1.5 (codemod, M), B2 (classifier, M), B4 (assembly, M), B8 (release.yml, M), B9 (CI workflows, M). Summing L=12-16h and M=6-10h per bead:

- Extraction track (B0-B4, B10): ~12 + 6 + 6 + 6 + 6 + 8 + 8 + 8 + 12 + 6 + 12 = ~90h **before B3.* sweep**
- Wait — B3.* IS the 40-60h sweep. Outside B3.*: 6 + 6 + 6 + 6 + 6 + 8 = ~38h for B0/B1/B1.5/B2/B4/B10 alone.
- Engine + installer track (B5-B9): 14 + 14 + 8 + 8 + 8 = ~52h
- Docs track (B12.1-B12.3): 8 + 8 + 8 = ~24h
- Webpage track (B13.1-B13.7): 8 + 8 + 4 + 8 + 8 + 8 + 8 = ~52h
- Content/release (B11, B11.5, B14, B14.5, B15, B16, B17): 8 + 14 + 2 + 2 + 8 + 2 + 1 = ~37h

**Naive sum (zero parallelism):** 40-60h (B3.*) + 38h (extraction infra) + 52h (engine/installer) + 24h (docs) + 52h (webpage) + 37h (content/release) = **243-263 worker-hours**.

**With realistic parallelism** (B12.* and B13.* parallelize against extraction; docs/webpage tracks share a worker; CI bead lift shared): ~50% effective reduction → **~120-130 worker-hours**.

The plan's "40-60 worker-hour" framing in §1 reads as if it's the whole project; it is not. §11 risk #8 ("the 40-60 worker-hour effort estimate proves optimistic") implicitly addresses extraction only.

**Severity:** HIGH. Recommendation: §1 executive summary states **two** numbers explicitly: "40-60h extraction sweep, plus ~60-80h surrounding engine/installer/webpage/docs/release/content work = ~100-140 total worker-hours for v0.2." Joshua plans calendar against the total, not the sweep.

---

### F2 — B3.4 script sweep is at the upper L bound and should split (MEDIUM)

**Plan location:** §10.1 ("B3.4 sits at the upper L bound; R2 reviewed whether to split further by subcategory... and decided **no**").

**Concern:** Lane A §1.5 measured 394 scripts, 197 hardcoding `/Users/josh`, 65 naming clients, **50 named after specific tenants/clients (inherently overlay)**. The remaining 344 candidate scripts at ~30-60 seconds of codemod review each + Mode-B rewrite spot-checks on the ~200 engine-after-rewrite scripts at ~5-10 min each = 16-24 worker-hours. Plan claims 10-15h. The 50 overlay-named scripts also need explicit *exclude* manifest work that's not in the codemod (the codemod doesn't decide allowlist; classifier does, and B2 is sized M).

Plan's claim that "a single worker can sweep them in one pass" is contradicted by the per-tenant launchd plist handling (§6.3) which requires bespoke template authoring, not codemod sweeping.

**Severity:** MEDIUM. Recommendation: split B3.4 into B3.4a (codemod sweep on path-parameterizable scripts, ~8-10h) + B3.4b (per-tenant plist + recovery-install-plist-* canonical-template authoring, ~4-6h). Phase 4 DECOMPOSE absorbs this.

---

### F3 — Skillos:1 coordination protocol unspecified; B16 is S-effort but skillos turnaround is unknown (HIGH)

**Plan location:** §4.5 "Phase-2 default: defer skill substrate to v0.3"; §10.6 B16 (S, "Skillos cross-orch coordination handoff"); §9 item #12 (Joshua-decision-required).

**Concern:** B16 acceptance is "an outbound message to skillos:1 is recorded in agent-mail with topic `flywheel-skill-boundary-v0.2` and a non-null `acknowledged_at`" — that is a *send-and-ack*, not a *converged-decision*. The plan defers the actual boundary decision to v0.3, which is fine *if* skillos:1 acknowledges within the v0.2 window. But the plan provides no SLA, no timeout, no escalation path if skillos:1 is slow (memory rule: "After 2 blocker ticks, sister orch escalates to flywheel-orch /flywheel:plan"). The §4.5 "v0.2 ships zero ambient skills" decision is the *de-risking* lever — it lets v0.2 ship without skillos converging — but the plan does not state this dependency cleanly.

Additionally, several skills the plan implicitly touches (e.g., the `agentic-coding-flywheel-setup` skill mentioned in Lane A §1.4) sit in `~/.claude/skills/` namespace which has known fuzzy ownership with skillos:1.

**Severity:** HIGH. Recommendation: B16 acceptance gets a third clause: "skillos:1 acknowledgment OR 14-day deadline passed with v0.2-ships-zero-skills decision locked in CHARTER." The plan reads as if both must happen; the de-risk path is "one or the other."

---

### F4 — Per-client consent path for B11.5 case-study is hand-waved (HIGH; TRUE-blocker class: named-client-consent per memory 2026-05-11)

**Plan location:** §3 H3 kill-condition narrative; §9 item #9 Joshua-decision-required; §10.6 B11.5 (L-effort, acceptance: `grep` returns empty for client names).

**Concern:** The plan asserts the meta-case-study can be told using "**only operator-side metrics (extraction worker-hours, bead-graph counts, doctrine line totals, cross-orch incidents) with zero client name references**." But the named-client-consent meta-rule (memory 2026-05-11) explicitly says "every public surface (README/profile/repo-name/social-post) requires its own explicit client-naming consent; CLAUDE.md is internal context not publishing-consent."

The plan's H3 kill-condition test ("grep is empty after redaction") is necessary but not sufficient. *Implicit* references — "a Montana telecom client," "an insurance defense practice," "an SMB-services operator" — still leak class-of-client and may be identifiable to anyone who knows Joshua's portfolio. The plan does not specify the threshold for "consent-class" vs "operator-only-metrics-class" beyond the grep test.

Per the memory rule, *industry-only descriptions* are the safe default. The plan should make this the B11.5 acceptance criterion, not just "grep returns empty."

**Severity:** HIGH (TRUE-blocker class: any consent breach is irreversible publication). Recommendation: B11.5 acceptance gains a sub-clause: "case-study describes operator-side substrate work only; uses industry-only descriptors for any contextual client mentions (e.g., 'telecom,' 'insurance defense'); no specific geography below state level; reviewed by Joshua before B15."

---

### F5 — DCO GitHub Actions wiring not in any bead (MEDIUM)

**Plan location:** §9 item #7 "DCO (Developer Certificate of Origin)"; §10.6 B11 acceptance ("CONTRIBUTING.md contains the string `Signed-off-by`").

**Concern:** The acceptance is *file contents only*, not *enforcement mechanism*. DCO without a check is a documentation gesture — the standard pattern is the `dco-bot` GitHub App or a `dco.yaml` workflow that fails PRs missing `Signed-off-by:` trailers. Neither is specified. B11's acceptance lets B11 close green while DCO is unenforced.

**Severity:** MEDIUM. Recommendation: add B11.6 (S-effort, "Wire DCO check on PRs via `dco-bot` App OR `.github/workflows/dco.yaml`") as a sub-bead of B11.

---

### F6 — DNS + Vercel + Cloudflare Worker setup is assumed but not bead-tracked (MEDIUM)

**Plan location:** §8 webpage architecture; §10.6 B13.7 ("Webpage deploy + DNS + Cloudflare-Worker for `install.sh`", M-effort).

**Concern:** B13.7 bundles three distinct mini-projects:
1. Vercel project creation + GitHub repo wire-up
2. DNS records on whoever owns `zeststream.ai` (Joshua's directive implies he controls it; not verified in plan)
3. Cloudflare Worker for `/install.sh` proxy (or Vercel static — §2.8 of Lane C says "decide in Phase 2"; R4 does not lock this)

Plus the docs subdomain (`docs.flywheel.zeststream.ai`) requires a *fourth* DNS record + Vercel project (§9 item #3 locks subdomain).

M-effort (~6-10h) is tight for one worker covering DNS propagation waits, Vercel build config, Worker authoring + testing, and SSL cert provisioning. Real-world budget: 6-10h *plus* propagation latency, which is calendar time not worker time.

Critically: §9 item #10 says "v0.2 ships repo + webpage together" — meaning B13.7 is on the critical path to B15. Any DNS misstep blocks launch.

**Severity:** MEDIUM. Recommendation: split B13.7 into B13.7a (Vercel + DNS for primary + docs subdomain; needs Joshua's Cloudflare/registrar credentials accessible) + B13.7b (Cloudflare Worker or Vercel static for install.sh proxy; decide and implement). Pre-load Joshua-decision item: "Cloudflare Worker or Vercel static for install.sh?" before Phase 5.

---

### F7 — CI secrets provisioning unspecified (MEDIUM)

**Plan location:** §7.6 CI workflows; §10.6 B8/B9 acceptance.

**Concern:** `release.yml` performs `gh attest` (signing) — requires `GITHUB_TOKEN` with attestations permissions (default) but also any release upload tokens. The webpage's CI for docs deployment to Vercel requires `VERCEL_TOKEN` + project IDs. The Cloudflare Worker deploy (if chosen) requires `CLOUDFLARE_API_TOKEN`. None of these are mentioned. Joshua's existing Vercel infra (§8.5 Lane C) presumably has tokens, but where are they provisioned in the *public* repo's CI?

GitHub Actions secrets are not transferable from Joshua's monorepo. Each secret needs explicit configuration in the new public repo's settings.

**Severity:** MEDIUM. Recommendation: add B8.5 (S-effort, "Provision public-repo CI secrets: VERCEL_TOKEN, CLOUDFLARE_API_TOKEN if applicable, dependabot tokens; document in SECURITY.md private appendix").

---

### F8 — First-adopter recruitment for v0.2.1 is unscheduled (LOW)

**Plan location:** §9.1 ("Recruit one external adopter during the v0.2→v0.2.1 window (target: 30 days post-launch)").

**Concern:** "Target 30 days post-launch" is the only specification. No recruitment strategy (where do candidates come from?), no qualification criteria (developer-class or SMB-class? what's a viable adopter?), no consent-collection protocol (will the v0.2.1 case study require explicit per-surface consent from the recruited adopter?), no fallback if no adopter materializes by day 30.

The plan acknowledges the post-launch recruitment is "easier ask, faster yield" but provides no operational path.

**Severity:** LOW (v0.2.1, not v0.2). Recommendation: defer to Phase 5 or v0.2.1 planning; flag for `ROADMAP.md` so Joshua's not surprised at day 30.

---

### F9 — Rollback path for failed launch is implicit (MEDIUM)

**Plan location:** §5.4 ("If H3 is killed... the working extraction trees are removed and the table is updated. The source repo is untouched"); §12.3 ("If any gate is failing on launch day, B15 does not close").

**Concern:** Pre-launch rollback is well-specified (don't close B15; the source repo is preserved). **Post-launch rollback is not.** If v0.2 ships, a developer files a critical issue (e.g., the installer wipes their `~/.claude/settings.json`), what's the response?

The plan needs to specify:
- Whose pager fires? (Joshua, presumably; flywheel:1?)
- What's the SLO for "this is broken in a way that hurts adopters"?
- Is there an authority to push a `v0.2.1` patch hotfix without re-running the full plan?
- Where do issue responses live operationally? (gh-cli skill exists; not bound to a bead.)
- What's the "yank" path if a security-class issue surfaces? (Delete release? Mark deprecated? README banner?)

The CHARTER's pre-1.0 history-rewrite policy (§9 item #11) covers force-pushes but not artifact yanking.

**Severity:** MEDIUM. Recommendation: add B15.5 (S-effort, post-launch monitoring/incident-response playbook, ~2-4h to author) as part of v0.2 release acceptance. Author a `SUPPORT.md` or extend `SECURITY.md` with "if the installer breaks your environment, here's the manual rollback."

---

### F10 — Critical path is mostly serial; parallelism is asserted but not designed (MEDIUM)

**Plan location:** §10.6 ("Webpage track (B13.*) and docs track (B12.*) parallelize against B5-B11").

**Concern:** Plan claims parallelism, but the DAG shows:
- B12.* deps on **B10 + B11** (extraction end-to-end + top-level files)
- B13.* (most) deps on **B11** (top-level files); B13.4 deps on **B11.5**
- B5 deps on B4; B6 deps on B5; B7 deps on B6 (strict serial)
- B10 deps on B3.* + B4

So in practice:
- Track 1 (serial, critical path): B0 → B1 → B1.5 → B2 → B3.* (parallelizable internally) → B4 → B5 → B6 → B7 → B10 → B11
- Track 2 (parallel from B11): B12.* + B13.* + B14.5 + B11.5
- Track 3 (parallel from B6): B8, B9 (CI workflows)

At one orchestrator + 3 codex workers (Joshua's canonical fleet shape, memory 2026-05-04), the parallel tracks need ~3 simultaneous worker assignments after B11 closes. That's feasible *if* the plan's worker assignment is explicit. It is not — Phase 4 DECOMPOSE handles worker assignment.

Also: B3.1-B3.5 *internal* parallelism requires the codemod (B1.5) and classifier (B2) both ship first, plus *5 workers*. Joshua has ~3 codex panes typically.

**Severity:** MEDIUM. Recommendation: §10.6 gains an explicit parallelism diagram — "after B11 closes, 3-worker fleet covers (docs|webpage|case-study) tracks for ~3 calendar days; before B11, single critical-path serial with B3.* sub-parallelism using up to 5 workers if available, else 3 workers in 2 waves."

---

### F11 — `flywheel.zeststream.ai` ownership/registrar access not verified (LOW)

**Plan location:** §8 webpage architecture; §1 executive summary names the subdomain.

**Concern:** Plan assumes Joshua owns `zeststream.ai` and has registrar access for DNS modification. Verification path is implicit. If the registrar is locked behind 2FA Joshua can't access from his terminal, or if `zeststream.ai` is at Cloudflare but the API token doesn't have DNS:write scope, B13.7 blocks.

This is a 5-minute verification, not a real risk — but it should happen *before* B13.7 starts, not during.

**Severity:** LOW. Recommendation: add a pre-flight checklist entry: "B0 acceptance includes `dig zeststream.ai NS` succeeds and Joshua confirms DNS-modification path."

---

### F12 — Webpage copy quality bar not measured against Lane B's anti-patterns (MEDIUM)

**Plan location:** §8.4 "What does NOT go on the webpage"; §12.2 success criteria.

**Concern:** Plan says no "comprehensive," "leveraging," "cutting-edge" etc. for the README. The webpage has no equivalent banned-words list. Lane B §4's anti-patterns (vague benefit claims, "contact us for pricing," anonymous testimonials) are referenced in §8.4 but B13.* acceptance is "page exists with first-draft content" — no copy-quality gate.

The plan's "Joshua-judged" gates (§12.2) require an SMB owner usability test before launch. That's a 30-minute paid test (mentioned). Not bead-tracked.

**Severity:** MEDIUM. Recommendation: B13.* acceptance adds "passes `de-slopify` skill check + `zeststream-brand-voice` skill review before B14 closes." B17 (smoke test) adds "SMB-owner usability test scheduled or completed before B15 closes."

---

### F13 — Cross-platform smoke is Ubuntu + macOS only; no Windows/WSL verified (LOW)

**Plan location:** §7.6 (CI workflows: macos-14 + ubuntu-22.04); Lane C §6.4 ("Windows (via WSL2) is best-effort").

**Concern:** Plan defers Windows. Acceptable for v0.2. But the README probably should say so explicitly — adopters discovering this via failed install are a worse outcome than adopters reading "macOS + Linux only at v0.2; Windows WSL untested" up front.

**Severity:** LOW. Recommendation: B11's README/installation section states platform support explicitly.

---

## 3. Severity counts

| Severity | Count | Findings |
|---|---:|---|
| Critical (TRUE-blocker) | 0 | — |
| High | 3 | F1, F3, F4 |
| Medium | 7 | F2, F5, F6, F7, F9, F10, F12 |
| Low | 3 | F8, F11, F13 |
| **Total** | **13** | — |

F4 carries a TRUE-blocker class citation (named-client-consent memory 2026-05-11) but is not itself critical because the plan has *partially* anticipated it via the grep test; the finding sharpens an existing acceptance criterion rather than naming a missing one.

---

## 4. Feasibility verdict

**SHIPPABLE WITH ADJUSTMENTS.**

The plan is executable. The bead DAG is structurally correct. Acceptance criteria are observable per §10.7 (a Phase-2 strength). Risk register top-10 covers the dominant scope-creep traps. The H3 hypothesis threads Joshua's two-audience directive cleanly.

**The adjustments are six items, three of which Phase 5 polish absorbs without re-planning:**

1. **F1 (HIGH) — restate total envelope.** Executive summary §1 surfaces ~100-140 total worker-hours (not just 40-60h sweep). Joshua plans calendar against the larger number. *Adjustment lives in §1 prose; no DAG change.*

2. **F3 (HIGH) — B16 acceptance gains escape clause.** "skillos:1 ack OR 14-day deadline with zero-skills v0.2 lock" — protects v0.2 from cross-orch dependency drag. *Acceptance-criterion edit; no new bead.*

3. **F4 (HIGH) — B11.5 acceptance gains industry-only-descriptor clause.** Prevents implicit-class-leak via context. *Acceptance-criterion edit; no new bead.*

4. **F5, F7, F9 (MEDIUM) — add three small beads:** B11.6 (DCO check), B8.5 (CI secrets), B15.5 (incident playbook + SUPPORT.md). Total ~6-10 worker-hours added. *DAG grows from 33 to 36 beads.*

5. **F2, F6, F10 (MEDIUM) — split-tactical beads in Phase 4:** B3.4 → B3.4a+B3.4b; B13.7 → B13.7a+B13.7b. Parallelism diagram explicit in §10.6. *Phase 4 DECOMPOSE absorbs; no R5 needed.*

6. **F12 (MEDIUM) — webpage copy-quality gate:** Add `de-slopify` + `zeststream-brand-voice` skill review to B13.* acceptance; SMB usability test scheduled in B17. *Acceptance-criterion edits.*

The remaining findings (F8, F11, F13) are roadmap-level notes, not v0.2 blockers.

**Calendar reality:** at ~100-140 worker-hours and Joshua's stated 4-5 productive hours/day with ~3-worker fleet, v0.2 ships in **~4-6 weeks of focused calendar time** assuming no scope creep and consistent supervision. The plan's implicit ROADMAP target of "Wave 2 June 2026" (3-4 weeks) is **tight; achievable only with disciplined scope-defense** (skills deferred to v0.3 as planned; webpage at v0.2 not v0.3; no external adopter recruited pre-launch as planned).

If Joshua observes scope-creep into "let's also do skills, also recruit an adopter, also harden the docs" the realistic ship date slips to **~July-August 2026**. The plan's H4/H5 rejection rationale (§3) should be re-read at any moment Joshua feels the project ballooning — H1/H2 still exist as scope-trim fallbacks.

---

*End of 03-AUDIT-r1-feasibility.md. Hand off to Phase 3 SYNTHESIS or to a second AUDIT lens (e.g., trust-bar) before convergence.*
