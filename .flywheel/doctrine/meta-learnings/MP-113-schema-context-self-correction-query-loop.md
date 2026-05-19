# MP-113 - Schema-context self-correction query loop

**Discovered:** 2026-05-19T07:46Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Generated queries and data operations are trustworthy only when grounded in explicit schema context, representative examples, dialect-specific rules, and a self-correction pass before execution.

## Where it applies

Text-to-SQL, Postgres tuning, database operations, analytics, time-series queries, migration review, RLS-sensitive systems, and any tool generating SQL or data transformations from natural language.

## Adoption signal

The generator receives table definitions, column types, relationships, examples, dialect constraints, and a validator that catches dangerous or impossible queries before execution.

## Exemplar skills (>=5)

- `~/.claude/skills/text-to-sql/SKILL.md:17` - schema context, few-shot examples, and self-correction compound accuracy.
- `~/.claude/skills/text-to-sql/SKILL.md:28` - the layered process runs schema context, examples, generation, correction, and execution.
- `~/.claude/skills/text-to-sql/SKILL.md:49` - schema context includes tables, columns, types, descriptions, and relationships.
- `~/.claude/skills/text-to-sql/SKILL.md:138` - generated SQL is validated for common errors.
- `~/.claude/skills/supabase-postgres-best-practices/SKILL.md:27` - Postgres rules are prioritized across query, connection, security, schema, locking, access, and monitoring categories.
- `~/.claude/skills/supabase-postgres-best-practices/SKILL.md:50` - each rule includes explanation, incorrect SQL, correct SQL, and metrics.
- `~/.claude/skills/time-series-analysis/SKILL.md:24` - method choice starts with data characteristics, objective, and operational context.
- `~/.claude/skills/database-operations/SKILL.md:20` - database operations cover backups, slow queries, connection pooling, maintenance, monitoring, and capacity.

## Adoption recipes

**Recipe 1 - Schema packet:** provide relevant DDL, relationships, enum values, row-level constraints, and dialect.

**Recipe 2 - Few-shot library:** include examples for joins, aggregation, date ranges, mutations, and forbidden operations.

**Recipe 3 - Pre-execution validator:** check unknown tables, ambiguous columns, unsafe mutations, missing filters, and dialect mismatches.

## Compliance test

```bash
grep -E "(schema context|few-shot|self-correction|SQL|table|column|dialect|validate|EXPLAIN|query)" SKILL.md || exit 1
```
