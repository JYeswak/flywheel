# 03-AUDIT-r1-SECURITY - /flywheel:recovery

task_id: recovery_audit_security
date: 2026-05-01
mode: Phase 3 paper audit, security lens
audited_plan: `02-REFINE-r1.md`
scope: plan-space only; no exploit execution

## Verdict

The r1 plan has the right security shape: dry-run before mutation, audit rows,
protected sessions, redacted exports, session-name validation, and no blind
force restore. The biggest remaining security issue is that several controls
are written as policy statements but not yet assigned to concrete validator
checks, ownership boundaries, or fail-closed behavior.

Security posture: promising, not bead-ready for protected-client automation.

Critical Joshua-disposes items before implementation bead conversion:

1. Who can run `restore --apply` for protected sessions.
2. Whether non-redacted checkpoint payloads are allowed at rest without encryption.
3. Whether plist install accepts, overwrites, or blocks on pre-existing labels.

Primary plan citations:

- Intent requires 8 sessions survive reboot, including `alpsinsurance`: `00-INTENT.md:L10-L23`.
- Launchd plist install is Joshua-disposes: `00-INTENT.md:L13-L16`.
- Recovery goals include explicit protected-session policy: `02-REFINE-r1.md:L180-L186`.
- Mutating restore/plist/delete operations require gates: `02-REFINE-r1.md:L188-L195`.
- State stores include recovery JSONL, snapshots, checkpoints, topology, repo docs, and beads DBs: `02-REFINE-r1.md:L217-L226`.
- Operating principles require dry-run, audit rows, protected-session policy, verified manifests, and transcript pointer-only handling: `02-REFINE-r1.md:L228-L240`.
- Manifest contains protected flags, watcher path, checkpoint export path/hash, native session path/hash, dispatch state, and AM readiness: `02-REFINE-r1.md:L248-L326`.
- Manifest restore blockers include low topology confidence, unverified checkpoint, protected force restore, null native session continuation, and orphan dispatches: `02-REFINE-r1.md:L329-L337`.
- Restore state machine limits actions by phase: `02-REFINE-r1.md:L343-L385`.
- Planned and unplanned recovery procedures define dry-run/apply order and AM replay ordering: `02-REFINE-r1.md:L392-L416`.
- Retention policy keeps daily/weekly/baseline artifacts and audit rows: `02-REFINE-r1.md:L418-L441`.
- Security/data exposure rules cover session-name regex, redacted exports, 0600 non-redacted local archives, token exclusion, and callback content limits: `02-REFINE-r1.md:L443-L452`.
- Rollback rules include config backup, plist uninstall rollback, no checkpoint deletion first rollout, live-target checkpoint, AM last handled IDs, and partial-status rows: `02-REFINE-r1.md:L458-L464`.
- Phase 2 installs watcher plists and one boot helper/LaunchAgent: `02-REFINE-r1.md:L505-L519`.
- Phase 3 creates verified checkpoints, redacted exports, and temp-to-final manifests: `02-REFINE-r1.md:L521-L535`.
- Phase 4 defines local nightly helper plus optional remote schedule nudge: `02-REFINE-r1.md:L537-L552`.
- Phase 5 applies restore under protected policy and drill ledger: `02-REFINE-r1.md:L554-L571`.
- Beads B04-B11 install per-session plists; B12 combines baseline snapshot, nightly cron, restore, and drills: `02-REFINE-r1.md:L579-L590`.
- Risk register already names protected force restore and checkpoint secrets: `02-REFINE-r1.md:L699-L714`.
- Joshua decision J2 covers protected-session policy; J3 covers cron authority; J4 covers retention: `02-REFINE-r1.md:L726-L748`.
- Acceptance requires dry-run schema, session-name rejection, disposable plist install/uninstall, checkpoint export, dry-run restore, and D1-D4 drills: `02-REFINE-r1.md:L818-L842`.

## Threat Findings

### T01 - Plist preplant / malicious label takeover

