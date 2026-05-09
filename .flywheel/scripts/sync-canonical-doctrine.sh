#!/usr/bin/env bash
# Sync generated canonical doctrine mirrors into repo-local doctrine copies.
set -euo pipefail

DEFAULT_SOURCE="/Users/josh/Developer/flywheel/AGENTS.md"
SOURCE="${SYNC_CANONICAL_SOURCE:-$DEFAULT_SOURCE}"
AGENTS_MD_GENERATOR="${SYNC_AGENTS_MD_GENERATOR:-/Users/josh/Developer/flywheel/.flywheel/scripts/agents-md-shard-extract.sh}"
CANONICAL_INDEX_TARGET="${SYNC_CANONICAL_INDEX_TARGET:-/Users/josh/Developer/flywheel/.flywheel/AGENTS-CANONICAL.md}"
TEMPLATE_INDEX_TARGET="${SYNC_CANONICAL_TEMPLATE_TARGET:-/Users/josh/Developer/flywheel/templates/flywheel-install/AGENTS.md}"
STORAGE_OVERRIDE_SCHEMA_SOURCE="${SYNC_STORAGE_OVERRIDE_SCHEMA_SOURCE:-/Users/josh/Developer/flywheel/.flywheel/validation-schema/v1/storage-override.schema.json}"
IDENTITY_DEFERRAL_SCHEMA_SOURCE="${SYNC_IDENTITY_DEFERRAL_SCHEMA_SOURCE:-/Users/josh/Developer/flywheel/.flywheel/validation-schema/v1/identity-registration-deferral.schema.json}"
BEAD_QUALITY_MINING_SOURCE="${SYNC_BEAD_QUALITY_MINING_SOURCE:-/Users/josh/Developer/flywheel/.flywheel/scripts/bead-quality-mining.sh}"
ORCH_VALIDATION_SKILL_SOURCE="${SYNC_ORCH_VALIDATION_SKILL_SOURCE:-/Users/josh/.claude/skills/orchestrator-validation-discipline/SKILL.md}"
DOCTRINE_DOCS_SOURCE_DIR="${SYNC_DOCTRINE_DOCS_SOURCE_DIR:-/Users/josh/Developer/flywheel/.flywheel/doctrine}"
RULES_SOURCE_DIR="${SYNC_RULES_SOURCE_DIR:-/Users/josh/Developer/flywheel/.flywheel/rules}"
SHARED_SCRIPT_SOURCE_DIR="${SYNC_SHARED_SCRIPT_SOURCE_DIR:-/Users/josh/Developer/flywheel/.flywheel/scripts}"
SHARED_SCRIPT_ALLOWLIST="${SYNC_SHARED_SCRIPT_ALLOWLIST:-agents-md-shard-extract.sh bead-quality-mining.sh cleanup-scratch.sh dispatch-and-verify.sh tmp-aggressive-prune.sh topology-tick-refresh.sh sync-canonical-doctrine.sh publishability-bar.sh zeststream-public-prepublish-hook.sh}"
LAUNCHD_TEMPLATE_SOURCE_DIR="${SYNC_LAUNCHD_TEMPLATE_SOURCE_DIR:-/Users/josh/Developer/flywheel/.flywheel/launchd}"
SECURITY_SETTINGS_DENY_SOURCE="${SYNC_SECURITY_SETTINGS_DENY_SOURCE:-/Users/josh/Developer/flywheel/.flywheel/security/v1/claude-settings-deny.json}"
LOOPS_DIR="${SYNC_CANONICAL_LOOPS_DIR:-$HOME/.flywheel/loops}"
SYNC_LEDGER="${SYNC_CANONICAL_LEDGER:-$HOME/.local/state/flywheel/doctrine-sync-ledger.jsonl}"
SYNC_TS="${SYNC_CANONICAL_NOW:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
ROOT_BLOCK_BEGIN="<!-- BEGIN-CANONICAL-FLYWHEEL-DOCTRINE -->"
ROOT_BLOCK_END="<!-- END-CANONICAL-FLYWHEEL-DOCTRINE -->"
ROOTS=()
MODE="check"
JSON_OUT=0
EXPLICIT_ROOTS=0

usage() {
  cat <<'EOF'
usage: sync-canonical-doctrine.sh [--dry-run|--apply] [--json] [--source PATH] [--root PATH ...]

Synchronizes doctrine surfaces for each flywheel-installed repo:
  1. .flywheel/rules/L*.md is the canonical L-rule source.
  2. AGENTS.md, .flywheel/AGENTS-CANONICAL.md, and
     templates/flywheel-install/AGENTS.md are generated thin indexes.
  3. ROOT AGENTS.md gets a replaceable canonical block between:
     <!-- BEGIN-CANONICAL-FLYWHEEL-DOCTRINE -->
     <!-- END-CANONICAL-FLYWHEEL-DOCTRINE -->
  4. .flywheel/validation-schema/v1/storage-override.schema.json is copied
     from the canonical source repo when present, with backup-before-write.
  5. .flywheel/validation-schema/v1/identity-registration-deferral.schema.json
     is copied from the canonical source repo when present, with backup-before-write.
  6. .flywheel/scripts/bead-quality-mining.sh is copied from the canonical
     source repo when present, with backup-before-write.
  7. .flywheel/doctrine/*.md is copied from the canonical source repo when
     present, with backup-before-write.
  8. Allowlisted .flywheel/scripts/*.sh files are copied from the canonical
     source repo when present, with backup-before-write and executable mode.
  9. .flywheel/launchd/*.plist templates are copied from the canonical source
     repo when present, with backup-before-write.
  10. .claude/settings.json receives the canonical managed security deny rules
     while preserving non-managed settings, with backup-before-write.

Existing root AGENTS.md content outside the block is preserved. The canonical
source repo root is treated as already synchronized to avoid self-embedding the
source AGENTS.md inside itself. The global orchestrator-validation-discipline
skill is reported by hash so skill drift is visible in the sync receipt.

Exit codes:
  0  all targets in sync, or apply completed successfully
  1  drift detected in dry-run/check mode
  2  usage/configuration error

Environment:
  SYNC_CANONICAL_SOURCE=/path/to/AGENTS.md
  SYNC_AGENTS_MD_GENERATOR=/path/to/agents-md-shard-extract.sh
  SYNC_GENERATED_MIRRORS_DISABLE=1
  SYNC_CANONICAL_INDEX_TARGET=/path/to/.flywheel/AGENTS-CANONICAL.md
  SYNC_CANONICAL_TEMPLATE_TARGET=/path/to/templates/flywheel-install/AGENTS.md
  SYNC_STORAGE_OVERRIDE_SCHEMA_SOURCE=/path/to/storage-override.schema.json
  SYNC_IDENTITY_DEFERRAL_SCHEMA_SOURCE=/path/to/identity-registration-deferral.schema.json
  SYNC_BEAD_QUALITY_MINING_SOURCE=/path/to/bead-quality-mining.sh
  SYNC_DOCTRINE_DOCS_SOURCE_DIR=/path/to/.flywheel/doctrine
  SYNC_RULES_SOURCE_DIR=/path/to/.flywheel/rules
  SYNC_SHARED_SCRIPT_SOURCE_DIR=/path/to/.flywheel/scripts
  SYNC_SHARED_SCRIPT_ALLOWLIST="bead-quality-mining.sh dispatch-and-verify.sh"
  SYNC_LAUNCHD_TEMPLATE_SOURCE_DIR=/path/to/.flywheel/launchd
  SYNC_SECURITY_SETTINGS_DENY_SOURCE=/path/to/claude-settings-deny.json
  SYNC_ORCH_VALIDATION_SKILL_SOURCE=/path/to/orchestrator-validation-discipline/SKILL.md
  SYNC_CANONICAL_ROOTS="/path/a:/path/b"
  SYNC_CANONICAL_LOOPS_DIR=/path/to/loops-json-dir
  SYNC_CANONICAL_LEDGER=/path/to/doctrine-sync-ledger.jsonl
  SYNC_CANONICAL_LEDGER_DISABLE=1
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|--check)
      MODE="check"
      shift
      ;;
    --apply)
      MODE="apply"
      shift
      ;;
    --json)
      JSON_OUT=1
      shift
      ;;
    --source)
      [[ -n "${2:-}" ]] || { echo "ERR: --source requires PATH" >&2; exit 2; }
      SOURCE="$2"
      shift 2
      ;;
    --root)
      [[ -n "${2:-}" ]] || { echo "ERR: --root requires PATH" >&2; exit 2; }
      ROOTS+=("$2")
      EXPLICIT_ROOTS=1
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERR: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

expand_path() {
  case "$1" in
    "~") printf '%s\n' "$HOME" ;;
    "~/"*) printf '%s/%s\n' "$HOME" "${1#~/}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

canonicalize_file() {
  local file="$1" dir base
  file="$(expand_path "$file")"
  dir="$(dirname "$file")"
  base="$(basename "$file")"
  (cd "$dir" 2>/dev/null && printf '%s/%s\n' "$(pwd -P)" "$base") || printf '%s\n' "$file"
}

sha256_file() {
  local file="$1"
  [[ -f "$file" ]] || { printf ''; return 0; }
  shasum -a 256 "$file" | awk '{print $1}'
}

canonicalize_dir() {
  local dir="$1"
  dir="$(expand_path "$dir")"
  (cd "$dir" 2>/dev/null && pwd -P) || printf '%s\n' "$dir"
}

backup_file() {
  local file="$1" ts
  [[ -f "$file" ]] || return 0
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  cp "$file" "${file}.bak.${ts}"
}

backup_file_with_path() {
  local file="$1" ts backup
  [[ -f "$file" ]] || return 0
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  backup="${file}.bak.${ts}"
  cp "$file" "$backup"
  printf '%s\n' "$backup"
}

extract_l_rules() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  sed -nE \
    -e 's/^## (L[0-9]+)[[:space:]].*/\1/p' \
    -e 's/^\|[[:space:]]*[0-9]+[[:space:]]*\|[[:space:]]*(L[0-9]+)[[:space:]]+—.*/\1/p' \
    "$file" | sort -u
}

