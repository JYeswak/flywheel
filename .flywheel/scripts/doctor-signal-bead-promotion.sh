#!/usr/bin/env bash
set -euo pipefail

REPO="/Users/josh/Developer/flywheel"
LOOP_BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
BR_BIN="${BR_BIN:-br}"
DRY_RUN="${DOCTOR_SIGNAL_DRY_RUN:-0}"
ROOT_CAUSE_LEAKAGE="${DOCTOR_SIGNAL_ROOT_CAUSE_LEAKAGE-flywheel-osz1}"
ROOT_CAUSE_DB_FAIL="${DOCTOR_SIGNAL_ROOT_CAUSE_DB_FAIL-flywheel-osz1}"
ROOT_CAUSE_PUNT="${DOCTOR_SIGNAL_ROOT_CAUSE_PUNT-flywheel-7lby}"
ROOT_CAUSE_STORAGE="${DOCTOR_SIGNAL_ROOT_CAUSE_STORAGE-flywheel-2zsj}"
ROOT_CAUSE_HEADLESS_BROWSER="${DOCTOR_SIGNAL_ROOT_CAUSE_HEADLESS_BROWSER-flywheel-3ck3}"
ROOT_CAUSE_AGENTMAIL_IDENTITY="${DOCTOR_SIGNAL_ROOT_CAUSE_AGENTMAIL_IDENTITY-flywheel-g9mi}"
ROOT_CAUSE_DAILY_REPORT="${DOCTOR_SIGNAL_ROOT_CAUSE_DAILY_REPORT-flywheel-o7dq}"
ROOT_CAUSE_REPO_LOCAL_CLI="${DOCTOR_SIGNAL_ROOT_CAUSE_REPO_LOCAL_CLI-flywheel-jbe}"
ROOT_CAUSE_MONOLITHIC_FILE_DEBT="${DOCTOR_SIGNAL_ROOT_CAUSE_MONOLITHIC_FILE_DEBT-flywheel-useh}"
ROOT_CAUSE_PEER_ORCH_BLOCKER="${DOCTOR_SIGNAL_ROOT_CAUSE_PEER_ORCH_BLOCKER-flywheel-vc3e}"
ROOT_CAUSE_WIRE_OR_EXPLAIN="${DOCTOR_SIGNAL_ROOT_CAUSE_WIRE_OR_EXPLAIN-flywheel-2eow}"
ROOT_CAUSE_PWS_FALSE_IDLE="${DOCTOR_SIGNAL_ROOT_CAUSE_PWS_FALSE_IDLE-flywheel-yqbku}"
ROOT_CAUSE_DISPATCH_CONTRACT="${DOCTOR_SIGNAL_ROOT_CAUSE_DISPATCH_CONTRACT-}"
DISPATCH_CONTRACT_THRESHOLD="${DOCTOR_SIGNAL_DISPATCH_CONTRACT_THRESHOLD:-5}"
ROOT_CAUSE_FLEET_SKILL_DISCOVERY="${DOCTOR_SIGNAL_ROOT_CAUSE_FLEET_SKILL_DISCOVERY-}"
FLEET_SKILL_DISCOVERY_PENDING_THRESHOLD="${DOCTOR_SIGNAL_FLEET_SKILL_DISCOVERY_PENDING_THRESHOLD:-1}"
FLEET_SKILL_DISCOVERY_SUSPICIOUS_THRESHOLD="${DOCTOR_SIGNAL_FLEET_SKILL_DISCOVERY_SUSPICIOUS_THRESHOLD:-1}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      REPO="${2:?missing --repo value}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      printf '{"action":"error","reason":"unknown_arg","arg":"%s"}\n' "$1"
      exit 2
      ;;
    *)
      REPO="$1"
      shift
      ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  printf '{"action":"error","reason":"jq_missing"}\n'
  exit 1
fi

if ! command -v "$BR_BIN" >/dev/null 2>&1; then
  if [ -x "$HOME/.cargo/bin/br" ]; then
    BR_BIN="$HOME/.cargo/bin/br"
  else
    printf '{"action":"error","reason":"br_missing"}\n'
    exit 1
  fi
fi

doctor_json() {
  if [ -n "${DOCTOR_SIGNAL_DOCTOR_JSON:-}" ]; then
    printf '%s\n' "$DOCTOR_SIGNAL_DOCTOR_JSON"
  elif [ -n "${DOCTOR_SIGNAL_DOCTOR_JSON_FILE:-}" ]; then
    cat "$DOCTOR_SIGNAL_DOCTOR_JSON_FILE"
  else
    "$LOOP_BIN" doctor --repo "$REPO" --json 2>/dev/null || true
  fi
}

issues_json() {
  (cd "$REPO" && "$BR_BIN" list --json)
}

issues_json_all() {
  (cd "$REPO" && "$BR_BIN" list --all --json --limit 0)
}

cutoff_24h() {
  python3 - <<'PY' 2>/dev/null || date -u -v-24H +%Y-%m-%dT%H:%M:%SZ
import datetime
print((datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(hours=24)).strftime("%Y-%m-%dT%H:%M:%SZ"))
PY
}

