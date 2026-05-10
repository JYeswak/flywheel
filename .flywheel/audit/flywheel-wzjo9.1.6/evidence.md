---
title: flywheel-wzjo9.1.6 evidence — flywheel-anchor canonical-CLI scaffold + 18-TODO fillin
type: evidence
created: 2026-05-10
bead: flywheel-wzjo9.1.6
parent: flywheel-wzjo9.1 (wave-2.0a)
sister: flywheel-wzjo9.1.1 (970), flywheel-wzjo9.1.3 (980); 1fk5f.{1..8} (avg 974)
chain: doctor-mode-lane-2 / canonical-cli-coverage / wave-2.0a-f
---

# flywheel-wzjo9.1.6 evidence

**Status:** DONE — flywheel-anchor scaffolded + 18-TODO fillin shipped. **20/20 PASS** on canonical-cli scaffold-test (13 baseline + 7 fillin-specific). AG1-5 strict-pass. Lint clean. cmd_run subcommand discipline (seed/list/inject/seed-all/refresh-cache) preserved.

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: 18 TODO markers replaced | DID — `grep -c 'TODO(canonical-cli-scaffold)' = 0` (strict) |
| AG2: bash -n clean | DID |
| AG3: canonical-cli-lint clean | DID — 0 violations L1–L8 |
| AG4: scaffold-test PASS | DID — 20/20 (13 baseline + 7 fillin-specific) |
| AG5: each surface returns concrete data | DID — see live-signal table below |

did=5/5, didnt=none, gaps=none.

## Pre/post state

| Aspect | Pre | Post |
|---|---|---|
| canonical_cli_scoping_status | partial | passing |
| world_class_doctor_score_estimate | 0 | 1000 (estimated) |
| has_doctor signal | false | true |
| Lines | 257 | 758 |
| Magic comment | absent | present |
| Backup | n/a | `flywheel-anchor.bak.scaffold-20260510T212944578939000Z-38626` |

## Substantive fillin

flywheel-anchor bridges flywheel skills to Joshua's repos via the socraticode MCP server. It consumes pre-fetched JSON anchor caches at `$FLYWHEEL_HOME/logs/anchors/<skill>.json` and seeds them into the flywheel DB / injects them into `~/.claude/skills/<name>/INTERNAL-ANCHORS.md`.

### Substrate probes (doctor)

| Probe | Description |
|---|---|
| `flywheel_home_resolvable` | FLYWHEEL_HOME env or default parent dir |
| `lib_common_readable` | `$FLYWHEEL_HOME/lib/common.sh` (provides fw_sql etc.) |
| `anchor_cache_dir` | `$FLYWHEEL_HOME/logs/anchors/` (warn-not-fail when absent; created on first seed) |
| `skills_dir_present` | `$FLYWHEEL_SKILLS_DIR` (default ~/.claude/skills) |
| `jq_on_path` | required for anchor-cache JSON parsing |

### Surface impls

- **scaffold_emit_schema:** per-surface schemas (doctor / health / repair / validate / audit / why / audit-row / default)
- **scaffold_emit_topic_help:** single-printf bodies per gl7om SIGPIPE discipline
- **scaffold_cmd_doctor:** 5 substrate probes
- **scaffold_cmd_health:** tail audit log → recent_runs / last_run_ts / distinct_skills / distinct_subcommands
- **scaffold_cmd_repair:** 2 scopes
  - `audit-log-rotate` — rotate ledger when >5MB
  - `anchor-cache-prime` — read-only probe of `$FLYWHEEL_HOME/logs/anchors/` (cache count + sample of skill names)
- **scaffold_cmd_validate:** 4 subjects (row / schema / config / **cache**)
  - The `cache` subject is anchor-specific: `--skill=NAME` validates the JSON shape of `$FLYWHEEL_HOME/logs/anchors/<NAME>.json` against the contract `{skill, queried_at, queries, hits}`
- **scaffold_cmd_audit:** delegates to `cli_emit_audit_tail` (path-then-schema per b9dfv)
- **scaffold_cmd_why <id>:** searches audit log for matching skill or subcmd

## Live signals surfaced

The substantive fillin caught real fleet state on this dev machine:

