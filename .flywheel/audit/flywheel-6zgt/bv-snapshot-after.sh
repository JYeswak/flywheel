#!/bin/bash
# bv wrapper — avoids Go runtime getcwd() hang on macOS launchd subprocesses
# The Go runtime calls getcwd() at startup which blocks indefinitely when
# spawned from launchd→ntm→bv subprocess chain. Setting cwd before exec
# ensures getcwd() returns immediately.
#
# Auto-detects beads directory if BEADS_DIR is not set:
# 1. Check BEADS_DIR env var
# 2. Walk up from PWD looking for .beads directory
# 3. Try git root + .beads
# 4. Fall back to PWD
#
# 2026-05-09: bead-isolation Phase 3 (Change 3.7) — adds cross-tree symlink
# detection in walk-up plus BEADS_STRICT_LOCAL=1 honoring. Owned by bead
# flywheel-6zgt. Stable exit codes: 0 success, 78 (config) for strict-local
# discovery failure, otherwise inherits bv-real's exit code.

# Use BEADS_DIR if set
if [[ -n "${BEADS_DIR:-}" ]]; then
    DIR="$BEADS_DIR"
    # NTM sets BEADS_DIR to project root (e.g. /path/to/repo), but bv-real
    # expects cwd to be the .beads/ directory containing issues.jsonl.
    # Auto-append .beads if the dir doesn't already end with it.
    if [[ "$DIR" != */.beads && "$DIR" != *.beads && -d "$DIR/.beads" ]]; then
        DIR="$DIR/.beads"
    fi
elif [[ -n "${BEADS_DB:-}" ]]; then
    # BEADS_DB can point to beads.db or the .beads directory
    if [[ "$BEADS_DB" == *.beads/beads.db ]]; then
        DIR="${BEADS_DB%.beads/beads.db}"
    elif [[ "$BEADS_DB" == */.beads ]]; then
        DIR="$BEADS_DB"
    elif [[ "$BEADS_DB" == */.beads/beads.db ]]; then
        DIR="${BEADS_DB%/.beads/beads.db}"
    else
        DIR="$BEADS_DB"
    fi
else
    # Auto-detect: walk up from PWD looking for .beads
    # Phase 3 hardening: skip cross-tree symlinks. A `.beads` whose
    # readlink target escapes the current walk-up tree is treated as
    # absent (continue walking up). This prevents repoB → repoA bead
    # bleed when repoB/.beads is a symlink to repoA/.beads.
    BEADS_BASE="$PWD"
    DIR=""
    # Loop guard: stop at "/" or empty (BASH "${var%/*}" yields "" when
    # var has no remaining "/", so without -n we would spin forever).
    while [[ -n "$BEADS_BASE" && "$BEADS_BASE" != "/" ]]; do
        candidate="$BEADS_BASE/.beads"
        if [[ -d "$candidate" ]]; then
            if [[ -L "$candidate" ]]; then
                resolved="$(readlink -f "$candidate" 2>/dev/null)"
                # Cross-tree symlink: target lives outside the walk-up
                # base, i.e. doesn't share the BEADS_BASE prefix.
                if [[ -n "$resolved" && "$resolved" != "$BEADS_BASE"/* && "$resolved" != "$BEADS_BASE" ]]; then
                    if [[ -t 2 ]]; then
                        printf 'bv: skipping cross-tree symlink %s -> %s\n' "$candidate" "$resolved" >&2
                    fi
                    BEADS_BASE="${BEADS_BASE%/*}"
                    continue
                fi
            fi
            DIR="$candidate"
            break
        fi
        BEADS_BASE="${BEADS_BASE%/*}"
    done
    # If we walked to root without finding a usable .beads, fall back
    # to the original PWD/.beads (bv-real may still error on it, which
    # is the desired strict-local behaviour).
    if [[ -z "$DIR" ]]; then
        DIR="$PWD/.beads"
    fi
fi

# Resolve symlinks
if [[ -L "$DIR" ]]; then
    DIR="$(readlink -f "$DIR" 2>/dev/null || echo "$DIR")"
fi

# BEADS_STRICT_LOCAL=1: refuse to operate against a discovered .beads
# whose canonicalised location is outside the original PWD's directory
# tree. This is the env var ntm and orchestrators set when they want
# fail-loud isolation rather than walk-up bleed. Stable exit code 78
# (EX_CONFIG) so callers can distinguish strict-local rejection from
# bv-real's own non-zero exits.
if [[ "${BEADS_STRICT_LOCAL:-0}" == "1" ]]; then
    # Canonicalise both sides through `cd … && pwd -P` so that
    # macOS's /tmp ↔ /private/tmp system symlink does not register as
    # a strict-local violation. Fall back to readlink -f when cd fails
    # (e.g. DIR does not exist).
    pwd_real="$(cd "$PWD" 2>/dev/null && pwd -P)"
    pwd_real="${pwd_real:-$PWD}"
    if [[ -d "$DIR" ]]; then
        dir_real="$(cd "$DIR" 2>/dev/null && pwd -P)"
        dir_real="${dir_real:-$(readlink -f "$DIR" 2>/dev/null || echo "$DIR")}"
    else
        dir_real="$(readlink -f "$DIR" 2>/dev/null || echo "$DIR")"
    fi
    if [[ ! -d "$dir_real" ]]; then
        printf 'bv: BEADS_STRICT_LOCAL=1: no .beads under %s; refusing\n' \
            "$pwd_real" >&2
        exit 78
    fi
    if [[ "$dir_real" != "$pwd_real"/* && "$dir_real" != "$pwd_real" ]]; then
        printf 'bv: BEADS_STRICT_LOCAL=1: %s is outside %s; refusing\n' \
            "$dir_real" "$pwd_real" >&2
        exit 78
    fi
fi

cd "$DIR" 2>/dev/null
export BEADS_DIR="$DIR"
exec ~/.local/bin/bv-real "$@"
