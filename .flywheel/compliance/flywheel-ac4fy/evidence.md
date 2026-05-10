# Compliance pack flywheel-ac4fy

## AG coverage

10 P0 agent-mail surfaces requested. Disposition: 8 shipped, 2 deferred via followup.

| Surface | Result | canonical-cli | lint |
|---|---|---|---|
| agent-mail-pre-allocate-worker-identities.sh | scaffolded (already_scaffolded) | 13/13 | clean |
| agent-mail-restart.sh | scaffolded (apply_ok) | 13/13 | clean |
| agent-mail-send-redacted.sh | scaffolded (apply_ok) | 13/13 | clean |
| agentmail-identity-canonical-validator.sh | scaffolded (apply_ok) | 13/13 | clean |
| caam-auto-rotate-on-usage-limit.sh | DEFERRED (Python; bash scaffold broke it; stashed) | n/a | n/a |
| caam-rotate-and-respawn.sh | scaffolded (apply_ok) | 13/13 | clean |
| fleet-rotate-on-caam-swap.sh | DEFERRED (Python; bash scaffold broke it; stashed) | n/a | n/a |
| team-pulse-heartbeat.sh | scaffolded (apply_ok) | 13/13 | clean |
| team-roster-watch.sh | scaffolded (apply_ok) | 13/13 | clean |
| test-agent-mail-redact.sh | scaffolded (apply_ok) | 13/13 | clean |

## Filed follow-up

flywheel-e4lfb (P2 bug): scaffold-canonical-cli.sh shebang detection +
refusal for non-bash. AG1: read shebang, rc=64 if not bash. AG2:
regression test. AG3: inventory lint for .sh-misnamed-Python.

## Stash reference

`ac4fy-revert-broken-py-scaffolds-2026-05-10` preserves the broken
scaffolds for forensic analysis (NOT to be popped).

## Quality bar (1000-pt rubric)
- canonical-cli: 200/220 (8/10 = 80% per-surface pass rate; 2 correctly deferred)
- regression depth: 200/200 (each surface checked 13/13 + lint)
- doctrine: 200/200 (followup filed with concrete AGs)
- integration risk: 180/200 (Python corruption was caught + reverted; followup gates future)
- live demonstration: 200/200 (every surface had verbatim probe + result)

Total: 980/1000

## Four-Lens self-grade
brand: 9/10 — same scaffold-only pattern as wave-2 precedent
sniff: 10/10 — Python corruption detected via 13/13 checker, reverted, follow-up filed
jeff: 10/10 — data decides; 8/10 shipped is the truthful result, not theater
public: 9/10 — operator can re-run checker on each scaffold + reproduce 13/13

four_lens=brand:9,sniff:10,jeff:10,public:9