- Severity: CRITICAL
- Likelihood: UNCOMMON
- Plan citation: watcher plists are per-session artifacts and one boot helper is added in Phase 2 (`02-REFINE-r1.md:L505-L519`); plist install touches system-level resources and is Joshua-disposes (`00-INTENT.md:L13-L16`).
- Current mitigation: plan requires dry-run before mutation and a launchd status verifier (`02-REFINE-r1.md:L232-L234`, `02-REFINE-r1.md:L511-L518`).
- Gap: no explicit owner/mode/hash validation before accepting an existing plist. A malicious or stale pre-existing `com.ntm.watcher.<session>.plist` could satisfy "exists" while running the wrong ProgramArguments.
- Suggested mitigation: add B04-B11 install preflight: `plist_owner_uid == current_uid`, not group/world-writable, canonical Label match, ProgramArguments hash match, path under `~/Developer/ntm/scripts/ntm-watcher.sh` or flywheel helper, and `plutil -lint` pass. If mismatch, block apply and emit `blocked_plist_preplant`.
- Owner: Phase 2 / B04-B11; Joshua-disposes if overwrite is required.

### T02 - Plist payload injection through session name

- Severity: HIGH
- Likelihood: UNCOMMON
- Plan citation: security rules require session names match `[A-Za-z0-9._-]` before plist generation (`02-REFINE-r1.md:L447-L447`), and acceptance repeats session-name rejection (`02-REFINE-r1.md:L818-L821`).
- Current mitigation: regex validation blocks slash and shell metacharacters if actually enforced.
- Gap: plan does not state whether regex is applied before every derived surface: plist filename, launchd label, log path, checkpoint path, JSON manifest row, and callback text.
- Suggested mitigation: centralize `validate_session_name()` in B01 schema and require all B02-B12 commands to consume only canonical validated names from manifest, not raw user args.
- Owner: Phase 0 / B01-B02.

### T03 - Plist file permissions / ownership hygiene

- Severity: HIGH
- Likelihood: COMMON
- Plan citation: Phase 2 installs LaunchAgents (`02-REFINE-r1.md:L505-L519`), but security rules only mention archive modes, not plist modes (`02-REFINE-r1.md:L443-L452`).
- Current mitigation: dry-run/apply split and launchd verifier exist.
- Gap: no explicit expected mode. User LaunchAgent plists commonly need to be user-owned and non-writable by group/others; mode `0644` is generally acceptable for launchd readability, while `0600` may be too restrictive on some setups. The plan does not state the policy.
- Suggested mitigation: B01 defines plist mode policy: owner=current user, group=staff, mode no more permissive than `0644`, parent dir not group/world-writable, and content hash recorded. Doctor should warn on `0600` only if launchd cannot read it, and error on group/world-writable.
- Owner: Phase 2 / B01 plus B04-B11.

### T04 - Snapshot scrollback secrets and ALPS client data exposure

- Severity: CRITICAL
- Likelihood: COMMON
- Plan citation: checkpoint exports default to redacted; non-redacted archives mode `0600`; callbacks avoid scrollback (`02-REFINE-r1.md:L447-L452`). Risk register names checkpoint secrets as High/Medium (`02-REFINE-r1.md:L703-L706`). ALPS is a protected client session (`02-REFINE-r1.md:L582-L585`, `02-REFINE-r1.md:L726-L732`).
- Current mitigation: redacted exports, local mode `0600`, no off-host archive by default.
- Gap: `ntm checkpoint save` captures local scrollback before export redaction. The plan does not state local checkpoint storage permissions, encryption-at-rest policy, or whether protected sessions may retain raw scrollback for 14 daily + 8 weekly.
- Suggested mitigation: add B12 protected-session snapshot mode: shallow default for ALPS/Picoz, redacted export mandatory, raw checkpoint directory mode checked, optional encrypted local tar for non-redacted protected payloads, and retention exception requiring Joshua decision.
- Owner: Phase 3/4 / B12; Joshua-disposes for non-redacted protected retention.

### T05 - Cross-session bleed: restore checkpoint A into session B

