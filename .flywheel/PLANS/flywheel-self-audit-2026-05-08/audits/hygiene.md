# Hygiene Layer Audit - 2026-05-08

Bead: `flywheel-uz7so`

Scope source: `.flywheel/PLANS/flywheel-self-audit-2026-05-08/00-PLAN.md:21-28` defines the 6-section audit contract, and `.flywheel/PLANS/flywheel-self-audit-2026-05-08/00-PLAN.md:32-37` requires Socraticode K=10, source-doc reads, gap cross-reference, lessons, and a compliance pack.

Socraticode survey: 9 K=10 searches against `/Users/josh/Developer/flywheel` for `storage`, `prune`, `residue`, `stash`, `cache`, `snapshot`, `fuckup`, `doctrine-sync`, `watcher-pattern-bank`, and stagger-spawn scheduling. Indexed chunks observed: 1175.

## 1. Inventory

| Surface | Family | Evidence | Notes |
|---|---|---|---|
| `.flywheel/scripts/storage-probe.sh` | storage | `.flywheel/scripts/storage-probe.sh:5`, `.flywheel/scripts/storage-probe.sh:28`, `.flywheel/scripts/storage-probe.sh:47`, `.flywheel/scripts/storage-probe.sh:155`, `.flywheel/scripts/storage-probe.sh:174`, `.flywheel/scripts/storage-probe.sh:206` | Read-only substrate-health probe. Emits disk, stale backup, Qdrant, tmp-dispatch, and live JSON fields. |
| `.flywheel/scripts/storage-prune.sh` | storage | `.flywheel/scripts/storage-prune.sh:14`, `.flywheel/scripts/storage-prune.sh:26`, `.flywheel/scripts/storage-prune.sh:39`, `.flywheel/scripts/storage-prune.sh:61`, `.flywheel/scripts/storage-prune.sh:90`, `.flywheel/scripts/storage-prune.sh:106`, `.flywheel/scripts/storage-prune.sh:174` | Dry-run default pruning primitive. Covers stale backups, tmp dispatch artifacts, sidecars, recovery archives, corpus projections; apply requires idempotency key. |
| `.flywheel/scripts/storage-headroom-watcher.sh` | storage | `.flywheel/scripts/storage-headroom-watcher.sh:5`, `.flywheel/scripts/storage-headroom-watcher.sh:35`, `.flywheel/scripts/storage-headroom-watcher.sh:95`, `.flywheel/scripts/storage-headroom-watcher.sh:141`, `.flywheel/scripts/storage-headroom-watcher.sh:480`, `.flywheel/scripts/storage-headroom-watcher.sh:502`, `.flywheel/scripts/storage-headroom-watcher.sh:546` | Tick/doctor-facing headroom controller. Records ledger rows and logs `storage-headroom-prune-exhausted` fuckups when apply cannot restore buffer. |
| `.flywheel/scripts/tick-driver-manifest.json` storage entries | storage scheduled job | `.flywheel/scripts/tick-driver-manifest.json:1`, `.flywheel/scripts/tick-driver-manifest.json:10`, `.flywheel/scripts/tick-driver-manifest.json:16` | Scheduled tick primitives include storage headroom watcher and storage prune with explicit idempotency key. |
| `.flywheel/scripts/private-tmp-prune.sh` | storage/residue | `.flywheel/scripts/private-tmp-prune.sh:4`, `.flywheel/scripts/private-tmp-prune.sh:12`, `.flywheel/scripts/private-tmp-prune.sh:20`, `.flywheel/scripts/private-tmp-prune.sh:36`, `.flywheel/scripts/private-tmp-prune.sh:39`, `.flywheel/scripts/private-tmp-prune.sh:53`, `.flywheel/scripts/private-tmp-prune.sh:66`, `.flywheel/scripts/private-tmp-prune.sh:74` | New reversible `/private/tmp` hygiene primitive. Allowlist-scoped, dry-run default, lsof/age protected, split from generic storage prune by design. |
| `.flywheel/scripts/session-residue-prune.sh` | residue | `.flywheel/scripts/session-residue-prune.sh:4`, `.flywheel/scripts/session-residue-prune.sh:12`, `.flywheel/scripts/session-residue-prune.sh:20`, `.flywheel/scripts/session-residue-prune.sh:57`, `.flywheel/scripts/session-residue-prune.sh:85`, `.flywheel/scripts/session-residue-prune.sh:96`, `.flywheel/scripts/session-residue-prune.sh:143` | Repo-local residue primitive for logs, tmp outputs, and generated audit artifacts. Skips tracked files and requires apply idempotency. |
| `templates/peer-orch-broadcasts/repo-hygiene-prompt-template.md` | repo hygiene | `templates/peer-orch-broadcasts/repo-hygiene-prompt-template.md:1`, `templates/peer-orch-broadcasts/repo-hygiene-prompt-template.md:13`, `templates/peer-orch-broadcasts/repo-hygiene-prompt-template.md:34`, `templates/peer-orch-broadcasts/repo-hygiene-prompt-template.md:61`, `templates/peer-orch-broadcasts/repo-hygiene-prompt-template.md:91`, `templates/peer-orch-broadcasts/repo-hygiene-prompt-template.md:114` | Broadcast prompt for repo-level dry-run hygiene. It references storage-health, dev-cache-janitor, apfs-snapshot-ops, git-stash-janitor, and storage discipline. |
| `templates/flywheel-install/hygiene-targets.schema.json` | repo hygiene | `templates/flywheel-install/hygiene-targets.schema.json:1`, `templates/flywheel-install/hygiene-targets.schema.json:31`, `templates/flywheel-install/hygiene-targets.schema.json:101`, `templates/flywheel-install/hygiene-targets.schema.json:181` | Declarative `.flywheel/hygiene-targets.yaml` schema. Encodes safe-delete contracts, trauma classes, applicable skill enum, and gitignore-gap disposition. |
| `~/.claude/skills/storage-health/SKILL.md` | storage skill | `/Users/josh/.claude/skills/storage-health/SKILL.md:1`, `/Users/josh/.claude/skills/storage-health/SKILL.md:10`, `/Users/josh/.claude/skills/storage-health/SKILL.md:16`, `/Users/josh/.claude/skills/storage-health/SKILL.md:32`, `/Users/josh/.claude/skills/storage-health/SKILL.md:48`, `/Users/josh/.claude/skills/storage-health/SKILL.md:82`, `/Users/josh/.claude/skills/storage-health/SKILL.md:155`, `/Users/josh/.claude/skills/storage-health/SKILL.md:208` | Primary human/agent doctrine for disk pressure. Defines 10% warning, 5% emergency, diagnosis ladder, recovery ladder, and prevention coupling. |
| `~/.claude/skills/dev-cache-janitor/SKILL.md` | cache skill | `/Users/josh/.claude/skills/dev-cache-janitor/SKILL.md:1`, `/Users/josh/.claude/skills/dev-cache-janitor/SKILL.md:10`, `/Users/josh/.claude/skills/dev-cache-janitor/SKILL.md:16`, `/Users/josh/.claude/skills/dev-cache-janitor/SKILL.md:33`, `/Users/josh/.claude/skills/dev-cache-janitor/SKILL.md:52`, `/Users/josh/.claude/skills/dev-cache-janitor/SKILL.md:191` | Cache cleanup doctrine for pnpm/npm/yarn/cargo/pip/docker caches. Gives safe commands and weekly prune pattern. |
| `~/.claude/skills/apfs-snapshot-ops/SKILL.md` | snapshot skill | `/Users/josh/.claude/skills/apfs-snapshot-ops/SKILL.md:1`, `/Users/josh/.claude/skills/apfs-snapshot-ops/SKILL.md:14`, `/Users/josh/.claude/skills/apfs-snapshot-ops/SKILL.md:31`, `/Users/josh/.claude/skills/apfs-snapshot-ops/SKILL.md:45`, `/Users/josh/.claude/skills/apfs-snapshot-ops/SKILL.md:66`, `/Users/josh/.claude/skills/apfs-snapshot-ops/SKILL.md:116`, `/Users/josh/.claude/skills/apfs-snapshot-ops/SKILL.md:132` | APFS local snapshot diagnosis/deletion doctrine. Critical when disk pressure is not explained by repo/cache residue. |
| `~/.claude/skills/git-stash-janitor/SKILL.md` | stash hygiene | `/Users/josh/.claude/skills/git-stash-janitor/SKILL.md:1`, `/Users/josh/.claude/skills/git-stash-janitor/SKILL.md:14`, `/Users/josh/.claude/skills/git-stash-janitor/SKILL.md:26`, `/Users/josh/.claude/skills/git-stash-janitor/SKILL.md:41`, `/Users/josh/.claude/skills/git-stash-janitor/SKILL.md:47`, `/Users/josh/.claude/skills/git-stash-janitor/SKILL.md:74`, `/Users/josh/.claude/skills/git-stash-janitor/SKILL.md:111`, `/Users/josh/.claude/skills/git-stash-janitor/SKILL.md:152`, `/Users/josh/.claude/skills/git-stash-janitor/SKILL.md:210` | Newly wired stash hygiene skill. Requires owner/source-of-truth triage, no pop/drop during concurrent agents, and recovery bundle at `<project-parent>/<basename>-stash-archive-YYYY-MM-DD/`. |
| `.flywheel/scripts/doctrine-sync.sh` | doctrine sync | `.flywheel/scripts/doctrine-sync.sh:11`, `.flywheel/scripts/doctrine-sync.sh:78`, `.flywheel/scripts/doctrine-sync.sh:155`, `.flywheel/scripts/doctrine-sync.sh:191`, `.flywheel/scripts/doctrine-sync.sh:204`, `.flywheel/scripts/doctrine-sync.sh:238` | Repo-local doctrine append/stamp primitive. Dry-run default; apply requires idempotency and target validation. |
| `.flywheel/scripts/sync-canonical-doctrine.sh` | doctrine sync | `.flywheel/scripts/sync-canonical-doctrine.sh:1`, `.flywheel/scripts/sync-canonical-doctrine.sh:20`, `.flywheel/scripts/sync-canonical-doctrine.sh:124`, `.flywheel/scripts/sync-canonical-doctrine.sh:191`, `.flywheel/scripts/sync-canonical-doctrine.sh:223` | Fleet doctrine sync wrapper. Collects targets, backs up before writing, and syncs canonical doctrine surfaces. |
| `~/.flywheel/canonical-meta-rules/sync.sh` | canonical meta-rule sync | `/Users/josh/.flywheel/canonical-meta-rules/sync.sh:1`, `/Users/josh/.flywheel/canonical-meta-rules/sync.sh:16`, `/Users/josh/.flywheel/canonical-meta-rules/sync.sh:57`, `/Users/josh/.flywheel/canonical-meta-rules/sync.sh:106`, `/Users/josh/.flywheel/canonical-meta-rules/sync.sh:140`, `/Users/josh/.flywheel/canonical-meta-rules/sync.sh:209`, `/Users/josh/.flywheel/canonical-meta-rules/sync.sh:251` | Fleet-shared three-surface sync gate. Not under `.flywheel/scripts/`; local docs sometimes call this `canonical-meta-rules-sync`. |
| `.flywheel/scripts/doctrine-drift-trend-probe.sh` | doctrine sync | `.flywheel/scripts/doctrine-drift-trend-probe.sh:4`, `.flywheel/scripts/doctrine-drift-trend-probe.sh:41`, `.flywheel/scripts/doctrine-drift-trend-probe.sh:92`, `.flywheel/scripts/doctrine-drift-trend-probe.sh:123` | Trend probe over canonical-meta-rule drift rows. Converts sync hygiene into trend signal. |
| `.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh` | doctrine sync | `.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh:1`, `.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh:15`, `.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh:41`, `.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh:76` | Fleet freshness skeleton. File itself says it is not yet wired into doctor. |
| `.flywheel/scripts/codex-template-stuck-detector.sh` | fuckup promotion | `.flywheel/scripts/codex-template-stuck-detector.sh:3`, `.flywheel/scripts/codex-template-stuck-detector.sh:15`, `.flywheel/scripts/codex-template-stuck-detector.sh:22`, `.flywheel/scripts/codex-template-stuck-detector.sh:37` | Detector emits ledger/fuckup rows for stuck Codex template classes. Current compact form writes fuckup rows for the input-deaf class. |
| `.flywheel/tests/test-detector-pattern-bank-replay.sh` | watcher/pattern replay | `.flywheel/tests/test-detector-pattern-bank-replay.sh:25`, `.flywheel/tests/test-detector-pattern-bank-replay.sh:40`, `.flywheel/tests/test-detector-pattern-bank-replay.sh:81`, `.flywheel/tests/test-detector-pattern-bank-replay.sh:103`, `.flywheel/tests/test-detector-pattern-bank-replay.sh:134` | Actual pattern-bank-like regression surface. Replays live/golden stuck-detector fixtures and asserts unknown-stable apply writes a fuckup/snapshot. |
| `~/.claude/skills/.flywheel/scripts/agent-mail-identity-audit.sh` | identity hygiene | `/Users/josh/.claude/skills/.flywheel/scripts/agent-mail-identity-audit.sh:1`, `/Users/josh/.claude/skills/.flywheel/scripts/agent-mail-identity-audit.sh:8`, `/Users/josh/.claude/skills/.flywheel/scripts/agent-mail-identity-audit.sh:39`, `/Users/josh/.claude/skills/.flywheel/scripts/agent-mail-identity-audit.sh:55`, `/Users/josh/.claude/skills/.flywheel/scripts/agent-mail-identity-audit.sh:77`, `/Users/josh/.claude/skills/.flywheel/scripts/agent-mail-identity-audit.sh:137` | Agent Mail identity janitor. Audits active/retired/duplicate identities, token files, and emits JSON dashboard line. |
| `.flywheel/scripts/jeff-corpus-storage-projection.{py,sh}` | storage projection | `.flywheel/scripts/storage-prune.sh:39`, `.flywheel/scripts/storage-prune.sh:46`, `.flywheel/scripts/storage-prune.sh:75`, `.flywheel/scripts/storage-prune.sh:98` | Storage-prune treats Jeff corpus projection artifacts as prune candidates. Projection scripts are storage-adjacent hygiene surfaces because stale projections consume repo disk. |

