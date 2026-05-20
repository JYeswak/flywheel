# flywheel-xr6zb — Stale-worktree detector + 3-layer SLB routing classifier

## Context

Joshua-direct question via zesttube:2 2026-05-20T07:42Z: "why can't SLB+DCG combined clean stale worktrees?" — answer: the wiring exists in pieces but lacks (a) hook enrichment to surface SLB on DCG block (zesttube-owned, bead 24kdr in flight) and (b) a detector that initiates cleanup (this bead).

Zesttube currently has ~27 stale worktrees from W7 work that closed days ago. Each `git worktree remove` is DCG-blocked → Joshua-prompt → friction. With:
- 8iook (pre-auth scopes, shipped) covering disposable-prefix patterns
- daeqx (recipe-based SLB execution, just shipped commit cd01b2fc) covering reversible ops with snapshot+verify+audit
- zesttube SLB peer-approval surface covering context-checked complex cases

…the THREE SLB layers exist. This bead fills the detector + routing-classifier gap.

## Deliverables

### A. .flywheel/scripts/stale-worktree-detector.sh
Per-repo periodic probe + auto-classify:

```
for each worktree in `git worktree list`:
  collect:
    - path
    - branch (if attached)
    - last_commit_age_days
    - merged_to_default_branch?      (git branch --merged <default>)
    - pushed_to_origin?               (git ls-remote origin <branch>)
    - path_prefix_class:              tmpdir / sibling-suffix / sibling-fresh-clone / detached
  
  classify into one of:
    - DISPOSABLE — path under /tmp/* or $TMPDIR/* → route to 8iook pre-auth (auto-execute, audit-only)
    - REVERSIBLE_RECIPE — merged + pushed + age > age_threshold + path matches sibling-suffix pattern → route to daeqx recipe (snapshot worktree state + execute via codex pane + verify + audit)
    - PEER_REVIEW — merged uncertain OR partial state OR detached → route to zesttube SLB peer-approval surface with context_check string
    - HUMAN_FALLBACK — fundamentally unclassifiable → Joshua-prompt (escape hatch, should be rare)
```

Flags:
- `--repo PATH` — target repo (default cwd's git toplevel)
- `--age-threshold-days N` — min age for cleanup candidacy (default 7)
- `--default-branch NAME` — auto-detect from origin HEAD if unspecified
- `--dry-run` — emit classification report, no SLB submission
- `--apply` — actually submit to SLB layer per classification
- `--json` — emit envelope

Emit envelope:
```json
{
  "schema_version": "flywheel.stale_worktree_detector.v1",
  "ts": "...",
  "repo": "...",
  "default_branch": "...",
  "worktrees_total": N,
  "classified": {
    "DISPOSABLE": [{"path":"...","route":"8iook"}],
    "REVERSIBLE_RECIPE": [{"path":"...","route":"daeqx","recipe":"git-worktree-remove-sibling"}],
    "PEER_REVIEW": [{"path":"...","route":"zesttube-slb","context_check":"..."}],
    "HUMAN_FALLBACK": [{"path":"...","reason":"..."}]
  },
  "submissions": N,
  "audit_log_path": "~/.local/state/flywheel/stale-worktree-detector.jsonl"
}
```

### B. Recipe addition to daeqx
Add to ~/.flywheel/slb-recipes.json:

```json
{
  "id": "git-worktree-remove-sibling-merged-pushed",
  "command_pattern": "^git worktree remove /Users/josh/Developer/[a-z][a-z0-9-]+-[a-z][a-z0-9-]+-[a-z0-9]{5}-[0-9]{6}/?$",
  "safe_execution_protocol": {
    "pre_snapshot": "git -C <worktree-path> rev-parse HEAD > .flywheel/audits/slb-snapshots/worktree-pre-<ts>-<basename>.sha",
    "pre_verify": "git branch --merged <default-branch> | grep -q <worktree-branch>",
    "execute": "git worktree remove <worktree-path>",
    "post_verify": "test ! -d <worktree-path>",
    "audit_log_required": true
  },
  "fallback_to_prompt_if": ["pre_verify_fails", "worktree-has-uncommitted-changes"]
}
```

### C. .flywheel/scripts/install-stale-worktree-detector-launchd.sh
Per-repo launchd cadence (every 6h). Logs to ~/.local/state/flywheel/stale-worktree-detector/<repo>.log. Idempotent install.

### D. .flywheel/scripts/stale-worktree-detector-fleet-rollout.sh
Iterate the known-fleet repos (flywheel + skillos + zesttube + mobile-eats + clutterfreespaces + alpsinsurance + vrtx + picoz + terratitle). Per-repo install. Dry-run report shows planned probe schedule. Joshua-gated --apply for fleet rollout (per memory: scope-pinned cadence install).

### E. .flywheel/doctrine/stale-worktree-detector-discipline.md
Document the 3-layer routing model + classification rules + cross-reference to:
- 8iook DCG pre-authorized-scopes
- daeqx /slb recipe-based execution
- zesttube SLB peer-approval surface
- 24kdr hook enrichment (zesttube-owned)
- Joshua's 07:42Z question framing

### F. tests/stale-worktree-detector-smoke.sh
8+ assertions covering each classification path, edge cases (detached HEAD, multiple worktrees same branch, uncommitted changes, non-tracking branch).

## Acceptance

- 4 scripts + 1 recipe addition + 1 doctrine + smoke ship
- shellcheck PASS
- Smoke 8+ assertions PASS
- Initial dry-run report against flywheel + zesttube (probe-only, no SLB submission) saved at .flywheel/audits/stale-worktree-detector-initial-dry-run-<ts>.md
- Recipe added to daeqx SLB registry
- Joshua-gated apply for fleet launchd rollout — DO NOT install cadence on remote repos without Joshua-greenlight
- Bead flywheel-xr6zb closed

## Out of scope

- Actually executing the worktree cleanups — that's the DOWNSTREAM of routing-to-SLB (each SLB layer does its own execution)
- Cross-session peer-approval orchestration — per-session is sufficient for worktree-local case
- Modifying zesttube's SLB tier mapping — zesttube owns that, this bead just routes TO it

## Loop contract

- Track 3 only
- mcp-agent-mail file_reservation_paths before edits
- socraticode K>=10 with 2 phrasings on existing daeqx SLB recipe schema + 8iook pre-auth config + zesttube SLB tier mapping
- Bridge daemon LIVE
- SCR event: C6_trauma_outflow (kills stale-worktree-accumulation class)
- STOP on Track 1/2 breach, BLOCKED, >3h hard cap

## FIRST ACTION

1. br show flywheel-xr6zb.
2. Read /Users/josh/Developer/zesttube/.flywheel/doctrine/slb-dcg-pairing.md + slb-tier-mapping.yaml for zesttube's SLB shape.
3. Read .flywheel/doctrine/slb-discipline.md (daeqx's shipping doctrine).
4. Read ~/.flywheel/dcg-pre-authorized-scopes.json (8iook config).
5. ACK row.
6. Implement detector + recipe + installer + rollout + doctrine + smoke.
7. Self-validate.
8. Commit + close bead + DIRECT pane-1 ntm send.
