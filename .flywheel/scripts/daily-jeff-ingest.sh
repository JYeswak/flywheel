#!/usr/bin/env bash
# Daily Jeff signal ingest for flywheel.
# Read-only on upstream sources; append-only on local ledger.
set -uo pipefail

VERSION="daily-jeff-ingest.v1"
SCRIPT_VERSION="2026-05-03.1"
STATE_DIR="${DAILY_JEFF_STATE_DIR:-$HOME/.local/state/flywheel}"
SNAPSHOT_DIR="${DAILY_JEFF_SNAPSHOT_DIR:-$STATE_DIR/daily-jeff-ingest-snapshots}"
LEDGER="${DAILY_JEFF_LEDGER:-$STATE_DIR/daily-jeff-ingest.jsonl}"
SHADOW_DIR="${DAILY_JEFF_SHADOW_DIR:-$HOME/Developer/jeff-corpus}"
SOURCES_FILE="${DAILY_JEFF_SOURCES_FILE:-$HOME/.claude/skills/dicklesworthstone-stack/data/sources.txt}"
CHECK_SCRIPT="${DAILY_JEFF_CHECK_SCRIPT:-$HOME/.claude/skills/dicklesworthstone-stack/scripts/check-dicklesworthstone-updates.sh}"
SNAPSHOT_DIFF_SCRIPT="${DAILY_JEFF_SNAPSHOT_DIFF_SCRIPT:-$HOME/.claude/skills/dicklesworthstone-stack/scripts/snapshot-diff-fallback.sh}"
BR_BIN="${DAILY_JEFF_BR_BIN:-br}"
STORAGE_PROBE="${DAILY_JEFF_STORAGE_PROBE:-/Users/josh/Developer/flywheel/.flywheel/scripts/storage-probe.sh}"
SHADOW_SOCRATICODE_SCRIPT="${DAILY_JEFF_SHADOW_SOCRATICODE_SCRIPT:-/Users/josh/Developer/flywheel/.flywheel/scripts/jeff-shadow-socraticode.sh}"
STORAGE_MIN_FREE_PCT="${DAILY_JEFF_STORAGE_MIN_FREE_PCT:-10}"
DAILY_JEFF_NOTIFY_BIN="${DAILY_JEFF_NOTIFY_BIN:-$HOME/.local/bin/notify}"
MAX_BEADS=5
JSON_OUT=0
QUIET=0
DRY_RUN=0
NO_MIRROR=0
EXPLAIN=0
MODE="run"

TMP_ROOT=""
WARNINGS_FILE=""
GROUPS_FILE=""
NEW_ITEMS_FILE=""
ACTIONABLE_FILE=""
MIRRORED_FILE=""
INDEXED_FILE=""
FETCHED=0
FAILED=0
NEW_ITEMS=0
ACTIONABLE_COUNT=0
BEADS_FILED=0
MIRRORED=0
INDEXED=0
DIGEST_PATH=""
STORAGE_JSON=""

usage() {
  cat <<'USAGE'
Usage:
  daily-jeff-ingest.sh [--json] [--quiet] [--dry-run] [--no-mirror]
  daily-jeff-ingest.sh --doctor [--json]
  daily-jeff-ingest.sh --info [--json]
  daily-jeff-ingest.sh --schema
  daily-jeff-ingest.sh --examples
  daily-jeff-ingest.sh --help

Options:
  --dry-run          Fetch and synthesize plan without writing snapshots, ledger, clones, or beads.
  --no-mirror        Skip best-effort mirroring of newly discovered GitHub repos.
  --max-beads N      Cap HIGH actionable auto-beads. Default: 5.
  --storage-fixture PATH
                     Test-only fixture passed to storage-probe.
  --quiet            Suppress human chatter; JSON output still prints when --json is used.
  --explain          Include extra rationale in human output.

Exit codes:
  0 success, including partial source failures with warnings
  1 domain failure
  2 usage error
USAGE
}

examples() {
  cat <<'EXAMPLES'
Examples:
  daily-jeff-ingest.sh --dry-run --json
  daily-jeff-ingest.sh --json
  daily-jeff-ingest.sh --no-mirror --quiet
  DAILY_JEFF_STATE_DIR=/tmp/jeff-state daily-jeff-ingest.sh --dry-run --json

Recommended cron line (not installed by this script; Joshua-decision):
  0 6 * * * ~/Developer/flywheel/.flywheel/scripts/daily-jeff-ingest.sh --quiet
EXAMPLES
}

schema_json() {
  cat <<'JSON'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "daily-jeff-ingest ledger row",
  "type": "object",
  "required": ["ts", "storage", "sources_fetched", "sources_failed", "new_items", "new_repos_mirrored", "socraticode_indexed", "actionable_beads_filed", "digest_path", "duration_sec", "warnings"],
  "properties": {
    "ts": {"type": "string"},
    "sources_fetched": {"type": "integer"},
    "sources_failed": {"type": "integer"},
    "new_items": {"type": "integer"},
    "new_repos_mirrored": {"type": "integer"},
    "socraticode_indexed": {"type": "integer"},
    "actionable_beads_filed": {"type": "array", "items": {"type": "string"}},
    "digest_path": {"type": "string"},
    "storage": {"type": "object"},
    "duration_sec": {"type": "integer"},
    "warnings": {"type": "array", "items": {"type": "string"}}
  }
}
JSON
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

today_utc() {
  date -u +%F
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 2
}

say() {
  if [ "$QUIET" -eq 0 ] && [ "$JSON_OUT" -eq 0 ]; then
    printf '%s\n' "$*"
  fi
}

have() {
  command -v "$1" >/dev/null 2>&1
}