Not found in this working tree:

- `~/.claude/skills/.flywheel/skills/flywheel:storage-prune.md` - the dispatch named it, but filesystem search found no matching file. The operational surface is `.flywheel/scripts/storage-prune.sh`.
- `.flywheel/scripts/canonical-meta-rules-sync.sh` - the canonical executable is `/Users/josh/.flywheel/canonical-meta-rules/sync.sh`, with local wrappers/tests referring to that path.
- `.flywheel/scripts/watcher-pattern-bank.*` - no exact file exists; the closest active surface is `.flywheel/tests/test-detector-pattern-bank-replay.sh`.
- A `repo-hygiene` or `1p9of` skill under `~/.claude/skills/` - the repo-hygiene substrate exists as prompt/schema templates, not as a live skill.

## 2. Load-bearing

| Surface | Why load-bearing | Evidence |
|---|---|---|
| `storage-probe.sh` + `storage-health` | Critical path. Today's storage pressure began around 3% free; below 5% the substrate cannot be trusted for logs, commits, or dispatch writes. | `.flywheel/scripts/storage-probe.sh:5`, `.flywheel/scripts/storage-probe.sh:155`, `/Users/josh/.claude/skills/storage-health/SKILL.md:10`, `/Users/josh/.claude/skills/storage-health/SKILL.md:32`, `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_storage_pressure_blocks_substrate.md:8`, `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_storage_pressure_blocks_substrate.md:19` |
| `storage-prune.sh` | Critical path and >=3 callsites by plan/tick/skill/test references. It is the only general, idempotent repo storage apply primitive in scope. | `.flywheel/scripts/storage-prune.sh:14`, `.flywheel/scripts/storage-prune.sh:90`, `.flywheel/scripts/storage-prune.sh:106`, `.flywheel/scripts/storage-prune.sh:174`, `.flywheel/scripts/tick-driver-manifest.json:16`, `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_storage_pressure_blocks_substrate.md:26` |
| `storage-headroom-watcher.sh` | Critical path. It turns storage probe/prune into scheduled loop behavior and creates durable ledgers/fuckup rows when storage recovery fails. | `.flywheel/scripts/storage-headroom-watcher.sh:35`, `.flywheel/scripts/storage-headroom-watcher.sh:141`, `.flywheel/scripts/storage-headroom-watcher.sh:480`, `.flywheel/scripts/storage-headroom-watcher.sh:502`, `.flywheel/scripts/tick-driver-manifest.json:10` |
| `private-tmp-prune.sh` | Critical path after today's 312GB `/private/tmp` incident. Generic repo pruning does not reach this class; the target allowlist and lsof/age gates make it the right separate primitive. | `.flywheel/scripts/private-tmp-prune.sh:12`, `.flywheel/scripts/private-tmp-prune.sh:36`, `.flywheel/scripts/private-tmp-prune.sh:39`, `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_private_tmp_accretes_until_disk_dies.md:2`, `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_private_tmp_accretes_until_disk_dies.md:18` |
| `repo-hygiene` prompt + `hygiene-targets` schema | Critical path for safe cross-repo cleanup. This is the only generalized repo hygiene contract found, and it delegates to the storage/cache/snapshot/stash skills instead of ad hoc deletes. | `templates/peer-orch-broadcasts/repo-hygiene-prompt-template.md:1`, `templates/peer-orch-broadcasts/repo-hygiene-prompt-template.md:34`, `templates/peer-orch-broadcasts/repo-hygiene-prompt-template.md:61`, `templates/flywheel-install/hygiene-targets.schema.json:31`, `templates/flywheel-install/hygiene-targets.schema.json:101` |
| `dev-cache-janitor` + `apfs-snapshot-ops` | Critical path fallback surfaces when storage-prune cannot explain pressure. They cover language caches and APFS snapshots, which are outside repo-local prune candidates. | `/Users/josh/.claude/skills/dev-cache-janitor/SKILL.md:10`, `/Users/josh/.claude/skills/dev-cache-janitor/SKILL.md:52`, `/Users/josh/.claude/skills/apfs-snapshot-ops/SKILL.md:14`, `/Users/josh/.claude/skills/apfs-snapshot-ops/SKILL.md:66`, `/Users/josh/.claude/skills/storage-health/SKILL.md:82` |
| `git-stash-janitor` | Critical path after today's stash census found alps 79, picoz 34, skillos 5, 118 total. Stash bloat is state leakage, not merely disk bloat. | `/Users/josh/.claude/skills/git-stash-janitor/SKILL.md:26`, `/Users/josh/.claude/skills/git-stash-janitor/SKILL.md:47`, `/Users/josh/.claude/skills/git-stash-janitor/SKILL.md:111`, `/Users/josh/.claude/skills/git-stash-janitor/SKILL.md:152` |
| `sync-canonical-doctrine.sh` + canonical meta-rule sync | Load-bearing because hygiene includes doctrine propagation: stale rules cause workers to keep using obsolete cleanup/safety behavior. The repo has repeated dispatch-log meta-rule sync rows and the canonical AGENTS text names the sync gate and launchd watchdog. | `.flywheel/scripts/sync-canonical-doctrine.sh:1`, `.flywheel/scripts/sync-canonical-doctrine.sh:191`, `/Users/josh/.flywheel/canonical-meta-rules/sync.sh:57`, `/Users/josh/.flywheel/canonical-meta-rules/sync.sh:140`, `.flywheel/AGENTS-CANONICAL.md:2653`, `.flywheel/AGENTS-CANONICAL.md:2972` |
| `codex-template-stuck-detector.sh` + detector replay test | Load-bearing for fuckup-log promotion. Hygiene is not only disk cleanup; it also turns residue events into durable failure classes. | `.flywheel/scripts/codex-template-stuck-detector.sh:15`, `.flywheel/scripts/codex-template-stuck-detector.sh:37`, `.flywheel/tests/test-detector-pattern-bank-replay.sh:103`, `.flywheel/tests/test-detector-pattern-bank-replay.sh:134` |
| `agent-mail-identity-audit.sh` | Critical path for coordination hygiene. Retired/duplicate/stale agent identities produce invisible delivery failures and bad file-reservation state. | `/Users/josh/.claude/skills/.flywheel/scripts/agent-mail-identity-audit.sh:1`, `/Users/josh/.claude/skills/.flywheel/scripts/agent-mail-identity-audit.sh:39`, `/Users/josh/.claude/skills/.flywheel/scripts/agent-mail-identity-audit.sh:55`, `/Users/josh/.claude/skills/.flywheel/scripts/agent-mail-identity-audit.sh:137` |

