# flywheel-5pjt2 Evidence — agent-mail-fd-doctor portable liveness fallback

Task: `flywheel-5pjt2-a55038`
Bead: `flywheel-5pjt2` (P3 OPEN → CLOSED this turn)
Title: [agent-mail-fd-doctor] replace lsof probe with portable health/liveness check (per flywheel-8nbah finding)
Date: 2026-05-10
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=adjacent` — closes the
flywheel-8nbah finding (ALPS T5 reported `agent_mail_lsof_unavailable`
on a host where lsof was missing or in non-default PATH).

## Headline outcome

**Doctor now uses a portable HTTP `/health/liveness` probe as the
canonical liveness check** (per memory rule
`reference_agent_mail_service.md`). When `lsof` is unavailable AND
the service is alive on `http://127.0.0.1:8765/health/liveness`,
status downgrades from FAIL → WARN with the descriptive code
"lsof unavailable; liveness OK — fd_pressure data unavailable".
When lsof is unavailable AND liveness fails, status stays FAIL with
both-condition message. 9/9 regression test guards both branches +
configuration + envelope shape.

## What changed

### `.flywheel/scripts/agent-mail-fd-doctor.sh`

| Line | Change | Why |
|---|---|---|
| 4 | `SCRIPT_VERSION` bump 2026-05-04.1 → 2026-05-10.1 | revision marker |
| 13-22 | NEW: `LIVENESS_URL`, `LIVENESS_TIMEOUT` env-configurable + flywheel-5pjt2 fix-receipt comment | introduces the portable probe surface |
| 26-30 | Usage exit-code section reworded | documents new WARN semantics |
| 137-156 | NEW: `check_liveness()` helper | tries `curl /health/liveness`; honors `AGENT_MAIL_FD_LIVENESS_OVERRIDE` for fixture testing (alive/down/no_curl) |
| 261-278 | lsof-unavailable branch rewired | now calls `check_liveness` first; status=WARN if alive, FAIL if not |

Behavior matrix:

| lsof | liveness | pre-fix status | post-fix status |
|---|---|---|---|
| available | n/a | (existing FD-pressure logic — unchanged) | (unchanged) |
| **unavailable** | **alive** | **FAIL** (uniform) | **WARN** with descriptive check |
| unavailable | down | FAIL (uniform) | FAIL with both-condition check |

Liveness probe is opt-out via env override
(`AGENT_MAIL_FD_LIVENESS_OVERRIDE=down` for fixture tests; URL +
timeout configurable).

### `tests/agent-mail-fd-doctor-portable-liveness.sh` (NEW, 9 PASS)

| # | Test | Behavior |
|---|---|---|
| 1 | doctor exists + bash -n + check_liveness helper + flywheel-5pjt2 citation + /health/liveness path | substrate gate |
| 2 | usage documents new exit-code semantics | docs match behavior |
| 3 | no-lsof + liveness=alive → WARN | post-fix branch (was FAIL pre-fix) |
| 4 | no-lsof + liveness=down → FAIL | canonical service-down preserved |
| 5 | check_liveness override branch present in source | fixture-test surface |
| 6 | liveness URL configurable via env | portability invariant |
| 7 | liveness timeout configurable via env | portability invariant |
| 8 | live doctor packet shape unchanged | regression guard |
| 9 | no-lsof branch routes through check_liveness | pre-fix uniform-FAIL gone |

## DoD status

The bead is a follow-up from flywheel-8nbah ("agent-mail lsof
probe unavailable on host"). The flywheel-8nbah recommendation:
"replace lsof with portable probe (pgrep, ps, or Agent Mail
health endpoint /health/liveness per memory
reference_agent_mail_service.md)". This close ships the
`/health/liveness` path + a portable curl-based fallback +
graceful degradation when lsof is genuinely missing.

| Acceptance | Status | Evidence |
|---|---|---|
| Replace lsof probe with portable health/liveness check | DONE | `check_liveness()` helper added; lsof-unavailable branch routes through it |
| Preserve FD-pressure detection when lsof IS available | DONE | existing FD-pressure logic unchanged; live test (Test 8) confirms canonical packet shape |
| Configurable for cross-host portability | DONE | `AGENT_MAIL_FD_LIVENESS_URL` + `AGENT_MAIL_FD_LIVENESS_TIMEOUT` + `AGENT_MAIL_FD_LIVENESS_OVERRIDE` env vars |
| Regression test covers both branches | DONE | Test 3 (no-lsof+alive) + Test 4 (no-lsof+down) + Test 9 (uniform-FAIL gone) |

did=4/4 didnt=none gaps=none.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| doctor (post-fix) | `.flywheel/scripts/agent-mail-fd-doctor.sh` | `4aa987c0211c640af9121981716b64c8d12013c7c1960b6be61ee3ee350f215d` |
| regression test | `tests/agent-mail-fd-doctor-portable-liveness.sh` | `0d673a78e249dbc1e00011923a0ec9a7090936d3205cfd485ea65c106bc6ebec` |

