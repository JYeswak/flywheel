#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-spawn-templates-versioned.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-spawn-templates-versioned.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/templates" "$TMP/bin"
cat >"$TMP/bin/ntm" <<'NTM'
#!/usr/bin/env bash
if [[ "${1:-}" == "version" ]]; then
  printf '{"version":"1.2.3","commit":"abc123","built_at":"2026-05-09T00:00:00Z","go_version":"go1.25.6","platform":"darwin/arm64"}\n'
  exit 0
fi
exit 64
NTM
chmod +x "$TMP/bin/ntm"

printf 'worker v1\n' >"$TMP/templates/worker.txt"
printf 'orchestrator v1\n' >"$TMP/templates/orchestrator.md"

"$SCRIPT" registry \
  --template-dir "$TMP/templates" \
  --registry "$TMP/registry.json" \
  --ntm-bin "$TMP/bin/ntm" \
  --apply \
  --idempotency-key fixture \
  --json >"$TMP/registry.out.json"

jq -e '.status == "written" and .snapshot.template_count == 2' "$TMP/registry.out.json" >/dev/null

"$SCRIPT" doctor \
  --template-dir "$TMP/templates" \
  --registry "$TMP/registry.json" \
  --ntm-bin "$TMP/bin/ntm" \
  --json >"$TMP/pass.json"

jq -e '.invariant_id == "ntm:spawn-templates-versioned" and .status == "pass" and .template_sha_version_matrix.current.template_count == 2' "$TMP/pass.json" >/dev/null

printf 'worker v2\n' >"$TMP/templates/worker.txt"
"$SCRIPT" doctor \
  --template-dir "$TMP/templates" \
  --registry "$TMP/registry.json" \
  --ntm-bin "$TMP/bin/ntm" \
  --json >"$TMP/sha-drift.json"

jq -e '.status == "warn" and any(.warnings[]; .code == "template_sha_drift" and .template == "worker.txt")' "$TMP/sha-drift.json" >/dev/null
grep -q 'worker v2' "$TMP/templates/worker.txt"

cat >"$TMP/bin/ntm" <<'NTM'
#!/usr/bin/env bash
if [[ "${1:-}" == "version" ]]; then
  printf '{"version":"1.2.4","commit":"def456","built_at":"2026-05-10T00:00:00Z","go_version":"go1.25.6","platform":"darwin/arm64"}\n'
  exit 0
fi
exit 64
NTM
chmod +x "$TMP/bin/ntm"

"$SCRIPT" doctor \
  --template-dir "$TMP/templates" \
  --registry "$TMP/registry.json" \
  --ntm-bin "$TMP/bin/ntm" \
  --json >"$TMP/version-drift.json"

jq -e '.status == "warn" and any(.warnings[]; .code == "ntm_version_drift")' "$TMP/version-drift.json" >/dev/null

"$SCRIPT" doctor \
  --template-dir "$TMP/missing" \
  --registry "$TMP/registry.json" \
  --ntm-bin "$TMP/bin/ntm" \
  --json >"$TMP/missing-dir.json"

jq -e '.status == "warn" and any(.warnings[]; .code == "template_dir_missing")' "$TMP/missing-dir.json" >/dev/null

"$SCRIPT" --schema --json | jq -e '.invariant_id == "ntm:spawn-templates-versioned"' >/dev/null
"$SCRIPT" --examples --json | jq -e '.examples | length >= 2' >/dev/null

printf 'ntm-spawn-templates-versioned tests passed\n'
