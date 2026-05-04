# Phase 5 POLISH r1 — adversarial review

## Verdict
NEEDS_REWORK

The plan is directionally correct and the bead graph is close, but it should not dispatch Wave 1 as written. The highest-risk hook path depends on a prompt source I could not verify (`CLAUDE_USER_PROMPT`) while existing Claude Code hooks in this environment consume stdin JSON `.prompt`; that is enough to make the capture hook either silently miss requests or break user input. The F3 secret scrub mitigation is also materially incomplete for common token formats, and the cross-session propagation claim does not match the current doctrine-sync hook trigger. Fix those before worker dispatch; the rest can ship as bead-body tightening.

## Findings (per focus area, severity-ranked)

### 1. Schema completeness
- HIGH: The entry schema is not yet strong enough for a six-month audit. Add stable provenance and lifecycle fields: `captured_at`, `source_session`, `source_pane`, `transcript_path`, `source_message_id` or `prompt_hash`, `request_text_hash`, `owner`, `priority`, `scope`, `last_updated_at`, `closure_actor`, `duplicate_of`, and `supersedes`.
- MEDIUM: `open` is doing too much work. The plan already has `inferred_action=PENDING_ORCH_INTERPRETATION`; that needs a lifecycle state such as `needs_triage` or `captured` before `acknowledged`.
- MEDIUM: `in_progress` has no way to distinguish active work from blocked/waiting. Add `blocked` or `waiting_on_external` so stale checks do not treat legitimate blocked work as forgotten.
- HIGH: `closure_evidence` must be typed, not free text. Require one of `bead_closed:<id>`, `commit:<sha>`, `dispatch_log:<task_id|line>`, `transcript:<path#message_id>`, or `joshua_confirmed:<quote_hash>`.

### 2. Hook architecture
- BLOCKER: Existing UserPromptSubmit hooks in `/Users/josh/.claude/hooks/` read stdin JSON and extract `.prompt`. I found no local evidence that `CLAUDE_USER_PROMPT` is surfaced by the Claude Code harness. The hook bead must require `input="$(cat)"` plus `jq -r '.prompt // empty'`, with env/argv only as fallback.
- BLOCKER: The proposed `set -euo pipefail` shape is fail-dangerous for a UserPromptSubmit hook. Capture failures must log and exit 0, emitting `{}` or another no-op response so user input continues.
- HIGH: Multi-line prompts need deterministic handling. Scrub before truncation, preserve a hash of the normalized original, and write JSON through `jq -n --arg ...` rather than shell interpolation. Markdown excerpts need escaping or fenced formatting.
- HIGH: The F3 scrub list is incomplete. Explicit test cases should include:
  - AWS access keys: `AKIA[0-9A-Z]{16}`, `ASIA[0-9A-Z]{16}`
  - GitHub tokens: `ghp_`, `gho_`, `ghu_`, `ghs_`, `ghr_`, `github_pat_`
  - Anthropic: `sk-ant-...`
  - OpenAI: `sk-...`, `sk-proj-...`
  - JWT: `eyJ...`.`...`.`...`
  - Bearer tokens: `Authorization: Bearer ...`
  - Google API keys: `AIza...`
  - Slack tokens: `xoxb-`, `xoxa-`, `xoxp-`, `xoxr-`, `xoxs-`
  - Private key blocks: `-----BEGIN ... PRIVATE KEY-----`
  - Agent Mail token fields: `registration_token=...`, `sender_token=...`
  - Long base64/base64url or hex strings when preceded by `token`, `secret`, `key`, `password`, or `authorization`
- HIGH: The plan should include a negative test proving non-secret Joshua requests are not over-scrubbed into unusable excerpts.

### 3. Cross-session propagation
- BLOCKER: `/Users/josh/.claude/hooks/flywheel-doctrine-sync-post-edit.sh` currently fires only when `/Users/josh/Developer/flywheel/AGENTS.md` is edited. It does not fire on `templates/josh-request-schema.md` or MISSION schema edits. The propagation bead must update the hook matcher or call the sync binary explicitly.
- HIGH: The active fleet roster is six repos, but the canonical member is `terratitle`, not `terra-title`. Use `/Users/josh/.local/state/flywheel/fleet-roster.json` as source of truth instead of a hardcoded list.
- LOW: Stamp ordering is not functionally important, but deterministic ordering matters for audit diffs. Sort by roster `name` and record per-repo result.

### 4. Tick-path consumer ordering
- HIGH: `00-PLAN.md` only says the request consumer is a sibling of doctor-signal and other tick helpers. It should run first, before doctor-signal, plan-to-bead, doctrine-ladder, and Jeff-response watchers, so human-originated requests are visible at the top of the tick prompt and can affect selection.
- MEDIUM: Auto-beading after two hours needs duplicate protection against already-linked beads, closed beads with live follow-up, and requests marked `deferred` or `wont_do`.
- MEDIUM: The tick prompt should show request state and evidence link, not only an excerpt, or the selector will still need transcript archaeology.

### 5. CLI helper edge cases
- HIGH: `josh-requests close --evidence` is too permissive. "Joshua said forget it" is valid only for `--status=wont_do` or `--status=deferred`, and should require transcript path/message id or a quote hash.
- MEDIUM: `josh-requests stale --hours=24` should default from repo config, with `--hours` as an override. Session cadences differ.
- HIGH: `josh-requests backfill --transcript=<path>` needs a canonical discovery path. Support `--repo`, discover Claude project JSONL transcripts for that cwd/session, and accept explicit paths for replay.

