# CASS Skill Enhancement Patch: append-only audit lineage

Bead: `flywheel-irm9`
Task: `[skill-enhance-cass] adopt Jeff append-only-audit-log into cass`
Target skill: `/Users/josh/.claude/skills/cass/SKILL.md`
Source matrix: `.flywheel/jeff-corpus/v1/learnings/06-skill-enhancement-matrix.md`

## JSM Classification

`cass` is installed in JSM (`installed_skills.name='cass'`, version 5,
`is_jeffreys=1`). `jsm show cass --json` timed out under a 20s safety cap, so
this worker did not mutate the live skill and did not run `jsm push`.

`no_direct_skill_mutation_reason`: JSM-managed skill plus live JSM command
timeout; direct edits would be unmanaged and could be overwritten by `jsm sync`.
This artifact is a `jsm push`-ready patch plan for skillos/JSM review.

## Diff Plan

Preserve existing trigger intent:
- Keep `cass` focused on session archaeology, prompt mining, recovery, and
  agent-history search.
- Do not replace existing bootstrap, recovery, or command examples.
- Add Jeff operational contracts only where they make CASS mutations and
  derived index state safer.

Adopted Jeff clusters/patterns:
- `append-only-audit-and-lineage`: require append-only receipts for recovery,
  index rebuilds, source syncs, and analytics rebuilds.
- `doctor-health-repair-triad`: make health/status/doctor/repair semantics
  explicit before mutation.
- `schema-versioning-and-migrations`: require receipt `schema_version` and
  compatibility notes for CASS-derived artifacts.
- `testing-patterns`: add replay/self-test guidance using existing
  `scripts/validate.sh`.
- `frontmatter-validation`: add a required `license` frontmatter key before
  upstream push.

Before score: `84` from the Jeff enhancement matrix.
After expected score: `94` if the patch lands and `scripts/validate.sh` passes.

## Push-Ready Patch

```diff
diff --git a/skills/cass/SKILL.md b/skills/cass/SKILL.md
--- a/skills/cass/SKILL.md
+++ b/skills/cass/SKILL.md
@@
 name: cass
+license: internal
 description: >-
   Mine past agent sessions for working prompts, decisions, and patterns. Use when
   "what did I ask?", "find that prompt", session archaeology, or agent history.
@@
 - [Workspace Scoping Audit](#workspace-scoping-audit)
+- [Jeff Audit & Lineage Addendum](#jeff-audit--lineage-addendum)
 - [Stuck-Index & Recovery Decision Tree](#stuck-index--recovery-decision-tree)
@@
 ## Workspace Scoping Audit
 
 Audit date: 2026-05-08, bead `flywheel-9f7h6`.
 
 The CASS skill already scopes searches with exact `--workspace <abs-path>`
 examples. Keep those paths physical and absolute, preferably from `pwd -P`,
 and do not derive memory, cache, or project keys from repo basename alone.
 This mirrors Jeff ntm#132: same-basename workspaces must not share context.
+
+## Jeff Audit & Lineage Addendum
+
+CASS is a search substrate, but `cass index`, `cass doctor --fix`,
+`cass sources sync`, and `cass analytics rebuild` mutate derived state. Treat
+those as recoverable mutations, not casual setup commands.
+
+### Append-only audit receipt
+
+Every CASS repair, rebuild, remote source sync, or analytics rebuild should emit
+or save an append-only receipt before the next human-facing summary:
+
+```json
+{
+  "schema_version": "cass-audit-receipt/v1",
+  "ts": "2026-05-08T00:00:00Z",
+  "actor": "agent-or-human",
+  "workspace": "/abs/path-or-null",
+  "command": "cass doctor --fix --json",
+  "mode": "doctor_fix|index_rebuild|source_sync|analytics_rebuild|search_only",
+  "mutation": true,
+  "pre_state": {"healthy": false, "index_fresh": false, "documents": 0},
+  "post_state": {"healthy": true, "index_fresh": true, "documents": 1234},
+  "backup_path": "/path/to/backup-or-null",
+  "exit_code": 0,
+  "followup": "none|rerun_status|route_repair"
+}
+```
+
+Append receipts to a run-local JSONL such as
+`/tmp/cass-audit-<bead-or-task>.jsonl` or to the project receipt directory when
+a repo has one. Do not rewrite old receipts to make a recovery look clean.
+
+### Doctor / health / repair triad
+
+Before mutation:
+1. `cass status --json` records cheap health and freshness.
+2. `cass doctor --json --verbose` classifies failure rows.
+3. `cass doctor --fix --json` or `cass index --full --force-rebuild --json`
+   runs only after the failure class matches the recovery table above.
+
+Search-only work may continue on a stale-but-usable index, but repair work must
+record the before/after state and exit code.
+
+### Schema and migration compatibility
+
+Any new CASS-derived artifact should carry a stable `schema_version`. When a
+receipt shape changes, consumers must accept the prior version for at least one
+migration window and report unknown fields as WARN, not FAIL, unless source
+session data would be lost.
+
+### Fixture / replay self-test
+
+Before pushing this skill upstream, run:
+
+```bash
+cd /Users/josh/.claude/skills/cass
+bash ./scripts/validate.sh
+cass status --json | jq '{healthy, fresh: .index.fresh, stale: .index.stale}'
+```
+
+For mutation guidance changes, replay at least one dry recovery path into a temp
+receipt file and verify the JSONL is append-only:
+
+```bash
+tmp="/tmp/cass-audit-self-test.$$.jsonl"
+cass status --json > /tmp/cass-status-before.$$.json
+printf '%s\n' '{"schema_version":"cass-audit-receipt/v1","mode":"search_only","mutation":false,"exit_code":0}' >> "$tmp"
+jq -e 'select(.schema_version=="cass-audit-receipt/v1")' "$tmp" >/dev/null
+test "$(wc -l < "$tmp")" -eq 1
+```
```

