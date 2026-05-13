#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/scripts/validate_cutover_receipts.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-cutover-receipts.XXXXXX")"
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

make_receipts() {
  local dir="$1"
  mkdir -p "$dir"
  local tag="v0.2.0"
  local tarball="flywheel-${tag}.tar.gz"
  local digest="sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  local install_hash
  install_hash="$(printf 'install-body' | shasum -a 256 | awk '{print $1}')"

  cat >"$dir/repo-view.json" <<'JSON'
{"nameWithOwner":"JYeswak/flywheel","url":"https://github.com/JYeswak/flywheel","visibility":"PUBLIC","isPrivate":false,"defaultBranchRef":{"name":"master"}}
JSON
  cat >"$dir/remote-workflows.json" <<'JSON'
[{"name":"CI"},{"name":"Installer Smoke"},{"name":"Release"},{"name":"Site Deploy"}]
JSON
  cat >"$dir/remote-runs.json" <<'JSON'
[{"workflowName":"CI","status":"completed","conclusion":"success","headBranch":"master"},{"workflowName":"Installer Smoke","status":"completed","conclusion":"success","headBranch":"master"}]
JSON
  jq -nc --arg tag "$tag" --arg tarball "$tarball" --arg digest "$digest" '{
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
  }' >"$dir/release-view.json"
  cat >"$dir/external-review-release.json" <<'JSON'
{"schema_version":"flywheel.external_review_gate.v0","status":"pass","valid_review_count":2,"distinct_reviewer_count":2,"errors":[]}
JSON
  cat >"$dir/release-signoff.receipt.json" <<'JSON'
{"schema_version":"flywheel.release_signoff.v0","status":"approved","approver":"Joshua Nowak","tag":"v0.2.0","remote":"JYeswak/flywheel","signed_at":"2026-05-13T00:00:00Z"}
JSON
  cat >"$dir/publication-readiness.json" <<'JSON'
{"schema_version":"flywheel.publication_readiness.v0","status":"pass","blockers":[]}
JSON
  cat >"$dir/publication-readiness-release.json" <<'JSON'
{"schema_version":"flywheel.publication_readiness.v0","status":"pass","blockers":[]}
JSON
  cat >"$dir/publication-readiness-replay.json" <<'JSON'
{"schema_version":"flywheel.publication_readiness.v0","status":"pass","blockers":[]}
JSON
  cat >"$dir/user-journey-pack-validation.json" <<'JSON'
{"schema_version":"flywheel.public_user_journey_pack.v0","status":"pass","path":"docs/runbooks/public-user-journey-pack.md","row_count":16,"errors":[]}
JSON
  printf 'HTTP/2 200\n' >"$dir/website-head.txt"
  jq -nc '{schema_version:"flywheel.live_site_probe.v0",status:"pass",source_count:6,probe_count:14,pass_count:14,failure_count:0,skipped_external_count:6,failures:[]}' >"$dir/live-site-probe.json"
  jq -nc '{url:"https://flywheel.zeststream.ai/",status_code:200,body_text:"Flywheel. Your business already has the data. I help SMB owners buy their time back. The Yuzu Method starts with one workflow slice.",body_sha256:"unused"}' >"$dir/website-probe.json"
  jq -nc --arg hash "$install_hash" '{url:"https://flywheel.zeststream.ai/install.sh",status_code:200,body_sha256:$hash,body_text:"install-body"}' >"$dir/install-probe.json"
  jq -nc --arg hash "$install_hash" '{url:"https://flywheel.zeststream.ai/install.sh.sha256",status_code:200,body_sha256:"unused",body_text:($hash + "  install.sh\n")}' >"$dir/install-sha256-probe.json"
  printf '%s\n' "$install_hash" >"$dir/install-sha256.actual"
  printf '%s  install.sh\n' "$install_hash" >"$dir/install-sha256.expected"
}

