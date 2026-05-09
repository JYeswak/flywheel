#!/usr/bin/env bash
set -euo pipefail

ROOT=/Users/josh/Developer/flywheel
MISSION_CMD=/Users/josh/.claude/commands/flywheel/mission-lock.md
SKILLS_CMD=/Users/josh/.claude/commands/flywheel/skills-best-practices.md
MISSION_SCHEMA="$ROOT/.flywheel/validation-schema/v1/examples/mission-lock-schema.example.json"
SKILLS_SCHEMA="$ROOT/.flywheel/validation-schema/v1/examples/skills-best-practices-schema.example.json"

python3 -m json.tool "$MISSION_SCHEMA" >/dev/null
python3 -m json.tool "$SKILLS_SCHEMA" >/dev/null

jq -e '
  .properties.schema_version.const == "mission-lock-schema/v1"
  and (.required | index("output_packet"))
  and (.required | index("lock_log_row"))
  and (."$defs".output_packet.required | index("mission_lock_id"))
  and (."$defs".output_packet.required | index("doctor_strict"))
' "$MISSION_SCHEMA" >/dev/null

jq -e '
  (.required | index("status"))
  and (.required | index("domain_hint"))
  and (.required | index("skills"))
  and (.properties.status.enum | index("degraded"))
' "$SKILLS_SCHEMA" >/dev/null

rg -n 'examples/mission-lock-schema\.example\.json' "$MISSION_CMD" >/dev/null
rg -n 'examples/skills-best-practices-schema\.example\.json' "$SKILLS_CMD" >/dev/null

if rg -n 'mission-lock-output-schema-validator|MISSION.md|lock-log.jsonl' "$ROOT/.flywheel/validation-schema/v1/examples" >/dev/null; then
  printf '%s\n' 'ERR_behavior_surface_named_in_schema_examples' >&2
  exit 1
fi

printf '%s\n' 'OK_slash_command_schema_examples'