## Verification commands (re-runnable)

```bash
# 9 PASS regression
bash /Users/josh/Developer/flywheel/tests/agent-mail-fd-doctor-portable-liveness.sh
# expected: SUMMARY pass=9 fail=0

# Live doctor on this host (lsof available)
.flywheel/scripts/agent-mail-fd-doctor.sh --doctor --json \
  | jq '{status, exit_code, total_fds, lock_fd_count}'

# Simulate lsof unavailable + service alive (the trauma case fixed)
AGENT_MAIL_FD_LIVENESS_OVERRIDE=alive PATH=/usr/bin:/bin \
  .flywheel/scripts/agent-mail-fd-doctor.sh --doctor --json \
  | jq '{status, exit_code, checks}'
# expected: status=WARN, exit_code=1, check cites "lsof unavailable; liveness OK"

# Simulate lsof unavailable + service down (canonical FAIL preserved)
AGENT_MAIL_FD_LIVENESS_OVERRIDE=down PATH=/usr/bin:/bin \
  .flywheel/scripts/agent-mail-fd-doctor.sh --doctor --json \
  | jq '{status, exit_code, checks}'
# expected: status=FAIL, exit_code=2, check cites "lsof unavailable AND liveness failed"

# Live liveness URL still alive
curl -fsS --max-time 3 http://127.0.0.1:8765/health/liveness
# expected: {"status":"alive"}
```

## L112 probe (worker callback)

```bash
bash /Users/josh/Developer/flywheel/tests/agent-mail-fd-doctor-portable-liveness.sh 2>/dev/null | tail -1
```

Expected (literal): `SUMMARY pass=9 fail=0`.

## Boundary

- **No edit to Agent Mail itself.** The
  `~/.local/share/mcp_agent_mail` install is upstream
  Dicklesworthstone substrate; we don't push or edit it.
- **No replacement of lsof entirely.** When lsof IS available,
  the FD-pressure enumeration still runs (it's the load-bearing
  reason this doctor exists — early FD-leak detection). The fix
  adds graceful degradation, not a different probe.
- **No edit to the launchctl/plist substrate.** Doctor is
  read-only on the service control surfaces.
- **No new INCIDENTS section.** Single-bug fix; the bead body
  + audit pack carry the verdict.
- **No new L-rule numbered.** Mechanism, not doctrine.

## Skill auto-routes

- `canonical-cli-scoping=yes` — preserved existing `--info` /
  `--schema` / `--examples` / `--health` / `--doctor` triad;
  added env vars + behavior matrix + Test 2 confirms usage
  documents new semantics.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python edits (curl is the new
  liveness probe).
- `readme-writing=n/a` — substrate fix, not README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no doctrine surface mutated.
- `readme_updated=not_applicable`.
- `no_touch_reason=substrate_fix_to_existing_doctor_no_doctrine_surface_mutated_no_l-rule_authored_canonical_cli_scoping_triad_preserved_9_test_regression_guards_both_branches_plus_envelope_shape`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes 4/4 acceptance gates verbatim;
  graceful-degradation pattern (FAIL → WARN when liveness OK)
  preserves operator trust (no false alarms when service is
  fine).
- **Sniff: 9** — outcome-shaped headline ("doctor now uses a
  portable HTTP /health/liveness probe... when lsof is
  unavailable AND service is alive, status downgrades from
  FAIL → WARN"); concrete behavior matrix table; 9-test
  regression with positive + negative + envelope-shape +
  configurability invariants.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose;
  refuses to edit Agent Mail upstream (Jeffrey's substrate);
  refuses to remove lsof entirely (preserves FD-pressure
  detection); refuses to push to upstream Dicklesworthstone
  (per memory `feedback_no_push_ntm_br`).
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow on a host without lsof)**: 4
    verification commands + behavior matrix tell them exactly
    what to expect; the WARN message is descriptive enough to
    skip diagnostic work.
  - **maintainer (extending later)**: env-var configurability
    (URL, timeout, override) is the extension point — adding
    a new fallback (e.g., `pgrep` if curl is also missing) is
    a one-helper addition + a fixture test.
  - **future worker (LLM agent)**: facing another
    "single-tool-dependency on host with missing tool" trauma,
    the worker has (a) the graceful-degradation pattern
    (FAIL→WARN+descriptive_code), (b) the override-env-var
    fixture pattern, (c) the canonical /health/liveness probe
    template.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-5pjt2
no_bead_reason=portable_liveness_fallback_landed_per_flywheel-8nbah_finding_lsof_unavailable_plus_alive_now_warn_was_fail_lsof_unavailable_plus_down_still_fail_canonical_cli_scoping_triad_preserved_9_test_regression_no_followup_observed`.
