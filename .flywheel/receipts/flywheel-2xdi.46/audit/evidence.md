# flywheel-2xdi.46 — false-positive close (resolved by upstream gap-hunt-probe fixes)

## Bead context

- ID: `flywheel-2xdi.46` (P3)
- Title: `[gap-wired-but-cold] .claude/skills/.flywheel/data/skill-packs/customer-growth-ops-pack/validate.sh`
- Auto-filed by gap-hunt-probe (parent: flywheel-2xdi autoloop executor)
- Filed before today's two upstream fixes landed.

## DoD gates (4)

| Gate | Status | Evidence |
|---|---|---|
| 1. Verify the bead represents a stale false-positive (script exists + is on-demand) | DONE | Script `customer-growth-ops-pack/validate.sh` exists (2496 bytes, sha256 captured); it's a skill-pack validator, the canonical on-demand class |
| 2. Confirm current probe state does NOT flag this script | DONE | `gap-hunt-probe.sh --dry-run --json | jq -r '.gap_ids[] | select(test("customer-growth-ops-pack"))'` returns empty (probe-output captured) |
| 3. Confirm script IS in current on-demand allowlist | DONE | Python replication of `on_demand_script_allowlist()` returns `target_in_allowlist=True`; the script is caught by the `pack-glob` fallback (`skill-packs/*/validate.sh`) |
| 4. Document upstream fix that resolved the false-positive class | DONE | Two upstream fixes that retroactively eliminate this entire false-positive class: `flywheel-2fw7v` (substrate-registry + skill-packs glob fallback in `on_demand_script_allowlist()`) and `flywheel-8vw0o` (cross-repo umbrella + runtime-sourced library detection — commit 2a3c130) |

`did=4/4`

## Disposition

**False-positive resolved by upstream fix.** The bead was auto-filed by `gap-hunt-probe.sh` BEFORE the on-demand allowlist + skill-packs glob fallback landed (parent flywheel-2fw7v) and BEFORE the cross-repo + runtime-sourced detection landed (parent flywheel-8vw0o). With both fixes in place, the same script is now correctly recognized as on-demand-allowlisted and would not be flagged again.

This is the classic gap-hunt-probe precision-improvement story: fix the detector, then sweep historical false-positive filings as no-op closes citing the upstream fix.

## Live verification (captured at `disposition-evidence.txt`)

```
=== Current gap-hunt-probe wired-but-cold probe (jq filter for customer-growth-ops-pack) ===
(empty = NOT flagged ✓)

=== On-demand allowlist coverage check ===
target_in_allowlist: True
allowlist_size: 50
```

## Out-of-scope (intentional)

- **No script edits** — the validate.sh is functional and on-demand by design.
- **No probe edits** — the probe was already corrected by upstream fixes; no further hardening needed.
- **No registry edits** — the pack-glob fallback in `on_demand_script_allowlist()` already covers all `skill-packs/*/validate.sh` paths without requiring substrate-registry rows.

## Mission fitness

`adjacent` — closing stale false-positive auto-beads tightens the orchestrator triage signal. Each unclosed false-positive auto-bead consumes triage attention; closing them with explicit upstream-fix citations is the canonical sweep pattern. Serves continuous-orchestrator-uptime by reducing noise in the triage queue.

## L52 bead receipt

- `beads_filed=none`
- `beads_updated=flywheel-2xdi.46` (closed by this dispatch as false_positive_resolved_by_upstream)
- `no_bead_reason=false-positive resolved by upstream gap-hunt-probe enhancements (flywheel-2fw7v + flywheel-8vw0o); current probe correctly recognizes the script as on-demand-allowlisted; no follow-up action required`

## L61 ECOSYSTEM-TOUCH

- `agents_md_updated=not_applicable`
- `readme_updated=not_applicable`
- `no_touch_reason=false-positive sweep close; no doctrine, INCIDENTS, canonical L-rule, or skill surface touched; no code edits made`

## Skill auto-routes

| Route | Status | Note |
|---|---|---|
| canonical-cli-scoping | n/a | Read-only invocation of existing canonical probe (gap-hunt-probe.sh) |
| rust-best-practices | n/a | No Rust touched |
| python-best-practices | n/a | No Python authored (the inline allowlist replication is a one-shot probe) |
| readme-writing | n/a | No README touched |

## Four-Lens Self-Grade

- **brand: 8** — clean false-positive sweep close; cites upstream fixes; receipts pin the verified probe state.
- **sniff: 8** — confirmed via two independent paths (live probe doesn't flag, Python allowlist replication shows allowlisted).
- **jeff: 8** — single-source-of-truth: defers to upstream fixes (2fw7v + 8vw0o) rather than re-implementing detection logic; doesn't touch the probe.
- **public: 8** — Three Judges: skeptical operator (probe re-runnable to verify), maintainer (false-positive class documented for future sweeps), future worker (the upstream fixes prevent re-fire).

`four_lens=brand:8,sniff:8,jeff:8,public:8`
