#!/usr/bin/env bash
set -euo pipefail

# build-cli-inventory.sh — produce inventory.jsonl per flywheel-cli-inventory apply-spec
# Read-only pass. No mutations to scripts. Produces:
#   .flywheel/audit/flywheel-cli-inventory/inventory.jsonl
#   .flywheel/audit/flywheel-cli-inventory/evidence.md

REPO="/Users/josh/Developer/flywheel"
OUT_DIR="$REPO/.flywheel/audit/flywheel-cli-inventory"
INVENTORY="$OUT_DIR/inventory.jsonl"
EVIDENCE="$OUT_DIR/evidence.md"
mkdir -p "$OUT_DIR"
: >"$INVENTORY"

# Lane inference from path tokens
infer_lane() {
  local p="$1"
  case "$p" in
    *storage*|*tmp-prune*) echo "storage" ;;
    *agent-mail*|*agentmail*|*am-*|*fd-*) echo "agent-mail" ;;
    *beads*|*br-*|*bead-*) echo "beads" ;;
    *dispatch*|*ntm*) echo "dispatch" ;;
    *respawn*|*recover*|*revive*|*kill*) echo "recovery" ;;
    *caam*) echo "caam" ;;
    *cass*) echo "cass" ;;
    *jeff*) echo "jeff-corpus" ;;
    *socratic*) echo "socraticode" ;;
    *doctor*|*health*|*verify*|*validate*) echo "doctrine" ;;
    *capacity*|*halt*|*idle*) echo "capacity" ;;
    *coord*|*orchest*) echo "orchestration" ;;
    *test*|*tests*) echo "testing" ;;
    *mission*|*goal*|*plan*) echo "mission" ;;
    *learn*|*polish*|*grade*|*compliance*) echo "quality" ;;
    *) echo "general" ;;
  esac
}

probe_script() {
  local path="$1"
  local rel="${path#$REPO/}"
  local name="$(basename "$path")"
  local lane; lane="$(infer_lane "$path")"

  # Boolean signals from grep (read-only)
  local has_apply=false has_dry_run=false has_revert=false has_idem=false has_ledger=false
  local has_doctor=false has_help=false has_info=false has_schema=false has_examples=false
  local has_backup=false has_json=false has_repair=false has_health=false
  local cli_surface=false

  grep -qE -- '--apply([^a-z_-]|$)' "$path" 2>/dev/null && has_apply=true
  grep -qE -- '--dry-run([^a-z_-]|$)' "$path" 2>/dev/null && has_dry_run=true
  grep -qE -- '--revert|undo[\)\|"]|rollback' "$path" 2>/dev/null && has_revert=true
  grep -qE -- '--idempotency-key|idempotency_key' "$path" 2>/dev/null && has_idem=true
  grep -qE -- 'ledger.*append|jsonl.*append|append.*ledger|append.*jsonl' "$path" 2>/dev/null && has_ledger=true
  grep -qE -- '\bdoctor[\)\|"]|--doctor[\b ]|"doctor"|case.*doctor' "$path" 2>/dev/null && has_doctor=true
  grep -qE -- '--help[\b ]|"--help"|usage\(\)|case.*--help' "$path" 2>/dev/null && has_help=true
  grep -qE -- '--info[\b ]|"--info"|case.*--info' "$path" 2>/dev/null && has_info=true
  grep -qE -- '--schema[\b ]|"--schema"|case.*--schema' "$path" 2>/dev/null && has_schema=true
  grep -qE -- '--examples?[\b ]|"--examples?"|case.*--examples?' "$path" 2>/dev/null && has_examples=true
  grep -qE -- 'backup_path|\.bak\.|cp.*\.bak|backup=' "$path" 2>/dev/null && has_backup=true
  grep -qE -- '--json[\b ]|"--json"|case.*--json' "$path" 2>/dev/null && has_json=true
  grep -qE -- '\brepair[\)\|"]|--repair[\b ]|"repair"' "$path" 2>/dev/null && has_repair=true
  grep -qE -- '\bhealth[\)\|"]|--health[\b ]|"health"' "$path" 2>/dev/null && has_health=true
  grep -qE '^# flywheel-cli-surface: true$' "$path" 2>/dev/null && cli_surface=true

  # Mutates_state heuristic: has --apply OR writes outside /tmp OR appends ledger
  local mutates="unknown"
  if [[ "$has_apply" == "true" || "$has_ledger" == "true" || "$has_backup" == "true" ]]; then
    mutates="yes"
  elif grep -qE 'rm |mv |cp |sed -i|echo .*>>?|tee |printf .*>>?|jq .*>>?' "$path" 2>/dev/null; then
    if grep -qE '^[^#]*\b(rm|mv|cp|sed -i)\b' "$path" 2>/dev/null; then
      mutates="yes"
    else
      mutates="no"
    fi
  else
    mutates="no"
  fi

  # canonical_cli_scoping_status
  local cli_status="missing"
  if [[ "$has_help" == "true" && "$has_info" == "true" && "$has_schema" == "true" && "$has_examples" == "true" ]]; then
    cli_status="passing"
  elif [[ "$has_help" == "true" && ( "$has_info" == "true" || "$has_schema" == "true" ) ]]; then
    cli_status="partial"
  elif [[ "$has_help" == "true" ]]; then
    cli_status="partial"
  fi

  # doctor_subcommand_status
  local doctor_status="absent"
  if [[ "$has_doctor" == "true" ]]; then
    if [[ "$has_revert" == "true" && "$has_idem" == "true" && "$has_backup" == "true" && "$has_json" == "true" ]]; then
      doctor_status="upgraded"
    elif [[ "$has_doctor" == "true" && "$has_json" == "true" ]]; then
      doctor_status="basic"
    else
      doctor_status="basic"
    fi
  fi

  # Score estimate: 125pts per boolean signal × 8 signals = max 1000
  local score=0
  $has_apply && score=$((score+125))
  $has_dry_run && score=$((score+125))
  $has_revert && score=$((score+125))
  $has_idem && score=$((score+125))
  $has_ledger && score=$((score+125))
  $has_backup && score=$((score+125))
  $has_doctor && score=$((score+125))
  $has_json && score=$((score+125))
  if [[ "$has_doctor" == "false" ]]; then score=0; fi

  # Exemplar match heuristic
  local exemplar="none"
  if $has_apply && $has_dry_run && $has_revert && $has_backup && $has_doctor; then
    exemplar="apply-tmux-tuning"
  elif $has_apply && $has_backup && $has_doctor && $has_ledger; then
    exemplar="beads-db-recover"
  elif $has_apply && $has_dry_run && $has_idem && $has_doctor; then
    exemplar="reconcile-polish-gate"
  fi

  # Priority
  local priority="P3"
  if [[ "$mutates" == "yes" ]]; then
    if [[ "$cli_status" == "missing" || "$cli_status" == "partial" || "$doctor_status" == "absent" ]]; then
      priority="P0"
    elif [[ "$cli_status" == "passing" && "$doctor_status" == "basic" ]]; then
      priority="P1"
    else
      priority="P1"
    fi
  else
    priority="P2"
  fi

  jq -nc \
    --arg name "$name" \
    --arg path "$rel" \
    --arg ownership "own" \
    --arg lane "$lane" \
    --arg cli_status "$cli_status" \
    --arg doctor_status "$doctor_status" \
    --arg mutates "$mutates" \
    --argjson has_apply "$has_apply" \
    --argjson has_dry_run "$has_dry_run" \
    --argjson has_revert "$has_revert" \
    --argjson has_idem "$has_idem" \
    --argjson has_ledger "$has_ledger" \
    --argjson has_backup "$has_backup" \
    --argjson has_doctor "$has_doctor" \
    --argjson has_help "$has_help" \
    --argjson has_info "$has_info" \
    --argjson has_schema "$has_schema" \
    --argjson has_examples "$has_examples" \
    --argjson has_json "$has_json" \
    --argjson has_repair "$has_repair" \
    --argjson has_health "$has_health" \
    --argjson cli_surface "$cli_surface" \
    --argjson score "$score" \
    --arg exemplar "$exemplar" \
    --arg priority "$priority" \
    '{
      name: $name,
      path: $path,
      ownership: $ownership,
      lane: $lane,
      canonical_cli_scoping_status: $cli_status,
      doctor_subcommand_status: $doctor_status,
      mutates_state: $mutates,
      signals: {
        has_apply: $has_apply,
        has_dry_run: $has_dry_run,
        has_revert: $has_revert,
        has_idempotency_key: $has_idem,
        has_ledger_receipt: $has_ledger,
        has_backup_pattern: $has_backup,
        has_doctor: $has_doctor,
        has_help: $has_help,
        has_info: $has_info,
        has_schema: $has_schema,
        has_examples: $has_examples,
        has_json: $has_json,
        has_repair: $has_repair,
        has_health: $has_health,
        marked_cli_surface: $cli_surface
      },
      world_class_doctor_score_estimate: $score,
      exemplar_match: $exemplar,
      priority: $priority
    }'
}

