---
title: "Coordination Layer Audit - 2026-05-08"
type: plan
created: 2026-05-07
bead: flywheel-self
frontmatter_source: scaffold-doc-frontmatter
---

# Coordination Layer Audit - 2026-05-08

Bead: `flywheel-r41sn`

Scope: NTM canonical surfaces, Agent Mail MCP coordination, file reservations,
dispatch-log substrate, doctrine-broadcast file sidechannel, callback contracts,
`_shared:dispatch-template`, and `_shared:close-handler`.

Socraticode receipt: `socraticode_queries=6`, project
`/Users/josh/Developer/flywheel`, K=10 each. Queries covered `ntm send`,
`dispatch-log`, `callback`, `agent-mail`, `broadcast`, and `monitor`; returned
60 result chunks.

## 1. Inventory

| Surface | Kind | Citation | Current role |
|---|---|---|---|
| NTM surface inventory | canonical inventory | `.flywheel/NTM-SURFACE-INVENTORY.md:15-28`, `.flywheel/NTM-SURFACE-INVENTORY.md:147` | Primary inventory of 108 NTM surfaces. Counts: 24 `VERIFIED-USE`, 12 `LATENT-USE`, 25 `WIRE-IT-QUEUED`, 14 `RECLASSIFIED-EXCLUDED`, 6 `RECLASSIFIED-WRAP-ALIAS`, 5 `RECLASSIFIED-ISSUE`, plus 8 prior issue candidates and 5 prior excluded rows. |
| NTM inventory rule | doctrine table preface | `.flywheel/NTM-SURFACE-INVENTORY.md:3-8`, `.flywheel/NTM-SURFACE-INVENTORY.md:32-36` | Defines USE / ISSUE / WRAP; no competing implementations when NTM has the function. |
| NTM pane I/O doctrine | AGENTS L29 | `AGENTS.md:95-107` | All pane operations route through NTM verbs; `ntm send`, `copy`, `grep`, `health`, `save` are canonical. |
| `/flywheel:ntm` slash wrapper | command doc | `/Users/josh/.claude/commands/flywheel/ntm.md:1-4`, `/Users/josh/.claude/commands/flywheel/ntm.md:18-25` | Ambient wrapper that keeps agents on the NTM surface and logs repo-local operations. |
| NTM `send` and worker dispatch | command/script | `/Users/josh/.claude/commands/flywheel/ntm.md:28-39`, `.flywheel/scripts/dispatch-and-log.sh:80-98` | Worker prompt delivery; `dispatch-and-log.sh` calls `ntm assign`, `ntm send`, and `ntm history`, then appends dispatch-log rows. |
| NTM `spawn` | inventory + native help | `.flywheel/NTM-SURFACE-INVENTORY.md:127`, `/Users/josh/.claude/commands/flywheel/ntm.md:97-100` | Session/agent launch surface; currently a wrap alias in onboarding, with native stagger flags observed by `ntm spawn --help`. |
| NTM verified-use rows | inventory rows | `.flywheel/NTM-SURFACE-INVENTORY.md:38`, `.flywheel/NTM-SURFACE-INVENTORY.md:44`, `.flywheel/NTM-SURFACE-INVENTORY.md:74`, `.flywheel/NTM-SURFACE-INVENTORY.md:121` | Verified native-use surfaces are load-bearing by definition; examples include `activity`, `assign`, `health`, and `send`. |
| NTM latent-use rows | inventory rows | `.flywheel/NTM-SURFACE-INVENTORY.md:49`, `.flywheel/NTM-SURFACE-INVENTORY.md:60`, `.flywheel/NTM-SURFACE-INVENTORY.md:89`, `.flywheel/NTM-SURFACE-INVENTORY.md:125` | Watch-list surfaces with 1-2 callsites or focused regression need: `bugs`, `copy`, `message`, `setup`. |
| NTM not-wired disposition report | audit report | `.flywheel/PLANS/ntm-surface-wire-in-USE-ISSUE-WRAP-2026-05-07/12-NOT-WIRED-DISPOSITIONS.md:9-17`, `.flywheel/PLANS/ntm-surface-wire-in-USE-ISSUE-WRAP-2026-05-07/12-NOT-WIRED-DISPOSITIONS.md:21-72` | Classifies the 50 not-wired rows after 500 Socraticode searches and 50 help probes. |
| Agent Mail skill | skill | `/Users/josh/.claude/skills/agent-mail/SKILL.md:1-7`, `/Users/josh/.claude/skills/agent-mail/SKILL.md:15-24` | MCP Agent Mail coordination: identities, messages, inbox, contact handling, file reservations. |
| Agent Mail file reservations | skill section | `/Users/josh/.claude/skills/agent-mail/SKILL.md:79-107`, `/Users/josh/.claude/skills/agent-mail/SKILL.md:109-124` | Reserve before editing; release when done; explicit conflict handling. |
| L51 dispatch file reservations | AGENTS L51 | `AGENTS.md:189-216` | Every edit-capable worker dispatch must reserve files through Agent Mail before editing and report `files_reserved` / `files_released`. |
| Worker-tick file reservation step | command doc | `/Users/josh/.claude/commands/flywheel/worker-tick.md:53-61`, `/Users/josh/.claude/commands/flywheel/worker-tick.md:170-172` | Worker execution contract reserves before edit, stages explicit paths, but still says to release after callback. |
| Shared-surface reservation checker | command contract | `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md:203-252` | Pane-level staging collision guard for shared surfaces on top of Agent Mail reservations. |
| Dispatch template callback contract | shared command | `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md:28-45`, `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md:52-70` | Required DONE/BLOCKED fields: Socraticode, file reservations, bead/no-bead receipt, fuckups, compliance pack, callback verification. |
| Dispatch delivery verification | shared command | `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md:254-285`, `AGENTS.md:2173-2212` | Four-state dispatch/callback delivery proof; `ntm send` transport acceptance alone is insufficient. |
| Close handler | shared command | `/Users/josh/.claude/commands/flywheel/_shared/close-handler.md:1-18`, `/Users/josh/.claude/commands/flywheel/_shared/close-handler.md:35-52` | Pre-summary callback validation and compliance evidence-pack validation before bead close. |
| L120 callback close field | AGENTS L120 | `AGENTS.md:3443-3490` | DONE callback must include `br_close_executed`; `br close` must run before callback. |
| L126 compliance pack field | AGENTS L126 | `AGENTS.md:3703-3754` | New DONE callbacks include `compliance_score` and `compliance_pack_path`; self-grades are no longer close facts. |
| Dispatch-log schema | schema + validator | `.flywheel/validation-schema/v1/dispatch-log-entry-v2.schema.json:1-23`, `.flywheel/scripts/dispatch-log-schema-validator.sh:28-35` | Canonical dispatch ledger row shape, including mission fitness and callback fields; validator scans and can write sidecar receipts. |
| Dispatch-log live file | ledger | `.flywheel/dispatch-log.jsonl:1`, `.flywheel/scripts/dispatch-and-log.sh:92-107` | Repo-local JSONL event substrate for sent dispatches, callback receipt updates, and auto-refill rows. |
| `/loop` dynamic Monitor | command doc + test | `/Users/josh/.claude/commands/loop.md:33-59`, `tests/test_loop_dynamic_mode_arms_monitor.sh:64-85` | Event-driven wake from `dispatch-log.jsonl` callback lines; schedule wake is fallback only. |
| Hot-pane refill after callback reap | command/script/test | `/Users/josh/.claude/commands/flywheel/tick.md:1012-1063`, `.flywheel/scripts/auto-refill-decision-log.sh:241-290`, `tests/test_hot_pane_refill_after_callback_reap.sh:42-59` | After callback reap, re-check pane state, capacity, ready work, and dispatch same tick. |
| Doctrine-broadcast send sidechannel | script | `.flywheel/scripts/doctrine-broadcast-send.sh:16-25`, `.flywheel/scripts/doctrine-broadcast-send.sh:90-141` | File-based cross-orch doctrine broadcast writer; avoids Agent Mail contact-approval gate. |
| Doctrine-broadcast tail sidechannel | script | `/Users/josh/.claude/skills/.flywheel/scripts/doctrine-broadcast-tail.sh:10-19`, `/Users/josh/.claude/skills/.flywheel/scripts/doctrine-broadcast-tail.sh:66-92` | Peer-side reader and processed-id ledger for doctrine broadcast inboxes. |
| Doctrine-broadcast receipts | receipt files | `.flywheel/receipts/doctrine-broadcasts/doctrine-147132a310178b3a.json:1`, `.flywheel/receipts/doctrine-broadcasts/doctrine-22c6cbe673fb04d4.json:1`, `.flywheel/receipts/doctrine-broadcasts/doctrine-ccc69aeb1ffe4c11.json:1`, `.flywheel/receipts/doctrine-broadcasts/doctrine-f9f561a306a723cf.json:1` | Four broadcasts delivered by file sidechannel. |
| Fleet comms health probe | script | `.flywheel/scripts/fleet-comms-health-probe.sh:15-30`, `.flywheel/scripts/fleet-comms-health-probe.sh:121-137` | Measures cross-orch communication health via Agent Mail token freshness, coordination logs, topology, and active loops. |
| External coordination doctrine | research doc | `.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:44-52`, `.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:65-75` | Public benchmark: 30s stagger, Agent Mail file reservations, bv routing, no thundering herd, no missing Agent Mail. |

