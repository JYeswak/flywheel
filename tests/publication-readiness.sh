#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/scripts/publication_readiness.py"
RUNBOOK="$ROOT/docs/runbooks/public-release-runbook.md"
PUBLIC_CUTOVER="$ROOT/docs/runbooks/release-cutover-authorization.md"
CUTOVER_PACKET="$ROOT/.flywheel/PLANS/public-share-readiness-2026-05-12/25-RELEASE-CUTOVER-AUTHORIZATION-PACKET.md"
CUTOVER_PACKET_DIR="$(dirname "$CUTOVER_PACKET")"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-publication-readiness.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if python3 -m py_compile "$SCRIPT"; then
  pass "syntax"
else
  fail "syntax"
fi

RECEIPT="$ROOT/.flywheel/PLANS/public-share-readiness-2026-05-12/23-TP-005-017-018-PUBLICATION-READINESS-RECEIPT.md"
if [[ -f "$RECEIPT" ]] && rg -qF 'TP-015 external review is closed for the current seven-surface public trust set.' "$RECEIPT"; then
  pass "readiness receipt records current external review closure"
elif [[ ! -f "$RECEIPT" && ! -f "$CUTOVER_PACKET" ]]; then
  pass "private readiness receipt omitted from public export"
else
  fail "readiness receipt records current external review closure"
fi

if rg -qF '| `approver` | `Joshua Nowak` exactly; aliases are rejected by `scripts/publication_readiness.py`. |' "$RUNBOOK"; then
  pass "release runbook documents exact signoff approver"
else
  fail "release runbook documents exact signoff approver"
fi

if rg -qF '`Joshua`, or `Josh`' "$RUNBOOK"; then
  fail "release runbook does not allow signoff aliases"
else
  pass "release runbook does not allow signoff aliases"
fi

if rg -qF '| GitHub workflows | `CI`, `Installer Smoke`, `Release`, and `Site Deploy` exist on the remote. |' "$RUNBOOK"; then
  pass "release runbook lists all required remote workflows"
else
  fail "release runbook lists all required remote workflows"
fi

if rg -qF '| Green runs | `CI` and `Installer Smoke` have successful remote runs on the remote default branch. |' "$RUNBOOK"; then
  pass "release runbook requires default-branch green runs"
else
  fail "release runbook requires default-branch green runs"
fi

if rg -qF '| User journey pack | `docs/runbooks/public-user-journey-pack.md` maps every public asset' "$RUNBOOK" \
  && rg -qF 'user-journey-pack-validation.json' "$RUNBOOK" \
  && rg -qF 'scripts/validate_user_journey_pack.py --json' "$RUNBOOK"; then
  pass "release runbook requires user journey pack validation"
else
  fail "release runbook requires user journey pack validation"
fi

if rg -qF 'repo-view.json' "$RUNBOOK" \
  && rg -qF 'remote-workflows.json' "$RUNBOOK" \
  && rg -qF 'remote-runs.json' "$RUNBOOK" \
  && rg -qF 'external-review-release.json' "$RUNBOOK" \
  && rg -qF 'release-signoff.receipt.json' "$RUNBOOK" \
  && rg -qF 'website-probe.json' "$RUNBOOK" \
  && rg -qF 'install-probe.json' "$RUNBOOK" \
  && rg -qF 'install-sha256-probe.json' "$RUNBOOK" \
  && rg -qF 'install-sha256.actual' "$RUNBOOK" \
  && rg -qF 'publication-readiness-replay.json' "$RUNBOOK" \
  && rg -qF 'cutover-receipts-validation.json' "$RUNBOOK"; then
  pass "release runbook lists full cutover receipt bundle"
else
  fail "release runbook lists full cutover receipt bundle"
fi

if rg -qF '[`release-cutover-authorization.md`](release-cutover-authorization.md)' "$RUNBOOK"; then
  pass "release runbook references cutover authorization packet"
else
  fail "release runbook references cutover authorization packet"
fi

if rg -qF 'Agents must not make the repository public, push the' "$RUNBOOK" \
  && rg -qF 'release tag, deploy the site, or create an approved signoff' "$RUNBOOK"; then
  pass "release runbook states no-agent-publication boundary"
else
  fail "release runbook states no-agent-publication boundary"
fi

for blocker_code in \
  remote_repo_private \
  remote_workflows_missing \
  remote_green_runs_missing \
  github_release_missing_or_draft \
  github_release_assets_missing \
  external_review_gate_blocked \
  website_unavailable \
  website_content_stale \
  install_proxy_checksum_mismatch \
  joshua_release_signoff_missing; do
  if rg -qF "\`$blocker_code\`" "$PUBLIC_CUTOVER"; then
    pass "public cutover runbook covers ${blocker_code}"
  else
    fail "public cutover runbook covers ${blocker_code}"
  fi
done

if [[ -f "$CUTOVER_PACKET" ]]; then
  pass "release cutover authorization packet exists"
elif [[ -d "$CUTOVER_PACKET_DIR" ]]; then
  fail "release cutover authorization packet exists"
else
  pass "private cutover packet omitted from public export"
fi

if [[ -f "$CUTOVER_PACKET" ]]; then
  for blocker_code in \
    remote_repo_private \
    remote_workflows_missing \
    remote_green_runs_missing \
    github_release_missing_or_draft \
    github_release_assets_missing \
    external_review_gate_blocked \
    website_unavailable \
    website_content_stale \
    install_proxy_checksum_mismatch \
    joshua_release_signoff_missing; do
    if rg -qF "\`$blocker_code\`" "$CUTOVER_PACKET"; then
      pass "cutover packet covers ${blocker_code}"
    else
      fail "cutover packet covers ${blocker_code}"
    fi
  done

  if rg -qF 'must not make the repository public' "$CUTOVER_PACKET" \
    && rg -qF 'push the release tag' "$CUTOVER_PACKET" \
    && rg -qF 'create an approved signoff' "$CUTOVER_PACKET"; then
    pass "cutover packet states no-agent-publication boundary"
  else
    fail "cutover packet states no-agent-publication boundary"
  fi

  if rg -qF 'A fixture, local staging export, or staging review packet is not' "$CUTOVER_PACKET"; then
    pass "cutover packet rejects proxy completion evidence"
  else
    fail "cutover packet rejects proxy completion evidence"
  fi