expect_replay_blocker() {
  local dir="$1"
  local label="$2"
  local code="$3"
  local out="$dir.out"
  local rc

  set +e
  python3 "$SCRIPT" --repo "$ROOT" --receipt-dir "$dir" --release --json >"$out"
  rc=$?
  set -e

  if [[ "$rc" -eq 1 ]] && jq -e --arg code "$code" \
    '.status == "blocked" and any(.publication_readiness_replay.blockers[]?; .code == $code)' \
    "$out" >/dev/null; then
    pass "$label"
  else
    fail "$label rc=${rc}"
    jq -c . "$out" >&2 || true
  fi
}

make_receipts "$TMP/good"
if python3 "$SCRIPT" --repo "$ROOT" --receipt-dir "$TMP/good" --release --json >"$TMP/good.out"; then
  if jq -e '.status == "pass" and (.errors | length) == 0 and .publication_readiness_replay.status == "pass"' "$TMP/good.out" >/dev/null; then
    pass "valid receipt bundle passes"
  else
    fail "valid receipt bundle envelope"
    jq -c . "$TMP/good.out" >&2
  fi
else
  fail "valid receipt bundle command"
  jq -c . "$TMP/good.out" >&2 || true
fi

cp -R "$TMP/good" "$TMP/private-repo"
jq '.visibility = "PRIVATE" | .isPrivate = true' "$TMP/private-repo/repo-view.json" >"$TMP/private-repo/repo.tmp"
mv "$TMP/private-repo/repo.tmp" "$TMP/private-repo/repo-view.json"
expect_replay_blocker "$TMP/private-repo" "private repo receipt blocks replay" "remote_repo_private"

cp -R "$TMP/good" "$TMP/missing-workflow"
jq 'map(select(.name != "Installer Smoke"))' "$TMP/missing-workflow/remote-workflows.json" >"$TMP/missing-workflow/workflows.tmp"
mv "$TMP/missing-workflow/workflows.tmp" "$TMP/missing-workflow/remote-workflows.json"
expect_replay_blocker "$TMP/missing-workflow" "missing workflow receipt blocks replay" "remote_workflows_missing"

cp -R "$TMP/good" "$TMP/feature-branch-runs"
jq 'map(.headBranch = "feature/publication-test")' "$TMP/feature-branch-runs/remote-runs.json" >"$TMP/feature-branch-runs/runs.tmp"
mv "$TMP/feature-branch-runs/runs.tmp" "$TMP/feature-branch-runs/remote-runs.json"
expect_replay_blocker "$TMP/feature-branch-runs" "feature-branch green runs block replay" "remote_green_runs_missing"

cp -R "$TMP/good" "$TMP/draft-release"
jq '.isDraft = true' "$TMP/draft-release/release-view.json" >"$TMP/draft-release/release.tmp"
mv "$TMP/draft-release/release.tmp" "$TMP/draft-release/release-view.json"
expect_replay_blocker "$TMP/draft-release" "draft release receipt blocks replay" "github_release_missing_or_draft"

cp -R "$TMP/good" "$TMP/prerelease"
jq '.isPrerelease = true' "$TMP/prerelease/release-view.json" >"$TMP/prerelease/release.tmp"
mv "$TMP/prerelease/release.tmp" "$TMP/prerelease/release-view.json"
expect_replay_blocker "$TMP/prerelease" "prerelease receipt blocks replay" "github_release_missing_or_draft"

cp -R "$TMP/good" "$TMP/empty-asset"
jq '(.assets[] | select(.name == "install.sh") | .size) = 0' "$TMP/empty-asset/release-view.json" >"$TMP/empty-asset/release.tmp"
mv "$TMP/empty-asset/release.tmp" "$TMP/empty-asset/release-view.json"
expect_replay_blocker "$TMP/empty-asset" "empty release asset blocks replay" "github_release_assets_missing"

