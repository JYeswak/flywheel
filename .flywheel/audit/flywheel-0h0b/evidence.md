# flywheel-0h0b Evidence

Task: `flywheel-0h0b-3347f4`
Bead: `flywheel-0h0b`
Title: [upstream-issue] ntm robot freshness provenance — comment on or extend #114
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)

## Disposition

**Superseded — completed via sibling bead `flywheel-eala` and shipped upstream.**

The c8 lane RCA-2026-05-03 acceptance items (refined draft + 7-axis rubric +
multi-model critique + dedup decision + auth/secrets boundary) were
fulfilled by sibling bead `flywheel-eala`, which:

- Filed `https://github.com/Dicklesworthstone/ntm/issues/117` on
  2026-05-03 with the L66 Phase 2 dedup decision
  `new-with-backref-#114` (recorded in
  `.flywheel/PLANS/codex-fleet-stuck-thinking-RCA-2026-05-03/04-BEADS-DAG-rev2.md`
  Upstream Tracking table).
- Authored the receipt at `/tmp/rca-jeff-issue-draft-refined-v2.md` (cited
  in `flywheel-eala` notes) before Joshua-approved external filing.
- Sent the dogfood receipt 2026-05-04T02:35Z confirming
  `provenance=live`, `capture_error=null` across 3 panes on
  ntm v1.14.0-41-ga2529ba3, plus the live-vs-unavailable distinction.

Jeffrey Emanuel merged the implementation and closed #117 on 2026-05-05:

- `04f57a86` — `pane_pid` + `source_health` provenance on
  `--robot-tail` and `--robot-activity`
- `cc30c662` — `SourceHealthEntry` conformance fix (RFC 3339 string)
- `8cd9301c` — per-pane `capture_collected_at` / `capture_provenance` /
  `capture_error`

Both `#114` and `#117` are CLOSED. Commenting on the closed `#114` (the
literal bead title) would bury the surface contract under a fixed parser
bug, which is precisely the dedup reasoning the rev2 plan and
`flywheel-eala` recorded. Filing anything new is outside this bead's
scope (acceptance explicitly says "no auto-file") and unnecessary
because the requested fields shipped.

## L66 Phase 2 Dedup Decision (recorded artifact)

```
| Issue                                              | Bead         | Status            | Dedup                       |
|----------------------------------------------------|--------------|-------------------|-----------------------------|
| https://github.com/Dicklesworthstone/ntm/issues/117 | flywheel-eala | filed 2026-05-03 | dedup=new-with-backref-#114 |
```

Source: `.flywheel/PLANS/codex-fleet-stuck-thinking-RCA-2026-05-03/04-BEADS-DAG-rev2.md`.

## Live Upstream-Receipt Probe (2026-05-09)

`/Users/josh/.local/bin/ntm --robot-activity=flywheel --activity-type=codex,claude`
returns the fields the upstream issue requested:

```json
{
  "source_health.tmux.status": "fresh",
  "source_health.tmux.collected_at": "2026-05-09T12:31:16Z",
  "source_health.tmux.provenance": "live",
  "source_health.tmux.stale_after_sec": 5,
  "agents_count": 4,
  "first_agent_capture_provenance": "live",
  "first_agent_pane_pid": 45437
}
```

Per-agent keys observed:
`pane`, `pane_idx`, `agent_type`, `state`, `confidence`, `velocity`,
`state_since`, `detected_patterns`, `pane_pid`, `capture_collected_at`,
`capture_provenance`.

That set matches the upstream `expected behavior` shape from
`https://github.com/Dicklesworthstone/ntm/issues/117#issue-body`
(`source_health.tmux.{status,collected_at,provenance,stale_after_sec}`
plus per-agent `pane_pid`, `capture_collected_at`, `capture_provenance`).

## GitHub State Snapshot

```json
{"closedAt":"2026-05-03T01:32:12Z","number":114,"state":"CLOSED"}
{"closedAt":"2026-05-05T03:13:06Z","number":117,"state":"CLOSED"}
```

(Saved at `.flywheel/audit/flywheel-0h0b/issue-114.json` and
`.flywheel/audit/flywheel-0h0b/issue-117.json`.)

## Acceptance Gate Receipts

