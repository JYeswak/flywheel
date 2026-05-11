# flywheel-90k49.2 — Evidence Pack

**Bead:** flywheel-90k49.2 (P4)
**Title:** [homebrew-sbh-capability-matrix] inventory flywheel's 8 storage scripts vs SBH capability surface — identify consolidation candidates
**Mission fitness:** `adjacent` — storage discipline supports the substrate that underpins continuous orch uptime.

## Acceptance gates (3/3)

| Gate | Status | Evidence |
|---|---|---|
| Classify each of 8 flywheel storage scripts as SUPERSEDED / STILL NEEDED / COMPLEMENT vs SBH surface | DONE | `.flywheel/PLANS/storage-discipline-consolidation/README.md` (full matrix); `matrix.tsv` (machine-readable) |
| Consolidation proposal lives at `.flywheel/PLANS/storage-discipline-consolidation/` | DONE | Directory created with README.md + matrix.tsv |
| Don't actually remove anything (next-bead scope) | DONE | No scripts touched; only the plan doc + a follow-up bead filed |

## Method

1. Read each of the 8 scripts at the path discovered under `.flywheel/scripts/`. Read header comments + canonical-cli scaffold blocks to determine purpose.
2. Fetched SBH public README via `gh api repos/Dicklesworthstone/storage_ballast_helper/contents/README.md`. Confirmed verbs + capabilities.
3. Probed install state: `which sbh` (not found), `brew list | grep sbh` (empty), `brew tap | grep sbh` (empty).
4. Probed Formula publish state: `gh api repos/Dicklesworthstone/homebrew-sbh/contents/Formula` → `[.gitkeep, sbh.rb]`. Formula PUBLISHED since 90k49.1 closed.
5. Classified each script along three axes (domain match, capability match, safety contract).
6. Built the recommended migration order (next-bead-class work).

## Findings

### Headline counts
- SUPERSEDED: 2 of 8 (private-tmp-prune, storage-headroom-watcher)
- COMPLEMENT: 3 of 8 (storage-pause-auto-resume, beads-mem-tmp-cleanup, session-residue-prune)
- STILL NEEDED: 3 of 8 (jeff-corpus-storage-projection, promotion-candidate-stale-fire-reaper, stale-in-progress-reaper)

### Sub-discovery 1: 3-of-8 are out-of-domain
`promotion-candidate-stale-fire-reaper.sh` and `stale-in-progress-reaper.sh` are bead-DB hygiene (close stale beads), not disk storage. `session-residue-prune.sh` is flywheel-repo hygiene. They are co-located in `.flywheel/scripts/` and conceptually adjacent but SBH's domain (raw disk pressure) does not overlap. Captured in README "Note (sub-discovery)" + "STILL NEEDED — out-of-domain" classification rows.

### Sub-discovery 2: install gate has flipped
The bead trigger was "when SBH is installed locally (gated on 90k49.1 firing first)". Live probe at this writing:
- `Formula/sbh.rb` is now PUBLISHED on Jeff's `homebrew-sbh` repo (was `.gitkeep`-only at 90k49.1 close).
- `sbh` NOT on PATH; no brew tap added; install not triggered.

Filed `flywheel-bx592` (P3) to trigger the install action per 90k49.1's AG5. The matrix work proceeded analytically from the bead's listed verb surface + public README, since:
- The bead body enumerates the SBH verbs explicitly.
- The deliverable is a plan doc, not an empirical SBH-vs-flywheel smoke test.

## DID / DIDNT / GAPS

- **DID 3/3** — all acceptance gates met
- **DIDNT none**
- **GAPS** = `flywheel-bx592` (P3 install-now-actionable; Formula/sbh.rb published since 90k49.1 closed)

## Files Changed

- `.flywheel/PLANS/storage-discipline-consolidation/README.md` (new; full matrix + migration order)
- `.flywheel/PLANS/storage-discipline-consolidation/matrix.tsv` (new; machine-readable)

No flywheel script source was modified — per dispatch contract ("Don't actually remove anything in this bead").

## L112 Probe

- `l112_probe_command`: `jq -r '.[].classification' < <(awk 'NR>1 {print "{\"classification\":\"" $2 "\"},"}' .flywheel/PLANS/storage-discipline-consolidation/matrix.tsv | sed '$ s/,$//' | (echo "["; cat; echo "]")) | sort -u | wc -l | tr -d ' '`
- `l112_probe_expected`: `literal:3`  (three distinct classes: SUPERSEDED, STILL_NEEDED, COMPLEMENT)
- `l112_probe_timeout_sec`: `5`

Simpler equivalent:
- `awk 'NR>1 {print $2}' .flywheel/PLANS/storage-discipline-consolidation/matrix.tsv | sort -u | wc -l | tr -d ' '` → expect `3`

## Four-Lens Self-Grade

- **brand:** 9 — clear classification logic; honors the "data over guess" doctrine
- **sniff:** 9 — matrix is decision-grade; ambiguities (#5 A-vs-B) called out, not papered over
- **jeff:** 10 — Jeff's repo state observed live; install-now-actionable surfaced honestly
- **public:** 9 — future operator can read README, understand the migration boundaries, and execute the follow-up sequence
