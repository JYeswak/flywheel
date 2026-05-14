#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SKILLOS_BOUNDARY_DOC="docs/concepts/skil""los-boundary.md"

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

install_template_has_private_client_residue() {
  local dir="$1"
  local client_lower="al""ps"
  local client_upper="AL""PS"
  rg -nF "$client_upper" "$dir" >/dev/null && return 0
  rg -nF "${client_lower}_" "$dir" >/dev/null && return 0
  rg -nF "${client_lower}-" "$dir" >/dev/null && return 0
  rg -n "(^|[^[:alnum:]_-])${client_lower}([^[:alnum:]_-]|$)" "$dir" >/dev/null && return 0
  return 1
}

verify_public_extraction_counts() {
  ROOT="$ROOT" python3 <<'PY'
import json
import os
import re
import sys
from pathlib import Path

root = Path(os.environ["ROOT"])
readme = (root / "README.md").read_text(encoding="utf-8")
evidence = (root / "docs/evidence/publication-evidence.md").read_text(encoding="utf-8")

readme_match = re.search(
    r"classified ([\d,]+) source files, copied ([\d,]+) public-safe files, excluded\s+"
    r"([\d,]+) denylisted .*?reduced a ([\d,]+)-row manual\s+review queue",
    readme,
    flags=re.S,
)
evidence_match = re.search(
    r"Fresh export status pass with ([\d,]+) classified files, ([\d,]+) copied "
    r"public-safe files, and ([\d,]+) denylist-excluded files; .*? ([\d,]+) "
    r"manual-review rows",
    evidence,
    flags=re.S,
)
run_match = re.search(r"codex-public-export-\d{8}T\d{4}Z", evidence)

if not readme_match or not evidence_match or not run_match:
    sys.exit(1)

readme_counts = tuple(int(value.replace(",", "")) for value in readme_match.groups())
evidence_counts = tuple(int(value.replace(",", "")) for value in evidence_match.groups())
if readme_counts != evidence_counts:
    sys.exit(1)

manifest_path = root / ".flywheel/extraction/assembly-runs" / run_match.group(0) / "manifest.json"
if manifest_path.exists():
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    classification_path = Path(manifest["classification_path"])
    manual_review_path = Path(manifest["manual_review_path"])
    manifest_counts = (
        sum(1 for _ in classification_path.open(encoding="utf-8")),
        int(manifest["copied_count"]),
        int(manifest["denylist_excluded_count"]),
        sum(1 for _ in manual_review_path.open(encoding="utf-8")),
    )
    if evidence_counts != manifest_counts:
        sys.exit(1)
PY
}

for rel in \
  docs/concepts/loops.md \
  docs/concepts/beads.md \
  docs/concepts/agent-mail.md \
  docs/concepts/socraticode.md \
  "$SKILLOS_BOUNDARY_DOC" \
  docs/concepts/evidence-contracts.md \
  docs/brand/naming-conventions.md \
  docs/evidence/publication-evidence.md \
  docs/evidence/publication-blocker-coverage.md \
  docs/evidence/staging-review-signoff-packet.md \
  docs/evidence/publication-goal-completion-audit.md \
  docs/evidence/flywheel-trajectory.json \
  docs/evidence/asupersync-gated-adoption.md \
  docs/evidence/asupersync-poc-receipt.template.json \
  docs/evidence/asupersync-poc-receipt.local.json \
  docs/evidence/external-review-log.jsonl \
  docs/runbooks/release-cutover-authorization.md \
  docs/runbooks/repo-trajectory-story-pack.md \
  docs/runbooks/public-user-journey-pack.md \
  docs/runbooks/public-site-smb-journey-wireframe.md \
  docs/runbooks/local-actions-preflight.md \
  docs/runbooks/isolated-agent-lane-testing.md \
  docs/runbooks/upstream-substrate-adoption.md \
  docs/runbooks/agent-lane-compatibility.md \
  docs/reference/commands.md \
  docs/reference/files.md \
  docs/reference/troubleshooting.md \
  packages/zeststream-story-system/package.json \
  packages/zeststream-story-system/README.md \
  packages/zeststream-story-system/story-system.json \
  packages/zeststream-story-system/tokens.css \
  packages/zeststream-ui/package.json \
  packages/zeststream-ui/README.md \
  packages/zeststream-ui/src/index.ts \
  packages/zeststream-ui/src/components/TrustWorryMatrix.tsx \
  scripts/zs-frontend-quality-gate.sh \
  tests/zeststream-ui-package.sh \
  docs/stories/flywheel-trajectory.md; do
  require_file "$rel"