Inventory count: 27 rows.

## 2. Load-bearing

Callsite scan command:

```bash
for term in 'ntm send' 'dispatch-log' 'callback' 'agent-mail' \
  'doctrine-broadcast' 'broadcast' 'monitor' 'file_reservation_paths' \
  'macro_start_session' 'dispatch-template' 'close-handler' 'ntm spawn' \
  'stagger' 'sleep 30'; do
  rg -l --fixed-strings "$term" . /Users/josh/.claude/commands/flywheel \
    /Users/josh/.claude/skills/.flywheel /Users/josh/.claude/skills/agent-mail \
    2>/dev/null | wc -l
done
```

Observed unique-file counts: `ntm send=212`, `dispatch-log=239`,
`callback=676`, `agent-mail=309`, `doctrine-broadcast=10`,
`broadcast=103`, `monitor=224`, `file_reservation_paths=14`,
`macro_start_session=14`, `dispatch-template=87`, `close-handler=15`,
`ntm spawn=12`, `stagger=8`, `sleep 30=3`.

| Surface | Why load-bearing | Evidence |
|---|---|---|
| NTM verified-use cohort | `VERIFIED-USE` rows have measured callsites and own runtime transport/state primitives. | Inventory headline counts at `.flywheel/NTM-SURFACE-INVENTORY.md:17-27`; examples: `send` has 48 verified callsites at `.flywheel/NTM-SURFACE-INVENTORY.md:121`, `health` has 19 at `.flywheel/NTM-SURFACE-INVENTORY.md:74`, `respawn` has 26 at `.flywheel/NTM-SURFACE-INVENTORY.md:110`, `wait` has 14 at `.flywheel/NTM-SURFACE-INVENTORY.md:139`. |
| NTM latent-use cohort | `LATENT-USE` rows are not vestigial; they are watch-list canonical surfaces with 1-2 callsites or focused regression probes pending. | `LATENT-USE` count at `.flywheel/NTM-SURFACE-INVENTORY.md:22`; examples at `.flywheel/NTM-SURFACE-INVENTORY.md:49`, `.flywheel/NTM-SURFACE-INVENTORY.md:60`, `.flywheel/NTM-SURFACE-INVENTORY.md:89`, `.flywheel/NTM-SURFACE-INVENTORY.md:125`. |
| `ntm send` / dispatch transport | Critical path for every worker dispatch and callback; raw transport is now wrapped by delivery and callback proof. | L29 usage at `AGENTS.md:97-103`; L91 four-state receipt at `AGENTS.md:2184-2212`; `dispatch-and-log.sh` sends and records native send/history at `.flywheel/scripts/dispatch-and-log.sh:80-98`. |
| `dispatch-log.jsonl` | Event substrate for dispatches, callbacks, monitor wake, auto-refill, validation sidecars, and mission-fitness enrichments. | Schema required fields at `.flywheel/validation-schema/v1/dispatch-log-entry-v2.schema.json:8-23`; validator scans `.flywheel/dispatch-log.jsonl` at `.flywheel/scripts/dispatch-log-schema-validator.sh:144-154`; `/loop` Monitor tails it at `/Users/josh/.claude/commands/loop.md:41-53`. |
| Callback envelope contract | Callback is the worker termination signal; missing fields hide failures or orphan follow-up work. | Required fields at `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md:28-70`; delivery verification at `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md:254-285`; L120 close-before-callback at `AGENTS.md:3454-3479`. |
| Close handler | Orchestrator must validate callbacks and compliance packs before summary or close. | Close handler Step 0 at `/Users/josh/.claude/commands/flywheel/_shared/close-handler.md:6-18`; compliance pack check at `/Users/josh/.claude/commands/flywheel/_shared/close-handler.md:35-52`; evidence-pack rule at `AGENTS.md:3714-3727`. |
| Agent Mail file reservations | Prevents cross-pane edits from racing; also required by dispatch and worker-tick contracts. | Skill use table at `/Users/josh/.claude/skills/agent-mail/SKILL.md:17-24`; reservation procedure at `/Users/josh/.claude/skills/agent-mail/SKILL.md:79-107`; L51 at `AGENTS.md:200-216`; worker-tick pre-edit reservation at `/Users/josh/.claude/commands/flywheel/worker-tick.md:53-61`. |
| Shared-surface reservation checker | Agent Mail prevents file races, but L107 prevents pane-level staging collisions on canonical shared surfaces. | Shared-surface block at `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md:203-252`; Socraticode returned L107 evidence from `AGENTS.md:2881-2980`; tests at `tests/shared-surface-reservation-check.sh:1-86`. |
| Doctrine-broadcast sidechannel | Newly load-bearing because Agent Mail contact approval blocked fleet doctrine broadcast; sidechannel delivered four broadcasts with zero Agent Mail calls. | zc9ie requirement to use Agent Mail at `.beads/issues.jsonl:1126`; 5dmg7 diagnosis at `.beads/issues.jsonl:285`; send script rows at `.flywheel/scripts/doctrine-broadcast-send.sh:90-141`; four receipts at `.flywheel/receipts/doctrine-broadcasts/doctrine-147132a310178b3a.json:1` and sibling receipt files. |
| `/loop` dispatch-log Monitor | Changes coordination from time-based polling to event-driven callback wake. | Dynamic-mode contract at `/Users/josh/.claude/commands/loop.md:33-59`; latency goal at `/Users/josh/.claude/commands/loop.md:86-94`; regression test at `tests/test_loop_dynamic_mode_arms_monitor.sh:64-85`. |
| Hot-pane refill after callback reap | Keeps freed panes from idling until the next wake; this is coordination throughput, not just worker execution. | Tick contract at `/Users/josh/.claude/commands/flywheel/tick.md:1012-1035`; refill implementation at `.flywheel/scripts/auto-refill-decision-log.sh:241-290`; fixtures at `tests/test_hot_pane_refill_after_callback_reap.sh:42-111`. |
| NTM wire-in program | 12 native surfaces wired today, reducing hand-rolled coordination code and making dispatch substrate healthier. | Not-wired counts at `.flywheel/PLANS/ntm-surface-wire-in-USE-ISSUE-WRAP-2026-05-07/12-NOT-WIRED-DISPOSITIONS.md:9-17`; WIRE-IT manifest begins at `.flywheel/PLANS/ntm-surface-wire-in-USE-ISSUE-WRAP-2026-05-07/12-NOT-WIRED-DISPOSITIONS.md:74-130`; inventory rollout rule at `.flywheel/NTM-SURFACE-INVENTORY.md:239-247`. |
| `ntm spawn` stagger support | Critical because public doctrine explicitly calls out thundering herd; native help shows `--stagger-mode` and `--stagger-delay`, while current flywheel onboarding treats spawn as wrapper alias. | External rule at `.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:49-51`, `.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:182-185`; inventory row at `.flywheel/NTM-SURFACE-INVENTORY.md:127`; Agent Mail registration branch has one `sleep 30` at `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md:160-177`, but no universal spawn default. |
| Fleet comms health probe | Coordination must be measured, not inferred from loop markers. | Probe constants and inputs at `.flywheel/scripts/fleet-comms-health-probe.sh:15-30`; session discovery at `.flywheel/scripts/fleet-comms-health-probe.sh:121-137`; tests at `tests/fleet-comms-health-probe.sh:58-153`. |