matching_issue() {
  local pattern="$1"
  issues_json | jq -r --arg pattern "$pattern" '
    (if type == "array" then .[] else .issues[]? end)
    | select(.status != "closed")
    | select((.title // "") | test($pattern; "i"))
    | [.id, (.priority // 4 | tostring)] | @tsv
  ' | head -1
}

recent_closed_auto_doctor() {
  local symptom="$1" cutoff
  cutoff="$(cutoff_24h)"
  issues_json_all | jq -r --arg pat "[auto-doctor:$symptom]" --arg cutoff "$cutoff" '
    (if type == "array" then .[] else .issues[]? end)
    | select(.status == "closed")
    | select((.title // "") | contains($pat))
    | select((.updated_at // .closed_at // "") > $cutoff)
    | .id
  ' | head -1
}

root_cause_for_symptom() {
  case "$1" in
    leakage) printf '%s\n' "$ROOT_CAUSE_LEAKAGE" ;;
    db_fail) printf '%s\n' "$ROOT_CAUSE_DB_FAIL" ;;
    punt) printf '%s\n' "$ROOT_CAUSE_PUNT" ;;
    storage) printf '%s\n' "$ROOT_CAUSE_STORAGE" ;;
    headless_browser) printf '%s\n' "$ROOT_CAUSE_HEADLESS_BROWSER" ;;
    agentmail_identity) printf '%s\n' "$ROOT_CAUSE_AGENTMAIL_IDENTITY" ;;
    daily_report) printf '%s\n' "$ROOT_CAUSE_DAILY_REPORT" ;;
    repo_local_cli) printf '%s\n' "$ROOT_CAUSE_REPO_LOCAL_CLI" ;;
    monolithic_file_debt) printf '%s\n' "$ROOT_CAUSE_MONOLITHIC_FILE_DEBT" ;;
    peer_orch_blocker) printf '%s\n' "$ROOT_CAUSE_PEER_ORCH_BLOCKER" ;;
    wire_or_explain) printf '%s\n' "$ROOT_CAUSE_WIRE_OR_EXPLAIN" ;;
    pws_false_idle) printf '%s\n' "$ROOT_CAUSE_PWS_FALSE_IDLE" ;;
    dispatch_contract) printf '%s\n' "$ROOT_CAUSE_DISPATCH_CONTRACT" ;;
    fleet_skill_discovery) printf '%s\n' "$ROOT_CAUSE_FLEET_SKILL_DISCOVERY" ;;
    *) printf '\n' ;;
  esac
}

