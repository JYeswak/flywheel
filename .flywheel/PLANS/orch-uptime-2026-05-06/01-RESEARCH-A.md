# Lane A Research: `codex_usage_limit` Detector + `caam-auto-rotate` Primitive

Task: `orch-uptime-plan-2026-05-06`  
Lane: A - DETECTOR + PRIMITIVE design  
Scope: read-only research, no repo code mutations, no `caam activate`, no launchctl calls  
Deliverable: `/tmp/orch-uptime-laneA-detector-primitive-2026-05-06.md`

## Donella Trace

| Field | Trace |
|---|---|
| Boundary | Flywheel stuck detector -> authorization gate -> CAAM vault selector -> Codex panes. |
| Stock | Continuously productive Codex worker panes with usable subscription quota. |
| Flow break | Codex usage-limit text is not a detector subclass, so the recovery loop never reaches CAAM rotation. |
| Loop | Detect usage-limit text -> authorize credential-rotation class -> choose alternate vaulted profile -> activate -> emit recovery ledger -> pane can be respawned/continued by existing loop. |
| Leverage | Meadows #5 rules: add subclass and recovery-class rule. Meadows #6 information flow: recovery receipt visible to doctor. Meadows #4 self-organization: CAAM profile swap is flywheel-decided, not Joshua-gated. |
| Intervention | Extend `codex-template-stuck-detector.sh` v1.2.0 -> v1.3.0, extend `capacity-halt-pane-authorization.sh`, add `caam-auto-rotate-on-usage-limit.sh`, extend recovery ledger schema/tests. |
| Measurement | Forced usage-limit fixture classifies as `codex_usage_limit`; dry-run has zero side effects; apply rotates to alternate CAAM profile and emits valid receipt in <60s; no Joshua page. |

## Socraticode Survey

`socraticode_queries=10` against canonical `/Users/josh/Developer/flywheel`.

Queries covered:

1. `codex-template-stuck-detector subclasses post_completion input_deaf codex_queued_not_submitted`
2. `capacity-halt-pane-authorization recovery_class topology_stale authorization gate`
3. `recovery-doctor-probe recovery ledger schema primitive fired false reason receipt json`
4. `caam activate codex usage limit credential rotation vault profile`
5. `usage limit Limit reached Plan free tier try again in 429 Too Many detector pattern`
6. `codex stuck detector auto recover dispatch table recommended_recovery auto_continue bare_enter respawn`
7. `capacity-halt-auto-continue-primitive dry-run apply JSON receipt rc fired attempted sent recovered`
8. `recovery-ledger.schema.json primitive_name recovery_class failure_class target actor transport post_check`
9. `caam recovery path probe caam list json caam activate auto profile cooldown codex`
10. `worker-auto-respawn-watchdog recovery primitive authorization topology stale capacity halt`

Grounded files/surfaces found:

| Surface | Existing role |
|---|---|
| `.flywheel/scripts/codex-template-stuck-detector.sh` | v1.2.0 detector; subclass list and auto-recover dispatch table. |
| `.flywheel/scripts/capacity-halt-pane-authorization.sh` | Worker-pane authorization gate; currently refuses `topology_stale`. |
| `.flywheel/scripts/capacity-halt-auto-continue-primitive.sh` | Best sibling primitive shape: dry-run default, `--apply`, JSON receipt, auth/budget/lease/post-check fields. |
| `.flywheel/validation-schema/v1/recovery-ledger.schema.json` | Canonical recovery row schema; currently no explicit `recovery_class` property. |
| `.flywheel/scripts/caam-recovery-path-probe.sh` | Existing read-only CAAM substrate probe; validates plists/logs/profiles but does not rotate. |
| `.flywheel/tests/test_caam_recovery_path_probe.sh` | Fixture pattern for CAAM profile/log probing without live mutation. |
| `tests/e2e/e2e_oom_classifier.sh` | Existing classifier regression sweep style for new subclasses. |

