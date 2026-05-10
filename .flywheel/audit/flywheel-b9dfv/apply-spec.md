# Bead flywheel-b9dfv: canonical-cli-helpers.sh revision (3 extractions)

Filed by CloudyMill during flywheel-3wxzi closeout 2026-05-10. The lib
v1 saved 111 lines/script (13.6%) on the pilot — in the 100-149 band,
below the 150-line threshold for "lib design validated."

This bead extracts 3 specific helpers identified during the pilot
refactor measurement. After ship, re-refactor pilot to confirm
combined savings clear 150/script (24-29% target).

## Three extraction targets

### Extraction 1: `cli_emit_schema_dispatch <surface_map_json>`

**Goal**: replace the 80-line per-surface `case "$surface" in default|run) ;;
doctor) ;; ...` schema dispatcher with a JSON-driven helper.

**Caller pattern (today, ~80 lines per script)**:
```bash
emit_schema() {
  local surface="${1:-default}"
  case "$surface" in
    default|run) jq -nc --arg sv "$SCHEMA_VERSION" '{schema_version:$sv, ...}' ;;
    doctor)      jq -nc '{schema_version:"...doctor/v1", ...}' ;;
    health)      jq -nc '{schema_version:"...health/v1", ...}' ;;
    ...
  esac
}
```

**New pattern (~10 lines per script + one JSON sidecar)**:
```bash
emit_schema() {
  local surface="${1:-default}"
  cli_emit_schema_dispatch "$ROOT/.flywheel/scripts/<name>-schemas.json" "$surface"
}
```

Sidecar `<name>-schemas.json`:
```json
{
  "default": {"schema_version":"<sv>", ...},
  "run":     {"schema_version":"<sv>", ...},
  "doctor":  {"schema_version":"<sv>.doctor/v1", ...},
  ...
}
```

**Helper signature**:
```bash
cli_emit_schema_dispatch <surface_map_json_path> <surface_name>
  # Reads the JSON map, looks up <surface_name> (with default/run aliasing),
  # emits the schema body. Exits 64 if surface not found.
```

**Expected savings**: ~60-80 lines/script.

### Extraction 2: `cli_route_command_help <subcommand> <topic_help_fn> <args...>`

**Goal**: consolidate the per-subcommand `case "${1:-}" in --help|-h) emit_topic_help <topic>; exit 0 ;; esac`
boilerplate.

**Caller pattern (today, ~3 lines × N subcommands ≈ 30 lines)**:
```bash
doctor) shift
  case "${1:-}" in --help|-h) emit_topic_help doctor; exit 0 ;; esac
  cmd_doctor; exit $? ;;
health) shift
  case "${1:-}" in --help|-h) emit_topic_help health; exit 0 ;; esac
  cmd_health; exit $? ;;
```

**New pattern (~1 line per subcommand)**:
```bash
doctor) shift; cli_route_command_help doctor emit_topic_help "$@"; cmd_doctor; exit $? ;;
health) shift; cli_route_command_help health emit_topic_help "$@"; cmd_health; exit $? ;;
```

**Helper signature**:
```bash
cli_route_command_help <subcommand_name> <topic_help_function> [<remaining_args...>]
  # If first remaining arg is --help or -h, calls topic_help_fn with subcommand_name
  # and exits 0. Otherwise returns 0 (caller proceeds).
```

**Expected savings**: ~10-20 lines/script.

### Extraction 3: `cli_emit_audit_tail <audit_log_path> <limit>`

**Goal**: extract the `tail -n N | jq -s ...` audit-reader pattern.

**Caller pattern (today, ~20 lines)**:
```bash
cmd_audit() {
  if [[ ! -f "$AUDIT_LOG" ]]; then
    jq -nc --arg sv "...audit/v1" '{schema_version:$sv,command:"audit",status:"missing",row_count:0,recent:[]}'
    return 0
  fi
  local row_count; row_count="$(wc -l <"$AUDIT_LOG" | tr -d ' ')"
  if [[ "$row_count" -eq 0 ]]; then
    jq -nc --arg sv "...audit/v1" '{schema_version:$sv,command:"audit",status:"empty",row_count:0,recent:[]}'
    return 0
  fi
  local recent; recent="$(tail -20 "$AUDIT_LOG" | jq -cs '.')"
  jq -nc --arg sv "...audit/v1" --argjson rc "$row_count" --argjson recent "$recent" \
    '{schema_version:$sv,command:"audit",status:"pass",row_count:$rc,recent:$recent}'
}
```

**New pattern (~5 lines)**:
```bash
cmd_audit() {
  cli_emit_audit_tail "$AUDIT_LOG" 20 "<schema_version>.audit/v1"
}
```

**Helper signature**:
```bash
cli_emit_audit_tail <audit_log_path> <limit> <schema_version>
  # Emits the audit envelope:
  #   {schema_version, command:"audit", status:"missing"|"empty"|"pass",
  #    row_count, recent:[<last_limit_rows>]}
```

**Expected savings**: ~15-25 lines/script.

## Combined acceptance gate

After all 3 extractions ship:
- Re-refactor `daily-report-enabled-repos.sh` against revised lib
- Re-measure: target ≥150 lines/script saved OR ≥25% of original
- 22/22 regression tests STILL PASS (zero modifications)
- canonical-cli-lint.sh remains zero violations
- canonical-cli-helpers-smoke.sh: extend to 19+ assertions covering
  the 3 new helpers
- Update `pilot-lessons.md` with new measurements

If combined savings ≥150/script: lib v2 validated; bead 2.x lane work
unblocked.
If still <150: file second revision followup; do NOT begin lane work.

## Boundary

- Backward compat: existing helper signatures (cli_iso_now,
  cli_sha_self, cli_audit_append, cli_emit_info, cli_emit_examples,
  cli_emit_quickstart, cli_emit_completion_*, cli_refuse_apply_without_idem_key,
  cli_dispatch_subcommand_help, cli_emit_topic_help) MUST NOT change.
  Lib version stays `canonical-cli-helpers/v1` (additive).
- Pilot regression test MUST continue to pass without modification.
- Schema sidecar pattern (extraction 1) is opt-in — scripts that
  prefer inline schemas can keep the existing case statement.

## Estimated effort

~3-4 hours. Three small helpers (~30 lines each) + smoke test extensions
+ pilot re-refactor + lessons update + commit chain.

## Dependencies

- jloib.0a (helper lib v1) — CLOSED
- jloib.0d (pilot refactor) — CLOSED, reference data captured

## Canonical structure (post-hoc backfill, flywheel-at83y)

This apply-spec was authored before the F7 canonical structure rule (filesystem-as-rag doctrine).
The body above contains the substantive content; the H2 stubs below satisfy the mechanical lint without rewriting the prose.

## Goal

See body above (typically the opening paragraph or first H1 section).

## Acceptance gate

See body above (typically near the end, named Acceptance or per-AG numbered).
