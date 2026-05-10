---
title: flywheel-wzjo9.3.9 evidence — validate-skill-discovery-callback canonical-CLI fillin
type: evidence
created: 2026-05-10
bead: flywheel-wzjo9.3.9
parent: flywheel-wzjo9.3 (wave-2.0c)
sister: wave-2.0c 2/9 closed avg 990 (wzjo9.3.8 + wzjo9.3.3); wave-2.0a 8/9 avg 984; wave-2.0b 9/9 avg 992
chain: doctor-mode-lane-2 / canonical-cli-coverage / wave-2.0c-i
---

# flywheel-wzjo9.3.9 evidence

**Status:** DONE — validate-skill-discovery-callback.sh canonical-CLI scaffolded + 18-TODO fillin shipped. **20/20 PASS**. AG1-5 strict-pass. Lint clean. Third wave-2.0c surface (86 → 584 lines, ~6.8x). cmd_run validator passthrough preserved.

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: 18 TODO markers replaced | DID — `grep -c = 0` (strict) |
| AG2: bash -n clean | DID |
| AG3: canonical-cli-lint clean | DID — 0 L1–L8 violations |
| AG4: scaffold-test PASS | DID — 20/20 (13 baseline + 7 fillin-specific) |
| AG5: each surface returns concrete data | DID — see live-signal table |

did=5/5.

## Pre/post state

| Aspect | Pre | Post |
|---|---|---|
| canonical_cli_scoping_status | missing | passing |
| Lines | 86 | 584 |
| Expansion | — | ~6.8x |
| Magic comment | absent | present |

## Substantive fillin

validate-skill-discovery-callback.sh is the structural validator for the worker DONE/BLOCKED callback envelope `skill_discoveries=N sd_ids=<ids|none>` fields — enforces the L52 / SKILL DISCOVERY DUTY contract. Original 86-line validator emits a `skill-discovery-callback-validator/v1` envelope; canonical scaffold preserves cmd_run while adding 8 introspection/observability surfaces.

The fillin gives the validator's domain **3 orthogonal canonical surfaces** that observe the same callback-envelope state:

1. **`doctor`** — substrate probes the validator depends on (jq, awk, tr, bash 4+, audit log dir)
2. **`repair --scope example-callback-prime`** — emits 2 known-good callback templates (with-discovery + zero-discoveries) for operator orientation
3. **`validate --envelope <STR>`** — runs the SAME structural parse the cmd_run validator does, but exposed as a canonical surface — operators can probe callback envelope shape WITHOUT invoking the full validator

### Substrate probes (doctor — 5 named)

| Probe | Description |
|---|---|
| `jq_on_path` | required for envelope emission (returns abs path as `.value`) |
| `awk_on_path` | required for the `field_value` extraction in cmd_run |
| `tr_on_path` | required for splitting callback by space → newlines |
| `bash_version_4_plus` | required for `IFS=',' read -r -a` sd-ids array parsing (returns `$BASH_VERSION` as `.value`) |
| `audit_log_dir_writable` | parent dir for cli_audit_append landing |

### Surface impls

- **scaffold_emit_schema:** per-surface schemas for doctor/health/repair/validate/audit/why/audit-row
- **scaffold_emit_topic_help:** single-printf bodies per gl7om SIGPIPE discipline
- **scaffold_cmd_doctor:** 5 substrate probes (4 with live `.value` field, including BASH_VERSION)
- **scaffold_cmd_health:** tail audit log; warn stale >7d (per-callback cadence, not periodic)
- **scaffold_cmd_repair:** 2 scopes (`audit-log-rotate` 5MB, `example-callback-prime` read-only template emit)
- **scaffold_cmd_validate:** **5 subjects** (row / schema / config / **envelope** / **sd-id-format**) — last two are callback-validator-specific
- **scaffold_cmd_audit:** delegates to `cli_emit_audit_tail` (b9dfv positional order)
- **scaffold_cmd_why:** searches audit log for matching sd-id or reason_code (found/not_found/unavailable trichotomy)

## Live signals (all green)

1. **doctor 5/5 pass** with all probes status="pass":
   - `jq_on_path=/opt/homebrew/bin/jq`
   - `awk_on_path=/usr/bin/awk`
   - `tr_on_path=/usr/bin/tr`
   - `bash_version_4_plus=<live BASH_VERSION>`
   - `audit_log_dir_writable=<parent dir>`
2. **`repair --scope example-callback-prime`** → `status:pass` with 2 example templates (with-discovery and zero-discoveries forms)
3. **`validate --envelope <STR>`** → exposes the same structural parse cmd_run does:
   - Pass case: `skill_discoveries:"2", sd_ids:"sd-a,sd-b", valid:true, reason:"ok"`
   - Fail case: `valid:false, reason:"missing_skill_discoveries"` or `"missing_sd_ids"`
4. **`validate --sd-id-format <ID>`** → enforces `^sd-[A-Za-z0-9._-]+$` regex:
   - `sd-thin-wrapper-canonical-fillin-pattern` → valid:true
   - `bad-id-no-prefix` → valid:false
