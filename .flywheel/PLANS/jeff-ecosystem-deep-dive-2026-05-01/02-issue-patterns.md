---
title: "Jeff Ecosystem Deep Dive — 02 Issue Patterns"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Jeff Ecosystem Deep Dive — 02 Issue Patterns

**Snapshot:** 2026-05-01
**Task:** `jeff_eco_pane2`
**Source inventory:** `01-repo-inventory.md` already complete; used its "Hotspot list" ordering.
**Repos audited:** 5
**Issues analyzed:** 146 closed issues from `gh issue list --state closed --limit 30`
**No GitHub issues submitted.**

## Repo Set

Top 5 most-active repos from Output 01, sorted by commit volume:

1. `agentic_coding_flywheel_setup`
2. `asupersync`
3. `beads_rust`
4. `coding_agent_session_search`
5. `destructive_command_guard`

All five are hot-zone repos. Four are directly adopted/evaluating in our stack; `asupersync` is adopted transitively.

## Summary Stats

| Repo | Issues sampled | Median close | Closed ≤24h | Completed | Not planned | Duplicate | Author mix |
|---|---:|---:|---:|---:|---:|---:|---|
| `agentic_coding_flywheel_setup` | 30 | 5.23h | 86.7% | 96.7% | 3.3% | 0% | 23 community, 7 automation |
| `asupersync` | 26 | 5.11h | 88.5% | 100% | 0% | 0% | 26 community |
| `beads_rust` | 30 | 3.79h | 93.3% | 96.7% | 3.3% | 0% | 28 community, 2 Jeff |
| `coding_agent_session_search` | 30 | 9.29h | 80.0% | 100% | 0% | 0% | 30 community |
| `destructive_command_guard` | 30 | 13.84h | 73.3% | 100% | 0% | 0% | 30 community |
| **Overall** | **146** | **6-8h band** | **84.2%** | **98.6%** | **1.4%** | **0%** | 137 community, 7 automation, 2 Jeff |

Notes:
- GitHub `stateReason` values in the sample were only `COMPLETED` and `NOT_PLANNED`; no duplicate state reasons observed.
- `asupersync` returned 26 closed issues, not 30.
- Automation means `app/github-actions`, mostly checksum/update canaries.

## Title Pattern → Close-Time Correlation

| Pattern | Count | Median close | Closed ≤24h | Read |
|---|---:|---:|---:|---|
| bug | 27 | 3.68h | 85.2% | Fastest meaningful category; concrete breakage wins attention. |
| config | 5 | 4.56h | 60.0% | Small sample; config bugs close fast when file/path-specific. |
| other | 56 | 5.95h | 83.9% | Many are precise operational gaps despite generic titles. |
| doc | 8 | 8.37h | 87.5% | Docs gaps still close quickly if tied to user confusion. |
| install | 33 | 8.43h | 81.8% | Install reports are common and actionable when repro is explicit. |
| feat | 17 | 10.34h | 94.1% | Feature-shaped issues close same-day if scoped as a missing primitive. |

Interpretation:
- The issue label/type is less predictive than the body quality. "Sprawling" bodies often closed faster because they included exact repros, logs, environment, and likely cause.
- Bugs/config/install close fastest when the title encodes the failure mode, not a vague symptom.
- Feature requests are accepted when framed as a precise missing capability with bounded expected behavior.

## Body Length Signal

| Body bucket | Count | Median close | Closed ≤24h | Read |
|---|---:|---:|---:|---|
| concise (<400 chars) | 15 | 12.82h | 86.7% | Good for simple cases, but includes withdrawn/no-op items. |
| medium | 40 | 9.55h | 80.0% | Adequate when commands and expected/actual are present. |
| sprawling (>1500 chars) | 91 | 5.25h | 85.7% | Structured evidence-heavy reports get fastest action. |

Doctrine: length is not the problem. Unstructured length is. Jeff appears to reward dense, structured, source-observed reports.

## Author Classification

