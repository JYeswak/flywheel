# Evidence: flywheel-2xdi.55 — register blocker-discipline-tick-chain-install-runs as self-instrumentation silo

**Bead**: flywheel-2xdi.55 (P3) | **Task ID**: flywheel-2xdi.55-d98a52 | **Identity**: MistyCliff
**Class**: cross-source-silos (not wired-but-cold)
**Flagged ledger**: `~/.local/state/flywheel/blocker-discipline-tick-chain-install-runs.jsonl`

## Bug shape (correction from bead description)

Bead said: ledger exists but is not referenced by sampled tick/status/synth/doctrine surfaces. **TRUE** — the ledger basename does not appear in any receiver surface, and was not in the known-silos allowlist.

But the ledger is **legitimately not-doctrine-relevant**:
- Writer: `.flywheel/scripts/blocker-discipline-tick-chain-launchd-install.sh` (the launchd wire-in installer for flywheel-tlclp)
- Schema: `{ts, action, sha256, status}` — installer audit rows
- Consumer: re-run idempotency check by the installer itself (sha256 hash matches → no-op)
- Not a doctrine/tick/status surface — it's an installer's self-instrumentation log

This is the same `class: self-instrumentation` shape as already-allowlisted ledgers like `autoloop-executor.jsonl`, `polish.jsonl`, `security-posture.jsonl` per `.flywheel/gap-hunt-known-silos.jsonl`.

## Fix

Appended one row to `.flywheel/gap-hunt-known-silos.jsonl`:

```jsonl
{"name":"blocker-discipline-tick-chain-install-runs.jsonl","class":"self-instrumentation","writer":"/Users/josh/Developer/flywheel/.flywheel/scripts/blocker-discipline-tick-chain-launchd-install.sh","rationale":"installer audit log for launchd wire-in (flywheel-tlclp); writes one row per --apply invocation with ts/action/sha256/status; intentionally not referenced by tick/status/synth/doctrine surfaces — consumed by gap-hunt-probe wired-but-cold + cross-source-silos rules (flywheel-2xdi.55)"}
```

Allowlist grew from 94 → 95 entries. Probe `known_silos()` now skips this ledger. Re-probe confirms `0` `cross-source-silos` matches for the basename.

## Acceptance

Bead asked to address cross-source-silos gap. Approach: register in known-silos allowlist (same shape as 3 prior similar registrations: autoloop-executor, polish, security-posture). One-row append.

This is the canonical disposition for self-instrumentation ledgers (per `.flywheel/gap-hunt-known-silos.jsonl` header comment + flywheel-gui5f / 2xdi.32 / 2xdi.43 precedent).

## Why not wire into a doctrine surface

Considered + rejected:
- The ledger's content (installer audit rows) is operationally informative but doesn't belong in tick/status/synth/doctrine. Forcing it into a doctrine surface would dilute those surfaces with non-doctrine noise.
- The installer's idempotency check IS the consumer; that's the actual wiring.
- Allowlist registration is the established canonical pattern for this class.

## L112 verify probe

`bash -c '.flywheel/scripts/gap-hunt-probe.sh --json --dry-run 2>/dev/null | jq -r ".gaps // [] | map(select(.where | test(\"blocker-discipline-tick-chain-install\"))) | length"'`
Expected: `grep:^0$`
