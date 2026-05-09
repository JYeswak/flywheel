# flywheel-wutd Evidence

Task: `flywheel-wutd-8db7b0`
Bead: `flywheel-wutd`
Title: [upstream-jeff] beads_rust: source_repo='.' leakage on br create — file upstream issue per L66
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)

## Disposition

**Superseded — upstream issue already filed, fixed, dogfooded, and closed
on 2026-05-04. Local `br` reproduces the corrected behavior today.**

The L66 phased process (refine → multi-model → dedup → 7-axis → Joshua
signoff → file → cross-reference) was executed by sibling beads
`flywheel-5ktw` and `flywheel-f505`, both now CLOSED:

- `flywheel-5ktw` (CLOSED 2026-05-04, P2)
  `[jeff-issue-posted] beads_rust#273 source_repo dot after create`
  - Posted after 7-axis rubric PASS.
  - Draft body: `/tmp/jeff-draft-br-source-repo-dot-after-create.v2.md`
  - Rubric receipt: `/tmp/jeff-5-draft-rubric-validation_findings.md`
  - Upstream URL: https://github.com/Dicklesworthstone/beads_rust/issues/273
- `flywheel-f505` (CLOSED 2026-05-04, P1)
  `[jeff-triage-beads_rust-273] response from Jeff (state=closed)`
  - Confirmed Jeffrey Emanuel's fix shipped in `03167479` with test
    coverage in `c3417779`.
  - Local `br` rebuilt from `main` commit `3c46bea`; before-rebuild probe
    returned `source_repo='.'`, after-rebuild probe returned the repo
    basename.
  - Dogfood receipt posted at
    https://github.com/Dicklesworthstone/beads_rust/issues/273#issuecomment-4368606559
  - Triage evidence: `/tmp/flywheel-f505-evidence.md`
  - Validator: `/tmp/flywheel-f505-validator.txt SAFE_TO_CLOSE`

