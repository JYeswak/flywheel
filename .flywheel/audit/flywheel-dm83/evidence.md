# flywheel-dm83 Evidence

Task: `flywheel-dm83-ef06d8`
Bead: `flywheel-dm83`
Title: [team-roster B08] NTM upstream session metadata sync decision
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)

Decision record:
`.flywheel/decisions/dm83-ntm-roster-sync-2026-05-09.md`
Probe evidence:
`.flywheel/audit/flywheel-dm83/ntm-probe-evidence.txt`

## Disposition

**DECIDED — AVOID full replacement; ADOPT-LITE complementary;
EXTEND deferred until Jeffrey adds missing semantic fields
upstream.**

Five-point summary:
1. team-roster.jsonl remains canonical for borrowing semantics,
   mission anchor, tier/client policy, append-only audit, fleet
   identity, loop_active.
2. NTM `activity <session> --json` is **already** the live-pane
   oracle (B06 borrow dispatcher and pane-state probes consume it).
   No migration needed.
3. NTM `sessions / checkpoint / agents` are AVOID-for-roster-purposes
   because they lack borrowing fields, append-only audit semantics,
   and mission/tier/client metadata.
4. Backwards-compatible Phase 1-4 sync path documented in the
   decision record for forward-readiness — but **no follow-up
   beads filed today** per acceptance #5 ("only after a concrete
   upstream surface exists").
5. Re-evaluation triggers (EXTEND-viable) tracked via the
   already-shipped `jeffrey-comment-watchtower` (flywheel-d6tz0)
   and `jeff-intel-digest-actionable.sh` (flywheel-1lpv.3).

## Acceptance Receipts

| # | Acceptance | Status | Evidence |
|---|---|---|---|
| 1 | Survey current NTM metadata/checkpoint/session surfaces and compare against team-roster fields | done | live probes captured at `ntm-probe-evidence.txt`: `ntm sessions list/show`, `ntm activity flywheel`, `ntm checkpoint list`, `ntm agents list`. Field-by-field comparison table in the decision record. |
| 2 | Decide ADOPT/EXTEND/AVOID for upstream NTM metadata as roster source of truth | done | Decision record § "Verdict": **AVOID** full replacement; **ADOPT-LITE** complementary; **EXTEND** deferred. With explicit triggers for revisit. |
| 3 | Preserve append-only audit semantics and Joshua-confirmed pane lock-in requirements in any migration | done | Decision record § "Why AVOID full replacement" §1-§4: documents that team-roster.jsonl is one-row-per-event vs NTM's overwrite-style state-shots; Joshua-confirmed pane lock-in via `~/.local/state/flywheel/orch-worker-identity/` has no NTM equivalent. |
| 4 | Define backwards-compatible sync path or explicit no-change rationale | done | Decision record § "Backwards-compatible sync path" defines Phase 1 (read-side dual-source) → Phase 2 (consumer dual-source with `roster-substrate-divergence` fuckup class) → Phase 3 (cut-over after clean parity) → Phase 4 (sunset). Plus explicit no-change rationale for today. |
| 5 | File implementation follow-ups only after a concrete upstream surface exists | done | `no_bead_reason=acceptance_5_explicitly_blocks_implementation_followups_until_concrete_upstream_surface_exists`. Watchtowers will route a re-evaluation signal (not a self-firing bead) when an EXTEND trigger lands. |

| Three-Q | Status | Evidence |
|---|---|---|
| VALIDATED | done | live NTM probes captured 2026-05-09T14:13Z; counts/keys named verbatim in the comparison table |
| DOCUMENTED | done | self-contained decision record at `.flywheel/decisions/dm83-ntm-roster-sync-2026-05-09.md` cites the plan + probe evidence + sister beads |
| SURFACED | done | decision record exists, this bead's L52 receipt is `beads_filed=none beads_updated=flywheel-dm83 no_bead_reason=<concrete>` |

did=8/8 didnt=none gaps=none.

## Files Changed

