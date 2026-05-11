# `br create` source_repo bug — workaround research

**Audit ID:** flywheel-6kdnf
**Date:** 2026-05-11
**Researcher:** subagent (Joshua's `feedback_jeff_issue_requires_full_workaround_research_first` META-RULE)

## Bug shape (corrected from task brief)

`br create` does NOT read `.beads/config.yaml`'s `issue_prefix` for `source_repo`. The installed binary `/Users/josh/.cargo/bin/br` (reports `0.2.5`, built 2026-05-06 between v0.2.5 tag and v0.2.6 tag) calls `canonical_source_repo(beads_dir)` (introduced commit `03167479` 2026-05-03, fixed up at `912126d8`). That helper returns the **basename of the canonicalized parent of `.beads/`**. On `/Users/josh/Developer/flywheel/.beads`, parent canonicalizes to `/Users/josh/Developer/flywheel`, basename is `flywheel` — which is also Joshua's `issue_prefix`, hence the original confusion. Repro in `/tmp/br-test.UisBYb`: `source_repo = "br-test.UisBYb"` (dir basename), unrelated to prefix `testbug`.

Fix exists upstream at `648b50f1` ("set source_repo to canonical repo path at create time") which switches to the full canonicalized absolute path — but that commit is on `master` past v0.2.6 and not in the installed binary.

Source-cite: `src/cli/commands/create.rs` lines 59-62 (HEAD, absolute-path version); historical helper `canonical_source_repo` per `git show 03167479` shows basename version that the installed binary still uses.

## Workaround matrix

| ID | Mechanism | Source-cite | Copy-test result | Risk | Decision |
|---|---|---|---|---|---|
| **W1** (applied wz5rh) | Bulk `jq` rewrite of `.beads/issues.jsonl` + `br sync --merge --force-jsonl` | `src/sync/mod.rs` accepts external JSONL with `--force-jsonl`; `src/cli/commands/sync.rs` help text | Works (already in production) | Violates `feedback_beads_jsonl_writes_via_br_only` for routine use; one-shot OK | One-shot cleanup OK, NOT routine |
| **W2** Set `issue_prefix:` to absolute path | `src/config/mod.rs:413` calls `set_config("issue_prefix", &prefix)` → `normalize_prefix` (storage/sqlite.rs:6610) strips non-alnum | Tested in `/tmp/br-w2.gC6scO`: prefix `/tmp/br-w2.gC6scO` produced ID `tmpbr-w2.gc6sco-xub` (mangled lowercased path used as prefix). `source_repo` STILL `"br-w2.gC6scO"` (unchanged — basename path is unrelated to prefix). | Catastrophic: IDs become unreadable, breaks every downstream lookup, `flywheel-XXXX` convention destroyed | REJECT |
| **W3** jq-edit JSONL row + `br sync --merge --force-jsonl` per-create | Same as W1 substrate; just scoped to single row | Tested in `/tmp/br-w3.Us1xdC`: created `testw3-0xx`, edited one row, ran merge — DB and JSONL both end with `source_repo=/tmp/br-w3.Us1xdC`. Output: `Convergent creation - kept external`. | Reversible. Race-condition exposure: another `br create` between jq-edit and `br sync` would lose race or trigger merge conflict (W1's bulk version has same exposure for the dirty-set window). Atomic temp-rename in br sync protects the JSONL file itself. | **Viable for routine use** as a wrapper, but adds ~200ms latency per create; cleaner than direct sqlite |
| **W4** Direct `sqlite3 UPDATE issues SET source_repo=... WHERE id=...` then `br sync --flush-only --force` | Schema confirmed at `src/storage/sqlite.rs:1552`, default in column is `"."`. Test required `--force` because direct SQL UPDATE does NOT add row to `dirty_issues` table (br tracks dirty via app-level inserts at write time). | Tested in `/tmp/br-w4.srwOac`: UPDATE worked, plain `--flush-only` said "Nothing to export"; `--flush-only --force` flushed full table including correct source_repo. | Concurrency: WAL-mode DB so a concurrent br write would race; `--force` bypasses staleness guard which could mask other drift. Reversible per-row. | **Viable** but `--force` bypassing guards is a code-smell for routine use |
| **W5** `BEADS_SOURCE_REPO=...` env var override | Searched all of `src/` for `BEADS_SOURCE_REPO` and `env::var.*source` — **does not exist**. Existing envs: `BEADS_DIR`, `BEADS_JSONL`, `BEADS_ACTOR`, `BEADS_CACHE_DIR`, `BEADS_STRICT_LOCAL`. Also tested `BEADS_DIR=$abspath/.beads br create` — `canonical_source_repo` still extracts basename. | Env var doesn't exist; `BEADS_DIR` override doesn't help (tested `/tmp/br-w5.yi6IFM` → still basename). | n/a | REJECT (would require upstream feature) |

## Why W2 fails (additional detail)

`src/storage/sqlite.rs:6610`: `set_config` calls `normalize_prefix(value)` when key is `issue_prefix`. `normalize_prefix` (per tests at L11728 "normalizes_issue_prefix" with input `" Project-Name! "`) lowercases and strips non-`[a-z0-9-]` chars. So `/Users/josh/Developer/flywheel` → `usersjoshdeveloperflywheel`-ish. Even if it accepted the literal path, `source_repo` is set from `canonical_source_repo(beads_dir)`, not from `config.issue_prefix` — so W2 cannot influence source_repo regardless.

## Recommendation

**File the Jeff issue.** Reasoning:

1. **W3 and W4 both work mechanically** but each requires either bypassing safety guards (`--force` in W4) or wrapping every `br create` call site (W3) — the fleet currently has ~30+ scripts that call `br create` directly (dispatch templates, worker close handlers, blocker-discipline-tick-chain, etc.).
2. Joshua's `feedback_beads_jsonl_writes_via_br_only` META-RULE (2026-05-07) explicitly fences manual JSONL writes; W1/W3 both violate the spirit.
3. The **upstream already has the canonical fix** committed at `648b50f1` ("set source_repo to canonical repo path at create time") sitting on master past v0.2.6. The Jeff issue is therefore not asking for new design — it is asking either (a) for a v0.2.7 release that includes `648b50f1`, or (b) clarification that the basename-not-absolute behavior between `03167479` and `648b50f1` is intentional and what the upgrade path is.
4. Evidence chain is now stronger than the W1 closeout draft: we have repro fixture (`/tmp/br-test.*`), source-cite chain (`03167479` → `912126d8` → `648b50f1`), and proof that 3 of 4 candidate workarounds are either broken (W2, W5) or violate fleet doctrine (W1 bulk, W3 per-create wrapper, W4 sqlite-+-force).

**Interim until Jeff response:** Keep using W1 (bulk jq + merge) for cleanup passes. Do NOT promote W3/W4 to canonical wrapper — that would entrench substrate-doctrine debt.

**Optional escalation:** If Jeff response is slow, ship W4-style wrapper as `.flywheel/scripts/br-create-with-source-repo.sh` gated by a `BEADS_FORCE_ABSOLUTE_SOURCE_REPO=1` env flag, with explicit memory anchor — but file the Jeff issue first.

## Copy-test snippets (re-runnable)

```bash
# W2
TMPDIR2=$(mktemp -d /tmp/br-w2.XXXXXX) && cd "$TMPDIR2" && git init -q
br init --prefix testw2 > /dev/null
printf 'issue_prefix: %s\n' "$TMPDIR2" > .beads/config.yaml
br create "w2 test" --priority 2 | tail -1
tail -1 .beads/issues.jsonl | jq '{id, source_repo}'
# Expect: mangled ID, source_repo still basename → REJECT

# W3
TMPDIR3=$(mktemp -d /tmp/br-w3.XXXXXX) && cd "$TMPDIR3" && git init -q
br init --prefix testw3 > /dev/null
br create "w3 test" --priority 2 | tail -1
ID=$(tail -1 .beads/issues.jsonl | jq -r .id)
jq -c --arg sr "$TMPDIR3" --arg id "$ID" \
  'if .id==$id then .source_repo=$sr else . end' \
  .beads/issues.jsonl > .beads/issues.jsonl.new
mv .beads/issues.jsonl.new .beads/issues.jsonl
br sync --merge --force-jsonl | tail -3
sqlite3 .beads/beads.db "SELECT source_repo FROM issues WHERE id='$ID';"
# Expect: both DB and JSONL show abs path → WORKS

# W4
TMPDIR4=$(mktemp -d /tmp/br-w4.XXXXXX) && cd "$TMPDIR4" && git init -q
br init --prefix testw4 > /dev/null
br create "w4 test" --priority 2 | tail -1
ID=$(tail -1 .beads/issues.jsonl | jq -r .id)
sqlite3 .beads/beads.db "UPDATE issues SET source_repo='$TMPDIR4' WHERE id='$ID';"
br sync --flush-only --force | tail -3
tail -1 .beads/issues.jsonl | jq '{id, source_repo}'
# Expect: abs path → WORKS but requires --force

# W5
# Source search confirms no BEADS_SOURCE_REPO; BEADS_DIR doesn't help either:
TMPDIR5=$(mktemp -d /tmp/br-w5.XXXXXX) && cd "$TMPDIR5" && git init -q
br init --prefix testw5 > /dev/null
BEADS_DIR="$TMPDIR5/.beads" br create "w5" --priority 2 | tail -1
tail -1 .beads/issues.jsonl | jq '{id, source_repo}'
# Expect: still basename → REJECT
```

## Source-cite summary

- `src/cli/commands/create.rs:59-62` (HEAD): `canonicalize().to_string_lossy()` → absolute path **(the fix)**
- `git show 03167479 -- src/cli/commands/create.rs`: `canonical_source_repo` returns basename **(installed binary's behavior)**
- `git show 912126d8`: confirms basename-of-parent design intent
- `src/storage/sqlite.rs:1552`: `unwrap_or(".")` default when source_repo is None
- `src/storage/sqlite.rs:6610` + L11728 test: `normalize_prefix` lowercases + strips non-alnum → breaks W2
- `src/util/source_repo_guard.rs:25-33`: `normalize_repo_path` resolves relative source_repo against cwd — explains why `"flywheel"` appears as a mismatch warning relative to `/Users/josh/Developer/flywheel`
- `src/config/mod.rs:218`: `BEADS_DIR` env var honored — but doesn't override `canonical_source_repo` derivation
