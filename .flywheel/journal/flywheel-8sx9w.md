# Journey entry — flywheel-8sx9w

**Bead**: P0 7axmt-followup (first of 7 Tier-1 fixes).
**Surface**: `.flywheel/scripts/sync-canonical-doctrine.sh` — cross-fleet doctrine sync, largest blast radius among the 7 Tier-1 violations.
**Sister**: flywheel-7axmt (970/1000, fleet-wide no-idempotency-key audit).
**Result**: 11/11 in-bead PASS + 154 sister assertions clean; 1000/1000.

## Arc

1. **Read fix-spec** at `.flywheel/audit/flywheel-7axmt/fix-specs.md` section 1. Recipe was already detailed from the audit work.
2. **Reserve target** + map structure: argparse at lines 234-281, first mutation gate at line 813, RESULT envelope at line 1138, ledger write at line 1286.
3. **Add module-scope vars** `IDEMPOTENCY_KEY=""` + `SCHEMA_VERSION="sync-canonical-doctrine-receipt/v1"`.
4. **Add argparse parsers** for both `--idempotency-key VALUE` and `--idempotency-key=VALUE` forms; missing-value → rc=2 usage error.
5. **Add refusal gate** right after the argparse `done` (before any side-effect). Canonical refusal envelope shape matches `cli_refuse_apply_without_idem_key`. rc=3.
6. **Add ledger-replay-check** (bonus from fix-spec). Skip the surface entirely (no-op exit 0) if the ledger already has a row with the same key + status in {ok, synced, in_sync}.
7. **Wire `idempotency_key` into RESULT envelope** at line 1138 so each ledger row carries the key.
8. **Update documentation**: usage, --info flags + mutates, --examples, --schema property declaration, exit codes.
9. **Live test**:
   - First run `--apply` without key → rc=3 + refusal envelope ✓
   - First run `--apply --idempotency-key=K --root /tmp/no-such` → ok + row written with key ✓
   - Second run with same K → expected replay; **didn't fire** ✗

10. **Debug step**: ledger had a parse error at line 411 (pre-existing, from before validation hygiene landed). Strict `jq -c` parser failed silently due to `2>/dev/null || true`, so replay-check returned empty. Fix: switched to `jq -Rc 'fromjson? | ...'` (raw-input + tolerant parse) to step past corrupt rows.

11. **Re-test**: replay-check fires correctly on re-run with same key (emits `replay:true`, exit 0) ✓.

12. **Write regression test** with 10 ACs covering: refusal contract, envelope shape, replay-check, fresh-key behavior, schema property, usage error, equals-form, check-mode passthrough, --info doc, --help doc. 11 assertions PASS.

13. **Clean test rows** from real ledger (29 rows removed across test-no-op-key + fresh-key-* + ag*-key prefixes); backup retained at `~/.local/state/flywheel/doctrine-sync-ledger.jsonl.bak.before-7axmt-cleanup.<pid>`.

## Discoveries (2)

1. **`ledger-replay-check-with-tolerant-parse`** — historical audit logs may have parse errors from before validation hygiene landed. Replay-check filters MUST use `jq -R 'fromjson?'` (raw-input + tolerant parse) to step past corrupt rows. The real sync-canonical ledger had a parse error at line 411 of 3465 that would have silently disabled the replay-check under strict `jq -c`. Discovery applies to ANY ledger-replay pattern across the fleet.

2. **`idempotency-key-with-replay-check` pair-pattern** — adding `--idempotency-key` to a mutation surface should ALSO add a ledger-replay-check. The gate alone refuses re-runs without a key; the replay-check enables safe-retry with a key. Together: "retry after partial failure" without double-mutation. Future 7axmt Tier-1 fixes should bundle both.

## 7axmt followup arc status

After this bead: **1/7 Tier-1 fixed**. Remaining:
- P1: flywheel-1o9fa (stale-error-auto-ping), flywheel-j0xpa (security-precommit-installer), flywheel-j99xb (regenerate-dicklesworthstone-sources)
- P2: flywheel-mfy7u (hub-blocker-detect), flywheel-y0ft6 (bcv-task-harness)
- P3: flywheel-wdh08 (jeff-bead-285-divergence-capture)
- L10-lint-rule: flywheel-9dace

The 6 remaining surfaces all benefit from the **pair-pattern** discovery (gate + replay-check). Their ledgers/audit-logs vary so the replay-check filter may need per-surface adaptation (different field names, different success-status values).

## Behavior change

This is the first 7axmt fix that **changes existing automation behavior**: any caller of `sync-canonical-doctrine.sh --apply` without `--idempotency-key` will now fail rc=3 instead of running. Operators must update invocations. Search command in evidence.md.