done

require_literal "docs/concepts/loops.md" "preflight -> init -> doctor -> tick -> dispatch or simulate -> validate receipt -> inspect" "loops concept names public loop"
require_literal "docs/concepts/beads.md" "Do not edit" "beads concept protects task DB"
require_literal "docs/concepts/agent-mail.md" "file reservations" "agent mail concept names reservations"
require_literal "docs/concepts/socraticode.md" "search first, patch second" "socraticode concept names search discipline"
require_literal "$SKILLOS_BOUNDARY_DOC" "Flywheel owns public installability" "capability boundary concept names Flywheel ownership"
require_literal "docs/concepts/evidence-contracts.md" "Public copy must follow the evidence." "evidence concept names copy discipline"
require_literal "docs/brand/naming-conventions.md" "Yuzu Method" "naming doc defines Yuzu Method"
require_literal "docs/brand/naming-conventions.md" "Flywheel remains the engine and" "naming doc preserves Flywheel namespace"
require_literal "docs/brand/naming-conventions.md" "Domain-collision" "naming doc requires domain-collision protection"
require_literal "docs/brand/naming-conventions.md" "Rename Gate" "naming doc includes rename gate"
require_literal "docs/concepts/evidence-contracts.md" "docs/brand/naming-conventions.md" "evidence concept names naming contract"
require_literal "README.md" "docs/evidence/publication-evidence.md" "README links publication evidence index"
require_literal "docs/evidence/publication-evidence.md" "Live Evidence Still Required" "publication evidence names live evidence boundary"
require_literal "docs/evidence/publication-evidence.md" "remote_repo_private" "publication evidence includes remote repo blocker"
require_literal "docs/evidence/publication-evidence.md" "headBranch" "publication evidence requires default-branch remote runs"
require_literal "docs/evidence/publication-evidence.md" "non-draft, non-prerelease release" "publication evidence rejects prerelease release proof"
require_literal "docs/evidence/publication-evidence.md" "sha256:" "publication evidence requires release asset digests"
require_literal "docs/evidence/publication-evidence.md" "docs/evidence/publication-blocker-coverage.md" "publication evidence links blocker coverage"
require_literal "docs/evidence/publication-evidence.md" "docs/evidence/publication-goal-completion-audit.md" "publication evidence links goal completion audit"
require_literal "docs/evidence/publication-evidence.md" "docs/stories/flywheel-trajectory.md" "publication evidence links generated trajectory"
require_literal "docs/evidence/staging-review-signoff-packet.md" "staging-review-ready-not-public-release" "staging review packet blocks public release claim"
require_literal "docs/evidence/staging-review-signoff-packet.md" "https://flywheel.zeststream.ai/" "staging review packet links staged site"
require_literal "docs/evidence/staging-review-signoff-packet.md" "docs/stories/flywheel-trajectory.md" "staging review packet links trajectory story"
require_literal "docs/evidence/staging-review-signoff-packet.md" "remote_repo_private" "staging review packet names public blockers"
require_literal "docs/evidence/staging-review-signoff-packet.md" "Not granted by this packet" "staging review packet separates staged and public approval"
require_literal "docs/evidence/flywheel-trajectory.json" "zeststream.repo_git_story.v0" "trajectory evidence names schema"
require_literal "docs/evidence/flywheel-trajectory.json" "zeststream.repo_story_message.v0" "trajectory evidence embeds owner message pack"
require_literal "docs/evidence/flywheel-trajectory.json" "show proof, do not sell the dream" "trajectory evidence names copy rule"
require_literal "docs/evidence/flywheel-trajectory.json" "Buy back the time hiding between your tools." "trajectory evidence names SMB headline option"
require_literal "docs/evidence/flywheel-trajectory.json" "AI will make a mess." "trajectory evidence names owner objection"
require_literal "docs/evidence/publication-blocker-coverage.md" "readiness_blocker_coverage" "blocker coverage names registry contract"
require_literal "docs/evidence/publication-blocker-coverage.md" "joshua_release_signoff_missing" "blocker coverage includes final signoff blocker"
require_literal "docs/evidence/publication-goal-completion-audit.md" "Prompt-To-Artifact Checklist" "goal completion audit maps prompt to artifacts"
require_literal "docs/evidence/publication-goal-completion-audit.md" "Current verdict: \`not complete\`." "goal completion audit blocks premature completion"
require_literal "docs/evidence/publication-goal-completion-audit.md" "remote_repo_private" "goal completion audit includes live remote blocker"
require_literal "docs/evidence/asupersync-gated-adoption.md" "Status: \`gated-evaluation\`." "asupersync evidence packet keeps gated status"
require_literal "docs/evidence/asupersync-gated-adoption.md" "add Asupersync to the public install path" "asupersync evidence packet blocks install dependency"
require_literal "docs/evidence/asupersync-poc-receipt.template.json" "flywheel.asupersync_poc_receipt.v0" "asupersync POC receipt template names schema"
require_literal "docs/evidence/asupersync-poc-receipt.local.json" "\"support_scope\": \"isolated_poc_only\"" "asupersync local POC receipt is isolated"
require_literal "docs/concepts/evidence-contracts.md" "docs/evidence/publication-blocker-coverage.md" "evidence concept names blocker coverage"
require_literal "docs/concepts/evidence-contracts.md" "docs/evidence/asupersync-gated-adoption.md" "evidence concept names asupersync adoption packet"
require_literal "docs/concepts/evidence-contracts.md" "docs/evidence/asupersync-poc-receipt.template.json" "evidence concept names asupersync POC receipt"
require_literal "docs/concepts/evidence-contracts.md" "docs/evidence/asupersync-poc-receipt.local.json" "evidence concept names asupersync local POC receipt"
require_literal "docs/concepts/evidence-contracts.md" "docs/evidence/external-review-log.jsonl" "evidence concept names public review evidence"
require_literal "docs/concepts/evidence-contracts.md" "scripts/live_site_probe.py" "evidence concept names live site probe"
require_literal "docs/concepts/evidence-contracts.md" "scripts/validate_cutover_receipts.py" "evidence concept names cutover receipt replay"
require_literal "docs/concepts/evidence-contracts.md" "scripts/validate_user_journey_pack.py" "evidence concept names user journey pack validator"
require_literal "docs/concepts/evidence-contracts.md" "scripts/validate_story_system_package.py" "evidence concept names story system validator"
require_literal "docs/concepts/evidence-contracts.md" "scripts/zs-frontend-quality-gate.sh" "evidence concept names frontend quality gate"
require_literal "docs/concepts/evidence-contracts.md" "scripts/extract_git_story.py" "evidence concept names git story extractor"
require_literal "docs/concepts/evidence-contracts.md" "packages/zeststream-story-system/story-system.json" "evidence concept names story system package"
require_literal "docs/concepts/evidence-contracts.md" "packages/zeststream-ui/" "evidence concept names UI package"
require_literal "docs/concepts/evidence-contracts.md" "docs/evidence/staging-review-signoff-packet.md" "evidence concept names staging review packet"
require_literal "docs/concepts/evidence-contracts.md" "docs/evidence/flywheel-trajectory.json" "evidence concept names trajectory evidence"
require_literal "docs/concepts/evidence-contracts.md" "docs/stories/flywheel-trajectory.md" "evidence concept names trajectory story"
require_literal "docs/concepts/evidence-contracts.md" "docs/runbooks/public-user-journey-pack.md" "evidence concept names public user journey pack"
require_literal "docs/concepts/evidence-contracts.md" "docs/runbooks/repo-trajectory-story-pack.md" "evidence concept names trajectory story pack"
require_literal "README.md" "docs/runbooks/release-cutover-authorization.md" "README links release cutover runbook"
require_literal "docs/runbooks/release-cutover-authorization.md" "Agents must not make the" "release cutover runbook states agent boundary"
require_literal "docs/runbooks/upstream-substrate-adoption.md" "Status: \`gated-evaluation\`." "upstream substrate runbook gates Asupersync"
require_literal "docs/runbooks/public-user-journey-pack.md" "flywheel.public_user_journey_pack.v0" "user journey pack names schema"
require_literal "docs/runbooks/public-user-journey-pack.md" "docs/runbooks/public-site-smb-journey-wireframe.md" "user journey pack links SMB wireframe"
require_literal "docs/runbooks/public-user-journey-pack.md" "source_pack_id=user-journey-wireframe-pack" "user journey pack fixes source pack id"
require_literal "docs/runbooks/public-user-journey-pack.md" "asset_id" "user journey pack requires asset id"
require_literal "docs/runbooks/public-user-journey-pack.md" "persona_lane" "user journey pack requires persona lane"
require_literal "docs/runbooks/public-user-journey-pack.md" "journey_stage" "user journey pack requires journey stage"
require_literal "docs/runbooks/public-user-journey-pack.md" "entrypoint" "user journey pack requires entrypoint"
require_literal "docs/runbooks/public-user-journey-pack.md" "visible_wording" "user journey pack requires visible wording"
require_literal "docs/runbooks/public-user-journey-pack.md" "visual_cue" "user journey pack requires visual cue"
require_literal "docs/runbooks/public-user-journey-pack.md" "primary_cta" "user journey pack requires primary CTA"
require_literal "docs/runbooks/public-user-journey-pack.md" "required_proof_refs[]" "user journey pack requires proof refs"
require_literal "docs/runbooks/public-user-journey-pack.md" "signoff_status" "user journey pack requires signoff status"
require_literal "docs/runbooks/public-user-journey-pack.md" "blocker_or_skip_receipt_ref" "user journey pack requires blocker or skip receipt"
require_literal "docs/runbooks/public-user-journey-pack.md" "SMB owner" "user journey pack covers SMB owner lane"
require_literal "docs/runbooks/public-user-journey-pack.md" "Developer" "user journey pack covers developer lane"
require_literal "docs/runbooks/public-user-journey-pack.md" "Operator" "user journey pack covers operator lane"
require_literal "docs/runbooks/public-user-journey-pack.md" "Signoff reviewer" "user journey pack covers signoff lane"
require_literal "docs/runbooks/public-user-journey-pack.md" "SkillOS is named only as the capability-control-plane integration point." "user journey pack preserves SkillOS boundary"
require_literal "docs/runbooks/public-user-journey-pack.md" "JOURNEY_SPEC_MISSING" "user journey pack names missing spec failure code"
require_literal "docs/runbooks/public-user-journey-pack.md" "STEP_VISUAL_CUE_MISSING" "user journey pack names visual cue failure code"
require_literal "docs/runbooks/public-user-journey-pack.md" "E2E_MAPPING_MISSING" "user journey pack names e2e failure code"
require_literal "docs/runbooks/public-user-journey-pack.md" "PRIVATE_STATE_LEAK" "user journey pack names private leak failure code"
require_literal "docs/runbooks/public-user-journey-pack.md" "CLAIM_WITHOUT_EVIDENCE" "user journey pack names evidence failure code"
require_literal "docs/runbooks/public-site-smb-journey-wireframe.md" "flywheel.public_site_smb_journey_wireframe.v0" "SMB wireframe names schema"
require_literal "docs/runbooks/public-site-smb-journey-wireframe.md" "receipt counts in the hero" "SMB wireframe blocks receipt-led hero"
require_literal "docs/runbooks/public-site-smb-journey-wireframe.md" "Technical proof is available but not required to understand the offer." "SMB wireframe blocks raw audit persuasion"
require_literal "docs/runbooks/public-site-smb-journey-wireframe.md" "private work stays private" "SMB wireframe translates proof to owner value"
require_literal "docs/runbooks/public-site-smb-journey-wireframe.md" "Your business already has the data. The work is just hidden between tools." "SMB wireframe leads with owner problem"
require_literal "docs/runbooks/public-site-smb-journey-wireframe.md" "Ten Owner Objections The Page Must Answer" "SMB wireframe names trust objections"
require_literal "docs/runbooks/public-site-smb-journey-wireframe.md" "AI will make a mess." "SMB wireframe names AI chaos objection"
require_literal "docs/runbooks/public-site-smb-journey-wireframe.md" "A slice is one bounded workflow improvement" "SMB wireframe defines workflow slice"
require_literal "docs/runbooks/public-site-smb-journey-wireframe.md" "Recommended Next.js target" "SMB wireframe names Next.js storytelling target"
require_literal "docs/runbooks/public-site-smb-journey-wireframe.md" "Server Components" "SMB wireframe maps progressive proof to Next.js"
require_literal "docs/runbooks/public-site-smb-journey-wireframe.md" "If a claim is not proven, it stays blocked." "SMB wireframe names blocked claim stance"
require_literal "docs/runbooks/public-site-smb-journey-wireframe.md" "The Yuzu Method ®" "SMB wireframe defines Yuzu Method"
require_literal "docs/runbooks/public-site-smb-journey-wireframe.md" "TrajectoryRail" "SMB wireframe names trajectory rail"
require_literal "docs/runbooks/public-site-smb-journey-wireframe.md" "Flywheel has a history, not just a homepage." "SMB wireframe names git-derived story scene"
require_literal "docs/runbooks/public-site-smb-journey-wireframe.md" "Map my workflow" "SMB wireframe names primary CTA"
require_literal "docs/runbooks/public-site-smb-journey-wireframe.md" "Implementation should not be accepted if tests pass while the page still feels" "SMB wireframe prevents generic-page acceptance"
require_literal "docs/runbooks/public-site-smb-journey-wireframe.md" "Implementation should not be accepted if the page can pass tests while still failing this journey." "SMB wireframe prevents tests-only acceptance"
require_literal "docs/runbooks/repo-trajectory-story-pack.md" "zeststream.repo_git_story_pack.v0" "repo trajectory pack names schema"
require_literal "docs/runbooks/repo-trajectory-story-pack.md" "zeststream.repo_story_message.v0" "repo trajectory pack names message schema"
require_literal "docs/runbooks/repo-trajectory-story-pack.md" "Show the proof, do not sell the dream." "repo trajectory pack names editorial rule"
require_literal "docs/runbooks/repo-trajectory-story-pack.md" "For another repo" "repo trajectory pack is reusable"
require_literal "docs/runbooks/repo-trajectory-story-pack.md" "trust_objections[]" "repo trajectory pack requires trust objections"
require_literal "docs/runbooks/repo-trajectory-story-pack.md" "visual_primitives[]" "repo trajectory pack requires visual primitives"
require_literal "docs/runbooks/repo-trajectory-story-pack.md" "generic SaaS language" "repo trajectory pack blocks generic SaaS language"
require_literal "docs/runbooks/repo-trajectory-story-pack.md" "human-approved slices" "repo trajectory pack uses owner-control language"
require_literal "docs/runbooks/repo-trajectory-story-pack.md" "shared React components" "repo trajectory pack targets reusable frontend components"
require_literal "docs/runbooks/repo-trajectory-story-pack.md" "packages/zeststream-story-system/" "repo trajectory pack names shared package"
require_literal "docs/runbooks/repo-trajectory-story-pack.md" "scripts/validate_story_system_package.py" "repo trajectory pack names package validator"
require_literal "docs/runbooks/repo-trajectory-story-pack.md" "ClutterFreeSpaces" "repo trajectory pack applies beyond Flywheel"
require_literal "docs/runbooks/repo-trajectory-story-pack.md" "Mobile Eats" "repo trajectory pack applies to Mobile Eats"
require_literal "docs/runbooks/repo-trajectory-story-pack.md" "falls back to Flywheel's public redaction" "repo trajectory pack documents fallback redaction"
require_literal "docs/stories/flywheel-trajectory.md" "Flywheel has a history, not just a homepage." "generated trajectory names owner headline"
require_literal "docs/stories/flywheel-trajectory.md" "Owner-Facing Message Pack" "generated trajectory includes owner message pack"
require_literal "docs/stories/flywheel-trajectory.md" "Map my workflow" "generated trajectory includes owner CTA"
require_literal "docs/stories/flywheel-trajectory.md" "OperatingRoomHero" "generated trajectory includes visual primitive"
require_literal "docs/stories/flywheel-trajectory.md" "show the proof, do not sell the dream" "generated trajectory names proof-not-dream rule"
require_literal "docs/runbooks/local-actions-preflight.md" "GitHub Actions as the final hosted-runner approval surface" "local actions runbook preserves GitHub final approval boundary"
require_literal "docs/runbooks/local-actions-preflight.md" "brew install act actionlint" "local actions runbook names global open-source tools"
require_literal "docs/runbooks/local-actions-preflight.md" "docker context use orbstack" "local actions runbook uses OrbStack"
require_literal "docs/runbooks/local-actions-preflight.md" "flywheel-actions-gate" "local actions runbook names global gate"
require_literal "docs/runbooks/local-actions-preflight.md" "--artifact-server-addr 127.0.0.1" "local actions runbook binds artifact server locally"
require_literal "docs/runbooks/local-actions-preflight.md" "--cache-server-addr 127.0.0.1" "local actions runbook binds cache server locally"
# shellcheck disable=SC2088
require_literal "docs/runbooks/local-actions-preflight.md" "~/Developer/skillos" "local actions runbook stamps SkillOS"
# shellcheck disable=SC2088
require_literal "docs/runbooks/local-actions-preflight.md" "~/Developer/mobile-eats" "local actions runbook stamps Mobile Eats"
# shellcheck disable=SC2088
require_literal "docs/runbooks/local-actions-preflight.md" "~/Developer/clutterfreespaces" "local actions runbook stamps ClutterFreeSpaces"
# shellcheck disable=SC2088
require_literal "docs/runbooks/local-actions-preflight.md" "~/Desktop/Projects/clients/alps-insurance" "local actions runbook stamps ALPS"
require_literal "docs/runbooks/isolated-agent-lane-testing.md" "creates a disposable environment" "isolated lane runbook names disposable environment"
require_literal "docs/runbooks/isolated-agent-lane-testing.md" "HOME" "isolated lane runbook isolates HOME"
require_literal "docs/runbooks/isolated-agent-lane-testing.md" "support_scope=isolated" "isolated lane runbook requires isolated support scope"
require_literal "docs/runbooks/isolated-agent-lane-testing.md" "private_state_scan.status=pass" "isolated lane runbook requires private-state scan"
require_literal "docs/runbooks/isolated-agent-lane-testing.md" "--live-adapters" "isolated lane runbook documents live adapter proof"
require_literal "docs/runbooks/isolated-agent-lane-testing.md" "--require-runtime" "isolated lane runbook documents strict blocker mode"
require_literal "docs/runbooks/isolated-agent-lane-testing.md" "bash tests/isolated-agent-lane-smoke.sh" "isolated lane runbook names contract test"
require_literal "docs/runbooks/public-release-runbook.md" "bash tests/cutover-receipts.sh" "release runbook includes cutover receipt gate"
require_literal "docs/runbooks/public-release-runbook.md" "bash tests/story-system-package.sh" "release runbook includes story package gate"
require_literal "docs/runbooks/public-release-runbook.md" "bash tests/zeststream-ui-package.sh" "release runbook includes UI package gate"
require_literal "docs/runbooks/public-release-runbook.md" "SUMMARY pass=18 fail=0" "release runbook names UI package verifier count"
require_literal "docs/runbooks/public-release-runbook.md" "SUMMARY pass=23 fail=0" "release runbook names current cutover verifier count"
require_literal "docs/runbooks/public-release-runbook.md" "SUMMARY pass=17 fail=0" "release runbook names story package verifier count"
require_literal "docs/runbooks/public-release-runbook.md" "SUMMARY pass=233 fail=0" "release runbook names current public docs count"
require_literal "docs/runbooks/public-release-runbook.md" "SUMMARY pass=95 fail=0" "release runbook names current website static count"
require_literal "docs/runbooks/public-release-runbook.md" "docs/runbooks/public-user-journey-pack.md\` maps every public asset" "release runbook includes user journey pack gate"
require_literal "docs/runbooks/public-release-runbook.md" "user-journey-pack-validation.json" "release runbook captures user journey validation receipt"
require_literal "docs/runbooks/public-release-runbook.md" "flywheel.agent_lane_runtime_receipt.v0" "release runbook names strict agent-lane receipt schema"
require_literal "docs/runbooks/public-release-runbook.md" "evidence==\"blocker_receipt\"" "release runbook names blocked agent-lane receipt interpretation"
require_literal "docs/runbooks/public-release-runbook.md" "agent-lanes-with-receipts.json" "release runbook probes agent-lane receipts"
require_literal "docs/runbooks/public-release-runbook.md" "live-site-probe.json" "release runbook captures live site probe receipt"
require_literal "docs/runbooks/public-release-runbook.md" "installer-smoke-receipt.json" "release runbook requires installer smoke receipt artifacts"
require_literal "docs/runbooks/public-release-runbook.md" "exactly one passing row for each required stage" "release runbook rejects ambiguous agent-lane runtime stages"
require_literal "docs/runbooks/public-release-runbook.md" "no \`private_state_scan.findings\` rows" "release runbook rejects private-state findings in runtime receipts"
require_literal "docs/runbooks/agent-lane-compatibility.md" "Do not update only one support-tier table." "agent lane runbook prevents support table drift"
require_literal "docs/runbooks/agent-lane-compatibility.md" "private_state_scan.status" "agent lane runbook requires private-state scan proof"
require_literal "docs/runbooks/agent-lane-compatibility.md" "flywheel.agent_lane_blocker_receipt.v0" "agent lane runbook names blocked receipt schema"
require_literal "docs/runbooks/agent-lane-compatibility.md" "exactly one \`journey_stages[]\` row" "agent lane runbook requires unambiguous required stages"
require_literal "docs/runbooks/agent-lane-compatibility.md" "no \`private_state_scan.findings\` rows" "agent lane runbook rejects private-state findings"
require_literal "docs/reference/commands.md" "flywheel validate-receipt" "command reference includes receipt validation"
require_literal "docs/reference/commands.md" "scripts/agent-lane-probe.sh --receipt-dir receipts/agent-lanes --json" "command reference includes agent-lane receipt probe"
require_literal "docs/reference/commands.md" "scripts/isolated-agent-lane-smoke.sh --receipt-dir state/isolated-agent-lanes --json" "command reference includes isolated lane smoke"
require_literal "docs/reference/commands.md" "scripts/local-actions-preflight.sh" "command reference includes local actions preflight"
require_literal "docs/reference/commands.md" "scripts/live_site_probe.py" "command reference includes live site probe"
require_literal "docs/reference/commands.md" "scripts/validate_cutover_receipts.py" "command reference includes cutover receipt validation"
require_literal "docs/reference/commands.md" "scripts/validate_user_journey_pack.py" "command reference includes user journey validation"
require_literal "docs/reference/commands.md" "scripts/validate_story_system_package.py" "command reference includes story system validation"
require_literal "docs/reference/commands.md" "scripts/zs-frontend-quality-gate.sh" "command reference includes frontend quality gate"
require_literal "docs/reference/commands.md" "scripts/extract_git_story.py" "command reference includes git story extraction"
require_literal "docs/reference/commands.md" "zeststream.repo_story_message.v0" "command reference names story message pack"
require_literal "docs/reference/commands.md" "--redaction-table" "command reference documents story redaction table"
require_literal "docs/reference/commands.md" "flywheel:de-personalization-table.yaml" "command reference documents fallback redaction table"
require_literal "docs/reference/files.md" ".flywheel/last_closeout_receipt.json" "file reference includes closeout receipt"
require_literal "docs/reference/files.md" "docs/brand/naming-conventions.md" "file reference includes naming contract"
require_literal "docs/reference/files.md" "packages/zeststream-story-system/story-system.json" "file reference includes story system package"
require_literal "docs/reference/files.md" "packages/zeststream-ui/" "file reference includes UI package"
require_literal "docs/reference/files.md" "scripts/zs-frontend-quality-gate.sh" "file reference includes frontend quality gate"
require_literal "docs/reference/files.md" "zeststream.repo_story_message.v0" "file reference names story message pack"
require_literal "docs/reference/files.md" "receipts/agent-lanes/<lane>.json" "file reference includes agent-lane receipts"
require_literal "docs/reference/files.md" "flywheel.agent_lane_blocker_receipt.v0" "file reference includes blocked agent-lane receipt schema"
require_literal "docs/reference/files.md" "scripts/isolated-agent-lane-smoke.sh" "file reference includes isolated lane smoke"
require_literal "docs/reference/files.md" "docs/runbooks/isolated-agent-lane-testing.md" "file reference includes isolated lane runbook"
require_literal "docs/reference/files.md" "scripts/live_site_probe.py" "file reference includes live site probe"
require_literal "docs/reference/files.md" "scripts/validate_cutover_receipts.py" "file reference includes cutover receipt verifier"
require_literal "docs/reference/files.md" "scripts/validate_user_journey_pack.py" "file reference includes user journey verifier"
require_literal "docs/reference/files.md" "scripts/extract_git_story.py" "file reference includes git story extractor"
require_literal "docs/reference/files.md" "docs/runbooks/public-user-journey-pack.md" "file reference includes user journey pack"
require_literal "docs/reference/files.md" "docs/runbooks/repo-trajectory-story-pack.md" "file reference includes repo trajectory pack"
require_literal "docs/reference/files.md" "docs/evidence/publication-blocker-coverage.md" "file reference includes blocker coverage"
require_literal "docs/reference/files.md" "docs/evidence/staging-review-signoff-packet.md" "file reference includes staging review packet"
require_literal "docs/reference/files.md" "docs/evidence/flywheel-trajectory.json" "file reference includes trajectory evidence"
require_literal "docs/reference/files.md" "docs/stories/flywheel-trajectory.md" "file reference includes trajectory story"
require_literal "docs/reference/files.md" "docs/evidence/external-review-log.jsonl" "file reference includes public review evidence"
require_literal "docs/reference/troubleshooting.md" "Publication readiness is blocked" "troubleshooting includes publication blocker path"
if verify_public_extraction_counts; then
  pass "public extraction counts are consistent"
else
  fail "public extraction counts are consistent"
fi

INSTALL_TEMPLATE_DIR="$ROOT/templates/flywheel-install"
if [[ -s "$INSTALL_TEMPLATE_DIR/MISSION.md.tmpl" ]] \
  && [[ -s "$INSTALL_TEMPLATE_DIR/STATE.md.tmpl" ]] \
  && [[ -s "$INSTALL_TEMPLATE_DIR/loop.json.tmpl" ]] \
  && [[ -s "$INSTALL_TEMPLATE_DIR/polish-gate/fixtures/scope-allowlist/strict-client.json" ]] \
  && [[ ! -e "$INSTALL_TEMPLATE_DIR/polish-gate/fixtures/scope-allowlist/alps.json" ]] \
  && ! install_template_has_private_client_residue "$INSTALL_TEMPLATE_DIR"; then
  pass "public install template omits private client residue"
else
  fail "public install template omits private client residue"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