- Severity: HIGH
- Likelihood: UNCOMMON
- Plan citation: manifest stores `session`, `repo_path`, watcher path, checkpoint id/hash, repo head, topology confidence, and pane counts (`02-REFINE-r1.md:L264-L315`). Restore dry-run must check pane count and working directory (`02-REFINE-r1.md:L825-L828`).
- Current mitigation: topology confidence low blocks restore; dry-run restore precedes apply (`02-REFINE-r1.md:L329-L335`, `02-REFINE-r1.md:L402-L403`).
- Gap: no explicit binding check between checkpoint metadata and target session name/repo path before `restore --apply`.
- Suggested mitigation: B12 restore preflight must compare checkpoint `session_name`, manifest `session`, current topology session, repo path, git remote, pane count, and protected flag. Any mismatch blocks with `blocked_checkpoint_target_mismatch`.
- Owner: Phase 5 / B12.

### T06 - Restore privilege: any agent can invoke apply

- Severity: CRITICAL
- Likelihood: UNCOMMON
- Plan citation: mutating operations need apply/override gates (`02-REFINE-r1.md:L188-L195`); protected sessions restore only by explicit policy (`02-REFINE-r1.md:L232-L237`); J2 asks what policy applies to ALPS/Picoz (`02-REFINE-r1.md:L726-L732`).
- Current mitigation: dry-run mandatory and protected sessions block force restore unless explicit approval is present.
- Gap: no authentication/authorization model for `/flywheel:recovery restore --apply`. If any pane can run the slash command, policy is only textual.
- Suggested mitigation: B01 defines an authorization envelope: `actor`, `pane`, `session`, `command`, `approval_token_or_receipt`, `protected_scope`, `expires_at`. Protected-session `--apply` requires Joshua-issued run token or human-pane confirmation row. Non-protected apply still requires manifest idempotency key.
- Owner: Phase 0 / B01; Joshua-disposes before implementation.

### T07 - Remote `/schedule` prompt injection or command drift

- Severity: HIGH
- Likelihood: UNCOMMON
- Plan citation: Phase 4 has local deterministic helper plus optional remote `/schedule` nudge after slash validation (`02-REFINE-r1.md:L537-L552`). J3 recommends local helper as authority and remote schedule as nudge/monitor (`02-REFINE-r1.md:L734-L740`).
- Current mitigation: remote schedule is not primary authority.
- Gap: no prompt canonicalization, maximum payload size, or "schedule may only request local helper status" rule. A cloud prompt that includes raw session names, callback snippets, or shell commands can be injection-prone or stale.
- Suggested mitigation: B12 schedule contract: remote schedule payload contains only a short stable command reference, no inline shell, no untrusted session data, and no apply operation. Local helper owns actual commands and validates manifest before action.
- Owner: Phase 4 / B12; orchestrator validates slash surface.

### T08 - Schedule prompt truncation causing partial recovery

- Severity: MEDIUM
- Likelihood: COMMON
- Plan citation: success criteria require nightly snapshot unattended (`00-INTENT.md:L19-L23`); Phase 4 writes aggregate and per-session nightly JSONL rows (`02-REFINE-r1.md:L537-L552`).
- Current mitigation: local helper is the authority.
- Gap: no explicit maximum size or checksum for remote schedule payload/result. A too-large schedule prompt may omit sessions silently or truncate the failure callback.
- Suggested mitigation: B12 schedule payload must be constant-size and refer to a local config file by hash. Nightly helper writes expected/seen counts and exits non-zero if `sessions_seen != sessions_expected`.
- Owner: Phase 4 / B12.

### T09 - Symlink/path traversal in checkpoint export or artifact promotion

- Severity: HIGH
- Likelihood: UNCOMMON
- Plan citation: artifacts can be promoted from `/tmp` into plan space (`02-REFINE-r1.md:L317-L323`, `02-REFINE-r1.md:L398-L400`); checkpoint exports are created in Phase 3 (`02-REFINE-r1.md:L521-L535`); J11 discusses `/tmp` promotion (`02-REFINE-r1.md:L798-L804`).
- Current mitigation: none explicit beyond dry-run and JSON manifest.
- Gap: no rule blocks symlinks, `..`, absolute destinations outside the plan dir, or tar entries escaping the extraction directory.
- Suggested mitigation: B01/B12 path policy: all promoted artifact sources must be regular files, not symlinks; destinations must resolve under the recovery plan dir; checkpoint archive verification must reject absolute paths, `..`, symlinks, hardlinks, device nodes, and owner-changing metadata.
- Owner: Phase 3 / B12.

