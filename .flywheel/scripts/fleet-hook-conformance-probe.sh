#!/usr/bin/env bash
# fleet-hook-conformance-probe.sh — fleet-wide hook hygiene observability.
#
# SLB-3: skillos:1 + flywheel:1 CONCUR 2026-05-20T22:55Z.
# Sister: flywheel-sync-hooks.sh
# Schema: skillos.hook_manifest.v1
#
# For each repo under ~/Developer/*: enumerate installed hooks
# (.git/hooks/* + ~/.claude/hooks/* visible to the repo) and compare
# against the canonical HOOK-MANIFEST + canonical .flywheel/hooks/ contents.
#
# Outputs (stdout):
#   default → JSON object with `fleet_hook_hygiene` block (doctor key).
#   --dashboard → single-line "Hook hygiene: <conformant>/<total> repos | <rogue> rogue | <missing> missing"
#
# Exit 0 even when non-conformant — this is OBSERVABILITY not enforcement.

set -euo pipefail

DASHBOARD=0
JSON_ONLY=0
FLEET_ROOT="${FLEET_ROOT:-$HOME/Developer}"

while (( $# > 0 )); do
  case "$1" in
    --dashboard) DASHBOARD=1; shift ;;
    --json)      JSON_ONLY=1; shift ;;
    --fleet-root) FLEET_ROOT="$2"; shift 2 ;;
    -h|--help)
      cat <<'EOF'
fleet-hook-conformance-probe.sh — enumerate hook hygiene across fleet repos.

USAGE:
  fleet-hook-conformance-probe.sh [--dashboard|--json] [--fleet-root <dir>]

OUTPUT:
  default | --json : full JSON to stdout (doctor key: fleet_hook_hygiene)
  --dashboard      : single dashboard line on stdout
EOF
      exit 0 ;;
    *) echo "[probe] unknown arg: $1" >&2; exit 2 ;;
  esac
done

command -v jq >/dev/null || { echo "[probe] jq required" >&2; exit 2; }

CANON_DIR="$HOME/Developer/flywheel/.flywheel/hooks"
if [[ ! -d "$CANON_DIR" ]]; then
  jq -n --arg msg "canonical hooks dir missing: $CANON_DIR" \
    '{fleet_hook_hygiene:{status:"unknown", reason:$msg, repos:[]}}'
  exit 0
fi

sha_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

# Build canonical map id -> sha
declare -A CANON_SHA
declare -a CANON_IDS
while IFS= read -r f; do
  base="$(basename "$f")"
  id="${base%.sh}"
  CANON_IDS+=("$id")
  CANON_SHA["$id"]="$(sha_file "$f")"
done < <(find "$CANON_DIR" -maxdepth 1 -type f -name '*.sh' | sort)

# Enumerate repos under fleet root
declare -a REPOS=()
while IFS= read -r d; do
  [[ -d "$d/.git" || -f "$d/.git" ]] && REPOS+=("$d")
