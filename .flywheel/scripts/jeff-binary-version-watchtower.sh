#!/usr/bin/env bash
set -euo pipefail

VERSION="jeff-binary-version-watchtower.v3"
DEFAULT_STATE_DIR="$HOME/.local/state/flywheel"

command="run"
json=0
apply=0
state_dir="${JEFF_BINARY_WATCHTOWER_STATE_DIR:-$DEFAULT_STATE_DIR}"
ntm_bin="${NTM_BIN:-ntm}"
br_bin="${BR_BIN:-br}"
frankenterm_fixture="${FRANKENTERM_RELEASE_FIXTURE:-}"
frankenterm_candidates="${FRANKENTERM_RELEASE_CANDIDATES:-frankenterm franken-term terminal}"
# flywheel-mspmr (AG5): extend watchtower to track openai/codex
# releases. The 0.129 canary on flywheel-x2okl proved unstable
# (background-terminal wedge class — 2 freezes in one session) and
# fleet rollout was halted. The watchtower now polls the codex repo
# for the next stable cut (0.130+) so the orchestrator can re-canary
# at that signal. Fixture path supports test isolation.
codex_fixture="${CODEX_RELEASE_FIXTURE:-}"
codex_repo="${CODEX_REPO:-openai/codex}"
codex_hold_version="${CODEX_HOLD_VERSION:-0.129}"
codex_target_version="${CODEX_TARGET_VERSION:-0.130}"

usage() { printf '%s\n' "Usage: jeff-binary-version-watchtower.sh [doctor|health|run] [--json] [--dry-run|--apply]" "       jeff-binary-version-watchtower.sh [--frankenterm-release-fixture PATH]" "       jeff-binary-version-watchtower.sh --info|--examples|completion"; }

normalize_version() { sed -E 's/\x1b\[[0-9;]*m//g; s/^[^0-9v]*v?//; s/[-+][A-Za-z0-9._-]+.*$//' <<<"${1:-}" | sed -E 's/[^0-9.].*$//' | awk 'NF{print; exit}'; }

version_key() { awk -F. '{printf "%06d%06d%06d\n", $1+0, $2+0, $3+0}' <<<"$(normalize_version "$1")"; }

relation() {
  local current latest c l
  current="$(normalize_version "$1")"
  latest="$(normalize_version "$2")"
  [[ -n "$current" && -n "$latest" ]] || { echo unknown; return; }
  c="$(version_key "$current")"
  l="$(version_key "$latest")"
  [[ "$c" < "$l" ]] && { echo behind; return; }
  [[ "$c" > "$l" ]] && { echo ahead; return; }
  echo current
}

ntm_version_json() { NO_COLOR=1 "$ntm_bin" version --json 2>&1 || true; }

ntm_upgrade_check() { NO_COLOR=1 "$ntm_bin" upgrade --check 2>&1 || true; }

installed_version() { local raw="$1"; jq -er '.version // empty' <<<"$raw" 2>/dev/null || normalize_version "$raw"; }

latest_version() {
  local raw="$1" found
  found="$(awk '/Latest version:/ {print $NF; found=1; exit} /New version available:/ {print $NF; found=1; exit} END{if(!found) exit 1}' <<<"$raw")" || return 1
  normalize_version "$found"
}

existing_bead() { local title="$1"; "$br_bin" list --json 2>/dev/null | jq -er --arg title "$title" '.[]? | select(.status != "closed" and .title == $title) | .id' 2>/dev/null | head -1 || true; }

promote() {
  local rel="$1" installed="$2" latest="$3"
  [[ "$rel" == "behind" ]] || { jq -nc '[]'; return; }
  local title existing desc
  title="[jeff-substrate-version-drift] ntm installed ${installed:-unknown} latest ${latest:-unknown}"
  existing="$(existing_bead "$title")"
  if [[ -n "$existing" ]]; then
    jq -nc --arg id "$existing" --arg title "$title" '[{action:"skipped",reason:"existing_bead",bead_id:$id,title:$title}]'
    return
  fi
  if [[ "$apply" != "1" ]]; then
    jq -nc --arg title "$title" '[{action:"planned",priority:"P1",title:$title}]'
    return
  fi
  desc="Auto-filed by jeff-binary-version-watchtower.sh via ntm version + ntm upgrade --check.\n\nTool: ntm\nInstalled: ${installed:-unknown}\nLatest: ${latest:-unknown}\nRelation: behind\nRecommended command: ntm upgrade --yes\n\nAcceptance gates:\n- Upgrade or intentionally pin this substrate version with a receipt.\n- Re-run .flywheel/scripts/jeff-binary-version-watchtower.sh --json and verify relation is no longer behind.\n- Record installed version evidence and any behavior-breaking follow-up bead."
  local out id
  out="$("$br_bin" create "$title" --type bug --priority P1 --description "$desc" --json 2>&1)" || {
    jq -nc --arg title "$title" --arg raw "$out" '[{action:"error",reason:"br_create_failed",priority:"P1",title:$title,raw:$raw}]'
    return
  }
  id="$(jq -er '.id // .issue.id // empty' <<<"$out" 2>/dev/null || true)"
  jq -nc --arg title "$title" --arg id "$id" '[{action:"created",priority:"P1",title:$title,bead_id:$id}]'
}

