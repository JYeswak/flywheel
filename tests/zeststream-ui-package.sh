#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/zeststream-ui-package.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

require_file() {
  local rel="$1"
  if [[ -s "$ROOT/$rel" ]]; then
    pass "file exists: $rel"
  else
    fail "file exists: $rel"
  fi
}

require_literal() {
  local rel="$1" literal="$2" label="$3"
  if rg -qF -- "$literal" "$ROOT/$rel"; then
    pass "$label"
  else
    fail "$label"
  fi
}

require_file "packages/zeststream-ui/package.json"
require_file "packages/zeststream-ui/tsconfig.json"
require_file "packages/zeststream-ui/src/index.ts"
require_file "packages/zeststream-ui/src/components/ProofRail.tsx"
require_file "packages/zeststream-ui/src/components/WorkflowMap.tsx"
require_file "packages/zeststream-ui/src/components/TelemetryBar.tsx"
require_file "packages/zeststream-ui/src/components/TrustWorryMatrix.tsx"
require_file "scripts/zs-frontend-quality-gate.sh"

require_literal "packages/zeststream-ui/package.json" "@zeststream/ui" "ui package name"
require_literal "packages/zeststream-ui/package.json" "./trust-worry-matrix" "ui package exports trust worry matrix"
require_literal "packages/zeststream-ui/src/index.ts" "TrustWorryMatrix" "ui index exports trust worry matrix"
require_literal "packages/zeststream-ui/src/components/TrustWorryMatrix.tsx" "visibleAnswer" "trust matrix carries owner-visible answer"
require_literal "scripts/zs-frontend-quality-gate.sh" "zs-frontend-quality-gate/v1" "frontend gate emits schema"
require_literal "scripts/zs-frontend-quality-gate.sh" "zeststream.repo_owner_story_brief.v0" "frontend gate requires owner brief evidence"

if python3 - "$ROOT" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
package = json.loads((root / "packages/zeststream-ui/package.json").read_text())
for target in package["exports"].values():
    if not (root / "packages/zeststream-ui" / target).exists():
        raise SystemExit(f"missing export target: {target}")
PY
then
  pass "ui package exports point to existing files"
else
  fail "ui package exports point to existing files"
fi

if shellcheck "$ROOT/scripts/zs-frontend-quality-gate.sh"; then
  pass "frontend quality gate shellcheck"
else
  fail "frontend quality gate shellcheck"
fi

GOOD="$TMP/good-next"
mkdir -p "$GOOD/app" "$GOOD/components" "$GOOD/lib/design" "$GOOD/lib" "$GOOD/docs/evidence"
cat >"$GOOD/package.json" <<'JSON'
{
  "dependencies": {
    "@zeststream/story-system": "workspace:*",
    "@zeststream/ui": "workspace:*",
    "next": "15.0.0",
    "react": "19.0.0"
  }
}
JSON
cat >"$GOOD/app/page.tsx" <<'TS'
import { Inter } from "next/font/google"
import { StoryPanel } from "../components/StoryPanel"

const inter = Inter({ subsets: ["latin"] })

export default function Page() {
  return <main className={inter.className}><StoryPanel /></main>
}
TS
cat >"$GOOD/app/globals.css" <<'CSS'
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms;
  }
}
CSS
cat >"$GOOD/components/StoryPanel.tsx" <<'TS'
import storySystem, { assertStorySystemContract } from "@zeststream/story-system"
import { ProofRail, TrustWorryMatrix, WorkflowMap } from "@zeststream/ui"

const springPresets = { proof: "bounded" }
assertStorySystemContract(storySystem)

export function StoryPanel() {
  return (
    <section aria-label="Workflow proof room" data-motion={springPresets.proof}>
      <WorkflowMap
        nodes={[{ id: "email", label: "Email", role: "source" }, { id: "crm", label: "CRM", role: "sink" }]}
        edges={[{ from: "email", to: "crm", proofState: "proven" }]}
      />
      <ProofRail items={[{ label: "Email to CRM", state: "proven" }]} />
      <TrustWorryMatrix
        items={[{
          worry: "AI will make a mess.",
          visibleAnswer: "The map comes before automation.",
          proofBehavior: "Unsupported claims stay blocked.",
          state: "proven",
        }]}
      />
      <a href="#add-menu-item" aria-label="Jump to add menu item">Add menu item</a>
    </section>
  )
}
TS
cat >"$GOOD/lib/design/tokens.ts" <<'TS'
export const tokens = {
  radius: 8,
}
TS
cat >"$GOOD/lib/copy.ts" <<'TS'
export const copy = {
  cta: "Map my workflow",
}
TS
cat >"$GOOD/docs/evidence/repo-trajectory.json" <<'JSON'
{
  "schema_version": "zeststream.repo_git_story.v0"
}
JSON
cat >"$GOOD/docs/evidence/repo-owner-brief.json" <<'JSON'
{
  "schema_version": "zeststream.repo_owner_story_brief.v0",
  "primary_cta": "Map my workflow"
}
JSON

if "$ROOT/scripts/zs-frontend-quality-gate.sh" --repo "$GOOD" --json >"$TMP/good.json" \
  && jq -e '.status == "pass" and .pass == 10 and .fail == 0 and .warn == 0' "$TMP/good.json" >/dev/null; then
  pass "frontend quality gate accepts complete Next fixture"
else
  fail "frontend quality gate accepts complete Next fixture"
  cat "$TMP/good.json" >&2 || true
fi

BAD="$TMP/bad-next"
mkdir -p "$BAD/app" "$BAD/components"
cat >"$BAD/package.json" <<'JSON'
{"dependencies":{"next":"15.0.0","react":"19.0.0"}}
JSON
cat >"$BAD/app/page.tsx" <<'TS'
export default function Page() {
  return <main>Missing the story system.</main>
}
TS
cat >"$BAD/components/Button.tsx" <<'TS'
export function Button() {
  return <button>Go</button>
}
TS

set +e
"$ROOT/scripts/zs-frontend-quality-gate.sh" --repo "$BAD" --strict --json >"$TMP/bad.json"
bad_rc=$?
set -e
if [[ "$bad_rc" -eq 1 ]] \
  && jq -e '.status == "fail" and .fail >= 3 and any(.results[]; .id == "FQ-01" and .verdict == "fail")' "$TMP/bad.json" >/dev/null; then
  pass "frontend quality gate rejects weak Next fixture"
else
  fail "frontend quality gate rejects weak Next fixture"
  cat "$TMP/bad.json" >&2 || true
fi

if "$ROOT/scripts/zs-frontend-quality-gate.sh" --repo "$ROOT" --json >"$TMP/flywheel.json" \
  && jq -e '.status == "pass" and .fail == 0 and any(.results[]; .id == "FQ-09" and (.detail | contains("packages/zeststream-story-system/story-system.json")) and (.detail | contains("flywheel-owner-brief.json")))' "$TMP/flywheel.json" >/dev/null; then
  pass "frontend quality gate prunes private extraction state"
else
  fail "frontend quality gate prunes private extraction state"
  cat "$TMP/flywheel.json" >&2 || true
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