# Phase 1: own scripts under .flywheel/scripts/
while IFS= read -r script; do
  probe_script "$script" >>"$INVENTORY"
done < <(find "$REPO/.flywheel/scripts" -maxdepth 1 -type f -name '*.sh' 2>/dev/null | sort)

# Phase 2: own scripts under .flywheel/scripts/_shared etc.
while IFS= read -r script; do
  probe_script "$script" >>"$INVENTORY"
done < <(find "$REPO/.flywheel/scripts" -mindepth 2 -type f \( -name '*.sh' -o -name '*.py' \) 2>/dev/null | sort)

# Phase 3: skill bins
while IFS= read -r script; do
  [[ -f "$script" ]] || continue
  probe_script "$script" >>"$INVENTORY"
done < <(find "/Users/josh/.claude/skills/.flywheel/bin" -maxdepth 1 -type f \
  ! -name '*.bak.*' ! -name '*.README.md' ! -name '__pycache__*' 2>/dev/null | sort)

# Phase 4: command wrappers
while IFS= read -r script; do
  probe_script "$script" >>"$INVENTORY"
done < <(find "/Users/josh/.claude/commands/flywheel" -type f -name '*.sh' 2>/dev/null | sort)

# Phase 5: jeff-stack hardcoded rows
for jeff_bin in ntm br bv bvp bvg am dcg caam cass cm jsm; do
  jq -nc --arg name "$jeff_bin" '{
    name: $name,
    path: ("upstream:" + $name),
    ownership: "jeff-stack-orchestrated",
    lane: "jeff-stack",
    canonical_cli_scoping_status: "upstream_owned",
    doctor_subcommand_status: "upstream_owned",
    mutates_state: "yes",
    signals: {},
    world_class_doctor_score_estimate: null,
    exemplar_match: "upstream",
    priority: "P3"
  }' >>"$INVENTORY"
done

echo "wrote $INVENTORY ($(wc -l <"$INVENTORY") rows)"