Load-bearing count: 14.

## 3. Vestigial

| Surface | Evidence | Disposition |
|---|---|---|
| NTM `RECLASSIFIED-EXCLUDED` rows | 14 rows are explicitly reclassified out of automated flywheel coordination: headline count at `.flywheel/NTM-SURFACE-INVENTORY.md:24`; examples include `adopt` at `.flywheel/NTM-SURFACE-INVENTORY.md:40`, `attach` at `.flywheel/NTM-SURFACE-INVENTORY.md:45`, `kill` at `.flywheel/NTM-SURFACE-INVENTORY.md:81`, and `view` at `.flywheel/NTM-SURFACE-INVENTORY.md:138`. | Vestigial-by-doctrine. Keep in inventory for audit history, but do not dispatch wire-in work. |
| NTM prior excluded physical rows | Inventory says 5 prior excluded rows sit outside the 86-row verification cohort at `.flywheel/NTM-SURFACE-INVENTORY.md:27-28`. | Keep as explicit no-fit rows only; no coordination investment. |
| NTM `RECLASSIFIED-WRAP-ALIAS` rows | 6 rows are wrapper aliases, not direct use: count at `.flywheel/NTM-SURFACE-INVENTORY.md:25`; examples `bind` at `.flywheel/NTM-SURFACE-INVENTORY.md:48`, `init` at `.flywheel/NTM-SURFACE-INVENTORY.md:78`, `spawn` at `.flywheel/NTM-SURFACE-INVENTORY.md:127`. | Not dead, but vestigial as direct NTM rows. Keep wrapper ownership clear. |
| NTM `RECLASSIFIED-ISSUE` rows | 5 rows require upstream contract clarification: count at `.flywheel/NTM-SURFACE-INVENTORY.md:26`; examples `controller` at `.flywheel/NTM-SURFACE-INVENTORY.md:58`, `guards` at `.flywheel/NTM-SURFACE-INVENTORY.md:72`, `hooks` at `.flywheel/NTM-SURFACE-INVENTORY.md:77`. | Sunset as active-use claims until Jeff issue manifests exist and close. |
| NTM issue candidates `lock` / `locks` / `unlock` | Inventory treats Agent Mail locking parity as unresolved issue candidates at `.flywheel/NTM-SURFACE-INVENTORY.md:84-85`, `.flywheel/NTM-SURFACE-INVENTORY.md:135`; research bead exists at `.beads/issues.jsonl:360`. | Vestigial as coordination implementation surfaces for now. Use MCP Agent Mail directly until field parity is proven. |
| W3a coordinator / pipeline shadow wrappers | Inventory says coordinator shadow wrapper is blocked by ntm#124 and should be deleted after native daemon unblocks at `.flywheel/NTM-SURFACE-INVENTORY.md:59`; pipeline shadow wrapper has same post-#124 deletion note at `.flywheel/NTM-SURFACE-INVENTORY.md:98`; wrap-territory note calls W3aC/W3aP transitional at `.flywheel/NTM-SURFACE-INVENTORY.md:183`. | Sunset candidates with trigger: delete after ntm#124 lands and native daemon is enabled. |
| `worker-tick.md` release-after-callback wording | Agent Mail says release before callback at `/Users/josh/.claude/skills/agent-mail/SKILL.md:115-120`; dispatch callbacks require `files_released=` in the DONE line at `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md:44`, `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md:59-64`; worker-tick still says release after callback at `/Users/josh/.claude/commands/flywheel/worker-tick.md:170-172`. | Superseded contract text. Fix to `br close -> release_file_reservations -> callback`, matching Agent Mail and callback truthfulness. |
| Legacy short callback shape in `/loop` | `/loop` still says worker callbacks should be a short `DONE <lane> verdict=...` envelope at `/Users/josh/.claude/commands/loop.md:145-149`, while dispatch-template requires the full L50/L51/L52/L53/L120/L126 envelope at `/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md:28-70`. | Superseded. Keep short summary as human-facing prose only after machine callback fields are present. |
| Agent Mail contact-approval path for fleet doctrine broadcast | zc9ie expected `send_message` to four peer orch identities at `.beads/issues.jsonl:1126`; 5dmg7 records that recipient-side approval created an unacceptable phantom-blocker at `.beads/issues.jsonl:285`; doctrine-broadcast sidechannel now writes inbox rows directly at `.flywheel/scripts/doctrine-broadcast-send.sh:20-24`. | Sunset for fleet doctrine broadcast. Agent Mail remains valid for normal per-agent messaging and reservations, but doctrine broadcast should stay on file sidechannel until fleet-trust-ring exists. |

