---
schema_version: journey-entry/v1
bead_id: flywheel-f0e77
task_id: flywheel-f0e77-85dd21
worker_identity: CloudyMill
ts: 2026-05-10T20:21:48Z
mission_fitness: adjacent
commit_sha: 569ec18
linked_l_rules:
  - L107
  - L52
  - L70
  - L120
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - pre-commit-hook-wire-in
  - hoqq8-trauma-class-defense-layer-3
  - local-core-hooks-path-discovery
  - multi-hook-chain-dispatcher-pattern
---

# flywheel-f0e77 — journey entry

This bead closes the 3-bead-arc that defends the hoqq8 trauma class:
hoqq8 caught the original bug at runtime (test scaffold leak); m12ji
audited the fleet (0 violations); ldp0a added the L9 lint rule; f0e77
wires the lint into pre-commit so the rule actually fires when an
author writes the shape.

Most interesting moment: discovered the host machine had a GLOBAL
`core.hooksPath` set to `~/.config/git/hooks`. My integration test
built an isolated tmp git repo with `.git/hooks/pre-commit` and
exercised `git commit` — and the hook DIDN'T FIRE. The commits
sailed through cleanly even when staged code had L9 violations.

The failing tests said "dirty commit not blocked: rc=0, commits=2 ->
3" — but the hook script wasn't reporting any issue because IT NEVER
RAN. Without the diagnostic `echo "PRE-COMMIT HOOK FIRED"` line I
added during debugging, the test would have passed-and-failed
meaninglessly: the assertion-shape was wrong but my fixture would have
"worked" against any hook chain.

Fix: `git config --local core.hooksPath .git/hooks` in the test
repo construction. The local config wins over global for that repo.
Filed as skill discovery — any future integration test for git hooks
needs this guard.

Second moment: multi-hook chain dispatcher design. The existing
`security-precommit-installer.sh` reads `flywheel.security
PrecommitChain` as a SINGLE script path. Pointing it directly at
`canonical-cli-lint-pre-commit.sh` would lose the slot for
`file-rag-discipline-pre-commit.sh` and anything else. Added
`pre-commit-chain.sh` as a dispatcher: one config slot, N hooks.
Skipped-if-missing semantics keep partial installs from breaking the
whole commit flow.

Third moment: --no-verify policy decision. Operators NEED an escape
hatch. The doctrine question is "how do we audit silent escapes?"
Answer: `git commit --no-verify` leaves a normal git log entry; the
commit SHA + message are in HEAD. A re-run of canonical-cli-lint
against HEAD would catch any L9-violating code that snuck through. So
the bypass is gated by visibility (everyone can see the commit) but
not by approval (no human gate). Matches stash-discipline's halt
threshold which is bypassable by direct git operations — same
operator-escape-with-trail pattern.

The substrate-hygiene-doctrine-cluster now has 3 fully-wired
disciplines: stash-discipline (audit-time + runtime), blocker-
discipline (audit-time + runtime), and canonical-cli-lint (author-
time + runtime via L9 pre-commit). Together they catch substrate
errors at every layer where they can first appear: code-write time,
commit time, tick time. The recursive-self-validation gap the
silent-defer trauma class warned about is now closed at every layer.