root_cause_open() {
  local symptom="$1" root
  root="$(root_cause_for_symptom "$symptom")"
  [ -n "$root" ] || return 0
  { (cd "$REPO" && "$BR_BIN" show "$root" --json 2>/dev/null) || printf '[]\n'; } | jq -r '
    .[0]? | select((.status // "") != "closed") | .id // empty
  ' | head -1
}

boost_priority_zero() {
  local id="$1" priority="$2"
  if [ -n "$id" ] && [ "${priority:-4}" != "0" ]; then
    if [ "$DRY_RUN" = "1" ]; then
      printf 'dry-run-boosted:%s' "$id"
      return 0
    fi
    (cd "$REPO" && "$BR_BIN" update "$id" --priority 0 --json >/dev/null)
    printf 'boosted:%s' "$id"
  else
    printf 'matched:%s' "$id"
  fi
}

create_bead() {
  local title="$1" description="$2"
  if [ "$DRY_RUN" = "1" ]; then
    printf 'dry-run:%s\n' "$(printf '%s' "$title" | shasum -a 256 | awk '{print substr($1,1,12)}')"
    return 0
  fi
  (cd "$REPO" && "$BR_BIN" create "$title" \
    --type bug \
    --priority 0 \
    --description "$description" \
    --json) | jq -r '.id // .issue.id // empty'
}

handle_symptom() {
  local symptom="$1" match_pattern="$2" title="$3" description="$4"
  local match issue_id priority recent_closed root_open bead_id

  match="$(matching_issue "$match_pattern")"
  if [ -n "$match" ]; then
    issue_id="$(awk '{print $1}' <<<"$match")"
    priority="$(awk '{print $2}' <<<"$match")"
    actions+=("$(boost_priority_zero "$issue_id" "$priority"):$symptom")
    return 0
  fi

  recent_closed="$(recent_closed_auto_doctor "$symptom")"
  if [ -n "$recent_closed" ]; then
    actions+=("skipped:$symptom:recently_closed:$recent_closed")
    return 0
  fi

  root_open="$(root_cause_open "$symptom")"
  if [ -n "$root_open" ]; then
    actions+=("matched:$symptom:root_cause_open:$root_open")
    return 0
  fi

  bead_id="$(create_bead "$title" "$description")"
  actions+=("created:$bead_id:$symptom")
}

DOCTOR_JSON="$(doctor_json)"
if ! jq -e . >/dev/null 2>&1 <<<"$DOCTOR_JSON"; then
  jq -nc --arg reason "doctor_json_invalid" '{action:"error",reason:$reason}'
  exit 1
fi

STATUS="$(jq -r '.status // "unknown"' <<<"$DOCTOR_JSON")"
ROOT_DRIFT="$(jq -r '.canonical_root_drift.drift // false' <<<"$DOCTOR_JSON")"
DOCTRINE_3_SURFACE_DIVERGENT_COUNT="$(jq -r '.doctrine_3_surface_divergent_count // .doctrine_3_surface_divergence.doctrine_3_surface_divergent_count // 0' <<<"$DOCTOR_JSON")"
FLEET_L_RULE_LAG_COUNT="$(jq -r '.fleet_repo_l_rule_lag_count // .fleet_l_rule_lag.fleet_repo_l_rule_lag_count // 0' <<<"$DOCTOR_JSON")"
PUNTED_COUNT="$(jq -r '.ticks_punted_count // .l70_chain_state.ticks_punted_count // 0' <<<"$DOCTOR_JSON")"
STORAGE_STATUS="$(jq -r '.storage.status // "ok"' <<<"$DOCTOR_JSON")"
STORAGE_FREE_PCT="$(jq -r '.storage.disk_free_pct // 100' <<<"$DOCTOR_JSON")"
STORAGE_STALE_BAKS="$(jq -r '.storage.stale_baks_count // 0' <<<"$DOCTOR_JSON")"
STORAGE_TRIGGER=0
if [ "$STORAGE_STATUS" = "fail" ] || awk -v pct="${STORAGE_FREE_PCT:-100}" 'BEGIN { exit !(pct < 10) }' || [ "${STORAGE_STALE_BAKS:-0}" -gt 5 ]; then
  STORAGE_TRIGGER=1
fi
HEADLESS_BROWSER_STATUS="$(jq -r '.agent_browser_leak.status // "pass"' <<<"$DOCTOR_JSON")"
HEADLESS_BROWSER_COUNT="$(jq -r '.agent_browser_leak.headless_agent_browser_count // .headless_agent_browser_count // 0' <<<"$DOCTOR_JSON")"
HEADLESS_BROWSER_OLDEST="$(jq -r '.agent_browser_leak.oldest_age_minutes // 0' <<<"$DOCTOR_JSON")"
HEADLESS_BROWSER_TRIGGER=0
if [ "$HEADLESS_BROWSER_STATUS" = "fail" ] || [ "${HEADLESS_BROWSER_COUNT:-0}" -gt 5 ] || [ "${HEADLESS_BROWSER_OLDEST:-0}" -gt 60 ]; then
  HEADLESS_BROWSER_TRIGGER=1
fi
IDENTITY_REGISTRY_DRIFT="$(jq -r '.identity_registry.drift_count // .identity_registry.identity_registry_drift // .identity_registry_drift // 0' <<<"$DOCTOR_JSON")"
IDENTITY_TOKEN_ORPHAN="$(jq -r '.identity_registry.orphan_token_count // .identity_registry.identity_token_orphan // .identity_token_orphan // 0' <<<"$DOCTOR_JSON")"
ORPHAN_TOKENS_UNSWEPT="$(jq -r '.identity_registry.orphan_tokens_unswept_count // .orphan_tokens_unswept_count // 0' <<<"$DOCTOR_JSON")"
IDENTITY_ROTATION_COUNT_24H="$(jq -r '.identity_registry.identity_rotation_count_24h // .identity_rotation_count_24h // 0' <<<"$DOCTOR_JSON")"
IDENTITY_CHAIN_MAX_LENGTH="$(jq -r '.identity_registry.identity_chain_max_length // .identity_chain_max_length // 0' <<<"$DOCTOR_JSON")"
AGENTMAIL_PENDING_REGISTRATION_BROADCASTS="$(jq -r '.agentmail_pending_registration_broadcasts_count // empty' <<<"$DOCTOR_JSON")"
[ -n "$AGENTMAIL_PENDING_REGISTRATION_BROADCASTS" ] || AGENTMAIL_PENDING_REGISTRATION_BROADCASTS="$IDENTITY_REGISTRY_DRIFT"
AGENTMAIL_IDENTITY_TRIGGER=0
if [ "${AGENTMAIL_PENDING_REGISTRATION_BROADCASTS:-0}" -gt 0 ] || [ "${IDENTITY_TOKEN_ORPHAN:-0}" -gt 0 ] || [ "${ORPHAN_TOKENS_UNSWEPT:-0}" -gt 0 ] || [ "${IDENTITY_CHAIN_MAX_LENGTH:-0}" -gt 3 ]; then
  AGENTMAIL_IDENTITY_TRIGGER=1
fi
DAILY_REPORT_STATUS="$(jq -r '.daily_report.status // "pass"' <<<"$DOCTOR_JSON")"
DAILY_REPORT_AGE="$(jq -r '.daily_report_age_hours // .daily_report.daily_report_age_hours // 0' <<<"$DOCTOR_JSON")"
DAILY_REPORT_TRIGGER=0
if [ "$DAILY_REPORT_STATUS" = "fail" ] || awk -v age="${DAILY_REPORT_AGE:-0}" 'BEGIN { exit !(age > 36) }'; then
  DAILY_REPORT_TRIGGER=1
fi
REPO_LOCAL_CLIS_BELOW="$(jq -r '.repo_local_clis_below_canonical_floor // 0' <<<"$DOCTOR_JSON")"
PEER_ORCH_IDLE_ON_BLOCKER_COUNT="$(jq -r '.peer_orch_idle_on_blocker_count // .peer_orch_blocker_watch.stale_blockers_count // 0' <<<"$DOCTOR_JSON")"
PEER_ORCH_BLOCKER_AGE_SECONDS="$(jq -r '.peer_orch_blocker_age_seconds // .peer_orch_blocker_watch.peer_orch_blocker_age_seconds // 0' <<<"$DOCTOR_JSON")"
OVERSIZED_FILES_COUNT="$(jq -r '.oversized_files_count // .file_length.oversized_files_count // 0' <<<"$DOCTOR_JSON")"
MONOLITHIC_FILE_DEBT_TRIGGER=0
if [ "${OVERSIZED_FILES_COUNT:-0}" -gt 3 ]; then
  MONOLITHIC_FILE_DEBT_TRIGGER=1
fi
WIRE_OR_EXPLAIN_STATUS="$(jq -r '.wire_or_explain.status // "pass"' <<<"$DOCTOR_JSON")"
WIRE_OR_EXPLAIN_UNRESOLVED="$(jq -r '.wire_or_explain.unresolved_count // 0' <<<"$DOCTOR_JSON")"
WIRE_OR_EXPLAIN_OVERDUE="$(jq -r '.wire_or_explain.overdue_count // 0' <<<"$DOCTOR_JSON")"
WIRE_OR_EXPLAIN_SKILL_BACKLOG="$(jq -r '.wire_or_explain.skill_candidate_backlog_count // 0' <<<"$DOCTOR_JSON")"
WIRE_OR_EXPLAIN_SKILL_RELAY_FAILURE="$(jq -r '.wire_or_explain.skill_candidate_relay_failure_count // 0' <<<"$DOCTOR_JSON")"
WIRE_OR_EXPLAIN_TRIGGER=0
if [ "$WIRE_OR_EXPLAIN_STATUS" = "error" ] || [ "${WIRE_OR_EXPLAIN_OVERDUE:-0}" -gt 0 ] || [ "${WIRE_OR_EXPLAIN_SKILL_RELAY_FAILURE:-0}" -gt 0 ]; then
  WIRE_OR_EXPLAIN_TRIGGER=1
fi
PWS_FALSE_IDLE_ERROR_COUNT="$(jq -r '[.pane_work_signal.errors[]? | select((.class // "") == "ntm_codex_false_idle")] | length' <<<"$DOCTOR_JSON")"
PWS_FALSE_IDLE_STATUS="$(jq -r '.pane_work_signal.status // "ok"' <<<"$DOCTOR_JSON")"
PWS_FALSE_IDLE_TRIGGER=0
if [ "${PWS_FALSE_IDLE_ERROR_COUNT:-0}" -gt 0 ] || { [ "$PWS_FALSE_IDLE_STATUS" = "fail" ] && [ "$(jq -r '.pane_work_signal.error_count // 0' <<<"$DOCTOR_JSON")" -gt 0 ]; }; then
  PWS_FALSE_IDLE_TRIGGER=1
fi
DISPATCH_CONTRACT_VIOLATIONS="$(jq -r '.dispatch_contract_violations // .dispatch_contract.dispatch_contract_violations // 0' <<<"$DOCTOR_JSON")"
DISPATCH_CONTRACT_STATUS="$(jq -r '.dispatch_contract.status // "pass"' <<<"$DOCTOR_JSON")"
DISPATCH_CONTRACT_TRIGGER=0
if [ "${DISPATCH_CONTRACT_VIOLATIONS:-0}" -gt "${DISPATCH_CONTRACT_THRESHOLD:-5}" ] || { [ "$DISPATCH_CONTRACT_STATUS" = "fail" ] && [ "${DISPATCH_CONTRACT_VIOLATIONS:-0}" -gt 0 ]; }; then
  DISPATCH_CONTRACT_TRIGGER=1
fi
FLEET_SKILL_DISCOVERY_STATUS="$(jq -r '.fleet_skill_discovery.status // "ok"' <<<"$DOCTOR_JSON")"
FLEET_SKILL_DISCOVERY_PENDING="$(jq -r '.fleet_skill_discovery.pending_coordinator_action_count // .fleet_skill_discovery_pending_coordinator_action_count // 0' <<<"$DOCTOR_JSON")"
FLEET_SKILL_DISCOVERY_SUSPICIOUS="$(jq -r '.fleet_skill_discovery.suspicious_callback_warning_count // .fleet_skill_discovery_suspicious_callback_warning_count // 0' <<<"$DOCTOR_JSON")"
FLEET_SKILL_DISCOVERY_MALFORMED="$(jq -r '.fleet_skill_discovery.malformed_rows_count // .fleet_skill_discovery_malformed_rows_count // 0' <<<"$DOCTOR_JSON")"
FLEET_SKILL_DISCOVERY_TOP="$(jq -r '.fleet_skill_discovery.top_candidates[0].candidate_skill_name // "none"' <<<"$DOCTOR_JSON")"
FLEET_SKILL_DISCOVERY_TRIGGER=0
if [ "${FLEET_SKILL_DISCOVERY_PENDING:-0}" -ge "${FLEET_SKILL_DISCOVERY_PENDING_THRESHOLD:-1}" ] || [ "${FLEET_SKILL_DISCOVERY_SUSPICIOUS:-0}" -ge "${FLEET_SKILL_DISCOVERY_SUSPICIOUS_THRESHOLD:-1}" ]; then
  FLEET_SKILL_DISCOVERY_TRIGGER=1
fi
if [ "$STATUS" != "fail" ] && [ "$ROOT_DRIFT" != "true" ] && [ "${DOCTRINE_3_SURFACE_DIVERGENT_COUNT:-0}" -le 0 ] && [ "${FLEET_L_RULE_LAG_COUNT:-0}" -le 0 ] && [ "${PUNTED_COUNT:-0}" -le 0 ] && [ "${PEER_ORCH_IDLE_ON_BLOCKER_COUNT:-0}" -le 0 ] && [ "$STORAGE_TRIGGER" -eq 0 ] && [ "$HEADLESS_BROWSER_TRIGGER" -eq 0 ] && [ "$AGENTMAIL_IDENTITY_TRIGGER" -eq 0 ] && [ "$DAILY_REPORT_TRIGGER" -eq 0 ] && [ "${REPO_LOCAL_CLIS_BELOW:-0}" -le 0 ] && [ "$MONOLITHIC_FILE_DEBT_TRIGGER" -eq 0 ] && [ "$WIRE_OR_EXPLAIN_TRIGGER" -eq 0 ] && [ "$PWS_FALSE_IDLE_TRIGGER" -eq 0 ] && [ "$DISPATCH_CONTRACT_TRIGGER" -eq 0 ] && [ "$FLEET_SKILL_DISCOVERY_TRIGGER" -eq 0 ]; then
  jq -nc --arg reason "doctor_status=$STATUS" '{action:"noop",reason:$reason}'
  exit 0
fi

LEAKAGE="$(jq -r '.beads_db_health.leakage_count // 0' <<<"$DOCTOR_JSON")"
DRIFT="$(jq -r '.canonical_doctrine_state // ""' <<<"$DOCTOR_JSON")"
ROOT_DRIFT_STATUS="$(jq -r '.canonical_root_drift.status // "unknown"' <<<"$DOCTOR_JSON")"
ROOT_DRIFT_MISSING="$(jq -r '(.canonical_root_drift.missing_rules // []) | join(",")' <<<"$DOCTOR_JSON")"
DB_STATUS="$(jq -r '.beads_db_health.status // ""' <<<"$DOCTOR_JSON")"
WAL_SIZE_MB="$(jq -r '.beads_db_health.wal_size_mb // 0' <<<"$DOCTOR_JSON")"

actions=()

if [ "${LEAKAGE:-0}" -gt 5 ]; then
  handle_symptom \
    "leakage" \
    'leakage|bead-isolation' \
    "[auto-doctor:leakage] bead-isolation leakage_count=$LEAKAGE" \
    "Auto-created by doctor-signal-bead-promotion.sh. Doctor reports leakage_count=$LEAKAGE >5. See ~/.claude/skills/.flywheel/INCIDENTS.md doctor-signal-fail-without-bead-promotion and .flywheel/PLANS/bead-isolation-fix-2026-04-30.md."
fi

if [[ "$DRIFT" == *drift* ]]; then
  handle_symptom \
    "drift" \
    'canonical_doctrine|doctrine.*drift|drift.*doctrine|doctrine-sync|sync-canonical|stamp' \
    "[auto-doctor:drift] canonical_doctrine_state=$DRIFT" \
    "Auto-created by doctor-signal-bead-promotion.sh. Doctor reports canonical_doctrine_state=$DRIFT. See ~/.claude/skills/.flywheel/INCIDENTS.md doctor-signal-fail-without-bead-promotion."
fi

if [ "$ROOT_DRIFT" = "true" ]; then
  handle_symptom \
    "root_drift" \
    'canonical_root_drift|root.*AGENTS|AGENTS.*root|doctrine.*root.*drift|root.*doctrine.*drift' \
    "[auto-doctor:root_drift] canonical_root_drift=$ROOT_DRIFT_STATUS" \
    "Auto-created by doctor-signal-bead-promotion.sh. Doctor reports canonical_root_drift=$ROOT_DRIFT_STATUS missing_rules=${ROOT_DRIFT_MISSING:-none}. Root AGENTS.md must carry the canonical flywheel doctrine block; see flywheel-ft04."
fi

if [ "${DOCTRINE_3_SURFACE_DIVERGENT_COUNT:-0}" -gt 0 ]; then
  handle_symptom \
    "doctrine_3_surface" \
    'doctrine.*3-surface|3-surface.*doctrine|doctrine_3_surface_divergent_count|AGENTS-CANONICAL.*template|L-rule.*surface' \
    "[auto-doctor:doctrine_3_surface] divergent_count=$DOCTRINE_3_SURFACE_DIVERGENT_COUNT" \
    "Auto-created by doctor-signal-bead-promotion.sh. Doctor reports doctrine_3_surface_divergent_count=$DOCTRINE_3_SURFACE_DIVERGENT_COUNT. L96 requires every L-rule to land on AGENTS.md, .flywheel/AGENTS-CANONICAL.md, and templates/flywheel-install/AGENTS.md in one coherent doctrine diff."
fi

if [ "${FLEET_L_RULE_LAG_COUNT:-0}" -gt 0 ]; then
  handle_symptom \
    "fleet_l_rule_lag" \
    'fleet.*L-rule.*lag|fleet_repo_l_rule_lag_count|repo.*doctrine.*lag|root.*AGENTS.*lag' \
    "[auto-doctor:fleet_l_rule_lag] lagging_repos=$FLEET_L_RULE_LAG_COUNT" \
    "Auto-created by doctor-signal-bead-promotion.sh. Doctor reports fleet_repo_l_rule_lag_count=$FLEET_L_RULE_LAG_COUNT. Fleet repos must pull canonical doctrine before dispatch so stale L-rules do not govern worker packets."
fi

if [ "${PUNTED_COUNT:-0}" -gt 0 ]; then
  handle_symptom \
    "punt" \
    'ticks_punted_count|orch-no-punt|no-punt|same-tick.*chain|chain.*same-tick|orch.*punt' \
    "[auto-doctor:punt] ticks_punted_count=$PUNTED_COUNT" \
    "Auto-created by doctor-signal-bead-promotion.sh. Doctor reports ticks_punted_count=$PUNTED_COUNT. L70 requires same-tick chaining or a concrete chain_blocked_reason; see flywheel-zdva and flywheel-7lby."
fi

if [ "${PEER_ORCH_IDLE_ON_BLOCKER_COUNT:-0}" -gt 0 ]; then
  handle_symptom \
    "peer_orch_blocker" \
    'peer-orch-idle-on-blocker|peer_orch_blocker|orch-blocker-coordination|flywheel-class.*blocker' \
    "[auto-doctor:peer_orch_blocker] stale_blockers=$PEER_ORCH_IDLE_ON_BLOCKER_COUNT age_seconds=$PEER_ORCH_BLOCKER_AGE_SECONDS" \
    "Auto-created by doctor-signal-bead-promotion.sh. Doctor reports peer_orch_idle_on_blocker_count=$PEER_ORCH_IDLE_ON_BLOCKER_COUNT peer_orch_blocker_age_seconds=$PEER_ORCH_BLOCKER_AGE_SECONDS. L75 requires flywheel-class peer orchestrator blockers to coordinate with flywheel:1 within five minutes; see flywheel-vc3e."
fi

if [ "$STORAGE_TRIGGER" -eq 1 ]; then
  handle_symptom \
    "storage" \
    'storage-low-headroom|storage.*headroom|disk_free_pct|stale.*bak|storage.*discipline' \
    "[auto-doctor:storage-low-headroom] disk_free_pct=$STORAGE_FREE_PCT stale_baks_count=$STORAGE_STALE_BAKS" \
    "Auto-created by doctor-signal-bead-promotion.sh. Doctor reports storage.status=$STORAGE_STATUS disk_free_pct=$STORAGE_FREE_PCT stale_baks_count=$STORAGE_STALE_BAKS. Storage below 10% or stale backup count above 5 blocks growth-heavy flywheel work; see flywheel-2zsj and .flywheel/STORAGE.md."
fi

if [ "$HEADLESS_BROWSER_TRIGGER" -eq 1 ]; then
  handle_symptom \
    "headless_browser" \
    'headless-browser|agent-browser-chrome|agent_browser_leak|browser.*orphan|chrome.*leak' \
    "[auto-doctor:headless_browser] agent_browser_leak count=$HEADLESS_BROWSER_COUNT oldest_age_minutes=$HEADLESS_BROWSER_OLDEST" \
    "Auto-created by doctor-signal-bead-promotion.sh. Doctor reports agent_browser_leak.status=$HEADLESS_BROWSER_STATUS headless_agent_browser_count=$HEADLESS_BROWSER_COUNT oldest_age_minutes=$HEADLESS_BROWSER_OLDEST. L71 requires runtime leaks to be validated, documented, and surfaced; see flywheel-3ck3."
fi

if [ "$AGENTMAIL_IDENTITY_TRIGGER" -eq 1 ]; then
  handle_symptom \
    "agentmail_identity" \
    'agentmail.identity|agent-mail.*identity|identity_registry|identity.*drift|identity.*orphan' \
    "[auto-doctor:agentmail_identity] pending_registration_broadcasts=$AGENTMAIL_PENDING_REGISTRATION_BROADCASTS identity_token_orphan=$IDENTITY_TOKEN_ORPHAN orphan_tokens_unswept_count=$ORPHAN_TOKENS_UNSWEPT identity_chain_max_length=$IDENTITY_CHAIN_MAX_LENGTH" \
    "Auto-created by doctor-signal-bead-promotion.sh. Doctor reports agentmail_pending_registration_broadcasts_count=$AGENTMAIL_PENDING_REGISTRATION_BROADCASTS identity_registry_drift=$IDENTITY_REGISTRY_DRIFT identity_token_orphan=$IDENTITY_TOKEN_ORPHAN orphan_tokens_unswept_count=$ORPHAN_TOKENS_UNSWEPT identity_rotation_count_24h=$IDENTITY_ROTATION_COUNT_24H identity_chain_max_length=$IDENTITY_CHAIN_MAX_LENGTH. Agent Mail identities must resolve through flywheel-loop identity and durable (session,pane,project) primary key; identity_name is only the current pointer. See flywheel-g9mi, flywheel-2uin, and L100."
fi

if [ "$DAILY_REPORT_TRIGGER" -eq 1 ]; then
  handle_symptom \
    "daily_report" \
    'daily_report|daily-report|daily_report_age_hours|no-daily-narrative' \
    "[auto-doctor:daily_report] daily_report_age_hours=$DAILY_REPORT_AGE" \
    "Auto-created by doctor-signal-bead-promotion.sh. Doctor reports daily_report.status=$DAILY_REPORT_STATUS daily_report_age_hours=$DAILY_REPORT_AGE. The daily narrative must be regenerated within 36h; see flywheel-o7dq and /flywheel:daily-report."
fi

if [ "${REPO_LOCAL_CLIS_BELOW:-0}" -gt 0 ]; then
  handle_symptom \
    "repo_local_cli" \
    'repo_local_clis_below_canonical_floor|canonical.*cli.*floor|repo-local.*cli|bin/.*cli' \
    "[auto-doctor:repo_local_cli_floor] repo_local_clis_below_canonical_floor=$REPO_LOCAL_CLIS_BELOW" \
    "Auto-created by doctor-signal-bead-promotion.sh. Doctor reports repo_local_clis_below_canonical_floor=$REPO_LOCAL_CLIS_BELOW. Repo-local bin/ executables must pass ~/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh; see flywheel-jbe and AGENTS.md L82."
fi

if [ "$MONOLITHIC_FILE_DEBT_TRIGGER" -eq 1 ]; then
  handle_symptom \
    "monolithic_file_debt" \
    'monolithic-file-debt|oversized_files_count|file-length|canonical-cli-scoping.*file' \
    "[auto-doctor:monolithic_file_debt] oversized_files_count=$OVERSIZED_FILES_COUNT" \
    "Auto-created by doctor-signal-bead-promotion.sh. Doctor reports oversized_files_count=$OVERSIZED_FILES_COUNT (>3). Files above canonical-cli-scoping thresholds must be split or carry a canonical-cli-scoping-allow-large receipt; see flywheel-useh and AGENTS.md file-length discipline."
fi

if [ "$WIRE_OR_EXPLAIN_TRIGGER" -eq 1 ]; then
  handle_symptom \
    "wire_or_explain" \
    'auto-doctor:wire_or_explain|wire-or-explain.*doctor.*signal|wire_or_explain.*overdue' \
    "[auto-doctor:wire_or_explain] unresolved_count=$WIRE_OR_EXPLAIN_UNRESOLVED overdue_count=$WIRE_OR_EXPLAIN_OVERDUE relay_failures=$WIRE_OR_EXPLAIN_SKILL_RELAY_FAILURE" \
    "Auto-created by doctor-signal-bead-promotion.sh. Doctor reports wire_or_explain.status=$WIRE_OR_EXPLAIN_STATUS unresolved_count=$WIRE_OR_EXPLAIN_UNRESOLVED overdue_count=$WIRE_OR_EXPLAIN_OVERDUE skill_candidate_backlog_count=$WIRE_OR_EXPLAIN_SKILL_BACKLOG skill_candidate_relay_failure_count=$WIRE_OR_EXPLAIN_SKILL_RELAY_FAILURE. The Peel Report doctor fields require every unresolved local blocker to be drained, deferred, or promoted; see flywheel-2eow and L110."
fi

if [ "$PWS_FALSE_IDLE_TRIGGER" -eq 1 ]; then
  handle_symptom \
    "pws_false_idle" \
    'ntm-health-codex-false-idle-followup|ntm_codex_false_idle|codex.*false.*idle|false.*idle.*codex' \
    "[auto-doctor:ntm-health-codex-false-idle-followup] ntm_codex_false_idle_errors=$PWS_FALSE_IDLE_ERROR_COUNT" \
    "Auto-created by doctor-signal-bead-promotion.sh. Doctor reports error-severity pane_work_signal class=ntm_codex_false_idle. PWS is defense-in-depth after ntm#124 IsLiveBusy, but repeated false-idle disagreement still needs a follow-up bead; see .flywheel/PLANS/pws-vs-islivebusy-2026-05-08.md."
fi

if [ "$DISPATCH_CONTRACT_TRIGGER" -eq 1 ]; then
  handle_symptom \
    "dispatch_contract" \
    'dispatch_contract|callback_contract_required|dispatch.*callback.*contract|dispatch-enforcement' \
    "[auto-doctor:dispatch_contract] violations=$DISPATCH_CONTRACT_VIOLATIONS" \
    "Auto-created by doctor-signal-bead-promotion.sh. Doctor reports dispatch_contract_violations=$DISPATCH_CONTRACT_VIOLATIONS status=$DISPATCH_CONTRACT_STATUS. Dispatch callbacks must carry numeric Socraticode fields, DID/DIDNT/GAPS, file reservation receipts, L52 bead/no-bead receipt, and L53 blocker logging; see .flywheel/PLANS/dispatch-enforcement-2026-05-01.md."
fi

if [ "$FLEET_SKILL_DISCOVERY_TRIGGER" -eq 1 ]; then
  handle_symptom \
    "fleet_skill_discovery" \
    'fleet_skill_discovery|skill-discovery.*doctor|skill_discovery_duty_skipped|skill.*coordinator.*pending' \
    "[auto-doctor:fleet_skill_discovery] pending_actions=$FLEET_SKILL_DISCOVERY_PENDING suspicious_callbacks=$FLEET_SKILL_DISCOVERY_SUSPICIOUS top_candidate=$FLEET_SKILL_DISCOVERY_TOP" \
    "Auto-created by doctor-signal-bead-promotion.sh. Doctor reports fleet_skill_discovery.status=$FLEET_SKILL_DISCOVERY_STATUS pending_coordinator_action_count=$FLEET_SKILL_DISCOVERY_PENDING suspicious_callback_warning_count=$FLEET_SKILL_DISCOVERY_SUSPICIOUS malformed_rows_count=$FLEET_SKILL_DISCOVERY_MALFORMED top_candidate=$FLEET_SKILL_DISCOVERY_TOP. Skill discovery rows must flow to skillos and long worker callbacks must report skill_discoveries/sd_ids or an explicit legal no-discovery reason; see .flywheel/PLANS/fleet-skill-reporting-2026-05-01.md."
fi

if [ "$DB_STATUS" = "fail" ]; then
  handle_symptom \
    "db_fail" \
    'auto-doctor:db_fail|beads[_ -]?db[_ -]?health|db\.health|integrity_check|frankensqlite|beads.*integrity' \
    "[auto-doctor:db_fail] beads_db_health=fail" \
    "Auto-created by doctor-signal-bead-promotion.sh. Doctor reports beads_db_health=fail. See ~/.claude/skills/.flywheel/INCIDENTS.md doctor-signal-fail-without-bead-promotion."
fi

if awk -v mb="${WAL_SIZE_MB:-0}" 'BEGIN { exit !(mb > 50) }'; then
  handle_symptom \
    "wal_size_high" \
    'auto-doctor:wal_size_high|wal.*size' \
    "[auto-doctor:wal_size_high] beads_db_health.wal_size_mb=$WAL_SIZE_MB" \
    "Auto-created by doctor-signal-bead-promotion.sh. Doctor reports beads_db_health.wal_size_mb=$WAL_SIZE_MB >50. See ~/.claude/skills/.flywheel/INCIDENTS.md doctor-signal-fail-without-bead-promotion."
fi

if [ "${#actions[@]}" -eq 0 ]; then
  actions_json="[]"
else
  actions_json="$(printf '%s\n' "${actions[@]}" | jq -R . | jq -s .)"
fi

jq -nc \
  --arg doctor_status "$STATUS" \
  --argjson leakage "${LEAKAGE:-0}" \
  --arg drift "$DRIFT" \
  --arg root_drift "$ROOT_DRIFT_STATUS" \
  --argjson punted_count "${PUNTED_COUNT:-0}" \
  --arg storage_status "$STORAGE_STATUS" \
  --argjson storage_free_pct "${STORAGE_FREE_PCT:-100}" \
  --argjson storage_stale_baks "${STORAGE_STALE_BAKS:-0}" \
  --arg headless_browser_status "$HEADLESS_BROWSER_STATUS" \
  --argjson headless_browser_count "${HEADLESS_BROWSER_COUNT:-0}" \
  --argjson headless_browser_oldest "${HEADLESS_BROWSER_OLDEST:-0}" \
  --argjson identity_registry_drift "${IDENTITY_REGISTRY_DRIFT:-0}" \
  --argjson identity_token_orphan "${IDENTITY_TOKEN_ORPHAN:-0}" \
  --argjson orphan_tokens_unswept_count "${ORPHAN_TOKENS_UNSWEPT:-0}" \
  --argjson identity_rotation_count_24h "${IDENTITY_ROTATION_COUNT_24H:-0}" \
  --argjson identity_chain_max_length "${IDENTITY_CHAIN_MAX_LENGTH:-0}" \
  --argjson agentmail_pending_registration_broadcasts "${AGENTMAIL_PENDING_REGISTRATION_BROADCASTS:-0}" \
  --arg daily_report_status "$DAILY_REPORT_STATUS" \
  --argjson daily_report_age_hours "${DAILY_REPORT_AGE:-0}" \
  --argjson peer_orch_idle_on_blocker_count "${PEER_ORCH_IDLE_ON_BLOCKER_COUNT:-0}" \
  --argjson peer_orch_blocker_age_seconds "${PEER_ORCH_BLOCKER_AGE_SECONDS:-0}" \
  --argjson oversized_files_count "${OVERSIZED_FILES_COUNT:-0}" \
  --arg wire_or_explain_status "$WIRE_OR_EXPLAIN_STATUS" \
  --argjson wire_or_explain_unresolved "${WIRE_OR_EXPLAIN_UNRESOLVED:-0}" \
  --argjson wire_or_explain_overdue "${WIRE_OR_EXPLAIN_OVERDUE:-0}" \
  --argjson wire_or_explain_skill_backlog "${WIRE_OR_EXPLAIN_SKILL_BACKLOG:-0}" \
  --argjson wire_or_explain_skill_relay_failure "${WIRE_OR_EXPLAIN_SKILL_RELAY_FAILURE:-0}" \
  --argjson pws_false_idle_error_count "${PWS_FALSE_IDLE_ERROR_COUNT:-0}" \
  --argjson dispatch_contract_violations "${DISPATCH_CONTRACT_VIOLATIONS:-0}" \
  --arg fleet_skill_discovery_status "$FLEET_SKILL_DISCOVERY_STATUS" \
  --argjson fleet_skill_discovery_pending "${FLEET_SKILL_DISCOVERY_PENDING:-0}" \
  --argjson fleet_skill_discovery_suspicious "${FLEET_SKILL_DISCOVERY_SUSPICIOUS:-0}" \
  --argjson fleet_skill_discovery_malformed "${FLEET_SKILL_DISCOVERY_MALFORMED:-0}" \
  --arg fleet_skill_discovery_top "$FLEET_SKILL_DISCOVERY_TOP" \
  --argjson dry_run "$([[ "$DRY_RUN" = "1" ]] && printf true || printf false)" \
  --arg db "$DB_STATUS" \
  --argjson actions "$actions_json" \
  '{
    action:"promoted",
    dry_run:$dry_run,
    doctor_status:$doctor_status,
    symptoms:{leakage:$leakage, drift:$drift, root_drift:$root_drift, ticks_punted_count:$punted_count, peer_orch_blocker:{peer_orch_idle_on_blocker_count:$peer_orch_idle_on_blocker_count,peer_orch_blocker_age_seconds:$peer_orch_blocker_age_seconds}, storage:{status:$storage_status,disk_free_pct:$storage_free_pct,stale_baks_count:$storage_stale_baks}, agent_browser_leak:{status:$headless_browser_status,headless_agent_browser_count:$headless_browser_count,oldest_age_minutes:$headless_browser_oldest}, agentmail_identity:{identity_registry_drift:$identity_registry_drift,identity_token_orphan:$identity_token_orphan,orphan_tokens_unswept_count:$orphan_tokens_unswept_count,identity_rotation_count_24h:$identity_rotation_count_24h,identity_chain_max_length:$identity_chain_max_length,agentmail_pending_registration_broadcasts_count:$agentmail_pending_registration_broadcasts}, daily_report:{status:$daily_report_status,daily_report_age_hours:$daily_report_age_hours}, monolithic_file_debt:{oversized_files_count:$oversized_files_count}, wire_or_explain:{status:$wire_or_explain_status,unresolved_count:$wire_or_explain_unresolved,overdue_count:$wire_or_explain_overdue,skill_candidate_backlog_count:$wire_or_explain_skill_backlog,skill_candidate_relay_failure_count:$wire_or_explain_skill_relay_failure}, pws_false_idle:{ntm_codex_false_idle_error_count:$pws_false_idle_error_count}, dispatch_contract:{dispatch_contract_violations:$dispatch_contract_violations}, fleet_skill_discovery:{status:$fleet_skill_discovery_status,pending_coordinator_action_count:$fleet_skill_discovery_pending,suspicious_callback_warning_count:$fleet_skill_discovery_suspicious,malformed_rows_count:$fleet_skill_discovery_malformed,top_candidate:$fleet_skill_discovery_top}, db:$db},
    actions:$actions
  }'
