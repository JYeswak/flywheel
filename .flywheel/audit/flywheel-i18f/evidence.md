# flywheel-i18f evidence

Task: flywheel-i18f-02f015
Bead: flywheel-i18f
Status: DONE-ready

## Acceptance

- PASS: `INCIDENTS.md` `orchestrator-substrate-blindness` breadth-first substrate inventory now includes `~/.config/ru/config`.
- PASS: The same checklist now includes `~/.config/ru/repos.d/*.txt`.
- PASS: The update is inline in the existing incident entry and scoped to the config-files inventory item.
- WARN: `/tmp/ru_path_drift_audit.md` was not present during execution; the bead body itself named the required RU paths and section intent.

## Verification

- PASS: `rg -n "RU-backed|~/.config/ru/config|~/.config/ru/repos.d/\\*\\.txt" INCIDENTS.md`
- PASS: `bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-i18f-02f015.md`
- PASS: `br dep tree flywheel-i18f`

## Four-Lens Self-Grade

- brand: 8 — localized doctrine update improves operator substrate inventory without broad rewrite.
- sniff: 9 — exact paths are present, auditable, and tied to the existing breadth-first rule.
- jeff: 8 — future multi-repo investigations now include RU truth before absence/path-drift claims.
- public: 8 — skeptical operator, maintainer, and future worker can verify the line with one grep and understand when it applies.

## Compliance pack

- socraticode_queries: 1
- indexed_chunks_observed: 10
- skill_auto_routes_addressed: canonical-cli-scoping=n/a, rust-best-practices=n/a, python-best-practices=n/a, readme-writing=n/a
- skill_discoveries: 0
- beads_filed: none
- beads_updated: flywheel-i18f
- no_bead_reason: no new gap; existing bead closed
- agents_md_updated: no
- readme_updated: no
- no_touch_reason: packet scope limited to inline `INCIDENTS.md` update; no AGENTS/README landing requested or allowed by file discipline
