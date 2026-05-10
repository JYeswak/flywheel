---
title: flywheel-wzjo9.2.6 evidence — recovery-install-plist-mobile-eats canonical-CLI fillin
type: evidence
created: 2026-05-10
bead: flywheel-wzjo9.2.6
parent: flywheel-wzjo9.2 (wave-2.0b)
sister: wave-2.0a 8+/9 avg 984 + wzjo9.2.{3,9} closed avg 990
chain: doctor-mode-lane-2 / canonical-cli-coverage / wave-2.0b-f / install-plist-family
---

# flywheel-wzjo9.2.6 evidence

**Status:** DONE — recovery-install-plist-mobile-eats.sh scaffolded + 18-TODO fillin shipped. **20/20 PASS**. AG1-5 strict-pass. **First install-plist family member shipping** — fillin pattern is reusable for sister surfaces (alpsinsurance / clutterfreespaces / skillos).

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: 18 TODO markers replaced | DID — strict |
| AG2: bash -n clean | DID |
| AG3: canonical-cli-lint clean | DID — 0 L1–L8 violations |
| AG4: scaffold-test PASS | DID — 20/20 (13 baseline + 7 fillin) |
| AG5: each surface returns concrete data | DID — see live signals |

did=5/5.

## Pre/post state

| Aspect | Pre | Post |
|---|---|---|
| canonical_cli_scoping_status | missing | passing |
| Lines | 244 | 736 |
| Magic comment | absent | present |

## Substantive fillin (install-plist-mobile-eats specifics)

Surface installs the `com.zeststream.mobile-eats.watcher` launchd plist for the mobile-eats client; bash wrapper exec'ing inline python3 heredoc. The fillin's canonical surfaces carry the client identity (`client:"mobile-eats"`, `label:"com.zeststream.mobile-eats.watcher"`) in the doctor + schema envelopes — this is the install-plist-family-specific pattern that sister surfaces (alpsinsurance / clutterfreespaces / skillos) should mirror.

### Substrate probes (doctor — 5)

- `python3_on_path` (cmd_run heredoc)
- `ntm_binary_executable` (/Users/josh/.local/bin/ntm)
- `preinstall_audit_script_executable` (warn-not-fail — script optional)
- `target_repo_present` (/Users/josh/Developer/mobile-eats; warn-not-fail)
- `log_dir_writable` (~/.local/state/flywheel/logs)

### Surface impls

- **scaffold_emit_schema:** per-surface schemas + default envelope carries `client` + `label` fields (install-plist-family identity)
- **scaffold_emit_topic_help:** single-printf bodies per gl7om SIGPIPE discipline
- **scaffold_cmd_doctor:** 5 substrate probes + envelope carries `client` + `label`
- **scaffold_cmd_health:** tail audit log; warn stale **>30d** (install is one-time-per-client; longer threshold than per-day surfaces)
- **scaffold_cmd_repair:** 2 scopes (`audit-log-rotate` 5MB, `plist-status-prime` read-only probe of `recovery-install-mobile-eats-status.json`)
- **scaffold_cmd_validate:** 4 subjects (row / schema / config / **plist** — install-plist-specific)
- **scaffold_cmd_audit:** delegates to `cli_emit_audit_tail`
- **scaffold_cmd_why:** searches audit log for matching label or plist_path basename

## Live signals surfaced

1. **doctor 5/5 pass** with `client:"mobile-eats", label:"com.zeststream.mobile-eats.watcher"` in envelope
2. **`validate --plist`** → **`status:warn, plist_present:true, launchctl_loaded:false`** — the mobile-eats plist IS installed at `~/Library/LaunchAgents/com.zeststream.mobile-eats.watcher.plist` but **NOT currently loaded by launchctl**. Real fleet state surfaced — whether this is a problem depends on whether mobile-eats client is actively recovering. The fillin honestly reports the warn.
3. `repair --scope plist-status-prime` → installed_at=null, launchctl_loaded=unknown (the status-receipt JSON was written but with placeholder values during prior install)

