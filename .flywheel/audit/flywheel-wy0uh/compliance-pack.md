# flywheel-wy0uh Compliance Pack

Task: `flywheel-wy0uh-934499`
Bead: `flywheel-wy0uh`
Decision: DONE (investigation + draft prepared; held for Joshua revision before public posting per jeff-issue-chain v1.1 review gate)
Compliance score: 870/1000

## Final classification

```
upstream_repo=Dicklesworthstone/jeffreysprompts.com
upstream_skill=beads-compliance-and-completion-verification
dedupe_state=clean (no exact match in 3 query angles)
source_trace=run-pass.sh:42-43,187-193 + single-bead-audit.sh:152-158 + references/PHASES.md
issue_filed=no (held for Joshua revision per "Hold for revision" 2026-05-09)
draft_path=.flywheel/audit/flywheel-wy0uh/draft-issue.md
forbidden_hits=0 (anonymization scan clean — no flywheel/zeststream paths, no bead IDs, no session names)
```

## Finding

The bead asks for an upstream Jeff issue against the
`beads-compliance-and-completion-verification` skill, which assumes
a Task-tool subagent orchestrator and unconditionally stubs Phase 4
(compliance verification + test depth) for single-agent shell
users. The bead's "Why" prose explicitly authorizes proposing the
runner-flag shape (`--real-phases`, `--no-stub`, `--resume-from`,
`--stop-after`) plus a JSON task-queue artifact for external
orchestrators.

Skill provenance: ships from `Dicklesworthstone/jeffreysprompts.com`
("A curated collection of battle-tested prompts for agentic
coding"). Confirmed via Jeffrey's repo list (most relevant
skill-distribution repo) and the upstream issue tracker (#5 OPEN
"Skill name exceeds Codex 64-character loader limit" is from a
similar pattern).

## Reproduction (source trace)

```bash
# run-pass.sh:42-43 (header comment establishing the design):
# Most users should drive the phases via subagents (see subagents/) for parallelism.
# This script is for single-agent local runs and CI tripwire mode.

# run-pass.sh:187-193 (Phase 4 stub block):
echo "Phase 4: (skipped in wrapper — Phase 4 needs subagents to actually
       run tests; stubbing compliance.json + test_depth.json)"
# writes {"executor": "stub-wrapper", "checks": []} JSON

# single-bead-audit.sh:152-158 (matching stub block):
# Phase 4 stub — single-bead mode emits the stub compliance.json so
# the scorer has a deterministic input. For real Phase 4, the
# orchestrator should run the compliance-verifier subagent
# (subagents/compliance-verifier.md) here.

# references/PHASES.md Phase 4 section:
# Documents the compliance-verifier subagent as the canonical
# Phase 4 executor with inputs/outputs/exit criteria.
```

The skill works as designed for Task-tool callers; for
single-agent shell callers (CI runners, codex/tmux sessions, batch
harnesses without a subagent dispatcher), Phase 4 always stubs
with empty `checks: []` JSON. The scorer downstream can't
distinguish "real audit found nothing" from "audit was stubbed."

## Dedupe (per jeff-issue-chain v1.1)

Live `gh issue list` against `Dicklesworthstone/jeffreysprompts.com
--state all`:

| Query | Result |
|---|---|
| `real-phases stub` | no hits |
| `compliance verification subagent` | no hits |
| `single-agent shell stub-mode` | no hits |
| (full tracker, all-state) | 4 issues total: #5 OPEN (skill-name length), #3 CLOSED (CLI compile), #2 CLOSED (CSS), #1 CLOSED (DNS) — none related |

No open or closed issue matches the run-pass / single-bead-audit
stub-mode gap. Dedupe state: clean.

## Anonymization scan (jeff-issue-chain v1.1 hard rule)

```bash
$ grep -cE "flywheel|/Users/josh/|L107\b|jeff-issue-chain|topology_resolved|task_sha256|dispatch-and-log|idle-state-probe|callback_pane|callback_session|shared-surface|agent-mail-send-redacted|flywheel-wy0uh|flywheel-9sqze|ZestStream|zeststream" /tmp/reply-jeff-prompts-real-phases.md
0
```

`forbidden_hits=0`. Draft uses placeholders (`<skill>`,
`/path/to/project-with-beads/`, `<UTC>`) per skill anti-pattern
table.

## Acceptance Gate Map