extract_root_block() {
  local file="$1" out="$2"
  [[ -f "$file" ]] || return 1
  awk -v begin="$ROOT_BLOCK_BEGIN" -v end="$ROOT_BLOCK_END" '
    $0 == begin { in_block=1; found=1; next }
    $0 == end { in_block=0; next }
    in_block { print }
    END { if (!found) exit 1 }
  ' "$file" >"$out"
}

render_root_agents_with_block() {
  local source="$1" target="$2" out="$3" input
  input="$target"
  [[ -f "$input" ]] || input="/dev/null"
  awk -v begin="$ROOT_BLOCK_BEGIN" -v end="$ROOT_BLOCK_END" -v source="$source" '
    function emit_source() {
      while ((getline line < source) > 0) print line
      close(source)
    }
    $0 == begin {
      print begin
      emit_source()
      print end
      in_block=1
      inserted=1
      next
    }
    $0 == end {
      in_block=0
      next
    }
    in_block { next }
    { print }
    END {
      if (!inserted) {
        if (NR > 0) print ""
        print begin
        emit_source()
        print end
      }
    }
  ' "$input" >"$out"
}

json_string_array_from_file() {
  local file="$1"
  if [[ ! -s "$file" ]]; then
    printf '[]'
    return 0
  fi
  jq -R . "$file" | jq -s -c .
}

copy_managed_file() {
  local repo="$1" source_file="$2" target_file="$3" action="$4" executable="${5:-0}"
  local source_hash target_hash tmp new_hash
  [[ -f "$source_file" ]] || return 0
  MANAGED_FILE_TARGET_COUNT=$((MANAGED_FILE_TARGET_COUNT + 1))
  source_hash="$(sha256_file "$source_file")"
  target_hash="$(sha256_file "$target_file")"
  if [[ "$target_hash" == "$source_hash" ]]; then
    jq -cn --arg repo "$repo" --arg source "$source_file" --arg target "$target_file" --arg action "$action" --arg hash "$target_hash" \
      '{repo:$repo,source:$source,target:$target,action:$action,status:"in_sync",hash:$hash}' >>"$MANAGED_DETAILS_FILE"
    return 0
  fi

  MANAGED_FILE_DRIFTED_COUNT=$((MANAGED_FILE_DRIFTED_COUNT + 1))
  if [[ "$MODE" != "apply" ]]; then
    jq -cn --arg repo "$repo" --arg source "$source_file" --arg target "$target_file" --arg action "$action" --arg source_hash "$source_hash" --arg target_hash "$target_hash" \
      '{repo:$repo,source:$source,target:$target,action:$action,status:"drifted",source_hash:$source_hash,target_hash:$target_hash}' >>"$MANAGED_DETAILS_FILE"
    return 0
  fi

  mkdir -p "$(dirname "$target_file")"
  tmp="${target_file}.tmp.$$"
  if cp "$source_file" "$tmp"; then
    backup_file "$target_file"
    if mv "$tmp" "$target_file"; then
      if [[ "$executable" == "1" ]]; then
        chmod +x "$target_file" 2>/dev/null || true
      fi
      new_hash="$(sha256_file "$target_file")"
      if [[ "$new_hash" == "$source_hash" ]]; then
        MANAGED_FILE_SYNCED_COUNT=$((MANAGED_FILE_SYNCED_COUNT + 1))
        jq -cn --arg repo "$repo" --arg source "$source_file" --arg target "$target_file" --arg action "$action" --arg prior_hash "$target_hash" --arg new_hash "$new_hash" \
          '{repo:$repo,source:$source,target:$target,action:$action,status:"synced",prior_hash:$prior_hash,new_hash:$new_hash}' >>"$MANAGED_DETAILS_FILE"
        jq -cn --arg path "$target_file" --arg action "$action" '{path:$path,action:$action}' >>"$WRITES_FILE"
      else
        ERROR_COUNT=$((ERROR_COUNT + 1))
        jq -cn --arg repo "$repo" --arg source "$source_file" --arg target "$target_file" --arg action "$action" --arg code "managed_file_hash_mismatch" \
          '{repo:$repo,source:$source,target:$target,action:$action,status:"error",code:$code,message:"managed file hash did not match source after copy"}' >>"$ERRORS_FILE"
      fi
    else
      rm -f "$tmp" 2>/dev/null || true
      ERROR_COUNT=$((ERROR_COUNT + 1))
      jq -cn --arg repo "$repo" --arg source "$source_file" --arg target "$target_file" --arg action "$action" --arg code "managed_file_move_failed" \
        '{repo:$repo,source:$source,target:$target,action:$action,status:"error",code:$code,message:"failed to move managed file into place"}' >>"$ERRORS_FILE"
    fi
  else
    rm -f "$tmp" 2>/dev/null || true
    ERROR_COUNT=$((ERROR_COUNT + 1))
    jq -cn --arg repo "$repo" --arg source "$source_file" --arg target "$target_file" --arg action "$action" --arg code "managed_file_copy_failed" \
      '{repo:$repo,source:$source,target:$target,action:$action,status:"error",code:$code,message:"failed to copy managed file"}' >>"$ERRORS_FILE"
  fi
}