## Skill Floor

Skills consulted:

| Skill | Why it applies |
|---|---|
| `caam` | Canonical account switching surface: `caam ls/list`, `caam activate`, cooldown semantics. |
| `codex-cli-tracker` | Codex stuck/freeze patterns; avoid respawn churn and keep issue-class receipts explicit. |
| `socraticode` | Required K>=10 semantic survey before non-trivial code claims. |
| `agent-monitoring` | Detector/recovery loop must expose health, failure class, and recovery success counters. |
| `agent-security` | Credential-touching primitive must not emit secrets and must enforce action authorization outside prompt text. |
| `coding-agent-usage-tracker` | Usage/quota detection belongs in operator automation and should use JSON outputs. |
| `rate-limiting` | 429/Retry-After/limit text forms the detector pattern bank and must avoid retry storms. |
| `beads-br` / `beads-workflow` | Start-bead attempt was required by dispatch, but live `br` failed with BusySnapshot; no repair run due read-only lane. |

## What Exists vs What Is New

| Area | Already there | Lane A change |
|---|---|---|
| Detector subclasses | `alive`, `buffer_stuck`, `post_completion`, `input_deaf`, `post_callback_reminder_template_with_stale_spinner`, `model_at_capacity_halt`, `codex_queued_not_submitted`, `oom_killed_pane`, `unknown_stable`. | Add `codex_usage_limit`; recommended recovery `caam_auto_rotate`. |
| Detector patterns | Capacity halt uses `selected model is at capacity|please try a different model`; queued prompt uses chevron + Working/background. | Add usage-limit regex bank: `usage limit`, `Limit reached`, `rate_limit_exceeded`, `Plan: free tier`, `try again in`, `429 Too Many`. |
| Auto recovery | `buffer_stuck` Enter, capacity auto-continue, queued bare Enter, OOM respawn, post-callback escape/re-prompt. | Route `codex_usage_limit` to new CAAM primitive only when `--auto-recover --apply`. |
| Authorization | Worker panes authorized; protected/unknown/stale topology refused. | Add `--recovery-class credential_rotation`; authorize vault selector swap even when topology is stale. |
| CAAM substrate | Read-only probe exists; live CLI supports `caam ls codex --json`, `caam list codex --json`, `caam status codex --json`, `caam activate --json`. | Add mutating primitive with dry-run default, idempotency ledger, post-check, recovery-ledger receipt. |
| Recovery schema | Required recovery fields cover actor/target/pane role/trauma/transport/post-check/primitive. | Add optional `recovery_class` enum and CAAM-specific receipt fields without breaking legacy rows. |

## Diff-Shaped Extension Plan

### 1. Extend Detector: `.flywheel/scripts/codex-template-stuck-detector.sh`

```diff
- VERSION="codex-stuck-detector.v1.2.0"
+ VERSION="codex-stuck-detector.v1.3.0"

  CAPACITY_HALT_SUBCLASS = "model_at_capacity_halt"
  QUEUED_NOT_SUBMITTED_SUBCLASS = "codex_queued_not_submitted"
  OOM_KILLED_SUBCLASS = "oom_killed_pane"
+ USAGE_LIMIT_SUBCLASS = "codex_usage_limit"
+ USAGE_LIMIT_RE = re.compile(
+   r"(usage limit|Limit reached|rate_limit_exceeded|Plan:\s*free tier|try again in|429\s+Too Many)",
+   re.I,
+ )

  subclasses:[ ... "oom_killed_pane","unknown_stable" ]
+ subclasses:[ ... "oom_killed_pane","codex_usage_limit","unknown_stable" ]

  safe_recovery_policy:{
    ...
+   codex_usage_limit:"caam_auto_rotate"
  }
```

Classifier ordering should be:

