# flywheel-k8gcv.19 — jeff-shadow-socraticode.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.19 (wave-3-19, P0)
Surface: `.flywheel/scripts/jeff-shadow-socraticode.sh`
Lane: jeff-corpus
mutates_state: yes (clones/fetches shadow repos, writes refresh receipt + index ledger)

## AG3 acceptance gate

19/19 PASS. AG3 strict 4/4. Lint clean (was 2 violations: L6+L7).

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L6 magic comment | Added |
| 2 | L7 --apply not gated | Added `IDEMPOTENCY_KEY` var + `--idempotency-key` flag + rc=3 refusal block for `refresh`/`repair`/`record-index` modes |
| 3 | `--info` missing AG3 fields | Enriched: name, version, capabilities (7), subcommands (10), canonical_flags, apply_supported, idempotency_key_required_for_apply, mutates_state, env_vars, exit_codes (legacy shadow_root/state_dir/index_ledger/refresh_receipt/canonical_repos/mutating_commands/default_mutation_mode preserved) |
| 4 | `--schema` missing AG3 fields | Added input_schema + output_schema with full property detail (legacy required_status_fields/required_refresh_fields/required_index_receipt_fields preserved) |
| 5 | doctor envelope missing `.checks` | Added `checks` array derived from `repos[]` (each repo → {name, status, path, detail} with status=pass when index_status=indexed, warn when exists-but-not-indexed, fail when missing). Legacy `repos` + `canonical_repos` arrays unchanged. |
| 6 | `--examples --json` envelope enriched | Added 5 example entries with purpose fields (was 3 with name+command only) |

## Backward compatibility

5 regression tests:
- Legacy `status` envelope (repo_count + indexed_count + last_refresh_age_hours + dashboard_line) preserved.
- doctor preserves `repos` + `canonical_repos` arrays alongside new `checks`.
- Legacy `--doctor` flag still routes to status_json.
- `refresh --dry-run` does NOT require `--idempotency-key`.
- `--help` + `completion` preserved.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/jeff-shadow-socraticode.sh` | 293 → 395 lines (+102) |
| `tests/jeff-shadow-socraticode-canonical-cli.sh` | NEW (19 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.19/evidence.md` | NEW |

## Compliance: 1000/1000

four_lens=brand:9,sniff:9,jeff:9,public:9
