# C2 Doctor Invariant Rig: frozen-projection-invariant

Task: read-only follow-on design for `flywheel-loop doctor --scope frozen-projection-invariant --json`.
Mission-anchor: self-sustaining-company-architecture-health.

Inputs used:
- C2 deep-research doctor schema lines 124-170 and F4 ladder lines 104-120.
- Existing doctor surfaces in `~/.claude/skills/.flywheel/bin/flywheel-loop`
  and `.flywheel/scripts/recovery-doctor-probe.sh`.
- Socraticode K=10 against canonical `/Users/josh/Developer/flywheel`;
  project index observed green with 979 indexed chunks.

## 1. Doctor JSON Top-Level Field Set

Scoped command contract:

```text
flywheel-loop doctor --scope frozen-projection-invariant --json
```

It should emit a complete scoped packet. The unscoped global doctor should nest
that packet under `.frozen_projection_invariant` and mirror only prefixed
summary fields at the global top level.

| field | type/cardinality | notes |
|---|---|---|
| `schema_version` | string, exactly 1 | const `frozen-projection-invariant/v1` |
| `surface` | string, exactly 1 | const `frozen-projection-invariant` |
| `scope` | string, exactly 1 | const `frozen-projection-invariant` |
| `status` | enum, exactly 1 | `pass`, `warn`, or `fail` |
| `mode` | enum, exactly 1 | `audit` default, `strict` when doctor is strict |
| `repo` | string, exactly 1 | canonical absolute repo path |
| `observed_at` | ISO-8601 string, exactly 1 | scan completion time |
| `cutoff_ts` | ISO-8601 string or null | enforcement cutoff for new debt |
| `strict_promoted_at` | ISO-8601 string or null | when assigned debt starts failing |
| `scanner_version` | string, exactly 1 | scanner implementation version |
| `scan_files` | integer >=0 | total files scanned across groups |
| `scan_inputs` | array, 5 expected groups | group summaries, deterministic order |
| `frozen_projection_status` | enum, exactly 1 | mirror of scoped `status` |
| `frozen_projection_count` | integer >=0 | unsuppressed strict findings |
| `frozen_projection_by_target` | object string->integer | counts by group or target class |
| `literal_payload_targets` | array of strings | unique paths with literal payload findings |
| `path_named_payload_targets` | array of strings | unique source-path/placeholder-backed paths |
| `oldest_literal_age_sec` | integer or null | max age among literal findings |
| `newest_fail_mtime` | ISO-8601 string or null | newest file mtime among fail findings |
| `new_debt_fail_count` | integer >=0 | post-cutoff unsuppressed findings |
| `existing_debt_warn_count` | integer >=0 | pre-cutoff unsuppressed findings |
| `secret_value_fail_count` | integer >=0 | secret literal findings, never suppressed |
| `scan_error_count` | integer >=0 | unreadable/malformed/internal scan errors |
| `findings` | array of objects | full scoped finding rows, stable IDs |
| `top_findings` | array of objects, capped | redacted operator summary, default cap 10 |
| `warnings` | array of objects | machine-readable `code`, `message`, evidence |
| `errors` | array of objects | machine-readable `code`, `message`, evidence |
| `actions` | array of objects | recommended repair or assignment actions |
| `signals` | object | L60-style producer/measurement/consumer metadata |
| `auto_bead_promotion_trigger` | object | enabled when status requires durable work |

Expected `scan_inputs[]` group summary fields:

```json
{
  "group": "launchagents",
  "glob": "/Users/josh/Library/LaunchAgents/*.plist",
  "files": 134,
  "raw_mutable_keyword_hits": 51,
  "strict_forbidden_hits": 0,
  "allow_hits": 7,
  "unreadable_count": 0,
  "malformed_count": 0
}
```

Expected `findings[]` row fields:

`finding_id`, `severity`, `group`, `path`, `line`, `pattern_id`,
`allow_pattern_id`, `file_mtime`, `mtime_relation`, `finding_age_sec`,
`target_class`, `reason_code`, `owner`, `remediation_bead`, `due_at`,
`raw_match_text_redacted`.

`finding_id` should be deterministic: `sha256(path + line + pattern_id + redacted_capture)[:16]`.

Global doctor mirror fields:

`frozen_projection_invariant`, `frozen_projection_status`,
`frozen_projection_count`, `frozen_projection_by_target`,
`literal_payload_targets`, `path_named_payload_targets`,
`oldest_literal_age_sec`, `frozen_projection_scan_files`,
`frozen_projection_cutoff_ts`, `frozen_projection_new_debt_fail_count`,
`frozen_projection_existing_debt_warn_count`.