## 3. Vestigial

| Surface | Why vestigial / sunset candidate | Evidence | Recommendation |
|---|---|---|---|
| `~/.claude/skills/.flywheel/skills/flywheel:storage-prune.md` | Dispatch/source-scope named this file, but it is absent. A missing skill doc pointer creates lookup noise and sends workers away from the real script. | `.flywheel/PLANS/flywheel-self-audit-2026-05-08/00-PLAN.md:16`, `.flywheel/scripts/storage-prune.sh:14` | Either author the missing command doc from the live script or remove the pointer from future dispatch scopes. |
| `.flywheel/scripts/session-residue-prune.sh` | 0-2 callsites observed in repo search, and its target classes overlap with `storage-prune.sh` and `private-tmp-prune.sh`. It is safer than ad hoc cleanup, but likely belongs as a subprimitive or schema-backed target, not an orphan script. | `.flywheel/scripts/session-residue-prune.sh:4`, `.flywheel/scripts/session-residue-prune.sh:85`, `.flywheel/scripts/storage-prune.sh:61`, `.flywheel/scripts/private-tmp-prune.sh:53` | Keep until storage-prune/private-tmp integration explicitly covers session residue, then fold or deprecate with a compatibility shim. |
| `.flywheel/scripts/doctrine-sync.sh` | 0-2 active callsites observed; it is an older repo-local append/stamp surface now largely superseded by fleet sync and canonical meta-rule three-surface sync. | `.flywheel/scripts/doctrine-sync.sh:11`, `.flywheel/scripts/doctrine-sync.sh:204`, `.flywheel/scripts/sync-canonical-doctrine.sh:1`, `/Users/josh/.flywheel/canonical-meta-rules/sync.sh:57` | Mark legacy unless it has a unique target no fleet sync covers. |
| `.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh` | The file says it is a skeleton and not wired into doctor. That makes it a visibility promise without enforcement. | `.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh:1`, `.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh:15`, `.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh:76` | Either wire into doctor/tick or demote to prototype. |
| `.flywheel/scripts/watcher-pattern-bank.*` | Scope named a watcher-pattern-bank file family, but no exact files exist. The active substrate is a replay test, not a reusable pattern bank. | `.flywheel/PLANS/flywheel-self-audit-2026-05-08/00-PLAN.md:16`, `.flywheel/tests/test-detector-pattern-bank-replay.sh:25`, `.flywheel/tests/test-detector-pattern-bank-replay.sh:81` | Rename scope to detector-pattern replay, or create a real pattern-bank artifact consumed by detectors. |
| `repo-hygiene` meta-skill | No `repo-hygiene` or `1p9of` skill found under `~/.claude/skills/`; the real surface is prompt/schema templates. | `templates/peer-orch-broadcasts/repo-hygiene-prompt-template.md:1`, `templates/flywheel-install/hygiene-targets.schema.json:1` | Either publish a small repo-hygiene skill that points to the prompt/schema, or stop calling it a skill. |