frankenterm_release_watch() {
  if [[ -n "$frankenterm_fixture" ]]; then
    jq -c . "$frankenterm_fixture"
    return 0
  fi

  local candidate raw
  for candidate in $frankenterm_candidates; do
    if command -v gh >/dev/null 2>&1 && raw="$(gh repo view "Dicklesworthstone/$candidate" --json name,url,isPrivate,latestRelease,pushedAt,description 2>/dev/null)"; then
      jq -nc --arg candidate "$candidate" --argjson raw "$raw" '
        {
          candidate:$candidate,
          repo:("Dicklesworthstone/" + ($raw.name // $candidate)),
          url:($raw.url // ("https://github.com/Dicklesworthstone/" + $candidate)),
          repo_public:(if $raw.isPrivate == true then false else true end),
          latest_release:($raw.latestRelease.tagName // null),
          pushed_at:($raw.pushedAt // null),
          description:($raw.description // null),
          status:(if ($raw.latestRelease.tagName // null) then "released" else "public_no_release" end)
        }'
    else
      jq -nc --arg candidate "$candidate" '{candidate:$candidate,repo:("Dicklesworthstone/" + $candidate),url:("https://github.com/Dicklesworthstone/" + $candidate),repo_public:false,latest_release:null,pushed_at:null,description:null,status:"not_found"}'
    fi
  done | jq -cs '.'
}

# flywheel-mspmr (AG5): codex release tracker. Polls openai/codex for
# the next stable cut so the orchestrator can re-canary 0.130 when it
# lands. Returns one row with status:
#   - hold_target_not_released: latest_release is the held version (0.129)
#     OR no release tag is reachable; canary remains suspended
#   - target_released: latest_release ≥ codex_target_version (0.130);
#     re-canary signal — operator should plan rollout
#   - newer_than_target: latest_release > target (e.g., 0.131);
#     same as target_released; the held version (0.129) is no longer
#     the latest cut
#   - unknown: gh unavailable or no fixture
codex_release_watch() {
  if [[ -n "$codex_fixture" ]]; then
    jq -c . "$codex_fixture"
    return 0
  fi
  local raw
  if command -v gh >/dev/null 2>&1 && raw="$(gh repo view "$codex_repo" --json name,url,isPrivate,latestRelease,pushedAt,description 2>/dev/null)"; then
    jq -nc \
      --arg repo "$codex_repo" \
      --arg hold "$codex_hold_version" \
      --arg target "$codex_target_version" \
      --argjson raw "$raw" '
      ($raw.latestRelease.tagName // null) as $tag |
      (if $tag then ($tag | gsub("^[^0-9v]*v?"; "") | gsub("[-+].*"; "")) else null end) as $tag_v |
      def vkey($v):
        if $v == null then null
        else ($v | split(".") | map(tonumber? // 0) + [0,0,0])[0:3] | reduce .[] as $n (0; . * 1000000 + $n)
        end;
      vkey($tag_v) as $tk |
      vkey($target) as $targetk |
      vkey($hold) as $holdk |
      {
        repo: $repo,
        url: ($raw.url // ("https://github.com/" + $repo)),
        repo_public: (if $raw.isPrivate == true then false else true end),
        latest_release: $tag,
        latest_release_normalized: $tag_v,
        pushed_at: ($raw.pushedAt // null),
        hold_version: $hold,
        target_version: $target,
        status: (
          if $tk == null then "unknown"
          elif $tk >= $targetk then
            (if $tk > $targetk then "newer_than_target" else "target_released" end)
          else "hold_target_not_released"
          end
        ),
        recanary_recommended: ($tk != null and $tk >= $targetk)
      }
    '
  else
    jq -nc \
      --arg repo "$codex_repo" \
      --arg hold "$codex_hold_version" \
      --arg target "$codex_target_version" \
      '{
        repo: $repo,
        url: ("https://github.com/" + $repo),
        repo_public: null,
        latest_release: null,
        latest_release_normalized: null,
        pushed_at: null,
        hold_version: $hold,
        target_version: $target,
        status: "unknown",
        recanary_recommended: false
      }'
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    doctor|health|run) command="$1" ;;
    --json) json=1 ;;
    --dry-run) ;;
    --apply) apply=1 ;;
    --state-dir) state_dir="$2"; shift ;;
    --repo-root|--fixture|--developer-root) shift ;;
    --frankenterm-release-fixture) frankenterm_fixture="$2"; shift ;;
    --codex-release-fixture) codex_fixture="$2"; shift ;;
    --br-bin) br_bin="$2"; shift ;;
    --ntm-bin) ntm_bin="$2"; shift ;;
    --now) shift ;;
    --no-fetch) ;;
    --help|-h|help) usage; exit 0 ;;
    --info) jq -nc --arg v "$VERSION" '{command:"jeff-binary-version-watchtower",version:$v,native:["ntm version --json","ntm upgrade --check"],mutates:["optional br beads with --apply","ledger append with --apply"]}'; exit 0 ;;
    --examples) printf '%s\n' ".flywheel/scripts/jeff-binary-version-watchtower.sh --dry-run --json" ".flywheel/scripts/jeff-binary-version-watchtower.sh --apply --json"; exit 0 ;;
    completion) printf '%s\n' 'complete -W "doctor health run --json --dry-run --apply --fixture --info --examples completion --help" jeff-binary-version-watchtower.sh'; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

