#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-lint.sh — static linter for flywheel canonical-CLI surfaces.
#
# Detects 4 bash gotchas hit during the daily-report-enabled-repos pilot
# plus 4 canonical-CLI acceptance violations. Static analysis only;
# never executes the target scripts. Zero external deps beyond bash,
# jq, grep, awk, sed.
#
# Rules (9 total):
#   L1 chained-local-set-u    — `local x="$1" y="$x/foo"` fails under set -u
#   L2 missing-return-zero    — function ending in if/&&/|| returns last rc
#   L3 brace-default-ambig    — `${3:-{}}` parses incorrectly
#   L4 short-circuit-helper   — `[[ ]] && X || Y` as last expr in helper
#   L5 missing-strict-mode    — top-of-script lacks `set -euo pipefail`
#   L6 missing-magic-comment  — script with --apply lacks marker comment
#   L7 apply-no-idem-key      — --apply path doesn't gate on idempotency-key
#   L8 mutate-no-backup       — --apply writes to user-state without .bak
#   L9 apply-side-effect-before-gate
#   L10 apply-mutation-needs-key — --apply pairs with mutation patterns but no
#                                  --idempotency-key gate (stricter than L7;
#                                  filed by 7axmt audit as bug-class detector)
#                             — side-effect inside --apply block fires BEFORE
#                                 apply-key gate refuses (hoqq8 trauma class:
#                                 refused apply still leaves test scaffold
#                                 behind). Hoist the gate above side-effects.
#
# Bead: flywheel-etp5n. Spec: .flywheel/audit/flywheel-jloib.0c/apply-spec.md.
set -euo pipefail

SCHEMA_VERSION="canonical-cli-lint/v1"
VERSION="0.1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"

usage() {
  cat <<'USAGE'
canonical-cli-lint.sh — static linter for flywheel canonical-CLI surfaces

USAGE:
  canonical-cli-lint.sh <script_path> [--json] [--rule LIST]
  canonical-cli-lint.sh --scan-all [--json] [--rule LIST] [--root DIR]
  canonical-cli-lint.sh --info | --schema | --examples | --doctor | --help

OPTIONS:
  <script_path>        Lint one file. Use - for stdin.
  --scan-all           Lint every .sh under <root>/.flywheel/scripts/
  --root <dir>         Override repo root (default: auto-detected)
  --rule L1,L3,L7,L10  Comma list of rules to run (default: all L1..L10)
  --json               Emit JSON envelope on stdout
  --info | --schema | --examples | --doctor | --help

EXIT CODES:
  0 clean | 1 violations found | 2 bad args | 3 file not found
USAGE
}

emit_info() {
  jq -nc --arg sv "$SCHEMA_VERSION" --arg v "$VERSION" '{
    schema_version:$sv,
    success:true,
    mode:"info",
    name:"canonical-cli-lint",
    version:$v,
    rules:[
      {id:"L1",label:"chained-local-set-u"},
      {id:"L2",label:"missing-return-zero"},
      {id:"L3",label:"brace-default-ambiguity"},
      {id:"L4",label:"short-circuit-in-helper"},
      {id:"L5",label:"missing-strict-mode"},
      {id:"L6",label:"missing-magic-comment"},
      {id:"L7",label:"apply-without-idempotency-key"},
      {id:"L8",label:"mutate-without-backup"},
      {id:"L9",label:"apply-side-effect-before-gate"},
      {id:"L10",label:"apply-mutation-needs-key"}
    ],
    exit_codes:{clean:0, violations:1, bad_args:2, not_found:3}
  }'
}

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    schema_version:$sv,
    title:"canonical-cli-lint output",
    type:"object",
    required:["schema_version","status","files_scanned","violations"],
    properties:{
      schema_version:{const:$sv},
      status:{enum:["clean","violations","error"]},
      files_scanned:{type:"integer",minimum:0},
      violations:{
        type:"array",
        items:{
          type:"object",
          required:["file","line","rule","message"],
          properties:{
            file:{type:"string"},
            line:{type:"integer",minimum:1},
            rule:{enum:["L1","L2","L3","L4","L5","L6","L7","L8","L9","L10"]},
            label:{type:"string"},
            message:{type:"string"},
            severity:{enum:["error","warn"]}
          }
        }
      }
    }
  }'
}