fi

if [[ -s "$PUBLIC_CUTOVER" ]] && rg -qF 'A fixture, local staging export, staging review packet, or' "$PUBLIC_CUTOVER"; then
  pass "public cutover runbook rejects proxy completion evidence"
else
  fail "public cutover runbook rejects proxy completion evidence"
fi

if rg -qF 'diff -u install-sha256.expected install-sha256.actual' "$PUBLIC_CUTOVER"; then
  pass "public cutover runbook compares install checksums"
else
  fail "public cutover runbook compares install checksums"
fi

if rg -qF 'publication-readiness.json' "$PUBLIC_CUTOVER" \
  && rg -qF 'publication-readiness-release.json' "$PUBLIC_CUTOVER" \
  && rg -qF 'user-journey-pack-validation.json' "$PUBLIC_CUTOVER" \
  && rg -qF 'scripts/validate_user_journey_pack.py --json > user-journey-pack-validation.json' "$PUBLIC_CUTOVER" \
  && rg -qF 'live-site-probe.json' "$PUBLIC_CUTOVER" \
  && rg -qF 'scripts/live_site_probe.py --base-url https://flywheel.zeststream.ai/ --json' "$PUBLIC_CUTOVER" \
  && rg -qF 'website-probe.json' "$PUBLIC_CUTOVER" \
  && rg -qF 'install-probe.json' "$PUBLIC_CUTOVER" \
  && rg -qF 'install-sha256-probe.json' "$PUBLIC_CUTOVER" \
  && rg -qF 'publication-readiness-replay.json' "$PUBLIC_CUTOVER" \
  && rg -qF 'cutover-receipts-validation.json' "$PUBLIC_CUTOVER" \
  && rg -qF 'scripts/validate_cutover_receipts.py --receipt-dir . --release --json' "$PUBLIC_CUTOVER" \
  && rg -qF -- '--repo-view-json repo-view.json' "$PUBLIC_CUTOVER" \
  && rg -qF -- '--workflows-json remote-workflows.json' "$PUBLIC_CUTOVER" \
  && rg -qF -- '--runs-json remote-runs.json' "$PUBLIC_CUTOVER" \
  && rg -qF -- '--release-json release-view.json' "$PUBLIC_CUTOVER" \
  && rg -qF -- '--review-json external-review-release.json' "$PUBLIC_CUTOVER" \
  && rg -qF -- '--website-probe-json website-probe.json' "$PUBLIC_CUTOVER" \
  && rg -qF -- '--install-probe-json install-probe.json' "$PUBLIC_CUTOVER" \
  && rg -qF -- '--install-sha256-probe-json install-sha256-probe.json' "$PUBLIC_CUTOVER" \
  && rg -qF -- '--signoff-json release-signoff.receipt.json' "$PUBLIC_CUTOVER" \
  && rg -qF '.status == "pass" and (.blockers | length) == 0' "$PUBLIC_CUTOVER"; then
  pass "public cutover runbook replays saved receipt bundle"
else
  fail "public cutover runbook replays saved receipt bundle"
fi

if [[ -f "$CUTOVER_PACKET" ]]; then
  if rg -qF 'diff -u install-sha256.expected install-sha256.actual' "$CUTOVER_PACKET"; then
    pass "cutover packet compares install checksums"
  else
    fail "cutover packet compares install checksums"
  fi

  if rg -qF 'publication-readiness-release.json' "$CUTOVER_PACKET" \
    && rg -qF 'website-probe.json' "$CUTOVER_PACKET" \
    && rg -qF 'install-probe.json' "$CUTOVER_PACKET" \
    && rg -qF 'install-sha256-probe.json' "$CUTOVER_PACKET" \
    && rg -qF 'publication-readiness-replay.json' "$CUTOVER_PACKET" \
    && rg -qF 'cutover-receipts-validation.json' "$CUTOVER_PACKET" \
    && rg -qF 'scripts/validate_cutover_receipts.py --receipt-dir . --release --json' "$CUTOVER_PACKET" \
    && rg -qF -- '--repo-view-json repo-view.json' "$CUTOVER_PACKET" \
    && rg -qF -- '--workflows-json remote-workflows.json' "$CUTOVER_PACKET" \
    && rg -qF -- '--runs-json remote-runs.json' "$CUTOVER_PACKET" \
    && rg -qF -- '--release-json release-view.json' "$CUTOVER_PACKET" \
    && rg -qF -- '--review-json external-review-release.json' "$CUTOVER_PACKET" \
    && rg -qF -- '--website-probe-json website-probe.json' "$CUTOVER_PACKET" \
    && rg -qF -- '--install-probe-json install-probe.json' "$CUTOVER_PACKET" \
    && rg -qF -- '--install-sha256-probe-json install-sha256-probe.json' "$CUTOVER_PACKET" \
    && rg -qF -- '--signoff-json release-signoff.receipt.json' "$CUTOVER_PACKET"; then
    pass "cutover packet replays saved receipt bundle"
  else
    fail "cutover packet replays saved receipt bundle"
  fi
fi

if rg -qF -- '--json workflowName,status,conclusion,headBranch > remote-runs.json' "$PUBLIC_CUTOVER" \
  && [[ ! -f "$CUTOVER_PACKET" || "$(rg -cF -- '--json workflowName,status,conclusion,headBranch > remote-runs.json' "$CUTOVER_PACKET")" -ge 1 ]]; then
  pass "cutover closeout captures remote run headBranch"
else
  fail "cutover closeout captures remote run headBranch"
fi