done < <(find "$FLEET_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

TOTAL_REPOS=${#REPOS[@]}
CONFORMANT=0
TOTAL_ROGUE=0
TOTAL_MISSING=0

REPO_ENTRIES="["
first_repo=1

for repo in "${REPOS[@]}"; do
  name="$(basename "$repo")"
  manifest="$repo/.flywheel/HOOK-MANIFEST.json"
  has_manifest=0
  [[ -f "$manifest" ]] && has_manifest=1

  # opted-out ids
  declare -a opted=()
  if (( has_manifest )); then
    while IFS= read -r oid; do
      [[ -n "$oid" ]] && opted+=("$oid")
    done < <(jq -r '.hook_opt_out[]?.id // empty' "$manifest" 2>/dev/null)
  fi
  is_opted() { local x="$1"; for o in "${opted[@]:-}"; do [[ "$o" == "$x" ]] && return 0; done; return 1; }

  # tool hooks visible: ~/.claude/hooks (one shared dir per machine)
  declare -a installed=()
  if [[ -d "$HOME/.claude/hooks" ]]; then
    while IFS= read -r f; do
      installed+=("$f")
    done < <(find "$HOME/.claude/hooks" -maxdepth 1 -type f -name '*.sh' 2>/dev/null)
  fi
  # repo git hooks
  if [[ -d "$repo/.git/hooks" ]]; then
    while IFS= read -r f; do
      installed+=("$f")
    done < <(find "$repo/.git/hooks" -maxdepth 1 -type f 2>/dev/null | grep -v '\.sample$' || true)
  fi

  # For each canonical id, classify
  missing_for_repo=0
  stale_for_repo=0
  conformant_count=0
  rogue_for_repo=0
  opt_out_count=0

  HOOK_DETAILS="["
  fd=1
  for id in "${CANON_IDS[@]}"; do
    if is_opted "$id"; then
      opt_out_count=$((opt_out_count+1))
      (( fd )) || HOOK_DETAILS+=","; fd=0
      reason=$(jq -r --arg id "$id" '.hook_opt_out[]? | select(.id==$id) | .reason // ""' "$manifest" 2>/dev/null)
      HOOK_DETAILS+=$(jq -nc --arg id "$id" --arg r "$reason" '{id:$id, status:"opted_out", reason:$r}')
      continue
    fi
    # find install
    found_path=""
    found_sha=""
    for f in "${installed[@]:-}"; do
      if [[ "$(basename "$f")" == "${id}.sh" ]]; then
        found_path="$f"
        found_sha="$(sha_file "$f")"
        break
      fi
    done
    if [[ -z "$found_path" ]]; then
      missing_for_repo=$((missing_for_repo+1))
      (( fd )) || HOOK_DETAILS+=","; fd=0
      HOOK_DETAILS+=$(jq -nc --arg id "$id" '{id:$id, status:"missing"}')
    elif [[ "$found_sha" != "${CANON_SHA[$id]}" ]]; then
      stale_for_repo=$((stale_for_repo+1))
      (( fd )) || HOOK_DETAILS+=","; fd=0
      HOOK_DETAILS+=$(jq -nc --arg id "$id" --arg p "$found_path" --arg s "$found_sha" --arg c "${CANON_SHA[$id]}" \
        '{id:$id, status:"stale", path:$p, installed_sha:$s, canonical_sha:$c}')
    else
      conformant_count=$((conformant_count+1))
      (( fd )) || HOOK_DETAILS+=","; fd=0
      HOOK_DETAILS+=$(jq -nc --arg id "$id" --arg p "$found_path" '{id:$id, status:"conformant", path:$p}')
    fi
  done

  # rogue = installed hooks whose basename doesn't match any canonical id and not in pre-commit family
  for f in "${installed[@]:-}"; do
    base="$(basename "$f" .sh)"
    base_with_ext="$(basename "$f")"
    is_canon=0
    for id in "${CANON_IDS[@]}"; do
      [[ "$id" == "$base" ]] && { is_canon=1; break; }
    done
    if (( is_canon == 0 )); then
      # Allow obvious non-canonical-class hooks (consumer-local). Only count tool hooks (~/.claude/hooks),
      # not .git/hooks/* which are commonly project-local
      case "$f" in
        */.claude/hooks/*)
          # consumer-local tool hook → rogue against canonical surface unless it's a pre-commit family
          case "$base_with_ext" in
            pre-commit*|*-pre-commit.sh) : ;;  # pre-commit family ok
            *) rogue_for_repo=$((rogue_for_repo+1))
               (( fd )) || HOOK_DETAILS+=","; fd=0
               HOOK_DETAILS+=$(jq -nc --arg id "$base" --arg p "$f" '{id:$id, status:"rogue", path:$p}')
               ;;
          esac
          ;;
      esac
    fi
  done
  HOOK_DETAILS+="]"

  is_conformant=0
  if (( missing_for_repo == 0 && stale_for_repo == 0 )); then
    is_conformant=1
    CONFORMANT=$((CONFORMANT+1))
  fi
  TOTAL_ROGUE=$((TOTAL_ROGUE+rogue_for_repo))
  TOTAL_MISSING=$((TOTAL_MISSING+missing_for_repo))

  (( first_repo )) || REPO_ENTRIES+=","
  first_repo=0
  REPO_ENTRIES+=$(jq -nc \
    --arg name "$name" --arg path "$repo" \
    --argjson has_manifest $has_manifest --argjson conformant $is_conformant \
    --argjson missing $missing_for_repo --argjson stale $stale_for_repo \
    --argjson rogue $rogue_for_repo --argjson opt_out $opt_out_count \
    --argjson conformant_count $conformant_count \
    --argjson hooks "$HOOK_DETAILS" \
    '{name:$name, path:$path, has_manifest:($has_manifest==1), conformant:($conformant==1),
      counts:{conformant:$conformant_count, missing:$missing, stale:$stale, rogue:$rogue, opt_out:$opt_out},
      hooks:$hooks}')
done
REPO_ENTRIES+="]"

if (( DASHBOARD == 1 )); then
  printf '🔧 Hook hygiene: %d/%d repos | %d rogue | %d missing\n' \
    "$CONFORMANT" "$TOTAL_REPOS" "$TOTAL_ROGUE" "$TOTAL_MISSING"
  exit 0
fi

jq -n \
  --argjson conformant $CONFORMANT --argjson total $TOTAL_REPOS \
  --argjson rogue $TOTAL_ROGUE --argjson missing $TOTAL_MISSING \
  --argjson repos "$REPO_ENTRIES" \
  --arg canon_dir "$CANON_DIR" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{
    fleet_hook_hygiene: {
      schema_version: "skillos.hook_manifest.v1",
      ts: $ts,
      canonical_dir: $canon_dir,
      summary: {
        total_repos: $total,
        conformant_repos: $conformant,
        rogue_hooks_total: $rogue,
        missing_hooks_total: $missing
      },
      dashboard_line: ("🔧 Hook hygiene: " + ($conformant|tostring) + "/" + ($total|tostring) + " repos | " + ($rogue|tostring) + " rogue | " + ($missing|tostring) + " missing"),
      repos: $repos
    }
  }'
