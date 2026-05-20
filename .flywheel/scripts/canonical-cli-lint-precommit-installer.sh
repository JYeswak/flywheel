#!/usr/bin/env bash
# canonical-cli-lint-precommit-installer.sh
# flywheel-cli-surface: true
#
# Installer for canonical-cli-lint pre-commit wire-in (L1-L9 rules from
# .flywheel/scripts/canonical-cli-lint.sh).
#
# Architecture:
#   - core.hooksPath points Git at the repo's `githooks/` dispatcher
#   - githooks/pre-commit chains into security-precommit-installer's run-hook
#   - security-precommit-installer reads flywheel.securityPrecommitChain
#   - This installer sets that config to .flywheel/hooks/pre-commit-chain.sh
#   - pre-commit-chain.sh runs canonical-cli-lint + file-rag-discipline
#
# Bypass: `git commit --no-verify` (git itself, not this installer).
#
# Bead: flywheel-f0e77 (ldp0a follow-up). Sister: security-precommit-installer.sh.

set -euo pipefail

SCHEMA_VERSION="canonical-cli-lint-precommit-installer/v1"
VERSION="0.1.0"
HOOKS_PATH_DEFAULT="githooks"
CHAIN_CONFIG_KEY="flywheel.securityPrecommitChain"
CHAIN_TARGET_REL=".flywheel/hooks/pre-commit-chain.sh"

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
JSON_OUT=0
APPLY=0
DRY_RUN=1
MODE=""

usage() {
  cat <<'USAGE'
canonical-cli-lint-precommit-installer.sh — wire canonical-cli-lint L1-L9
into git pre-commit chain via flywheel.securityPrecommitChain config.

USAGE:
  canonical-cli-lint-precommit-installer.sh <mode> [--apply] [--json]
  canonical-cli-lint-precommit-installer.sh --info|--examples|--schema|--help [--json]

MODES:
  install       Set flywheel.securityPrecommitChain to pre-commit-chain.sh
                Default --dry-run; mutate with --apply.
  uninstall     Unset flywheel.securityPrecommitChain.
                Default --dry-run; mutate with --apply.
  doctor        Probe substrate: linter+chain script+git config state.
  validate      Verify the wire-in is functional (chain config + chain script + linter).
  audit         Show current git config for this repo's hook chain.
  why <id>      Explain (1=core.hooksPath, 2=chain, 3=script, 4=linter).

OPTIONS:
  --apply       Mutate git config (default: dry-run, preview only)
  --json        Emit JSON envelopes
  --help/-h     This help

BYPASS:
  Operator bypasses with `git commit --no-verify` — git itself shortcuts
  the hook chain entirely. This is intentional and documented per
  blocker-discipline-style "operator escape hatch with audit trail":
  the bypass leaves a git log entry indicating the commit went through
  without hook gates.

EXIT CODES:
  0 success | 1 mutation failed or hook-chain validation failed
  2 usage error
  3 not-applicable (not in a git repo, chain script missing, linter missing)
USAGE
}

emit_info() {
  jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg v "$VERSION" \
    --arg repo "$REPO_ROOT" \
    --arg hp "$HOOKS_PATH_DEFAULT" \
    --arg ck "$CHAIN_CONFIG_KEY" \
    --arg ct "$CHAIN_TARGET_REL" \
    '{
      schema_version:$sv,
      name:"canonical-cli-lint-precommit-installer.sh",
      version:$v,
      repo:$repo,
      hooks_path:$hp,
      chain_config_key:$ck,
      chain_target_rel:$ct,
      sister:"security-precommit-installer.sh",
      bypass_mechanism:"git commit --no-verify",
      mutation_default:"dry-run",
      modes:["install","uninstall","doctor","validate","audit","why"],
      exit_codes:{"0":"success","1":"failed","2":"usage","3":"not_applicable"}
    }'
}

emit_examples() {
  jq -nc '{examples:[
    "canonical-cli-lint-precommit-installer.sh install --dry-run --json",
    "canonical-cli-lint-precommit-installer.sh install --apply --json",
    "canonical-cli-lint-precommit-installer.sh doctor --json",
    "canonical-cli-lint-precommit-installer.sh validate --json",
    "canonical-cli-lint-precommit-installer.sh audit --json",
    "canonical-cli-lint-precommit-installer.sh uninstall --apply --json"
  ]}'
}

