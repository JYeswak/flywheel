# Draft GitHub Issue — Dicklesworthstone/beads_rust

**Status:** DRAFT in flywheel-8x2le evidence pack. NOT YET FILED upstream.
**Audience:** Jeffrey Emanuel (per `~/.claude/skills/jeff-issue-chain` protocol; Jeffrey, not Jeff, in human-facing prose)
**Title:** `br create` writes basename-only `source_repo` instead of absolute repo path
**br version probed:** `br 0.2.5`
**Date:** 2026-05-09

---

## Title

`br create` writes basename-only `source_repo` instead of absolute repo path

## Reproduction

```bash
tmp=$(mktemp -d -t br-probe.XXXXXX)
cd "$tmp" && git init -q
~/.cargo/bin/br init >/dev/null
~/.cargo/bin/br create "src-repo-probe" -t task -p 4 -d "probe"
sqlite3 "$tmp/.beads/beads.db" "SELECT source_repo FROM issues ORDER BY created_at DESC LIMIT 1;"
# Observed:  br-probe.XXXXXX.JXAL56t2x9
# Expected:  /private/var/folders/d0/.../br-probe.XXXXXX.JXAL56t2x9
```

## Impact

Cross-project state keyed by `source_repo` collides when two repos share a basename (e.g., a temp scratch and the canonical repo of the same name). Downstream consumers that rely on `source_repo` as a canonical key — for cross-project bead routing, `br where`, audit tooling, and reservation registries — produce false-positive collisions or fail safety invariants.

Joshua's flywheel substrate has a doctrine note (`memory: feedback_basename_keying_collision_class`, 2026-05-08) that names this exact pattern as a recurring trauma class.

## Prior history

- `beads_rust#273` (closed) addressed `source_repo='.'` literal — that is now fixed; new beads no longer record `.`. Thank you.
- This issue is the follow-up: post-#273, `source_repo` records the **basename** of the working directory rather than the **absolute path**. Joshua's audit `tests/phase2-audit.sh` T2.4 expects absolute and currently fails.

## Suggested fix shape

When `br create` resolves the working directory for `source_repo`, prefer the canonical absolute path (e.g., the `cwd` of the `br` invocation passed through `std::fs::canonicalize` or `pwd -P` equivalent). The basename of `current_dir().file_name()` is a lossy projection of mutable state — the same trauma class as `frozen-projection-of-mutable-state` from Joshua's INCIDENTS.md.

A regression test could mirror Joshua's audit: create a temp dir, run `br init && br create`, assert `source_repo == fs::canonicalize(cwd)`.

## Acceptance from Joshua side

After upstream lands, Joshua's `tests/phase2-audit.sh` T2.4 will pass. Joshua-owned repos with legacy `source_repo='.'` rows will be backfilled separately (flywheel-8x2le.1 follow-up bead). Jeff-owned working copies (frankenterm, vibe_cockpit, ntm-mirror) follow the `feedback_no_push_ntm_br` doctrine and stay local.

## Filing protocol

Per `jeff-issue-chain` skill: this draft awaits Joshua's approval before filing on `Dicklesworthstone/beads_rust`. The draft documents the exact reproduction Joshua's audit hit so Jeffrey's response cycle has the full evidence in one place.
