# flywheel-ubrb5 FrankenTerm Watchtower Evidence

Date: 2026-05-08
Bead: flywheel-ubrb5
Follow-up bead: flywheel-g6xaw

## Objective

Ship the FrankenTerm watchtower bead with lifecycle tracking and close
flywheel-ubrb5 only after all five acceptance gates have concrete evidence.

## Prompt-to-artifact checklist

| Requirement | Evidence |
|---|---|
| AG1: Add FrankenTerm to `dicklesworthstone-stack` inventory watchlist. | `/Users/josh/.claude/skills/dicklesworthstone-stack/references/INVENTORY.md` contains `frankenterm` as row 39 and in the compact table. `/Users/josh/.claude/skills/dicklesworthstone-stack/data/sources.txt` contains `https://github.com/Dicklesworthstone/frankenterm`. |
| AG2: Extend `.flywheel/scripts/jeff-binary-version-watchtower.sh` to monitor FrankenTerm release. | `.flywheel/scripts/jeff-binary-version-watchtower.sh` emits `watchlists.frankenterm_release` with candidates `frankenterm`, `franken-term`, and `terminal`; live dry-run reports `public_count=1`, `release_count=0`, `status=public_no_release`. |
| AG3: Daily Jeff intel scheduled runner includes FrankenTerm GitHub and auto-clone/index path once public. | `jeff-intel-scheduled-runner.sh` runs source regeneration before `daily-jeff-ingest.sh`; `daily-jeff-ingest.sh` mirrors new GitHub repos and warns for Socraticode indexing. Current state already has `/Users/josh/Developer/jeff-corpus/frankenterm` indexed in Socraticode with 5302 files, and search returns FrankenTerm hits. |
| AG4: Author migration plan when FrankenTerm hits v0.1+. | Current GitHub truth: `latestRelease=null`, so v0.1+ is not released yet. Migration trigger and rollout plan are authored below and carried into follow-up bead `flywheel-g6xaw`. |
| AG5: File follow-up bead for adoption when public; block AG4 on release announcement. | `flywheel-g6xaw` created as the adoption/migration canary bead and depends on `flywheel-ubrb5`. It requires `latestRelease.tagName >= v0.1.0` before any migration. |

## Verification commands

```bash
gh repo view Dicklesworthstone/frankenterm --json name,url,isPrivate,latestRelease,defaultBranchRef,pushedAt,description
gh release list --repo Dicklesworthstone/frankenterm --limit 10
mcp__socraticode__codebase_search(projectPath="/Users/josh/Developer/jeff-corpus/frankenterm", query="FrankenTerm terminal hypervisor agent swarms WezTerm memory leaking glitching", limit=10)
bash tests/jeff-binary-version-watchtower.sh
.flywheel/scripts/jeff-binary-version-watchtower.sh --dry-run --json | jq '{status,public_count:.watchlists.frankenterm_release.public_count,release_status:.watchlists.frankenterm_release.status,row:.watchlists.frankenterm_release.rows[0]}'
br show flywheel-g6xaw --json
br dep list flywheel-g6xaw --json
```

Observed:

- `gh repo view`: public `Dicklesworthstone/frankenterm`, default branch `main`, pushed `2026-05-08T20:06:25Z`, `latestRelease=null`.
- `gh release list`: no releases.
- Socraticode search on `/Users/josh/Developer/jeff-corpus/frankenterm`: 10 hits, including `PLAN.md`, swarm session docs, and memory leak investigation docs.
- Watchtower test: `SUMMARY pass=11 fail=0`.
- Live watchtower dry-run: `public_count=1`, `release_status=public_no_release`, candidate row `frankenterm`.
- Follow-up dependency: `flywheel-g6xaw` depends on `flywheel-ubrb5`.

## Migration Plan

Trigger:

- Do not migrate on repo-public alone.
- Start adoption only when `gh repo view Dicklesworthstone/frankenterm --json latestRelease` returns a semver tag `v0.1.0` or higher.

Preflight:

- Build/install FrankenTerm in an isolated path.
- Run a read-only `ft` or FrankenTerm robot/capture smoke against a disposable session.
- Capture rollback command and prove WezTerm relaunch still works before touching live fleet sessions.

Rollout:

- Phase 1: one `flywheel` worker-pane canary for at least 24 hours.
- Phase 2: `skillos` after flywheel canary has green pane capture, recovery, and memory/RSS telemetry.
- Phase 3: `mobile-eats` and `alpsinsurance` only after a per-session rollback receipt exists.

Validation:

- Compare pane capture fidelity before/after migration.
- Compare long-running RSS growth against the current WezTerm baseline.
- Verify dispatch, callback, recovery, and pane-work-signal outputs remain green.
- File blocking bug beads instead of widening rollout if any signal regresses.

Rollback:

- Stop the FrankenTerm canary session.
- Relaunch the same pane topology in WezTerm.
- Verify `ntm` and flywheel pane-work-signal see the restored panes.
- Append the rollback receipt before retrying.
