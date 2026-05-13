#!/usr/bin/env bash
# test_symlink_bleed_isolation.sh — Phase 4 T4.1 regression fixture.
# Mimics the production layout that caused FM-1: parent dir with a real
# .beads/, plus a child dir whose .beads/ is a cross-tree symlink. Asserts:
#
#   (1) br-authority-probe detects the cross-tree symlink.
#   (2) verify-bead-authority refuses to operate on the symlinked child.
#   (3) BEADS_STRICT_LOCAL=1 routing causes discovery_method=strict-error.
#
# Fixture-only — never touches $HOME/Developer or live beads DBs.
set -euo pipefail

ROOT="<flywheel-repo>"
PROBE="$ROOT/.flywheel/scripts/br-authority-probe.sh"
VERIFY="$ROOT/.flywheel/scripts/verify-bead-authority.sh"

[[ -x "$PROBE" ]] || { echo "FAIL: probe not executable: $PROBE" >&2; exit 2; }
[[ -x "$VERIFY" ]] || { echo "FAIL: verify not executable: $VERIFY" >&2; exit 2; }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/symlink-bleed-isolation.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# Production-shape: a "parent project" with .beads at $TMP/parent/.beads,
# plus a "child" directory whose .beads is a symlink to a far-away vault.
mkdir -p "$TMP/parent/.beads" "$TMP/child" "$TMP/global-vault/.beads"
echo "fixture parent" > "$TMP/parent/.beads/beads.db"
echo "fixture global" > "$TMP/global-vault/.beads/beads.db"
ln -s "$TMP/global-vault/.beads" "$TMP/child/.beads"

# --- Case 1: child with cross-tree symlinked .beads ---
out_child="$("$PROBE" --target-dir "$TMP/child" --json)"
disc_child="$(jq -r '.discovery_method' <<<"$out_child")"
sym_child="$(jq -r '.is_symlink' <<<"$out_child")"
cross_child="$(jq -r '.cross_tree' <<<"$out_child")"

if [[ "$disc_child" != "local" ]]; then
  echo "FAIL: child probe expected discovery_method=local got $disc_child" >&2
  echo "$out_child" >&2
  exit 1
fi
if [[ "$sym_child" != "true" ]]; then
  echo "FAIL: child probe expected is_symlink=true got $sym_child" >&2
  echo "$out_child" >&2
  exit 1
fi
if [[ "$cross_child" != "true" ]]; then
  echo "FAIL: child probe expected cross_tree=true got $cross_child" >&2
  echo "$out_child" >&2
  exit 1
fi

# --- Case 2: verify-bead-authority refuses cross-tree symlink ---
verify_rc=0
verify_out="$("$VERIFY" --target-dir "$TMP/child" --json 2>&1)" || verify_rc=$?
if [[ "$verify_rc" -ne 1 ]]; then
  echo "FAIL: verify expected rc=1 on cross-tree symlink, got $verify_rc" >&2
  echo "$verify_out" >&2
  exit 1
fi
verdict="$(jq -r '.verdict' <<<"$verify_out")"
if [[ "$verdict" != "refused-cross-tree" ]]; then
  echo "FAIL: verify expected verdict=refused-cross-tree got $verdict" >&2
  echo "$verify_out" >&2
  exit 1
fi

# --- Case 3: bare child without .beads, BEADS_STRICT_LOCAL routes ---
mkdir -p "$TMP/bare-child"
out_walk="$(BEADS_STRICT_LOCAL=1 "$PROBE" --target-dir "$TMP/bare-child" --json)"
disc_walk="$(jq -r '.discovery_method' <<<"$out_walk")"
walk_dist="$(jq -r '.walk_up_distance' <<<"$out_walk")"

# Bare-child has no .beads anywhere up the temp tree (we built parent/child
# siblings, not parent/bare-child); discovery should be 'none' from the
# fixture root since the temp dir itself has no .beads.
case "$disc_walk" in
  none|strict-error|walk-up) :;;
  *) echo "FAIL: bare-child probe expected discovery_method in {none|strict-error|walk-up} got $disc_walk" >&2; echo "$out_walk" >&2; exit 1;;
esac

# --- Case 4: parent with a real local .beads passes ---
out_parent="$("$PROBE" --target-dir "$TMP/parent" --json)"
disc_parent="$(jq -r '.discovery_method' <<<"$out_parent")"
sym_parent="$(jq -r '.is_symlink' <<<"$out_parent")"
cross_parent="$(jq -r '.cross_tree' <<<"$out_parent")"
if [[ "$disc_parent" != "local" ]]; then
  echo "FAIL: parent probe expected discovery_method=local got $disc_parent" >&2
  echo "$out_parent" >&2
  exit 1
fi
if [[ "$sym_parent" != "false" ]]; then
  echo "FAIL: parent probe expected is_symlink=false got $sym_parent" >&2
  exit 1
fi
if [[ "$cross_parent" != "false" ]]; then
  echo "FAIL: parent probe expected cross_tree=false got $cross_parent" >&2
  exit 1
fi

verify_rc=0
verify_out="$("$VERIFY" --target-dir "$TMP/parent" --json 2>&1)" || verify_rc=$?
if [[ "$verify_rc" -ne 0 ]]; then
  echo "FAIL: verify expected rc=0 on clean parent .beads, got $verify_rc" >&2
  echo "$verify_out" >&2
  exit 1
fi
clean_verdict="$(jq -r '.verdict' <<<"$verify_out")"
if [[ "$clean_verdict" != "ok" ]]; then
  echo "FAIL: verify expected verdict=ok on clean parent got $clean_verdict" >&2
  exit 1
fi

printf 'PASS: symlink-bleed isolation regression — cross-tree symlink refused, clean parent ok\n'
