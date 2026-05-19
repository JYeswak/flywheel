# MP-95 - Data-contract reconciliation ledger

**Discovered:** 2026-05-19T08:02Z
**Discovered by:** skillos:2
**Skills exemplifying:** 6+

## Essence

Data-moving systems need a ledger of source schema, quality rules, lineage, quarantines, idempotency keys, and source-vs-target reconciliation for every run.

## Where it applies

ETL, batch processing, migrations, analytics, de-identification, billing data, model evaluation datasets, and any pipeline where silent corruption is worse than failure.

## Adoption signal

The pipeline records schema version, freshness/completeness SLAs, lineage, rejected records, dedup keys, row counts, and reconciliation results before consumers trust the output.

## Exemplar skills (>=5)

- `~/.claude/skills/etl-pipeline/SKILL.md:25` - pipelines must handle schema evolution, quality drift, volume spikes, and upstream breakage without silent corruption.
- `~/.claude/skills/etl-pipeline/SKILL.md:114` - failed records are quarantined by data-quality rules.
- `~/.claude/skills/etl-pipeline/SKILL.md:200` - retries require upsert/merge, dedup keys, and idempotent writes.
- `~/.claude/skills/etl-pipeline/SKILL.md:204` - source and target row counts must reconcile every run.
- `~/.claude/skills/data-quality-validation/SKILL.md:57` - schema-on-write plus dead letter combines enforcement with no data loss.
- `~/.claude/skills/data-quality-validation/SKILL.md:86` - data contracts include freshness, availability, and completeness thresholds.
- `~/.claude/skills/data-quality-validation/SKILL.md:172` - lineage answers where bad data came from and what it affects.
- `~/.claude/skills/data-deidentification/SKILL.md:141` - de-identification reports document methods, parameters, and residual risk per field.
- `~/.claude/skills/batch-processing/SKILL.md:107` - batch jobs expose status and request counts before result collection.

## Adoption recipes

**Recipe 1 - Run receipt:** emit source counts, target counts, rejected counts, duplicate counts, freshness, and schema version.

**Recipe 2 - Quarantine, do not drop:** invalid records go to a DLQ with enough metadata to reprocess.

**Recipe 3 - Lineage minimum:** record source system, job/run ID, transform version, owner, and downstream consumers.

## Compliance test

```bash
grep -E "(schema|contract|lineage|reconciliation|row count|quarantine|DLQ|freshness|idempotent|dedup)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-52-streaming-data-roundtrip-boundary.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