```diff
  if hint in {...}:
    subclass = hint
  elif has_oom_killed_signature(t1):
    subclass = OOM_KILLED_SUBCLASS
+ elif has_usage_limit_prompt(t1):
+   subclass = USAGE_LIMIT_SUBCLASS
  elif has_capacity_halt_prompt(t1):
    subclass = CAPACITY_HALT_SUBCLASS
```

Reason: usage-limit text can be stable with or without a chevron prompt. It must beat generic `alive`/`unknown_stable` and should also beat capacity text if a provider wraps a 429 in a generic status panel.

Recovery map:

```diff
  recovery = {
    ...
+   USAGE_LIMIT_SUBCLASS: "caam_auto_rotate",
  }
```

Auto-recover branch:

```diff
+ def run_caam_auto_rotate(session, pane, digest):
+   if not caam_auto_rotate.exists():
+     return {"recovered": False, "returncode": 3, "error": "caam_auto_rotate_primitive_missing"}
+   proc = subprocess.run(
+     [str(caam_auto_rotate), "--tool", "codex", "--session", str(session), "--pane", str(pane), "--digest", digest, "--apply", "--json"],
+     text=True, capture_output=True, env=os.environ.copy()
+   )
+   ...

  elif auto_recover and subclass == OOM_KILLED_SUBCLASS:
    ...
+ elif auto_recover and subclass == USAGE_LIMIT_SUBCLASS:
+   recovery_attempted = "caam_auto_rotate"
+   if apply and not dry_run:
+     recovery_payload = run_caam_auto_rotate(session, pane, hash_t1)
+     recovery_succeeded = bool(recovery_payload.get("rotated")) or recovery_payload.get("returncode") == 0
+   else:
+     recovery_succeeded = False
```

Also update:

- `schema_json fixture` optional `subclass_hint` allowed set.
- Doctor counters: include `codex_usage_limit` in recent stuck class set.
- Human `why`/quickstart text: CAAM rotation is selector swap, not secret rotation.

### 2. New Primitive: `.flywheel/scripts/caam-auto-rotate-on-usage-limit.sh`

Proposed CLI:

```text
caam-auto-rotate-on-usage-limit.sh --tool codex --session flywheel --pane 2 --digest <sha256> --dry-run --json
caam-auto-rotate-on-usage-limit.sh --tool codex --session flywheel --pane 2 --digest <sha256> --apply --json
```

Default mode: dry-run. `--apply` required for mutation.

Algorithm:

1. Validate `tool` is `codex` for v1.0.0.
2. Call authorization gate:
   `capacity-halt-pane-authorization.sh --session <s> --pane <p> --recovery-class credential_rotation --json`.
3. Check idempotency ledger by `identity_key=tool:session:pane:digest`; if prior success exists inside TTL, emit `already_rotated_for_signal`, rc=0, no CAAM mutation.
4. Read profiles via `caam list <tool> --json`; fallback to `caam ls <tool> --json` because both work locally, while docs/scripts use both names.
5. Determine current active profile from `.profiles[] | select(.active==true).name`, fallback `caam status <tool> --json`.
6. Candidate set: vaulted profiles where `active != true`, `system != true`, and health status is not `critical`/`expired` unless `--allow-unhealthy` is set.
7. Sort candidates by health score: `healthy|ok`, then `warning`, then `unknown`; stable tie-break by profile name.
8. If no candidate: emit `no_alternate_profile`, rc=4.
9. Dry-run: emit `dry_run`, `would_activate`, rc=0, no ledger mutation.
10. Apply: run `caam activate <tool> <next> --json`.
11. Post-check with `caam status <tool> --json` or `caam list <tool> --json`; active profile must equal selected profile.
12. Append recovery ledger row and primitive-specific attempt row.
13. Return rc=0 if rotated or already rotated, rc=4 if no alternate, rc=2 for CAAM/auth/post-check errors.

Base receipt shape:

