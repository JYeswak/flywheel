# flywheel-9a3k1 — Evidence Pack

**Bead:** flywheel-9a3k1 (P2)
**Title:** [auto-bead-filer] dedup-blind-spot — identical-title open beads filed as separate rows
**Mission fitness:** `adjacent` — bead-DB hygiene prevents duplicate-bead-pair confusion in orch + worker triage
**Discovered during:** flywheel-2xdi.101 (Joshua-flagged via dispatch note)

## Acceptance gates (4/4)

| # | Gate | Status |
|---|---|---|
| AG1 | Locate auto-bead-filer entry point | DONE — `create_bead()` in `.flywheel/scripts/gap-hunt-probe.sh` line 1935 |
| AG2 | Add dedup against open-beads JSONL for matching title | DONE — new `open_bead_titles()` cache + `create_bead(open_titles=...)` parameter |
| AG3 | Sister fix referenced (gap_id stable_id path disambiguation) | NOTED — sister bead `flywheel-dnxjb` covers the probe-finder false-positive root cause; this bead implements the safety-net dedup |
| AG4 | Regression test asserting same-title gaps produce ONE bead | DONE — `tests/gap-hunt-probe-dedup-canonical-cli.sh` 8/8 PASS |

## Fix

Two new pieces in `.flywheel/scripts/gap-hunt-probe.sh`:

### 1. `open_bead_titles()` cache function

```python
def open_bead_titles() -> dict:
    """Return {title: bead_id} for all open + in_progress beads."""
    if not BR_BIN.exists():
        return {}
    result = subprocess.run(
        [str(BR_BIN), "list", "--status", "open",
         "--status", "in_progress", "--limit", "5000", "--json"],
        cwd=str(REPO_ROOT), text=True, capture_output=True, timeout=20, check=False,
    )
    if result.returncode != 0:
        return {}
    payload = json.loads(result.stdout)
    titles: dict = {}
    for row in payload.get("issues", []):
        title = row.get("title")
        bead_id = row.get("id")
        if title and bead_id and title not in titles:
            titles[title] = bead_id   # first-seen wins (oldest open bead)
    return titles
```

### 2. `create_bead()` dedup guard

```python
def create_bead(item: dict, open_titles: dict | None = None) -> str | None:
    ...
    title = f"[gap-{cls}] {item['name']}"[:180]
    # flywheel-9a3k1: skip if open/in_progress bead has matching title
    if open_titles is not None and title in open_titles:
        existing = open_titles[title]
        warn(f"dedup: open bead {existing} matches title; skipping ...")
        return None
    ...
```

### 3. `main()` builds cache + mutates it intra-run

```python
open_titles = open_bead_titles() if not DRY_RUN else {}
for item in new_items[:AUTO_BEAD_CAP]:
    bead_id = create_bead(item, open_titles=open_titles)
    if bead_id:
        auto_beads.append(bead_id)
        # Add newly-filed bead's title so subsequent gaps dedup against it
        cls = item["id"].split(":", 1)[0]
        new_title = f"[gap-{cls}] {item['name']}"[:180]
        open_titles[new_title] = bead_id
```

The intra-run mutation closes the race where two same-title gaps both fire in a single tick: the first call files the bead, the second call sees the title in the cache and skips.

## Test design

`tests/gap-hunt-probe-dedup-canonical-cli.sh` — 8 assertions:

1. syntax
2. `open_bead_titles()` defined
3. `create_bead()` dedup check present
4. main() builds the cache
5. main() mutates cache for intra-run dedup
6. dry-run skips br list (no side effects)
7. Integration: stub `br list` returns a fixture with a collision title; assert the dedup logic correctly skips the matching title and accepts a non-matching one
8. Stub `br create` was NEVER called (dedup short-circuited before reaching it)

The integration test uses a `PATH`-overridden stub `br` that logs invocations to a file. Test asserts ZERO `br create` calls occurred when the dedup cache had a matching title.

## Verification

```bash
$ bash tests/gap-hunt-probe-dedup-canonical-cli.sh
SUMMARY pass=8 fail=0

$ bash -n .flywheel/scripts/gap-hunt-probe.sh && echo SYNTAX_OK
SYNTAX_OK

$ bash .flywheel/scripts/gap-hunt-probe.sh --json --dry-run | jq '.gap_class_distribution["probe-without-receiver"]'
14  # no regression

# Sister tests:
$ bash tests/gap-hunt-probe-for-loop-source-corpus.sh   # 4/4
$ bash tests/gap-hunt-probe-skill-md-corpus.sh          # 4/4
$ bash tests/gap-hunt-probe-exec-sh-corpus.sh           # 4/4
$ bash tests/gap-hunt-probe-skill-tree-md-corpus.sh     # 6/6
```

## DID / DIDNT / GAPS

- **DID 4/4** — entry point located, dedup wired (cache + check + intra-run mutation), regression test 8/8
- **DIDNT none**
- **GAPS none** — sister gap (`flywheel-dnxjb`) for probe-finder FP is its own bead, not in scope here

## Files Changed

- `.flywheel/scripts/gap-hunt-probe.sh` — +`open_bead_titles()` function, dedup-aware `create_bead()` signature, main() builds + mutates cache
- `tests/gap-hunt-probe-dedup-canonical-cli.sh` (new, 8/8 PASS)
- `.flywheel/audit/flywheel-9a3k1/` (this evidence pack)

## L112 Probe

- `l112_probe_command`: `bash tests/gap-hunt-probe-dedup-canonical-cli.sh | tail -1`
- `l112_probe_expected`: `grep:pass=8 fail=0`
- `l112_probe_timeout_sec`: `30`

## Four-Lens Self-Grade

- **brand:** 9 — convergent with 2xdi.* cluster pattern (probe-side fix that closes a class)
- **sniff:** 10 — covers both inter-run dedup (against existing beads) AND intra-run dedup (within same probe invocation)
- **jeff:** 10 — surfaced by Joshua during 2xdi.101; closed in same session as the bead that surfaced it
- **public:** 9 — future workers reading the warn message get clear "dedup: open bead X matches title; skipping" signal