ensure_tmp() {
  TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/daily-jeff-ingest.XXXXXX")" || exit 1
  WARNINGS_FILE="$TMP_ROOT/warnings.jsonl"
  GROUPS_FILE="$TMP_ROOT/groups.jsonl"
  NEW_ITEMS_FILE="$TMP_ROOT/new-items.jsonl"
  ACTIONABLE_FILE="$TMP_ROOT/actionable.jsonl"
  MIRRORED_FILE="$TMP_ROOT/mirrored.jsonl"
  INDEXED_FILE="$TMP_ROOT/indexed.jsonl"
  : >"$WARNINGS_FILE"
  : >"$GROUPS_FILE"
  : >"$NEW_ITEMS_FILE"
  : >"$ACTIONABLE_FILE"
  : >"$MIRRORED_FILE"
  : >"$INDEXED_FILE"
}

cleanup_tmp() {
  if [ -n "${TMP_ROOT:-}" ] && [ -d "$TMP_ROOT" ]; then
    rm -rf "$TMP_ROOT"
  fi
}

json_array_file() {
  local file="$1"
  if [ -s "$file" ]; then
    jq -cs '.' "$file" 2>/dev/null || printf '[]\n'
  else
    printf '[]\n'
  fi
}

warn() {
  local msg="$1"
  if [ "$QUIET" -eq 0 ] && [ "$JSON_OUT" -eq 0 ]; then
    printf '%s\n' "$msg" >&2
  fi
  jq -Rn --arg v "$msg" '$v' >>"$WARNINGS_FILE" 2>/dev/null || true
}

storage_probe_json() {
  local args=("--repo" "/Users/josh/Developer/flywheel" "--json" "--min-free-pct" "$STORAGE_MIN_FREE_PCT")
  if [ "$MODE" = "run" ] && [ "$DRY_RUN" -eq 0 ]; then
    args+=("--notify")
  fi
  if [ "$MODE" = "run" ] && [ "$DRY_RUN" -eq 0 ]; then
    args+=("--record-history")
  fi
  if [ -n "${DAILY_JEFF_STORAGE_FIXTURE:-}" ]; then
    args+=("--fixture" "$DAILY_JEFF_STORAGE_FIXTURE")
  fi
  if [ ! -x "$STORAGE_PROBE" ]; then
    jq -nc --arg path "$STORAGE_PROBE" '{status:"fail",errors:[{code:"storage_probe_missing",path:$path}],warnings:[]}'
    return 0
  fi
  NOTIFY_BIN="$DAILY_JEFF_NOTIFY_BIN" "$STORAGE_PROBE" "${args[@]}" 2>/dev/null || \
    jq -nc '{status:"fail",errors:[{code:"storage_probe_failed"}],warnings:[]}'
}

notify_storage_abort() {
  local pct="$1" gb="$2"
  if [ -x "$DAILY_JEFF_NOTIFY_BIN" ]; then
    "$DAILY_JEFF_NOTIFY_BIN" --priority 1 "STORAGE LOW" "daily-jeff-ingest aborted disk_free_pct=${pct}% disk_free_gb=${gb}" >/dev/null 2>&1 || true
  fi
}

storage_preflight() {
  STORAGE_JSON="$(storage_probe_json)"
  if ! jq -e . >/dev/null 2>&1 <<<"$STORAGE_JSON"; then
    STORAGE_JSON='{"status":"fail","errors":[{"code":"storage_probe_invalid_json"}],"warnings":[]}'
  fi
  local status pct gb
  status="$(jq -r '.status // "fail"' <<<"$STORAGE_JSON")"
  pct="$(jq -r '.disk_free_pct // 0' <<<"$STORAGE_JSON")"
  gb="$(jq -r '.disk_free_gb // 0' <<<"$STORAGE_JSON")"
  if [ "$status" = "fail" ] || awk -v pct="$pct" -v min="$STORAGE_MIN_FREE_PCT" 'BEGIN { exit !(pct < min) }'; then
    [ "$DRY_RUN" -eq 1 ] || notify_storage_abort "$pct" "$gb"
    return 1
  fi
  return 0
}

