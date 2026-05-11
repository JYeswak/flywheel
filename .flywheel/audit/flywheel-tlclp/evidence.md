# flywheel-tlclp — blocker-discipline-tick-chain launchd wire-in

Bead: flywheel-tlclp (P2)
Lane: infrastructure
mutates_state: yes (creates LaunchAgent under gui/$UID; runs hourly going forward)
Parent: flywheel-yy9qi (P1 CLOSED — shipped the chain script)
Sister: flywheel-tlclp.1 (P3 OPEN — fleet propagation deferred)

## What shipped

1. **Plist** `.flywheel/launchd/ai.zeststream.flywheel-blocker-discipline-tick-chain.plist` — canonical source plist, `StartInterval=3600` (hourly), runs `blocker-discipline-tick-chain.sh tick --apply --json`, with `BLOCKER_DISCIPLINE_SKIP_AGENT_MAIL=1` to suppress non-interactive Agent Mail noise.
2. **README** `.flywheel/launchd/ai.zeststream.flywheel-blocker-discipline-tick-chain.plist.README.md` — operator guidance, cadence rationale, install/uninstall pattern, fleet replication template.
3. **Installer** `.flywheel/scripts/blocker-discipline-tick-chain-launchd-install.sh` — canonical-cli surface with `doctor`, `health`, `validate`, `apply`, `unload`, `audit` subcommands, idempotency-key gate on `apply`, watcher-registration integration via `flywheel-watchers register`.
4. **Sister bead** `flywheel-tlclp.1` (P3) — filed for fleet propagation when chain scripts ship to alps/mobile-eats/skillos/vrtx.

## Live state (post-apply)

```json
{
  "schema_version": "blocker-discipline-tick-chain-launchd-install/v1",
  "mode": "health",
  "status": "loaded",
  "detail": "gui/501/ai.zeststream.flywheel-blocker-discipline-tick-chain is registered",
  "label": "ai.zeststream.flywheel-blocker-discipline-tick-chain",
  "domain": "gui/501",
  "target": "/Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-blocker-discipline-tick-chain.plist"
}
```

`launchctl print` reports `state = not running` (waiting for first scheduled firing), `run interval = 3600 seconds`. LaunchAgent is registered with `flywheel-watchers` (`label=ai.zeststream.flywheel-blocker-discipline-tick-chain`, `owner=flywheel-orch`, `bead=flywheel-tlclp`, `idempotency-key=tlclp-launchd-ai.zeststream.flywheel-blocker-discipline-tick-chain`).

## Acceptance gates

The bead body has no explicit AC list (Title-only). Inferred AGs from title ("launchd/cron wire-in for blocker-discipline-tick-chain.sh fleet-wide cadence per yy9qi worker action"):

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Plist exists and is plutil-valid | **DONE** | `plutil -lint` PASS on source plist; written at `.flywheel/launchd/ai.zeststream.flywheel-blocker-discipline-tick-chain.plist` |
| AG2 | Cadence is documented and reasonable | **DONE** | `StartInterval=3600` (hourly) — rationale documented in README cadence section: matches `THRESHOLD_N=4` chain semantics → escalation kicks in after 4hr of consecutive AC failure. Suppresses Agent Mail (`BLOCKER_DISCIPLINE_SKIP_AGENT_MAIL=1`) under non-interactive launchd. |
| AG3 | Wire-in is installable + uninstallable + idempotent | **DONE** | Installer canonical-cli surface (doctor/health/validate/apply/unload/audit) with idempotency-key gate. Two consecutive `apply --apply --idempotency-key …` runs: first = `register: registered, bootstrap: bootstrapped`; second = `register: noop_already_registered, bootstrap: noop_already_loaded`. Both = `status=ok`. |
| AG4 | Wire-in is actually loaded under launchctl | **DONE** | `launchctl print gui/501/ai.zeststream.flywheel-blocker-discipline-tick-chain` returns `state = not running, run interval = 3600 seconds`. Service registered, awaiting first scheduled tick. |
| AG5 | Fleet-wide propagation addressed (wire-or-explain) | **DONE — EXPLAIN side** | Chain script absent from alps/mobile-eats/skillos/vrtx (also `.flywheel/state/blockers/` ABSENT in all four). Cannot wire what isn't there. Sister bead `flywheel-tlclp.1` filed (P3) for fleet propagation when chain ships to fleet members. Per memory rule `feedback_naming_rename_is_cross_repo_wire_or_explain`. |

## Test execution receipts

### Doctor

```
status: "ok"
checks: source_plist_present=ok, source_plist_parses=ok, launch_agents_dir=ok, chain_script_executable=ok
```

### Apply (first run)

```
status: "ok", symlink: "created", register: "registered", bootstrap: "bootstrapped"
```

### Apply (idempotency re-run)

```
status: "ok", symlink: "noop_already_correct", register: "noop_already_registered", bootstrap: "noop_already_loaded"
```

### Idempotency-key refusal

```
$ blocker-discipline-tick-chain-launchd-install.sh apply --apply --json
{"status":"refused","reason":"missing_idempotency_key","hint":"pass --idempotency-key <stable-key>"}
rc=3
```

### Audit log

4 rows appended (one per `apply` invocation): refused → fail → ok → ok. Audit log: `~/.local/state/flywheel/blocker-discipline-tick-chain-install-runs.jsonl`.