emit_schema() {
  jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    '{
      "$schema":"https://json-schema.org/draft/2020-12/schema",
      schema_version:$sv,
      title:"canonical-cli-lint-precommit-installer envelopes",
      "$defs":{
        envelope:{
          type:"object",
          required:["schema_version","mode","status"],
          properties:{
            schema_version:{const:$sv},
            mode:{enum:["install","uninstall","doctor","validate","audit","why"]},
            status:{enum:["installed","uninstalled","planned","unplanned","ok","fail","warn","unknown"]},
            apply:{type:"boolean"},
            dry_run:{type:"boolean"},
            hooks_path:{type:["string","null"]},
            chain_target:{type:["string","null"]},
            chain_target_actual:{type:["string","null"]},
            chain_target_executable:{type:"boolean"},
            linter_executable:{type:"boolean"},
            checks:{type:"array"}
          }
        }
      }
    }'
}

# ---------- helpers ----------

now_iso() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }

ensure_git_repo() {
  if ! git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg repo "$REPO_ROOT" \
      '{schema_version:$sv,mode:"error",status:"fail",reason:"not a git repo",repo:$repo}'
    exit 3
  fi
}

# Get current git config value for a key (empty if unset).
git_get() {
  local key="$1"
  git -C "$REPO_ROOT" config --local --get "$key" 2>/dev/null || printf ''
}

# Set git config (apply only).
git_set() {
  local key="$1" value="$2"
  git -C "$REPO_ROOT" config --local "$key" "$value"
}

# Unset git config (apply only). Silent on already-unset.
git_unset() {
  local key="$1"
  git -C "$REPO_ROOT" config --local --unset "$key" 2>/dev/null || true
}

linter_path() { printf '%s/.flywheel/scripts/canonical-cli-lint.sh' "$REPO_ROOT"; }
chain_path()  { printf '%s/%s' "$REPO_ROOT" "$CHAIN_TARGET_REL"; }
chain_hook_canonical_cli()  { printf '%s/.flywheel/hooks/canonical-cli-lint-pre-commit.sh' "$REPO_ROOT"; }

# ---------- modes ----------

cmd_doctor() {
  local checks_jsonl="" overall="ok"
  _add() {
    local n="$1" s="$2" d="$3"
    [[ "$s" == "fail" ]] && overall="fail"
    checks_jsonl+="$(jq -nc --arg c "$n" --arg s "$s" --arg d "$d" '{check:$c,status:$s,detail:$d}')"$'\n'
  }

  # 1. linter exists + executable
  local lp; lp="$(linter_path)"
  if [[ -x "$lp" ]]; then _add linter ok "$lp"
  else _add linter fail "missing or not executable: $lp"
  fi

  # 2. chain dispatcher exists + executable
  local cp; cp="$(chain_path)"
  if [[ -x "$cp" ]]; then _add chain_dispatcher ok "$cp"
  else _add chain_dispatcher fail "missing or not executable: $cp"
  fi

  # 3. canonical-cli pre-commit hook exists + executable
  local pc; pc="$(chain_hook_canonical_cli)"
  if [[ -x "$pc" ]]; then _add canonical_cli_pre_commit ok "$pc"
  else _add canonical_cli_pre_commit warn "missing or not executable: $pc (chain will skip this hook)"
  fi

  # 4. core.hooksPath set (local or global)
  local hp_local hp_global
  hp_local="$(git_get core.hooksPath)"
  hp_global="$(git -C "$REPO_ROOT" config --global --get core.hooksPath 2>/dev/null || printf '')"
  if [[ -n "$hp_local" ]]; then _add core_hooks_path ok "local=$hp_local"
  elif [[ -n "$hp_global" ]]; then _add core_hooks_path warn "global=$hp_global (not repo-local; security-precommit-installer typically sets local=githooks)"
  else _add core_hooks_path warn "unset; git uses default .git/hooks"
  fi

  # 5. flywheel.securityPrecommitChain set + points at chain script
  local chain_cfg; chain_cfg="$(git_get "$CHAIN_CONFIG_KEY")"
  if [[ -z "$chain_cfg" ]]; then _add chain_config warn "$CHAIN_CONFIG_KEY unset (run install --apply to wire in)"
  elif [[ "$chain_cfg" == "$cp" ]] || [[ "$chain_cfg" == "$CHAIN_TARGET_REL" ]]; then
    _add chain_config ok "$chain_cfg"
  else _add chain_config warn "$CHAIN_CONFIG_KEY set to $chain_cfg (not our chain script $cp)"
  fi

  local ts; ts="$(now_iso)"
  printf '%s' "$checks_jsonl" | jq -sc \
    --arg sv "$SCHEMA_VERSION" --arg ts "$ts" --arg status "$overall" \
    '{schema_version:$sv,mode:"doctor",ts:$ts,status:$status,checks:.}'
}