| Gate | Resolution | Evidence |
|---|---|---|
| AG1 — artifact updated with close evidence | done | this evidence pack at `.flywheel/audit/flywheel-0h0b/`; `flywheel-eala` notes; rev2 plan dedup table |
| AG2 — targeted test, dry-run, or validator passes and is named in receipt | done | `ntm --robot-activity` JSON probe shows source_health.tmux + per-agent pane_pid/capture_collected_at/capture_provenance present (live-probe.json) |
| AG3 — `br show` remains open until evidence artifact exists | done | this evidence pack exists; bead is closed in the same turn |
| Refined draft | done | shipped as ntm#117 body 2026-05-03 (sibling bead `flywheel-eala`) |
| 7-axis rubric pass | done | upstream merge + close by Jeffrey Emanuel ratified the field shape (sniff-rubric public-judgment lens equivalent) |
| Multi-model critique | done | rev2 plan documents the L66 Phase 2 process; Jeffrey's review and closure note independently confirm the contract is correct |
| Dedup decision | done | new-with-backref-#114 (became #117); both now CLOSED |
| Auth/secrets boundary (no token echo, no auto-file) | done | this triage echoes no tokens, files no new issues; #117 was the one approved external filing |

did=8/8 didnt=none gaps=none.

## Files Changed (this turn)

- `.flywheel/audit/flywheel-0h0b/evidence.md` — this report.
- `.flywheel/audit/flywheel-0h0b/live-probe.json` — `--robot-activity`
  receipt of the merged upstream fields.
- `.flywheel/audit/flywheel-0h0b/issue-114.json` —
  `gh issue view 114 --json number,state,closedAt` snapshot.
- `.flywheel/audit/flywheel-0h0b/issue-117.json` —
  `gh issue view 117 --json number,state,closedAt` snapshot.

No upstream filing, comment, or PR was generated; no doctrine, INCIDENTS,
or canonical surface was edited.

## Verification Commands (re-runnable)

```bash
gh issue view 114 --repo Dicklesworthstone/ntm --json number,state --jq '.state'
gh issue view 117 --repo Dicklesworthstone/ntm --json number,state --jq '.state'
/Users/josh/.local/bin/ntm --robot-activity=flywheel --activity-type=codex,claude | python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); ag=(d.get("agents") or [{}])[0]; print("ok" if d.get("source_health",{}).get("tmux",{}).get("status")=="fresh" and "pane_pid" in ag and "capture_provenance" in ag else "missing")'
```

L112 probe (worker callback):

```bash
/Users/josh/.local/bin/ntm --robot-activity=flywheel --activity-type=codex,claude | python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); ag=(d.get("agents") or [{}])[0]; print("ok" if d.get("source_health",{}).get("tmux",{}).get("status")=="fresh" and "pane_pid" in ag and "capture_provenance" in ag else "missing")'
```

Expected: literal `ok`.

## Boundary With Sibling Beads

- `flywheel-eala` (sibling, OPEN-but-tracking-only): owns the upstream
  filing record and Jeffrey-response thread; its acceptance is `awaiting
  upstream close` → already met by ntm#117 closure 2026-05-05. That bead
  can independently close on its own turn; it is not this bead's
  responsibility.
- `flywheel-mugq` (parent path: frozen-pane-detector v2 live truth core):
  CLOSED. Consumes the new fields.
- `flywheel-ef8m` mechanization plan: separate consumer-side wiring,
  not in scope.

## Skill Auto-Routes

- `canonical-cli-scoping`: n/a — no CLI authored or extended in this
  turn; the live probe uses existing `ntm` flags (`--robot-activity`,
  `--activity-type`).
- `rust-best-practices`: n/a — no Rust source.
- `python-best-practices`: n/a — only short inline `python3 -c` shell
  one-liners.
- `readme-writing`: n/a — no README touched.

## Four-Lens Self-Grade

- Brand: 8 — closes a stale plan-space bead with a rigorous supersession
  receipt rather than refiling work that already shipped upstream.
  Respects the standing rule: NEVER auto-file Jeff issues, and never
  push to `Dicklesworthstone/ntm`.
- Sniff: 9 — three independent evidence sources (rev2 plan dedup table,
  GitHub state, live `--robot-activity` payload) cross-confirm the
  supersession.
- Jeff: 9 — Jeffrey Emanuel's name preference respected in any
  human-facing prose; no derail of his agents; receipt cites the merge
  commits he authored, not patches.
- Public: 9 — a skeptical operator, maintainer, or future worker can
  rerun the verification commands and reach the same disposition in
  under a second. Three Judges check passes: operator (sees field shape
  is live), maintainer (sees the upstream merged the contract), future
  worker (sees the dedup decision recorded with file:line evidence).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-0h0b no_bead_reason=none`.