## Skill auto-routes addressed

- **canonical-cli-scoping** = YES — installer ships canonical-cli surface (`doctor`/`health`/`repair-class via unload`/`validate`/`audit`/`why`-class-via-help triad), `--info`/`--schema`/`--examples`/`--help` introspection, `--dry-run`/`--apply` mutation discipline with `--idempotency-key` gate. AG3 verified.
- **rust-best-practices** = n/a — bash installer, no Rust.
- **python-best-practices** = n/a — bash installer; only `plutil` and `launchctl` external deps.
- **readme-writing** = YES — plist README ships with Quick Start (`apply` 1-line install), env vars, log paths, Probe section, fleet replication template, source-beads provenance.

## L52 bead receipt

- `beads_filed`: `flywheel-tlclp.1` (P3 sister for fleet propagation)
- `beads_updated`: none
- `no_bead_reason`: n/a (gap surfaced + filed)

## Wire-or-explain on fleet propagation

| Repo | Chain script present? | `.flywheel/state/blockers/`? | Decision |
|---|---|---|---|
| flywheel | YES | YES (live) | **WIRED** by this bead |
| alps | NO | NO | DEFER — sister bead `flywheel-tlclp.1` |
| mobile-eats | NO | NO | DEFER — sister bead `flywheel-tlclp.1` |
| skillos | NO | NO | DEFER — sister bead `flywheel-tlclp.1` |
| vrtx | NO | NO | DEFER — sister bead `flywheel-tlclp.1` |

This is the EXPLAIN side of wire-or-explain. The chain primitive isn't in fleet repos yet; wiring a launchd plist there would point at a missing script — DRY-VIOLATION. Fleet propagation is captured as P3 sister bead; pick up when chains ship to fleet.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/launchd/ai.zeststream.flywheel-blocker-discipline-tick-chain.plist` | NEW (28 lines) |
| `.flywheel/launchd/ai.zeststream.flywheel-blocker-discipline-tick-chain.plist.README.md` | NEW |
| `.flywheel/scripts/blocker-discipline-tick-chain-launchd-install.sh` | NEW (255 lines, canonical-cli surface) |
| `.flywheel/audit/flywheel-tlclp/evidence.md` | NEW |
| External: `~/Library/LaunchAgents/ai.zeststream.flywheel-blocker-discipline-tick-chain.plist` | NEW symlink → source plist |
| External: `flywheel-watchers registry` | label `ai.zeststream.flywheel-blocker-discipline-tick-chain` registered, owner=flywheel-orch, bead=flywheel-tlclp |

## Four-Lens Self-Grade

- **brand** (9): plist + installer follow exact existing fleet patterns (zeststream.*-codex-stuck-detector lineage); audit log path matches fleet conventions (`~/.local/state/flywheel/`); cite `yy9qi` (chain) and `tlclp` (wire-in) in plist comments.
- **sniff** (9): zero speculation. Real launchctl print proves loaded state. Idempotency verified by double-apply. Sister-bead pattern matches existing fleet discipline (wire-or-explain).
- **jeff** (9): launchctl bootstrap guard (`flywheel-watchers register`) honored — installer routes through canonical registration, not the documented `LAUNCHCTL_GUARD_BYPASS=1` shortcut. Per `feedback_substrate_loss_worker_commit_orphan` and `feedback_orchestrators_kill_panes_without_respawn`, working WITH fleet guards not around them.
- **public** (9): Three Judges check —
  - Skeptical operator: can run `bash .flywheel/scripts/blocker-discipline-tick-chain-launchd-install.sh doctor --json` and confirm everything before applying; idempotency-key gate prevents accidents.
  - Maintainer: cadence rationale + Agent Mail suppression + fleet propagation deferral all documented in README; sister bead captures the deferred work.
  - Future worker: README's "Fleet propagation" section gives a copy-paste template for replicating to alps/mobile-eats/skillos/vrtx when chains ship.

four_lens=brand:9,sniff:9,jeff:9,public:9

## Compliance: 950/1000

- AG1-AG5: all DONE. ✓
- Idempotency verified (double-apply, audit log). ✓
- Canonical-cli surface (doctor/health/validate/apply/unload/audit + --info/--schema/--examples). ✓
- Plist plutil-valid + launchctl-loaded. ✓
- flywheel-watchers registration honored (not bypassed). ✓
- Sister bead filed (L52 gap-receipt). ✓
- README ships with install/uninstall/probe/cadence/fleet-replication sections. ✓

Score 950 not 1000 because:
- No automated regression test for the installer (would be the +50). Manual smoke verification only.

If a +50 test is desired, a quick `tests/blocker-discipline-tick-chain-launchd-install.sh` could exercise: doctor (asserts status=ok), apply --dry-run (asserts status=dry_run + hint message), apply --apply without key (asserts rc=3 status=refused), idempotency (two applies with same key produce status=ok), unload --dry-run (asserts status=dry_run). Out-of-scope for the bead title but a natural follow-up.

## L112 probe

Command: `launchctl print gui/$(id -u)/ai.zeststream.flywheel-blocker-discipline-tick-chain 2>&1 | grep -c 'run interval = 3600'`
Expected: `literal:1`
Timeout: 5 seconds
