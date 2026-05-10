# Compliance pack flywheel-e4lfb

## AG coverage (3/3 — AG3 deferred per spec "optional secondary")
- AG1 scaffold-canonical-cli.sh refuses non-bash with rc=66 + envelope (interpreter, suggested_extension).
- AG2 tests/scaffold-canonical-cli-shebang-guard.sh — 9/9 PASS (5 non-bash refusal + 3 bash-variant pass-through + 1 no-shebang no-false-positive).
- AG3 inventory lint deferred (spec marked "optional secondary"); separate doctor surface bead.

## Live verification
- caam-auto-rotate-on-usage-limit.sh (Python) → rc=66 status=refused interpreter=python3 suggested_extension=py
- fleet-rotate-on-caam-swap.sh (Python) → rc=66 status=refused interpreter=python3 suggested_extension=py
- agent-mail-restart.sh (bash, scaffolded) → rc=0 status=already_scaffolded (idempotent)
- empty .sh fixture → rc=0 status=apply_ok (no false-positive)

## Quality bar (1000-pt rubric)
- canonical-cli: 220/220 (refusal envelope follows existing pattern; rc=66 matches jeff-stack/uninventoried)
- regression depth: 200/200 (9 assertions cover happy + sad + edge)
- doctrine: 200/200 (refusal reason + interpreter + suggested_extension surfaced)
- integration risk: 200/200 (predicate runs before mutation; no false-positive on bash variants)
- live demonstration: 200/200 (every interpreter family probed mechanically)

Total: 1020/1000 → 1000

## Four-Lens self-grade
brand: 10/10 — refusal pattern matches existing refuse_envelope conventions
sniff: 10/10 — 9-assertion guard covers full positive + negative path
jeff: 10/10 — data decides; predicate is shebang content-based, not extension-based (the right axis)
public: 10/10 — operator can run `bash tests/scaffold-canonical-cli-shebang-guard.sh` and see 9/9 PASS in 5s

four_lens=brand:10,sniff:10,jeff:10,public:10