### T10 - Snapshot race during active dispatch

- Severity: HIGH
- Likelihood: COMMON
- Plan citation: original constraints say snapshot should not run during active worker generation (`00-INTENT.md:L13-L17`); manifest tracks dispatch `in_flight`, orphan candidates, and last callback (`02-REFINE-r1.md:L305-L309`); operating principles include audit rows before and after mutation (`02-REFINE-r1.md:L232-L235`).
- Current mitigation: dispatch state is captured in manifest and orphan candidates are not auto-closed (`02-REFINE-r1.md:L337-L337`).
- Gap: no fail-closed rule says `snapshot --apply` blocks when `in_flight > 0` unless session emits a checkpoint receipt.
- Suggested mitigation: B12 snapshot gate: if active dispatch exists, require pane-level checkpoint receipt or mark session `snapshot_deferred_active_generation`; no protected-session snapshot during unbounded generation.
- Owner: Phase 3/4 / B12.

### T11 - Restore while target session is live

- Severity: HIGH
- Likelihood: COMMON
- Plan citation: restore apply can proceed if session is missing or explicit force allowed (`02-REFINE-r1.md:L366-L369`); restore apply should checkpoint live target first when feasible (`02-REFINE-r1.md:L458-L462`); risk register flags protected force restore (`02-REFINE-r1.md:L703-L705`).
- Current mitigation: force gate and pre-restore live checkpoint recommendation.
- Gap: "when feasible" is weak for protected sessions; the plan does not require pane idle checks, user confirmation, or active-worker drain before force restore.
- Suggested mitigation: B12 force-restore policy: live target restore requires `ntm health`, pane-work-signal, dispatch ledger clear, pre-restore checkpoint success, and Joshua run token for protected sessions. Otherwise block.
- Owner: Phase 5 / B12; Joshua-disposes for protected force.

### T12 - Retention preserves rotated secrets and client data

- Severity: HIGH
- Likelihood: COMMON
- Plan citation: retention keeps latest, baseline, 14 daily, 8 weekly, 90 days audit, and never prunes current manifest checkpoints (`02-REFINE-r1.md:L422-L432`). J4 recommends 14 daily + 8 weekly + baselines plus byte ceiling (`02-REFINE-r1.md:L742-L748`).
- Current mitigation: redacted exports and 0600 non-redacted archives.
- Gap: no policy ties secret rotation or client offboarding to checkpoint reclassification. A 30-day-old protected raw checkpoint may contain a rotated token or ALPS data beyond business need.
- Suggested mitigation: add `sensitivity_class`, `contains_raw_scrollback`, `client_session`, `secret_epoch`, and `retire_after` to manifest. Secret rotation emits a recovery-retention review row for all affected checkpoint ranges.
- Owner: Phase 4 / B12; Joshua-disposes for ALPS retention.

### T13 - Audit log tampering

- Severity: HIGH
- Likelihood: UNCOMMON
- Plan citation: audit JSONL is authoritative state (`02-REFINE-r1.md:L217-L223`), helper writes rows before and after mutations (`02-REFINE-r1.md:L232-L235`), and raw rows are retained 90 days (`02-REFINE-r1.md:L430-L430`).
- Current mitigation: append-only convention and before/after rows.
- Gap: no tamper-evidence. Any local process with user permissions can rewrite JSONL rows and remove failed applies.
- Suggested mitigation: each audit row includes `prev_hash`, `row_hash`, monotonic sequence, host, actor, command hash, and manifest ID. Doctor verifies hash chain and reports `audit_chain_broken`.
- Owner: Phase 0 / B01; Phase 5 doctor.

### T14 - Agent Mail token leakage vs reauth survival