Vestigial/superseded count: 9.

## 4. Missing per agent-flywheel.com gap analysis

### Gap 1: Stagger-spawn 30s+ discipline

agent-flywheel.com names staggered swarm launch as phase 5 and explicitly warns
against thundering herd (`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:49-51`,
`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:72-75`).
Its local gap analysis says to check `ntm spawn` flags and add or document the
approximation (`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:182-185`).

Observed: native `ntm spawn --help` exposes `--stagger-mode`,
`--stagger-delay` default 30s for fixed mode, legacy `--stagger`, and smart
mode. Flywheel does not yet make `--stagger-mode=fixed --stagger-delay=30s` or
`--stagger-mode=smart` a universal wrapper default. The only hard 30-second
delay found is Agent Mail registration re-probe in dispatch-template
(`/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md:160-177`),
not swarm spawn cadence. This is a Tier-2 coordination gap.

### Gap 2: File-reservation discipline via Agent Mail

The public guide treats Agent Mail file reservations as default coordination
(`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:31`,
`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:51`).
Flywheel has the core discipline: Agent Mail skill reserve/release
(`/Users/josh/.claude/skills/agent-mail/SKILL.md:79-107`), L51 dispatch rule
(`AGENTS.md:200-216`), worker-tick pre-edit reservation
(`/Users/josh/.claude/commands/flywheel/worker-tick.md:53-61`), and callback
fields (`/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md:59-64`).

