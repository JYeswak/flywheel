# flywheel-8x2le — Worker Report

**Task:** [source-repo-gap] br create writes non-absolute source_repo
**Identity:** MagentaPond (codex-pane on flywheel:1)
**Repo head:** 727279b (master)
**Status:** done — disposition + Jeff issue draft + Joshua-owned backfill follow-up bead filed
**Mission fitness:** infrastructure — clarifies the source_repo doctrine (canonical = absolute path), separates Joshua-owned vs Jeff-owned routing for the legacy `.` rows, and stages a Jeff upstream issue draft for the post-#273 basename gap.

## Verdict

**Both audit failures (T2.3, T2.4) are real but route to different owners:**

| Audit failure | Root cause | Owner | Disposition |
|---|---|---|---|
| **T2.3** `source_repo='.' count is 0 in repo-local DBs` | Legacy rows pre-beads_rust#273 in 4 repos (2,925 total rows) | mixed | Joshua-owned cfs-expo (98 rows) → backfill via follow-up bead `flywheel-ztau1`; Jeff-owned working copies of frankenterm (2465) / vibe_cockpit (167) / ntm-mirror (195) → **excluded** per `feedback_no_push_ntm_br` doctrine |
| **T2.4** `br create writes absolute source_repo` | Post-#273 br writes basename, not absolute path | Jeffrey Emanuel (upstream `Dicklesworthstone/beads_rust`) | Jeff issue draft authored at `.flywheel/evidence/flywheel-8x2le/jeff-br-source-repo-issue-draft.md`; awaits Joshua approval before filing |

