---
title: "Fleet-Coherence Schema v2"
type: plan
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# Fleet-Coherence Schema v2

**Created:** 2026-05-01  
**Bead:** flywheel-2te (Phase 0 schema fixtures)  
**Status:** frozen — all Phase 1 beads depend on this contract

---

## 1. Drift-Class Contract and Dedupe Grammar

Every fleet-coherence event belongs to exactly one drift class.
Dedupe key format: `class:session[:pane][:expected][:actual][:bucket]`

| Class | Canonical dedupe key shape | Severity |
|---|---|---|
| `topology_stale_or_kind_mismatch` | `topology_stale_or_kind_mismatch:SESSION:PANE:EXPECTED_KIND:ACTUAL_KIND` | error |
| `topology_missing_unmanaged_session` | `topology_missing_unmanaged_session:SESSION:bucket` | warning |
| `pane_count_drift` | `pane_count_drift:SESSION:EXPECTED_COUNT:ACTUAL_COUNT` | warning |
| `pane_activity_misclassified` | `pane_activity_misclassified:SESSION:PANE:EXPECTED:ACTUAL` | error |
| `worker_role_command_mismatch` | `worker_role_command_mismatch:SESSION:PANE:EXPECTED_ROLE:ACTUAL_CMD_PREFIX` | error |
| `orchestrator_no_cadence` | `orchestrator_no_cadence:SESSION:PANE` | error |
| `dual_orchestrator_tick_loop` | `dual_orchestrator_tick_loop:SESSION:PANE:SOURCE` | critical |
| `sustained_operator_pause_exceeded` | `sustained_operator_pause_exceeded:SESSION:PANE:PAUSE_CLASS` | error |
| `loop_running_without_topology` | `loop_running_without_topology:SESSION:LOOP_NAME` | error |
| `schedule_source_drift` | `schedule_source_drift:SESSION:SOURCE_CLASS:bucket` | warning |
| `codex_auth_expired_silent` | `codex_auth_expired_silent:SESSION:PANE` | critical |
| `fleet_mail_identity_invalid_or_missing` | `fleet_mail_identity_invalid_or_missing:SESSION:IDENTITY_KEY:REASON` | error |
| `detector_runtime_drift` | `detector_runtime_drift:COMPONENT:DRIFT_CLASS` | warning |
| `skill_version_drift` | `skill_version_drift:SKILL_NAME:INSTALLED:EXPECTED` | warning |
| `alert_channel_degraded` | `alert_channel_degraded:CHANNEL:REASON` | error |

Close-row dedupe key appends `:closed` suffix, e.g. `topology_stale_or_kind_mismatch:flywheel:1:orchestrator:worker:closed`.

---

## 2. Event Schema v2

Required fields for every `record_type == "event"` row:

```
event_id          string   — unique per event, format: fc_<class>_<seq>
schema_version    integer  — const: 2
record_type       string   — const: "event"
class             string   — one of 15 drift classes above
detector          string   — const: "fleet-coherence"
detector_version  string   — semver, e.g. "0.1.0"
detector_git_sha  string   — git sha or "fixture"
confidence        float    — 0.0–1.0
severity          string   — "warning" | "error" | "critical"
state             string   — "open" | "closed" | "suppressed"
session           string   — NTM session name
pane              integer|null — pane number or null for session-level events
ts                string   — ISO8601Z detection timestamp
source_ts         string   — ISO8601Z source observation timestamp
source_age_s      integer  — seconds between source_ts and ts
first_seen_ts     string   — ISO8601Z
last_seen_ts      string   — ISO8601Z
seen_count        integer  — dedup accumulation count
sample_count      integer  — samples in window
sample_window_s   integer  — observation window in seconds
resend_after_ts   string   — ISO8601Z resend cadence
suppression_id    string|null
dedupe_key        string   — class:session[:pane][:qualifiers]
raw_source_refs   array    — [{path, line}] references to source files
evidence          object   — detector-specific observation fields

l61               object   — alert channel state
  ntm_attempted         boolean
  ntm_pane              integer|null
  ntm_session           string|null
  ntm_result            string|null
  ntm_sent_at           string|null
  agent_mail_attempted  boolean
  agent_mail_from       string|null
  agent_mail_to         string|null
  agent_mail_message_id string|null
  agent_mail_sent_at    string|null
  l61_pairing_status    string   — "ok" | "degraded" | "not_attempted"
  degraded_reason       string|null
  fleet_mail_identity_source string|null
  project_key           string|null
  vault_token_validated boolean

l62               object   — repair tracking
  repair_callback_required  boolean
  sd_count                  integer|null
  sd_ids                    array

l63               object   — recovery drill tracking
  recovery_action_requires_drill  boolean
  recovery_drill_ids              array

actions           object   — what the detector recommends
  would_l61             boolean
  would_bead            boolean
  would_no_bead_reason  string|null
  bead_id               string|null
  no_bead_reason        string|null
  receipt_required      boolean
  shadow_mode           boolean
```

---

## 3. Suppression Schema v2

Required fields for every `record_type == "suppression"` row:

```
id                    string   — unique suppression id, format: sup_<ts>_<slug>
record_type           string   — const: "suppression"
class                 string   — drift class being suppressed
session               string
pane                  integer|null
allowed_classes       array    — [class] (at minimum the suppressed class)
dedupe_key_pattern    string   — glob pattern matched against event dedupe_key
created_at            string   — ISO8601Z
created_by            string   — authoring agent or "josh"
expires_at            string   — ISO8601Z — TTL enforcement
review_due            string   — ISO8601Z — review reminder
max_ttl               string   — human-readable max TTL (e.g. "2h", "24h")
reason                string   — plain-english rationale
bead_id               string|null — tracking bead if severity warrants one
no_bead_reason        string|null — explicit reason if bead_id is null for a high-severity event
source_event_id       string|null — event_id that triggered this suppression
```

High-severity suppressions (`severity == "critical"` or `severity == "error"`) MUST have either `bead_id` or an explicit `no_bead_reason`.

---

## 4. Fixture Corpus Requirements (Phase 0)

- At least 5 example event rows per drift class (75 rows total, 15 classes).
- At least 1 suppression example per 3 classes (5 suppressions minimum).
- Each fixture row must be valid JSONL (one JSON object per line, no trailing comma).
- Dedupe grammar table above covers all 15 classes with close-row variant.

### Fixture files

| File | Type | Rows |
|---|---|---|
| `.flywheel/fixtures/fleet-coherence-events-v2.jsonl` | events | 75 |
| `.flywheel/fixtures/fleet-coherence-suppressions-v2.jsonl` | suppressions | 5 |
| `.flywheel/fixtures/fleet-coherence-fixtures.jsonl` | combined (legacy) | 80 |

---

## 5. Canonical Fixture Classes (from synthesis v2 §59-79)

The seven fixture scenarios named in the plan:

1. **ALPS topology mismatch** — class: `topology_stale_or_kind_mismatch`, session: `alpsinsurance`
2. **Codex auth text** — class: `codex_auth_expired_silent`, evidence contains auth-screen text pattern
3. **Sustained pause receipt** — class: `sustained_operator_pause_exceeded`, source: tick receipt
4. **Missing topology** — class: `topology_missing_unmanaged_session`, no topology file present
5. **Invalid token** — class: `fleet_mail_identity_invalid_or_missing`, vault_token_validated: false
6. **CronCreate schedule drift** — class: `schedule_source_drift`, source_class: `CronCreate`
7. **Codex false-idle** — class: `pane_activity_misclassified`, expected: active, actual: idle