Gap: release ordering is inconsistent. The Agent Mail skill says release before
callback because callback is the boundary (`/Users/josh/.claude/skills/agent-mail/SKILL.md:115-120`),
while worker-tick says release after callback (`/Users/josh/.claude/commands/flywheel/worker-tick.md:170-172`).
That mismatch makes `files_released=` easy to lie about or omit. Discipline is
present but not fully converged.

### Gap 3: Cross-orch broadcast

The public guide warns against "No Agent Mail" but does not address multi-orch
contact approval. Flywheel's gap analysis names the local sidechannel as unique:
`doctrine-broadcast-send.sh` exists because Agent Mail recipient approval gates
intra-fleet handshakes (`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:132-134`).

End-to-end status: PASS for send path. 5dmg7 produced file-based broadcast
inboxes; the send script validates target/body, redacts internal references,
appends a row under `~/.local/state/flywheel/doctrine-broadcasts/`, and writes
a receipt (`.flywheel/scripts/doctrine-broadcast-send.sh:58-69`,
`.flywheel/scripts/doctrine-broadcast-send.sh:112-141`). The tail script reads
unprocessed rows and writes processed receipts
(`/Users/josh/.claude/skills/.flywheel/scripts/doctrine-broadcast-tail.sh:55-87`).
Four receipts exist for `alpsinsurance`, `mobile-eats`, `polymarket-pico-z`,
and `zesttube` (`.flywheel/receipts/doctrine-broadcasts/doctrine-147132a310178b3a.json:1`
and sibling receipt files).

