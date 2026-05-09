# flywheel-rdqc7.1 Evidence

task_id: flywheel-rdqc7.1-2ba30f
bead: flywheel-rdqc7.1
worker: flywheel:3

## DID

- Added `--l-rules` / `--rules` to `/Users/josh/.local/bin/flywheel-doctrine-sync` via symlink target `.flywheel/scripts/doctrine-sync.sh`.
- The allowlist accepts comma or whitespace separated L-rule ids and normalizes them to canonical `L<N>` ids.
- Dry-run and apply output now include selected scope fields:
  - `l_rules_allowlist`
  - `l_rules_allowlist_active`
  - `missing_l_rules_all`
  - `missing_l_rules_all_count`
  - `unselected_missing_l_rules`
  - `unselected_missing_l_rules_count`
- Apply mode appends only selected missing rules.
- Partial allowlist applies do not stamp `.flywheel/STATE.json` with the full canonical doctrine version while unselected canonical drift remains.
- Invalid allowlist ids fail closed with `status=ERROR` and no mutation.

## Verification

- PASS: `bash -n .flywheel/scripts/doctrine-sync.sh`
- PASS: `.flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-rdqc7.1-2ba30f.md`
- PASS: `/Users/josh/.local/bin/flywheel-doctrine-sync --help | rg -- '--l-rules'`
- PASS: `.flywheel/receipts/flywheel-rdqc7.1/l112_probe.sh`
- PASS: fixture dry-run proved `--l-rules L2` reports selected missing `L2`, all missing `L2,L3`, unselected `L3`, and no state update.
- PASS: fixture apply proved `--l-rules L2` appended only L2 to both doctrine surfaces and did not write `doctrine_version`.
- PASS: fixture apply proved a final `--l-rules L3` wave updates state once all canonical missing rules are covered.
- PASS: fixture invalid `--l-rules L99` exited 4 with `l_rule_not_in_canonical:L99`.

## Socraticode

- socraticode_queries=10
- indexed_chunks_observed=1578

## Skill Routes

- canonical-cli-scoping=yes: checklist addressed for this flag extension; existing full canonical CLI debt remains tracked by `flywheel-ynys`.
- rust-best-practices=n/a: no Rust touched.
- python-best-practices=n/a: embedded Python was modified inside a shell CLI, but no standalone Python module/public API was added.
- readme-writing=n/a: no README/public-doc change requested; help text documents the new flag.

## Observed Gaps

- Existing canonical CLI checker result for `.flywheel/scripts/doctrine-sync.sh`: `Summary: 1 pass, 3 fail`.
- Existing bead `flywheel-ynys` already owns canonical CLI repair for `flywheel-doctrine-sync`; comment 35 records this dispatch's observation.
- DCG blocked one attempted redirected checker-output capture; reran the checker without redirect. Fuckup row class: `dcg-redirect-blocked`.

## Four-Lens Self-Grade

- brand:9 - direct substrate enablement, no product voice/doc claims.
- sniff:9 - scoped mutation, dry-run default preserved, invalid allowlists fail closed.
- jeff:9 - idempotency key gate preserved and partial state stamping avoids false convergence.
- public:9 - skeptical operator can rerun the L112 probe and fixture commands; maintainer sees narrow diff; future worker gets evidence and linked gap bead.
