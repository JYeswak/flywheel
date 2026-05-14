# Context And Model Routing

Flywheel treats context as the budget lever. The expensive mistake is usually
not the model choice by itself; it is sending context the task did not need,
then repeating that context through every retry, tool call, and worker handoff.

This runbook is part of the public operating method. It applies to local
single-agent work, NTM-backed orchestration, and non-NTM workflows run from
Claude, Codex, Gemini, OpenClaw, or a reduced local lane.

## Operating Rules

1. Grep before fetching.
   Use `rg` or an equivalent search first. Fetch the smallest file section that
   explains the symbol, command, fixture, or contract under change.

2. Keep no just-in-case context.
   Do not include files because they might matter. Name what you searched, what
   matched, and which small surfaces were enough.

3. Batch related tool calls.
   Plan the inspection pass, run related reads together, and summarize large
   outputs before feeding them back into the next decision.

4. Preserve prompt-cache-friendly prefixes.
   Stable doctrine, repo maps, and task packets should stay stable. Put volatile
   evidence and command output after the stable prefix, and avoid rewriting the
   stable packet unless the contract changed.

5. Graduate repeated work into SKILL.md patterns.
   If a workflow recurs, capture the steps once so later agents load the method
   instead of rediscovering the environment.

6. Summarize long sessions.
   Compress old execution history into receipts, bead comments, or closeout
   summaries. Continue from evidence, not raw transcript sprawl.

7. Optimize slow surfaces with receipts.
   Long-running gates, classifiers, validators, doctors, and release checks must
   use the profile-first loop before optimization work is accepted: capture a
   baseline timing, save a golden-output behavior proof, change one lever, rerun
   the golden proof, recheck timing, and record the receipt. A faster run without
   behavior proof is not release evidence.

## Routing Tiers

Route by the cost of a wrong answer, not by habit.

| Tier | Use For | Avoid For |
|---|---|---|
| Premium | Architecture, security-critical review, concurrency, irreversible release decisions, destructive operations, cross-system policy choices. | Routine implementation steps that can be checked with tests. |
| Workhorse | Normal implementation, debugging, refactoring, code review, runbook edits, fixture updates, and bounded worker tasks. | Final signoff where a bad decision is expensive. |
| Utility | Lint, format, rename, mechanical copy edits, shellcheck fixes, and single-surface cleanup. | Multi-step design or ambiguous behavior changes. |
| Local | Autocomplete, boilerplate, stubs, syntax nudges, and cheap exploratory drafts. | Work requiring judgment, repo-specific doctrine, or release evidence. |

No static model price table belongs in this repo. Provider pricing, context
windows, model IDs, caching behavior, and quality tradeoffs change quickly. Keep
the public rule stable: measure the current provider surface, then choose the
lowest tier that can satisfy the acceptance gate.

## NTM Worker Dispatch

NTM can use lower-model workers for bounded routine work when the packet is
explicit. A lower-tier worker packet must include:

- the selected routing tier and reason,
- a maximum context budget or file-count budget,
- the grep before fetching command or search target,
- files or modules the worker owns,
- the exact validation command,
- an escalation trigger for uncertainty, safety, cross-system behavior, or
  failing tests,
- the expected receipt shape.

Do not assign lower-tier workers to architecture signoff, security-critical
review, concurrency diagnosis, publication signoff, destructive operations, or
tasks that load live secrets. Those require premium escalation or direct human
approval according to the surrounding runbook.

## Receipts

A useful routing receipt names:

- what was searched before files were opened,
- which context was included and why,
- which tier did the work,
- where the workflow should become a SKILL.md pattern,
- what validation proved the result.

This makes cost discipline auditable. It also makes the next run cheaper,
because the next agent starts from a verified method instead of rebuilding the
same context.

A useful slow-surface optimization receipt names:

- the baseline command, timing, and hotspot,
- the golden output or checksum used to prove behavior did not change,
- the single optimization lever applied,
- the post-change timing,
- any residual hotspot that should become the next bead.