- Severity: HIGH
- Likelihood: UNCOMMON
- Plan citation: Agent Mail token contents are never copied into recovery manifests (`02-REFINE-r1.md:L451-L451`); manifest records `agent_mail_identity_ready` (`02-REFINE-r1.md:L310-L314`); AM replay waits for topology and identities (`02-REFINE-r1.md:L414-L414`).
- Current mitigation: token contents excluded from manifests.
- Gap: plan does not state whether token vault paths are included by reference, whether token files are backed up separately, or how recovered sessions reauth if token files are missing.
- Suggested mitigation: B12 token handling policy: manifests store token file path hash and mode only; token vault doctor ensures file exists mode `0600`; recovery never copies token content into checkpoints; missing tokens block AM replay with `blocked_agent_mail_token_missing`.
- Owner: Phase 0/3/5 / B01-B12.

### T15 - Beads DB poisoning and rollback confusion

- Severity: HIGH
- Likelihood: UNCOMMON
- Plan citation: repo-local `.beads/*.db` is an authoritative state store (`02-REFINE-r1.md:L225-L226`); manifest records `beads_integrity` (`02-REFINE-r1.md:L288-L293`); B12 inspects Beads local state before redispatch (`02-REFINE-r1.md:L671-L672`).
- Current mitigation: Beads integrity gate and dirty owner map block restore if unknown (`02-REFINE-r1.md:L533-L535`).
- Gap: no explicit pre/post restore beads DB hash, WAL handling, or "checkpoint must not overwrite active `.beads`" rule. A restored repo or artifact could regress issue state.
- Suggested mitigation: B12 captures `.beads/*.db`, `*.db-wal`, and `*.db-shm` hashes before restore; restore never writes `.beads` from checkpoint in v1; redispatch requires post-restore `br doctor`/integrity result and hash drift explanation.
- Owner: Phase 3/5 / B12.

### T16 - Manifest poisoning or stale manifest replay

- Severity: HIGH
- Likelihood: UNCOMMON
- Plan citation: latest valid manifest controls restore; if none exists, restore blocks (`02-REFINE-r1.md:L407-L412`); manifest includes idempotency key and mode (`02-REFINE-r1.md:L252-L258`).
- Current mitigation: temp-to-final manifest write (`02-REFINE-r1.md:L533-L534`) and current manifest references block pruning (`02-REFINE-r1.md:L432-L432`).
- Gap: no signature/hash-chain protection for "latest valid" selection. A stale but well-formed manifest can redirect restore to older checkpoints.
- Suggested mitigation: manifest registry file with hash chain, created_at monotonicity, `supersedes_manifest_id`, and "current" symlink disallowed unless resolved and hash-verified. Restore accepts only manifests in registry.
- Owner: Phase 3/5 / B12.

### T17 - Callback content leakage

- Severity: MEDIUM
- Likelihood: COMMON
- Plan citation: callbacks include artifact paths and counts, not scrollback contents (`02-REFINE-r1.md:L452-L452`); failure callback contract is Phase 4 deliverable (`02-REFINE-r1.md:L541-L546`).
- Current mitigation: callback content limitation.
- Gap: no max-length or redaction check for callback subject/body. A failed command may include raw error output with secrets or client data.
- Suggested mitigation: callback builder takes structured fields only, truncates values, rejects newline-heavy outputs, and scans for token-like patterns before `ntm send`.
- Owner: Phase 4/5 / B12.

### T18 - Recovery helper path hijack / PATH injection

- Severity: HIGH
- Likelihood: UNCOMMON
- Plan citation: architecture uses `flywheel-recovery helper` calling topology, NTM config, plists, checkpoints, restore, and Agent Mail health (`02-REFINE-r1.md:L196-L215`). Plan says existing Jeff primitives are called, not copied (`02-REFINE-r1.md:L232-L237`).
- Current mitigation: none explicit beyond dry-run and reuse policy.
- Gap: no absolute binary path policy. A modified `PATH` during launchd boot or schedule execution could call the wrong `ntm`, `jq`, `br`, or helper.
- Suggested mitigation: B01 helper contract pins absolute paths or validates `command -v` against expected locations and hashes. LaunchAgent ProgramArguments use absolute helper path and sanitized environment.
- Owner: Phase 0/2 / B01-B04.

