#!/usr/bin/env bash
set -euo pipefail

memory="/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/project_cass_v2_mission_target_hit_2026_05_02.md"

for sha in 687a851 63ab9f2 9cae8e2; do
  if git -C /Users/josh/Developer/gpu-optimization cat-file -e "$sha^{commit}" 2>/dev/null; then
    printf 'unexpected_resolving_sha=%s\n' "$sha" >&2
    exit 1
  fi
done

rg -q 'Correction \(2026-05-09, flywheel-wd48\)' "$memory"
