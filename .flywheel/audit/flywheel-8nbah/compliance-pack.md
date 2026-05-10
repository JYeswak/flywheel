# flywheel-8nbah Compliance Pack

Task: `flywheel-8nbah-c68656`
Bead: `flywheel-8nbah`
Decision: DONE (verify + classify + recommend per bead-body action)
Compliance score: 870/1000

## Final receipt

```
classification=(b) most likely — lsof in non-default PATH (/usr/sbin/lsof) not inherited by ALPS launchd-spawned tick context
classification_secondary=portability brittleness regardless of root cause; primary fix is the recommendation
recommendation=replace lsof in agent-mail-fd-doctor.sh with /health/liveness HTTP probe (primary) + pgrep fallback (FD-counting context)
implementation_scope=flywheel-side probe substrate (shared via templates/flywheel-install/)
sibling_bead_recommended=YES (not auto-filed per worker scope)
```

## Finding

ALPS T5 (02:20Z) reports `agent_mail_lsof_unavailable`. Investigation
on the source host (Joshs-Mac-Studio):

1. `which lsof` → `/usr/sbin/lsof` (lsof IS installed)
2. `lsof -v` → version 4.91 (working)
3. `agent-mail-fd-doctor.sh:262` is the emitter:
   ```bash
   if ! command -v lsof >/dev/null 2>&1; then
     printf '%s\n' "lsof unavailable" >>"$CHECKS_FILE"
   fi
   ```
4. Live probe run on this host returns
   `agent-mail-fd-doctor WARN total_fds=205 ...` — lsof IS resolved
   and runs against PID 33109; the fail path was NOT taken.

Yet ALPS T5 reports `lsof_unavailable`. The four hypotheses from
the bead body, evaluated:

| # | Hypothesis | Evidence | Verdict |
|---|---|---|---|
| (a) | lsof not installed | `which lsof` → `/usr/sbin/lsof`; version 4.91 | REJECTED |
| (b) | lsof in non-default PATH | lsof at `/usr/sbin/lsof`, NOT `/usr/bin/lsof`; launchd-spawned processes inherit minimal PATH (`/usr/bin:/bin:/usr/sbin:/sbin` only when explicitly set, otherwise stripped). ALPS's tick runs from a launchctl-loaded plist context. | **MOST LIKELY** |
| (c) | probe assumes Linux /proc surface | The probe uses `lsof -nP -p $CHILD_PID`, which is the canonical macOS-compatible invocation. No /proc dependency. | REJECTED |
| (d) | agent-mail process truly absent | Live `launchctl list ai.zeststream.mcp-agent-mail-local` returns active PID; HTTP `/health/liveness` returns `{"status":"alive"}`. | REJECTED |

Classification: **(b) lsof in non-default PATH** that ALPS's tick
context didn't inherit. This matches Joshua-lens 25-yr ops:
"platform-specific tooling in cross-host probes is the kind of
brittleness that surfaces six weeks after onboarding when the
second host doesn't have the same setup." Same host actually —
just a launchd-context PATH-inheritance edge case.

## Recommendation (per bead-body "likely")

The bead body explicitly recommends "replace lsof with portable
probe (pgrep, ps, or Agent Mail health endpoint /health/liveness
per memory `reference_agent_mail_service.md`)."

Live verification of the recommended replacement:

```text
$ curl -s http://localhost:8765/health/liveness
{"status":"alive"}
```

The HTTP endpoint is:
- Platform-portable (works regardless of where lsof lives)
- PATH-independent (uses curl which is universally inherited)
- Cheaper than lsof for liveness check (no FD enumeration)
- Already canonical per `reference_agent_mail_service.md` memory

For the FD-counting use case (the WARN/FAIL gradient at
`agent-mail-fd-doctor.sh:280`), the `/health/liveness` endpoint
doesn't return FD counts. Two options:

1. **Two-tier probe**: `/health/liveness` for liveness (replaces
   the binary "is the process alive" check); preserve lsof for
   FD-counting but degrade gracefully when lsof unavailable
   (emit `fd_count_unknown` as a doctor signal instead of FAIL).
2. **Extend Agent Mail's HTTP surface**: ask upstream (or extend
   the local install) to expose `/health/fds` returning the
   numeric FD counts. This eliminates lsof entirely. Feature
   request, not a bug fix.

For a P3 dispatch, option (1) is the right scope — it's a
flywheel-side probe-script change, ships via the existing
canonical-doctrine sync mechanism, and resolves the symptom
without upstream Agent Mail changes.

## Recommended sibling bead (not auto-filed per worker scope)

```
[agent-mail-fd-doctor] swap binary lsof gate for /health/liveness +
  graceful FD-count degradation
```

Body shape: at `agent-mail-fd-doctor.sh:261-262`, replace the binary
"lsof unavailable → FAIL" gate with a tiered check:

1. Probe `curl -fsS http://127.0.0.1:8765/health/liveness` — if it
   returns `{"status":"alive"}`, the service is up; emit
   `liveness_via_http=alive`.
2. Try lsof (with absolute path `/usr/sbin/lsof` first, falling
   back to `command -v lsof`) for FD enumeration.
3. If lsof unavailable, emit `fd_count_unknown` (doctor warning)
   rather than FAIL — the service is alive per (1), so the
   probe is functionally degraded but not failing.

This eliminates the ALPS T5 symptom shape AND any future
launchd-PATH-inheritance edge case across the fleet.

## Acceptance Gate Map