cmd_install() {
  local cp; cp="$(chain_path)"
  if [[ ! -x "$cp" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg cp "$cp" \
      '{schema_version:$sv,mode:"install",status:"fail",reason:"chain dispatcher missing or not executable",chain_target:$cp}'
    exit 3
  fi

  local cur; cur="$(git_get "$CHAIN_CONFIG_KEY")"
  local planned_value="$cp"

  if [[ "$cur" == "$planned_value" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg ck "$CHAIN_CONFIG_KEY" --arg cur "$cur" \
      '{schema_version:$sv,mode:"install",status:"installed",apply:false,dry_run:false,chain_config_key:$ck,chain_target:$cur,idempotent_no_op:true,note:"already installed"}'
    return 0
  fi

  if [[ "$APPLY" -ne 1 ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg ck "$CHAIN_CONFIG_KEY" --arg cur "$cur" --arg pv "$planned_value" \
      '{schema_version:$sv,mode:"install",status:"planned",apply:false,dry_run:true,
        chain_config_key:$ck,
        chain_target_current:(if $cur == "" then null else $cur end),
        chain_target_planned:$pv,
        planned_actions:[{action:"git_config_set",key:$ck,value:$pv}],
        note:"add --apply to mutate"}'
    return 0
  fi

  git_set "$CHAIN_CONFIG_KEY" "$planned_value"
  local actual; actual="$(git_get "$CHAIN_CONFIG_KEY")"
  if [[ "$actual" == "$planned_value" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg ck "$CHAIN_CONFIG_KEY" --arg pv "$planned_value" \
      '{schema_version:$sv,mode:"install",status:"installed",apply:true,dry_run:false,
        chain_config_key:$ck,chain_target:$pv,
        applied_actions:[{action:"git_config_set",key:$ck,value:$pv,result:"ok"}]}'
  else
    jq -nc --arg sv "$SCHEMA_VERSION" --arg ck "$CHAIN_CONFIG_KEY" --arg pv "$planned_value" --arg actual "$actual" \
      '{schema_version:$sv,mode:"install",status:"fail",apply:true,dry_run:false,
        chain_config_key:$ck,chain_target_planned:$pv,chain_target_actual:$actual,
        reason:"git config set did not persist"}'
    return 1
  fi
}

cmd_uninstall() {
  local cur; cur="$(git_get "$CHAIN_CONFIG_KEY")"
  if [[ -z "$cur" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg ck "$CHAIN_CONFIG_KEY" \
      '{schema_version:$sv,mode:"uninstall",status:"uninstalled",apply:false,dry_run:false,chain_config_key:$ck,idempotent_no_op:true,note:"already unset"}'
    return 0
  fi

  if [[ "$APPLY" -ne 1 ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg ck "$CHAIN_CONFIG_KEY" --arg cur "$cur" \
      '{schema_version:$sv,mode:"uninstall",status:"planned",apply:false,dry_run:true,
        chain_config_key:$ck,chain_target_current:$cur,
        planned_actions:[{action:"git_config_unset",key:$ck,was:$cur}],
        note:"add --apply to mutate"}'
    return 0
  fi

  git_unset "$CHAIN_CONFIG_KEY"
  jq -nc --arg sv "$SCHEMA_VERSION" --arg ck "$CHAIN_CONFIG_KEY" --arg cur "$cur" \
    '{schema_version:$sv,mode:"uninstall",status:"uninstalled",apply:true,dry_run:false,
      chain_config_key:$ck,
      applied_actions:[{action:"git_config_unset",key:$ck,was:$cur,result:"ok"}]}'
}

cmd_validate() {
  # Validate the wire-in is functional. Distinct from doctor:
  # doctor probes the substrate; validate verifies the chain wiring is
  # logically consistent + ready to fire.
  local lp cp pc chain_cfg
  lp="$(linter_path)"
  cp="$(chain_path)"
  pc="$(chain_hook_canonical_cli)"
  chain_cfg="$(git_get "$CHAIN_CONFIG_KEY")"

  local results_jsonl="" pass=0 fail=0
  _add() {
    local check="$1" ok="$2" detail="$3"
    if [[ "$ok" == "true" ]]; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
    results_jsonl+="$(jq -nc --arg c "$check" --argjson ok "$ok" --arg d "$detail" '{check:$c,pass:$ok,detail:$d}')"$'\n'
  }

  [[ -x "$lp" ]] && _add linter_executable true "$lp" || _add linter_executable false "missing/not executable: $lp"
  [[ -x "$cp" ]] && _add chain_executable true "$cp" || _add chain_executable false "missing/not executable: $cp"
  [[ -x "$pc" ]] && _add canonical_cli_pre_commit_executable true "$pc" || _add canonical_cli_pre_commit_executable false "missing/not executable: $pc"
  [[ -n "$chain_cfg" ]] && _add chain_config_set true "$chain_cfg" || _add chain_config_set false "$CHAIN_CONFIG_KEY unset"
  [[ "$chain_cfg" == "$cp" ]] && _add chain_config_points_at_chain true "matches" || _add chain_config_points_at_chain false "expected=$cp got=$chain_cfg"

  local status="ok"
  [[ "$fail" -gt 0 ]] && status="fail"
  printf '%s' "$results_jsonl" | jq -sc \
    --arg sv "$SCHEMA_VERSION" --arg status "$status" --argjson p "$pass" --argjson f "$fail" \
    '{schema_version:$sv,mode:"validate",status:$status,pass:$p,fail:$f,checks:.}'
  [[ "$status" == "ok" ]] && return 0 || return 1
}

cmd_audit() {
  local hp_local; hp_local="$(git_get core.hooksPath)"
  local hp_global; hp_global="$(git -C "$REPO_ROOT" config --global --get core.hooksPath 2>/dev/null || printf '')"
  local chain_cfg; chain_cfg="$(git_get "$CHAIN_CONFIG_KEY")"

  jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg hpl "$hp_local" \
    --arg hpg "$hp_global" \
    --arg ck "$CHAIN_CONFIG_KEY" \
    --arg cc "$chain_cfg" \
    '{schema_version:$sv,mode:"audit",
      core_hooks_path_local:(if $hpl == "" then null else $hpl end),
      core_hooks_path_global:(if $hpg == "" then null else $hpg end),
      chain_config_key:$ck,
      chain_target:(if $cc == "" then null else $cc end),
      bypass_doc:"git commit --no-verify bypasses ALL pre-commit hooks (git built-in, not gate-able by this installer)"}'
}

cmd_why() {
  local id="${1:-}"
  case "$id" in
    "1"|core.hooksPath|hooks-path)
      jq -nc '{topic:"core.hooksPath",detail:"Points Git at the dispatcher directory. Set by security-precommit-installer.sh install --apply to local=githooks. Without this, git falls back to .git/hooks/."}' ;;
    "2"|chain|chain-config|securityPrecommitChain)
      jq -nc '{topic:"flywheel.securityPrecommitChain",detail:"Single-link chain config read by security-precommit-installer.sh run-hook. After scan-staged completes, run-hook calls the chain script. canonical-cli-lint-precommit-installer.sh install --apply points this at .flywheel/hooks/pre-commit-chain.sh"}' ;;
    "3"|chain-script|dispatcher)
      jq -nc '{topic:".flywheel/hooks/pre-commit-chain.sh",detail:"Multi-hook dispatcher. Runs canonical-cli-lint-pre-commit.sh then file-rag-discipline-pre-commit.sh (if present). First failure stops the chain for fastest operator feedback."}' ;;
    "4"|linter)
      jq -nc '{topic:".flywheel/scripts/canonical-cli-lint.sh",detail:"L1-L9 rules. L9 (apply-side-effect-before-gate) added by flywheel-ldp0a. Runs against staged .sh under .flywheel/scripts/ + any .sh with magic comment # flywheel-cli-surface: true."}' ;;
    *)
      jq -nc --arg id "$id" '{topic:"unknown",id:$id,known_topics:["1=core.hooksPath","2=chain","3=chain-script","4=linter"]}' ;;
  esac
}

# ---------- main ----------

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info) emit_info; exit 0 ;;
    --examples) emit_examples; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    --json) JSON_OUT=1; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --dry-run) APPLY=0; DRY_RUN=1; shift ;;
    install|uninstall|doctor|validate|audit|why) MODE="$1"; shift ;;
    --) shift; break ;;
    *)
      if [[ "$MODE" == "why" ]] && [[ -z "${WHY_ID:-}" ]]; then
        WHY_ID="$1"; shift
      else
        echo "ERR: unknown arg: $1" >&2; usage >&2; exit 2
      fi ;;
  esac
done

[[ -z "$MODE" ]] && { echo "ERR: mode required" >&2; usage >&2; exit 2; }

ensure_git_repo

case "$MODE" in
  install)   cmd_install ;;
  uninstall) cmd_uninstall ;;
  doctor)    cmd_doctor ;;
  validate)  cmd_validate ;;
  audit)     cmd_audit ;;
  why)       cmd_why "${WHY_ID:-}" ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
