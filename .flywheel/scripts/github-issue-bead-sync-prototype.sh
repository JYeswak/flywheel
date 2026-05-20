#!/usr/bin/env bash
# github-issue-bead-sync-prototype.sh
#
# flywheel-cli-surface: false   (prototype; canonical CLI is follow-up bead)
# Bead: flywheel-wukwc
# Purpose: prove the GitHub-issue → bead polling path for ONE repo (JYeswak/flywheel).
#          Read-only against GitHub. Mutates: bead store (via `br create`) and
#          the registry JSONL.
#
# Inputs (env, all optional):
#   REPO              default: JYeswak/flywheel
#   BR_BIN            default: $HOME/.cargo/bin/br
#   STATE_DIR         default: $HOME/.local/state/flywheel/issue-bead-sync
#   PRIORITY          default: P2
#   DRY_RUN           default: 0  (when 1: skips br create, still writes a dry receipt)
#   MAX_ISSUES        default: 100
#
# Outputs:
#   stdout: human summary
#   $STATE_DIR/registry.jsonl  (append-only minted-bead rows)
#   $STATE_DIR/state.json      (last-tick state, overwritten atomically)
#   $STATE_DIR/receipts/<ts>-receipt.json (one per run)
#
# Doctrine refs:
#   - feedback_no_push_ntm_br.md (NEVER push to Dicklesworthstone/* — we don't)
#   - feedback_two_truth_sources_before_decide.md (close-reconciler is follow-up bead)
#   - feedback_canonical_cli_at_dispatch.md (canonical CLI is follow-up bead)
#   - feedback_orch_wake_event_driven_not_time_based.md (poll only on discovery)
#
set -euo pipefail

REPO="${REPO:-JYeswak/flywheel}"
BR_BIN="${BR_BIN:-$HOME/.cargo/bin/br}"
STATE_DIR="${STATE_DIR:-$HOME/.local/state/flywheel/issue-bead-sync}"
PRIORITY="${PRIORITY:-P2}"
DRY_RUN="${DRY_RUN:-0}"
MAX_ISSUES="${MAX_ISSUES:-100}"

mkdir -p "$STATE_DIR/receipts"
REGISTRY="$STATE_DIR/registry.jsonl"
STATE_JSON="$STATE_DIR/state.json"
touch "$REGISTRY"

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }
RUN_TS="$(ts)"
RECEIPT="$STATE_DIR/receipts/${RUN_TS//:/-}-receipt.json"

err() { printf 'ERROR: %s\n' "$*" >&2; }
die() { err "$*"; exit 1; }

command -v gh   >/dev/null 2>&1 || die "gh CLI not on PATH"
command -v jq   >/dev/null 2>&1 || die "jq not on PATH"
[[ -x "$BR_BIN" ]] || die "br not executable at $BR_BIN"

# --- 1. rate-limit guard --------------------------------------------------
rate_remaining="$(gh api rate_limit --jq '.resources.core.remaining' 2>/dev/null || echo 0)"
if [[ "${rate_remaining:-0}" -lt 50 ]]; then
  cat >"$RECEIPT" <<JSON
{"schema_version":"flywheel.issue_bead_sync_receipt.v1","ts":"$RUN_TS","repo":"$REPO","aborted":"rate_limit_guard","rate_remaining":$rate_remaining}
JSON
  die "rate-limit guard: only $rate_remaining core requests remaining; abort tick"
fi

# --- 2. fetch open issues -------------------------------------------------
issues_json="$(gh issue list --repo "$REPO" --state open --limit "$MAX_ISSUES" \
  --json number,title,body,labels,createdAt,updatedAt,url,state,isPullRequest 2>/dev/null || echo '[]')"
issue_count="$(jq 'length' <<<"$issues_json")"

# --- 3. load existing registry URLs --------------------------------------
existing_urls="$(jq -rs '[.[] | .github_issue_url] | unique' "$REGISTRY" 2>/dev/null || echo '[]')"

# --- 4. iterate & mint ----------------------------------------------------
minted=0
already=0
skipped_pr=0
skipped_dry=0
minted_ids=()