## 4. Missing per agent-flywheel.com gap analysis

### Gap 1: stagger-spawn enforcement

agent-flywheel.com's methodology calls swarm launch a distinct phase and specifies `stagger 30s+` (`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:50`). Its anti-pattern list names thundering herd (`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:74`), and the local gap analysis asks to check `ntm spawn` flags and add or document stagger behavior (`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:182-185`).

Observed: the coordination audit found native stagger support, but the hygiene/scheduling layer audited here does not enforce spawn staggering in storage, doctrine sync, repo hygiene, or watcher scheduling. Hygiene does have stagger-adjacent cadence wisdom in skills (`/Users/josh/.claude/skills/.flywheel/PATTERNS.md:153`, `/Users/josh/.claude/skills/accretive-cron-orchestration/SKILL.md:49`), but no hygiene primitive rejects or rewrites simultaneous fleet spawns.

Classification: missing enforcement, not merely missing documentation.

### Gap 2: recovery bundle convention

`git-stash-janitor` codifies a recovery bundle at `<project-parent>/<basename>-stash-archive-YYYY-MM-DD/` (`/Users/josh/.claude/skills/git-stash-janitor/SKILL.md:111`, `/Users/josh/.claude/skills/git-stash-janitor/SKILL.md:144`, `/Users/josh/.claude/skills/git-stash-janitor/SKILL.md:152`). That convention is strong for stash cleanup, but it is not generalized across storage-prune, session-residue-prune, private-tmp-prune, doctrine-sync backup files, or repo-hygiene target receipts.