checked_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
version_raw="$(ntm_version_json)"
upgrade_raw="$(ntm_upgrade_check)"
installed="$(installed_version "$version_raw")"
latest="$(latest_version "$upgrade_raw" || true)"
rel="$(relation "$installed" "$latest")"
status="$([[ "$rel" == behind ]] && echo fail || { [[ "$rel" == unknown ]] && echo warn || echo pass; })"
promotions="$(promote "$rel" "$installed" "$latest")"
frankenterm_watch="$(frankenterm_release_watch)"
codex_watch="$(codex_release_watch)"

result="$(jq -nc --arg schema "$VERSION" --arg checked_at "$checked_at" --arg status "$status" --arg installed "$installed" --arg latest "$latest" --arg relation "$rel" --arg state_dir "$state_dir" --arg binary_path "$(command -v "$ntm_bin" 2>/dev/null || true)" --argjson promotions "$promotions" --argjson frankenterm_watch "$frankenterm_watch" --argjson codex_watch "$codex_watch" '{schema_version:$schema,checked_at:$checked_at,status:$status,cadence:"hourly",canonical_binary_count:1,release_watch_count:(($frankenterm_watch | length) + 1),stale_count:(if $relation == "behind" then 1 else 0 end),unknown_count:(if $relation == "unknown" then 1 else 0 end),highest_priority:(if $relation == "behind" then "P1" else null end),rows:[{name:"ntm",repo:"ntm",binary_path:$binary_path,installed_version:$installed,latest_version:$latest,latest_source:"ntm upgrade --check",relation:$relation,status:(if $relation == "behind" then "stale" elif $relation == "unknown" then "unknown" else "ok" end),recommended_command:(if $relation == "behind" then "ntm upgrade --yes" else null end),upgrade_mutation_invoked:false}],watchlists:{frankenterm_release:{cadence:"daily",candidates:($frankenterm_watch | map(.candidate)),public_count:($frankenterm_watch | map(select(.repo_public == true)) | length),release_count:($frankenterm_watch | map(select(.latest_release != null)) | length),status:(if ($frankenterm_watch | map(select(.latest_release != null)) | length) > 0 then "released" elif ($frankenterm_watch | map(select(.repo_public == true)) | length) > 0 then "public_no_release" else "not_found" end),rows:$frankenterm_watch},codex_release:{cadence:"daily",repo:$codex_watch.repo,hold_version:$codex_watch.hold_version,target_version:$codex_watch.target_version,latest_release:$codex_watch.latest_release,status:$codex_watch.status,recanary_recommended:$codex_watch.recanary_recommended,source_bead:"flywheel-mspmr",row:$codex_watch}},stale:(if $relation == "behind" then [{name:"ntm",repo:"ntm",installed_version:$installed,latest_version:$latest,relation:$relation,status:"stale"}] else [] end),promotions:$promotions,warnings:[],state_dir:$state_dir}')"

if [[ "$apply" == "1" ]]; then
  mkdir -p "$state_dir"
  ledger="$state_dir/jeff-binary-version-watchtower.jsonl"
  printf '%s\n' "$result" >>"$ledger"
  result="$(jq -c --arg ledger "$ledger" '. + {ledger:$ledger}' <<<"$result")"
fi

if [[ "$json" == "1" || "$command" =~ ^(doctor|health|run)$ ]]; then
  printf '%s\n' "$result"
else
  jq -r '"jeff-binary-version-watchtower status=\(.status) stale=\(.stale_count)"' <<<"$result"
fi

[[ "$status" == fail && "$command" =~ ^(doctor|health)$ ]] && exit 1
exit 0