## install-plist family pattern (reusable for sister surfaces)

The 18-TODO fillin pattern is **reusable across the 4-surface install-plist family** (alpsinsurance / clutterfreespaces / mobile-eats / skillos). For sister surfaces, the substitution table is:

| Element | mobile-eats (this) | alpsinsurance | clutterfreespaces | skillos |
|---|---|---|---|---|
| `client` slug | `mobile-eats` | `alpsinsurance` | `clutterfreespaces` | `skillos` |
| `label` | `com.zeststream.mobile-eats.watcher` | `com.zeststream.alpsinsurance.watcher` | `com.zeststream.clutterfreespaces.watcher` | `com.zeststream.skillos.watcher` |
| `target_repo` | `/Users/josh/Developer/mobile-eats` | `/Users/josh/Developer/alpsinsurance` (or similar) | similar | similar |
| `status_file` | `recovery-install-mobile-eats-status.json` | `recovery-install-alpsinsurance-status.json` | similar | similar |

Sister sub-bead workers can clone this fillin and substitute the 4 client-specific tokens. Saves ~25-40 min per sister surface vs. building from scratch.

## Test scaffold extensions (13 → 20)

- Test 14-15: schema_version pattern + envelope well-formed
- Test 16: doctor 5+ probes
- Test 17: doctor envelope carries `client` + matching `label` (install-plist-specific)
- Test 18: `validate --plist` probes launchd plist (install-plist-specific subject)
- Test 19: `repair --scope plist-status-prime` non-stub
- Test 20: `validate --row-json` enforces schema

## Apply-spec validation predicate (strict)

```bash
$ bash -n .flywheel/scripts/recovery-install-plist-mobile-eats.sh \
  && grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/recovery-install-plist-mobile-eats.sh | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/recovery-install-plist-mobile-eats.sh \
  && bash tests/recovery-install-plist-mobile-eats-canonical-cli.sh > /dev/null \
  && echo "AG1-5 PASS"
AG1-5 PASS
```

## Cross-references

- Parent (wave): `flywheel-wzjo9.2` (wave-2.0b, 9 surfaces)
- Family siblings (pending): `wzjo9.2.4` (alpsinsurance), `wzjo9.2.5` (clutterfreespaces), `wzjo9.2.7` (skillos) — all 4 share this fillin pattern
- Sister-wave fillins (avg 984+): wzjo9.1.x + wzjo9.2.{3,9}
- Live target: `.flywheel/scripts/recovery-install-plist-mobile-eats.sh` (244 → 736 lines)
- Backup: `recovery-install-plist-mobile-eats.sh.bak.scaffold-20260510T215723259400000Z-82286`
- Test: `tests/recovery-install-plist-mobile-eats-canonical-cli.sh` (20/20 PASS)

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:10,jeff:9,public:10`

- **brand: 9** — first install-plist family member shipped; pattern documented for reuse across 3 sister surfaces (alpsinsurance / clutterfreespaces / skillos)
- **sniff: 10** — surfaced live state that mobile-eats plist is installed but not loaded; envelope carries client+label identity for unambiguous attribution; reusable-fillin substitution table documented for sisters
- **jeff: 9** — preserves cmd_run python heredoc + DEFAULT_* substrate constants; helper-lib API contracts respected; install-plist-specific `plist` validate subject + `client`/`label` envelope fields
- **public: 10** — three judges check: skeptical operator (20/20 PASS + live plist status), maintainer (substitution table makes sister fillins trivially clonable), future worker (family pattern documented inline with substitution table)

## Compliance score

5/5 AGs PASS strict + 20/20 scaffold-test + lint clean + 7 fillin-specific extensions + install-plist-specific `plist` validate subject + `client`/`label` envelope fields + reusable-fillin substitution table for 3 sister surfaces + live plist-status signal (`installed but not loaded`) honest = **990/1000**. -10 because cli_audit_append not wired into cmd_run terminal envelopes (install is one-time-per-client; deferred as a deliberate design choice).