render_security_settings() {
  local source_file="$1" target_file="$2" out_file="$3"
  python3 - "$source_file" "$target_file" "$out_file" <<'PY'
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path


source_path = Path(sys.argv[1])
target_path = Path(sys.argv[2])
out_path = Path(sys.argv[3])

source = json.loads(source_path.read_text())
existing: dict[str, object] = {}
if target_path.exists():
    loaded = json.loads(target_path.read_text())
    if not isinstance(loaded, dict):
        raise TypeError("settings_json_not_object")
    existing = loaded

permissions = existing.get("permissions")
if not isinstance(permissions, dict):
    permissions = {}

source_permissions = source.get("permissions")
if not isinstance(source_permissions, dict):
    raise TypeError("source_permissions_not_object")

source_deny = source_permissions.get("deny")
if not isinstance(source_deny, list):
    raise TypeError("source_permissions_deny_not_array")

existing_deny = permissions.get("deny")
if not isinstance(existing_deny, list):
    existing_deny = []

deny: list[str] = []
seen: set[str] = set()
for value in [*existing_deny, *source_deny]:
    if isinstance(value, str) and value not in seen:
        deny.append(value)
        seen.add(value)

permissions["deny"] = deny
existing["permissions"] = permissions

metadata = existing.get("flywheel_security")
if not isinstance(metadata, dict):
    metadata = {}
metadata.update(
    {
        "schema_version": "security-settings-sync/v1",
        "managed_block_id": source.get("managed_block_id", "agent-security-deny/v1"),
        "control_schema_version": source.get(
            "control_schema_version", "agent-security-control/v1"
        ),
        "source": ".flywheel/security/v1/claude-settings-deny.json",
        "source_sha256": hashlib.sha256(source_path.read_bytes()).hexdigest(),
        "sync_surface": "sync-canonical-doctrine.sh",
    }
)
existing["flywheel_security"] = metadata

out_path.write_text(json.dumps(existing, indent=2, sort_keys=True) + "\n")
PY
}

sync_security_settings_for_repo() {
  local repo="$1" target_file rendered_tmp source_hash target_hash new_hash backup_path rc blocked_by
  target_file="$repo/.claude/settings.json"
  SECURITY_SETTINGS_TARGET_COUNT=$((SECURITY_SETTINGS_TARGET_COUNT + 1))

  if [[ ! -f "$SECURITY_SETTINGS_DENY_SOURCE" ]]; then
    SECURITY_SETTINGS_BLOCKED_COUNT=$((SECURITY_SETTINGS_BLOCKED_COUNT + 1))
    jq -cn --arg repo "$repo" --arg target "$target_file" --arg blocked_by "security_settings_deny_source_missing" \
      '{repo:$repo,target:$target,status:"blocked",blocked_by:$blocked_by}' >>"$SECURITY_SETTINGS_DETAILS_FILE"
    return 0
  fi

  rendered_tmp="$(mktemp "${TMPDIR:-/tmp}/sync-security-settings.XXXXXX")"
  set +e
  render_security_settings "$SECURITY_SETTINGS_DENY_SOURCE" "$target_file" "$rendered_tmp" 2>/dev/null
  rc=$?
  set -e
  if [[ "$rc" -ne 0 ]]; then
    rm -f "$rendered_tmp" 2>/dev/null || true
    blocked_by="settings_json_render_failed"
    if [[ -f "$target_file" ]] && ! jq -e 'type == "object"' "$target_file" >/dev/null 2>&1; then
      blocked_by="settings_json_invalid"
    fi
    SECURITY_SETTINGS_BLOCKED_COUNT=$((SECURITY_SETTINGS_BLOCKED_COUNT + 1))
    jq -cn --arg repo "$repo" --arg target "$target_file" --arg blocked_by "$blocked_by" \
      '{repo:$repo,target:$target,status:"blocked",blocked_by:$blocked_by}' >>"$SECURITY_SETTINGS_DETAILS_FILE"
    return 0
  fi

  source_hash="$(sha256_file "$rendered_tmp")"
  target_hash="$(sha256_file "$target_file")"
  if [[ "$target_hash" == "$source_hash" ]]; then
    jq -cn --arg repo "$repo" --arg target "$target_file" --arg hash "$target_hash" \
      '{repo:$repo,target:$target,status:"in_sync",hash:$hash,blocked_by:null}' >>"$SECURITY_SETTINGS_DETAILS_FILE"
    rm -f "$rendered_tmp"
    return 0
  fi

  SECURITY_SETTINGS_DRIFTED_COUNT=$((SECURITY_SETTINGS_DRIFTED_COUNT + 1))
  if [[ "$MODE" != "apply" ]]; then
    jq -cn --arg repo "$repo" --arg target "$target_file" --arg source_hash "$source_hash" --arg target_hash "$target_hash" \
      '{repo:$repo,target:$target,status:"drifted",source_hash:$source_hash,target_hash:$target_hash,blocked_by:null}' >>"$SECURITY_SETTINGS_DETAILS_FILE"
    rm -f "$rendered_tmp"
    return 0
  fi

  mkdir -p "$(dirname "$target_file")"
  backup_path=""
  if [[ -f "$target_file" ]]; then
    backup_path="$(backup_file_with_path "$target_file")"
  fi
  if mv "$rendered_tmp" "$target_file"; then
    new_hash="$(sha256_file "$target_file")"
    if [[ "$new_hash" == "$source_hash" ]]; then
      SECURITY_SETTINGS_SYNCED_COUNT=$((SECURITY_SETTINGS_SYNCED_COUNT + 1))
      jq -cn --arg repo "$repo" --arg target "$target_file" --arg prior_hash "$target_hash" --arg new_hash "$new_hash" --arg backup_path "$backup_path" \
        '{repo:$repo,target:$target,status:"synced",prior_hash:$prior_hash,new_hash:$new_hash,backup_path:($backup_path // empty),blocked_by:null}' >>"$SECURITY_SETTINGS_DETAILS_FILE"
      jq -cn --arg path "$target_file" --arg action "merge_security_settings_deny" '{path:$path,action:$action}' >>"$WRITES_FILE"
    else
      ERROR_COUNT=$((ERROR_COUNT + 1))
      jq -cn --arg repo "$repo" --arg target "$target_file" --arg code "security_settings_hash_mismatch" \
        '{repo:$repo,target:$target,status:"error",code:$code,message:"security settings hash did not match rendered source after write"}' >>"$ERRORS_FILE"
    fi
  else
    rm -f "$rendered_tmp" 2>/dev/null || true
    ERROR_COUNT=$((ERROR_COUNT + 1))
    jq -cn --arg repo "$repo" --arg target "$target_file" --arg code "security_settings_move_failed" \
      '{repo:$repo,target:$target,status:"error",code:$code,message:"failed to move security settings into place"}' >>"$ERRORS_FILE"
  fi
}

collect_targets() {
  local target_tmp="$1" root repo_path
  : >"$target_tmp"

  if [[ -n "${SYNC_CANONICAL_ROOTS:-}" && "${#ROOTS[@]}" -eq 0 ]]; then
    IFS=':' read -r -a ROOTS <<<"$SYNC_CANONICAL_ROOTS"
    EXPLICIT_ROOTS=1
  fi
  if [[ "${#ROOTS[@]}" -eq 0 ]]; then
    ROOTS=("/Users/josh/Developer")
  fi

  for root in "${ROOTS[@]}"; do
    root="$(expand_path "$root")"
    [[ -d "$root" ]] || continue
    find "$root" -maxdepth 4 -name 'AGENTS-CANONICAL.md' -path '*/.flywheel/*' -type f -print 2>/dev/null >>"$target_tmp"
  done

  if [[ "$EXPLICIT_ROOTS" -eq 0 && -d "$LOOPS_DIR" ]]; then
    while IFS= read -r loop_json; do
      [[ -f "$loop_json" ]] || continue
      repo_path="$(jq -r '.repo_path // .repo // .project_path // empty' "$loop_json" 2>/dev/null || true)"
      [[ -n "$repo_path" && "$repo_path" != "null" ]] || continue
      repo_path="$(expand_path "$repo_path")"
      [[ -f "$repo_path/.flywheel/AGENTS-CANONICAL.md" ]] || continue
      printf '%s/.flywheel/AGENTS-CANONICAL.md\n' "$repo_path" >>"$target_tmp"
    done < <(find "$LOOPS_DIR" -maxdepth 1 -name '*.json' -type f -print 2>/dev/null | sort)
  fi

  sort -u "$target_tmp" -o "$target_tmp"
}