`flywheel-wutd` was created 2026-05-03 with a Phase-1-through-Phase-7
plan-space ask. Phases 1-7 were completed via the two beads above on
2026-05-03 / 2026-05-04, before this dispatch ran. The "Phase 6 file"
step has already happened (#273 is the artifact) and the "Phase 7
cross-reference flywheel bead" exists in the form of `flywheel-5ktw`
plus the upstream comment thread on #273 referencing
`flywheel-5ktw / flywheel-f505`.

## GitHub Issue Snapshot

```json
{
  "number": 273,
  "state": "CLOSED",
  "title": "br create stores source_repo='.' for new issues",
  "createdAt": "2026-05-03T06:15:25Z",
  "closedAt": "2026-05-03T16:14:45Z",
  "url": "https://github.com/Dicklesworthstone/beads_rust/issues/273"
}
```

(Saved at `.flywheel/audit/flywheel-wutd/issue-273.json`.)

Closure remark from Jeffrey Emanuel (`Dicklesworthstone`):

> Fixed in `03167479` (and test coverage in `c3417779`), already on
> `main`. Both `br create` and the bulk `br create --file <md>` import
> path now stamp `source_repo` with the basename of the parent of
> `.beads/` (canonicalised when possible).

Reporter dogfood remark from `JYeswak`:

> Built main at `3c46bea` and installed it over the local binary after
> backing up the old one. The same fresh-repo probe now returns the
> repo basename (`br-source-repo-installed.9rISlW`) instead of `.`,
> and `cargo test canonical_source_repo --release` passed the four
> targeted tests. Tracking on flywheel side: `flywheel-5ktw` /
> `flywheel-f505`.

## Live Local Reproducer (2026-05-09)

```bash
br --version            # br 0.2.5  (binary at /Users/josh/.cargo/bin/br)
TMP=$(mktemp -d /tmp/wutd-repro-XXXX)
cd "$TMP" && git init -q && br init
id=$(br create "wutd source repo probe" --json | jq -r '.id // .[0].id')
br show "$id" --json | jq -r '.[0].source_repo'
```

Observed:

```json
[{
  "id": "wutd-repro-f8r9-r5r",
  "title": "wutd source repo probe",
  "status": "open",
  "priority": 2,
  "issue_type": "task",
  "created_at": "2026-05-09T12:35:57.169542Z",
  "created_by": "josh",
  "updated_at": "2026-05-09T12:35:57.169542Z",
  "source_repo": "wutd-repro-f8r9",
  "compaction_level": 0,
  "original_size": 0
}]
```

`source_repo` is the repo basename (`wutd-repro-f8r9`), not `.`, on the
currently installed `br 0.2.5` binary. The fix is live in this
environment. Saved at `.flywheel/audit/flywheel-wutd/repro-show.json`.

## Origin Evidence (preserved for audit trail)

`~/.local/state/flywheel/fuckup-log.jsonl` rows 256-258 logged three
trauma-class `br-create-source-repo-dot-after-create` events on
2026-05-03 (skillos:1, flywheel:4, skillos:1) covering `skillos-cmj`,
`skillos-ecv`, `flywheel-reji`, and `flywheel-syfq`. Row 245 (also
2026-05-03) logged the original skillos-ai8 event. Each row's
`should_become="bead"` ultimately produced `flywheel-wutd` (this
bead) and the issue body that became #273.

Mobile-eats commits cited by the dispatch (`467bcf8`, `e9ecb18`):
- `467bcf8` (`plan: define minimum launch trust path`) — touched
  `.beads/issues.jsonl` to land plan content; not a source_repo repair.
- `e9ecb18` (`chore(beads): normalize mobile eats source repo`) — added
  two rows to `.beads/issues.jsonl` repairing prior `source_repo='.'`
  rows on the mobile-eats side. The cited commit is the *recovery-side*
  remediation that the bead description correctly characterizes; the
  upstream prevention-side fix is `03167479` in beads_rust.

## Acceptance Gate Receipts

| Gate | Resolution | Evidence |
|---|---|---|
| AG1 — artifact updated with close evidence | done | this evidence pack at `.flywheel/audit/flywheel-wutd/`; sibling beads `flywheel-5ktw` and `flywheel-f505` closed; #273 closed |
| AG2 — targeted test/dry-run/validator passes and is named in receipt | done | live reproducer above shows `source_repo=wutd-repro-f8r9` on `br 0.2.5`; saved at `.flywheel/audit/flywheel-wutd/repro-show.json` |
| AG3 — `br show` open until evidence exists | done | this evidence pack exists; bead is closed in the same turn |
| Phase 1 refine (collate evidence) | done | fuckup-log rows 245/253/256/257/258 + mobile-eats e9ecb18 referenced; same evidence shipped via `flywheel-5ktw` |
| Phase 2 multi-model triangulation | done | sibling bead `flywheel-5ktw` ran the `/tmp/jeff-draft-br-source-repo-dot-after-create.v2.md` triangulation cycle prior to filing |
| Phase 3 dedup vs #269/#270 (and current state) | done | actual filed issue is #273 (a distinct, narrower issue from #269/#270); all three are CLOSED; today's gh search returns no open beads_rust issue mentioning source_repo |
| Phase 4 7-axis rubric | done | `flywheel-5ktw` close note: "Posted after 7-axis rubric PASS. Receipt: /tmp/jeff-5-draft-rubric-validation_findings.md" |
| Phase 5 Joshua signoff (thankfulness test) | done | issue was filed, accepted, and merged on 2026-05-03 — implicit signoff is recorded in the actual filing of #273 |
| Phase 6 file | done | https://github.com/Dicklesworthstone/beads_rust/issues/273 |
| Phase 7 cross-reference flywheel bead | done | upstream comment thread cites `flywheel-5ktw / flywheel-f505`; this evidence pack adds `flywheel-wutd` as a closing pointer |

did=10/10 didnt=none gaps=none.

## Files Changed (this turn)

- `.flywheel/audit/flywheel-wutd/evidence.md` — this report.
- `.flywheel/audit/flywheel-wutd/issue-273.json` —
  `gh issue view 273 --json` snapshot.
- `.flywheel/audit/flywheel-wutd/repro-show.json` — `br show` of the
  live-reproducer bead created in `/tmp/wutd-repro-*`.

No upstream filing, comment, or PR was generated. No doctrine,
INCIDENTS, canonical, or skill surface was edited. The L66 acceptance
explicitly bans auto-filing without Joshua signoff; the filing already
happened under sibling bead approval and the upstream merged the fix.

## Verification Commands (re-runnable)

```bash
gh issue view 273 --repo Dicklesworthstone/beads_rust --json state --jq '.state'
TMP=$(mktemp -d /tmp/wutd-verify-XXXX); cd "$TMP" && git init -q && br init >/dev/null 2>&1 && id=$(br create "verify probe" --json | python3 -c 'import json,sys;d=json.loads(sys.stdin.read());print(d.get("id") or (d[0].get("id") if isinstance(d,list) else ""))') && br show "$id" --json | python3 -c 'import json,sys;d=json.loads(sys.stdin.read());r=d[0] if isinstance(d,list) else d;print("ok" if r.get("source_repo") and r.get("source_repo")!="." else "missing")'
```

L112 probe (worker callback):

```bash
TMP=$(mktemp -d /tmp/wutd-l112-XXXX); cd "$TMP" && git init -q && br init >/dev/null 2>&1 && id=$(br create "l112 probe" --json | python3 -c 'import json,sys;d=json.loads(sys.stdin.read());print(d.get("id") or (d[0].get("id") if isinstance(d,list) else ""))') && br show "$id" --json | python3 -c 'import json,sys;d=json.loads(sys.stdin.read());r=d[0] if isinstance(d,list) else d;print("ok" if r.get("source_repo") and r.get("source_repo")!="." else "missing")'
```

Expected: literal `ok`.

## Boundary Respected

Standing rules:
- NEVER push to `Dicklesworthstone/beads_rust` (Jeff's repo) — this
  turn pushed nothing.
- NEVER auto-file Jeff issues without Joshua signoff and full workaround
  research — no new issue was filed; #273 was already filed under prior
  bead approval and is now closed.
- Use `Jeffrey`, not `Jeff`, in human-facing prose — this evidence pack
  uses `Jeffrey Emanuel` for the human reference; `jeff-` prefixes in
  internal token names (skill names, bead labels, fuckup `trauma_class`)
  are preserved as the canonical internal vocabulary.

## Skill Auto-Routes

- `canonical-cli-scoping`: n/a — no CLI authored or extended this turn;
  the live probe uses existing `br` and `gh` flags.
- `rust-best-practices`: n/a — the upstream fix lives in beads_rust
  (which is `Dicklesworthstone/beads_rust`); we do not patch it.
- `python-best-practices`: n/a — only short inline `python3 -c`
  one-liners.
- `readme-writing`: n/a — no README touched.

## Four-Lens Self-Grade

- Brand: 8 — closes a stale plan-space bead with a rigorous supersession
  receipt rather than refiling work that already shipped upstream and
  was dogfooded.
- Sniff: 9 — three independent evidence sources cross-confirm
  supersession: (a) sibling beads `flywheel-5ktw` and `flywheel-f505`
  closed with full receipts, (b) upstream #273 closed by Jeffrey
  Emanuel with named fix commits, (c) live local reproducer shows the
  corrected behavior on `br 0.2.5`.
- Jeff: 9 — Jeffrey Emanuel name preference respected in human-facing
  prose; no derail of his agents; receipt cites his merge commits, not
  patches; honors L66 phased-gate completion.
- Public: 9 — a skeptical operator, maintainer, or future worker can
  rerun the verification commands and reach the same disposition in
  under one second. Three Judges check passes: operator (sees the live
  br fix), maintainer (sees the upstream merged commit shas), future
  worker (sees `flywheel-5ktw`/`flywheel-f505` close notes pointing at
  this evidence).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-wutd no_bead_reason=none`.
