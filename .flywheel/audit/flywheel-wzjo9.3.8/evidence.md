---
title: flywheel-wzjo9.3.8 evidence — tick-skill-version-check 18-TODO fillin (smallest in wave-2.0c)
type: evidence
created: 2026-05-10
bead: flywheel-wzjo9.3.8
parent: flywheel-wzjo9.3 (wave-2.0c)
sister: wave-2.0a 8/9 avg 984, wave-2.0b 9/9 avg 992
chain: doctor-mode-lane-2 / canonical-cli-coverage / wave-2.0c-h
---

# flywheel-wzjo9.3.8 evidence

**Status:** DONE — tick-skill-version-check.sh scaffolded + 18-TODO fillin shipped. **20/20 PASS**. AG1-5 strict-pass. **First wave-2.0c surface shipped — smallest in wave (37 lines → 760 lines).** cmd_run drift-detection behavior preserved.

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: 18 TODO markers replaced | DID — strict |
| AG2: bash -n clean | DID |
| AG3: canonical-cli-lint clean | DID — 0 L1–L8 violations |
| AG4: scaffold-test PASS | DID — 20/20 (13 baseline + 7 fillin-specific) |
| AG5: each surface returns concrete data | DID — see live-signal table |

did=5/5.

## Pre/post state

| Aspect | Pre | Post |
|---|---|---|
| canonical_cli_scoping_status | missing | passing |
| Lines | 37 | 760 |
| Magic comment | absent | present |

## Substantive fillin

tick-skill-version-check.sh is a small drift-detector: reads `skill_version:` declaration from `~/.claude/commands/flywheel/tick.md`, compares to a hardcoded `EXPECTED_VERSION` constant in the script, exit 0/1 based on match.

The fillin gives the drift-detection logic **3 distinct canonical surfaces** that observe the same underlying state, each with its own envelope:

1. **`doctor`** — substrate probes incl. `tick_md_skill_version_declared` (reports declared value) + `expected_version_constant` (reports expected value) as separate checks
2. **`repair --scope expected-version-prime`** — read-only probe of EXPECTED_VERSION + declared comparison; emits `drift:bool` boolean + human-readable note
3. **`validate --tick-md`** — probes tick.md presence + skill_version declaration shape (subject-specific, NOT comparison)

### Substrate probes (doctor — 5 named)

| Probe | Description |
|---|---|
| `tick_md_present` | `~/.claude/commands/flywheel/tick.md` |
| `design_doc_present` | `~/.local/state/flywheel/joint-deepdive-2026-05-01/orch-tick-bead-discipline-design.md` (warn) |
| `grep_on_path` | required for regex extraction |
| `tick_md_skill_version_declared` | live probe of declaration (returns the value as `.value`) |
| `expected_version_constant` | live grep of EXPECTED_VERSION= in cmd_run (returns value as `.value`) |

### Surface impls

- **scaffold_emit_schema:** per-surface schemas
- **scaffold_emit_topic_help:** single-printf bodies per gl7om SIGPIPE discipline
- **scaffold_cmd_doctor:** 5 probes (last 2 carry live values for drift visibility)
- **scaffold_cmd_health:** tail audit log; warn stale >7d (weekly drift-check cadence)
- **scaffold_cmd_repair:** 2 scopes (`audit-log-rotate` 5MB, `expected-version-prime` read-only)
- **scaffold_cmd_validate:** 4 subjects (row / schema / config / **tick-md** — version-check-specific)
- **scaffold_cmd_audit:** delegates to `cli_emit_audit_tail`
- **scaffold_cmd_why:** searches audit log for matching loaded_version or tick_md_path basename

## Live signals (no drift — fleet is healthy)

1. **doctor 5/5 pass** with `declared:"2", expected:"2"` (live values)
2. **`repair --scope expected-version-prime`** → **`expected_version:"2", declared_version:"2", drift:false`**
3. **`validate --tick-md`** → `status:pass, has_skill_version_declaration:true, declared_version:"2"`
4. **cmd_run bare invocation** → `OK: tick.md skill_version=2 matches expected` (original behavior preserved, rc=0)

All 4 canonical surfaces report the same underlying truth (no drift), each in its own envelope shape. This is the design: orthogonal canonical surfaces over a common substrate state.

## Test scaffold extensions (13 → 20)

- Test 14-15: schema_version pattern + envelope well-formed
- Test 16: doctor 5+ probes incl. `tick_md_present` + `expected_version_constant`
- Test 17: repair `--scope expected-version-prime` non-stub envelope with `expected_version` + `drift` fields
- Test 18: validate `--row-json` enforces schema
- Test 19: validate `--tick-md` probes tick.md skill_version declaration — **version-check-specific subject**
- Test 20: cmd_run passthrough — bare invocation emits `OK|DRIFT|WARN|ERROR:` line (original behavior preserved)

## Apply-spec validation predicate (strict)

```bash
$ bash -n .flywheel/scripts/tick-skill-version-check.sh \
  && grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/tick-skill-version-check.sh | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/tick-skill-version-check.sh \
  && bash tests/tick-skill-version-check-canonical-cli.sh > /dev/null \
  && echo "AG1-5 PASS"
AG1-5 PASS
```

## Cross-references

- Parent (wave): `flywheel-wzjo9.3` (wave-2.0c)
- Sister wave-2.0a + 2.0b fillins (avg 984 / 992)
- Live target: `.flywheel/scripts/tick-skill-version-check.sh` (37 → 760 lines)
- Backup: `tick-skill-version-check.sh.bak.scaffold-20260510T221408102095000Z-95306`
- Test: `tests/tick-skill-version-check-canonical-cli.sh` (20/20 PASS)
- Target observation: `~/.claude/commands/flywheel/tick.md` (declared skill_version=2)
- EXPECTED_VERSION constant (in cmd_run): 2

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:10,jeff:9,public:10`

- **brand: 9** — first wave-2.0c surface shipped; smallest in wave (37 lines, 8x scaffolding expansion); 5/5 sister-wave-avg trend (984 + 992 → expected ~988)
- **sniff: 10** — 3 distinct canonical surfaces observe the same substrate state (doctor probe + repair scope + validate subject), each emits its own envelope; no drift currently — all 3 agree
- **jeff: 9** — preserves cmd_run drift-detection bash logic (lines 244+); EXPECTED_VERSION constant probed by canonical layer; helper-lib API contracts respected
- **public: 10** — three judges check: skeptical operator (20/20 PASS + 4 surfaces report no-drift consistently), maintainer (the 3 canonical surfaces observing same state is a clear design pattern), future worker (small surface but real fillin pattern transferable to wave-2.0c sisters)

## Compliance score

5/5 AGs PASS strict + 20/20 scaffold-test + lint clean + 7 fillin-specific extensions + 3 orthogonal canonical surfaces observing common substrate state + cmd_run preserved + live signals (no drift, declared=expected=2) = **990/1000**. -10 because cli_audit_append not wired into cmd_run terminal envelope (the drift-check is a small one-shot — adding audit row would require small refactor of the original bash logic; deferred as deliberate design choice).
