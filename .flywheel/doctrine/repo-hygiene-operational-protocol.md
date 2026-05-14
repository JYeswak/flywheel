# Repo Hygiene — Operational Protocol

Canonical 2026-05-14. Repo hygiene is not a periodic manual cleanup — it is an
enforced operational protocol. A repo accreted to 70,602 working-tree files
(~3.4 GB of cruft) around a ~4,000-file real project, and 3,061 regenerable
audit-output files reached git history, before anyone noticed. The fix is not
a one-time sweep; it is the rules below plus the check that runs them.

## The four invariants

**H-1. The shadowing invariant — `git ls-files | git check-ignore` returns 0.**
A tracked file that matches a `.gitignore` rule means the ignore rule is
lying: `git status` hides it, but it still accretes commits. Adding a glob to
`.gitignore` never untracks an already-tracked file — it must be paired with
`git rm --cached`. *Check [M]:* pipe every tracked file through
`git check-ignore`; non-empty output is a FAIL.

**H-2. Output directories are gitignored at creation, not at discovery.**
If a process *generates* a directory of files — audit output, extraction
output, compliance reports, build artifacts, per-bead JSON — that directory is
added to `.gitignore` in the same change that writes the process. Not 3,061
files later. The author of the generator owns the ignore rule. *Check [M]:* no
tracked directory is >200 files of generated output (JSON/CSV/MD matching an
output-naming pattern) without an explicit `keep-tracked` marker.

**H-3. Every accreting surface declares a retention policy at creation.**
Any directory that grows unbounded — `.flywheel/extraction/`, `.flywheel/audit/`,
`.beads/` sidecars, `.git-archive/`, `.flywheel/reports/`, `.flywheel/summaries/`,
`/tmp/*` sandboxes — carries a retention policy when it is first created: a max
age, a max size, or a cron/launchd prune. "We'll clean it later" is how
`.flywheel/extraction/` reached 1.3 GB. *Check [M]:* every directory on the
accreting-surface register has a retention marker; flag working-tree size over
threshold.

**H-4. Substrate is rebuildable, not precious.** `beads.db`, `node_modules/`,
extraction output, audit output, `.git-archive/` contents — all regenerable
from a source of truth (`issues.jsonl`, lockfiles, the generators). They never
enter git; they are pruned freely; losing them costs a rebuild, not work.
Treat them accordingly — do not hoard them "just in case."

## The accreting-surface register

These directories accrete and are governed by H-3. Each must carry a retention
policy. (As of 2026-05-14, retention policies are still TODO — see the wiring
section.)

| Surface | Class | Source of truth | Retention |
|---|---|---|---|
| `.flywheel/extraction/` | skill output | the extraction generators | TODO — size cap |
| `.flywheel/audit/` | skill output | audit generators | TODO — age cap |
| `.flywheel/reports/` | tick output | the tick loop | TODO — age cap |
| `.flywheel/summaries/` | session output | session close | TODO — age cap |
| `.beads/` sidecars/backups | substrate | `issues.jsonl` | TODO — keep last N |
| `.git-archive/` | sediment | git history | TODO — delete-on-prune |
| `node_modules/` (all) | build deps | lockfiles | n/a — gitignored, prune anytime |
| `/tmp/*` sandboxes | scratch | n/a | TODO — launchd prune |

## The enforcement — `scripts/repo-hygiene-check.sh`

The invariants are only real if a check runs them. `repo-hygiene-check.sh`
emits a machine-readable verdict (`pass`/`warn`/`fail`) for H-1..H-4 and is
wired into the flywheel tick/loop so accretion is caught at the tick, not at
the next 70k-file surprise. `fail` (H-1 or H-2 breach) blocks; `warn` (H-3/H-4
thresholds) surfaces as debt.

## Wiring status — what is done, what is next

Done 2026-05-14:
- `.flywheel/audit/` gitignored + `git rm --cached` (3,061 files untracked) —
  H-1 and H-2 restored for that surface.
- This protocol committed as doctrine.
- `scripts/repo-hygiene-check.sh` — implements the H-1..H-4 checks.
- `scripts/repo-hygiene-prune.sh` — the H-3 retention enforcement tool. Safe
  by construction: allowlist-only, never deletes a git-tracked file, dry-run
  by default. First run freed ~2.75 GB (node_modules, `.flywheel/extraction`,
  `.git-archive` contents). Hygiene check now 4/4 pass.

Next (the remaining "wired in" work):
1. Wire `repo-hygiene-check.sh` into the flywheel tick/loop (alongside the
   other gates) so accretion is caught at the tick.
2. Schedule `repo-hygiene-prune.sh` on a cadence (launchd/cron) so the
   accreting surfaces are pruned automatically, not manually.
3. Fill the Retention column of the accreting-surface register with each
   surface's policy (max age / max size / keep-last-N).
4. Connect to the `bszgl` git-hygiene enforcement beads — those were designed
   to enforce exactly this and never shipped; this protocol is their spec.

## Relationship to git-repo-janitor

The `git-repo-janitor` skill is the *remediation* tool — run it when hygiene
has already decayed (recovery-bundle + verbatim authorization before any
destructive op). This protocol is the *prevention* layer: H-1..H-4 plus the
tick check keep the repo from decaying in the first place. Prevention is
cheap; remediation is a multi-phase orchestrated run. Lean on prevention.