Observed: storage-prune has apply receipts and targeted archives (`.flywheel/scripts/storage-prune.sh:90`, `.flywheel/scripts/storage-prune.sh:106`); doctrine sync has backup behavior (`.flywheel/scripts/sync-canonical-doctrine.sh:124`); private-tmp-prune has ledgers (`.flywheel/scripts/private-tmp-prune.sh:66`). They do not share one recovery-bundle naming contract.

Classification: convention exists in one skill only; missing cross-hygiene standard.

### Gap 3: periodic stash-bloat probe

Today's stash census found alps 79, picoz 34, skillos 5, or 118 total, before any recurring surface flagged it. `git-stash-janitor` now provides the human/agent cleanup doctrine, but `/flywheel:tick` step 4 fleet self-diagnosis does not appear to include stash-count thresholds.

Observed: the tick storage manifest covers storage headroom and storage prune (`.flywheel/scripts/tick-driver-manifest.json:10`, `.flywheel/scripts/tick-driver-manifest.json:16`), but no stash-count primitive appears beside those hygiene checks. The stash skill is manual/procedural (`/Users/josh/.claude/skills/git-stash-janitor/SKILL.md:74`, `/Users/josh/.claude/skills/git-stash-janitor/SKILL.md:111`) rather than periodic fleet telemetry.

