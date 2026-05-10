# Compliance pack flywheel-b2zpg

## AG coverage
- AG1 .flywheel/scripts/codex-death-event-classifier.sh — canonical CLI
  (run/doctor/health/repair + validate/audit/why + schema/examples/info/completion);
  H1/H2/H3/H4 taxonomy; idempotent via sha-256 of receipt content;
  files P1 bead for H2, P2 bead for H3.
- AG2 .flywheel/launchd/ai.zeststream.codex-death-classifier.plist — 5-min
  StartInterval, KeepAlive=false, plutil -lint OK.
- AG3 .flywheel/tests/test-codex-death-event-classifier.sh — 8 assertion
  groups (H1/H2/H3/H4 + idempotency + audit/doctor/health/why +
  malformed-receipt + introspection), PASS.
- AG4 .flywheel/doctrine/codex-death-event-flow.md — pipeline diagram,
  hypothesis matrix, decoupling rationale, anti-patterns, bead-filing policy.

## Quality bar (1000-pt rubric self-grade)
- canonical-cli-scoping: 220 / 220 (full triad + subsidiary triad + introspection)
- regression test depth: 200 / 200 (every hypothesis branch + idempotency + malformed)
- doctrine coverage: 190 / 200 (anti-patterns, sister surfaces, no rollout plan since
  launchd not yet loaded — operator step)
- integration risk: 180 / 180 (decoupled from launcher, isolated ledger,
  --no-bead-filing in tests, KeepAlive=false)
- live demonstration: 180 / 200 (doctor against real evidence dir returns
  pending=0 total_receipts=0 since PID 5838 still alive — boundary respected)

Total: 970 / 1000

## Four-Lens self-grade
brand: 9/10 (matches existing plist + script conventions; canonical-cli-scoping)
sniff: 9/10 (sha-keyed idempotency means re-process is mechanically impossible;
  --no-bead-filing covers test isolation; --dry-run blocks ledger writes)
jeff: 9/10 (data decides; the classifier waits for evidence, never watches PID;
  policy table makes priorities deterministic)
public: 9/10 (skeptical operator: yes; maintainer: yes; future worker: yes —
  schema, examples, info answer all "what does this do?" questions)

four_lens=brand:9,sniff:9,jeff:9,public:9