### 6. Anti-patterns in the plan itself
- MEDIUM: F4's "Periodic Joshua-side audit" risks reintroducing human vigilance as the backstop. It should be auto-surfaced in the tick and status dashboard; Joshua confirmation should only be required for `wont_do` or ambiguous closure.
- HIGH: The plan is Claude-hook-centric while the stated problem is cross-session. It needs either an explicit "Claude Code only in this wave" boundary or capture adapters for Codex/web/shell orchestrators.
- MEDIUM: Wave 2 says three beads but lists four (`l6j2`, `2ps2`, `j9fq`, `cg9w`). More importantly, hook registration must happen after the hook is tested in dry-run mode.
- MEDIUM: The plan references a missing skill but has no final bead for skillos handoff. The preliminary DAG includes an `ANN` node, but the 15 filed beads do not.

### 7. Bead body quality
- MEDIUM: Several bead bodies have good titles and dependency wiring, but the acceptance gates lean on "DOD: COMMIT" rather than executable checks. The security and hook beads especially need concrete test matrices before dispatch.

### 8. Skill-handoff completeness
- HIGH: The plan identifies a reusable missing skill (`human-operator-input-channel-capture` / `josh-request-capture`) but does not include a handoff bead to skillos. Add a final documentation/handoff bead or explicitly declare no skill artifact in this wave.

## Bead body sample audit
- `flywheel-7elw`: CAVEAT. Good doctrine target and cost citation intent, but acceptance is weak. Require a structured INCIDENTS entry with trauma class, Forever-Rule, cost citation, mechanism, evidence link, and L56 linkage.
- `flywheel-2ps2`: PASS WITH CAVEAT. Acceptance is mostly testable, but editing MISSION while preserving `lock_hash` needs a lock-log/probe compatibility check, not just "hash unchanged."
- `flywheel-j9fq`: FAIL AS WRITTEN. "JSONL with head comment" conflicts with "jq-parseable." JSONL should remain pure JSON lines; put schema comments in a sidecar or template, not the data file.

## Recommended bead updates

```bash
br update flywheel-l6j2 --description "Implement UserPromptSubmit hook using stdin JSON .prompt as canonical input; env/argv are fallback only. Hook must scrub before truncation, write JSON with jq, handle multi-line prompts, log failures, and always exit 0/no-op on internal errors. Acceptance: fixture tests cover multi-line prompt, empty prompt, malformed stdin, write failure, and secret scrub cases for AWS AKIA/ASIA, GitHub ghp/gho/ghu/ghs/ghr/github_pat, Anthropic sk-ant, OpenAI sk/sk-proj, JWT, Bearer, Google AIza, Slack xox*, private-key blocks, Agent Mail token fields, and context-sensitive base64/hex secrets."
```

```bash
br update flywheel-wroj --description "Define schema with audit-grade provenance: id, captured_at, source_session, source_pane, transcript_path, source_message_id or prompt_hash, request_text_hash, sanitized_excerpt, inferred_action, owner, priority, scope, state, stale_after, linked_bead_ids, duplicate_of, supersedes, last_updated_at, closure_actor, and typed closure_evidence. States must include needs_triage/captured, acknowledged, in_progress, blocked or waiting_on_external, done, deferred, wont_do."
```

```bash
br update flywheel-cg9w --description "Update doctrine-sync propagation to match actual hook behavior. Current PostToolUse hook only fires on /Users/josh/Developer/flywheel/AGENTS.md; extend matcher or explicitly invoke flywheel-doctrine-sync for josh-request schema/template changes. Use ~/.local/state/flywheel/fleet-roster.json as source of truth, sort by roster name, and verify terratitle path."
```

```bash
br update flywheel-j9fq --description "Initialize pure JSONL data file with no comments. Put schema documentation in templates or a sidecar. Acceptance: empty file parse path succeeds, populated JSONL validates line-by-line with jq, concurrent append test passes, permissions are correct, and malformed-line recovery behavior is documented."
```

```bash
br update flywheel-iaak --description "Tighten CLI semantics: close requires typed evidence; wont_do/deferred require transcript reference or quote hash for Joshua-originated cancellation; stale default comes from repo config with --hours override; backfill supports --repo transcript discovery plus explicit --transcript path."
```

```bash
br update flywheel-2ps2 --description "Add acceptance gate proving MISSION update is compatible with mission lock doctrine: lock_hash behavior understood, lock-log row/probe result recorded if required, and mission-anchor-init validation passes after adding the Joshua Requests section."
```

```bash
br update flywheel-7elw --description "Require INCIDENTS entry to include trauma_class=joshua-request-forgotten, Forever-Rule, cost citation, mechanism, at least one evidence link to this plan/bead set or fuckup-log row, and L56 promotion-ladder placement."
```

```bash
br create "[josh-req-16] handoff josh-request-capture skill to skillos" --type task --priority 1 --description "Create the skillos handoff for the reusable josh-request-capture / human-operator-input-channel-capture skill. Include plan path, shipped hook/CLI/tick artifacts, test matrix, and open gaps. Blocks final plan closeout if this wave claims a skill deliverable."
```

## Recommendation
- Wave 1 ship-go/no-go: NO-GO until `flywheel-l6j2`, `flywheel-wroj`, and `flywheel-cg9w` are revised.
- Pre-ship blockers: verify prompt source via stdin JSON `.prompt`; make hook fail-safe; expand F3 scrub matrix; fix doctrine-sync trigger mismatch; use fleet roster source of truth; remove JSONL comment conflict.
- After those revisions: Wave 1 can dispatch with caveats, but register the hook only after dry-run fixture tests pass.