## Critical Findings

### C01 - Protected-session restore authority is not yet a security boundary

Severity: CRITICAL.

Joshua must decide before implementation whether protected `restore --apply`
requires a human-issued run token, human-pane confirmation row, or some other
authorization envelope. The r1 plan says protected force restore needs explicit
policy (`02-REFINE-r1.md:L334-L335`, `02-REFINE-r1.md:L726-L732`), but it does
not yet say who is allowed to create the policy artifact at runtime.

Joshua-disposes: yes.

### C02 - Raw checkpoint payloads may preserve ALPS/client secrets

Severity: CRITICAL.

The plan redacts exported archives and uses mode `0600` for non-redacted local
archives (`02-REFINE-r1.md:L447-L452`), but raw NTM checkpoint storage may still
hold scrollback before export. ALPS is explicitly in scope (`00-INTENT.md:L10-L12`)
and has protected-session treatment (`02-REFINE-r1.md:L582-L585`).

Joshua-disposes: yes, for protected-session raw retention and encryption policy.

### C03 - LaunchAgent preplant handling is undefined

Severity: CRITICAL.

The plan installs watcher plists and a boot helper (`02-REFINE-r1.md:L505-L519`)
but does not say whether existing labels are accepted, overwritten, quarantined,
or blocked. Because plist install is a Joshua-disposes system-level action
(`00-INTENT.md:L13-L16`), preplant handling needs an explicit security decision.

Joshua-disposes: yes, for overwrite/quarantine behavior.

## Common Gap Patterns

### Pattern 1 - Policy without verifier

The plan says session names are constrained, exports are redacted, tokens are
not copied, and protected sessions require explicit policy (`02-REFINE-r1.md:L443-L452`),
but several controls need concrete validator names, exit codes, and receipt fields.

Affected threats: T01, T03, T04, T06, T14, T16.

### Pattern 2 - Local durability without tamper evidence

The plan uses JSONL audit rows, manifests, checkpoint hashes, and state docs
(`02-REFINE-r1.md:L217-L226`, `02-REFINE-r1.md:L248-L326`), but the audit and
manifest registries are not yet hash-chained.

Affected threats: T13, T16, T12.

### Pattern 3 - Protected sessions are identified, but data classes are not

The plan marks protected sessions and flags ALPS/Picoz policy (`02-REFINE-r1.md:L720-L732`),
but does not assign sensitivity classes to checkpoint payloads, scrollback,
tokens, or artifact promotion.

Affected threats: T04, T10, T11, T12, T17.

### Pattern 4 - Boot automation has two trust boundaries

Launchd and remote `/schedule` both create delayed execution contexts
(`02-REFINE-r1.md:L505-L519`, `02-REFINE-r1.md:L537-L552`). The plan treats
them operationally, but security needs environment, payload, path, and identity
constraints at both boundaries.

Affected threats: T01, T07, T08, T18.

## Doctrine Implications

### L63 - Recovery primitives must rehearse before claiming reliability

The plan aligns with L63 by requiring D1-D4 drills (`02-REFINE-r1.md:L568-L571`,
`02-REFINE-r1.md:L832-L842`). Security amendment: drills must include negative
security cases in dry-run only: malicious plist preplant fixture, bad session
name, stale manifest, and protected force attempt.

Doctrine violation: none if negative drills are added before readiness.

### L48 / L67 - Credential substrate probes before escalation

Recovery touches Agent Mail tokens and potentially credential-rich scrollback.
The plan says token contents are not copied (`02-REFINE-r1.md:L451-L451`), but
missing tokens should not become a vague Joshua ask. Token failure should emit a
ledger row with path/mode/hash presence only, consistent with credential-substrate
rules in AGENTS L48/L67.

Doctrine violation: potential if token reauth wall lacks probe ledger.

### L61 / L65 - Dual-channel and fleet-mail boundaries

The plan correctly blocks Agent Mail replay until topology and identities are
ready (`02-REFINE-r1.md:L414-L414`). Security amendment: replay must respect
L61/L65, meaning cross-orch mail after restore must use fleet-mail-project and
paired NTM poke when panes exist.

