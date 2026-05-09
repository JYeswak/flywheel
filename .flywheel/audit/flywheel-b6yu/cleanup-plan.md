# Backup-first cleanup plan — `~/.config/ntm/config.toml` and `~/.config/ntm/recipes.toml`

> **Status:** DRAFT pending Joshua approval. Do **NOT** execute
> without explicit Joshua signoff. No file mutated this turn.

## Phase 0 — Backup

```bash
cp ~/.config/ntm/config.toml \
   ~/.config/ntm/config.toml.bak.$(date -u +%Y%m%dT%H%M%SZ)
cp ~/.config/ntm/recipes.toml \
   ~/.config/ntm/recipes.toml.bak.$(date -u +%Y%m%dT%H%M%SZ)
```

## Phase 1 — Sidecar extension files (move custom-extension fields out of strict NTM schema)

Create two new sidecars in a flywheel-owned namespace:

```bash
mkdir -p ~/.config/flywheel
touch ~/.config/flywheel/ntm-extensions.toml
touch ~/.config/flywheel/session-paths.toml
```

Move these blocks from `~/.config/ntm/config.toml` to
`~/.config/flywheel/ntm-extensions.toml` (TOML-valid, flywheel reads
this surface; ntm does not):

- `[agents.claude-local]`, `[agents.deepagents]`, `[agents.zesty]`,
  `[agents.zesty-worker]`
- `[models.claude-local]`, `[models.pi]`, `[models.zesty]`
- `[coordinator.schema_version]` field + `[coordinator.session_default]`
  block (preserved as forward-compatible flywheel-side until upstream
  adds per-session defaults; see "Upstream draft" below)
- `[scanner]` block (`warning_threshold` + any siblings)

Move these blocks from `~/.config/ntm/config.toml` to
`~/.config/flywheel/session-paths.toml`:

- `[session_paths]` parent + all 22 named entries
  (agent-bench, alps-insurance, alpsinsurance, bearnecessities,
  chanelscloset, clutterfreespaces, cubchat, cubcloud-bears,
  fc-sandbox, flywheel, gpu-optimization, josh-ops, local-agents,
  openfang-setup, picoz, skillos, terratitle, vrtx, zeststream-v2,
  zesttube)

Cross-link with sibling decision flywheel-dm83
(`.flywheel/decisions/dm83-ntm-roster-sync-2026-05-09.md`):
session-paths is a flywheel-substrate concern; NTM today does not own
this metadata.

## Phase 2 — Remove keys with no runtime consumer (per #113)

`health.researcher_sessions` has zero runtime consumers in the local
fleet (grep across `/Users/josh/Developer/flywheel` and
`/Users/josh/.claude` returns only plan docs and handoffs — no scripts
read this field). Per ntm #113 decision: stays rejected. Recommend
removal from `~/.config/ntm/config.toml`. If a future runtime
consumer materializes, restore from backup.

## Phase 3 — `recipes.toml` cleanup

The recipes `cubcode`, `pi-team`, `hybrid` reference unsupported agent
types `zesty` and `pi` (ntm #121 was closed without adding them to
the agent enum). Two options for Joshua decision:

- **Option A (recommended):** comment out the offending entries in
  `~/.config/ntm/recipes.toml` with a header line documenting the
  decision (`# zesty/pi agent types are local extensions; ntm #121
  closed without enum addition; reactivate when plugin support
  ships`).
- **Option B:** move the recipes to
  `~/.config/flywheel/ntm-recipes-extensions.toml` and let ntm see a
  trimmed `recipes.toml`.

## Phase 4 — Re-validate

```bash
ntm config validate --json > /tmp/validate-after-flywheel-b6yu.json
jq '.summary' /tmp/validate-after-flywheel-b6yu.json
```

Expected: `error_count: 0`, `valid: true` for both files.

If `error_count > 0`, restore from `*.bak.*` and re-classify. The
backup retention is open-ended (`*.bak.*` files preserved for 30+
days minimum).

## Phase 5 — Roll back guard

```bash
# Roll back command (single line):
cp ~/.config/ntm/config.toml.bak.<TIMESTAMP> ~/.config/ntm/config.toml \
  && cp ~/.config/ntm/recipes.toml.bak.<TIMESTAMP> ~/.config/ntm/recipes.toml \
  && ntm config validate --json | jq .summary
```

## Joshua signoff checklist

- [ ] Phase 1 sidecar move reviewed for correctness (no duplicate
      sections, no comment loss).
- [ ] Phase 2 removal of `health.researcher_sessions` confirmed safe
      (no runtime consumer found 2026-05-09).
- [ ] Phase 3 chooses Option A or Option B for recipes.
- [ ] Backup retention strategy approved (30 days minimum).
- [ ] Re-validation receipt at `/tmp/validate-after-flywheel-b6yu.json`
      shows `error_count: 0` before close.
- [ ] Optional: an upstream issue covering `coordinator.session_default`
      per-session overrides (draft staged at
      `.flywheel/audit/flywheel-b6yu/upstream-issue-draft.md`).

## Why no mutation this turn

Per acceptance criterion: "If local-only, produce a backup-first
config cleanup plan; do not mutate `~/.config/ntm/config.toml`
without Joshua approval." This document is the plan. Execution is
gated.
