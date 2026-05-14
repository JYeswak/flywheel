# Flywheel Canonical Operational Doctrine

## How to read this file

This is the canonical "how agents operate" reference, distributed via
flywheel-loop init to every flywheel-installed repo as
`.flywheel/AGENTS-CANONICAL.md`. Each repo's local AGENTS.md should
reference this file and add only repo-specific operational rules.
Domain rules (what we're building, not how we operate) belong in CLAUDE.md.

## L-Rule Schema

Each L-rule below uses this frontmatter (YAML between `---` fences):

| Field | Type | Required | Meaning |
|---|---|---|---|
| id | string | yes | e.g. L48 (canonical id, never reused) |
| title | string | yes | one-line summary |
| status | enum | yes | long_term \| temporary \| retired |
| shipped | date | yes | YYYY-MM-DD when rule first landed |
| sunset_when | object | if temporary | bead: bd-XXX OR metric: <expr> OR date: YYYY-MM-DD |
| review_due | date | yes | YYYY-MM-DD next mandatory re-evaluation |
| trauma_class | string | yes | grouping label (e.g. phantom-substrate) |
| retired_by | object | if retired | bead/metric/date that triggered + retired_at |
| retired_at | date | if retired | YYYY-MM-DD |

## Rules

<!-- GENERATED: edit .flywheel/rules/L*.md, then run .flywheel/scripts/agents-md-shard-extract.sh --apply -->

<!-- BEGIN-CANONICAL-FLYWHEEL-DOCTRINE -->

The full canonical L-rule bodies are sharded under `.flywheel/rules/`.
`MANIFEST.json` records the exact round-trip hash for `cat .flywheel/rules/L*.md`.

<!-- BEGIN-RULES-INDEX -->
| Order | Rule | Status | Shard |
|---:|---|---|---|
| 1 | L48 — SUBSTRATE-EXHAUSTION-BEFORE-ESCALATION | long_term | `.flywheel/rules/L001-L48-substrate-exhaustion-before-escalation.md` |
| 2 | L29 — NTM-only doctrine | long_term | `.flywheel/rules/L002-L29-ntm-only-doctrine.md` |
| 3 | L35 — Every Tier 3 classification requires a paired-tool bead | long_term | `.flywheel/rules/L003-L35-every-tier-3-classification-requires-a-paired-tool-bead.md` |
| 4 | L50 — SOCRATICODE-MANDATORY-IN-EVERY-DISPATCH (every NTM dispatch surveys what we have before writing what we want) | long_term | `.flywheel/rules/L004-L50-socraticode-mandatory-in-every-dispatch-every-ntm-dispatch-surveys-wha.md` |
| 5 | L51 — DISPATCH-FILE-RESERVATIONS-MANDATORY (every multi-file worker dispatch reserves files via agent-mail before edits) | long_term | `.flywheel/rules/L005-L51-dispatch-file-reservations-mandatory-every-multi-file-worker-dispatch-.md` |
| 6 | L52 — ISSUES-TO-BEADS-OR-EXPLICIT-NO-BEAD-RECEIPT (no observed gap is absorbed silently) | long_term | `.flywheel/rules/L006-L52-issues-to-beads-or-explicit-no-bead-receipt-no-observed-gap-is-absorbe.md` |
| 7 | L53 — FUCKUPS-REPORTED-IN-CALLBACK (every blocker / trauma / gap surfaces as a fuckup-log row) | long_term | `.flywheel/rules/L007-L53-fuckups-reported-in-callback-every-blocker-trauma-gap-surfaces-as-a-fu.md` |
| 8 | L54 — SKILL-DEEP-DIVE-ON-BLOCKERS (workers climb the skill tree before declaring a wall) | long_term | `.flywheel/rules/L008-L54-skill-deep-dive-on-blockers-workers-climb-the-skill-tree-before-declar.md` |
| 9 | L55 — CAPABILITY-CONTROL-PLANE-ESCALATION-FOR-MISSING-SKILLS (when no skill exists for a trauma class) | long_term | `.flywheel/rules/L009-L55-capability-control-plane-escalation-for-missing-skills-when-no-skill-exists-fo.md` |
| 10 | L56 — FUCKUP-LOG → INCIDENTS → CANONICAL-L-RULE PROMOTION LADDER | long_term | `.flywheel/rules/L010-L56-fuckup-log-incidents-canonical-l-rule-promotion-ladder.md` |
| 11 | L57 — LOOP-STATE-MARKER-NOT-DRIVER | long_term | `.flywheel/rules/L011-L57-loop-state-marker-not-driver.md` |
| 12 | L58 — SECRET-MATERIAL-NEVER-IN-PANE-TEXT | long_term | `.flywheel/rules/L012-L58-secret-material-never-in-pane-text.md` |
| 13 | L59 — RECONCILE-SCRIPT-POSTCHECK-STEP | long_term | `.flywheel/rules/L013-L59-reconcile-script-postcheck-step.md` |
| 14 | L60 — LOOP-INTEGRITY-5-SIGNAL-CONTRACT | long_term | `.flywheel/rules/L014-L60-loop-integrity-5-signal-contract.md` |
| 15 | L61 — DOCTRINE-LANDING-WIRES-INTO-AGENTS-AND-README | long_term | `.flywheel/rules/L015-L61-doctrine-landing-wires-into-agents-and-readme.md` |
| 16 | L62 — STATE-MD-IS-LATENT-OPPORTUNITY-SUBSTRATE | long_term | `.flywheel/rules/L016-L62-state-md-is-latent-opportunity-substrate.md` |
| 17 | L63 — JEFF-INTEL-NETWORK-IS-CANONICAL-SUBSTRATE-DEPENDENCY | long_term | `.flywheel/rules/L017-L63-jeff-intel-network-is-canonical-substrate-dependency.md` |
| 18 | L64 — JEFF-IS-MENTOR-NOT-JUST-DEPENDENCY | long_term | `.flywheel/rules/L018-L64-jeff-is-mentor-not-just-dependency.md` |
| 19 | L65 — CLI-IDENTITY-BEATS-COMMAND-NAME | long_term | `.flywheel/rules/L019-L65-cli-identity-beats-command-name.md` |
| 20 | L66 — OUTBOUND-JEFF-ISSUES-USE-PHASED-COMMAND-GATE | long_term | `.flywheel/rules/L020-L66-outbound-jeff-issues-use-phased-command-gate.md` |
| 21 | L67 — TRUTH-SOURCE-MUST-BE-LIVE-NOT-CACHED | long_term | `.flywheel/rules/L021-L67-truth-source-must-be-live-not-cached.md` |
| 22 | L68 — NO-SILENT-DARKNESS-GOAL-CONTRACT | long_term | `.flywheel/rules/L022-L68-no-silent-darkness-goal-contract.md` |
| 23 | L69 — ORCH-PROBE-AGENT-CONTEXT (probe runs THROUGH agent execution, not orchestrator shell) | long_term | `.flywheel/rules/L023-L69-orch-probe-agent-context-probe-runs-through-agent-execution-not-orches.md` |
| 24 | L70 — ORCH-NO-PUNT (next actionable runs same tick, not next tick) | long_term | `.flywheel/rules/L024-L70-orch-no-punt-next-actionable-runs-same-tick-not-next-tick.md` |
| 25 | L71 — VALIDATE-AND-REDISPATCH-DISCIPLINE | long_term | `.flywheel/rules/L025-L71-validate-and-redispatch-discipline.md` |
| 26 | L72 — STORAGE-DISCIPLINE-SYSTEM-WIDE | long_term | `.flywheel/rules/L026-L72-storage-discipline-system-wide.md` |
| 27 | L73 — HEADLESS-BROWSER-ORPHAN-LEAK-DOCTOR | long_term | `.flywheel/rules/L027-L73-headless-browser-orphan-leak-doctor.md` |
| 28 | L74 — AGENT-SECURITY-DENY-RULES-CANONICAL | long_term | `.flywheel/rules/L028-L74-agent-security-deny-rules-canonical.md` |
| 29 | L75 — ORCH-BLOCKER-COORDINATION | long_term | `.flywheel/rules/L029-L75-orch-blocker-coordination.md` |
| 30 | L76 — AGENTMAIL-IDENTITY-CANONICAL | long_term | `.flywheel/rules/L030-L76-agentmail-identity-canonical.md` |
| 31 | L77 — DAILY-REPORT-LEARNING-ROLLUP | long_term | `.flywheel/rules/L031-L77-daily-report-learning-rollup.md` |
| 32 | L78 — JEFF-CORPUS-ACCRETIVE-INGESTION | long_term | `.flywheel/rules/L032-L78-jeff-corpus-accretive-ingestion.md` |
| 33 | L79 — STORAGE-OVERRIDE-RECEIPTS-ARE-MECHANICAL | long_term | `.flywheel/rules/L033-L79-storage-override-receipts-are-mechanical.md` |
| 34 | L80 — CLOSED-BEAD-AUDIT-MINING | long_term | `.flywheel/rules/L034-L80-closed-bead-audit-mining.md` |
| 35 | L81 — DOCS-ARE-LOAD-BEARING-CROSS-PANE-VALIDATED | long_term | `.flywheel/rules/L035-L81-docs-are-load-bearing-cross-pane-validated.md` |
| 36 | L82 — CANONICAL-CLI-SCOPING-MANDATORY-FOR-ALL-FLYWHEEL-CLIS | long_term | `.flywheel/rules/L036-L82-canonical-cli-scoping-mandatory-for-all-flywheel-clis.md` |
| 37 | L83 — FILE-LENGTH-DISCIPLINE-FLEET-WIDE | long_term | `.flywheel/rules/L037-L83-file-length-discipline-fleet-wide.md` |
| 38 | L84 — LOCKED-WORKER-IDENTITIES-CANONICAL | long_term | `.flywheel/rules/L038-L84-locked-worker-identities-canonical.md` |
| 39 | L85 — IDLE-STATE-CLASS-CANONICAL | long_term | `.flywheel/rules/L039-L85-idle-state-class-canonical.md` |
| 40 | L86 — CROSS-SESSION-CALLBACK-RECEIVER-MUST-BE-LIVE | long_term | `.flywheel/rules/L040-L86-cross-session-callback-receiver-must-be-live.md` |
| 41 | L87 — STALE-ERROR-TEXT-AUTO-PING-RECOVERY | temporary | `.flywheel/rules/L041-L87-stale-error-text-auto-ping-recovery.md` |
| 42 | L88 — PUBLISHABILITY-BAR-CANONICAL | long_term | `.flywheel/rules/L042-L88-publishability-bar-canonical.md` |
| 43 | L89 — ZESTSTREAM-VOICE-PUBLIC-REPO-CANONICAL | long_term | `.flywheel/rules/L043-L89-zeststream-voice-public-repo-canonical.md` |
| 44 | L90 — PANE-ACTION-PLAN-REQUIRES-LIVE-CAPTURE | long_term | `.flywheel/rules/L044-L90-pane-action-plan-requires-live-capture.md` |
| 45 | L91 — DISPATCH-DELIVERY-IS-A-FOUR-STATE-RECEIPT | long_term | `.flywheel/rules/L045-L91-dispatch-delivery-is-a-four-state-receipt.md` |
| 46 | L92 — AUDIT-FINDINGS-ROUTE-BY-DATA | long_term | `.flywheel/rules/L046-L92-audit-findings-route-by-data.md` |
| 47 | L93 — JEFF-ISSUE-REQUIRES-WORKAROUND-RESEARCH-FIRST | long_term | `.flywheel/rules/L047-L93-jeff-issue-requires-workaround-research-first.md` |
| 48 | L94 — SHARED-SQLITE-WRITES-MUST-SERIALIZE | long_term | `.flywheel/rules/L048-L94-shared-sqlite-writes-must-serialize.md` |
| 49 | L95 — WORKER-STALL-RECOVERY-PROTOCOL | long_term | `.flywheel/rules/L049-L95-worker-stall-recovery-protocol.md` |
| 50 | L96 — DOCTRINE-LANDS-AS-3-SURFACE-DIFF-OR-DOES-NOT-LAND | long_term | `.flywheel/rules/L050-L96-doctrine-lands-as-3-surface-diff-or-does-not-land.md` |
| 51 | L97 — ORCH-DISPATCHES-ONLY-TO-KNOWN-WORKERS | long_term | `.flywheel/rules/L051-L97-orch-dispatches-only-to-known-workers.md` |
| 52 | L98 — ARCHITECTURE-HEALTH-MEASURED-NOT-INDIVIDUALS | long_term | `.flywheel/rules/L052-L98-architecture-health-measured-not-individuals.md` |
| 53 | L99 — WORKER-RECOVERY-SLO-180S | long_term | `.flywheel/rules/L053-L99-worker-recovery-slo-180s.md` |
| 54 | L100 — IDENTITY-PRIMARY-KEY-IS-SESSION-PANE-PROJECT | long_term | `.flywheel/rules/L054-L100-identity-primary-key-is-session-pane-project.md` |
| 55 | L101 — FLYWHEEL-OWNS-CONTINUOUS-FLEET-PRODUCTIVITY | long_term | `.flywheel/rules/L055-L101-flywheel-owns-continuous-fleet-productivity.md` |
| 56 | L102 — META-RULE-CACHE-MUST-REFRESH-ON-TICK | long_term | `.flywheel/rules/L056-L102-meta-rule-cache-must-refresh-on-tick.md` |
| 57 | L103 — FLEET-CONFORMANCE-SCORE-IS-THE-GATE | long_term | `.flywheel/rules/L057-L103-fleet-conformance-score-is-the-gate.md` |
| 58 | L104 — FLEET-COMMS-MEASURED-NOT-ASSUMED | long_term | `.flywheel/rules/L058-L104-fleet-comms-measured-not-assumed.md` |
| 59 | L105 — PROCESS-GAPS-ARE-MEASURED-AND-AUTO-ROUTED | long_term | `.flywheel/rules/L059-L105-process-gaps-are-measured-and-auto-routed.md` |
| 60 | L106 — FLEET-HEALTH-IS-A-SINGLE-NUMBER-AGGREGATED-FROM-8-SPINES | long_term | `.flywheel/rules/L060-L106-fleet-health-is-a-single-number-aggregated-from-8-spines.md` |
| 61 | L107 — SHARED-SURFACE-WRITES-MUST-RESERVE-ACROSS-PANES | long_term | `.flywheel/rules/L061-L107-shared-surface-writes-must-reserve-across-panes.md` |
| 62 | L108 — META-RULE-CACHE-IS-CACHE-NOT-CONVERGENCE-GATE | long_term | `.flywheel/rules/L062-L108-meta-rule-cache-is-cache-not-convergence-gate.md` |
| 63 | L109 — WIRE-OR-EXPLAIN-IS-A-FLOW-GATE | long_term | `.flywheel/rules/L063-L109-wire-or-explain-is-a-flow-gate.md` |
| 64 | L110 — SUBSTRATE-PRIMITIVES-DECLARE-SELF-REPAIR-LOOP | long_term | `.flywheel/rules/L064-L110-substrate-primitives-declare-self-repair-loop.md` |
| 65 | L111 — REAL-TIME-QUALITY-BAR-ON-EVERY-WORK-BODY | long_term | `.flywheel/rules/L065-L111-real-time-quality-bar-on-every-work-body.md` |
| 66 | L115 — PEER-ORCH-RECOVERY-PERMIT-GATE | long_term | `.flywheel/rules/L066-L115-peer-orch-recovery-permit-gate.md` |
| 67 | L116 — TICK-IS-PROCESS-NOT-DOCUMENT | long_term | `.flywheel/rules/L067-L116-tick-is-process-not-document.md` |
| 68 | L117 — PEER-ORCH-FREEZE-MONITOR-IS-A-DRIVER | long_term | `.flywheel/rules/L068-L117-peer-orch-freeze-monitor-is-a-driver.md` |
| 69 | L118 — STABLE-FAILURE-REASON-CODES-BEFORE-PROSE | long_term | `.flywheel/rules/L069-L118-stable-failure-reason-codes-before-prose.md` |
| 70 | L119 — TEMPLATES-NAME-SOURCES-NOT-VALUES | long_term | `.flywheel/rules/L070-L119-templates-name-sources-not-values.md` |
| 71 | L120 — DISPATCH-CALLBACK-MUST-INCLUDE-BR-CLOSE-EXECUTED | long_term | `.flywheel/rules/L071-L120-dispatch-callback-must-include-br-close-executed.md` |
| 72 | L121 — LAUNCHD-SERIALIZE-WRAPPERS-MUST-BE-KILL-RESILIENT | long_term | `.flywheel/rules/L072-L121-launchd-serialize-wrappers-must-be-kill-resilient.md` |
| 73 | L122 — BULK-MUTATION-SCRIPTS-MUST-HAVE-SURGICAL-BOUNDS | long_term | `.flywheel/rules/L073-L122-bulk-mutation-scripts-must-have-surgical-bounds.md` |
| 74 | L123 — L29-RAW-TMUX-HISTORICAL-DEBT-MUST-BE-DOCTOR-VISIBLE | long_term | `.flywheel/rules/L074-L123-l29-raw-tmux-historical-debt-must-be-doctor-visible.md` |
| 75 | L124 — SUBSTRATE-DISCIPLINE-NO-ORCHESTRATOR-PAUSE | long_term | `.flywheel/rules/L075-L124-substrate-discipline-no-orchestrator-pause.md` |
| 76 | L125 — ENV-FILE-IS-SEALED-SUBSTRATE | long_term | `.flywheel/rules/L076-L125-env-file-is-sealed-substrate.md` |
| 77 | L126 — EVIDENCE-PACK-REPLACES-SELF-GRADE | long_term | `.flywheel/rules/L077-L126-evidence-pack-replaces-self-grade.md` |
| 78 | L127 — PREDICTION-LOCK-RECEIPTS | long_term | `.flywheel/rules/L078-L127-prediction-lock-receipts.md` |
| 79 | L128 — PLAN-CONVERGENCE-PROVED-WITH-DATA | long_term | `.flywheel/rules/L079-L128-plan-convergence-proved-with-data.md` |
| 80 | L129 — WORKER-SUBSTRATE-EXPLICIT | long_term | `.flywheel/rules/L080-L129-worker-substrate-explicit.md` |
| 81 | L130 — DISPATCH-SKILL-REQUIRED-HOOK-GATE | long_term | `.flywheel/rules/L081-L130-dispatch-skill-required-hook-gate.md` |
| 82 | L131 — PLIST-COVERAGE-DRIFT-DOCTOR-INVARIANT | long_term | `.flywheel/rules/L082-L131-plist-coverage-drift-doctor-invariant.md` |
| 83 | L132 — SCHEMA-VERSIONED-INGESTION-JEFF-DOCTRINE | long_term | `.flywheel/rules/L083-L132-schema-versioned-ingestion-jeff-doctrine.md` |
| 84 | L133 — DATA-BACKED-DEFERRAL-DOCTOR-SURFACE | long_term | `.flywheel/rules/L084-L133-data-backed-deferral-doctor-surface.md` |
| 85 | L134 — TEAM-ROSTER-FRESHNESS-GATES-LOOPS | long_term | `.flywheel/rules/L085-L134-team-roster-freshness-gates-loops.md` |
| 86 | L135 — SKILL-DISCOVERY-CALLBACK-FIELDS | long_term | `.flywheel/rules/L086-L135-skill-discovery-callback-fields.md` |
| 87 | L136 — ABSOLUTE-PATH-KEYING-FOR-CROSS-PROJECT-STATE | long_term | `.flywheel/rules/L087-L136-absolute-path-keying-for-cross-project-state.md` |
| 88 | L137 — BEADS-MUTATIONS-USE-A-SERIAL-WRITE-LANE | long_term | `.flywheel/rules/L088-L137-beads-mutations-use-a-serial-write-lane.md` |
| 89 | L138 — IDENTITY-DEFERRAL-AFTER-RESERVATION-CLEAR | long_term | `.flywheel/rules/L089-L138-identity-deferral-after-reservation-clear.md` |
| 90 | L139 — TMP-LIFECYCLE-IS-A-CLOSE-GATE-AND-DOCTOR-INVARIANT | long_term | `.flywheel/rules/L090-L139-tmp-lifecycle-is-a-close-gate-and-doctor-invariant.md` |
| 91 | L140 — DISPATCH-AND-VERIFY-MANDATORY | long_term | `.flywheel/rules/L091-L140-dispatch-and-verify-mandatory.md` |
| 92 | L141 — LOOP-MUST-BE-ACCRETIVE | long_term | `.flywheel/rules/L092-L141-loop-must-be-accretive.md` |
| 93 | L142 — CODEX-PREPARED-CHEVRON-NOT-STALE-BUFFER | long_term | `.flywheel/rules/L093-L142-codex-prepared-chevron-not-stale-buffer.md` |
| 94 | L143 — WORKER-CLOSE-REQUIRES-GIT-COMMIT | long_term | `.flywheel/rules/L094-L143-worker-close-requires-git-commit.md` |
| 95 | L144 — GIT-STASH-JANITOR-FLEET-HYGIENE | long_term | `.flywheel/rules/L095-L144-git-stash-janitor-fleet-hygiene.md` |
| 96 | L145 — ORCH-HANDSHAKES-NEVER-GATE-ON-JOSHUA | long_term | `.flywheel/rules/L096-L145-orch-handshakes-never-gate-on-joshua.md` |
| 97 | L146 — SKILL-ENHANCE-HONORS-JSM-MANAGEMENT | long_term | `.flywheel/rules/L097-L146-skill-enhance-honors-jsm-management.md` |
| 98 | L147 — SKILL-AUTORESEARCH-ROUTES-BY-TOOLING-SUBSTRATE | long_term | `.flywheel/rules/L098-L147-skill-autoresearch-routes-by-tooling-substrate.md` |
| 99 | L148 — PUBLIC-READY-DEFAULT | long_term | `.flywheel/rules/L099-L148-public-ready-default.md` |
| 100 | L149 — PRE-COMMIT-GITLEAKS-MANDATORY | long_term | `.flywheel/rules/L100-L149-pre-commit-gitleaks-mandatory.md` |
| 101 | L150 — SKILL-NAMING-CONSTRAINT | long_term | `.flywheel/rules/L101-L150-skill-naming-constraint.md` |
| 102 | L151 — JEFFREY-COMMENT-RESPONSE-SLA | long_term | `.flywheel/rules/L102-L151-jeffrey-comment-response-sla.md` |
| 103 | L152 — COORDINATOR-DAEMON-CANONICAL-DISPATCH | long_term | `.flywheel/rules/L103-L152-coordinator-daemon-canonical-dispatch.md` |
| 104 | L153 — CAPTURE-PROVENANCE-CANONICAL | long_term | `.flywheel/rules/L104-L153-capture-provenance-canonical.md` |
| 105 | L154 — CLOSURE-EVIDENCE-CONTRACT-VERSION-ANCHOR | long_term | `.flywheel/rules/L105-L154-closure-evidence-contract-version-anchor.md` |
| 106 | L155 — CLOSURE-EVIDENCE-PUBLIC-LENS-ANCHOR | long_term | `.flywheel/rules/L106-L155-closure-evidence-public-lens-anchor.md` |
| 107 | L156 — INBOX-DISCIPLINE-0TH-PROBE | long_term | `.flywheel/rules/L107-L156-inbox-discipline-0th-probe.md` |
| 108 | L157 — OUTBOX-DISCIPLINE-CROSS-ORCH-SHIP-NOTIFICATION | long_term | `.flywheel/rules/L108-L157-outbox-discipline-cross-orch-ship-notification.md` |
| 109 | L168 — EVERY-CONSUMER-REPO-MUST-DECLARE-ZS-TENANT-YAML-AT-ROOT | long_term | `.flywheel/rules/L109-L168-every-consumer-repo-must-declare-zs-tenant-yaml-at-root.md` |
<!-- END-RULES-INDEX -->

<!-- BMBUB-PENDING (template held behind canonical for L154-L167; backfill on next propagator-class-aware-ownership-gate ship) -->

## Tenant routing (Hard Rule — L168)

Every consumer repo MUST declare its tenant routing at the repo root via `.zs-tenant.yaml`. Run `/zs:project-bootstrap <slug>` to generate the declaration + CI wiring.

Required hooks once bootstrapped:
- `pnpm secrets:doctor` (or equivalent) MUST pass in CI BEFORE deploy
- DB migrations MUST gate on `zs-verify-supabase-tenant` against the declared Supabase ref
- Deploy fails with: `"Run /zs:project-bootstrap <slug> to declare tenant routing for this repo."` if `.zs-tenant.yaml` is absent

Origin: cross-Infisical-Supabase tenant collision (proof-product:1 TIER-3 <timestamp>; 66 migrations almost ran against {insurance-client} production). {operator}-directive PROMOTED-IMMEDIATE.

<!-- END-CANONICAL-FLYWHEEL-DOCTRINE -->