SOURCE="$(canonicalize_file "$SOURCE")"
DEFAULT_SOURCE_CANONICAL="$(canonicalize_file "$DEFAULT_SOURCE")"
AGENTS_MD_GENERATOR="$(canonicalize_file "$AGENTS_MD_GENERATOR")"
CANONICAL_INDEX_TARGET="$(canonicalize_file "$CANONICAL_INDEX_TARGET")"
TEMPLATE_INDEX_TARGET="$(canonicalize_file "$TEMPLATE_INDEX_TARGET")"
STORAGE_OVERRIDE_SCHEMA_SOURCE="$(canonicalize_file "$STORAGE_OVERRIDE_SCHEMA_SOURCE")"
IDENTITY_DEFERRAL_SCHEMA_SOURCE="$(canonicalize_file "$IDENTITY_DEFERRAL_SCHEMA_SOURCE")"
BEAD_QUALITY_MINING_SOURCE="$(canonicalize_file "$BEAD_QUALITY_MINING_SOURCE")"
ORCH_VALIDATION_SKILL_SOURCE="$(canonicalize_file "$ORCH_VALIDATION_SKILL_SOURCE")"
SECURITY_SETTINGS_DENY_SOURCE="$(canonicalize_file "$SECURITY_SETTINGS_DENY_SOURCE")"
RULES_SOURCE_DIR="$(canonicalize_dir "$RULES_SOURCE_DIR")"
if [[ "${SYNC_GENERATED_MIRRORS_DISABLE:-0}" != "1" && "$SOURCE" == "$DEFAULT_SOURCE_CANONICAL" && -x "$AGENTS_MD_GENERATOR" && -d "$RULES_SOURCE_DIR" ]]; then
  "$AGENTS_MD_GENERATOR" \
    --source "$SOURCE" \
    --canonical "$CANONICAL_INDEX_TARGET" \
    --root "$SOURCE" \
    --template "$TEMPLATE_INDEX_TARGET" \
    --rules-dir "$RULES_SOURCE_DIR" \
    --apply \
    --json >/dev/null
fi
if [[ ! -f "$SOURCE" ]]; then
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg source "$SOURCE" '{mode:"error",status:"error",source:$source,errors:[{code:"source_missing",message:"canonical source is missing",path:$source}]}'
  else
    echo "ERR: canonical source is missing: $SOURCE" >&2
  fi
  exit 2
fi

TARGETS_FILE="$(mktemp "${TMPDIR:-/tmp}/sync-canonical-targets.XXXXXX")"
REPOS_FILE="$(mktemp "${TMPDIR:-/tmp}/sync-canonical-repos.XXXXXX")"
DETAILS_FILE="$(mktemp "${TMPDIR:-/tmp}/sync-canonical-details.XXXXXX")"
ROOT_DETAILS_FILE="$(mktemp "${TMPDIR:-/tmp}/sync-canonical-root-details.XXXXXX")"
WRITES_FILE="$(mktemp "${TMPDIR:-/tmp}/sync-canonical-writes.XXXXXX")"
ERRORS_FILE="$(mktemp "${TMPDIR:-/tmp}/sync-canonical-errors.XXXXXX")"
MANAGED_DETAILS_FILE="$(mktemp "${TMPDIR:-/tmp}/sync-canonical-managed-details.XXXXXX")"
SECURITY_SETTINGS_DETAILS_FILE="$(mktemp "${TMPDIR:-/tmp}/sync-canonical-security-settings.XXXXXX")"
SOURCE_RULES_FILE="$(mktemp "${TMPDIR:-/tmp}/sync-canonical-source-rules.XXXXXX")"
trap 'rm -f "$TARGETS_FILE" "$REPOS_FILE" "$DETAILS_FILE" "$ROOT_DETAILS_FILE" "$WRITES_FILE" "$ERRORS_FILE" "$MANAGED_DETAILS_FILE" "$SECURITY_SETTINGS_DETAILS_FILE" "$SOURCE_RULES_FILE"' EXIT

collect_targets "$TARGETS_FILE"
: >"$DETAILS_FILE"
: >"$ROOT_DETAILS_FILE"
: >"$WRITES_FILE"
: >"$ERRORS_FILE"
: >"$MANAGED_DETAILS_FILE"
: >"$SECURITY_SETTINGS_DETAILS_FILE"
: >"$REPOS_FILE"
extract_l_rules "$SOURCE" >"$SOURCE_RULES_FILE"

SOURCE_HASH="$(sha256_file "$SOURCE")"
SOURCE_REPO="$(canonicalize_dir "$(dirname "$SOURCE")")"
if [[ -z "${SYNC_DOCTRINE_DOCS_SOURCE_DIR:-}" ]]; then
DOCTRINE_DOCS_SOURCE_DIR="$SOURCE_REPO/.flywheel/doctrine"
fi
if [[ -z "${SYNC_RULES_SOURCE_DIR:-}" ]]; then
  RULES_SOURCE_DIR="$SOURCE_REPO/.flywheel/rules"
fi
if [[ -z "${SYNC_SHARED_SCRIPT_SOURCE_DIR:-}" ]]; then
  SHARED_SCRIPT_SOURCE_DIR="$SOURCE_REPO/.flywheel/scripts"
fi
if [[ -z "${SYNC_LAUNCHD_TEMPLATE_SOURCE_DIR:-}" ]]; then
  LAUNCHD_TEMPLATE_SOURCE_DIR="$SOURCE_REPO/.flywheel/launchd"
fi
TARGET_COUNT=0
CANONICAL_DRIFTED_COUNT=0
CANONICAL_SYNCED_COUNT=0
ROOT_TARGET_COUNT=0
ROOT_DRIFTED_COUNT=0
ROOT_SYNCED_COUNT=0
SCHEMA_TARGET_COUNT=0
SCHEMA_DRIFTED_COUNT=0
SCHEMA_SYNCED_COUNT=0
IDENTITY_DEFERRAL_SCHEMA_TARGET_COUNT=0
IDENTITY_DEFERRAL_SCHEMA_DRIFTED_COUNT=0
IDENTITY_DEFERRAL_SCHEMA_SYNCED_COUNT=0
BEAD_MINING_TARGET_COUNT=0
BEAD_MINING_DRIFTED_COUNT=0
BEAD_MINING_SYNCED_COUNT=0
MANAGED_FILE_TARGET_COUNT=0
MANAGED_FILE_DRIFTED_COUNT=0
MANAGED_FILE_SYNCED_COUNT=0
SECURITY_SETTINGS_TARGET_COUNT=0
SECURITY_SETTINGS_DRIFTED_COUNT=0
SECURITY_SETTINGS_SYNCED_COUNT=0
SECURITY_SETTINGS_BLOCKED_COUNT=0
ERROR_COUNT=0
SCHEMA_SOURCE_HASH="$(sha256_file "$STORAGE_OVERRIDE_SCHEMA_SOURCE")"
IDENTITY_DEFERRAL_SCHEMA_HASH="$(sha256_file "$IDENTITY_DEFERRAL_SCHEMA_SOURCE")"
BEAD_QUALITY_MINING_HASH="$(sha256_file "$BEAD_QUALITY_MINING_SOURCE")"
ORCH_VALIDATION_SKILL_HASH="$(sha256_file "$ORCH_VALIDATION_SKILL_SOURCE")"
SECURITY_SETTINGS_DENY_HASH="$(sha256_file "$SECURITY_SETTINGS_DENY_SOURCE")"