Classification: missing fleet probe.

## 5. Lessons learned (today's evidence)

1. `ehz8` teaches that hygiene surface ownership must include commit/state ownership, not just disk deletion. In mobile-eats, accretive corpus ingestion surfaced a structural finding: 7/8 closed beads had dirty or uncommitted worker artifacts. That is repo hygiene because uncommitted artifacts are long-lived substrate residue.

2. `flywheel-23dsl` / pending L127 is hygiene-relevant because worker-close without a git commit is a state leak class. The memory says closed worker beads must declare `git_committed=<yes|no_changes|skipped>` and the close handler must block if scoped changes remain uncommitted (`/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_worker_close_requires_git_commit.md:7`, `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_worker_close_requires_git_commit.md:15`).

3. `/private/tmp` reached 312GB on a 926GB disk before flywheel noticed (`/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_private_tmp_accretes_until_disk_dies.md:2`, `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_private_tmp_accretes_until_disk_dies.md:41`). The lesson is that repo-local hygiene is insufficient; macOS temp substrate needs its own watcher and gated prune path.

4. Today's 3% free storage event proved storage is not a low-priority janitor concern. Below 5%, substrate operations become untrustworthy (`/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_storage_pressure_blocks_substrate.md:8`, `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_storage_pressure_blocks_substrate.md:19`). Storage hygiene is fleet uptime infrastructure.

