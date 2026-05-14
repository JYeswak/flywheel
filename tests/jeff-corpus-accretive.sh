#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
FREEZE="$ROOT/.flywheel/scripts/jeff-corpus-freeze-baseline.sh"
WATCHER="$ROOT/.flywheel/scripts/jeff-corpus-diff-watcher.sh"
DELTA="$ROOT/.flywheel/scripts/jeff-corpus-delta-reindex.sh"
COMPACT="$ROOT/.flywheel/scripts/jeff-corpus-compact.sh"
DOCTOR="$ROOT/.flywheel/scripts/jeff-corpus-doctor.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jeff-corpus-accretive.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'PASS %s\n' "$1"
}

fail() {
  fail_count=$((fail_count + 1))
  printf 'FAIL %s\n' "$1" >&2
}

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
  mkdir -p "$repo"
  git -C "$repo" init -q
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name "Fixture Test"
  printf 'alpha\n' >"$repo/a.txt"
  git -C "$repo" add a.txt
  git -C "$repo" commit -qm initial
}

script_syntax() {
  for script in "$FREEZE" "$WATCHER" "$DELTA" "$COMPACT" "$DOCTOR"; do
    bash -n "$script" && pass "syntax $(basename "$script")" || fail "syntax $(basename "$script")"
  done
}

real_manifest_check() {
  local manifest="$ROOT/.flywheel/jeff-corpus/v1/manifest.json"
  local repos_jsonl="$HOME/.local/state/jeff-intel/repos.jsonl"
  if [ ! -s "$manifest" ]; then
    fail "AG1 real manifest exists"
    return
  fi
  local expected
  expected="$(jq -s 'map(select(.index_status == "verified_indexed")) | length' "$repos_jsonl")"
  jq -e --argjson expected "$expected" '
    .schema_version == "jeff-corpus-manifest/v1"
    and .repo_count == $expected
    and (.repos | length) == $expected
    and all(.repos[]; (.content_hash_set | length) > 0 and (.git_sha | length) >= 7 and (.chunk_count | type) == "number")
  ' "$manifest" >/dev/null && pass "AG1 real manifest covers verified corpus" || fail "AG1 real manifest covers verified corpus"
}

watcher_fixture() {
  local manifest="$TMP/watcher-manifest.json" heads="$TMP/heads.json" pending="$TMP/pending.jsonl" out="$TMP/watcher.out"
  jq -n '{
    schema_version:"jeff-corpus-manifest/v1",
    repos:[
      {repo:"alpha",path:"/tmp/alpha",upstream_url:"https://example.invalid/alpha.git",git_sha:"old-alpha",content_hash_set:[{path:"a.txt",sha256:"old",bytes:1}]},
      {repo:"beta",path:"/tmp/beta",upstream_url:"https://example.invalid/beta.git",git_sha:"same-beta",content_hash_set:[{path:"b.txt",sha256:"same",bytes:1}]}
    ]
  }' >"$manifest"
  jq -n '{"alpha":"new-alpha","beta":"same-beta"}' >"$heads"
  "$WATCHER" --manifest "$manifest" --pending "$pending" --remote-heads "$heads" --now 2026-05-04T03:00:00Z --json >"$out"
  assert_jq "$out" '.status == "pass" and .changed == 1 and .recommended_schedule == "daily 03:00Z"' "AG4 watcher summary"
  jq -s 'length == 1 and .[0].repo == "alpha" and .[0].old_sha == "old-alpha" and .[0].new_sha == "new-alpha"' "$pending" >/dev/null \
    && pass "AG4 watcher deterministic pending row" || fail "AG4 watcher deterministic pending row"
}

