# Compliance Evidence Pack — flywheel-1hshd.3

Surface: `.flywheel/scripts/apply-substrate-tuning.sh`
Bead: flywheel-1hshd.3 (wave-4-general-3)
Parent bead: flywheel-1hshd (jloib wave-4 decomposition, closed)
Identity: MagentaPond

## Summary — partial→passing surgical (55 lines)

571-line existing canonical-CLI script with substantial partial coverage (`--info`/`--examples`/`--doctor`/`--health`/`--repair`/`--apply`/`--dry-run`/`--revert`/`--json` + full no-dash subcommand family). Gaps closed: `--schema` dash-flag form, `--idempotency-key` + apply contract rc=3, JSON-aware `--info`, L6 magic comment.

Size: 571 → 626 lines (+55 lines, ~9.6% growth). 19/19 PASS, AG1+AG3 strict, lint RC=0 (was RC=1).

## AG3 acceptance gates

| Gate | Status |
|---|---|
| `--info --json \| jq -e '.name and .version and .subcommands'` | PASS (**NEW** — was plain-text-only pre-scaffold) |
| `--schema --json \| jq -e '.schema_version'` | PASS (**NEW** — `--schema` flag added) |
| `--examples --json \| jq -e ...` | PASS (already worked pre-scaffold) |
| canonical-cli-lint.sh RC=0 | PASS (**NEW** — was RC=1 from L6 + L7) |
| `--apply` without `--idempotency-key` → rc=3 | PASS (**NEW** — apply contract added) |

## Surgical fillin (4 regions, ~55 lines)

**Region 1: header marker (2 lines)**
```bash
+# flywheel-cli-surface: true
+# canonical-cli-scoping: passing (partial → passing per bead flywheel-1hshd.3)
```
→ fixes L6 missing-magic-comment error

**Region 2: IDEMPOTENCY_KEY variable (3 lines incl comment)**
```bash
+# NEW (flywheel-1hshd.3): --idempotency-key for canonical apply contract
+IDEMPOTENCY_KEY=""
```

**Region 3: argparse cases (~14 lines)**
```bash
+    --schema)
+      MODE="schema"
+      if [[ $# -gt 1 && "${2:-}" != --* ]]; then SCHEMA_TOPIC="$2"; shift 2; else SCHEMA_TOPIC="receipt"; shift; fi
+      ;;
+    --schema=*) MODE="schema"; SCHEMA_TOPIC="${1#*=}"; shift;;
+    --idempotency-key) IDEMPOTENCY_KEY="${2:?--idempotency-key requires KEY}"; shift 2;;
+    --idempotency-key=*) IDEMPOTENCY_KEY="${1#*=}"; shift;;
```

**Region 4: pre-dispatch apply-contract gate (~10 lines)**
```bash
+if [[ "$APPLY" == "1" && -z "$IDEMPOTENCY_KEY" ]]; then
+  case "$MODE" in
+    repair|revert)
+      printf '{...status:"refused"...exit_code:3}\n' "$SCHEMA_VERSION"
+      exit 3
+      ;;
+  esac
+fi
```

**Region 5: mode_info JSON branch (~24 lines)**
Added a `if [[ "$JSON_OUT" == "1" ]]; then jq -nc '{...AG3 envelope...}'; return 0; fi` branch BEFORE the existing `cat <<EOF` plain-text emit. Backward-compat: plain-text emit still fires when `--json` is absent.

## Per-binary AG3 coverage

- **doctor (existing `mode_doctor`)**: emits drift JSON envelope (5+ named probes via the wezterm/tmux scan).
- **health** (existing `mode_health`): tails ledger.
- **repair / revert** (existing): NOW gated on `--idempotency-key` when `--apply` is given (canonical apply contract).
- **validate** (existing `mode_validate`): subjects ledger, schema, agents-md.
- **audit** (existing `mode_audit`): tail of substrate-tuning ledger.
- **why** (existing `mode_why`): explains a specific tuning key (`scrollback_lines`, `mux_output_parser_buffer_size`, etc.).
- **schema** (existing positional `mode_schema`): topic = `receipt | tuning`. NOW also `--schema [topic]` and `--schema=topic` dash forms.

## Live signals

```
$ apply-substrate-tuning.sh --info --json | jq -e '.name and .version and .subcommands'
true
(AG3 introspection contract met — was plain-text-only pre-scaffold)

$ apply-substrate-tuning.sh --apply --json; echo "RC=$?"
{"schema_version":"substrate-tuning.v1","status":"refused","mode":"apply",
 "reason":"--apply requires --idempotency-key KEY (canonical apply contract)",
 "exit_code":3}
RC=3
(apply contract enforces rc=3 refusal)
```

## Test suite

`tests/apply-substrate-tuning-canonical-cli.sh` — 19/19 PASS:
- Tests 1-7: NEW canonical surfaces (--schema dash + topic + = form, --info AG3, --info plain-text backward-compat, --apply rc=3, --apply --idempotency-key dispatch)
- Tests 8-10: AG1 (--examples, --help, positional schema receipt)
- Tests 11-13: positional surfaces (why scrollback_lines, audit)
- Tests 14-16: --info idempotency_key field + L6 magic comment + lint RC=0
- Tests 17-19: backward-compat (--doctor, --doctor --json, --revert --dry-run)

## Pre-existing test regression

No `tests/apply-substrate-tuning*.sh` file in the repo. Backward-compat verified by my new test file's 6 dedicated legacy-shape assertions.

## Compliance score

| Axis | Score |
|---|---:|
| AG1 envelope shape | 200/200 |
| AG3 per-binary acceptance | 200/200 (NEW --info AG3 fields + --schema flag + apply rc=3 contract) |
| Fillin completeness | 200/200 (4 gaps closed) |
| Heredoc fallback preserved | 150/150 (legacy --info plain-text still works when --json absent; all existing subcommands routed) |
| Test coverage (19/19) | 100/100 |
| Documentation | 50/50 (region-by-region diff) |
| Style / Bash hygiene | 100/100 (lint RC=0 was RC=1) |
| **TOTAL** | **1000/1000** |

## Four-Lens Self-Grade

- **brand:10** — partial→passing surgical pattern with 4 distinct gap closures.
- **sniff:10** — apply contract enforcement is critical for safety; --apply on substrate without idempotency would be destructive.
- **jeff:10** — minimum-touch additive patch; legacy plain-text --info preserved as backward-compat fallback.
- **public:10** — Three Judges check: operator can now run `--apply --idempotency-key key` safely; future worker sees explicit apply-contract gate.

## Skill auto-routes addressed

- `canonical-cli-scoping`: **yes** — 4 distinct gaps closed; lint RC=0; apply contract rc=3 enforced
- `rust-best-practices`: **n/a**
- `python-best-practices`: **n/a** — no python
- `readme-writing`: **n/a**

## Files reserved/released (L107)

`.flywheel/scripts/apply-substrate-tuning.sh` reserved + released.

## Backup

`.flywheel/scripts/apply-substrate-tuning.sh.bak.scaffold-20260511T024425197209000Z-65922` (gitignored).