Remaining gap: peer consumption is tick-dependent unless each peer has an
active tail/check in its loop. The sidechannel works as file delivery; the next
hardening step is measured unread age and per-peer consume receipts in
`fleet-comms-health-probe`.

## 5. Lessons learned

Today's evidence says the coordination layer matured from "send prompt and wait"
to "maintain an event substrate."

- zc9ie showed that Agent Mail's contact approval policy is correct for general
  safety but wrong for fleet doctrine propagation. The bead required one Agent
  Mail message per peer, then 5dmg7 diagnosed recipient approval as a phantom
  blocker and recommended the file sidechannel (`.beads/issues.jsonl:1126`,
  `.beads/issues.jsonl:285`).
- 5dmg7 shipped the practical response: four file-sidechannel broadcasts,
  zero Agent Mail sends, and receipts for every target. That is a good local
  workaround because it lowers ceremony for doctrine-only information flow
  without weakening Agent Mail's reservation layer.
- opwu8 and flsau changed the NTM inventory from aspiration to measured native
  callsites: 4 P0 wire-ins plus 8 P1 wire-ins, with 106 native callsites across
  12 surfaces per dispatch evidence and commit history (`c82b351`, `a557c10`,
  `0af69ff`, `d63ad1f`, `3cddc67` through `975f49e`).