delta_fixture() {
  local repo="$TMP/repo" manifest="$TMP/delta-manifest.json" pending="$TMP/delta-pending.jsonl" delta="$TMP/delta.jsonl" out="$TMP/delta.out"
  make_repo "$repo"
  local old new old_hash
  old="$(git -C "$repo" rev-parse HEAD)"
  old_hash="$(shasum -a 256 "$repo/a.txt" | awk '{print $1}')"
  printf 'alpha changed\n' >"$repo/a.txt"
  printf 'bravo\n' >"$repo/b.txt"
  git -C "$repo" add a.txt b.txt
  git -C "$repo" commit -qm update
  new="$(git -C "$repo" rev-parse HEAD)"
  jq -n --arg repo "$repo" --arg old "$old" --arg old_hash "$old_hash" '{
    schema_version:"jeff-corpus-manifest/v1",
    repos:[{repo:"fixture",path:$repo,git_sha:$old,last_indexed_at:"2026-05-04T00:00:00Z",chunk_count:1,repo_size_bytes:1,content_hash_set:[{path:"a.txt",sha256:$old_hash,bytes:6}]}]
  }' >"$manifest"
  jq -nc --arg repo "$repo" --arg old "$old" --arg new "$new" '{repo:"fixture",path:$repo,old_sha:$old,new_sha:$new}' >"$pending"
  "$DELTA" --manifest "$manifest" --pending "$pending" --delta "$delta" --dry-run --now 2026-05-04T04:00:00Z --json >"$out"
  assert_jq "$out" '.status == "pass" and .full_reindex == false and .new_chunks == 2 and .processed[0].changed_files == 2' "AG5 delta dry-run only changed files"
  "$DELTA" --manifest "$manifest" --pending "$pending" --delta "$delta" --apply --idempotency-key fixture-delta --now 2026-05-04T04:00:00Z --json >"$TMP/delta-apply.out"
  jq -s 'length == 2 and ([.[].path] | sort) == ["a.txt","b.txt"]' "$delta" >/dev/null \
    && pass "AG5 delta emits expected chunks" || fail "AG5 delta emits expected chunks"
}

compact_fixture() {
  local manifest_dir="$TMP/compact/v1" manifest="$TMP/compact/v1/manifest.json" delta="$TMP/compact/v2/delta-index.jsonl" out_manifest="$TMP/compact/v3/manifest.json" out="$TMP/compact.out" replay="$TMP/compact-replay.out" qdrant="$TMP/qdrant-fixture.json" receipt_dir="$TMP/receipts" doctor_out="$TMP/compact-doctor.out"
  mkdir -p "$manifest_dir" "$(dirname "$delta")"
  jq -n '{
    schema_version:"jeff-corpus-manifest/v1",
    baseline:"jeff-corpus-v1",
    repo_count:1,
    total_repo_size_bytes:6291456000,
    total_repo_size_mb:6000,
    repos:[{repo:"fixture",path:"/tmp/fixture",git_sha:"old",last_indexed_at:"old-ts",chunk_count:1,repo_size_bytes:6291456000,qdrant_collection:"codebase_fixture",content_hash_set:[{path:"a.txt",sha256:"oldoldoldoldoldold",bytes:1}]}]
  }' >"$manifest"
  jq -nc '{schema_version:"jeff-corpus-delta/v1",indexed_at:"2026-05-04T04:00:00Z",repo:"fixture",path:"a.txt",old_sha:"old",new_sha:"new",content_sha256:"newhash",bytes:2,target_collection:"jeff-corpus-v2"}' >"$delta"
  jq -n '{collections:{codebase_fixture:{points_count:1,delete_matches:1}}}' >"$qdrant"
  JEFF_CORPUS_QDRANT_FIXTURE="$qdrant" "$COMPACT" --manifest "$manifest" --delta "$delta" --out "$out_manifest" --receipt-dir "$receipt_dir" --idempotency-key fixture-key --qdrant-url "fixture://qdrant" --apply --now 2026-05-05T04:00:00Z --json >"$out"
  assert_jq "$out" '.status == "pass" and .delta_rows_merged == 1 and .superseded_chunks_dropped == 1 and .qdrant_deletes_attempted == 1 and .qdrant_points_deleted == 1 and .retired_to_cold_storage == true and .promoted_to_doctor_baseline == true and (.archive_manifest_path | endswith("v1.archived-20260505T040000Z.json.gz"))' "AG6 compaction summary"
  assert_jq "$manifest" '.baseline == "jeff-corpus-v3" and .repos[0].content_hash_set[0].sha256 == "newhash" and .raw_total_repo_size_mb == 6000 and .total_repo_size_mb < 1' "AG6 compaction promoted manifest"
  assert_jq "$out_manifest" '.baseline == "jeff-corpus-v3" and .repos[0].content_hash_set[0].sha256 == "newhash"' "AG6 compaction out manifest"
  test -s "$receipt_dir/fixture-key.json" && pass "AG6 compaction idempotency receipt" || fail "AG6 compaction idempotency receipt"
  "$COMPACT" --manifest "$manifest" --delta "$delta" --out "$out_manifest" --receipt-dir "$receipt_dir" --idempotency-key fixture-key --apply --now 2026-05-05T04:00:00Z --json >"$replay"
  assert_jq "$replay" '.idempotent_replay == true and .idempotency_key == "fixture-key"' "AG6 compaction idempotent replay"
  "$DOCTOR" --manifest "$manifest" --json >"$doctor_out"
  assert_jq "$doctor_out" '.status == "pass" and .jeff_corpus_storage_health == "GREEN"' "AG6 compaction doctor reads promoted baseline"
}

