# flywheel-5j5sp — DCG-block hook enrichment: surface SLB hint when DCG fires

## Context

Pairs with flywheel-xr6zb (detector, just shipped commit 536c7b2a) + zesttube zt-slb peer-approval surface (PR #40 merged at 62d6034c) + zesttube zt-slb-dcg-hook-enrichment-cross-repo-24kdr (zesttube's tracking bead, awaiting flywheel hook commit).

Today's joint sub-sprint with zesttube:2:
- zesttube owns peer-approval surface + tier-mapping (shipped)
- flywheel owns detector + 3-layer routing classifier (just shipped via xr6zb)
- flywheel owns hook enrichment (THIS BEAD)
- zesttube ratifies cross-bead 24kdr on flywheel hook landing

## What this hook does

When DCG fires a block, currently the message says "Joshua-approval required" + maybe a hint. After this enrichment, the message ALSO surfaces:
- Which SLB layer COULD handle the command (8iook pre-auth OR daeqx recipe OR zesttube peer-approval)
- The exact command pattern to invoke that layer
- Audit row link

User experience shift: DCG-block goes from "ask Joshua" to "submit-to-SLB-X via $RECIPE; Joshua-fallback only if no layer matches".

## Deliverables

### A. ~/.claude/hooks/PreToolUse/dcg-block-with-slb-hint.sh
Wraps the existing DCG hook chain. Logic:
1. Receive DCG-flagged command
2. Probe ~/.flywheel/dcg-pre-authorized-scopes.json (8iook config) — if pattern matches, surface hint: "command matches 8iook pre-auth scope <id>; auto-approve by re-running"
3. Probe ~/.flywheel/slb-recipes.json (daeqx config) — if pattern matches, surface hint: "command matches daeqx SLB recipe <id>; safe-execute via .flywheel/scripts/slb-recipe-add.sh or wrapper invocation"
4. Probe zesttube/.flywheel/config/slb-tier-mapping.yaml — if pattern matches AND tier is DANGEROUS, surface hint: "command matches zesttube SLB tier-mapping; submit peer-approval via ntm send zesttube --pane=1 SLB_REVIEW_REQUEST ..."
5. If no layer matches: fall through to existing DCG prompt with "no SLB layer matched; Joshua-approval required" annotation

### B. ~/.flywheel/dcg-block-with-slb-hint-audit.jsonl
Log every DCG-block-with-enrichment row: timestamp + command pattern + matched layer + user action taken (auto-approve / submitted-to-SLB / Joshua-prompt). Useful for substrate observability — measures the Joshua-keystroke savings rate.

### C. tests/dcg-block-with-slb-hint-smoke.sh
- 8+ assertions:
  1. Command matching 8iook pattern → hint includes "8iook pre-auth scope" + scope_id
  2. Command matching daeqx recipe → hint includes "daeqx SLB recipe" + recipe_id
  3. Command matching zesttube tier-mapping DANGEROUS → hint includes peer-approval invocation
  4. Command matching no layer → annotation "no SLB layer matched; Joshua-approval required"
  5. Multiple-layer match → hints surfaced for each layer in priority order
  6. Audit row written
  7. Idempotent re-run
  8. Schema validation for output envelope

### D. .flywheel/doctrine/dcg-block-with-slb-hint-discipline.md
- Document the 3-layer routing surface from a USER perspective (when DCG blocks, what they see + how to act)
- Cross-link to 8iook + daeqx + zesttube tier-mapping
- Cross-link to xr6zb stale-worktree detector (uses same routing logic)
- Document audit-row schema

### E. Cross-orch handoff to zesttube:2
Auto-generated handoff confirming the hook landed at flywheel commit + ready for zesttube ratification:
- Hook commit sha
- Audit-ledger path
- Smoke fixture status
- Recommend zesttube:2 trigger their post-merge verify (per their 08:04Z ratification packet drafted)

## Acceptance

- Hook installed at ~/.claude/hooks/PreToolUse/dcg-block-with-slb-hint.sh
- ~/.flywheel/dcg-block-with-slb-hint-audit.jsonl initialized
- Smoke 8+ assertions PASS
- shellcheck PASS
- Doctrine doc shipped
- Cross-orch handoff to zesttube:2 sent
- Bead flywheel-5j5sp closed

## Out of scope

- Modifying existing DCG hook — wrapper-only
- Modifying 8iook or daeqx configs
- Modifying zesttube tier-mapping — read-only consume
- Actually executing the suggested SLB invocation — surface hint only, user/agent acts

## Loop contract

- Track 3 only
- mcp-agent-mail file_reservation_paths before edits
- socraticode K>=10 with 2 phrasings on ~/.claude/hooks/ existing patterns + zesttube slb-tier-mapping schema
- Bridge daemon LIVE
- SCR event: C6_trauma_outflow (kills DCG-block-then-Joshua-prompt class for known-patterns) + C7_verification_density

## FIRST ACTION

1. br show flywheel-5j5sp.
2. Read /Users/josh/Developer/zesttube/.flywheel/config/slb-tier-mapping.yaml (note: xr6zb detector reported this path may not exist — verify path + confirm with zesttube:2 if mismatch; my expected path is from their 07:55Z handoff).
3. Read ~/.flywheel/dcg-pre-authorized-scopes.json (8iook).
4. Read ~/.flywheel/slb-recipes.json (daeqx).
5. ACK row.
6. Implement hook + audit ledger + smoke + doctrine.
7. Self-validate.
8. Commit + close bead + cross-orch handoff to zesttube:2 + DIRECT pane-1 ntm send.