5. Stash census - alps 79, picoz 34, skillos 5 - showed that stash bloat had no recurring telemetry. `git-stash-janitor` supplies the cleanup doctrine, but a skill does not equal a probe. Hygiene needs periodic detection and thresholds.

6. DCG prose-trigger fired three times today. That is primarily authoring discipline, not a hygiene surface gap, because the fix is prompt/text generation hygiene: strip dangerous substrings from prose packets and write prompt files when needed (`/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_dcg_prose_trigger_strip_dangerous_substrings.md:7`, `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_dcg_prose_trigger_strip_dangerous_substrings.md:15`). It is a doctrine-broadcast candidate, not a storage-prune bug.

## 6. Fix-bead manifest

Recommendations only. No beads filed in this audit pass.

### 1. `[hygiene] wire private tmp pressure into storage headroom control`

Priority: P0

Scope: Integrate `.flywheel/scripts/private-tmp-prune.sh` into the storage-health pathway without merging it into generic repo prune. Add doctor/tick fields for `/private/tmp` total bytes, largest allowed bucket, recent growth, and whether an apply is eligible under the allowlist/lsof/age contract.

Acceptance:

- `storage-headroom-watcher` or tick doctor reports `/private/tmp` pressure before free disk falls below 10%.
- Apply path remains allowlist-scoped and idempotency-key gated.
- Regression fixture proves a 312GB `/private/tmp` simulation emits a warning/failure and recommended prune action.
- No broad temp delete command is introduced.