storage_budget_fixture() {
  local manifest="$TMP/red-manifest.json" out="$TMP/red.out" yellow="$TMP/yellow-manifest.json" yellow_out="$TMP/yellow.out"
  jq -n '{schema_version:"jeff-corpus-manifest/v1",repo_count:1,total_repo_size_mb:5001,repos:[{repo:"fixture",content_hash_set:[{path:"a",sha256:"h",bytes:1}]}]}' >"$manifest"
  "$DOCTOR" --manifest "$manifest" --json >"$out" || true
  assert_jq "$out" '.status == "pass" and .jeff_corpus_storage_health == "GREEN" and .jeff_corpus_v1_total_mb == 5001 and .jeff_corpus_local_storage_mb < 1000' "AG7 source size alone does not trigger local storage block"
  JEFF_CORPUS_LOCAL_STORAGE_MB_FIXTURE=5001 "$DOCTOR" --manifest "$manifest" --json >"$out" || true
  assert_jq "$out" '.status == "fail" and .jeff_corpus_storage_health == "RED" and .jeff_corpus_v1_total_mb == 5001 and .jeff_corpus_local_storage_mb == 5001 and (.errors[]?.code == "jeff_corpus_storage_red")' "AG7 RED blocks local storage pressure"
  jq -n '{schema_version:"jeff-corpus-manifest/v1",repo_count:1,total_repo_size_mb:1001,repos:[{repo:"fixture",content_hash_set:[{path:"a",sha256:"h",bytes:1}]}]}' >"$yellow"
  JEFF_CORPUS_LOCAL_STORAGE_MB_FIXTURE=1001 "$DOCTOR" --manifest "$yellow" --json >"$yellow_out" || true
  assert_jq "$yellow_out" '.status == "warn" and .jeff_corpus_storage_health == "YELLOW" and .jeff_corpus_local_storage_mb == 1001 and (.warnings[]?.code == "jeff_corpus_storage_yellow")' "AG7 YELLOW allows compacted corpus"
}

doctor_wiring_check() {
  local out="$TMP/loop-doctor.out"
  FLYWHEEL_HOME="${FLYWHEEL_HOME:-$HOME/.claude/skills/.flywheel}" REPO_ABS="$ROOT" bash -c '
    set -euo pipefail
    source "$FLYWHEEL_HOME/lib/jeff.sh"
    jeff_corpus_doctor_json
  ' >"$out"
  assert_jq "$out" '(.jeff_corpus_v1_total_mb | type) == "number" and (.jeff_corpus_local_storage_mb | type) == "number" and (.jeff_corpus_storage_health | IN("GREEN","YELLOW","RED"))' "AG2 Jeff corpus doctor helper exposes fields"
}

main() {
  command -v jq >/dev/null || { printf 'missing jq\n' >&2; exit 69; }
  script_syntax
  real_manifest_check
  watcher_fixture
  delta_fixture
  compact_fixture
  storage_budget_fixture
  doctor_wiring_check
  if [ "$fail_count" -gt 0 ]; then
    printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
    exit 1
  fi
  printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
}

main "$@"
