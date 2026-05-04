#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
LOOP="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jeff-corpus-doctor-scoping.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    printf '  expr=%s file=%s\n' "$expr" "$file" >&2
    jq . "$file" >&2 || true
  fi
}

make_repo() {
  local repo="$1"
  mkdir -p "$repo/.flywheel" "$repo/.beads"
  git -C "$repo" init -q >/dev/null 2>&1
  printf '# Mission\n\nstatus: ready\n' >"$repo/.flywheel/MISSION.md"
  printf '# Goal\n\nstatus: ready\n' >"$repo/.flywheel/GOAL.md"
  printf '# State\n\nstatus: ready\n' >"$repo/.flywheel/STATE.md"
  printf '{"enabled":false}\n' >"$repo/.flywheel/daily-report-config.json"
}

storage_fixture="$TMP/storage-healthy.json"
jq -nc '{disk_total_gb:926,disk_free_gb:400,disk_free_pct:43,developer_dir_gb:0,local_state_gb:0,stale_baks_count:0,stale_baks_size_mb:0,qdrant_volumes_size_mb:0,tmp_dispatch_artifacts_count:0}' >"$storage_fixture"

owner_repo="$TMP/owner"
make_repo "$owner_repo"
mkdir -p "$owner_repo/.flywheel/jeff-corpus/v1"
jq -n '{schema_version:"jeff-corpus-manifest/v1",repo_count:1,total_repo_size_mb:42,repos:[{repo:"fixture",content_hash_set:[{path:"a",sha256:"h",bytes:1}]}]}' >"$owner_repo/.flywheel/jeff-corpus/v1/manifest.json"
FLYWHEEL_STORAGE_PROBE_FIXTURE="$storage_fixture" FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 "$LOOP" doctor --repo "$owner_repo" --json >"$TMP/owner.json" 2>/dev/null || true
assert_jq "$TMP/owner.json" '.jeff_corpus.status == "pass" and .jeff_corpus_v1_total_mb == 42 and (.jeff_corpus.applies_to | length) >= 2' "corpus owner emits signal"

non_owner_repo="$TMP/non-owner"
make_repo "$non_owner_repo"
FLYWHEEL_STORAGE_PROBE_FIXTURE="$storage_fixture" FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 "$LOOP" doctor --repo "$non_owner_repo" --json >"$TMP/non-owner.json" 2>/dev/null || true
assert_jq "$TMP/non-owner.json" '.jeff_corpus.status == "not_applicable" and .jeff_corpus_v1_total_mb == null and .jeff_corpus_storage_health == null and ([.errors[]?.code] | index("jeff_corpus_storage_red") | not)' "non corpus repo skips signal"

missing_fw_repo="$TMP/missing-fw"
mkdir -p "$missing_fw_repo"
git -C "$missing_fw_repo" init -q >/dev/null 2>&1
FLYWHEEL_STORAGE_PROBE_FIXTURE="$storage_fixture" FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 "$LOOP" doctor --repo "$missing_fw_repo" --json >"$TMP/missing-fw.json" 2>/dev/null || true
assert_jq "$TMP/missing-fw.json" '.jeff_corpus.status == "not_applicable" and .jeff_corpus_v1_total_mb == null and .jeff_corpus_storage_health == null' "missing flywheel dir skips signal"

canonical_repo="$TMP/canonical"
make_repo "$canonical_repo"
printf 'jeff_corpus_manifest\t.flywheel/jeff-corpus/v1/manifest.json\tfixture\tFixture ownership declaration.\n' >"$canonical_repo/.flywheel/canonical-paths.txt"
mkdir -p "$canonical_repo/.flywheel/jeff-corpus/v1"
jq -n '{schema_version:"jeff-corpus-manifest/v1",repo_count:1,total_repo_size_mb:7,repos:[{repo:"fixture",content_hash_set:[{path:"a",sha256:"h",bytes:1}]}]}' >"$canonical_repo/.flywheel/jeff-corpus/v1/manifest.json"
FLYWHEEL_STORAGE_PROBE_FIXTURE="$storage_fixture" FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 "$LOOP" doctor --repo "$canonical_repo" --json >"$TMP/canonical.json" 2>/dev/null || true
assert_jq "$TMP/canonical.json" '.jeff_corpus.status == "pass" and .jeff_corpus_v1_total_mb == 7' "canonical declaration owner emits signal"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