storage_trend_json() {
  local history="${FLYWHEEL_STORAGE_HISTORY:-$HOME/.local/state/flywheel/storage-history.jsonl}"
  if [ ! -s "$history" ]; then
    jq -nc '{samples:0,latest_pct:null,min_pct:null,delta_pct:null}'
    return 0
  fi
  jq -sc '
    [ .[] | select(.disk_free_pct != null) ] as $rows
    | ($rows[-7:] // []) as $recent
    | {
        samples:($recent | length),
        latest_pct:($recent[-1].disk_free_pct // null),
        min_pct:($recent | map(.disk_free_pct) | min // null),
        delta_pct:(if ($recent | length) > 1 then (($recent[-1].disk_free_pct // 0) - ($recent[0].disk_free_pct // 0)) else null end)
      }' "$history" 2>/dev/null || jq -nc '{samples:0,latest_pct:null,min_pct:null,delta_pct:null,error:"storage_history_parse_failed"}'
}

count_lines() {
  local file="$1"
  awk 'NF { n++ } END { print n + 0 }' "$file" 2>/dev/null || printf '0\n'
}

safe_label() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9_.-' '-'
}

latest_prior_snapshot() {
  local label="$1" today="$2"
  find "$SNAPSHOT_DIR" -maxdepth 1 -type f -name "${label}-*.txt" 2>/dev/null \
    | awk -v t="$today" -F'[-.]' '
        {
          path=$0
          n=split(path, a, "/")
          file=a[n]
          if (match(file, /[0-9]{4}-[0-9]{2}-[0-9]{2}/)) {
            d=substr(file, RSTART, RLENGTH)
            if (d < t) print d "\t" path
          }
        }' \
    | sort \
    | tail -1 \
    | cut -f2-
}

record_group() {
  local name="$1" status="$2" items="$3" snapshot="$4"
  jq -nc \
    --arg name "$name" \
    --arg status "$status" \
    --argjson items "$items" \
    --arg snapshot "$snapshot" \
    '{name:$name,status:$status,items:$items,snapshot:$snapshot}' >>"$GROUPS_FILE"
}

record_item() {
  local source="$1" class="$2" summary="$3" url="$4" high="$5" reason="$6"
  NEW_ITEMS=$((NEW_ITEMS + 1))
  jq -nc \
    --arg source "$source" \
    --arg class "$class" \
    --arg summary "$summary" \
    --arg url "$url" \
    --argjson high "$high" \
    --arg reason "$reason" \
    '{source:$source, accretive_value_class:$class, summary:$summary, url:$url, high_actionable:$high, reason:$reason}' >>"$NEW_ITEMS_FILE"
  if [ "$high" -eq 1 ]; then
    ACTIONABLE_COUNT=$((ACTIONABLE_COUNT + 1))
    jq -nc \
      --arg source "$source" \
      --arg class "$class" \
      --arg summary "$summary" \
      --arg url "$url" \
      --arg reason "$reason" \
      '{source:$source, accretive_value_class:$class, summary:$summary, url:$url, reason:$reason}' >>"$ACTIONABLE_FILE"
  fi
}

github_repo_is_unmodified_fork() {
  local repo="$1"
  local meta is_fork parent_owner parent_name branch compare
  have gh || return 1
  meta="$(gh repo view "Dicklesworthstone/$repo" --json isFork,parent,defaultBranchRef 2>/dev/null)" || return 1
  is_fork="$(jq -r '.isFork // false' <<<"$meta" 2>/dev/null)" || return 1
  [ "$is_fork" = "true" ] || return 1
  parent_owner="$(jq -r '.parent.owner.login // empty' <<<"$meta" 2>/dev/null)" || return 1
  parent_name="$(jq -r '.parent.name // empty' <<<"$meta" 2>/dev/null)" || return 1
  branch="$(jq -r '.defaultBranchRef.name // "main"' <<<"$meta" 2>/dev/null)" || return 1
  [ -n "$parent_owner" ] && [ -n "$parent_name" ] && [ -n "$branch" ] || return 1
  compare="$(gh api "repos/Dicklesworthstone/$repo/compare/${parent_owner}:${branch}...Dicklesworthstone:${branch}" \
    --jq '{status,ahead_by,behind_by,total_commits}' 2>/dev/null)" || return 1
  jq -e '.status == "identical" and .ahead_by == 0 and .total_commits == 0' <<<"$compare" >/dev/null 2>&1
}

compare_and_snapshot() {
  local label="$1" current="$2" today="$3" class="$4" high_default="$5" reason="$6"
  local safe target prior additions count
  safe="$(safe_label "$label")"
  target="$SNAPSHOT_DIR/${safe}-${today}.txt"
  prior="$(latest_prior_snapshot "$safe" "$today")"

  if [ -n "$prior" ] && [ -f "$prior" ]; then
    additions="$TMP_ROOT/${safe}.additions"
    grep -Fvx -f "$prior" "$current" 2>/dev/null | sed '/^[[:space:]]*$/d' | head -50 >"$additions" || true
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      if [ "$label" = "github-repos" ] && github_repo_is_unmodified_fork "$line"; then
        record_item "$label" "archived-signal" "$(printf '%s' "$line" | cut -c1-180)" "$label" 0 "Unmodified fork of an upstream repo; no Jeffrey-authored delta to evaluate"
        continue
      fi
      record_item "$label" "$class" "$(printf '%s' "$line" | cut -c1-180)" "$label" "$high_default" "$reason"
    done <"$additions"
  else
    warn "baseline snapshot for $label; no prior daily snapshot, treating current items as baseline"
  fi

  count="$(count_lines "$current")"
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$SNAPSHOT_DIR"
    cp "$current" "$target"
  else
    target="dry-run:$target"
  fi
  record_group "$label" "ok" "$count" "$target"
}

fetch_url() {
  local url="$1" out="$2"
  local attempt max_time attempts
  max_time="${DAILY_JEFF_FETCH_MAX_TIME:-}"
  attempts="${DAILY_JEFF_FETCH_ATTEMPTS:-}"
  if [ -z "$max_time" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then max_time=5; else max_time=30; fi
  fi
  if [ -z "$attempts" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then attempts=1; else attempts=3; fi
  fi
  for attempt in $(seq 1 "$attempts"); do
    if curl -fsSL --max-time "$max_time" -A "flywheel-daily-jeff-ingest/1.0" "$url" -o "$out" 2>/dev/null; then
      return 0
    fi
    [ "$attempt" -ge "$attempts" ] || sleep "$attempt"
  done
  return 1
}

fetch_github() {
  local today="$1" out="$TMP_ROOT/github-atom.txt" repos="$TMP_ROOT/github-repos.txt"
  local feed_seen=0 feed_limit
  : >"$out"
  : >"$repos"
  feed_limit="${DAILY_JEFF_GITHUB_FEED_LIMIT:-}"
  if [ -z "$feed_limit" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then feed_limit=8; else feed_limit=0; fi
  fi

  if [ -x "$CHECK_SCRIPT" ] || [ -f "$CHECK_SCRIPT" ]; then
    if [ "$DRY_RUN" -eq 0 ]; then
      if ! bash "$CHECK_SCRIPT" >"$TMP_ROOT/check-dicklesworthstone-updates.out" 2>"$TMP_ROOT/check-dicklesworthstone-updates.err"; then
        warn "check-dicklesworthstone-updates.sh returned nonzero; continuing with direct feed fetch"
      fi
      sed -n '1,80p' "$TMP_ROOT/check-dicklesworthstone-updates.out" >>"$out" 2>/dev/null || true
    else
      printf 'dry-run would invoke %s\n' "$CHECK_SCRIPT" >>"$out"
    fi
  else
    warn "GitHub helper missing: $CHECK_SCRIPT"
  fi

  if [ ! -f "$SOURCES_FILE" ]; then
    warn "sources file missing: $SOURCES_FILE"
    record_group "github" "failed" 0 "none"
    FAILED=$((FAILED + 1))
    return 0
  fi

  while IFS= read -r url; do
    url="${url%%#*}"
    url="$(printf '%s' "$url" | awk '{$1=$1; print}')"
    case "$url" in
      https://github.com/*".atom")
        feed_seen=$((feed_seen + 1))
        if [ "$feed_limit" -gt 0 ] && [ "$feed_seen" -gt "$feed_limit" ]; then
          continue
        fi
        tmp="$TMP_ROOT/feed-$(printf '%s' "$url" | shasum -a 256 | awk '{print $1}').xml"
        if fetch_url "$url" "$tmp"; then
          printf 'SOURCE %s\n' "$url" >>"$out"
          python3 - "$tmp" >>"$out" <<'PY' 2>/dev/null || true
import re, sys, xml.etree.ElementTree as ET
path = sys.argv[1]
try:
    root = ET.parse(path).getroot()
except Exception:
    sys.exit(0)
ns = {"a": "http://www.w3.org/2005/Atom"}
for entry in root.findall("a:entry", ns)[:10]:
    title = (entry.findtext("a:title", default="", namespaces=ns) or "").strip()
    updated = (entry.findtext("a:updated", default="", namespaces=ns) or "").strip()
    link = ""
    for el in entry.findall("a:link", ns):
        if el.attrib.get("href"):
            link = el.attrib["href"]
            break
    print(re.sub(r"\\s+", " ", f"{updated} {title} {link}").strip())
PY
        else
          warn "GitHub feed fetch failed: $url"
        fi
        ;;
    esac
  done <"$SOURCES_FILE"
  if [ "$feed_limit" -gt 0 ] && [ "$feed_seen" -gt "$feed_limit" ]; then
    warn "GitHub atom dry-run feed limit applied: fetched ${feed_limit} of ${feed_seen}"
  fi

  if have gh; then
    if gh api users/Dicklesworthstone/repos --paginate --jq '.[].name' >"$repos" 2>"$TMP_ROOT/gh-repos.err"; then
      sort -u "$repos" -o "$repos"
    else
      warn "gh repo list failed; trying unauthenticated API"
      if fetch_url "https://api.github.com/users/Dicklesworthstone/repos?per_page=100" "$TMP_ROOT/repos.json"; then
        jq -r '.[].name' "$TMP_ROOT/repos.json" 2>/dev/null | sort -u >"$repos" || true
      fi
    fi
  elif fetch_url "https://api.github.com/users/Dicklesworthstone/repos?per_page=100" "$TMP_ROOT/repos.json"; then
    jq -r '.[].name' "$TMP_ROOT/repos.json" 2>/dev/null | sort -u >"$repos" || true
  else
    warn "no gh command and GitHub REST fetch failed"
  fi

  if [ ! -s "$out" ] && [ ! -s "$repos" ]; then
    record_group "github" "failed" 0 "none"
    FAILED=$((FAILED + 1))
    return 0
  fi

  FETCHED=$((FETCHED + 1))
  compare_and_snapshot "github-atom" "$out" "$today" "new-tool" 0 "Review Jeff GitHub activity for flywheel applicability"
  compare_and_snapshot "github-repos" "$repos" "$today" "new-tool" 1 "New Jeff repo should be mirrored and evaluated for flywheel reuse"
  mirror_new_repos "$repos" "$today"
}

fetch_jsm() {
  local today="$1" out="$TMP_ROOT/jsm.txt"
  : >"$out"
  if have jsm; then
    if [ "$DRY_RUN" -eq 0 ]; then
      if ! jsm sync >"$TMP_ROOT/jsm-sync.out" 2>"$TMP_ROOT/jsm-sync.err"; then
        warn "jsm sync failed; continuing with jsm status"
      fi
      sed -n '1,80p' "$TMP_ROOT/jsm-sync.out" >>"$out" 2>/dev/null || true
    else
      printf 'dry-run would run jsm sync\n' >>"$out"
    fi
    if jsm status --json >"$TMP_ROOT/jsm-status.json" 2>"$TMP_ROOT/jsm-status.err"; then
      jq -c . "$TMP_ROOT/jsm-status.json" >>"$out" 2>/dev/null || cat "$TMP_ROOT/jsm-status.json" >>"$out"
      FETCHED=$((FETCHED + 1))
      compare_and_snapshot "jsm" "$out" "$today" "skill-update" 0 "JSM status changed; inspect for skill upgrade opportunities"
    else
      warn "jsm status --json failed"
      record_group "jsm" "failed" 0 "none"
      FAILED=$((FAILED + 1))
    fi
  else
    warn "jsm not found"
    record_group "jsm" "failed" 0 "none"
    FAILED=$((FAILED + 1))
  fi
}

fetch_rss() {
  local today="$1" out="$TMP_ROOT/jeff-rss.txt" rss="$TMP_ROOT/jeff-rss.xml"
  : >"$out"
  if fetch_url "https://jeffreyemanuel.com/rss.xml" "$rss"; then
    python3 - "$rss" >"$out" <<'PY' 2>/dev/null || true
import re, sys, xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
channel = root.find("channel")
items = channel.findall("item") if channel is not None else []
for item in items[:20]:
    title = (item.findtext("title") or "").strip()
    link = (item.findtext("link") or "").strip()
    pub = (item.findtext("pubDate") or "").strip()
    print(re.sub(r"\\s+", " ", f"{pub} {title} {link}").strip())
PY
    FETCHED=$((FETCHED + 1))
    compare_and_snapshot "jeffreyemanuel-rss" "$out" "$today" "doctrine-update" 1 "New Jeff writing may change flywheel doctrine"
  else
    warn "jeffreyemanuel.com RSS fetch failed"
    record_group "jeffreyemanuel-rss" "failed" 0 "none"
    FAILED=$((FAILED + 1))
  fi
}

fetch_x() {
  local today="$1" out="$TMP_ROOT/x-doodlestein.txt"
  : >"$out"
  if have x-cli; then
    if x-cli -md user timeline doodlestein --max 20 >"$out" 2>"$TMP_ROOT/x.err"; then
      FETCHED=$((FETCHED + 1))
      compare_and_snapshot "x-doodlestein" "$out" "$today" "tweet-thread" 0 "Tweet thread may contain tactical substrate signal"
    else
      warn "x-cli timeline failed; skipping X source"
      record_group "x-doodlestein" "failed" 0 "none"
      FAILED=$((FAILED + 1))
    fi
  else
    warn "x-cli not found; skipping X source"
    record_group "x-doodlestein" "failed" 0 "none"
    FAILED=$((FAILED + 1))
  fi
}

fetch_agent_flywheel() {
  local today="$1" out="$TMP_ROOT/agent-flywheel.txt" urls_file="$TMP_ROOT/agent-flywheel-urls.txt"
  : >"$out"
  cat >"$urls_file" <<'EOF'
https://agent-flywheel.com/complete-guide
https://agent-flywheel.com/core-flywheel
https://agent-flywheel.com/flywheel
https://agent-flywheel.com/tldr
https://agent-flywheel.com/learn/welcome
EOF

  if [ -f "$SNAPSHOT_DIFF_SCRIPT" ]; then
    if [ "$DRY_RUN" -eq 0 ]; then
      if ! bash "$SNAPSHOT_DIFF_SCRIPT" >"$TMP_ROOT/snapshot-diff.out" 2>"$TMP_ROOT/snapshot-diff.err"; then
        warn "snapshot-diff-fallback.sh reported change or fetch failure; continuing with body snapshot"
      fi
      sed -n '1,120p' "$TMP_ROOT/snapshot-diff.out" >>"$out" 2>/dev/null || true
    else
      printf 'dry-run would invoke %s\n' "$SNAPSHOT_DIFF_SCRIPT" >>"$out"
    fi
  else
    warn "snapshot-diff fallback missing: $SNAPSHOT_DIFF_SCRIPT"
  fi

  while IFS= read -r url; do
    tmp="$TMP_ROOT/site-$(printf '%s' "$url" | shasum -a 256 | awk '{print $1}').html"
    if fetch_url "$url" "$tmp"; then
      bytes="$(wc -c <"$tmp" | tr -d ' ')"
      digest="$(shasum -a 256 "$tmp" | awk '{print $1}')"
      printf '%s bytes=%s sha256=%s\n' "$url" "$bytes" "$digest" >>"$out"
    else
      warn "agent-flywheel page fetch failed: $url"
    fi
  done <"$urls_file"

  if [ -s "$out" ]; then
    FETCHED=$((FETCHED + 1))
    compare_and_snapshot "agent-flywheel" "$out" "$today" "doctrine-update" 1 "Agent Flywheel doctrine changed; inspect for local doctrine updates"
  else
    record_group "agent-flywheel" "failed" 0 "none"
    FAILED=$((FAILED + 1))
  fi
}

refresh_jeff_shadow() {
  local out rc item_count status
  if [ ! -x "$SHADOW_SOCRATICODE_SCRIPT" ]; then
    warn "jeff-shadow refresh helper missing: $SHADOW_SOCRATICODE_SCRIPT"
    return 0
  fi
  out="$TMP_ROOT/jeff-shadow-socraticode.json"
  set +e
  if [ "$DRY_RUN" -eq 1 ]; then
    "$SHADOW_SOCRATICODE_SCRIPT" refresh --dry-run --json >"$out" 2>"$out.err"
  else
    "$SHADOW_SOCRATICODE_SCRIPT" refresh --apply --json >"$out" 2>"$out.err"
  fi
  rc=$?
  set -e
  if ! jq empty "$out" >/dev/null 2>&1; then
    warn "jeff-shadow refresh returned invalid JSON"
    return 0
  fi
  status="$(jq -r '.status // "unknown"' "$out")"
  item_count="$(jq -r '.repo_count // 0' "$out")"
  INDEXED="$(jq -r '.indexed_count // 0' "$out")"
  record_group "jeff-shadow" "$status" "$item_count" "$(jq -r '.state_file // "none"' "$out")"
  if [ "$rc" -ne 0 ]; then
    warn "jeff-shadow refresh exited nonzero: $rc"
  fi
}

mirror_new_repos() {
  local repos_file="$1" today="$2" prior additions repo target
  if [ "$NO_MIRROR" -eq 1 ]; then
    warn "mirror skipped by --no-mirror"
    return 0
  fi

  prior="$(latest_prior_snapshot "github-repos" "$today")"
  if [ -z "$prior" ] || [ ! -f "$prior" ]; then
    warn "no prior github-repos snapshot; treating repo list as baseline and mirroring 0 repos"
    return 0
  fi

  additions="$TMP_ROOT/new-repos.txt"
  grep -Fvx -f "$prior" "$repos_file" 2>/dev/null | sed '/^[[:space:]]*$/d' >"$additions" || true
  if [ ! -s "$additions" ]; then
    return 0
  fi

  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$SHADOW_DIR"
  fi

  while IFS= read -r repo; do
    [ -n "$repo" ] || continue
    target="$SHADOW_DIR/$repo"
    if [ -d "$target/.git" ]; then
      continue
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
      jq -nc --arg repo "$repo" --arg target "$target" '{repo:$repo,target:$target,status:"planned"}' >>"$MIRRORED_FILE"
      continue
    fi
    if git clone --depth 50 "https://github.com/Dicklesworthstone/${repo}" "$target" >"$TMP_ROOT/clone-${repo}.out" 2>"$TMP_ROOT/clone-${repo}.err"; then
      MIRRORED=$((MIRRORED + 1))
      jq -nc --arg repo "$repo" --arg target "$target" '{repo:$repo,target:$target,status:"cloned"}' >>"$MIRRORED_FILE"
      warn "socraticode indexing requires MCP host; repo cloned and ready for codebase_index: $target"
    else
      warn "clone failed for Dicklesworthstone/$repo"
    fi
  done <"$additions"
}

file_actionable_beads() {
  local count=0 line id title description
  if [ "$DRY_RUN" -eq 1 ]; then
    return 0
  fi
  if ! have "$BR_BIN"; then
    warn "br not found; cannot auto-file actionable beads"
    return 0
  fi
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    if [ "$count" -ge "$MAX_BEADS" ]; then
      break
    fi
    title="$(printf '%s' "$line" | jq -r '"[jeff-signal-action] " + .source + ": " + (.summary | tostring | .[0:70])' 2>/dev/null)"
    description="$(printf '%s' "$line" | jq -r '"Source: " + (.url // .source) + ". Detected: " + "'"$(now_iso)"'" + ". Signal class: " + .accretive_value_class + ". Why actionable: " + .reason + ". Apply-to-flywheel hypothesis: evaluate this Jeff signal for doctrine, skill, or substrate upgrade."' 2>/dev/null)"
    if [ -z "$title" ] || [ -z "$description" ]; then
      continue
    fi
    id="$("$BR_BIN" create "$title" --priority 3 --type research --description "$description" --silent 2>/dev/null || true)"
    if [ -n "$id" ]; then
      BEADS_FILED=$((BEADS_FILED + 1))
      jq -nc --arg id "$id" '$id' >>"$TMP_ROOT/beads.jsonl"
      count=$((count + 1))
    else
      warn "failed to file actionable bead: $title"
    fi
  done <"$ACTIONABLE_FILE"
}

write_digest() {
  local today="$1" groups items actionable warnings storage_trend
  DIGEST_PATH="/tmp/daily-jeff-digest-${today}.md"
  groups="$(json_array_file "$GROUPS_FILE")"
  items="$(json_array_file "$NEW_ITEMS_FILE")"
  actionable="$(json_array_file "$ACTIONABLE_FILE")"
  warnings="$(json_array_file "$WARNINGS_FILE")"
  storage_trend="$(storage_trend_json)"
  if [ "$DRY_RUN" -eq 1 ]; then
    return 0
  fi
  {
    printf '# Daily Jeff Digest - %s\n\n' "$today"
    printf '## Today'\''s Jeff signals (ranked accretive value)\n\n'
    printf '%s\n' "$items" | jq -r '
      if length == 0 then "- No new items versus prior snapshots."
      else .[] | "- [" + .accretive_value_class + "] " + .source + ": " + .summary
      end'
    printf '\n## Sources\n\n'
    printf '%s\n' "$groups" | jq -r '.[] | "- " + .name + ": " + .status + " (" + (.items|tostring) + " rows) snapshot=" + .snapshot'
    printf '\n## HIGH-conf actionable\n\n'
    printf '%s\n' "$actionable" | jq -r '
      if length == 0 then "- None."
      else .[] | "- " + .source + ": " + .summary + " — " + .reason
      end'
    printf '\n## Storage\n\n'
    if [ -n "$STORAGE_JSON" ]; then
      printf '%s\n' "$STORAGE_JSON" | jq -r '"- status=" + (.status // "unknown") + " disk_free_pct=" + ((.disk_free_pct // 0)|tostring) + " disk_free_gb=" + ((.disk_free_gb // 0)|tostring) + " developer_dir_gb=" + ((.developer_dir_gb // 0)|tostring) + " stale_baks_count=" + ((.stale_baks_count // 0)|tostring)'
      printf '%s\n' "$storage_trend" | jq -r '"- trend samples=" + ((.samples // 0)|tostring) + " latest_pct=" + ((.latest_pct // "null")|tostring) + " min_pct=" + ((.min_pct // "null")|tostring) + " delta_pct=" + ((.delta_pct // "null")|tostring)'
    else
      printf '%s\n' "- No storage probe result recorded."
    fi
    printf '\n## Warnings\n\n'
    printf '%s\n' "$warnings" | jq -r '
      if length == 0 then "- None."
      else .[] | "- " + .
      end'
  } >"$DIGEST_PATH"
}

write_ledger() {
  local started="$1" duration warnings beads
  [ "$DRY_RUN" -eq 0 ] || return 0
  mkdir -p "$STATE_DIR"
  touch "$LEDGER"
  warnings="$(json_array_file "$WARNINGS_FILE")"
  if [ -s "$TMP_ROOT/beads.jsonl" ]; then
    beads="$(json_array_file "$TMP_ROOT/beads.jsonl")"
  else
    beads="[]"
  fi
  duration=$(( $(date -u +%s) - started ))
  jq -nc \
    --arg ts "$(now_iso)" \
    --arg digest "$DIGEST_PATH" \
    --argjson storage "${STORAGE_JSON:-{\"status\":\"unknown\"}}" \
    --argjson sources_fetched "$FETCHED" \
    --argjson sources_failed "$FAILED" \
    --argjson new_items "$NEW_ITEMS" \
    --argjson mirrored "$MIRRORED" \
    --argjson indexed "$INDEXED" \
    --argjson beads "$beads" \
    --argjson duration "$duration" \
    --argjson warnings "$warnings" \
    '{ts:$ts,storage:$storage,sources_fetched:$sources_fetched,sources_failed:$sources_failed,
      new_items:$new_items,new_repos_mirrored:$mirrored,socraticode_indexed:$indexed,
      actionable_beads_filed:$beads,digest_path:$digest,duration_sec:$duration,
      warnings:$warnings}' >>"$LEDGER"
}

info_json() {
  jq -nc \
    --arg version "$VERSION" \
    --arg script_version "$SCRIPT_VERSION" \
    --arg state_dir "$STATE_DIR" \
    --arg snapshot_dir "$SNAPSHOT_DIR" \
    --arg ledger "$LEDGER" \
    --arg shadow_dir "$SHADOW_DIR" \
    --arg storage_probe "$STORAGE_PROBE" \
    --arg jeff_shadow_script "$SHADOW_SOCRATICODE_SCRIPT" \
    --arg sources_file "$SOURCES_FILE" \
    '{success:true,mode:"info",version:$version,script_version:$script_version,
      state_dir:$state_dir,snapshot_dir:$snapshot_dir,ledger:$ledger,
      shadow_dir:$shadow_dir,jeff_shadow_script:$jeff_shadow_script,sources_file:$sources_file,storage_probe:$storage_probe,
      mutates:["daily storage-history append","daily ledger append","daily snapshots","optional jeff-corpus clones","jeff-shadow clone/fetch refresh","optional br beads"],
      cron_installed:false}'
}

doctor_json() {
  local ok=1 deps storage
  storage="$(storage_probe_json)"
  deps="$(
    jq -nc \
      --arg bash_path "$(command -v bash 2>/dev/null || true)" \
      --arg curl_path "$(command -v curl 2>/dev/null || true)" \
      --arg jq_path "$(command -v jq 2>/dev/null || true)" \
      --arg python3_path "$(command -v python3 2>/dev/null || true)" \
      --arg git_path "$(command -v git 2>/dev/null || true)" \
      --arg br_path "$(command -v "$BR_BIN" 2>/dev/null || true)" \
      --arg gh_path "$(command -v gh 2>/dev/null || true)" \
      --arg jsm_path "$(command -v jsm 2>/dev/null || true)" \
      --arg xcli_path "$(command -v x-cli 2>/dev/null || true)" \
      --arg storage_probe "$STORAGE_PROBE" \
      '[
        {name:"bash", path:$bash_path, required:true, ok:($bash_path!="")},
        {name:"curl", path:$curl_path, required:true, ok:($curl_path!="")},
        {name:"jq", path:$jq_path, required:true, ok:($jq_path!="")},
        {name:"python3", path:$python3_path, required:true, ok:($python3_path!="")},
        {name:"git", path:$git_path, required:true, ok:($git_path!="")},
        {name:"br", path:$br_path, required:false, ok:($br_path!="")},
        {name:"gh", path:$gh_path, required:false, ok:($gh_path!="")},
        {name:"jsm", path:$jsm_path, required:false, ok:($jsm_path!="")},
        {name:"x-cli", path:$xcli_path, required:false, ok:($xcli_path!="")},
        {name:"storage-probe", path:$storage_probe, required:true, ok:($storage_probe!="")}
      ]'
  )"
  have bash || ok=0
  have curl || ok=0
  have jq || ok=0
  have python3 || ok=0
  have git || ok=0
  [ -f "$SOURCES_FILE" ] || ok=0
  [ -x "$STORAGE_PROBE" ] || ok=0
  jq -nc \
    --arg ts "$(now_iso)" \
    --arg version "$VERSION" \
    --arg sources_file "$SOURCES_FILE" \
    --arg check_script "$CHECK_SCRIPT" \
    --arg snapshot_diff_script "$SNAPSHOT_DIFF_SCRIPT" \
    --arg state_dir "$STATE_DIR" \
    --arg snapshot_dir "$SNAPSHOT_DIR" \
    --arg ledger "$LEDGER" \
    --arg shadow_dir "$SHADOW_DIR" \
    --argjson ok "$ok" \
    --argjson deps "$deps" \
    --argjson storage "$storage" \
    '{success:($ok==1),mode:"doctor",checked_at:$ts,version:$version,
      paths:{sources_file:$sources_file,check_script:$check_script,
        snapshot_diff_script:$snapshot_diff_script,state_dir:$state_dir,
        snapshot_dir:$snapshot_dir,ledger:$ledger,shadow_dir:$shadow_dir},
      deps:$deps,
      storage:$storage,
      notes:["--dry-run performs no state writes","cron installation intentionally out of scope"]}'
}

human_doctor() {
  doctor_json | jq -r '
    "daily-jeff-ingest doctor: " + (if .success then "PASS" else "FAIL" end),
    "sources_file=" + .paths.sources_file,
    (.deps[] | "- " + .name + ": " + (if .ok then "ok" else "missing" end))'
}

run_ingest() {
  local started today result warnings groups
  started="$(date -u +%s)"
  today="$(today_utc)"
  DIGEST_PATH="/tmp/daily-jeff-digest-${today}.md"
  if ! storage_preflight; then
    result="$(
      jq -nc \
        --arg ts "$(now_iso)" \
        --arg version "$VERSION" \
        --argjson dry_run "$DRY_RUN" \
        --argjson storage "$STORAGE_JSON" \
        '{success:false,mode:"run",version:$version,ts:$ts,dry_run:($dry_run==1),
          reason:"storage_low_headroom",storage:$storage,warnings:["storage preflight failed; aborting before Jeff diff pull"]}'
    )"
    if [ "$JSON_OUT" -eq 1 ]; then
      printf '%s\n' "$result"
    elif [ "$QUIET" -eq 0 ]; then
      printf '%s\n' "$result" | jq -r '"daily-jeff-ingest: aborted reason=" + .reason + " disk_free_pct=" + ((.storage.disk_free_pct // 0)|tostring)'
    fi
    return 1
  fi
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$STATE_DIR" "$SNAPSHOT_DIR" "$SHADOW_DIR"
  fi

  say "daily-jeff-ingest: starting (${today})"
  fetch_github "$today"
  fetch_jsm "$today"
  fetch_rss "$today"
  fetch_x "$today"
  fetch_agent_flywheel "$today"
  refresh_jeff_shadow
  file_actionable_beads
  write_digest "$today"
  write_ledger "$started"

  warnings="$(json_array_file "$WARNINGS_FILE")"
  groups="$(json_array_file "$GROUPS_FILE")"
  result="$(
    jq -nc \
      --arg ts "$(now_iso)" \
      --arg mode "run" \
      --arg version "$VERSION" \
      --arg digest "$DIGEST_PATH" \
      --arg ledger "$LEDGER" \
      --argjson dry_run "$DRY_RUN" \
      --argjson storage "$STORAGE_JSON" \
      --argjson fetched "$FETCHED" \
      --argjson failed "$FAILED" \
      --argjson new_items "$NEW_ITEMS" \
      --argjson mirrored "$MIRRORED" \
      --argjson indexed "$INDEXED" \
      --argjson beads "$BEADS_FILED" \
      --argjson warnings "$warnings" \
      --argjson groups "$groups" \
      '{success:($fetched > 0),mode:$mode,version:$version,ts:$ts,dry_run:($dry_run==1),storage:$storage,
        sources_fetched:$fetched,sources_failed:$failed,new_items:$new_items,
        new_repos_mirrored:$mirrored,socraticode_indexed:$indexed,
        actionable_beads_filed_count:$beads,digest_path:$digest,ledger:$ledger,
        cron_installed:false,warnings:$warnings,groups:$groups}'
  )"
  if [ "$JSON_OUT" -eq 1 ]; then
    printf '%s\n' "$result"
  elif [ "$QUIET" -eq 0 ]; then
    printf '%s\n' "$result" | jq -r '"daily-jeff-ingest: fetched=" + (.sources_fetched|tostring) + " failed=" + (.sources_failed|tostring) + " new_items=" + (.new_items|tostring) + " digest=" + .digest_path'
    if [ "$EXPLAIN" -eq 1 ]; then
      printf '%s\n' "$result" | jq -r '.warnings[]? | "WARN: " + .'
    fi
  fi
  if [ "$FETCHED" -gt 0 ]; then
    return 0
  fi
  return 1
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --help|-h) MODE="help"; shift ;;
      --info) MODE="info"; shift ;;
      --schema) MODE="schema"; shift ;;
      --examples) MODE="examples"; shift ;;
      --doctor|doctor) MODE="doctor"; shift ;;
      --health|health) MODE="doctor"; shift ;;
      completion) printf 'complete -W "--doctor doctor --health health --json --quiet --dry-run --no-mirror --info --schema --examples completion --help" daily-jeff-ingest.sh\n'; exit 0 ;;
      --json) JSON_OUT=1; shift ;;
      --quiet) QUIET=1; shift ;;
      --dry-run) DRY_RUN=1; shift ;;
      --no-mirror) NO_MIRROR=1; shift ;;
      --explain) EXPLAIN=1; shift ;;
      --storage-fixture)
        [ $# -ge 2 ] || die "--storage-fixture requires a value"
        DAILY_JEFF_STORAGE_FIXTURE="$2"
        shift 2
        ;;
      --max-beads)
        [ $# -ge 2 ] || die "--max-beads requires a value"
        MAX_BEADS="$2"
        case "$MAX_BEADS" in (*[!0-9]*|"") die "--max-beads must be numeric" ;; esac
        shift 2
        ;;
      *) die "unknown argument: $1" ;;
    esac
  done
}

main() {
  parse_args "$@"
  case "$MODE" in
    help) usage ;;
    examples) examples ;;
    schema) schema_json ;;
    info)
      if [ "$JSON_OUT" -eq 1 ]; then info_json; else info_json | jq -r 'to_entries[] | "\(.key)=\(.value)"'; fi
      ;;
    doctor)
      if [ "$JSON_OUT" -eq 1 ]; then doctor_json; else human_doctor; fi
      ;;
    run)
      ensure_tmp
      trap cleanup_tmp EXIT
      run_ingest
      ;;
    *) die "unknown mode: $MODE" ;;
  esac
}

main "$@"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-76-authority-ranked-retrieval-maintenance.md`
