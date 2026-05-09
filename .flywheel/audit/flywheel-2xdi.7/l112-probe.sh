#!/usr/bin/env bash
set -euo pipefail

memory_file="/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/project_skillos_goal_rotation_v2_2026_05_03.md"
memory_index="/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/MEMORY.md"
incidents="/Users/josh/.claude/skills/.flywheel/INCIDENTS.md"
handoff="/Users/josh/Developer/flywheel/.flywheel/handoffs/2026-05-04-1535-eod-validator-v2-in-flight.md"
research="/Users/josh/Developer/flywheel/.flywheel/research/fleet-ops-meeting-approved-method-2026-05-05/LANE-D-joshua.md"

test -s "$memory_file"
rg -n 'project_skillos_goal_rotation_v2_2026_05_03\.md' "$memory_index" >/dev/null
rg -n 'project_skillos_goal_rotation_v2_2026_05_03\.md' "$incidents" >/dev/null
rg -n 'project_skillos_goal_rotation_v2_2026_05_03' "$handoff" >/dev/null
rg -n 'project_skillos_goal_rotation_v2_2026_05_03\.md' "$research" >/dev/null

printf 'pass\n'
