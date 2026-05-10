---
title: per-bead apply-spec template (jloib wave-1 / flywheel-ok1sk)
type: template
parent: flywheel-ok1sk
parent_apply_spec: .flywheel/audit/flywheel-jloib/wave-1-apply-spec.md
---

# Per-bead apply-spec template

Each `flywheel-ok1sk.<N>` sub-bead inherits this shape. Replace the
`{{name}}` / `{{path}}` / `{{lane}}` placeholders per the
`decomposition-receipt.md` mapping table.

## Identity

- **Bead:** `flywheel-ok1sk.<N>`
- **Wave label:** wave-1-{{lane}}-{{N}} (per-binary fillin, jloib wave-1 family)
- **Parent (wave):** `flywheel-ok1sk` (jloib wave-1 = P0 missing × non-general lanes)
- **Grandparent:** `flywheel-jloib` (3-bead chain, doctor-mode-integration-2)

## Surface

| Attribute | Value |
|---|---|
| Name | `{{name}}` |
| Path | `{{path}}` |
| Pre-scaffold lines | (see decomposition-receipt) |
| Interpreter | bash |
| Priority | P0 |
| Lane | `{{lane}}` |
| canonical_cli_scoping_status (pre) | `missing` |

## Scope

Single-surface scaffold + 18-TODO substantive fillin following the canonical
sister-fillin shape (wzjo9.1.x + 1fk5f.x pattern).

## Deliverables

1. **Dry-run scaffold:** `scaffold-canonical-cli.sh {{path}} --json`
2. **Apply with idempotency-key:** `scaffold-canonical-cli.sh {{path}} --apply --idempotency-key=flywheel-ok1sk.<N>-pilot --json`
3. **Substantive 18-TODO fillin** (replace all functional `# TODO(canonical-cli-scaffold)` markers):
   - `scaffold_emit_schema` per-surface schemas
   - `scaffold_emit_topic_help` single-printf bodies (gl7om SIGPIPE discipline)
   - `scaffold_cmd_doctor` ≥5 named substrate probes
   - `scaffold_cmd_health` tail SCAFFOLD_AUDIT_LOG; warn stale >24h
   - `scaffold_cmd_repair` ≥2 surface-specific scopes + canonical refusal contract
   - `scaffold_cmd_validate` ≥3 subjects with rc=1 schema rejection
   - `scaffold_cmd_audit` `cli_emit_audit_tail` (path-then-schema positional order)
   - `scaffold_cmd_why` provenance lookup (found / not_found / unavailable)
4. **cmd_run wiring:** call `cli_audit_append` at terminal envelopes if cmd_run has clear terminal points
5. **Test additions:** extend baseline 13-test scaffold to ≥19 with 4-6 fillin-specific assertions

## Acceptance gates

- **AG1:** 18 TODO markers replaced
- **AG2:** `bash -n` clean
- **AG3:** `canonical-cli-lint.sh {{path}}` clean (0 L1-L8 violations)
- **AG4:** test PASS (≥13/13, prefer 19/19)
- **AG5:** each canonical surface returns concrete data

## Lane-specific doctor probe hints

When picking the `>=5 named substrate probes` for `scaffold_cmd_doctor`,
follow the lane-specific patterns from sister fillins:

- **agent-mail**: agent-mail token vault writable, agent-mail SQLite reachable, ntm executable, identity registry path resolvable, project_key valid
- **beads**: br executable, .beads/issues.jsonl readable, .beads/beads.db present, sqlite3 available, jq available
- **doctrine**: doctrine source path readable (e.g. INCIDENTS.md / AGENTS.md), repo root resolvable, jq available, comparator script (if any) executable, target log dir writable
- **jeff-corpus**: jeff-corpus root path exists (~/Developer/jeff-corpus), socraticode index present, jq + sqlite3 available, source repo enumeration sane, output ledger dir writable
- **quality**: polish-gate config readable, scorecard ledger path writable, jq available, sniff-rubric reachable, repo root resolvable
- **testing**: tested binary executable, fixture dir present, expected-output checksum match (if any), bash version >=4, repo root resolvable

## Validation predicate (strict, one-shot)

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n {{path}} \
  && grep -c 'TODO(canonical-cli-scaffold)' {{path}} | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh {{path}} \
  && bash tests/{{name-without-.sh}}-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

## Estimated wall-time

30-60 min per bead (longer for 600+ line surfaces; shorter for <150 line surfaces).
If exceeded, consider splitting the 18 TODOs across 2 ticks per natural-unit
META-RULE.

## Cross-refs

- Parent: `flywheel-ok1sk` (jloib wave-1 — 17 in-scope surfaces after exclusions)
- Grandparent: `flywheel-jloib` (3-bead chain)
- Sister exemplars (avg 982): wzjo9.1.{1,2,3,6,7,8} (avg 980); wzjo9.2.{1,3,4} (avg 990)
- Scaffolder: `.flywheel/scripts/scaffold-canonical-cli.sh` (with hoqq8 apply-gate fix + sacan verb-collision detection)
- Helper lib: `.flywheel/lib/canonical-cli-helpers.sh`

## Doctrine pointers

- SIGPIPE/pipefail multi-printf trap → single-printf topic_help bodies
- `cli_emit_audit_tail` signature: `(path, schema, limit)` — path first
- Apply-gate fires BEFORE side-effects (flywheel-hoqq8 invariant)
- Verb-collision bypass auto-emitted when collision detected (flywheel-sacan)
- For binaries with native `doctor`/`health`/etc. (verb-collision fully overlapping), see wzjo9.1.7 pattern: bypass-all intercept; scaffold_cmd_X stubs documented as scaffold-meta probes
- Test calibration per `feedback_calibrate_test_to_actual_contract` META-RULE: bare `validate`/`repair --scope none` returns rc=64 refusal envelope (canonical contract); use real `--scope log_dir` etc. in baseline tests