while IFS= read -r target; do
  [[ -n "$target" ]] || continue
  TARGET_COUNT=$((TARGET_COUNT + 1))
  target_hash="$(sha256_file "$target")"
  repo="$(dirname "$(dirname "$target")")"
  repo="$(canonicalize_dir "$repo")"
  printf '%s\n' "$repo" >>"$REPOS_FILE"

  if [[ "$target_hash" == "$SOURCE_HASH" ]]; then
    jq -cn --arg repo "$repo" --arg target "$target" --arg hash "$target_hash" \
      '{repo:$repo,target:$target,status:"in_sync",hash:$hash}' >>"$DETAILS_FILE"
    continue
  fi

  CANONICAL_DRIFTED_COUNT=$((CANONICAL_DRIFTED_COUNT + 1))
  if [[ "$MODE" == "apply" ]]; then
    tmp="${target}.tmp.$$"
    if cp "$SOURCE" "$tmp"; then
      backup_file "$target"
      if mv "$tmp" "$target"; then
      new_hash="$(sha256_file "$target")"
      if [[ "$new_hash" == "$SOURCE_HASH" ]]; then
        CANONICAL_SYNCED_COUNT=$((CANONICAL_SYNCED_COUNT + 1))
        jq -cn --arg repo "$repo" --arg target "$target" --arg prior_hash "$target_hash" --arg new_hash "$new_hash" \
          '{repo:$repo,target:$target,status:"synced",prior_hash:$prior_hash,new_hash:$new_hash}' >>"$DETAILS_FILE"
        jq -cn --arg path "$target" --arg action "copy_canonical" '{path:$path,action:$action}' >>"$WRITES_FILE"
      else
        ERROR_COUNT=$((ERROR_COUNT + 1))
        jq -cn --arg repo "$repo" --arg target "$target" --arg code "post_copy_hash_mismatch" \
          '{repo:$repo,target:$target,status:"error",code:$code,message:"target hash did not match source after copy"}' >>"$ERRORS_FILE"
      fi
      else
        rm -f "$tmp" 2>/dev/null || true
        ERROR_COUNT=$((ERROR_COUNT + 1))
        jq -cn --arg repo "$repo" --arg target "$target" --arg code "copy_failed" \
          '{repo:$repo,target:$target,status:"error",code:$code,message:"failed to move canonical source to target"}' >>"$ERRORS_FILE"
      fi
    else
      rm -f "$tmp" 2>/dev/null || true
      ERROR_COUNT=$((ERROR_COUNT + 1))
      jq -cn --arg repo "$repo" --arg target "$target" --arg code "copy_failed" \
        '{repo:$repo,target:$target,status:"error",code:$code,message:"failed to copy canonical source to target"}' >>"$ERRORS_FILE"
    fi
  else
    jq -cn --arg repo "$repo" --arg target "$target" --arg hash "$target_hash" \
      '{repo:$repo,target:$target,status:"drifted",hash:$hash}' >>"$DETAILS_FILE"
  fi
done <"$TARGETS_FILE"
sort -u "$REPOS_FILE" -o "$REPOS_FILE"

while IFS= read -r repo; do
  [[ -n "$repo" ]] || continue
  ROOT_TARGET_COUNT=$((ROOT_TARGET_COUNT + 1))
  root_agents="$repo/AGENTS.md"

  if [[ "$repo" == "$SOURCE_REPO" ]]; then
    jq -cn --arg repo "$repo" --arg target "$root_agents" --arg source "$SOURCE" \
      '{repo:$repo,target:$target,status:"source_root",drift:false,block_present:false,source:$source,missing_rules:[],reason:"canonical source repo root is the source AGENTS.md"}' >>"$ROOT_DETAILS_FILE"
    continue
  fi

  block_tmp="$(mktemp "${TMPDIR:-/tmp}/sync-canonical-root-block.XXXXXX")"
  target_rules_tmp="$(mktemp "${TMPDIR:-/tmp}/sync-canonical-target-rules.XXXXXX")"
  missing_rules_tmp="$(mktemp "${TMPDIR:-/tmp}/sync-canonical-missing-rules.XXXXXX")"
  rendered_tmp="$(mktemp "${TMPDIR:-/tmp}/sync-canonical-root-render.XXXXXX")"
  block_present=true
  if ! extract_root_block "$root_agents" "$block_tmp"; then
    block_present=false
    : >"$block_tmp"
  fi
  extract_l_rules "$block_tmp" >"$target_rules_tmp"
  comm -23 "$SOURCE_RULES_FILE" "$target_rules_tmp" >"$missing_rules_tmp" || true
  missing_rules="$(json_string_array_from_file "$missing_rules_tmp")"
  block_hash="$(sha256_file "$block_tmp")"

  if [[ "$block_present" == true && "$block_hash" == "$SOURCE_HASH" ]]; then
    jq -cn --arg repo "$repo" --arg target "$root_agents" --arg hash "$block_hash" --argjson missing_rules "$missing_rules" \
      '{repo:$repo,target:$target,status:"in_sync",drift:false,block_present:true,block_hash:$hash,missing_rules:$missing_rules}' >>"$ROOT_DETAILS_FILE"
    rm -f "$block_tmp" "$target_rules_tmp" "$missing_rules_tmp" "$rendered_tmp"
    continue
  fi

  ROOT_DRIFTED_COUNT=$((ROOT_DRIFTED_COUNT + 1))
  if [[ "$MODE" == "apply" ]]; then
    if render_root_agents_with_block "$SOURCE" "$root_agents" "$rendered_tmp"; then
      backup_file "$root_agents"
      if mv "$rendered_tmp" "$root_agents"; then
        new_block_tmp="$(mktemp "${TMPDIR:-/tmp}/sync-canonical-new-root-block.XXXXXX")"
        if extract_root_block "$root_agents" "$new_block_tmp" && [[ "$(sha256_file "$new_block_tmp")" == "$SOURCE_HASH" ]]; then
          ROOT_SYNCED_COUNT=$((ROOT_SYNCED_COUNT + 1))
          jq -cn --arg repo "$repo" --arg target "$root_agents" --arg prior_hash "$block_hash" --arg new_hash "$SOURCE_HASH" --argjson missing_rules "$missing_rules" \
            '{repo:$repo,target:$target,status:"synced",drift:false,block_present:true,prior_block_hash:$prior_hash,new_block_hash:$new_hash,prior_missing_rules:$missing_rules}' >>"$ROOT_DETAILS_FILE"
          jq -cn --arg path "$root_agents" --arg action "replace_root_agents_canonical_block" '{path:$path,action:$action}' >>"$WRITES_FILE"
        else
          ERROR_COUNT=$((ERROR_COUNT + 1))
          jq -cn --arg repo "$repo" --arg target "$root_agents" --arg code "root_block_post_write_mismatch" \
            '{repo:$repo,target:$target,status:"error",code:$code,message:"root AGENTS.md canonical block did not match source after write"}' >>"$ERRORS_FILE"
        fi
        rm -f "$new_block_tmp"
      else
        rm -f "$rendered_tmp" 2>/dev/null || true
        ERROR_COUNT=$((ERROR_COUNT + 1))
        jq -cn --arg repo "$repo" --arg target "$root_agents" --arg code "root_block_move_failed" \
          '{repo:$repo,target:$target,status:"error",code:$code,message:"failed to replace root AGENTS.md canonical block"}' >>"$ERRORS_FILE"
      fi
    else
      rm -f "$rendered_tmp" 2>/dev/null || true
      ERROR_COUNT=$((ERROR_COUNT + 1))
      jq -cn --arg repo "$repo" --arg target "$root_agents" --arg code "root_block_render_failed" \
        '{repo:$repo,target:$target,status:"error",code:$code,message:"failed to render root AGENTS.md canonical block"}' >>"$ERRORS_FILE"
    fi
  else
    jq -cn --arg repo "$repo" --arg target "$root_agents" --arg hash "$block_hash" --argjson block_present "$block_present" --argjson missing_rules "$missing_rules" \
      '{repo:$repo,target:$target,status:"drifted",drift:true,block_present:$block_present,block_hash:$hash,missing_rules:$missing_rules}' >>"$ROOT_DETAILS_FILE"
  fi
  rm -f "$block_tmp" "$target_rules_tmp" "$missing_rules_tmp" "$rendered_tmp"