### 2. `[hygiene] add fleet stash-bloat probe and shared recovery-bundle convention`

Priority: P1

Scope: Add a read-only fleet stash census to `/flywheel:tick` step 4 fleet self-diagnosis and codify a shared recovery-bundle naming contract for destructive hygiene classes. Reuse `git-stash-janitor` for cleanup doctrine; do not auto-pop/drop/apply stashes.

Acceptance:

- Probe emits per-repo stash counts and total count with thresholds, for example warning >=10 and urgent >=50 unless explicitly suppressed.
- alps=79, picoz=34, skillos=5 fixture fails the probe with `stash_bloat_detected=true`.
- Shared recovery bundle format covers stash archives, storage archives, doctrine-sync backups, and repo-hygiene receipts.
- Cleanup remains manual/agent-gated through `git-stash-janitor`.

### 3. `[scheduling] make staggered multi-agent spawn enforceable`

Priority: P1

Scope: Audit flywheel spawn/onboard/dispatch wrappers and add an explicit stagger policy for multi-agent launches. This belongs at the scheduling/hygiene boundary because thundering herd degrades the fleet silently before task work starts.

Acceptance:

- Every multi-agent spawn wrapper either emits `ntm spawn` with a stagger mode/delay or emits a machine-readable `stagger_not_applicable` receipt.
- Tests cover generated commands for at least one swarm launch path and one single-pane exemption.
- Doctor/tick can report recent simultaneous spawn bursts as hygiene warnings.