emit_examples() {
  cat <<'EX'
canonical-cli-lint.sh .flywheel/scripts/daily-report-enabled-repos.sh
canonical-cli-lint.sh --scan-all
canonical-cli-lint.sh --scan-all --json > lint-baseline.json
canonical-cli-lint.sh script.sh --rule L1,L3,L7
canonical-cli-lint.sh script.sh --rule L7,L8 --json
EX
}

emit_doctor() {
  local bash_ok=true jq_ok=true
  command -v jq >/dev/null 2>&1 || jq_ok=false
  jq -nc --arg sv "$SCHEMA_VERSION" --argjson bash "$bash_ok" --argjson jq "$jq_ok" '{
    schema_version:($sv | sub("/v1$"; ".doctor.v1")),
    status:(if $bash and $jq then "pass" else "warn" end),
    bash_present:$bash,
    jq_present:$jq
  }'
}

# ---------- rule implementations ----------
# Each rule takes (file, lineno, line) and emits violation rows
# to stdout in the format: line<TAB>rule<TAB>label<TAB>severity<TAB>message
# We then post-process into JSON or text.

_RULE_BUF=""
_FUNC_DEPTH=0
_FUNC_BODY=""
_FUNC_START=0
_FUNC_NAME=""

_violations=()

emit_v() {
  # args: line rule label severity message
  _violations+=("$1"$'\t'"$2"$'\t'"$3"$'\t'"$4"$'\t'"$5")
}