if rg -qF -- 'gh repo view JYeswak/flywheel --json nameWithOwner,visibility,isPrivate,defaultBranchRef,url > repo-view.json' "$PUBLIC_CUTOVER" \
  && rg -qF -- 'gh api repos/JYeswak/flywheel/actions/workflows > remote-workflows.json' "$PUBLIC_CUTOVER" \
  && [[ ! -f "$CUTOVER_PACKET" || "$(rg -cF -- 'repo-view.json' "$CUTOVER_PACKET")" -ge 1 ]] \
  && [[ ! -f "$CUTOVER_PACKET" || "$(rg -cF -- 'remote-workflows.json' "$CUTOVER_PACKET")" -ge 1 ]]; then
  pass "cutover closeout captures repo and workflow receipts"
else
  fail "cutover closeout captures repo and workflow receipts"
fi

if rg -qF -- 'python3 scripts/validate_external_review.py --release --json > external-review-release.json' "$PUBLIC_CUTOVER" \
  && rg -qF -- "release-signoff.receipt.json" "$PUBLIC_CUTOVER" \
  && [[ ! -f "$CUTOVER_PACKET" || "$(rg -cF -- 'external-review-release.json' "$CUTOVER_PACKET")" -ge 1 ]] \
  && [[ ! -f "$CUTOVER_PACKET" || "$(rg -cF -- 'release-signoff.receipt.json' "$CUTOVER_PACKET")" -ge 1 ]]; then
  pass "cutover closeout captures review and signoff receipts"
else
  fail "cutover closeout captures review and signoff receipts"
fi

cat >"$TMP/repo-public.json" <<'JSON'
{"nameWithOwner":"JYeswak/flywheel","url":"https://github.com/JYeswak/flywheel","visibility":"PUBLIC","isPrivate":false,"defaultBranchRef":{"name":"master"}}
JSON
cat >"$TMP/workflows.json" <<'JSON'
[{"name":"CI"},{"name":"Installer Smoke"},{"name":"Release"},{"name":"Site Deploy"}]
JSON
cat >"$TMP/runs-green.json" <<'JSON'
[{"workflowName":"CI","status":"completed","conclusion":"success","headBranch":"master"},{"workflowName":"Installer Smoke","status":"completed","conclusion":"success","headBranch":"master"}]
JSON
cat >"$TMP/runs-green-feature.json" <<'JSON'
[{"workflowName":"CI","status":"completed","conclusion":"success","headBranch":"feature/publication"},{"workflowName":"Installer Smoke","status":"completed","conclusion":"success","headBranch":"feature/publication"}]
JSON
release_tag="v0.2.1"
release_tarball="flywheel-${release_tag}.tar.gz"
jq_digest="sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
jq -nc --arg tag "$release_tag" --arg tarball "$release_tarball" --arg digest "$jq_digest" '{
  tagName: $tag,
  isDraft: false,
  isPrerelease: false,
  url: ("https://github.com/JYeswak/flywheel/releases/tag/" + $tag),
  assets: [
    {name:"install.sh",state:"uploaded",size:1000,digest:$digest},
    {name:"install.sh.sha256",state:"uploaded",size:100,digest:$digest},
    {name:"SHA256SUMS",state:"uploaded",size:500,digest:$digest},
    {name:$tarball,state:"uploaded",size:1000,digest:$digest},
    {name:($tarball + ".sha256"),state:"uploaded",size:100,digest:$digest}
  ]
}' >"$TMP/release.json"
jq -nc --arg tag "$release_tag" --arg tarball "$release_tarball" --arg digest "$jq_digest" '{
  tagName: $tag,
  isDraft: false,
  isPrerelease: true,
  url: ("https://github.com/JYeswak/flywheel/releases/tag/" + $tag),
  assets: [
    {name:"install.sh",state:"uploaded",size:1000,digest:$digest},
    {name:"install.sh.sha256",state:"uploaded",size:100,digest:$digest},
    {name:"SHA256SUMS",state:"uploaded",size:500,digest:$digest},
    {name:$tarball,state:"uploaded",size:1000,digest:$digest},
    {name:($tarball + ".sha256"),state:"uploaded",size:100,digest:$digest}
  ]
}' >"$TMP/release-prerelease.json"
jq -nc --arg tag "$release_tag" --arg tarball "$release_tarball" --arg digest "$jq_digest" '{
  tagName: $tag,
  isDraft: false,
  isPrerelease: false,
  url: ("https://github.com/JYeswak/flywheel/releases/tag/" + $tag),
  assets: [
    {name:"install.sh",state:"uploaded",size:0,digest:$digest},
    {name:"install.sh.sha256",state:"uploaded",size:100,digest:$digest},
    {name:"SHA256SUMS",state:"uploaded",size:500,digest:$digest},
    {name:$tarball,state:"uploaded",size:1000,digest:$digest},
    {name:($tarball + ".sha256"),state:"uploaded",size:100,digest:$digest}
  ]
}' >"$TMP/release-empty-asset.json"
jq -nc --arg tag "$release_tag" --arg tarball "$release_tarball" --arg digest "$jq_digest" '{
  tagName: $tag,
  isDraft: false,
  isPrerelease: false,
  url: ("https://github.com/JYeswak/flywheel/releases/tag/" + $tag),
  assets: [
    {name:"install.sh",state:"uploaded",size:1000,digest:"sha256:not-a-real-digest"},
    {name:"install.sh.sha256",state:"uploaded",size:100,digest:$digest},
    {name:"SHA256SUMS",state:"uploaded",size:500,digest:$digest},
    {name:$tarball,state:"uploaded",size:1000,digest:$digest},
    {name:($tarball + ".sha256"),state:"uploaded",size:100,digest:$digest}
  ]
}' >"$TMP/release-bad-digest.json"
jq -nc --arg tag "$release_tag" --arg tarball "$release_tarball" --arg digest "$jq_digest" '{
  tagName: $tag,
  isDraft: false,
  isPrerelease: false,
  url: ("https://github.com/JYeswak/flywheel/releases/tag/" + $tag),
  assets: [
    {name:"install.sh",state:"uploaded",size:1000,digest:$digest},
    {name:"install.sh",state:"uploaded",size:1000,digest:$digest},
    {name:"install.sh.sha256",state:"uploaded",size:100,digest:$digest},
    {name:"SHA256SUMS",state:"uploaded",size:500,digest:$digest},
    {name:$tarball,state:"uploaded",size:1000,digest:$digest},
    {name:($tarball + ".sha256"),state:"uploaded",size:100,digest:$digest}
  ]
}' >"$TMP/release-duplicate-asset.json"
install_hash="$(printf 'install-body' | shasum -a 256 | awk '{print $1}')"
website_current_text="$(printf 'Buy back the hours hiding between your tools. I help SMB owners buy their time back. 25+ years in operations. The Yuzu Method starts with one safe first fix. %02500d No CRM connection. No auto-response. No follow-up.' 0)"
jq -nc --arg body "$website_current_text" '{url:"https://flywheel.zeststream.ai/",status_code:200,body_text:$body,body_sha256:"unused"}' >"$TMP/website-ok.json"
jq -nc '{url:"https://flywheel.zeststream.ai/",status_code:200,body_text:"Old Flywheel placeholder",body_sha256:"unused"}' >"$TMP/website-stale.json"
jq -nc --arg hash "$install_hash" '{url:"https://flywheel.zeststream.ai/install.sh",status_code:200,body_sha256:$hash,body_text:"install-body"}' >"$TMP/install-ok.json"
jq -nc --arg hash "$install_hash" '{url:"https://flywheel.zeststream.ai/install.sh.sha256",status_code:200,body_sha256:"unused",body_text:($hash + "  install.sh\n")}' >"$TMP/install-sha-ok.json"
cat >"$TMP/signoff.json" <<'JSON'
{"schema_version":"flywheel.release_signoff.v0","status":"approved","approver":"Joshua Nowak","tag":"v0.2.1","remote":"JYeswak/flywheel","signed_at":"2026-05-13T00:00:00Z"}
JSON
cat >"$TMP/signoff-pending.json" <<'JSON'
{"schema_version":"flywheel.release_signoff.v0","status":"pending","approver":"Joshua Nowak","tag":"v0.2.1","remote":"JYeswak/flywheel","signed_at":""}
JSON
cat >"$TMP/signoff-alias.json" <<'JSON'
{"schema_version":"flywheel.release_signoff.v0","status":"approved","approver":"Josh","tag":"v0.2.1","remote":"JYeswak/flywheel","signed_at":"2026-05-13T00:00:00Z"}
JSON
cat >"$TMP/signoff-bad-ts.json" <<'JSON'
{"schema_version":"flywheel.release_signoff.v0","status":"approved","approver":"Joshua Nowak","tag":"v0.2.1","remote":"JYeswak/flywheel","signed_at":"not-a-timestamp"}
JSON
cat >"$TMP/signoff-missing-schema.json" <<'JSON'
{"status":"approved","approver":"Joshua Nowak","tag":"v0.2.1","remote":"JYeswak/flywheel","signed_at":"2026-05-13T00:00:00Z"}
JSON
cat >"$TMP/review-pass.json" <<'JSON'
{"schema_version":"flywheel.external_review_gate.v0","status":"pass","valid_review_count":2,"distinct_reviewer_count":2,"errors":[]}
JSON
cat >"$TMP/review-blocked.json" <<'JSON'
{"schema_version":"flywheel.external_review_gate.v0","status":"blocked","valid_review_count":0,"distinct_reviewer_count":0,"errors":[{"code":"review_log_missing"}]}
JSON