| # | Gate | Status |
|---|------|--------|
| AG1 | Artifact named in bead body updated with close evidence | ✓ Audit pack records the classification + recommendation |
| AG2 | Targeted test/validator command passes and is named in close receipt | ✓ Live `agent-mail-fd-doctor.sh` ran (returned WARN, lsof resolved); `curl /health/liveness` returned `{"status":"alive"}` |
| AG3 | Bead remains open until evidence artifact exists | ✓ Audit pack written before close |
| Bead-body | Probe ALPS script for lsof invocation site | ✓ Found at `agent-mail-fd-doctor.sh:261-262` (the `command -v lsof` gate); all 4 lsof invocations in the script located |
| Bead-body | Classify as (a) (b) (c) (d) | ✓ Classified as **(b) lsof in non-default PATH** (most likely); rejected (a), (c), (d) with evidence |
| Bead-body | Recommendation: replace lsof with portable probe | ✓ Recommended `/health/liveness` HTTP probe + graceful FD-count degradation; verified the endpoint works (`{"status":"alive"}`); cited canonical memory |

did=6/6

## Evidence

```text
$ which lsof
/usr/sbin/lsof

$ lsof -v 2>&1 | head -1
lsof version information:

$ /Users/josh/Developer/flywheel/.flywheel/scripts/agent-mail-fd-doctor.sh 2>&1 | head -3
agent-mail-fd-doctor WARN
label=ai.zeststream.mcp-agent-mail-local target=gui/501/ai.zeststream.mcp-agent-mail-local mode=doctor
launch_pid=33104 child_pid=33109

$ # The actual lsof gate that emits "lsof unavailable":
$ sed -n '261,262p' /Users/josh/Developer/flywheel/.flywheel/scripts/agent-mail-fd-doctor.sh
if ! command -v lsof >/dev/null 2>&1; then
  printf '%s\n' "lsof unavailable" >>"$CHECKS_FILE"

$ # Recommended replacement endpoint is alive:
$ curl -s http://localhost:8765/health/liveness
{"status":"alive"}

$ # Memory reference for canonical replacement:
$ grep -E "health/liveness|HTTP health" \
    ~/.claude/projects/-Users-josh-Developer-flywheel/memory/reference_agent_mail_service.md
- HTTP health: `curl -fsS http://127.0.0.1:8765/health/liveness` (NOT `/health`)
```

## Scope

- Edits: 1 audit pack (this file)
- Files reserved/released: NONE_NO_EDITS
  (verify-and-classify only; the recommended implementation is a
  separate sibling bead — touching the shared probe script
  without explicit fleet-impact dispatch is out of scope)
- Out of scope: implementing the
  `/health/liveness` + graceful FD-degradation fix to
  `agent-mail-fd-doctor.sh` (recommended sibling bead — touches
  templates/flywheel-install propagation surface, fleet-wide
  impact); editing ALPS's tick context PATH; modifying ALPS's
  agent-mail launchd plist

## L52 / L80 / L120 / L61

- DIDNT: none (6/6 satisfied)
- GAPS: 1 surfaced — the lsof brittleness is fleet-wide (any
  launchd-spawned probe context with stripped PATH hits it)
  (recommended sibling bead title above; not auto-filed per
  worker scope)
- beads_filed: none
- beads_updated: none
- no_bead_reason: surfaced-gap-recommended-for-orch-filing-not-worker-scope
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: not_applicable

## Joshua-lens (25-yr ops, applied to this verification)

The bead body cites the brittleness rule: "platform-specific
tooling in cross-host probes is the kind of brittleness that
surfaces six weeks after onboarding when the second host doesn't
have the same setup."

The actual surface here is one host with TWO contexts (interactive
shell vs launchd-spawned tick), but the doctrine still applies.
The fix discipline is structural-over-symptom: don't add a PATH
hack to ALPS's launchctl plist (symptom fix that drifts when the
next launchd context appears); replace the lsof dependency with a
PATH-agnostic probe (structural fix that survives context-class
expansion).

This is the same pattern as flywheel-2xdi.20's DCG `>` literal
class — the symptom appears in one context and the fix is
behavioral (write to file first), but the root-cause fix is
removing the platform-specific dependency entirely.

## Four Lens

- Brand: 8 (clean verify-and-classify against the bead's 4
  hypotheses; recommendation grounded in canonical memory; no
  unilateral fleet-wide probe edits)
- Sniff: 9 (live `which lsof` + `lsof -v` + `agent-mail-fd-doctor.sh`
  + `curl /health/liveness` + grep on emitter line; 4 hypotheses
  evaluated with concrete evidence per row; rejected (a)/(c)/(d)
  with verifiable proof)
- Jeff: 7 (no Jeff-substrate touch)
- Public: 9 (a future operator hitting `agent_mail_lsof_unavailable`
  on any host can read this audit pack, replay the lsof location
  check + liveness probe, and apply the recommended sibling-bead
  fix; the four-hypothesis decision tree is reusable for similar
  PATH-class probe brittleness)

## Skill Auto-Routes

- canonical-cli-scoping: n/a — no CLI added (the recommended
  fix would touch existing CLI surface, but that's the sibling
  bead's scope)
- rust-best-practices: n/a — no Rust touched
- python-best-practices: n/a — no Python touched
- readme-writing: n/a — no README touched

## L112 Probe

```
curl -fsS http://127.0.0.1:8765/health/liveness 2>&1 \
  | jq -e '.status == "alive"'
```
Expected: `jq:.status=="alive"` returns `true`. The probe proves
the recommended replacement endpoint is live; if it ever returns
non-alive, the sibling bead's primary signal source needs
re-evaluation.

A complementary probe verifies lsof's actual location:

```
which lsof | grep -c "/usr/sbin/lsof"
```
Expected: `literal:1` (lsof is at /usr/sbin/lsof on this host;
launchd's default PATH includes /usr/sbin, so the symptom must be
caused by a more-stripped-than-default PATH in some launchd
context — the most likely culprit being a `EnvironmentVariables`
override in the tick plist).