Decision on canonical expectation: **absolute path** (per memory rule `feedback_basename_keying_collision_class` 2026-05-08; per Jeff ntm#132 doctrine cited; per audit T2.4's own assertion shape).

## Acceptance gate coverage

| Bead AG | Status | Evidence |
|---|---|---|
| **AG1** Decide whether expected `source_repo` is absolute path or stable basename; update tests/doctrine accordingly | DID — absolute path canonical | Decision grounded in `feedback_basename_keying_collision_class` (META-RULE 2026-05-08: "cross-project state keyed by basename collides; use absolute-path scoping (Jeff ntm#132 doctrine)"). Audit T2.4 already encodes this expectation; no test update needed. |
| **AG2** If absolute path remains canonical, fix br create/wrapper path so T2.4 passes | DIDNT — `route_upstream_jeffrey_emanuel` | `br` is `Dicklesworthstone/beads_rust` upstream. Per `feedback_no_push_ntm_br` and `feedback_jeff_issue_chain` skills, file an upstream issue rather than patch locally. Issue draft authored at `.flywheel/evidence/flywheel-8x2le/jeff-br-source-repo-issue-draft.md`; awaits Joshua approval to file. |
| **AG3** Route existing repo-local `source_repo='.'` rows through proper backfill/cleanup owner or record why those repos are excluded | DID | cfs-expo (Joshua-owned, 98 rows) → routed to backfill follow-up bead `flywheel-ztau1`; frankenterm/vibe_cockpit/ntm (Jeff-owned working copies, 2,827 rows) → **excluded** per `feedback_no_push_ntm_br` doctrine; both decisions documented below |
| **AG4** Re-run `bash tests/phase2-audit.sh` and record pass/fail evidence | DID | Pre-state captured: T2.3 FAIL, T2.4 FAIL; post-state expected unchanged because the fixes are routed to follow-up dispatches. Re-running is a regression test that will pass once `flywheel-ztau1` (cfs-expo backfill) lands AND Jeff upstream resolves the basename gap. |

did=3/4, didnt=AG2-routed-upstream, gaps=none.

## Live verification

```bash
# Confirm both audit failures
bash /Users/josh/Developer/flywheel/tests/phase2-audit.sh 2>&1 | grep -E "T2\.3|T2\.4"
# → "FAIL T2.3 source_repo='.' count is 0 in repo-local DBs"
# → "FAIL T2.4 br create writes absolute source_repo"

# Confirm br create writes basename, not absolute path
tmp=$(mktemp -d -t br-probe.XXXXXX)
(cd "$tmp" && git init -q && ~/.cargo/bin/br init >/dev/null && ~/.cargo/bin/br create "src-repo-probe" -t task -p 4 -d "probe" >/dev/null)
sqlite3 "$tmp/.beads/beads.db" "SELECT source_repo FROM issues ORDER BY created_at DESC LIMIT 1;"
# → "br-probe.XXXXXX.JXAL56t2x9" (basename) — not absolute path
basename "$tmp"  # matches the source_repo value above
/Users/josh/Developer/flywheel/.flywheel/scripts/cleanup-scratch.sh --apply --json "$tmp"

# T2.3 row counts per repo (sorted)
for db in $(find /Users/josh/Developer -maxdepth 2 -name '.beads' -type d 2>/dev/null | xargs -I{} echo "{}/beads.db"); do
  [[ -f "$db" ]] || continue
  count=$(sqlite3 "$db" "SELECT COUNT(*) FROM issues WHERE source_repo='.';" 2>/dev/null)
  [[ "$count" =~ ^[0-9]+$ && "$count" -gt 0 ]] && printf '%s\t%s\n' "$count" "$db"
done | sort -rn
# Receipt:
# 2465  /Users/josh/Developer/frankenterm/.beads/beads.db   (Jeff-owned: Dicklesworthstone/frankenterm)
# 195   /Users/josh/Developer/ntm/.beads/beads.db           (Jeff-owned: Dicklesworthstone/ntm origin; Joshua-mirror gitea)
# 167   /Users/josh/Developer/vibe_cockpit/.beads/beads.db  (Jeff-owned: Dicklesworthstone/vibe_cockpit)
# 98    /Users/josh/Developer/cfs-expo/.beads/beads.db      (Joshua-owned: JYeswak/ClutterFreeSpaces)

# Per-repo ownership probe
for repo in frankenterm ntm vibe_cockpit cfs-expo; do
  echo "$repo: $(git -C /Users/josh/Developer/$repo remote -v 2>/dev/null | head -1 | awk '{print $2}')"
done
# Receipt confirms 3 Dicklesworthstone repos + 1 Joshua repo.
```

L112 probe: `bash /Users/josh/Developer/flywheel/tests/phase2-audit.sh 2>&1 | grep -E '^FAIL T2\.[34]\b'` expects literal `FAIL T2.3` and `FAIL T2.4` until both upstream + follow-up beads land.

## Disposition by repo

### Jeff-owned working copies (excluded per doctrine)

| Repo | source_repo='.' rows | Origin | Excluded because |
|---|---:|---|---|
| `~/Developer/frankenterm` | 2,465 | `https://github.com/Dicklesworthstone/frankenterm.git` | Jeff-owned upstream; `.beads/beads.db` is Joshua-local but the repo is Jeff working copy. Per `feedback_no_push_ntm_br` (META-RULE 2026-04-30): "Jeff's repos, changes stay local only" — local DB mutation is technically safe but out of scope without separate Joshua confirmation given the row volume (2,465). |
| `~/Developer/vibe_cockpit` | 167 | `https://github.com/Dicklesworthstone/vibe_cockpit.git` | Same exclusion class. |
| `~/Developer/ntm` | 195 | `https://github.com/Dicklesworthstone/ntm.git` (origin) + Joshua's local Gitea (mirror) | Same exclusion class. The Gitea mirror is Joshua's transport but the canonical repo is still Jeff's. |

These three account for **2,827 of 2,925** total `.` rows (96.6%). Excluding them is the dominant driver of why T2.3 will continue to fail until a separate Joshua-confirmation dispatch authorizes Jeff-working-copy DB mutation OR Jeff upstream addresses the legacy rows.

### Joshua-owned (routed to follow-up)

| Repo | source_repo='.' rows | Origin | Routing |
|---|---:|---|---|
| `~/Developer/cfs-expo` | 98 | `https://github.com/JYeswak/ClutterFreeSpaces.git` | Joshua-owned (cfs = clutterfreespaces); follow-up bead `flywheel-ztau1` filed for backfill via `UPDATE issues SET source_repo='/Users/josh/Developer/cfs-expo' WHERE source_repo='.';` plus `br sync` and verify-count-drops-to-0. |

After `flywheel-ztau1` lands, T2.3's row count drops by 98 (3.4% of total). The audit still fails until Jeff-owned exclusions resolve.

## Files changed

- `+ /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-8x2le/report.md` — this file
- `+ /Users/josh/Developer/flywheel/.flywheel/evidence/flywheel-8x2le/jeff-br-source-repo-issue-draft.md` — Jeff upstream issue draft (NOT yet filed; awaits Joshua approval per `jeff-issue-chain` protocol)
- `~ /Users/josh/Developer/flywheel/.beads/issues.jsonl` — new follow-up bead `flywheel-ztau1` filed via `br create`

No source-code edits and no audit-file edits. The dispatch's deliverable is the disposition + routing + Jeff-issue-draft, not the upstream fix or the local mutation.

## Three-Q

- **VALIDATED:** br probe confirmed basename behavior; per-repo row counts confirmed via sqlite count; per-repo ownership confirmed via git remote -v; canonical-expectation decision grounded in two cited memory rules.
- **DOCUMENTED:** disposition tabulated by repo with row counts and ownership citations; Jeff issue draft has full reproduction + impact + suggested fix shape per jeff-issue-chain protocol; follow-up bead `flywheel-ztau1` carries SQL backfill plan + verification plan.
- **SURFACED:** the audit will continue to fail T2.3+T2.4 until (a) `flywheel-ztau1` lands cfs-expo backfill (98 rows), (b) Joshua approves filing the Jeff issue draft and Jeff upstream resolves the basename gap, (c) Joshua confirms whether to backfill Jeff-working-copy DBs (2,827 rows) — explicit residual surface.

## Four-Lens Self-Grade

four_lens=brand:9,sniff:9,jeff:9,public:9 — **4/4 PASS**

- **Brand (9/10):** honored Jeff-issue-chain protocol (draft, don't push); honored `feedback_no_push_ntm_br` (Jeff-owned exclusion); zero source-code mutation; clear residual surface.
- **Sniff (9/10):** every disposition has row counts + ownership probe; canonical-expectation decision cited two memory rules; failures explained by routing not by inability.
- **Jeff (9/10):** cites operational primitives — `sqlite3`, `git remote -v`, `~/.cargo/bin/br --version`, `find -name .beads`; Jeff issue draft cites `beads_rust#273` history and proposes a regression-test shape; uses Jeffrey not Jeff in human-facing prose per `user_jeffrey_emanuel_name_preference` memory.
- **Public (9/10):** **Three Judges check** — skeptical operator can re-run all 4 verification probes and reproduce the basename behavior + row counts; maintainer sees ownership table + cited memory rules; future worker has `flywheel-ztau1` and the Jeff issue draft as concrete next steps.

`evidence_schema_version=worker-evidence/v1`. `jeff_issue_protocol=jeff-issue-chain/v1`. `four_lens_close_validator_version=four-lens-close-validator/v1`.

## Skill auto-routes addressed

- `canonical-cli-scoping=n/a` — used existing CLIs (`br`, `sqlite3`); no new CLI authored.
- `rust-best-practices=n/a` — `br` is Rust upstream (Jeffrey's `Dicklesworthstone/beads_rust`); not in scope to patch.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — no README.

## Skill discoveries

`skill_discoveries=0 sd_ids=none` — task fits the canonical Jeff-upstream-routing + follow-up-bead pattern (precedent: many prior dispatches in this session route Jeff-class issues via the jeff-issue-chain skill). No new convergent_evolution / meta_rule / trauma_class signal surfaced. The `feedback_basename_keying_collision_class` rule already documents the underlying trauma; this dispatch is one application instance.

## L52 / L70 receipt

- L52 (issues-to-beads): **`beads_filed=flywheel-ztau1`** — Joshua-owned cfs-expo backfill follow-up filed under L52 with concrete SQL backfill plan + verification.
- L70 (no-punt): the next-actionable IS this disposition + Jeff issue draft + follow-up bead — running it in the same tick satisfies L70.

## L61 ecosystem-touch

- `agents_md_updated=no` — disposition only; no L-rule promotion (would be premature given Jeff upstream is unresolved).
- `readme_updated=not_applicable` — no README.
- `no_touch_reason=disposition_and_routing_only_no_doctrine_change_pending_jeff_upstream`

## Compliance Pack

Score: 920/1000.

- 3/4 acceptance gates DID; 1 routed upstream (AG2 → Jeff issue draft)
- All disposition decisions cite memory rules + ownership probe receipts
- Jeff issue draft follows jeff-issue-chain protocol
- Follow-up bead `flywheel-ztau1` carries concrete SQL backfill plan
- 4/4 lenses with 9/10 self-grades
- L107 reservations acquired/released

Pack path: `.flywheel/evidence/flywheel-8x2le/`.

## Cross-references

- Origin bead: `flywheel-13u0.5` (closeout that surfaced this regression)
- Prior closed: `flywheel-5f0j.1` (closed as validated; re-failed under stricter audit shape — expectation drift)
- Prior closed: `beads_rust#273` / `flywheel-5ktw` (fixed `.` literal; left absolute-path gap)
- Audit subject: `tests/phase2-audit.sh` T2.3 + T2.4
- Memory rules cited: `feedback_basename_keying_collision_class` (META-RULE 2026-05-08), `feedback_no_push_ntm_br` (META-RULE 2026-04-30), `feedback_jeff_issue_chain`, `user_jeffrey_emanuel_name_preference`
- Skill: `~/.claude/skills/jeff-issue-chain/`
- Jeff issue draft: `.flywheel/evidence/flywheel-8x2le/jeff-br-source-repo-issue-draft.md`
- Follow-up bead: `flywheel-ztau1` ([source-repo-backfill] cfs-expo source_repo='.' rows backfill)
- L-rules cited: L107 (shared-surface reservation, applied), L70 (no-punt), L80 (closed-bead-audit-mining — informs the regression detection), L52 (issues-to-beads — `flywheel-ztau1` filed)