while IFS= read -r row; do
  [[ -z "$row" ]] && continue

  url="$(jq -r '.url' <<<"$row")"
  num="$(jq -r '.number' <<<"$row")"
  title="$(jq -r '.title' <<<"$row")"
  body="$(jq -r '.body // ""' <<<"$row")"
  is_pr="$(jq -r '.isPullRequest // false' <<<"$row")"
  labels_csv="$(jq -r '[.labels[].name] | join(",")' <<<"$row")"
  created_at="$(jq -r '.createdAt' <<<"$row")"

  # Skip PRs — they are not issues for sync purposes (PRs against us are a separate class).
  if [[ "$is_pr" == "true" ]]; then
    skipped_pr=$((skipped_pr + 1))
    continue
  fi

  # Skip if already in registry.
  if jq -e --arg u "$url" 'any(.[]; . == $u)' <<<"$existing_urls" >/dev/null; then
    already=$((already + 1))
    continue
  fi

  # Compose synthetic labels.
  repo_short="${REPO//\//-}"   # JYeswak/flywheel -> JYeswak-flywheel
  syn_labels="source:github,source:gh-issue,repo:${repo_short}"
  if [[ -n "$labels_csv" ]]; then
    full_labels="${syn_labels},${labels_csv}"
  else
    full_labels="$syn_labels"
  fi

  # Slug: gh-<repo>-<num>  (lowercased by br normalizer).
  slug="gh-$(echo "${REPO##*/}" | tr 'A-Z' 'a-z')-$num"

  if [[ "$DRY_RUN" == "1" ]]; then
    skipped_dry=$((skipped_dry + 1))
    continue
  fi

  # Bead description: prefix with issue URL line so it's visible in `br show`.
  description="GitHub issue: $url

$body"

  # Mint.
  if create_json="$("$BR_BIN" create "$title" \
        --type task \
        --priority "$PRIORITY" \
        --slug "$slug" \
        --labels "$full_labels" \
        --external-ref "$url" \
        --description "$description" \
        --json 2>/dev/null)"; then
    bead_id="$(jq -r '.id // .issue.id // empty' <<<"$create_json")"
    if [[ -z "$bead_id" ]]; then
      err "br create returned no id for issue $url; skipping"
      continue
    fi
    minted_ids+=("$bead_id")

    # Append registry row.
    jq -nc \
      --arg sv "flywheel.issue_bead_sync.v1" \
      --arg ts "$RUN_TS" \
      --arg url "$url" \
      --argjson num "$num" \
      --arg repo "$REPO" \
      --arg state "open" \
      --arg created "$created_at" \
      --arg labels_csv "$labels_csv" \
      --arg bead_id "$bead_id" \
      --arg pri "$PRIORITY" \
      '{schema_version:$sv, ts:$ts,
        github_issue_url:$url, github_issue_number:$num,
        github_repo:$repo, github_state_at_mint:$state,
        github_created_at:$created,
        github_labels:($labels_csv | split(",") | map(select(length>0))),
        bead_id:$bead_id, bead_priority:$pri,
        minted_by:"github-issue-bead-sync-prototype.sh", minted_at:$ts}' \
      >>"$REGISTRY"

    minted=$((minted + 1))
  else
    err "br create FAILED for issue $url"
  fi

done < <(jq -c '.[]' <<<"$issues_json")

# --- 5. write state.json (atomic) ----------------------------------------
tmp_state="$(mktemp "${STATE_JSON}.XXXXXX")"
jq -nc \
  --arg sv "flywheel.issue_bead_sync_state.v1" \
  --arg ts "$RUN_TS" \
  --arg repo "$REPO" \
  --argjson minted "$minted" \
  --argjson already "$already" \
  --argjson skipped_pr "$skipped_pr" \
  --argjson skipped_dry "$skipped_dry" \
  --argjson rate_remaining "${rate_remaining:-0}" \
  '{schema_version:$sv, last_poll_ts:$ts, repos_synced:[$repo],
    minted_this_tick:$minted, already_present:$already,
    skipped_pr:$skipped_pr, skipped_dry:$skipped_dry,
    rate_remaining:$rate_remaining}' >"$tmp_state"
mv -f "$tmp_state" "$STATE_JSON"

# --- 6. write receipt ----------------------------------------------------
jq -nc \
  --arg sv "flywheel.issue_bead_sync_receipt.v1" \
  --arg ts "$RUN_TS" \
  --arg repo "$REPO" \
  --argjson issue_count "$issue_count" \
  --argjson minted "$minted" \
  --argjson already "$already" \
  --argjson skipped_pr "$skipped_pr" \
  --argjson skipped_dry "$skipped_dry" \
  --arg bead "flywheel-wukwc" \
  --argjson dry "$([[ "$DRY_RUN" == 1 ]] && echo true || echo false)" \
  --argjson minted_ids "$(printf '%s\n' "${minted_ids[@]+"${minted_ids[@]}"}" | jq -R . | jq -s .)" \
  '{schema_version:$sv, ts:$ts, source_bead:$bead, repo:$repo,
    dry_run:$dry, issue_count:$issue_count,
    minted:$minted, already_present:$already,
    skipped_pr:$skipped_pr, skipped_dry:$skipped_dry,
    minted_bead_ids:$minted_ids}' >"$RECEIPT"

# --- 7. summary ----------------------------------------------------------
cat <<EOF
[github-issue-bead-sync-prototype] repo=$REPO ts=$RUN_TS
  open issues fetched : $issue_count
  minted beads        : $minted
  already in registry : $already
  PRs skipped         : $skipped_pr
  dry-run skipped     : $skipped_dry
  registry            : $REGISTRY
  state               : $STATE_JSON
  receipt             : $RECEIPT
EOF