done <"$REPOS_FILE"

if [[ -f "$STORAGE_OVERRIDE_SCHEMA_SOURCE" ]]; then
  while IFS= read -r repo; do
    [[ -n "$repo" ]] || continue
    SCHEMA_TARGET_COUNT=$((SCHEMA_TARGET_COUNT + 1))
    schema_target="$repo/.flywheel/validation-schema/v1/storage-override.schema.json"
    schema_hash="$(sha256_file "$schema_target")"
    if [[ "$schema_hash" == "$SCHEMA_SOURCE_HASH" ]]; then
      continue
    fi
    SCHEMA_DRIFTED_COUNT=$((SCHEMA_DRIFTED_COUNT + 1))
    if [[ "$MODE" == "apply" ]]; then
      mkdir -p "$(dirname "$schema_target")"
      tmp="${schema_target}.tmp.$$"
      if cp "$STORAGE_OVERRIDE_SCHEMA_SOURCE" "$tmp"; then
        backup_file "$schema_target"
        if mv "$tmp" "$schema_target"; then
          new_hash="$(sha256_file "$schema_target")"
          if [[ "$new_hash" == "$SCHEMA_SOURCE_HASH" ]]; then
            SCHEMA_SYNCED_COUNT=$((SCHEMA_SYNCED_COUNT + 1))
            jq -cn --arg path "$schema_target" --arg action "copy_storage_override_schema" '{path:$path,action:$action}' >>"$WRITES_FILE"
          else
            ERROR_COUNT=$((ERROR_COUNT + 1))
            jq -cn --arg repo "$repo" --arg target "$schema_target" --arg code "storage_override_schema_hash_mismatch" \
              '{repo:$repo,target:$target,status:"error",code:$code,message:"storage override schema hash did not match after copy"}' >>"$ERRORS_FILE"
          fi
        else
          rm -f "$tmp" 2>/dev/null || true
          ERROR_COUNT=$((ERROR_COUNT + 1))
          jq -cn --arg repo "$repo" --arg target "$schema_target" --arg code "storage_override_schema_move_failed" \
            '{repo:$repo,target:$target,status:"error",code:$code,message:"failed to move storage override schema into place"}' >>"$ERRORS_FILE"
        fi
      else
        rm -f "$tmp" 2>/dev/null || true
        ERROR_COUNT=$((ERROR_COUNT + 1))
        jq -cn --arg repo "$repo" --arg target "$schema_target" --arg code "storage_override_schema_copy_failed" \
          '{repo:$repo,target:$target,status:"error",code:$code,message:"failed to copy storage override schema"}' >>"$ERRORS_FILE"
      fi
    fi
  done <"$REPOS_FILE"
fi

if [[ -f "$BEAD_QUALITY_MINING_SOURCE" ]]; then
  while IFS= read -r repo; do
    [[ -n "$repo" ]] || continue
    BEAD_MINING_TARGET_COUNT=$((BEAD_MINING_TARGET_COUNT + 1))
    mining_target="$repo/.flywheel/scripts/bead-quality-mining.sh"
    mining_hash="$(sha256_file "$mining_target")"
    if [[ "$mining_hash" == "$BEAD_QUALITY_MINING_HASH" ]]; then
      continue
    fi
    BEAD_MINING_DRIFTED_COUNT=$((BEAD_MINING_DRIFTED_COUNT + 1))
    if [[ "$MODE" == "apply" ]]; then
      mkdir -p "$(dirname "$mining_target")"
      tmp="${mining_target}.tmp.$$"
      if cp "$BEAD_QUALITY_MINING_SOURCE" "$tmp"; then
        backup_file "$mining_target"
        if mv "$tmp" "$mining_target"; then
          chmod +x "$mining_target" 2>/dev/null || true
          new_hash="$(sha256_file "$mining_target")"
          if [[ "$new_hash" == "$BEAD_QUALITY_MINING_HASH" ]]; then
            BEAD_MINING_SYNCED_COUNT=$((BEAD_MINING_SYNCED_COUNT + 1))
            jq -cn --arg path "$mining_target" --arg action "copy_bead_quality_mining_probe" '{path:$path,action:$action}' >>"$WRITES_FILE"
          else
            ERROR_COUNT=$((ERROR_COUNT + 1))
            jq -cn --arg repo "$repo" --arg target "$mining_target" --arg code "bead_quality_mining_hash_mismatch" \
              '{repo:$repo,target:$target,status:"error",code:$code,message:"bead quality mining probe hash did not match after copy"}' >>"$ERRORS_FILE"
          fi
        else
          rm -f "$tmp" 2>/dev/null || true
          ERROR_COUNT=$((ERROR_COUNT + 1))
          jq -cn --arg repo "$repo" --arg target "$mining_target" --arg code "bead_quality_mining_move_failed" \
            '{repo:$repo,target:$target,status:"error",code:$code,message:"failed to move bead quality mining probe into place"}' >>"$ERRORS_FILE"
        fi
      else
        rm -f "$tmp" 2>/dev/null || true
        ERROR_COUNT=$((ERROR_COUNT + 1))
        jq -cn --arg repo "$repo" --arg target "$mining_target" --arg code "bead_quality_mining_copy_failed" \
          '{repo:$repo,target:$target,status:"error",code:$code,message:"failed to copy bead quality mining probe"}' >>"$ERRORS_FILE"
      fi
    fi
  done <"$REPOS_FILE"
fi