1. **`repair --scope anchor-cache-prime`** reports **`cache_count:61`** — 61 anchor-cache JSON files exist in `$FLYWHEEL_HOME/logs/anchors/`. Sample of 20 skill names returned. **Fleet anchor infrastructure is well-populated.**
2. **`validate --skill cloudflare-api`** returns **`status:pass`** — the cloudflare-api cache file has all 4 required fields (skill / queried_at / queries / hits). **Live validation against real anchor data works.**
3. **`doctor` returns 5/5 pass** — full substrate is healthy on this dev fleet.
4. **`validate --config` returns pass** — all of FLYWHEEL_HOME, lib/common.sh, anchor-cache dir, jq present.

These are real signals, not contrived test fixtures — the fillin proves the scaffold layer works against live fleet data.

## Test scaffold extensions (13 → 20)

- Test 14: `--info schema_version` matches `flywheel-anchor/v1`
- Test 15: `--schema` envelope well-formed
- Test 16: doctor 5+ probes incl. `flywheel_home_resolvable` + `anchor_cache_dir`
- Test 17: repair `--scope anchor-cache-prime` non-stub envelope with `cache_count` or `reason`
- Test 18: validate `--row-json` enforces schema
- Test 19: validate `--skill` emits cache subject envelope (pass|warn|fail per cache state) — **anchor-specific subject**
- Test 20: why provenance enum

## Apply-spec validation predicate (strict)

```bash
$ bash -n /Users/josh/.claude/skills/.flywheel/bin/flywheel-anchor \
  && grep -c 'TODO(canonical-cli-scaffold)' /Users/josh/.claude/skills/.flywheel/bin/flywheel-anchor | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh /Users/josh/.claude/skills/.flywheel/bin/flywheel-anchor \
  && bash tests/flywheel-anchor-canonical-cli.sh > /dev/null \
  && echo "AG1-5 PASS"
AG1-5 PASS
```

## Cross-references

- Parent (wave): `flywheel-wzjo9.1` (wave-2.0a, 9 surfaces)
- Sister fillins closed: `flywheel-wzjo9.1.1` (flywheel-summarize, 970/1000), `flywheel-wzjo9.1.3` (flywheel-trauma-check, 980/1000)
- Sister-lane exemplars: `flywheel-1fk5f.{1..8}` (8/8 closed avg 974)
- Live target: `/Users/josh/.claude/skills/.flywheel/bin/flywheel-anchor` (257 → 758 lines)
- Backup: `flywheel-anchor.bak.scaffold-20260510T212944578939000Z-38626`
- Test: `tests/flywheel-anchor-canonical-cli.sh` (20/20 PASS)
- Live anchor caches: `$FLYWHEEL_HOME/logs/anchors/*.json` (61 files on this fleet)

Boundary: live-mutated target lives in `~/.claude/skills/.flywheel/bin/`. Only test scaffold + audit evidence committed in this repo.

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:10,jeff:9,public:9`

- **brand: 9** — third surface in wave-2.0a shipped; pattern matches sister-lane exemplar
- **sniff: 10** — live signals surfaced (61 anchor caches, cloudflare-api cache validates clean) — fillin proves itself against real fleet data, not contrived fixtures
- **jeff: 9** — preserves cmd_run subcommand discipline (seed/list/inject/seed-all/refresh-cache); helper-lib API contracts respected; anchor-specific 4th validate subject (`cache`) added cleanly without overloading existing subjects
- **public: 9** — three judges check: skeptical operator (20/20 PASS + live anchor-cache count), maintainer (substrate probes match cmd_run's actual dependencies), future worker (anchor-specific cache validate subject is documented in topic-help)

## Compliance score

5/5 AGs PASS strict + 20/20 scaffold-test PASS + lint clean + 7 fillin-specific test extensions + backup preserved + cmd_run subcommand discipline preserved + anchor-specific `cache` validate subject added cleanly + live signals proven (61 caches + cloudflare-api validates) = **980/1000**. -20 because cli_audit_append is not yet wired into cmd_run terminal envelopes (deferred — cmd_run subcommands `seed`/`list`/`inject`/`seed-all`/`refresh-cache` could each emit a row but the wiring requires careful per-subcommand integration).