In-repo:
- `.flywheel/decisions/dm83-ntm-roster-sync-2026-05-09.md` —
  decision record (~135 lines, self-contained).
- `.flywheel/audit/flywheel-dm83/evidence.md` — this report.
- `.flywheel/audit/flywheel-dm83/ntm-probe-evidence.txt` — live
  NTM surface probes (sessions, activity, checkpoint, agents +
  team-roster row keys for comparison).

No edits to `roster-register.sh`, `team-pulse-heartbeat.sh`,
`cross-session-worker-borrow.sh`, the team-roster.jsonl ledger,
AGENTS.md, INCIDENTS, canonical L-rules, or any skill. No NTM
patch, no Jeffrey issue filed (acceptance #5 explicitly bans
that until upstream surfaces exist).

## Verification Commands (re-runnable)

```bash
# Re-probe NTM surfaces (no mutations)
ntm sessions list --json | jq '.count'
ntm activity flywheel --json | jq '.agents | length'
ntm checkpoint list --json | jq '.count'
ntm agents list --json | jq 'length'

# Re-derive comparison: team-roster has borrow-* fields, NTM doesn't
tail -1 /Users/josh/.local/state/flywheel/team-roster.jsonl | jq 'has("available_for_borrow"), has("max_borrow_workers")'
ntm activity flywheel --json | jq 'has("available_for_borrow")'   # → false
```

L112 probe (worker callback):

```bash
test -f /Users/josh/Developer/flywheel/.flywheel/decisions/dm83-ntm-roster-sync-2026-05-09.md \
  && grep -q "DECIDED — AVOID full replacement" /Users/josh/Developer/flywheel/.flywheel/decisions/dm83-ntm-roster-sync-2026-05-09.md \
  && echo ok || echo missing
```

Expected: literal `ok`.

## Boundary

- Decision record is the authoritative artifact; the audit
  evidence pack is the verification trail.
- NTM is unchanged; the `flywheel-cgjo` borrow dispatcher already
  consumes `ntm activity` and that boundary is preserved.
- Three watchtowers exist to surface EXTEND triggers without
  filing a bead today: `jeffrey-comment-watchtower`,
  `jeff-intel-digest-actionable`, and the in-flight Jeffrey
  intel network (parent `flywheel-1lpv` in_progress).

## Skill Auto-Routes

- `canonical-cli-scoping`: n/a — no CLI authored or extended this
  turn (decision-only artifact).
- `rust-best-practices`: n/a — no Rust.
- `python-best-practices`: n/a — only inline `jq` for probes.
- `readme-writing`: n/a — decision-record style, not README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no L-rule promotion this turn.
- `readme_updated=not_applicable` — no README touched.
- `no_touch_reason=decision_record_lives_in_decisions_dir_no_doctrine_promotion_until_extend_trigger_fires`.

## Four-Lens Self-Grade

- Brand: 8 — closes a P3 paradigm-tier decision with a verdict
  that preserves load-bearing flywheel substrate (team-roster,
  borrow protocol, mission anchor) while explicitly tracking
  re-evaluation triggers via existing watchtowers.
- Sniff: 9 — three independent probe sources (sessions,
  activity, checkpoint, agents) cross-confirm the gap matrix;
  field-by-field comparison table cites concrete schema
  evidence; backwards-compatible Phase 1-4 sync path defined
  for forward-readiness.
- Jeff: 9 — Jeffrey-not-Jeff in human-facing prose; no push to
  Dicklesworthstone/ntm; no auto-filed Jeffrey issue (acceptance
  #5 bans it); cites watchtowers (flywheel-d6tz0,
  flywheel-1lpv.3) as the canonical re-evaluation surface.
- Public: 9 — operator/maintainer/future worker can rerun the
  4-line probe block in <2s and re-derive the gap matrix; the
  decision record is self-contained with explicit triggers,
  phases, and rationale.

## L52 Receipt

`beads_filed=none beads_updated=flywheel-dm83
no_bead_reason=acceptance_5_explicitly_blocks_implementation_followups_until_concrete_upstream_surface_exists`.