| Author class | Count | Median close | Closed ≤24h |
|---|---:|---:|---:|
| Jeff (`Dicklesworthstone`, `jeffhaskin`) | 2 | 1.63h | 100% |
| Community | 137 | 7.32h | 83.9% |
| Automation | 7 | 3.20h | 85.7% |

Jeff's own issues close faster in this sample, but `n=2` is too small to infer much. The important signal is that community-filed issues still get same-day treatment: 84% closed within 24h.

## Fastest Community-Filed Completed Issues

Excluded withdrawn/not-planned issue `agentic_coding_flywheel_setup#265` and automation-authored checksum canaries. Top three completed community issues closed in the sampled April window:

### 1. `agentic_coding_flywheel_setup#267` — 0.09h

**Title:** "NTM misclassifies Bun-launched Codex panes as user panes"
**Author:** `jvaug`
**URL:** https://github.com/Dicklesworthstone/agentic_coding_flywheel_setup/issues/267
**Close:** ~5.7 minutes, `COMPLETED`

Pattern:
- Title shape: subsystem + precise wrong classification + triggering runtime wrapper.
- Repro structure: fresh session recreate commands, tmux metadata, captured pane proof, `ntm status --json`, `ntm send --dry-run`, direct pane workaround.
- Source observations: no file:line refs, but strong process-tree/argv observation.
- Proposed patch: yes, at design level: detect agent type from process tree/argv in addition to tmux metadata.
- Prior issue citations: none.

Why it worked:
- It proved the pane was usable Codex while NTM classified it as `user`.
- It supplied both user-visible symptom and likely root cause without demanding a specific patch.

### 2. `agentic_coding_flywheel_setup#261` — 0.17h

**Title:** "apt commands hang: DEBIAN_FRONTEND lost through sudo, needrestart not suppressed"
**Author:** `frantisek-heca`
**URL:** https://github.com/Dicklesworthstone/agentic_coding_flywheel_setup/issues/261
**Close:** 10 minutes, `COMPLETED`

Pattern:
- Title shape: command family + hang + two root causes.
- Repro structure: Problem, Root cause, two numbered sub-causes, Suggested fix, Environment.
- Source observations: yes. Cites `update.sh` line 10, `get_sudo()` line 798, apt command lines 1826/1843/1846, plus absence of `needrestart` handling.
- Proposed patch: yes, with concrete env propagation examples.
- Prior issue citations: yes, cites issue `#254` and explains why its fix was incomplete.

Why it worked:
- It turned a hang into a file-line-bounded diff target.
- It showed prior-fix awareness, avoiding duplicate/redundant framing.

### 3. `agentic_coding_flywheel_setup#266` — 0.25h

**Title:** "Onboard step 5: ntm send fails when CASS is installed but uninitialized"
**Author:** `jvaug`
**URL:** https://github.com/Dicklesworthstone/agentic_coding_flywheel_setup/issues/266
**Close:** ~14.9 minutes, `COMPLETED`

Pattern:
- Title shape: tutorial location + failing command + exact dependency state.
- Repro structure: command, observed failure, investigation, direct failing subprocess, recovery command, expected behavior, possible fixes.
- Source observations: no file:line refs, but includes exact subprocess invocation and health output.
- Proposed patch: yes, multiple ranked options; explicitly notes privacy/runtime tradeoff for silent indexing.
- Prior issue citations: none.

Why it worked:
- It identified the hidden integration edge: "installed" is not "initialized".
- It separated onboarding, runtime fallback, and dependency-status UX as distinct fix surfaces.

## Cross-Repo Pattern Notes

### `agentic_coding_flywheel_setup`

Installer/onboarding bugs close quickly when reports include:
- exact command path (`acfs update`, onboard step number, `ntm send`)
- environment (`Ubuntu 24.04`, Hetzner, version/commit)
- expected/actual split
- likely fix direction but not a giant patch demand

### `beads_rust`

Median close is fastest in the top five. Beads issues that close quickly often frame a data-integrity or workflow invariant rather than "nice-to-have" UX. `beads_rust#238` closed in 0.39h with a title that named the dirty-DB condition and the relative temp-path cause.

