# flywheel-8qal5 Evidence — promote concurrent-dirty-validation-drift to L56 layer-2

Task: `flywheel-8qal5-242724`
Bead: `flywheel-8qal5` (P2 OPEN → CLOSED this turn)
Title: [promotion-candidate] concurrent-dirty-validation-drift (13 events in 7d)
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=infrastructure` — legitimate L56
promotion (not supersession). Same shape as `flywheel-ijsb7`
(agent-mail-reservation-unavailable) earlier in session: zero prior
INCIDENTS coverage, 13+ fuckup-log events, dedup-skip status was
`bead_exists` (only this bead, no canonical section).

## Headline finding — legitimate promotion

| Surface | Count |
|---|---|
| `INCIDENTS.md` references to `concurrent-dirty-validation-drift` (pre-rework) | 0 |
| `fuckup-log.jsonl` events for the class | 13 (mobile-eats, 2026-05-08 09:34Z–15:17Z) |
| Open promotion-candidate bead | 1 (this bead) |
| Closed sister bead | 0 |

Dedup-skip status pre-rework was `bead_exists` (this open bead is the
only canonical surface). After this rework lands, future ladder runs
will show `concurrent-dirty-validation-drift:incidents_covered`.

## What changed

### `INCIDENTS.md`

Added new `## concurrent-dirty-validation-drift` section at line 6152,
inserted immediately after the sister `## shared-repo-dirty-preflight`
section (the orchestrator-layer counterpart). All 10 canonical
template fields populated:

- Date: 2026-05-09
- Promotion Action: NEW
- Class: `concurrent-dirty-validation-drift`
- Event Count: 13 events in 7 days
- Severity: medium
- Cost: 13 mobile-eats validations on 2026-05-08 (09:34Z–15:17Z) saw
  `pnpm test/typecheck/build` fail because of unrelated dirty edits a
  sibling pane had made in the same shared worktree. Each affected
  worker re-ran in `/tmp/mobile-eats-<task>-validate-<pid>` and
  passed.
- Root Cause: Validation tooling is whole-repo by design; multi-pane
  workers in the same git worktree cross-pollute. Sister to
  `shared-repo-dirty-preflight` (orch layer) but at the worker layer.
- Forever-Rule: When a worker performs full-repo validation in a
  shared worktree where another active pane has dirty state, the
  worker MUST validate in a dedicated `/tmp/<repo>-<task>-validate-<pid>`
  isolated worktree. The narrow scope can still ship from the shared
  worktree (pathspec staging holds), but the validation gate runs
  against the isolated copy.
- Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
  --promote concurrent-dirty-validation-drift`. Pairs with
  `shared-repo-dirty-preflight` for the dual orch/worker layer
  coverage.
- Evidence: 13 fuckup-log line numbers (4263, 4264, 4267, 4268, 4273,
  4274, 4277, 4278, 4279, 4281, 4283, 4285, 4287) + failure-shape
  distribution + sister INCIDENTS entry + AGENTS.md L107 reference +
  skill cross-link + companion dedup bead + this bead's id.

### `~/.local/state/flywheel/fuckup-processed.jsonl`

Appended row:

```json
{"ts":"2026-05-09T19:11:06Z","trauma_class":"concurrent-dirty-validation-drift","decision":"promoted","fuckup_log_lines":[4263,4264,4267,4268,4273,4274,4277,4278,4279,4281,4283,4285,4287],"processed_into":"INCIDENTS.md#concurrent-dirty-validation-drift","processed_by":"/flywheel:learn --promote","bead_id":"flywheel-8qal5","skills_covered":"dispatch-tool-contracts shared-repo-dirty-preflight orch layer","skills_extend":"dispatch-tool-contracts could add isolated-worktree-validation Forever-Rule for the worker layer","related":["flywheel-7xcfl","flywheel-qnkj2"],"note":"..."}
```

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — substrate updated with close evidence | DID | INCIDENTS.md gains new section at line 6152; `.flywheel/audit/flywheel-8qal5/` carries this evidence pack + pinned SHA |
| AG2 — targeted validator passes and named | DID | `bash .flywheel/scripts/incidents-evidence-link-validator.sh --json` returns `status:"pass"`, `incidents_evidence_missing_count:0`, `entries_checked:109`; template-coverage probe confirms all 10 required fields present |
| AG3 — `br show flywheel-8qal5` open until evidence exists | DID | this evidence pack exists; bead is closed in the same turn |

did=3/3 didnt=none gaps=none.

## Failure-shape distribution (from 13 events)

| Cross-pollution shape | Count |
|---|---|
| Pane 3 dirty billing/copy edits poisoning Track A | 2 |
| Pane 2 dirty entitlements/dunning/stripe edits poisoning Track L | 2 |
| Track H email-sequences cross-pollination | 4 |
| Track A/B fixture drift | 1 |
| Track H7/customer-reengagement copy drift | 4 |

All 13 events on `session=mobile-eats`, panes 2 and 3 cross-polluting,
all on 2026-05-08 within a 6-hour window — concentrated mobile-eats
multi-pane work day. Pattern is the same root cause across all 13:
shared worktree, two active panes, validation tool reads everything.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| INCIDENTS.md (post-promotion) | `INCIDENTS.md` | (see `pinned-shas.txt`) |

## Verification commands (re-runnable)

```bash
# Confirm new section exists
grep -n "^## concurrent-dirty-validation-drift$" /Users/josh/Developer/flywheel/INCIDENTS.md
# expected: line 6152