cp -R "$TMP/good" "$TMP/missing-digest"
jq 'del(.assets[] | select(.name == "install.sh") | .digest)' "$TMP/missing-digest/release-view.json" >"$TMP/missing-digest/release.tmp"
mv "$TMP/missing-digest/release.tmp" "$TMP/missing-digest/release-view.json"
expect_replay_blocker "$TMP/missing-digest" "missing release asset digest blocks replay" "github_release_assets_missing"

cp -R "$TMP/good" "$TMP/signoff-wrong-remote"
jq '.remote = "JYeswak/not-flywheel"' "$TMP/signoff-wrong-remote/release-signoff.receipt.json" >"$TMP/signoff-wrong-remote/signoff.tmp"
mv "$TMP/signoff-wrong-remote/signoff.tmp" "$TMP/signoff-wrong-remote/release-signoff.receipt.json"
expect_replay_blocker "$TMP/signoff-wrong-remote" "signoff wrong remote blocks replay" "joshua_release_signoff_missing"

cp -R "$TMP/good" "$TMP/signoff-wrong-tag"
jq '.tag = "v9.9.9"' "$TMP/signoff-wrong-tag/release-signoff.receipt.json" >"$TMP/signoff-wrong-tag/signoff.tmp"
mv "$TMP/signoff-wrong-tag/signoff.tmp" "$TMP/signoff-wrong-tag/release-signoff.receipt.json"
expect_replay_blocker "$TMP/signoff-wrong-tag" "signoff wrong tag blocks replay" "joshua_release_signoff_missing"