### `coding_agent_session_search`

Closes are slower than beads/ACFS but still mostly same-day. Fast issues identify connector-specific path/marker mismatches, e.g. startup rebuild due to missing generation marker or OpenCode connector scanning the wrong location.

### `destructive_command_guard`

Highest median close in the top five, but still 73% within 24h. DCG reports need extra care because false positives/negative command gates affect safety. Best filing shape should include exact command, expected safety classification, observed block/allow, and why a narrower rule preserves safety.

## Doctrine for Our Filings

Top 5 patterns to adopt:

1. **Title = component + failure mode + root-cause hint.**
   Good: `apt commands hang: DEBIAN_FRONTEND lost through sudo, needrestart not suppressed`. Avoid vague "config broken" titles.

2. **Put the repro before the theory.**
   Fast reports show command -> observed output -> expected output -> why this matters.

3. **Use source observations, not source demands.**
   Cite file:line and function names, then say "if correct, this looks like..." rather than insisting on a patch.

4. **Name hidden state transitions.**
   `installed but uninitialized`, `Bun wrapper but Codex child process`, `config hint exists but schema loader rejects it` are the shapes Jeff validates quickly.

5. **Offer bounded fix surfaces.**
   The best reports give 2-4 surfaces: schema, runtime path, CLI status, docs. That lets Jeff choose implementation while preserving the diagnosis.

Anti-patterns to avoid:

- Filing without exact commands and observed output.
- Filing a broad "ecosystem drift" issue without a minimal concrete repro.
- Over-prescribing a full patch when file:line diagnosis is enough.
- Omitting version/commit/environment on install/config/runtime reports.
- Hiding tradeoffs. If a fix has privacy/runtime implications, say so explicitly.

## Comparison: Our ntm Filings

### `ntm#107`

`ntm#107` matches the fast-close style well:
- Summary first, then two deterministic repros.
- Strong source observations: `internal/cli/spawn.go`, `internal/cli/dashboard.go`, `internal/watcher/file_reservation.go`, and Agent Mail reference paths.
- Maintainer response confirmed root cause and closed with commit `5ca8a45` / v1.13.1.
- Time-to-close: about 11.2h, slower than the top-three examples but still same-day and fully validated.

What made it work:
- It found a contract mismatch, not just a symptom.
- It cited both sides of the producer/consumer contract.

### `ntm#111`

`ntm#111` is even closer to the best observed pattern:
- Title names exact surface: `coordinator status ignores [coordinator] config from config.toml`.
- Body has Summary, Why this matters, Environment, Repro, Expected, Actual, Source observations, Workaround.
- Source observations are tentative and defer to maintainer.
- Jeff independently confirmed in the first response, with file:line citations and a three-piece fix plan.

GitHub timestamps show owner validation within roughly 30-45 minutes. This is exactly the target style for future filings.

Delta to improve next time:
- Add one short "minimal fixture" block when possible, so the issue can be reproduced without our local fleet state.
- Keep the "broader drift" claim as a final sweep hypothesis, not in the title.

## Filing Template Recommendation

For future Jeff issues, use this skeleton:

```markdown
## Summary
One sentence describing the invariant violation.

## Why this matters
Concrete operational consequence.

## Environment
- tool version / commit
- OS / shell / relevant runtime

## Repro
Commands, config snippet, and observed output.

## Expected
What the command/config should do.

## Actual
What it does instead.

## Source observations (tentative)
- `path:line-line` — what appears to create the behavior
- `path:line-line` — second side of the contract

## Workaround
Current safe workaround, if any.
```

Keep patch proposals optional. For validated repo-source observations, phrase as "If correct, this looks like..." rather than "change X to Y."

## Artifacts

- Raw issue JSON: `/tmp/jeff_issue_patterns/*.closed.json`
- Analysis rows: `/tmp/jeff_issue_patterns/analysis_rows.json`
- ntm comparison issues: `/tmp/jeff_issue_patterns/ntm-107.json`, `/tmp/jeff_issue_patterns/ntm-111.json`