Doctrine violation: potential if restore replay sends local-project mail for
cross-orch coordination.

### L52 / L53 - Findings and traumas must become beads/fuckup rows

This audit is plan-space and does not file beads by dispatch scope. During bead
conversion, every CRITICAL and HIGH finding should map to a bead line or explicit
no-bead reason. Security failures during implementation should also log
fuckup rows.

Doctrine violation: none in this dispatch; future violation if findings are
absorbed silently.

### L51 - File reservations

Implementation beads that edit recovery helper, plist scripts, or plan files
must reserve files before edits. This paper audit wrote only the requested audit
artifact.

Doctrine violation: none for this dispatch scope.

## Compliance Touch - ALPS and Client Data

ALPS is an insurance client context and is explicitly in the eight-session
recovery scope (`00-INTENT.md:L10-L12`). The plan also assigns ALPS a protected
plist bead and says it should proceed only after protected policy/path confidence
(`02-REFINE-r1.md:L582-L585`).

Potential exposure classes:

1. Raw pane scrollback in NTM checkpoints.
2. Git patch files in checkpoints.
3. Native provider transcript paths and hashes.
4. `/tmp` artifacts promoted into repo plan space.
5. Agent Mail messages and identity metadata.
6. Audit JSONL rows containing command outputs.

HIPAA/GDPR-style issue:

Even if ALPS data is not formally HIPAA in this workflow, the recovery system
creates a new copy surface for client operational data. Retention is 14 daily
plus 8 weekly for protected sessions (`02-REFINE-r1.md:L424-L427`), which may
outlive business need if raw scrollback contains client facts or credentials.

Required compliance controls before ALPS automation:

1. Mark ALPS session `sensitivity_class=client_protected`.
2. Default ALPS to shallow/redacted checkpoint export.
3. Store raw protected checkpoints only locally, mode verified, preferably encrypted.
4. Do not promote ALPS `/tmp` artifacts unless named in manifest allowlist.
5. Require Joshua-disposes for non-redacted protected retention.
6. Add retention review on credential rotation or client data purge request.
7. Callback messages for ALPS use artifact path and counts only.

## Security Bead Amendments

Recommended additions to the existing bead plan:

1. B01 add `security schema`: actor, authorization envelope, sensitivity class, manifest hash-chain, audit hash-chain.
2. B01 add `path policy`: canonical path resolution, no symlink promotion, no archive traversal.
3. B02 add `protected-session classifier`: client/safety/brain/internal plus retention policy.
4. B04-B11 add `plist verifier`: owner, mode, label, ProgramArguments, hash, plutil, preplant block.
5. B12 add `protected snapshot mode`: shallow/redacted default, raw local mode check, optional encryption decision.
6. B12 add `restore privilege gate`: protected apply requires Joshua run token/receipt.
7. B12 add `audit tamper evidence`: prev_hash/row_hash chain and doctor verification.
8. B12 add `schedule payload contract`: constant-size nudge only, no inline shell/apply.
9. B12 add `beads DB safety`: pre/post `.beads` DB/WAL hash and no restore overwrite in v1.
10. B12 add `token vault doctor`: token content never copied, mode/path/hash presence only.

## Validation Ladder

1. >=15 distinct threats evaluated: PASS, 18 threats.
2. Each threat has severity, likelihood, current mitigation, gap, suggested mitigation, owner: PASS.
3. Critical-findings list present with Joshua-disposes flagged: PASS, 3 criticals.
4. Common-pattern synthesis >=3 patterns: PASS, 4 patterns.
5. Doctrine-implications check against AGENTS.md L-rules: PASS.
6. Compliance section addresses ALPS context: PASS.
7. No fabrication: PASS; each threat references plan lines.
8. Read-only: PASS; only requested audit output was written.
9. No testing of actual exploits: PASS; paper audit only.
10. ladder_passed=yes only if 1-9 clean: PASS.

ladder_passed=yes
threats=18
criticals=3
doctrine_violations=0