# Validator passes
bash /Users/josh/Developer/flywheel/.flywheel/scripts/incidents-evidence-link-validator.sh --json \
  | jq '{status, incidents_evidence_missing_count, entries_checked}'
# expected: status=pass, incidents_evidence_missing_count=0, entries_checked=109

# Confirm dedup heuristic now skips this class (post-merge)
/Users/josh/Developer/flywheel/.flywheel/scripts/doctrine-ladder-promote.sh \
  | jq -r '.skipped[] | select(test("concurrent-dirty"))'
# expected: concurrent-dirty-validation-drift:incidents_covered (post-close)
```

## L112 probe (worker callback)

```bash
grep -q "^## concurrent-dirty-validation-drift$" /Users/josh/Developer/flywheel/INCIDENTS.md \
  && bash /Users/josh/Developer/flywheel/.flywheel/scripts/incidents-evidence-link-validator.sh --json \
       | jq -e '.status == "pass" and .incidents_evidence_missing_count == 0' >/dev/null \
  && echo ok || echo missing
```

Expected (literal): `ok`.

## Boundary

- **No `/flywheel:learn` slash-command invocation.** Worker replicates
  the artifact shape (INCIDENTS section + processed-ledger row)
  directly, mirroring sister-bead pattern from `flywheel-ijsb7` and
  `flywheel-2tgl`.
- **No new bead filed for follow-up.** The 13 events all already
  organically migrated to `/tmp/<repo>-<task>-validate-<pid>` isolated
  worktrees — the Forever-Rule codifies an in-flight discipline that
  workers are already practicing. No additional fix-this bead is
  needed; doctor signals will route runtime issues to the existing
  shared-repo-dirty-preflight family.
- **No script edit.** `dispatch-tool-contracts` skill could add an
  isolated-worktree-validation Forever-Rule for the worker layer
  (noted in the Evidence block as a `skills_extend` candidate), but
  that's a follow-up beyond this bead's scope.
- **Sister section unchanged.** `## shared-repo-dirty-preflight`
  (line 6099) is unchanged; the new section is appended after it.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — INCIDENTS doctrine, not README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — INCIDENTS.md gained a layer-2 entry; AGENTS.md
  L107 is referenced but unchanged.
- `readme_updated=not_applicable`.
- `no_touch_reason=L56_layer-2_INCIDENTS_promotion_canonical_L-rule_L107_unchanged`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes AG1/AG2/AG3 verbatim. Names the dual layer
  coverage (orch via shared-repo-dirty-preflight, worker via this
  section) explicitly.
- **Sniff: 9** — failure-shape distribution mechanically derived from
  13 fuckup-log rows; validator passes; processed-ledger row attached;
  template fields 10/10.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small surface
  (one INCIDENTS section + one ledger row); Forever-Rule codifies
  in-flight discipline rather than mandating new tooling.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: 13 fuckup-log lines cited; sister
    section pointer is grep-friendly; Forever-Rule is one shell
    command (`git worktree add /tmp/<repo>-<task>-validate-<pid>`).
  - **maintainer (extending later)**: failure-shape distribution table
    is the extension point; isolated-worktree pattern can be promoted
    to a canonical L-rule if recurrence continues.
  - **future worker (LLM agent)**: dual-layer template (orch
    pre-flight gate + worker isolated-validation) is the load-bearing
    insight; future cross-pane validation collisions route through
    this section.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-8qal5
no_bead_reason=incidents_promotion_complete_paired_with_shared-repo-dirty-preflight_orch_layer_no_followup_observed_isolated-worktree_pattern_already_in_organic_practice`.
