# flywheel-1ebor Evidence

Task: `flywheel-1ebor-3e3461`
Worker: `MagentaPond`

## Acceptance Gates

AG1 Reproduce: PASS.

Scratch repo apply proof:

```bash
SYNC_CANONICAL_SOURCE="$APPLY/source/AGENTS.md" \
SYNC_RULES_SOURCE_DIR="$APPLY/source/.flywheel/rules" \
SYNC_CANONICAL_LEDGER_DISABLE=1 \
  .flywheel/scripts/sync-canonical-doctrine.sh --apply --root "$APPLY/dev" --json
```

Receipt: `/var/folders/d0/09qgt_0n1m1ff8nyzbxppx9c0000gn/T/flywheel-1ebor.XXXXXX.1OKL99j4y3/ag1-ag3-apply.json`.
Observed `rule_files=102` (101 `L*.md` shards plus `MANIFEST.json`), `status=ok`, and `rule_shard_drift_count=0`.

AG2 Diff alpsinsurance vs others: PASS.

Current bounded fleet sample:

```text
alpsinsurance canonical_lines=142 shards=101 manifest=yes
alpsinsurance-seed-org-43451a8e-3256a440 canonical_lines=142 shards=101 manifest=yes
zesttube canonical_lines=142 shards=101 manifest=yes
polymarket-pico-z canonical_lines=142 shards=101 manifest=yes
cubcloud-aaas canonical_lines=142 shards=101 manifest=yes
mobile-eats canonical_lines=142 shards=101 manifest=yes
josh-ops canonical_lines=142 shards=101 manifest=yes
flywheel canonical_lines=142 shards=101 manifest=yes
```

The current state no longer preserves the original failure state because the manual copy already repaired it. The useful distinction left in the substrate is timing: `alpsinsurance/.flywheel/rules` mtime was `2026-05-08T22:50:45-0600`, while repaired peers were later (`22:55:04` through `22:58:00`). That matches the bead report: alpsinsurance received shards before the manual repair wave; the others were repaired after.

AG3 Patch propagation: PASS.

`.flywheel/scripts/sync-canonical-doctrine.sh` already had the `a42e050e` managed-file loop that copies `$RULES_SOURCE_DIR/L*.md` plus `MANIFEST.json`. This patch preserves that behavior and adds explicit post-sync shard coherence reporting so the copy surface cannot silently regress.

AG4 Fleet drift detector: PASS.

Scratch shardless repo proof:

```bash
SYNC_CANONICAL_SOURCE="$DETECT/source/AGENTS.md" \
SYNC_RULES_SOURCE_DIR="$DETECT/source/.flywheel/rules" \
SYNC_CANONICAL_LEDGER_DISABLE=1 \
  .flywheel/scripts/sync-canonical-doctrine.sh --dry-run --root "$DETECT/dev" --json
```

Receipt: `/var/folders/d0/09qgt_0n1m1ff8nyzbxppx9c0000gn/T/flywheel-1ebor.XXXXXX.1OKL99j4y3/ag4-detect.json`.
Observed `rc=1`, `status=drift_detected`, `rule_shard_drift_count=1`, `canonical_lines=142`, `rule_shards=0`, `manifest_present=false`.

AG5 Re-run sync and verify fleet clean for shard propagation: PASS with bounded scope.

The default fleet dry-run was stopped after it collided with an older concurrent `sync-canonical-doctrine.sh --dry-run --json` process and a broad stale `find /Users/josh/Developer -maxdepth 5 -name .git -type d -prune`. To avoid adding load to a stuck substrate, I ran an explicit bounded dry-run over the 8 known doctrine targets:

```bash
SYNC_CANONICAL_LEDGER_DISABLE=1 .flywheel/scripts/sync-canonical-doctrine.sh --dry-run --json \
  --root /Users/josh/Developer/flywheel \
  --root /Users/josh/Developer/alpsinsurance \
  --root /Users/josh/Developer/alpsinsurance-seed-org-43451a8e-3256a440 \
  --root /Users/josh/Developer/zesttube \
  --root /Users/josh/Developer/polymarket-pico-z \
  --root /Users/josh/Developer/cubcloud-aaas \
  --root /Users/josh/Developer/mobile-eats \
  --root /Users/josh/Developer/josh-ops
```

Receipt: `/var/folders/d0/09qgt_0n1m1ff8nyzbxppx9c0000gn/T/flywheel-1ebor.XXXXXX.1OKL99j4y3/ag5-bounded-sync-dry-run.json`.
Observed `target_count=8`, `rule_shard_drift_count=0`, `rule_shard_drift_repos=[]`.
The dry-run still returned `rc=1` because unrelated managed-file drift exists (`managed_file_drifted_count=35`), so no fleet apply was attempted.

## Verification

```bash
bash -n .flywheel/scripts/sync-canonical-doctrine.sh
.flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-1ebor-3e3461.md
```

Both passed.

Shellcheck was run and returned one pre-existing warning at line 129 (`SC2088` in `expand_path`), outside the changed hunk.

Socraticode: 4 searches against `/Users/josh/Developer/flywheel`; project status reported 1496 indexed chunks.

## L52

No new bead filed. `no_bead_reason=all_findings_fixed_or_recorded_in_this_receipt`.

## Four-Lens Self-Grade

brand: 9
sniff: 9
jeff: 9
public: 8

Three Judges: a skeptical operator gets a failing JSON field for the exact shard drift, a maintainer gets a bounded patch with no external mutation, and a future worker gets replayable receipts.