```json
{
  "schema_version": "caam-auto-rotate-on-usage-limit.result.v1",
  "status": "rotated",
  "tool": "codex",
  "session": "flywheel",
  "pane": 2,
  "digest": "<sha256>",
  "dry_run": false,
  "apply": true,
  "authorized": true,
  "recovery_class": "credential_rotation",
  "current_profile_before": "joshua@zeststream.ai",
  "selected_profile": "chiefzester",
  "rotated": true,
  "caam_rc": 0,
  "post_check": {"verdict": "success", "active_profile": "chiefzester"},
  "failure_class": null,
  "recovery_ledger_written": true
}
```

Security note: do not print auth files, token fragments, raw `~/.codex/auth.json`, CAAM vault contents, or bearer values. Profile names are selector labels; if future profiles include sensitive labels, add `--redact-profile-names` while keeping a digest.

### 3. Extend Authorization Gate

`capacity-halt-pane-authorization.sh` is capacity-named, but currently owns the practical pane-action gate. Extend without renaming:

```diff
+ p.add_argument("--recovery-class", default="pane_input")
+ p.add_argument("--tool", default="")

+ if args.recovery_class == "credential_rotation":
+   if args.tool and args.tool != "codex":
+     emit(... status="malformed", refusal_reason="unsupported_tool", rc=3)
+   emit(... status="authorized", role="unknown", authorized=True,
+        authorization_outcome="authorized",
+        recovery_class="credential_rotation",
+        stale_topology_allowed=True,
+        decision_reason="vault_selector_swap_independent_of_pane_role", rc=0)
```

Rationale: the operation changes the CAAM active profile for the tool, not pane text or process state. It can succeed when topology is stale. This does not authorize token rotation, vault writes, launchctl changes, or pane respawn.

### 4. Recovery Ledger Schema Delta

Do not make `recovery_class` required in v1; existing recovery rows and tests would break. Add it as a typed optional property and have the new primitive emit it.

```diff
  "properties": {
+   "recovery_class": {
+     "type": "string",
+     "enum": ["pane_input", "respawn", "credential_rotation", "operator_notify", "unknown"]
+   },
+   "profile_selector": {
+     "type": "object",
+     "additionalProperties": true,
+     "properties": {
+       "tool": {"type": "string"},
+       "from": {"type": ["string", "null"]},
+       "to": {"type": ["string", "null"]},
+       "redacted": {"type": "boolean"}
+     }
+   },
    "primitive_invoked": {
      "type": "string",
      "minLength": 1
    }
  }
```

New primitive emits canonical row:

```json
{
  "actor": "watchdog",
  "target_session": "flywheel",
  "target_pane": 2,
  "pane_role": "unknown",
  "trauma_class": "codex_usage_limit",
  "signal_text": "usage_limit",
  "decision_reason": "credential_rotation_authorized_even_when_topology_stale",
  "budget_state": {"per_pane_count_window": 0, "fleet_count_window": 0, "authorized": true},
  "transport": {"rc": 0, "duration_ms": 55, "send_command": "caam activate codex <profile> --json"},
  "post_check": {"verdict": "success", "evidence": "caam status codex active_profile matched selected_profile"},
  "failure_class": null,
  "primitive_invoked": "caam-auto-rotate-on-usage-limit",
  "recovery_class": "credential_rotation"
}
```

## Test Plan

Add new test file: `.flywheel/tests/test_caam_auto_rotate_on_usage_limit.sh`.

Extend existing detector tests near `.flywheel/tests/test_codex_template_stuck_detector.sh` / `tests/e2e/e2e_oom_classifier.sh`.

Minimum cases:

| # | Case | Expected |
|---|---|---|
| 1 | Fixture text contains `usage limit`. | Detector subclass `codex_usage_limit`, recovery `caam_auto_rotate`. |
| 2 | Fixture text contains `Limit reached`. | Same subclass/recovery. |
| 3 | Fixture text contains `rate_limit_exceeded`. | Same subclass/recovery. |
| 4 | Fixture text contains `Plan: free tier`. | Same subclass/recovery. |
| 5 | Fixture text contains `try again in 4h`. | Same subclass/recovery. |
| 6 | Fixture text contains `429 Too Many Requests`. | Same subclass/recovery. |
| 7 | Stable non-limit unknown fixture. | Still `unknown_stable`; no false positive. |
| 8 | Vault has current + alternate; dry-run. | `status=dry_run`, `would_activate=<alternate>`, no CAAM command log mutation. |
| 9 | Vault has current + alternate; apply success. | Runs `caam activate codex <alternate> --json`; post-check success; rc=0. |
| 10 | Vault has no alternate. | `status=no_alternate_profile`, `failure_class=no_alternate_profile`, rc=4. |
| 11 | `caam list` fails, `caam ls` succeeds. | Fallback works; candidate selected. |
| 12 | `caam activate` returns nonzero. | `status=caam_error`, `failure_class=caam_activate_failed`, rc=2. |
| 13 | Post-check active profile mismatch. | `status=post_check_failed`, rc=2. |
| 14 | Same `tool:session:pane:digest` seen after success. | `status=already_rotated_for_signal`, rc=0, no second activation. |
| 15 | Topology stale with `recovery_class=credential_rotation`. | Authorization returns rc=0 with `stale_topology_allowed=true`. |
| 16 | Topology stale with default recovery class. | Existing `topology_stale` refusal remains unchanged. |
| 17 | Detector `--auto-recover --apply` with fake primitive. | Recovery payload attached; ledger `recovery_attempted=caam_auto_rotate`. |
| 18 | Recovery schema validates CAAM row. | Optional `recovery_class=credential_rotation` and `profile_selector` accepted. |

Do not run live `caam activate` in tests. Use fake CAAM binary that records argv and returns fixture JSON.

## True Joshua-Blocker Class Check

None fire.

| Class | Verdict |
|---|---|
| Credential-shaped secret rotation | Not fired. CAAM profile selector swap is not Cloudflare/AgentMail/token rotation and uses already vaulted profiles. |
| Substrate corruption | Not fired for implementation. Start-bead `br` BusySnapshot is a separate substrate issue; this lane proceeds read-only and reports no-bead reason. |
| Service-state human operation | Not fired. CAAM profile state is local and script-addressable. |
| Destructive command / DCG | Not fired. No destructive commands proposed. |
| Prod deploy / SLB | Not fired. Plan only; no deploy. |
| Security/PII escalation | Not fired if receipts avoid token/auth file content and only record selector labels or redacted digests. |

## Start Bead / Read-Only Note
Dispatch requested start bead `flywheel-orch-uptime-plan-2026-05-06`. Read-only `br search` failed with SQLite BusySnapshot before any create, so I did not repair or mutate `.beads/`; callback should include `no_bead_reason=br_busy_snapshot_read_only_lane`.

## Proposed File Ownership for Ship Phase

Extend:

- `.flywheel/scripts/codex-template-stuck-detector.sh`
- `.flywheel/scripts/capacity-halt-pane-authorization.sh`
- `.flywheel/validation-schema/v1/recovery-ledger.schema.json`
- `.flywheel/tests/test_codex_template_stuck_detector.sh`
- `tests/e2e/e2e_oom_classifier.sh`

Add:

- `.flywheel/scripts/caam-auto-rotate-on-usage-limit.sh`
- `.flywheel/tests/test_caam_auto_rotate_on_usage_limit.sh`

`new_files_proposed=2`

## Acceptance Probe

Planned ship-phase L112:

```bash
bash .flywheel/tests/test_codex_template_stuck_detector.sh
bash tests/e2e/e2e_oom_classifier.sh
bash .flywheel/tests/test_caam_auto_rotate_on_usage_limit.sh
jq -e '.properties.recovery_class.enum | index("credential_rotation")' .flywheel/validation-schema/v1/recovery-ledger.schema.json
echo OK_orch_uptime_laneA_research_complete
```
Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet
