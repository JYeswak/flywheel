# Flywheel Lock Log Schema

`.flywheel/lock-log.jsonl` is append-only evidence for lock-affecting actions on
repo-local flywheel docs. Every line is a JSON object. Existing rows without
`schema_version` are schema v1 and remain valid.

## v1 Rows

Current rows include lock repair, state finalize, reconcile, and canonical
snapshot actions. Common fields:

| Field | Type | Meaning |
|---|---|---|
| `ts` | string | UTC event timestamp. |
| `action` | string | Operation class, for example `lock-repair`, `state-finalize-lock`, or `reconcile-apply`. |
| `file` | string | Repo-relative or absolute path touched by the operation. |
| `lock_hash` | string | Body hash written into frontmatter when applicable. |
| `content_sha256` | string | Whole-content hash or body/content proof when available. |
| `actor` / `rendered_by` | string | Tool or worker that emitted the row. |

## v2 Mission-Lock Rows

Mission-lock writes use `schema_version: 2` and action `mission-lock`.

Required fields:

```json
{
  "schema_version": 2,
  "ts": "2026-05-03T00:00:00Z",
  "action": "mission-lock",
  "file": ".flywheel/MISSION.md",
  "mission_lock_id": "mission-lock-20260503T000000Z",
  "mission_lock_reason": "project-start | milestone-shift | mission-pivot | owner-review",
  "lock_hash": "<sha256 body hash>",
  "content_sha256": "<sha256 full file or rendered body proof>",
  "locked_at": "2026-05-03T00:00:00Z",
  "locked_by": "flywheel:mission-lock",
  "q_a_summary": {
    "questions_answered": 14,
    "open_questions": []
  },
  "skills_best_practices_queries": [
    {
      "domain": "agent orchestration",
      "skills_consulted": ["agent-orchestration", "beads-workflow"],
      "adopted_refs": ["~/.claude/skills/agent-orchestration/SKILL.md"]
    }
  ],
  "socraticode_queries": [
    {
      "query": "existing mission lock template",
      "projectPath": "/Users/josh/Developer/flywheel",
      "indexed_chunks_observed": 10
    }
  ],
  "research_triad_queries": [],
  "existing_project_patterns": [],
  "research_refs": [],
  "doctor_status": "ok",
  "doctor_errors": [],
  "preview_path": ".flywheel/MISSION.md.preview.20260503T000000Z",
  "backup_paths": [".flywheel/MISSION.md.bak.20260503T000000Z"],
  "rendered_by": "flywheel:mission-lock"
}
```

Optional fields:

| Field | Type | Meaning |
|---|---|---|
| `diff_path` | string | Saved preview/apply diff. |
| `owner_confirmed_by` | string | Human or orchestrator identity that approved the lock. |
| `doctrine_refs` | array | L-rules or doctrine files explicitly applied. |
| `bead_ids` | array | Beads created or updated by the lock. |

## Migration Note

Readers must treat missing `schema_version` as `1`. v2 adds fields for
mission-lock provenance but does not rename or invalidate v1 fields, so existing
rows are forward-compatible.