if [[ -f "$IDENTITY_DEFERRAL_SCHEMA_SOURCE" ]]; then
  while IFS= read -r repo; do
    [[ -n "$repo" ]] || continue
    IDENTITY_DEFERRAL_SCHEMA_TARGET_COUNT=$((IDENTITY_DEFERRAL_SCHEMA_TARGET_COUNT + 1))
    schema_target="$repo/.flywheel/validation-schema/v1/identity-registration-deferral.schema.json"
    schema_hash="$(sha256_file "$schema_target")"
    if [[ "$schema_hash" == "$IDENTITY_DEFERRAL_SCHEMA_HASH" ]]; then
      continue
    fi
    IDENTITY_DEFERRAL_SCHEMA_DRIFTED_COUNT=$((IDENTITY_DEFERRAL_SCHEMA_DRIFTED_COUNT + 1))
    if [[ "$MODE" == "apply" ]]; then
      mkdir -p "$(dirname "$schema_target")"
      tmp="${schema_target}.tmp.$$"
      if cp "$IDENTITY_DEFERRAL_SCHEMA_SOURCE" "$tmp"; then
        backup_file "$schema_target"
        if mv "$tmp" "$schema_target"; then
          new_hash="$(sha256_file "$schema_target")"
          if [[ "$new_hash" == "$IDENTITY_DEFERRAL_SCHEMA_HASH" ]]; then
            IDENTITY_DEFERRAL_SCHEMA_SYNCED_COUNT=$((IDENTITY_DEFERRAL_SCHEMA_SYNCED_COUNT + 1))
            jq -cn --arg path "$schema_target" --arg action "copy_identity_registration_deferral_schema" '{path:$path,action:$action}' >>"$WRITES_FILE"
          else
            ERROR_COUNT=$((ERROR_COUNT + 1))
            jq -cn --arg repo "$repo" --arg target "$schema_target" --arg code "identity_deferral_schema_hash_mismatch" \
              '{repo:$repo,target:$target,status:"error",code:$code,message:"identity registration deferral schema hash did not match after copy"}' >>"$ERRORS_FILE"
          fi
        else
          rm -f "$tmp" 2>/dev/null || true
          ERROR_COUNT=$((ERROR_COUNT + 1))
          jq -cn --arg repo "$repo" --arg target "$schema_target" --arg code "identity_deferral_schema_move_failed" \
            '{repo:$repo,target:$target,status:"error",code:$code,message:"failed to move identity registration deferral schema into place"}' >>"$ERRORS_FILE"
        fi
      else
        rm -f "$tmp" 2>/dev/null || true
        ERROR_COUNT=$((ERROR_COUNT + 1))
        jq -cn --arg repo "$repo" --arg target "$schema_target" --arg code "identity_deferral_schema_copy_failed" \
          '{repo:$repo,target:$target,status:"error",code:$code,message:"failed to copy identity registration deferral schema"}' >>"$ERRORS_FILE"
      fi
    fi
  done <"$REPOS_FILE"
fi

while IFS= read -r repo; do
  [[ -n "$repo" ]] || continue
  sync_security_settings_for_repo "$repo"
done <"$REPOS_FILE"