cp -R "$TMP/good" "$TMP/missing-release"
rm "$TMP/missing-release/release-view.json"
set +e
python3 "$SCRIPT" --repo "$ROOT" --receipt-dir "$TMP/missing-release" --release --json >"$TMP/missing-release.out"
missing_release_rc=$?
set -e
if [[ "$missing_release_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.errors[]?; .code == "missing_receipt_file" and (.path | endswith("release-view.json")))' "$TMP/missing-release.out" >/dev/null; then
  pass "missing receipt file blocks release"
else
  fail "missing receipt file blocks release rc=${missing_release_rc}"
fi

cp -R "$TMP/good" "$TMP/bad-checksum"
printf 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb\n' >"$TMP/bad-checksum/install-sha256.expected"
set +e
python3 "$SCRIPT" --repo "$ROOT" --receipt-dir "$TMP/bad-checksum" --release --json >"$TMP/bad-checksum.out"
bad_checksum_rc=$?
set -e
if [[ "$bad_checksum_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.errors[]?; .code == "install_sha256_text_mismatch")' "$TMP/bad-checksum.out" >/dev/null; then
  pass "checksum text mismatch blocks release"
else
  fail "checksum text mismatch blocks release rc=${bad_checksum_rc}"
fi

cp -R "$TMP/good" "$TMP/bad-website-head"
printf 'HTTP/2 404\n' >"$TMP/bad-website-head/website-head.txt"
set +e
python3 "$SCRIPT" --repo "$ROOT" --receipt-dir "$TMP/bad-website-head" --release --json >"$TMP/bad-website-head.out"
bad_website_head_rc=$?
set -e
if [[ "$bad_website_head_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.errors[]?; .code == "website_head_status_not_success" and .status_code == 404)' "$TMP/bad-website-head.out" >/dev/null; then
  pass "website HEAD failure blocks release"
else
  fail "website HEAD failure blocks release rc=${bad_website_head_rc}"
fi

cp -R "$TMP/good" "$TMP/missing-publication-readiness"
rm "$TMP/missing-publication-readiness/publication-readiness.json"
set +e
python3 "$SCRIPT" --repo "$ROOT" --receipt-dir "$TMP/missing-publication-readiness" --release --json >"$TMP/missing-publication-readiness.out"
missing_publication_readiness_rc=$?
set -e
if [[ "$missing_publication_readiness_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.errors[]?; .code == "missing_receipt_file" and (.path | endswith("publication-readiness.json")))' "$TMP/missing-publication-readiness.out" >/dev/null; then
  pass "missing publication readiness receipt blocks release"
else
  fail "missing publication readiness receipt blocks release rc=${missing_publication_readiness_rc}"
fi

cp -R "$TMP/good" "$TMP/blocked-publication-readiness"
jq '.status = "blocked" | .blockers = [{code:"remote_repo_private"}]' "$TMP/blocked-publication-readiness/publication-readiness.json" >"$TMP/blocked-publication-readiness/publication-readiness.tmp"
mv "$TMP/blocked-publication-readiness/publication-readiness.tmp" "$TMP/blocked-publication-readiness/publication-readiness.json"
set +e
python3 "$SCRIPT" --repo "$ROOT" --receipt-dir "$TMP/blocked-publication-readiness" --release --json >"$TMP/blocked-publication-readiness.out"
blocked_publication_readiness_rc=$?
set -e
if [[ "$blocked_publication_readiness_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.errors[]?; .code == "publication_readiness_not_pass" and .status == "blocked" and .blocker_count == 1)' "$TMP/blocked-publication-readiness.out" >/dev/null; then
  pass "blocked publication readiness receipt blocks release"
else
  fail "blocked publication readiness receipt blocks release rc=${blocked_publication_readiness_rc}"
fi

cp -R "$TMP/good" "$TMP/missing-publication-readiness-replay"
rm "$TMP/missing-publication-readiness-replay/publication-readiness-replay.json"
set +e
python3 "$SCRIPT" --repo "$ROOT" --receipt-dir "$TMP/missing-publication-readiness-replay" --release --json >"$TMP/missing-publication-readiness-replay.out"
missing_publication_readiness_replay_rc=$?
set -e
if [[ "$missing_publication_readiness_replay_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.errors[]?; .code == "missing_receipt_file" and (.path | endswith("publication-readiness-replay.json")))' "$TMP/missing-publication-readiness-replay.out" >/dev/null; then
  pass "missing publication readiness replay receipt blocks release"
else
  fail "missing publication readiness replay receipt blocks release rc=${missing_publication_readiness_replay_rc}"
fi

cp -R "$TMP/good" "$TMP/blocked-publication-readiness-replay"
jq '.status = "blocked" | .blockers = [{code:"github_release_assets_missing"}]' "$TMP/blocked-publication-readiness-replay/publication-readiness-replay.json" >"$TMP/blocked-publication-readiness-replay/publication-readiness-replay.tmp"
mv "$TMP/blocked-publication-readiness-replay/publication-readiness-replay.tmp" "$TMP/blocked-publication-readiness-replay/publication-readiness-replay.json"
set +e
python3 "$SCRIPT" --repo "$ROOT" --receipt-dir "$TMP/blocked-publication-readiness-replay" --release --json >"$TMP/blocked-publication-readiness-replay.out"
blocked_publication_readiness_replay_rc=$?
set -e
if [[ "$blocked_publication_readiness_replay_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.errors[]?; .code == "publication_readiness_saved_replay_not_pass" and .status == "blocked" and .blocker_count == 1)' "$TMP/blocked-publication-readiness-replay.out" >/dev/null; then
  pass "blocked publication readiness replay receipt blocks release"
else
  fail "blocked publication readiness replay receipt blocks release rc=${blocked_publication_readiness_replay_rc}"
fi

cp -R "$TMP/good" "$TMP/missing-live-site-probe"
rm "$TMP/missing-live-site-probe/live-site-probe.json"
set +e
python3 "$SCRIPT" --repo "$ROOT" --receipt-dir "$TMP/missing-live-site-probe" --release --json >"$TMP/missing-live-site-probe.out"
missing_live_site_probe_rc=$?
set -e
if [[ "$missing_live_site_probe_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.errors[]?; .code == "missing_receipt_file" and (.path | endswith("live-site-probe.json")))' "$TMP/missing-live-site-probe.out" >/dev/null; then
  pass "missing live-site probe receipt blocks release"
else
  fail "missing live-site probe receipt blocks release rc=${missing_live_site_probe_rc}"
fi

cp -R "$TMP/good" "$TMP/missing-user-journey-validation"
rm "$TMP/missing-user-journey-validation/user-journey-pack-validation.json"
set +e
python3 "$SCRIPT" --repo "$ROOT" --receipt-dir "$TMP/missing-user-journey-validation" --release --json >"$TMP/missing-user-journey-validation.out"
missing_user_journey_validation_rc=$?
set -e
if [[ "$missing_user_journey_validation_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.errors[]?; .code == "missing_receipt_file" and (.path | endswith("user-journey-pack-validation.json")))' "$TMP/missing-user-journey-validation.out" >/dev/null; then
  pass "missing user journey validation receipt blocks release"
else
  fail "missing user journey validation receipt blocks release rc=${missing_user_journey_validation_rc}"
fi

cp -R "$TMP/good" "$TMP/bad-user-journey-validation"
jq '.status = "fail" | .errors = [{code:"STEP_VISUAL_CUE_MISSING",message:"fixture"}]' "$TMP/bad-user-journey-validation/user-journey-pack-validation.json" >"$TMP/bad-user-journey-validation/user-journey-pack-validation.tmp"
mv "$TMP/bad-user-journey-validation/user-journey-pack-validation.tmp" "$TMP/bad-user-journey-validation/user-journey-pack-validation.json"
set +e
python3 "$SCRIPT" --repo "$ROOT" --receipt-dir "$TMP/bad-user-journey-validation" --release --json >"$TMP/bad-user-journey-validation.out"
bad_user_journey_validation_rc=$?
set -e
if [[ "$bad_user_journey_validation_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.errors[]?; .code == "user_journey_pack_validation_not_pass" and .status == "fail" and .error_count == 1)' "$TMP/bad-user-journey-validation.out" >/dev/null; then
  pass "failing user journey validation receipt blocks release"
else
  fail "failing user journey validation receipt blocks release rc=${bad_user_journey_validation_rc}"
fi

cp -R "$TMP/good" "$TMP/bad-live-site-probe"
jq '.status = "fail" | .failure_count = 1 | .failures = [{url:"https://flywheel.zeststream.ai/missing",reason:"http_error"}]' "$TMP/bad-live-site-probe/live-site-probe.json" >"$TMP/bad-live-site-probe/live-site-probe.tmp"
mv "$TMP/bad-live-site-probe/live-site-probe.tmp" "$TMP/bad-live-site-probe/live-site-probe.json"
set +e
python3 "$SCRIPT" --repo "$ROOT" --receipt-dir "$TMP/bad-live-site-probe" --release --json >"$TMP/bad-live-site-probe.out"
bad_live_site_probe_rc=$?
set -e
if [[ "$bad_live_site_probe_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.errors[]?; .code == "live_site_probe_not_pass" and .status == "fail" and .failure_count == 1)' "$TMP/bad-live-site-probe.out" >/dev/null; then
  pass "failing live-site probe receipt blocks release"
else
  fail "failing live-site probe receipt blocks release rc=${bad_live_site_probe_rc}"
fi

cp -R "$TMP/good" "$TMP/pending-signoff"
jq '.status = "pending"' "$TMP/pending-signoff/release-signoff.receipt.json" >"$TMP/pending-signoff/signoff.tmp"
mv "$TMP/pending-signoff/signoff.tmp" "$TMP/pending-signoff/release-signoff.receipt.json"
set +e
python3 "$SCRIPT" --repo "$ROOT" --receipt-dir "$TMP/pending-signoff" --release --json >"$TMP/pending-signoff.out"
pending_signoff_rc=$?
set -e
if [[ "$pending_signoff_rc" -eq 1 ]] && jq -e '.status == "blocked" and any(.publication_readiness_replay.blockers[]?; .code == "joshua_release_signoff_missing")' "$TMP/pending-signoff.out" >/dev/null; then
  pass "pending signoff blocks replay"
else
  fail "pending signoff blocks replay rc=${pending_signoff_rc}"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
