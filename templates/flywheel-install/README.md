# flywheel-install templates

Template-backed source files for portable `flywheel-loop init`.

## Contract

- `MISSION.md.tmpl`, `GOAL.md.tmpl`, and `STATE.md.tmpl` render locked repo-local docs with the full v0.1.0 frontmatter contract.
- `loop.json.tmpl` renders the repo-local portable loop config.
- `validate-callback-before-close.sh.tmpl` installs the four-lens close validator into `.flywheel/scripts/`.
- `render.sh` is the only renderer in this directory. It is bash-only, takes one template path, reads `key=value` substitutions from stdin, preserves multiline values, allows empty values, and fails if any `{{marker}}` remains.
- `schema.json` documents the required frontmatter keys, template set, and `loop.json` keys for this template version.
- Idle watcher launchd plists live in `.flywheel/launchd/` in the flywheel repo and are activated through `/flywheel:loop watcher ...` so repo-local loops can prove a driver, not just an active marker.

## Polish Gate

Polish Gate is the Phase 2 quality gate for flywheel-installed repos: it starts in `bootstrap`, can run as `audit_only`, and becomes `blocking` once required surfaces are reconciled. The manifest schema is `polish-gate/v1/manifest.schema.json`; grade JSONL rows use `polish-gate/v1/grade-receipt.schema.json`; the current aggregate uses `polish-gate/v1/latest-summary.schema.json`; mode examples live under `polish-gate/fixtures/`; the implementation plan remains the Phase 2 P2-01 through P2-04 polish-gate plan.

## Hashes

Run this after template edits and update the table in the same patch:

```bash
shasum -a 256 templates/flywheel-install/*.tmpl
```

| Template | SHA-256 |
|---|---|
| `ESCALATION-LADDER.md.tmpl` | `e73b5f2938e21f92e4636cbe50ddd6599e3a72cc95b881d46d337be182c90eae` |
| `MISSION.md.tmpl` | `9aca1e19d34c539a5e91d6d81ad8834b0c7973167061116a02049f5fd6ee6adf` |
| `GOAL.md.tmpl` | `43d3b3f39af636be079de8e8d2728360fced885e6438c26afd88f5e461a17ebf` |
| `STATE.md.tmpl` | `1c262f716519326ffa0ba1fcc6ce0b8f8fd41236a0d885f2d4b70f878a852494` |
| `loop.json.tmpl` | `fe22c635b4f1342eae3c2358b921c3849fc109cbab7c60e83e3d02275ff35b3f` |
| `validate-callback-before-close.sh.tmpl` | `87ec6f9fbc04ce87bb7fffc7379b8140a293efe37816ee62f7f9b43a2d239c97` |

Rendered files should carry the hash of the specific template used in `template_hash`.

Part of the Yuzu Method framework by ZestStream.