if python3 "$SCRIPT" --repo "$ROOT" --repo-view-json "$TMP/repo-public.json" --workflows-json "$TMP/workflows.json" --runs-json "$TMP/runs-green.json" --release-json "$TMP/release.json" --review-json "$TMP/review-pass.json" --website-probe-json "$TMP/website-ok.json" --install-probe-json "$TMP/install-ok.json" --install-sha256-probe-json "$TMP/install-sha-ok.json" --signoff-json "$TMP/signoff.json" --release --json >"$TMP/pass.out"; then
  if jq -e '.status == "pass" and (.blockers | length) == 0' "$TMP/pass.out" >/dev/null; then
    pass "public fixture passes"
  else
    fail "public fixture envelope"
  fi
else
  fail "public fixture command"
fi

set +e
python3 "$SCRIPT" --repo "$ROOT" --repo-view-json "$TMP/repo-public.json" --workflows-json "$TMP/workflows.json" --runs-json "$TMP/runs-green.json" --release-json "$TMP/release.json" --review-json "$TMP/review-pass.json" --website-probe-json "$TMP/website-stale.json" --install-probe-json "$TMP/install-ok.json" --install-sha256-probe-json "$TMP/install-sha-ok.json" --signoff-json "$TMP/signoff.json" --release --json >"$TMP/stale-site.out"
stale_site_rc=$?
set -e
if [[ "$stale_site_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "website_content_stale" and (.missing | contains("I help SMB owners buy their time back.")))' "$TMP/stale-site.out" >/dev/null; then
  pass "stale website fixture remains blocked"
else
  fail "stale website fixture remains blocked rc=${stale_site_rc}"
fi

set +e
python3 "$SCRIPT" --repo "$ROOT" --repo-view-json "$TMP/repo-public.json" --workflows-json "$TMP/workflows.json" --runs-json "$TMP/runs-green.json" --release-json "$TMP/release.json" --review-json "$TMP/review-pass.json" --website-probe-json "$TMP/website-ok.json" --install-probe-json "$TMP/install-ok.json" --install-sha256-probe-json "$TMP/install-sha-ok.json" --signoff-json "$TMP/signoff-pending.json" --release --json >"$TMP/pending-signoff.out"
pending_signoff_rc=$?
set -e
if [[ "$pending_signoff_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "joshua_release_signoff_missing")' "$TMP/pending-signoff.out" >/dev/null; then
  pass "pending signoff fixture remains blocked"
else
  fail "pending signoff fixture remains blocked rc=${pending_signoff_rc}"
fi

if jq -e 'any(.next_actions[]?; .code == "joshua_release_signoff_missing" and .owner == "Joshua" and (.command | contains("release-signoff.template.json")))' "$TMP/pending-signoff.out" >/dev/null; then
  pass "pending signoff includes actionable next action"
else
  fail "pending signoff includes actionable next action"
fi

for fixture in signoff-alias signoff-bad-ts signoff-missing-schema; do
  set +e
  python3 "$SCRIPT" --repo "$ROOT" --repo-view-json "$TMP/repo-public.json" --workflows-json "$TMP/workflows.json" --runs-json "$TMP/runs-green.json" --release-json "$TMP/release.json" --review-json "$TMP/review-pass.json" --website-probe-json "$TMP/website-ok.json" --install-probe-json "$TMP/install-ok.json" --install-sha256-probe-json "$TMP/install-sha-ok.json" --signoff-json "$TMP/${fixture}.json" --release --json >"$TMP/${fixture}.out"
  signoff_fixture_rc=$?
  set -e
  if [[ "$signoff_fixture_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "joshua_release_signoff_missing")' "$TMP/${fixture}.out" >/dev/null; then
    pass "${fixture} remains blocked"
  else
    fail "${fixture} remains blocked rc=${signoff_fixture_rc}"
  fi
done

set +e
python3 "$SCRIPT" --repo "$ROOT" --repo-view-json "$TMP/repo-public.json" --workflows-json "$TMP/workflows.json" --runs-json "$TMP/runs-green.json" --release-json "$TMP/release.json" --review-json "$TMP/review-blocked.json" --website-probe-json "$TMP/website-ok.json" --install-probe-json "$TMP/install-ok.json" --install-sha256-probe-json "$TMP/install-sha-ok.json" --signoff-json "$TMP/signoff.json" --release --json >"$TMP/blocked-review.out"
blocked_review_rc=$?
set -e
if [[ "$blocked_review_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "external_review_gate_blocked")' "$TMP/blocked-review.out" >/dev/null; then
  pass "blocked external review fixture remains blocked"
else
  fail "blocked external review fixture remains blocked rc=${blocked_review_rc}"
fi

set +e
python3 "$SCRIPT" --repo "$ROOT" --repo-view-json "$TMP/repo-public.json" --workflows-json "$TMP/workflows.json" --runs-json "$TMP/runs-green-feature.json" --release-json "$TMP/release.json" --review-json "$TMP/review-pass.json" --website-probe-json "$TMP/website-ok.json" --install-probe-json "$TMP/install-ok.json" --install-sha256-probe-json "$TMP/install-sha-ok.json" --signoff-json "$TMP/signoff.json" --release --json >"$TMP/feature-runs.out"
feature_runs_rc=$?
set -e
if [[ "$feature_runs_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "remote_green_runs_missing")' "$TMP/feature-runs.out" >/dev/null; then
  pass "feature-branch green runs do not satisfy remote green gate"
else
  fail "feature-branch green runs do not satisfy remote green gate rc=${feature_runs_rc}"
fi

set +e
python3 "$SCRIPT" --repo "$ROOT" --repo-view-json "$TMP/repo-public.json" --workflows-json "$TMP/workflows.json" --runs-json "$TMP/runs-green.json" --release-json "$TMP/release-prerelease.json" --review-json "$TMP/review-pass.json" --website-probe-json "$TMP/website-ok.json" --install-probe-json "$TMP/install-ok.json" --install-sha256-probe-json "$TMP/install-sha-ok.json" --signoff-json "$TMP/signoff.json" --release --json >"$TMP/prerelease.out"
prerelease_rc=$?
set -e
if [[ "$prerelease_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "github_release_missing_or_draft")' "$TMP/prerelease.out" >/dev/null; then
  pass "prerelease fixture remains blocked"
else
  fail "prerelease fixture remains blocked rc=${prerelease_rc}"
fi

set +e
python3 "$SCRIPT" --repo "$ROOT" --repo-view-json "$TMP/repo-public.json" --workflows-json "$TMP/workflows.json" --runs-json "$TMP/runs-green.json" --release-json "$TMP/release-empty-asset.json" --review-json "$TMP/review-pass.json" --website-probe-json "$TMP/website-ok.json" --install-probe-json "$TMP/install-ok.json" --install-sha256-probe-json "$TMP/install-sha-ok.json" --signoff-json "$TMP/signoff.json" --release --json >"$TMP/empty-asset.out"
empty_asset_rc=$?
set -e
if [[ "$empty_asset_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "github_release_assets_missing" and (.invalid | contains("install.sh")))' "$TMP/empty-asset.out" >/dev/null; then
  pass "empty release asset fixture remains blocked"
else
  fail "empty release asset fixture remains blocked rc=${empty_asset_rc}"
fi

set +e
python3 "$SCRIPT" --repo "$ROOT" --repo-view-json "$TMP/repo-public.json" --workflows-json "$TMP/workflows.json" --runs-json "$TMP/runs-green.json" --release-json "$TMP/release-bad-digest.json" --review-json "$TMP/review-pass.json" --website-probe-json "$TMP/website-ok.json" --install-probe-json "$TMP/install-ok.json" --install-sha256-probe-json "$TMP/install-sha-ok.json" --signoff-json "$TMP/signoff.json" --release --json >"$TMP/bad-digest.out"
bad_digest_rc=$?
set -e
if [[ "$bad_digest_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "github_release_assets_missing" and (.invalid | contains("install.sh")))' "$TMP/bad-digest.out" >/dev/null; then
  pass "bad release asset digest fixture remains blocked"
else
  fail "bad release asset digest fixture remains blocked rc=${bad_digest_rc}"
fi

set +e
python3 "$SCRIPT" --repo "$ROOT" --repo-view-json "$TMP/repo-public.json" --workflows-json "$TMP/workflows.json" --runs-json "$TMP/runs-green.json" --release-json "$TMP/release-duplicate-asset.json" --review-json "$TMP/review-pass.json" --website-probe-json "$TMP/website-ok.json" --install-probe-json "$TMP/install-ok.json" --install-sha256-probe-json "$TMP/install-sha-ok.json" --signoff-json "$TMP/signoff.json" --release --json >"$TMP/duplicate-asset.out"
duplicate_asset_rc=$?
set -e
if [[ "$duplicate_asset_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "github_release_assets_missing" and (.invalid | contains("install.sh")))' "$TMP/duplicate-asset.out" >/dev/null; then
  pass "duplicate release asset fixture remains blocked"
else
  fail "duplicate release asset fixture remains blocked rc=${duplicate_asset_rc}"
fi

cat >"$TMP/repo-private.json" <<'JSON'
{"nameWithOwner":"JYeswak/flywheel","url":"https://github.com/JYeswak/flywheel","visibility":"PRIVATE","isPrivate":true,"defaultBranchRef":{"name":"master"}}
JSON
printf '[]\n' >"$TMP/empty.json"
jq -nc '{url:"https://flywheel.zeststream.ai/",status_code:404,body_text:"",body_sha256:""}' >"$TMP/website-bad.json"
jq -nc '{url:"https://flywheel.zeststream.ai/install.sh",status_code:200,body_sha256:"actual",body_text:""}' >"$TMP/install-bad.json"
jq -nc '{url:"https://flywheel.zeststream.ai/install.sh.sha256",status_code:200,body_sha256:"unused",body_text:"expected  install.sh\n"}' >"$TMP/install-sha-bad.json"

if python3 "$SCRIPT" --repo "$ROOT" --repo-view-json "$TMP/repo-private.json" --workflows-json "$TMP/empty.json" --runs-json "$TMP/empty.json" --release-json "$TMP/empty.json" --review-json "$TMP/review-blocked.json" --website-probe-json "$TMP/website-bad.json" --install-probe-json "$TMP/install-bad.json" --install-sha256-probe-json "$TMP/install-sha-bad.json" --signoff-json "$TMP/missing-signoff.json" --release --json >"$TMP/blocked.out"; then
  fail "private fixture must fail release"
else
  if jq -e '.status == "blocked" and any(.blockers[]?; .code == "remote_repo_private") and any(.blockers[]?; .code == "remote_workflows_missing" and (.missing | contains("Site Deploy"))) and any(.blockers[]?; .code == "remote_green_runs_missing") and any(.blockers[]?; .code == "github_release_missing_or_draft") and any(.blockers[]?; .code == "github_release_assets_missing") and any(.blockers[]?; .code == "website_unavailable") and any(.blockers[]?; .code == "install_proxy_checksum_mismatch") and any(.blockers[]?; .code == "joshua_release_signoff_missing") and any(.blockers[]?; .code == "external_review_gate_blocked")' "$TMP/blocked.out" >/dev/null; then
    pass "private remote blockers explicit"
  else
    fail "private remote blocker shape"
  fi
fi

missing_public_cutover_codes=()
while IFS= read -r blocker_code; do
  if ! rg -qF "\`$blocker_code\`" "$PUBLIC_CUTOVER"; then
    missing_public_cutover_codes+=("$blocker_code")
  fi
done < <(jq -r '.blockers[]?.code' "$TMP/blocked.out" | sort -u)
if [[ "${#missing_public_cutover_codes[@]}" -eq 0 ]]; then
  pass "public cutover runbook covers every blocked fixture code"
else
  fail "public cutover runbook missing blocked fixture codes: ${missing_public_cutover_codes[*]}"
fi

if [[ -f "$CUTOVER_PACKET" ]]; then
  missing_private_cutover_codes=()
  while IFS= read -r blocker_code; do
    if ! rg -qF "\`$blocker_code\`" "$CUTOVER_PACKET"; then
      missing_private_cutover_codes+=("$blocker_code")
    fi
  done < <(jq -r '.blockers[]?.code' "$TMP/blocked.out" | sort -u)
  if [[ "${#missing_private_cutover_codes[@]}" -eq 0 ]]; then
    pass "private cutover packet covers every blocked fixture code"
  else
    fail "private cutover packet missing blocked fixture codes: ${missing_private_cutover_codes[*]}"
  fi
else
  pass "private cutover packet coverage omitted from public export"
fi

if jq -e '
  (.next_actions | length) >= 9
  and any(.next_actions[]?; .code == "remote_repo_private" and (.command | contains("gh repo edit")))
  and any(.next_actions[]?; .code == "remote_green_runs_missing" and (.command | contains("headBranch")))
  and any(.next_actions[]?; .code == "github_release_assets_missing" and (.command | contains("isPrerelease")))
  and any(.next_actions[]?; .code == "external_review_gate_blocked" and (.command | contains("validate_external_review.py")))
  and any(.next_actions[]?; .code == "install_proxy_checksum_mismatch" and (.command | contains("install.sh.sha256")) and (.command | contains("test \"$actual\" = \"$expected\"")))
' "$TMP/blocked.out" >/dev/null; then
  pass "blocked fixture includes actionable next actions"
else
  fail "blocked fixture includes actionable next actions"
fi

if jq -e '
  all(.next_actions[]?; .blocker_code == .code and (.blocker_code | length) > 0)
  and any(.next_actions[]?; .blocker_code == "remote_repo_private")
  and any(.next_actions[]?; .blocker_code == "joshua_release_signoff_missing")
' "$TMP/blocked.out" >/dev/null; then
  pass "blocked fixture next actions include blocker_code alias"
else
  fail "blocked fixture next actions include blocker_code alias"
fi

if jq -e '
  all(.blockers[]?; (.owner | length) > 0 and (.summary | length) > 0 and (.next_action | length) > 0 and (.command | length) > 0)
  and any(.blockers[]?; .code == "remote_repo_private" and .owner == "Joshua" and (.command | contains("gh repo edit")))
' "$TMP/blocked.out" >/dev/null; then
  pass "blocked fixture includes inline blocker actions"
else
  fail "blocked fixture includes inline blocker actions"
fi

set +e
python3 "$SCRIPT" --repo "$ROOT" --skip-remote --json >"$TMP/skip.out"
skip_rc=$?
set -e
if [[ "$skip_rc" -eq 20 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "remote_probe_skipped")' "$TMP/skip.out" >/dev/null; then
  pass "skip remote stays blocked"
else
  fail "skip remote blocked shape rc=${skip_rc}"
fi

manifest_repo="$TMP/manifest-repo"
python3 - "$SCRIPT" "$manifest_repo" <<'PY'
import importlib.util
import sys
from pathlib import Path

script = Path(sys.argv[1])
repo = Path(sys.argv[2])
spec = importlib.util.spec_from_file_location("publication_readiness", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

for rel in module.REQUIRED_LOCAL_FILES:
    path = repo / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("fixture\n")

(repo / "scripts/journey-smoke.sh").unlink()
PY

set +e
python3 "$SCRIPT" --repo "$manifest_repo" --skip-remote --json >"$TMP/manifest-missing.out"
manifest_missing_rc=$?
set -e
if [[ "$manifest_missing_rc" -eq 20 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "local_required_file_missing" and .path == "scripts/journey-smoke.sh")' "$TMP/manifest-missing.out" >/dev/null; then
  pass "first-run manifest files are required"
else
  fail "first-run manifest files are required rc=${manifest_missing_rc}"
fi

agent_lane_repo="$TMP/agent-lane-repo"
python3 - "$SCRIPT" "$agent_lane_repo" <<'PY'
import importlib.util
import sys
from pathlib import Path

script = Path(sys.argv[1])
repo = Path(sys.argv[2])
spec = importlib.util.spec_from_file_location("publication_readiness", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

for rel in module.REQUIRED_LOCAL_FILES:
    path = repo / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("fixture\n")

(repo / "scripts/agent-lane-probe.sh").unlink()
PY

set +e
python3 "$SCRIPT" --repo "$agent_lane_repo" --skip-remote --json >"$TMP/agent-lane-missing.out"
agent_lane_missing_rc=$?
set -e
if [[ "$agent_lane_missing_rc" -eq 20 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "local_required_file_missing" and .path == "scripts/agent-lane-probe.sh")' "$TMP/agent-lane-missing.out" >/dev/null; then
  pass "agent-lane manifest files are required"
else
  fail "agent-lane manifest files are required rc=${agent_lane_missing_rc}"
fi

agent_lane_receipt_repo="$TMP/agent-lane-receipt-repo"
python3 - "$SCRIPT" "$agent_lane_receipt_repo" <<'PY'
import importlib.util
import sys
from pathlib import Path

script = Path(sys.argv[1])
repo = Path(sys.argv[2])
spec = importlib.util.spec_from_file_location("publication_readiness", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

for rel in module.REQUIRED_LOCAL_FILES:
    path = repo / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("fixture\n")

(repo / "receipts/agent-lanes/codex.json").unlink()
PY

set +e
python3 "$SCRIPT" --repo "$agent_lane_receipt_repo" --skip-remote --json >"$TMP/agent-lane-receipt-missing.out"
agent_lane_receipt_missing_rc=$?
set -e
if [[ "$agent_lane_receipt_missing_rc" -eq 20 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "local_required_file_missing" and .path == "receipts/agent-lanes/codex.json")' "$TMP/agent-lane-receipt-missing.out" >/dev/null; then
  pass "agent-lane blocker receipts are required"
else
  fail "agent-lane blocker receipts are required rc=${agent_lane_receipt_missing_rc}"
fi

workflow_contract_repo="$TMP/workflow-contract-repo"
python3 - "$SCRIPT" "$workflow_contract_repo" <<'PY'
import importlib.util
import sys
from pathlib import Path

script = Path(sys.argv[1])
repo = Path(sys.argv[2])
spec = importlib.util.spec_from_file_location("publication_readiness", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

for rel in module.REQUIRED_LOCAL_FILES:
    path = repo / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("fixture\n")

(repo / "tests/github-workflows.sh").unlink()
PY

set +e
python3 "$SCRIPT" --repo "$workflow_contract_repo" --skip-remote --json >"$TMP/workflow-contract-missing.out"
workflow_contract_missing_rc=$?
set -e
if [[ "$workflow_contract_missing_rc" -eq 20 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "local_required_file_missing" and .path == "tests/github-workflows.sh")' "$TMP/workflow-contract-missing.out" >/dev/null; then
  pass "workflow contract manifest files are required"
else
  fail "workflow contract manifest files are required rc=${workflow_contract_missing_rc}"
fi

journey_pack_repo="$TMP/journey-pack-repo"
python3 - "$SCRIPT" "$journey_pack_repo" <<'PY'
import importlib.util
import sys
from pathlib import Path

script = Path(sys.argv[1])
repo = Path(sys.argv[2])
spec = importlib.util.spec_from_file_location("publication_readiness", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

for rel in module.REQUIRED_LOCAL_FILES:
    path = repo / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("fixture\n")

(repo / "docs/runbooks/public-user-journey-pack.md").unlink()
PY

set +e
python3 "$SCRIPT" --repo "$journey_pack_repo" --skip-remote --json >"$TMP/journey-pack-missing.out"
journey_pack_missing_rc=$?
set -e
if [[ "$journey_pack_missing_rc" -eq 20 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "local_required_file_missing" and .path == "docs/runbooks/public-user-journey-pack.md")' "$TMP/journey-pack-missing.out" >/dev/null; then
  pass "user journey pack manifest file is required"
else
  fail "user journey pack manifest file is required rc=${journey_pack_missing_rc}"
fi

journey_pack_validator_repo="$TMP/journey-pack-validator-repo"
python3 - "$SCRIPT" "$journey_pack_validator_repo" <<'PY'
import importlib.util
import sys
from pathlib import Path

script = Path(sys.argv[1])
repo = Path(sys.argv[2])
spec = importlib.util.spec_from_file_location("publication_readiness", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

for rel in module.REQUIRED_LOCAL_FILES:
    path = repo / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("fixture\n")

(repo / "scripts/validate_user_journey_pack.py").unlink()
PY

set +e
python3 "$SCRIPT" --repo "$journey_pack_validator_repo" --skip-remote --json >"$TMP/journey-pack-validator-missing.out"
journey_pack_validator_missing_rc=$?
set -e
if [[ "$journey_pack_validator_missing_rc" -eq 20 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "local_required_file_missing" and .path == "scripts/validate_user_journey_pack.py")' "$TMP/journey-pack-validator-missing.out" >/dev/null; then
  pass "user journey pack validator is required"
else
  fail "user journey pack validator is required rc=${journey_pack_validator_missing_rc}"
fi

verifier_impl_repo="$TMP/verifier-impl-repo"
python3 - "$SCRIPT" "$verifier_impl_repo" <<'PY'
import importlib.util
import sys
from pathlib import Path

script = Path(sys.argv[1])
repo = Path(sys.argv[2])
spec = importlib.util.spec_from_file_location("publication_readiness", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

for rel in module.REQUIRED_LOCAL_FILES:
    path = repo / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("fixture\n")

(repo / ".flywheel/scripts/public-surface-gap-scanner.py").unlink()
PY

set +e
python3 "$SCRIPT" --repo "$verifier_impl_repo" --skip-remote --json >"$TMP/verifier-impl-missing.out"
verifier_impl_missing_rc=$?
set -e
if [[ "$verifier_impl_missing_rc" -eq 20 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "local_required_file_missing" and .path == ".flywheel/scripts/public-surface-gap-scanner.py")' "$TMP/verifier-impl-missing.out" >/dev/null; then
  pass "verifier implementation files are required"
else
  fail "verifier implementation files are required rc=${verifier_impl_missing_rc}"
fi

live_probe_repo="$TMP/live-probe-repo"
python3 - "$SCRIPT" "$live_probe_repo" <<'PY'
import importlib.util
import sys
from pathlib import Path

script = Path(sys.argv[1])
repo = Path(sys.argv[2])
spec = importlib.util.spec_from_file_location("publication_readiness", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

for rel in module.REQUIRED_LOCAL_FILES:
    path = repo / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("fixture\n")

(repo / "scripts/live_site_probe.py").unlink()
PY

set +e
python3 "$SCRIPT" --repo "$live_probe_repo" --skip-remote --json >"$TMP/live-probe-missing.out"
live_probe_missing_rc=$?
set -e
if [[ "$live_probe_missing_rc" -eq 20 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "local_required_file_missing" and .path == "scripts/live_site_probe.py")' "$TMP/live-probe-missing.out" >/dev/null; then
  pass "live site probe implementation is required"
else
  fail "live site probe implementation is required rc=${live_probe_missing_rc}"
fi

evidence_repo="$TMP/evidence-repo"
python3 - "$SCRIPT" "$evidence_repo" <<'PY'
import importlib.util
import sys
from pathlib import Path

script = Path(sys.argv[1])
repo = Path(sys.argv[2])
spec = importlib.util.spec_from_file_location("publication_readiness", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

for rel in module.REQUIRED_LOCAL_FILES:
    path = repo / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("fixture\n")

(repo / "docs/evidence/external-review-log.jsonl").unlink()
PY

set +e
python3 "$SCRIPT" --repo "$evidence_repo" --skip-remote --json >"$TMP/evidence-missing.out"
evidence_missing_rc=$?
set -e
if [[ "$evidence_missing_rc" -eq 20 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "local_required_file_missing" and .path == "docs/evidence/external-review-log.jsonl")' "$TMP/evidence-missing.out" >/dev/null; then
  pass "public review evidence is required"
else
  fail "public review evidence is required rc=${evidence_missing_rc}"
fi

asupersync_poc_repo="$TMP/asupersync-poc-repo"
python3 - "$SCRIPT" "$asupersync_poc_repo" <<'PY'
import importlib.util
import sys
from pathlib import Path

script = Path(sys.argv[1])
repo = Path(sys.argv[2])
spec = importlib.util.spec_from_file_location("publication_readiness", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

for rel in module.REQUIRED_LOCAL_FILES:
    path = repo / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("fixture\n")

(repo / "docs/evidence/asupersync-poc-receipt.template.json").unlink()
PY

set +e
python3 "$SCRIPT" --repo "$asupersync_poc_repo" --skip-remote --json >"$TMP/asupersync-poc-missing.out"
asupersync_poc_missing_rc=$?
set -e
if [[ "$asupersync_poc_missing_rc" -eq 20 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "local_required_file_missing" and .path == "docs/evidence/asupersync-poc-receipt.template.json")' "$TMP/asupersync-poc-missing.out" >/dev/null; then
  pass "asupersync POC receipt template is required"
else
  fail "asupersync POC receipt template is required rc=${asupersync_poc_missing_rc}"
fi

asupersync_local_poc_repo="$TMP/asupersync-local-poc-repo"
python3 - "$SCRIPT" "$asupersync_local_poc_repo" <<'PY'
import importlib.util
import sys
from pathlib import Path

script = Path(sys.argv[1])
repo = Path(sys.argv[2])
spec = importlib.util.spec_from_file_location("publication_readiness", script)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

for rel in module.REQUIRED_LOCAL_FILES:
    path = repo / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("fixture\n")

(repo / "docs/evidence/asupersync-poc-receipt.local.json").unlink()
PY

set +e
python3 "$SCRIPT" --repo "$asupersync_local_poc_repo" --skip-remote --json >"$TMP/asupersync-local-poc-missing.out"
asupersync_local_poc_missing_rc=$?
set -e
if [[ "$asupersync_local_poc_missing_rc" -eq 20 ]] && jq -e '.status == "blocked" and any(.blockers[]?; .code == "local_required_file_missing" and .path == "docs/evidence/asupersync-poc-receipt.local.json")' "$TMP/asupersync-local-poc-missing.out" >/dev/null; then
  pass "asupersync local POC receipt is required"
else
  fail "asupersync local POC receipt is required rc=${asupersync_local_poc_missing_rc}"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