# Read a file and run rules. We do single-pass scanning; complex
# function-body rules are handled via state machine.
lint_file() {
  local file="$1"
  local rules_filter="$2"
  local has_apply=false has_magic=false has_strict=false
  local in_func=false func_start=0 func_name="" func_body=""
  local lineno=0
  local prev_line=""
  local has_idem_check=false
  local func_has_return=false
  # L10 signals (7axmt-followup bug-class detector). Mutation patterns set
  # has_mutation when surface uses git commit/push, ntm send, br update/set/
  # close, sed -i, etc. has_l10_exempt is set when surface explicitly refuses
  # --apply (apply_not_supported, --apply == --check) or declares itself
  # idempotent (# IDEMPOTENT-BY-CONSTRUCTION:).
  local has_mutation=false
  local has_l10_exempt=false
  local mutation_sample=""

  if [[ "$file" == "-" ]]; then
    file="<stdin>"
    mapfile -t lines < <(cat)
  elif [[ ! -r "$file" ]]; then
    return 3
  else
    mapfile -t lines < "$file"
  fi

  # First pass — gather global signals
  for line in "${lines[@]}"; do
    [[ "$line" =~ ^#[[:space:]]*flywheel-cli-surface:[[:space:]]*true ]] && has_magic=true
    [[ "$line" =~ ^set[[:space:]]+-euo[[:space:]]+pipefail ]] && has_strict=true
    [[ "$line" =~ \-\-apply\) ]] && has_apply=true
    [[ "$line" =~ idempotency-key|IDEM_KEY|idem_key ]] && has_idem_check=true
    # L10 — exemption markers: explicit no-apply refusal OR declared idempotency.
    if [[ "$line" =~ apply_not_supported|read_only_bridge|apply.*==.*--check ]]; then
      has_l10_exempt=true
    fi
    if [[ "$line" =~ \#[[:space:]]*IDEMPOTENT-BY-CONSTRUCTION ]]; then
      has_l10_exempt=true
    fi
    # L10 — mutation patterns (7axmt audit's bug-class detector).
    # External pane state (ntm send), beads writes (br update/set/close/dep/label),
    # git commits/pushes/resets, in-place edits, plist writes, file writes to
    # non-tmp paths, destructive rm.
    if [[ -z "$mutation_sample" ]]; then
      # Skip comment-only lines (#... mentions are documentation, not mutation)
      local _trim="${line## }"
      _trim="${_trim## }"
      if [[ ! "$_trim" =~ ^# ]]; then
        if [[ "$line" =~ git[[:space:]]+(commit|push|reset[[:space:]]+--hard|checkout[[:space:]]+--|merge|rebase|tag|branch[[:space:]]+-D) ]] \
          || [[ "$line" =~ ntm[[:space:]]+send ]] \
          || [[ "$line" =~ \"\$BR_BIN\"[[:space:]]+(update|set|close|dep|label) ]] \
          || [[ "$line" =~ br[[:space:]]+(update|set|close[[:space:]]|dep[[:space:]]+add|label[[:space:]]+add) ]] \
          || [[ "$line" =~ sed[[:space:]]+-i([[:space:]]|$) ]] \
          || [[ "$line" =~ plistlib\.dump ]]; then
          has_mutation=true
          mutation_sample="$line"
        fi
      fi
    fi
  done

  # L5 — missing strict mode
  if _rule_enabled L5 "$rules_filter"; then
    if ! $has_strict; then
      emit_v 1 L5 missing-strict-mode error "missing 'set -euo pipefail' near top of script"
    fi
  fi

  # L6 — magic comment required if --apply present
  if _rule_enabled L6 "$rules_filter"; then
    if $has_apply && ! $has_magic; then
      emit_v 1 L6 missing-magic-comment error "script handles --apply but lacks '# flywheel-cli-surface: true' marker"
    fi
  fi

  # L7 — apply without idempotency-key (broad presence check)
  if _rule_enabled L7 "$rules_filter"; then
    if $has_apply && ! $has_idem_check; then
      emit_v 1 L7 apply-without-idempotency-key error "--apply path does not gate on --idempotency-key (no IDEM_KEY/idempotency-key reference found)"
    fi
  fi

  # L10 — apply paired with mutation patterns without --idempotency-key gate
  # (stricter than L7; filed by 7axmt audit as the bug-class detector).
  # Fires only when: --apply present AND --idempotency-key absent AND mutation
  # patterns present AND no exemption marker. The 7 sister fixes (8sx9w,
  # 1o9fa, j0xpa, j99xb, mfy7u, y0ft6, wdh08) all now satisfy this rule.
  # Exemption: surfaces with apply_not_supported / read_only_bridge / "--apply
  # == --check" refusal OR with '# IDEMPOTENT-BY-CONSTRUCTION:' marker.
  if _rule_enabled L10 "$rules_filter"; then
    if $has_apply && ! $has_idem_check && $has_mutation && ! $has_l10_exempt; then
      local sample="${mutation_sample##*( )}"
      sample="${sample:0:140}"
      emit_v 1 L10 apply-mutation-needs-key error "--apply paired with mutation pattern '${sample}' but no --idempotency-key gate; add the canonical refusal contract per 7axmt-followup pair-pattern (mark surface '# IDEMPOTENT-BY-CONSTRUCTION:' if mutation is structurally idempotent)"
    fi
  fi

  # Second pass — line-level rules
  lineno=0
  in_func=false
  func_start=0
  func_name=""
  func_body=""

  # L9 line-set collection (apply-block openers, gate fires, side-effects).
  # Cross-line check runs after the loop. Patterns adapted from m12ji's
  # scanner.py and the hoqq8 fix-diff (canonical example).
  #
  # Function-scope-aware: gates only protect side-effects in the SAME
  # function. The hoqq8 trauma was scaffold_target() having a gate at
  # the bottom while side-effects ran at the top — but other functions
  # (e.g., a separate repair handler) had their own gate that L9 must
  # NOT credit toward scaffold_target's coverage.
  local -a _l9_apply_block_lines=()
  local -a _l9_apply_block_funcs=()
  local -a _l9_gate_lines=()
  local -a _l9_gate_funcs=()
  local -a _l9_side_effect_lines=()
  local -a _l9_side_effect_funcs=()
  local -a _l9_side_effect_samples=()
  local _l9_current_func=""
  local _l9_brace_depth=0

  for line in "${lines[@]}"; do
    lineno=$((lineno + 1))
    local trimmed="${line#"${line%%[![:space:]]*}"}"

    # L9 — line-set collection (skipped during analysis, used after loop).
    # Only collect if rule is enabled to avoid wasted work when L9 is filtered out.
    if _rule_enabled L9 "$rules_filter"; then
      # Function-scope tracker for L9 (independent of L2/L4's tracker, which
      # runs AFTER this block). Reset at function start; clear at closing `}`.
      if [[ "$trimmed" =~ ^([a-zA-Z_][a-zA-Z0-9_]*)\(\)[[:space:]]*\{?[[:space:]]*$ ]] || \
         [[ "$trimmed" =~ ^function[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
        _l9_current_func="${BASH_REMATCH[1]}"
        _l9_brace_depth=1
      elif [[ -n "$_l9_current_func" ]]; then
        # Crude brace-depth tracking: count `{` and `}` on this line.
        # Sufficient for the common shapes (one func per close-brace at col 0).
        local _l9_opens="${trimmed//[^\{]/}"
        local _l9_closes="${trimmed//[^\}]/}"
        _l9_brace_depth=$((_l9_brace_depth + ${#_l9_opens} - ${#_l9_closes}))
        if [[ "$_l9_brace_depth" -le 0 ]]; then
          _l9_current_func=""
          _l9_brace_depth=0
        fi
      fi

      # Skip comments + blank lines
      if [[ -n "$trimmed" ]] && [[ ! "$trimmed" =~ ^# ]]; then
        # Apply-block openers (matches m12ji's APPLY_BLOCK_OPENER set).
        # Pattern matches BARE `if [[ "$mode" == "apply" ]]` — NOT joint
        # forms like `... && -z "$idem_key" ]]`. Joint gate-conditions are
        # captured separately as gates (they refuse-and-exit).
        if [[ "$line" =~ if[[:space:]]+\[\[[[:space:]]+\"\$mode\"[[:space:]]*==[[:space:]]*\"apply\"[[:space:]]*\]\] ]] || \
           [[ "$line" =~ if[[:space:]]+\[\[[[:space:]]+\"\$\{mode:?-?\}\"[[:space:]]*==[[:space:]]*\"apply\"[[:space:]]*\]\] ]] || \
           [[ "$line" =~ if[[:space:]]+\[\[[[:space:]]+\"\$apply_mode\"[[:space:]]*==[[:space:]]*true[[:space:]]*\]\] ]] || \
           [[ "$line" =~ if[[:space:]]+\[\[[[:space:]]+\$\{?mode\}?[[:space:]]*==[[:space:]]*\"?apply\"?[[:space:]]*\]\] ]]; then
          _l9_apply_block_lines+=("$lineno")
          _l9_apply_block_funcs+=("$_l9_current_func")
        fi
        # Gate fires (matches m12ji's GATE_PATTERNS — looser than block opener)
        if [[ "$line" =~ cli_refuse_apply_without_idem_key ]] || \
           [[ "$line" =~ \"--apply[[:space:]]+requires[[:space:]]+--idempotency-key\" ]] || \
           [[ "$line" =~ \"--apply\"[[:space:]]+requires[[:space:]]+\"--idempotency-key\" ]]; then
          _l9_gate_lines+=("$lineno")
          _l9_gate_funcs+=("$_l9_current_func")
        fi
        # Side-effects (mkdir/cp/mv/rm/sed -i/chmod/touch + git mutating + redirect to non-tmp).
        # Patterns match anywhere on the line (not anchored to start) since
        # mid-line shapes like `cmd > "$var"` and `emit_x > "$test_path"` were
        # the canonical hoqq8 trauma example. Exclusion list filters tmp paths.
        local _se_match=false
        if [[ "$line" =~ (^|[^a-zA-Z_])(mkdir[[:space:]]+-p[[:space:]]) ]] || \
           [[ "$line" =~ (^|[^a-zA-Z_])(cp[[:space:]]+(-[a-zA-Z]+[[:space:]]+)?[^-]) ]] || \
           [[ "$line" =~ (^|[^a-zA-Z_])(mv[[:space:]]+) ]] || \
           [[ "$line" =~ (^|[^a-zA-Z_])(rm[[:space:]]+-rf?[[:space:]]) ]] || \
           [[ "$line" =~ (^|[^a-zA-Z_])(sed[[:space:]]+-i) ]] || \
           [[ "$line" =~ (^|[^a-zA-Z_])(chmod[[:space:]]) ]] || \
           [[ "$line" =~ (^|[^a-zA-Z_])(touch[[:space:]]+[^-]) ]] || \
           [[ "$line" =~ (^|[^a-zA-Z_])(git[[:space:]]+(commit|push|reset[[:space:]]+--hard|rebase|cherry-pick)) ]] || \
           [[ "$line" =~ \>\>?[[:space:]]*\"?\$HOME ]] || \
           [[ "$line" =~ \>\>?[[:space:]]*\"?/Users/ ]] || \
           [[ "$line" =~ \>\>?[[:space:]]*\"?\$\{?[a-zA-Z][a-zA-Z0-9_]* ]]; then
          _se_match=true
        fi
        # Filter: tmp paths, .bak suffixes, /dev/null, stderr/stdout, here-doc
        # token markers aren't production side-effects (per m12ji exclusion list).
        if $_se_match; then
          if [[ "$line" =~ \$tmp_|\$WORK_TMP|tmp_dir|/tmp/|/private/tmp/|TMPDIR|\.bak\.|/dev/null|\>\&[12]|\>[[:space:]]*\$\{?(stdout|stderr) ]]; then
            _se_match=false
          fi
          # Also exclude redirect-to-fd (e.g. `2>&1`, `>&2`) and JSON > here strings (`<<<`, `<<EOF`)
          # which shouldn't trip the redirect-to-var pattern.
          if [[ "$line" =~ \<\<\< ]] || [[ "$line" =~ \<\<[A-Z] ]]; then
            _se_match=false
          fi
        fi
        if $_se_match; then
          _l9_side_effect_lines+=("$lineno")
          _l9_side_effect_samples+=("${trimmed:0:80}")
          _l9_side_effect_funcs+=("$_l9_current_func")
        fi
      fi
    fi

    # L1 — chained local with set -u risk
    # `local x="..." y="...$x..."` — bash regex lacks backreferences,
    # so we match the structural shape (two `name="..."` assignments
    # on one local line where second value contains a $-reference) and
    # then verify via grep that the second value references the first
    # name. False-positive rate is acceptably low because the structural
    # pattern is uncommon.
    if _rule_enabled L1 "$rules_filter"; then
      if [[ "$line" =~ ^[[:space:]]*local[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)=\"[^\"]*\"[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)=\"[^\"]*\$ ]]; then
        local first_var="${BASH_REMATCH[1]}"
        # Get everything after first match — check if second value references first_var
        if [[ "$line" =~ \"[^\"]*\$\{?${first_var}[^a-zA-Z0-9_]?[^\"]*\"[[:space:]]*$ ]]; then
          emit_v "$lineno" L1 chained-local-set-u error "chained 'local' references prior var '\$${first_var}' on same line; fails under set -u — split into two local lines"
        fi
      fi
    fi

    # L3 — brace-default-ambiguity ${N:-{}}
    if _rule_enabled L3 "$rules_filter"; then
      if [[ "$line" =~ \$\{[0-9]+:-\{\}\} ]] || [[ "$line" =~ \$\{[a-zA-Z_][a-zA-Z0-9_]*:-\{\}\} ]]; then
        emit_v "$lineno" L3 brace-default-ambiguity error "\${X:-{}} parses incorrectly — use intermediate var with explicit fallback"
      fi
    fi

    # Function body tracking for L2 and L4
    # Match: name() { OR function name { OR name () {
    if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\(\)[[:space:]]*\{[[:space:]]*$ ]] || \
       [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\(\)[[:space:]]*$ ]] || \
       [[ "$line" =~ ^[[:space:]]*function[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
      in_func=true
      func_start="$lineno"
      func_name="${BASH_REMATCH[1]}"
      func_body=""
      func_has_return=false
      prev_line=""
      continue
    fi

    if $in_func; then
      # End of function: closing brace at column 0 or only-whitespace prefix
      if [[ "$line" =~ ^[[:space:]]*\}[[:space:]]*$ ]]; then
        # Run function-end rules using prev_line as last meaningful line
        local last_line="${prev_line#"${prev_line%%[![:space:]]*}"}"

        # L2 — enumerator function returning last iteration's rc.
        # Specifically: last meaningful line is `done` (for/while loop
        # terminator with optional input redirect) AND no explicit
        # return appears anywhere in the body. Pilot bug shape:
        #   list_enabled() { for x; do is_y "$x" && echo "$x"; done; }
        # → returns rc of last is_y; trips `cmd $(list_enabled)` under set -e.
        if _rule_enabled L2 "$rules_filter"; then
          if ! $func_has_return; then
            # `done | cmd` (pipe) means rc is rightmost cmd's, not the loop's
            # → skip those (false positive). Only flag bare `done` or
            # `done <<<input` with NO trailing pipe.
            if [[ "$last_line" =~ ^done([[:space:]]|$|\<) ]] && \
               [[ ! "$last_line" =~ \| ]]; then
              emit_v "$func_start" L2 missing-return-zero warn "enumerator function '$func_name' last line is 'done' with no explicit return; rc bleeds from loop body — add 'return 0'"
            fi
          fi
        fi

        # L4 — [[ ]] && X || Y as final expression
        if _rule_enabled L4 "$rules_filter"; then
          if [[ "$last_line" =~ ^\[\[.*\]\][[:space:]]*\&\&.*\|\| ]]; then
            emit_v "$func_start" L4 short-circuit-in-helper error "function '$func_name' last expr is '[[ ]] && X || Y'; under set -e the failed branch may exit early — use if/then/elif/fi"
          fi
        fi

        in_func=false
        func_name=""
        func_body=""
      else
        # Track meaningful (non-comment, non-blank) lines for prev_line
        if [[ -n "$trimmed" ]] && [[ ! "$trimmed" =~ ^# ]]; then
          prev_line="$line"
          [[ "$trimmed" =~ ^(return|exit)([[:space:]]|$) ]] && func_has_return=true
        fi
      fi
    fi

    # L8 — mutate without backup (heuristic: --apply block writes to non-/tmp path)
    # Conservative: scan for `>` redirect to ${HOME}/... or absolute non-/tmp path
    # within --apply case arms. We emit warn (not error) per spec.
    if _rule_enabled L8 "$rules_filter"; then
      # Only flag inside obvious mutation contexts; we look at the line itself
      # for a heredoc/pipe write that could be destructive.
      if [[ "$line" =~ \>[[:space:]]*\"?(\$HOME|/Users/|\$\{HOME\}) ]] && \
         [[ ! "$line" =~ \.bak ]] && \
         [[ "$line" =~ apply|APPLY ]]; then
        emit_v "$lineno" L8 mutate-without-backup warn "write to user-state path inside --apply context without visible .bak.<ts> backup"
      fi
    fi
  done

  # L9 — apply-side-effect-before-gate (cross-line, post-pass).
  # Trauma class: hoqq8 — refused --apply (no idempotency-key) still wrote
  # tests/<name>-canonical-cli.sh because the test-scaffold side-effect ran
  # BEFORE the apply-key gate. Per m12ji audit (95 surfaces, 0 violations),
  # we want this STAY-clean preventively at author time.
  #
  # Violation shape: side-effect line is INSIDE an apply-block (after some
  # apply-block opener) AND BEFORE the first apply-key gate. If gate is
  # absent entirely, L7 catches it; L9 stays silent.
  if _rule_enabled L9 "$rules_filter"; then
    if [[ "${#_l9_apply_block_lines[@]}" -gt 0 ]] && [[ "${#_l9_side_effect_lines[@]}" -gt 0 ]]; then
      local _l9_idx=0
      for _l9_se_line in "${_l9_side_effect_lines[@]}"; do
        local _l9_se_func="${_l9_side_effect_funcs[$_l9_idx]:-}"
        # Find most recent apply-block opener strictly before this side-effect
        # AND in the same function scope (or both top-level).
        local _l9_most_recent_ab=0
        local _l9_ab_idx=0
        for _l9_ab in "${_l9_apply_block_lines[@]}"; do
          local _l9_ab_func="${_l9_apply_block_funcs[$_l9_ab_idx]:-}"
          if [[ "$_l9_ab" -lt "$_l9_se_line" ]] && [[ "$_l9_ab_func" == "$_l9_se_func" ]]; then
            _l9_most_recent_ab="$_l9_ab"
          fi
          _l9_ab_idx=$((_l9_ab_idx + 1))
        done
        # Side-effect not inside any apply-block context in same function → skip
        if [[ "$_l9_most_recent_ab" -eq 0 ]]; then
          _l9_idx=$((_l9_idx + 1))
          continue
        fi
        # Look for any gate BEFORE the side-effect in the SAME function.
        # Function-scope is load-bearing: hoqq8 trauma was scaffold_target()
        # missing its own gate while another function (repair scope) had
        # one. Cross-function gates don't protect this SE.
        local _l9_gated=false
        local _l9_g_idx=0
        for _l9_g in "${_l9_gate_lines[@]}"; do
          local _l9_g_func="${_l9_gate_funcs[$_l9_g_idx]:-}"
          if [[ "$_l9_g" -lt "$_l9_se_line" ]] && [[ "$_l9_g_func" == "$_l9_se_func" ]]; then
            _l9_gated=true
            break
          fi
          _l9_g_idx=$((_l9_g_idx + 1))
        done
        if ! $_l9_gated; then
          local _l9_sample="${_l9_side_effect_samples[$_l9_idx]:-}"
          local _l9_scope="${_l9_se_func:-<top-level>}"
          emit_v "$_l9_se_line" L9 apply-side-effect-before-gate error "side-effect inside apply-block (opened L${_l9_most_recent_ab}, scope=${_l9_scope}) fires with no apply-key gate before it in same function — hoist 'cli_refuse_apply_without_idem_key' above side-effect per flywheel-hoqq8 trauma class. Sample: ${_l9_sample}"
        fi
        _l9_idx=$((_l9_idx + 1))
      done
    fi
  fi

  return 0
}

_rule_enabled() {
  local rule="$1" filter="${2:-}"
  [[ -z "$filter" ]] && return 0
  [[ ",$filter," == *",$rule,"* ]]
}

# ---------- main ----------
MODE=lint
JSON=false
SCAN_ALL=false
RULE_FILTER=""
ROOT_DIR="$REPO_ROOT"
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info) emit_info; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    --examples) emit_examples; exit 0 ;;
    --doctor|--health) emit_doctor; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    --json) JSON=true; shift ;;
    --scan-all) SCAN_ALL=true; shift ;;
    --rule) RULE_FILTER="$2"; shift 2 ;;
    --root) ROOT_DIR="$2"; shift 2 ;;
    --) shift; break ;;
    -*) echo "ERR: unknown flag: $1" >&2; usage >&2; exit 2 ;;
    *) TARGET="$1"; shift ;;
  esac
done

declare -a FILES_TO_LINT=()
if $SCAN_ALL; then
  while IFS= read -r f; do FILES_TO_LINT+=("$f"); done < <(find "$ROOT_DIR/.flywheel/scripts" -maxdepth 1 -name '*.sh' -type f 2>/dev/null | sort)
elif [[ -n "$TARGET" ]]; then
  FILES_TO_LINT+=("$TARGET")
else
  echo "ERR: provide a script path or --scan-all" >&2
  exit 2
fi

# Run lint for each file, accumulate _violations
ALL_V=()
SCANNED=0
for f in "${FILES_TO_LINT[@]}"; do
  _violations=()
  if ! lint_file "$f" "$RULE_FILTER"; then
    rc=$?
    if [[ "$rc" -eq 3 ]]; then
      echo "ERR: file not found: $f" >&2
      exit 3
    fi
  fi
  SCANNED=$((SCANNED + 1))
  for v in "${_violations[@]:-}"; do
    [[ -z "$v" ]] && continue
    ALL_V+=("$f"$'\t'"$v")
  done
done

VIOLATION_COUNT="${#ALL_V[@]}"

if $JSON; then
  status="clean"
  [[ "$VIOLATION_COUNT" -gt 0 ]] && status="violations"
  jq_input=""
  for row in "${ALL_V[@]:-}"; do
    [[ -z "$row" ]] && continue
    IFS=$'\t' read -r f line rule label severity message <<<"$row"
    jq_input+=$(jq -nc \
      --arg file "$f" \
      --argjson line "$line" \
      --arg rule "$rule" \
      --arg label "$label" \
      --arg severity "$severity" \
      --arg message "$message" \
      '{file:$file, line:$line, rule:$rule, label:$label, severity:$severity, message:$message}')
    jq_input+=$'\n'
  done
  if [[ -z "$jq_input" ]]; then
    violations_json="[]"
  else
    violations_json=$(echo -n "$jq_input" | jq -sc '.')
  fi
  jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg status "$status" \
    --argjson scanned "$SCANNED" \
    --argjson violations "$violations_json" \
    '{schema_version:$sv, status:$status, files_scanned:$scanned, violations:$violations}'
else
  for row in "${ALL_V[@]:-}"; do
    [[ -z "$row" ]] && continue
    IFS=$'\t' read -r f line rule label severity message <<<"$row"
    printf '%s:%s: %s [%s,%s]: %s\n' "$f" "$line" "$rule" "$label" "$severity" "$message"
  done
fi

[[ "$VIOLATION_COUNT" -eq 0 ]] && exit 0
exit 1

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