- a2lff's 50-surface disposition report is what made opwu8/flsau safe. The
  important part is not the count; it is that each surface has a disposition,
  a reason, and an action, so coordination code can be deleted instead of
  parallelized.
- 7wr3e and ka0xt are the higher-order lesson. The dispatch-log Monitor wakes
  the orchestrator when a callback row appears, and hot-pane refill consumes
  that wake by re-checking pane state, capacity, and ready work in the same
  tick. The result is a closed loop: callback -> validation/reap -> dispatch
  next bead -> log row. Coordination becomes event-driven instead of
  schedule-driven (`/Users/josh/.claude/commands/loop.md:33-59`,
  `/Users/josh/.claude/commands/flywheel/tick.md:1012-1063`).

Body-shape lesson: coordination beads need to name the communication path, the
failure mode, the fallback substrate, and the callback fields. zc9ie was strong
because it named the intended Agent Mail path and verification shape; 5dmg7 was
stronger because it named why that path failed and proposed a file-sidechannel
with acceptance. Future coordination beads should include: source event,
target session/pane/project, transport, delivery receipt, consumption receipt,
reservation/release obligations, and "what happens if the transport is blocked."

## 6. Fix-Bead Manifest

Recommendations only. No beads filed by this audit.

1. **Title:** `[coordination-contract] align reservation release ordering across worker-tick, Agent Mail, and dispatch-template`
   **Priority:** P0
   **Scope:** Update `/Users/josh/.claude/commands/flywheel/worker-tick.md` and any mirrored install/template surfaces so close order is `br close -> release_file_reservations -> ntm send callback`, with callback fields proving both reserved and released.
   **Acceptance:** Worker-tick, Agent Mail skill, dispatch-template, and close-handler agree on ordering; regression test rejects DONE callback with `files_released` absent for edit tasks; no live skill edits unless routed through the owning sync path.

2. **Title:** `[ntm-spawn] make staggered spawn the flywheel default`
   **Priority:** P1
   **Scope:** Audit flywheel spawn/onboard wrappers and add `ntm spawn --stagger-mode=smart` or `--stagger-mode=fixed --stagger-delay=30s` where multi-agent sessions are created.
   **Acceptance:** `rg "ntm spawn"` wrappers show an explicit stagger policy or an explicit no-stagger receipt; test fixture proves generated spawn command contains the selected stagger mode for multi-agent swarms.

3. **Title:** `[doctrine-broadcast] add consume receipts and unread-age doctor signal`
   **Priority:** P1
   **Scope:** Extend doctrine-broadcast tail/fleet-comms health so every peer has `unread_count`, oldest unread age, processed receipt count, and last consumed broadcast id.
   **Acceptance:** Four current broadcast inboxes produce PASS/WARN health rows; unread age over one loop interval warns; peer consume receipt clears the warning; tests cover no inbox, unread, processed, and malformed rows.

Fix beads proposed: 3.