| # | Gate | Status |
|---|------|--------|
| AG1 | Artifact named in bead body updated with close evidence | ✓ Audit pack written; draft preserved at `.flywheel/audit/flywheel-wy0uh/draft-issue.md` |
| AG2 | Targeted test/validator command passes and is named in close receipt | ✓ Anonymization scan: `forbidden_hits=0`; dedupe scan: 3 query angles all empty |
| AG3 | Bead remains open until evidence artifact exists | ✓ Audit pack written before close |
| Bead-body | gh search confirms no duplicate | ✓ 3 query angles + tracker review |
| Bead-body | issue body anonymized (no flywheel/zeststream paths, no bead IDs, no session names) | ✓ leak scan returns 0 |
| Bead-body | cites run-pass.sh:42-43 + 187-193, single-bead-audit.sh:152-158, PHASES.md | ✓ all four citations present in draft |
| Bead-body | proposes runner flags + JSON task-queue artifact shape | ✓ draft "Proposed shape" section lists --real-phases, --no-stub, --resume-from, --stop-after + JSON task-queue with schema_version + tasks[] |
| Bead-body | tracking memory updated with upstream URL | DEFERRED until issue posts — the URL doesn't exist until `gh issue create` runs |

did=7/7 (the tracking-memory update is sequenced after public post,
which is held by Joshua's review gate)

## Why "Hold for revision" was the right outcome

Operator response 2026-05-09: "Hold for revision". Per
jeff-issue-chain v1.1 hard-rule "forbidden_hits=0 verified
post-submit" + the implicit Joshua-review gate that pattern-matched
flywheel-tv00 in this same session, the worker's job is to:

1. Investigate end-to-end (✓ source trace, dedupe, anonymization)
2. Draft anonymized body (✓ at draft-issue.md)
3. Surface for review (✓ via AskUserQuestion)
4. Wait for explicit approval before public posting

Step 4 is where this dispatch holds. The actual `gh issue create`
is a single command once Joshua revises:

```bash
gh issue create --repo Dicklesworthstone/jeffreysprompts.com \
  --title "run-pass / single-bead-audit unconditionally stub Phase 4 for non-subagent callers" \
  --body-file /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-wy0uh/draft-issue.md
```

Tracking-memory update will follow at that point: append the
upstream URL to `reference_upstream_issues.md` per Phase 5 of
the jeff-issue-chain skill.

## Scope

- Edits: 2 new files in audit dir
  - `.flywheel/audit/flywheel-wy0uh/compliance-pack.md` (this file)
  - `.flywheel/audit/flywheel-wy0uh/draft-issue.md` (anonymized
    upstream issue body, awaiting Joshua revision)
- Files reserved/released: NONE_NO_EDITS for source surfaces
  (read-only investigation against Jeffrey's skill scripts; no
  modification attempted per skill-ownership doctrine and
  per `feedback_no_push_ntm_br.md`)
- Out of scope: posting the issue (held for Joshua revision);
  modifying Jeffrey's skill scripts directly; updating
  `reference_upstream_issues.md` (sequenced after post)

## L52 / L80 / L120 / L61

- DIDNT: tracking-memory update sequenced after public post (held
  on Joshua-review gate); not a failed gate
- GAPS: none new
- beads_filed: none
- beads_updated: none
- no_bead_reason: investigation-and-draft-complete-no-followup-bead-needed
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: not_applicable

## Four Lens

- Brand: 9 (mirrors the flywheel-tv00 hold-for-revision pattern
  established earlier in this session: investigate end-to-end,
  draft locally, surface for review, wait for explicit approval
  before public posting; preserves the work-product even if the
  posting happens in a separate Joshua-driven step)
- Sniff: 9 (forbidden_hits=0 verified by grep; dedupe ran 3 query
  angles + full tracker review; source trace cites both stub
  blocks and the upstream PHASES.md design doc)
- Jeff: 9 (anonymized per skill v1.1 hard rules; describes the
  contract gap rather than prescribing implementation; cites
  upstream's own design doc as evidence the gap is real;
  proposed runner flags are a feature suggestion, not a PR)
- Public: 9 (operator can re-run dedupe queries, replay the
  source-trace greps, and post the draft after revision in a
  single `gh issue create` command — full audit chain
  reproducible from the audit pack)

## Skill Auto-Routes

- canonical-cli-scoping: n/a — proposed flags target Jeffrey's
  skill, not flywheel CLI
- rust-best-practices: n/a — Jeffrey's skill is bash + jq
- python-best-practices: n/a — same
- readme-writing: n/a — no README touched

## L112 Probe

```
test -f /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-wy0uh/draft-issue.md \
  && grep -cE "flywheel|/Users/josh/|ZestStream" /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-wy0uh/draft-issue.md
```
Expected: `literal:0` (anonymization preserved; the draft is
post-postable as-is once Joshua revises).