while IFS= read -r repo; do
  [[ -n "$repo" ]] || continue
  if [[ -d "$RULES_SOURCE_DIR" ]]; then
    for rule_source in "$RULES_SOURCE_DIR"/L*.md "$RULES_SOURCE_DIR"/MANIFEST.json; do
      [[ -f "$rule_source" ]] || continue
      copy_managed_file "$repo" "$rule_source" "$repo/.flywheel/rules/$(basename "$rule_source")" "copy_rule_shard" 0
    done
  fi
  if [[ -d "$DOCTRINE_DOCS_SOURCE_DIR" ]]; then
    for doctrine_source in "$DOCTRINE_DOCS_SOURCE_DIR"/*.md; do
      [[ -f "$doctrine_source" ]] || continue
      copy_managed_file "$repo" "$doctrine_source" "$repo/.flywheel/doctrine/$(basename "$doctrine_source")" "copy_doctrine_doc" 0
    done
  fi
  if [[ -d "$SHARED_SCRIPT_SOURCE_DIR" ]]; then
    for script_name in $SHARED_SCRIPT_ALLOWLIST; do
      [[ "$script_name" == *.sh ]] || continue
      script_source="$SHARED_SCRIPT_SOURCE_DIR/$script_name"
      [[ -f "$script_source" ]] || continue
      copy_managed_file "$repo" "$script_source" "$repo/.flywheel/scripts/$script_name" "copy_shared_script" 1
    done
  fi
  if [[ -d "$LAUNCHD_TEMPLATE_SOURCE_DIR" ]]; then
    for plist_source in "$LAUNCHD_TEMPLATE_SOURCE_DIR"/*.plist; do
      [[ -f "$plist_source" ]] || continue
      copy_managed_file "$repo" "$plist_source" "$repo/.flywheel/launchd/$(basename "$plist_source")" "copy_launchd_template" 0
    done
  fi
done <"$REPOS_FILE"

DRIFTED_COUNT=$((CANONICAL_DRIFTED_COUNT + ROOT_DRIFTED_COUNT + SCHEMA_DRIFTED_COUNT + IDENTITY_DEFERRAL_SCHEMA_DRIFTED_COUNT + BEAD_MINING_DRIFTED_COUNT + SECURITY_SETTINGS_DRIFTED_COUNT + MANAGED_FILE_DRIFTED_COUNT))
SYNCED_COUNT=$((CANONICAL_SYNCED_COUNT + ROOT_SYNCED_COUNT + SCHEMA_SYNCED_COUNT + IDENTITY_DEFERRAL_SCHEMA_SYNCED_COUNT + BEAD_MINING_SYNCED_COUNT + SECURITY_SETTINGS_SYNCED_COUNT + MANAGED_FILE_SYNCED_COUNT))

STATUS="ok"
if [[ "$ERROR_COUNT" -gt 0 ]]; then
  STATUS="error"
elif [[ "$MODE" == "check" && "$DRIFTED_COUNT" -gt 0 ]]; then
  STATUS="drift_detected"
fi

DETAILS="$(jq -s -c '.' "$DETAILS_FILE")"
ROOT_DETAILS="$(jq -s -c '.' "$ROOT_DETAILS_FILE")"
WRITES="$(jq -s -c '.' "$WRITES_FILE")"
ERRORS="$(jq -s -c '.' "$ERRORS_FILE")"
TARGETS="$(json_string_array_from_file "$TARGETS_FILE")"
REPOS="$(json_string_array_from_file "$REPOS_FILE")"
SECURITY_SETTINGS_DETAILS="$(jq -s -c '.' "$SECURITY_SETTINGS_DETAILS_FILE")"
SECURITY_ROLLOUT_RECEIPT="$(jq -nc \
  --arg schema_version "security-settings-rollout/v1" \
  --arg ts "$SYNC_TS" \
  --arg scope "sandbox" \
  --arg source "$SECURITY_SETTINGS_DENY_SOURCE" \
  --arg source_hash "$SECURITY_SETTINGS_DENY_HASH" \
  --arg rollback_restore_pattern ".claude/settings.json.bak.<UTC_TIMESTAMP>" \
  --arg rollback_guard "restore_backup_before_retry" \
  --argjson targets "$SECURITY_SETTINGS_DETAILS" \
  '{
    schema_version:$schema_version,
    ts:$ts,
    scope:{env:$scope},
    source:{path:$source,sha256:$source_hash},
    targets:$targets,
    rollback_guard:{
      restore_pattern:$rollback_restore_pattern,
      guard:$rollback_guard,
      blocked_target_action:"do_not_overwrite_without_manual_restore"
    },
    token_shaped_values:false
  }')"
RESULT="$(jq -nc \
  --arg ts "$SYNC_TS" \
  --arg mode "$MODE" \
  --arg status "$STATUS" \
  --arg source "$SOURCE" \
  --arg ledger_path "$SYNC_LEDGER" \
  --arg source_hash "$SOURCE_HASH" \
  --argjson target_count "$TARGET_COUNT" \
  --argjson drifted_count "$DRIFTED_COUNT" \
  --argjson synced_count "$SYNCED_COUNT" \
  --argjson canonical_drifted_count "$CANONICAL_DRIFTED_COUNT" \
  --argjson canonical_synced_count "$CANONICAL_SYNCED_COUNT" \
  --argjson root_target_count "$ROOT_TARGET_COUNT" \
  --argjson root_drifted_count "$ROOT_DRIFTED_COUNT" \
  --argjson root_synced_count "$ROOT_SYNCED_COUNT" \
  --arg storage_override_schema_source "$STORAGE_OVERRIDE_SCHEMA_SOURCE" \
  --arg storage_override_schema_hash "$SCHEMA_SOURCE_HASH" \
  --argjson storage_override_schema_target_count "$SCHEMA_TARGET_COUNT" \
  --argjson storage_override_schema_drifted_count "$SCHEMA_DRIFTED_COUNT" \
  --argjson storage_override_schema_synced_count "$SCHEMA_SYNCED_COUNT" \
  --arg identity_deferral_schema_source "$IDENTITY_DEFERRAL_SCHEMA_SOURCE" \
  --arg identity_deferral_schema_hash "$IDENTITY_DEFERRAL_SCHEMA_HASH" \
  --argjson identity_deferral_schema_target_count "$IDENTITY_DEFERRAL_SCHEMA_TARGET_COUNT" \
  --argjson identity_deferral_schema_drifted_count "$IDENTITY_DEFERRAL_SCHEMA_DRIFTED_COUNT" \
  --argjson identity_deferral_schema_synced_count "$IDENTITY_DEFERRAL_SCHEMA_SYNCED_COUNT" \
  --arg bead_quality_mining_source "$BEAD_QUALITY_MINING_SOURCE" \
  --arg bead_quality_mining_hash "$BEAD_QUALITY_MINING_HASH" \
  --argjson bead_quality_mining_target_count "$BEAD_MINING_TARGET_COUNT" \
  --argjson bead_quality_mining_drifted_count "$BEAD_MINING_DRIFTED_COUNT" \
  --argjson bead_quality_mining_synced_count "$BEAD_MINING_SYNCED_COUNT" \
  --arg security_settings_deny_source "$SECURITY_SETTINGS_DENY_SOURCE" \
  --arg security_settings_deny_hash "$SECURITY_SETTINGS_DENY_HASH" \
  --argjson security_settings_target_count "$SECURITY_SETTINGS_TARGET_COUNT" \
  --argjson security_settings_drifted_count "$SECURITY_SETTINGS_DRIFTED_COUNT" \
  --argjson security_settings_synced_count "$SECURITY_SETTINGS_SYNCED_COUNT" \
  --argjson security_settings_blocked_count "$SECURITY_SETTINGS_BLOCKED_COUNT" \
  --argjson security_settings_details "$SECURITY_SETTINGS_DETAILS" \
  --argjson security_rollout_receipt "$SECURITY_ROLLOUT_RECEIPT" \
  --arg doctrine_docs_source_dir "$DOCTRINE_DOCS_SOURCE_DIR" \
  --arg rules_source_dir "$RULES_SOURCE_DIR" \
  --arg shared_script_source_dir "$SHARED_SCRIPT_SOURCE_DIR" \
  --arg shared_script_allowlist "$SHARED_SCRIPT_ALLOWLIST" \
  --arg launchd_template_source_dir "$LAUNCHD_TEMPLATE_SOURCE_DIR" \
  --argjson managed_file_target_count "$MANAGED_FILE_TARGET_COUNT" \
  --argjson managed_file_drifted_count "$MANAGED_FILE_DRIFTED_COUNT" \
  --argjson managed_file_synced_count "$MANAGED_FILE_SYNCED_COUNT" \
  --arg orch_validation_skill_source "$ORCH_VALIDATION_SKILL_SOURCE" \
  --arg orch_validation_skill_hash "$ORCH_VALIDATION_SKILL_HASH" \
  --argjson errors_count "$ERROR_COUNT" \
  --argjson targets "$TARGETS" \
  --argjson repos "$REPOS" \
  --argjson details "$DETAILS" \
  --argjson root_details "$ROOT_DETAILS" \
  --argjson writes "$WRITES" \
  --argjson errors "$ERRORS" \
  --slurpfile managed_details "$MANAGED_DETAILS_FILE" \
  '{
    ts:$ts,
    mode:$mode,
    status:$status,
    source:$source,
    ledger_path:$ledger_path,
    source_hash:$source_hash,
    target_count:$target_count,
    drifted_count:$drifted_count,
    synced_count:$synced_count,
    canonical_drifted_count:$canonical_drifted_count,
    canonical_synced_count:$canonical_synced_count,
    root_target_count:$root_target_count,
    root_drifted_count:$root_drifted_count,
    root_synced_count:$root_synced_count,
    storage_override_schema_source:$storage_override_schema_source,
    storage_override_schema_hash:$storage_override_schema_hash,
    storage_override_schema_target_count:$storage_override_schema_target_count,
    storage_override_schema_drifted_count:$storage_override_schema_drifted_count,
    storage_override_schema_synced_count:$storage_override_schema_synced_count,
    identity_deferral_schema_source:$identity_deferral_schema_source,
    identity_deferral_schema_hash:$identity_deferral_schema_hash,
    identity_deferral_schema_target_count:$identity_deferral_schema_target_count,
    identity_deferral_schema_drifted_count:$identity_deferral_schema_drifted_count,
    identity_deferral_schema_synced_count:$identity_deferral_schema_synced_count,
    bead_quality_mining_source:$bead_quality_mining_source,
    bead_quality_mining_hash:$bead_quality_mining_hash,
    bead_quality_mining_target_count:$bead_quality_mining_target_count,
    bead_quality_mining_drifted_count:$bead_quality_mining_drifted_count,
    bead_quality_mining_synced_count:$bead_quality_mining_synced_count,
    security_settings_deny_source:$security_settings_deny_source,
    security_settings_deny_hash:$security_settings_deny_hash,
    security_settings_target_count:$security_settings_target_count,
    security_settings_drifted_count:$security_settings_drifted_count,
    security_settings_synced_count:$security_settings_synced_count,
    security_settings_blocked_count:$security_settings_blocked_count,
    security_settings_drift:{
      target_count:$security_settings_target_count,
      drifted_count:$security_settings_drifted_count,
      synced_count:$security_settings_synced_count,
      blocked_count:$security_settings_blocked_count
    },
    security:{
      settings_deny:{
        source:$security_settings_deny_source,
        source_hash:$security_settings_deny_hash,
        target_count:$security_settings_target_count,
        drifted_count:$security_settings_drifted_count,
        synced_count:$security_settings_synced_count,
        blocked_count:$security_settings_blocked_count,
        details:$security_settings_details
      },
      rollout_receipt:$security_rollout_receipt
    },
    doctrine_docs_source_dir:$doctrine_docs_source_dir,
    rules_source_dir:$rules_source_dir,
    shared_script_source_dir:$shared_script_source_dir,
    shared_script_allowlist:$shared_script_allowlist,
    launchd_template_source_dir:$launchd_template_source_dir,
    managed_file_target_count:$managed_file_target_count,
    managed_file_drifted_count:$managed_file_drifted_count,
    managed_file_synced_count:$managed_file_synced_count,
    orch_validation_skill_source:$orch_validation_skill_source,
    orch_validation_skill_hash:$orch_validation_skill_hash,
    errors_count:$errors_count,
    targets:$targets,
    repos:$repos,
    details:$details,
    root_details:$root_details,
    managed_details:$managed_details,
    writes:$writes,
    errors:$errors
  }')"

if [[ "${SYNC_CANONICAL_LEDGER_DISABLE:-0}" != "1" ]]; then
  mkdir -p "$(dirname "$SYNC_LEDGER")"
  printf '%s\n' "$RESULT" >>"$SYNC_LEDGER"
fi

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$RESULT"
else
  printf 'mode=%s status=%s targets=%s drifted=%s synced=%s errors=%s\n' \
    "$MODE" "$STATUS" "$TARGET_COUNT" "$DRIFTED_COUNT" "$SYNCED_COUNT" "$ERROR_COUNT"
fi

if [[ "$ERROR_COUNT" -gt 0 ]]; then
  exit 2
fi
if [[ "$MODE" == "check" && "$DRIFTED_COUNT" -gt 0 ]]; then
  exit 1
fi
exit 0
