#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../../.."

bash -n .flywheel/scripts/tentacle-source-presence-audit.sh
bash -n tests/tentacle-source-presence-audit.sh
tests/tentacle-source-presence-audit.sh
.flywheel/scripts/tentacle-source-presence-audit.sh --json \
  | jq -e '
      .schema_version == "tentacle-source-presence-audit/v1" and
      .auto_clone_attempted == false and
      (.rows | length) == .total and
      all(.rows[]; (.source_present | type) == "boolean") and
      all(.rows[]; (.source_present == true) or (.route == "warn" or .route == "l61_message"))
    ' >/dev/null

printf '%s\n' 'OK_tentacle_source_presence_audit_stable'