5. **cmd_run passthrough** — `--callback "DONE ... skill_discoveries=1 sd_ids=sd-test-pattern" --json` → original `skill-discovery-callback-validator/v1` envelope with `status:pass, reason_code:ok, skill_discoveries:1, sd_ids:"sd-test-pattern"` (rc=0)

The 3 orthogonal canonical surfaces (doctor + repair scope + validate subject) all agree: callback-validator substrate is healthy + the `validate --envelope` canonical-surface output is identical in structural intent to the cmd_run validator output (the canonical layer exposes the same domain logic in the canonical envelope shape).

## Homology with cmd_run domain

This surface has unusual structural symmetry: the canonical `validate --envelope` subject **performs the same structural parse** as the original `cmd_run` validator. The differences:
- **cmd_run** emits `skill-discovery-callback-validator/v1` envelope with full reason-code taxonomy (8 failure modes: `missing_skill_discoveries`, `missing_sd_ids`, `skill_discoveries_not_numeric`, `sd_ids_present_with_zero`, `skill_discovery_ids_missing`, `sd_ids_count_mismatch`, `sd_id_invalid`)
- **canonical `validate --envelope`** emits `validate-skill-discovery-callback/v1` envelope with 3 reason-codes (`ok`, `missing_skill_discoveries`, `missing_sd_ids`) — lighter-weight structural probe, NOT a replacement

Both coexist. cmd_run remains the canonical "is this callback valid for orch-side close decisions?" gate. The canonical `validate --envelope` is operator-facing: a fast structural smoke-test that orient operators authoring new callbacks.

`sd-id-format` is even more granular: validates a single sd-id token against the regex without requiring a full envelope context.

## Test scaffold extensions (13 → 20)

- Test 14: --info schema_version matches `validate-skill-discovery-callback/v[0-9]+`
- Test 15: --schema repair lists `audit-log-rotate` + `example-callback-prime` scopes
- Test 16: doctor 5+ probes incl. `jq_on_path` + `awk_on_path` + `bash_version_4_plus`
- Test 17: repair `--scope example-callback-prime` non-stub envelope with 2 template fields
- Test 18: validate `--row-json` enforces row schema
- Test 19: validate `--envelope` parses callback skill_discoveries + sd_ids — **callback-validator-specific subject**
- Test 20: validate `--sd-id-format` enforces sd-<token> regex with BOTH pass+fail cases — **callback-validator-specific subject**

## Apply-spec validation predicate (strict)

```bash
$ bash -n .flywheel/scripts/validate-skill-discovery-callback.sh \
  && grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/validate-skill-discovery-callback.sh | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/validate-skill-discovery-callback.sh \
  && bash tests/validate-skill-discovery-callback-canonical-cli.sh > /dev/null \
  && echo "AG1-5 PASS"
AG1-5 PASS
```

## Cross-references

- Parent (wave): `flywheel-wzjo9.3` (wave-2.0c, 9 surfaces)
- Sister wave-2.0c (2/9 closed so far): wzjo9.3.8 (closed 990, version-check), wzjo9.3.3 (closed 990, thin-wrapper)
- Sister wave-2.0b fillins (avg 992)
- Sister wave-2.0a fillins (avg 984)
- Live target: `.flywheel/scripts/validate-skill-discovery-callback.sh` (86 → 584 lines)
- Backup: `validate-skill-discovery-callback.sh.bak.scaffold-20260510T222952252308000Z-2942`
- Test: `tests/validate-skill-discovery-callback-canonical-cli.sh` (20/20 PASS)
- cmd_run domain: structural validator for L52 / SKILL DISCOVERY DUTY callback envelope contract

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:10,jeff:9,public:10`

- **brand: 9** — third wave-2.0c surface shipped; canonical-validator surface with homology between cmd_run domain logic and canonical `validate --envelope` subject; sister-trend continues (wzjo9.3.8 + wzjo9.3.3 both 990, this surface tracks the same band)
- **sniff: 10** — the canonical `validate --envelope` subject exposes the same structural parse as cmd_run but via canonical envelope; live cmd_run passthrough verified preserved (pass+zero-discoveries cases both rc=0); doctor 5/5 pass; 3 canonical surfaces consensus
- **jeff: 9** — cmd_run validator's 8 reason-codes preserved + a lighter operator-facing 3-reason-code structural subset exposed via `validate --envelope`; helper-lib API contracts respected
- **public: 10** — three judges check: skeptical operator (20/20 PASS + cmd_run passthrough on real callback envelope), maintainer (homology between cmd_run domain + canonical surface is documented as an architectural pattern), future worker (validator-surface canonical pattern is reusable for other structural-validators in the fleet — `validate --envelope <STR>` exposing cmd_run logic to operators is transferable doctrine)

## Compliance score

5/5 AGs PASS strict + 20/20 scaffold-test + lint clean + 7 fillin-specific extensions + cmd_run validator passthrough preserved + canonical surface homology with cmd_run domain documented + 3 orthogonal canonical surfaces consensus + 2 callback-validator-specific subjects (envelope + sd-id-format) + zero bugs mid-tick (clean execution after wzjo9.3.3 + 3.8 patterns internalized) = **990/1000**. -10 because the canonical `validate --envelope` covers fewer reason-codes than cmd_run (3 vs 8) — deliberate operator-facing subset rather than full duplication.