## 2. Scan-Aggregate Pipeline

1. Discover scan inputs by deterministic sorted groups:
   G1 LaunchAgent plists, G2 local loop tick scripts, G3 repo tick/watch/stuck
   scripts, G4 flywheel templates, G5 flywheel command surfaces.
2. Extract text lines. For plists, parse structured XML first and scan relevant
   string values plus script arguments; fall back to raw text only with a
   warning row.
3. Apply regex bank in three passes:
   `raw mutable keyword` -> `strict forbidden` -> `allow/source suppression`.
4. Never allow-suppress `secret_value_literal`; redact the value and retain only
   key name plus value hash.
5. Emit per-finding rows only for unsuppressed strict hits, secret hits,
   unreadable required groups, malformed plists, and invalid allow receipts.
   Raw keyword density stays in `scan_inputs[]` unless paired with strict risk.
6. Aggregate scoped counts:
   - `scan_files`: sum of group `files`.
   - `frozen_projection_count`: count of unsuppressed strict findings, warn and
     fail, excluding raw-only density and allow-suppressed hits.
   - `frozen_projection_by_target`: count by `target_class` or `group`.
   - `literal_payload_targets`: sorted unique paths from unsuppressed strict
     literal findings.
   - `path_named_payload_targets`: sorted unique paths where mutable state is
     sourced by path, placeholder, or topology lookup.
   - `oldest_literal_age_sec`: max `observed_at - file_mtime` for literal
     findings.
   - `newest_fail_mtime`: max `file_mtime` where severity is fail.
   - `new_debt_fail_count`, `existing_debt_warn_count`,
     `secret_value_fail_count`, `scan_error_count`: direct sums by reason.
7. Build `actions[]` from failed or warn-debt buckets, not from raw matches:
   e.g. assign fleet sweep, file remediation bead, repair malformed plist, or
   replace literal pane/payload with live topology lookup.

## 3. Status Enum And F4 Ladder Integration

Status values are lowercase to match current scoped doctor surfaces.

`pass`:
- Scanner ran all required groups.
- No unsuppressed strict forbidden findings.
- Raw keyword density is either absent or backed by allow/source patterns.

`warn`:
- Existing debt: unsuppressed strict forbidden hit where
  `file_mtime <= cutoff_ts`.
- Assigned debt: pre-cutoff finding has `remediation_bead`, `owner`, and
  unexpired `due_at`.
- Audit-mode execution error in optional groups G3-G5.
- Raw mutable-keyword density above threshold without strict forbidden hits.

`fail`:
- New debt: unsuppressed strict forbidden hit where `file_mtime > cutoff_ts`.
- Any `secret_value_literal`.
- Missing or unreadable required group G1 or G2.
- Malformed plist that prevents extraction.
- Inline allow receipt without reason/source.
- After `strict_promoted_at`, pre-cutoff finding without a remediation bead.
- Assigned finding past `due_at`.
- Strict-mode scanner execution error.

F4 behavior:
- Audit mode makes the scanner visible first: existing fleet debt warns, new
  mutable-state literals fail, and secret material fails immediately.
- Strict mode raises execution errors and overdue/unassigned promoted debt to
  fail.
- `auto_bead_promotion_trigger.enabled` should be true when `status == "fail"`,
  and false for pure warn unless a policy explicitly wants advisory bead
  creation.

## 4. Backward Compatibility With Existing Doctor Scopes

- Add one new scope case: `frozen-projection-invariant`. Do not alter existing
  `wire-or-explain`, `loop-driver`, `idle-state`, `publishability-bar`,
  `storage`, or file-length fields.
- Unscoped doctor embeds the full scoped packet at `.frozen_projection_invariant`; all global mirrors use the
  `frozen_projection_*` prefix except the two target arrays already proposed by
  C2.
- Do not reuse global `status`, `errors`, or `warnings` names for this scope.
  The main doctor may still derive its overall status from the nested packet
  according to existing aggregation policy.
- Missing scanner binary returns a warn fallback packet with all required fields
  present and zero/empty defaults, matching existing missing-probe behavior.
- Invalid scanner JSON returns a warn fallback packet with
  `warnings[{code:"frozen_projection_invalid_json"}]`.
- Scoped command exits nonzero only for `status == "fail"`. Warn remains exit 0
  so old dashboards and bootstrap installs do not break.
- The scanner stays read-only. It recommends bead promotion through `actions[]`
  and `auto_bead_promotion_trigger`, but does not create beads itself.