## Validation / Self-Test Guidance

Validation command for this worker artifact:

```bash
test -f /Users/josh/.claude/skills/cass/SKILL.md
test -f /Users/josh/.claude/skills/cass/scripts/validate.sh
grep -n "## Jeff Audit & Lineage Addendum" .flywheel/PLANS/skill-enhance-cass-append-only-audit-log-2026-05-08.md
grep -n "schema_version.: .cass-audit-receipt/v1" .flywheel/PLANS/skill-enhance-cass-append-only-audit-log-2026-05-08.md
```

Validation result observed by this worker:

```text
artifact_grep=PASS
cass status --json=PASS healthy=true index.fresh=true conversations=32946
bash /Users/josh/.claude/skills/cass/scripts/validate.sh=FAIL
```

The live skill validator failure is not caused by this patch artifact. The
current validator calls `cass status --robot-format json`; the installed
`cass 0.2.0` reports `Could not parse arguments` for that flag, while
`cass status --json` returns healthy state. That compatibility gap is tracked
outside this patch as a dispatch gap.

Validation command for skillos/JSM after applying the patch:

```bash
cd /Users/josh/.claude/skills/cass
bash ./scripts/validate.sh
jsm validate /Users/josh/.claude/skills/cass
```

`jsm push /Users/josh/.claude/skills/cass` should only run from the serialized
JSM mutation lane after validation, DB integrity checks, and ownership review.

## Three-Q Receipt

- Q1 What changed? A push-ready patch adds Jeff audit/lineage, triad,
  schema-version, and fixture-replay guidance to CASS without changing trigger
  intent.
- Q2 How was it validated? Matrix and first 200 CASS lines read; local JSM DB
  proves `cass` is installed; artifact grep/self-test commands pass; direct
  `cass status --json` is healthy; existing validator compatibility gap is
  documented; live skill mutation withheld because JSM command timed out.
- Q3 What remains? skillos/JSM owner applies the patch, runs `bash scripts/validate.sh`
  plus `jsm validate`, then performs serialized `jsm push` if approved.
