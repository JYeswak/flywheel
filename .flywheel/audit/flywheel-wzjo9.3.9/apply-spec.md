# flywheel-wzjo9.3.9 — apply-spec

## Identity

**Bead:** flywheel-wzjo9.3.9
**Wave label:** wave-2.0c-i (sub-bead i of 9 in wave-2.0c — flywheel ecosystem skills + validators)
**Parent (wave):** flywheel-wzjo9.3
**Grandparent (lane):** flywheel-wzjo9

## Surface

| Attribute | Value |
|---|---|
| Name | `validate-skill-discovery-callback.sh` |
| Path | `.flywheel/scripts/validate-skill-discovery-callback.sh` |
| Lines | 86 |
| Interpreter | bash |
| Priority | P2 |
| Location | repo scripts |

## Scope

Single-surface scaffold + 18-TODO substantive fillin following the canonical sister-fillin shape (wzjo9.1.x + wzjo9.2.x pattern; sister waves avg 984 / 992).

## Deliverables

1. **Dry-run scaffold:** `scaffold-canonical-cli.sh .flywheel/scripts/validate-skill-discovery-callback.sh --json`
2. **Apply with idempotency-key:** `scaffold-canonical-cli.sh .flywheel/scripts/validate-skill-discovery-callback.sh --apply --idempotency-key=flywheel-wzjo9.3.9-pilot --json`
3. **Substantive 18-TODO fillin** matching sister-fillin shape
4. **Test additions:** extend baseline 15-test scaffold to ≥19

## Acceptance gates

- AG1: 18 TODO markers replaced
- AG2: bash -n clean
- AG3: canonical-cli-lint clean
- AG4: scaffold-test PASS (≥13/13, prefer 20/20)
- AG5: each canonical surface returns concrete data

## Validation predicate (strict)

```bash
cd /Users/josh/Developer/flywheel
bash -n .flywheel/scripts/validate-skill-discovery-callback.sh \
  && grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/validate-skill-discovery-callback.sh | grep -qx 0 \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/validate-skill-discovery-callback.sh \
  && bash tests/validate-skill-discovery-callback-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

## Estimated wall-time

30-60 min.

## Cross-refs

- Parent (wave): flywheel-wzjo9.3
- Lane: flywheel-wzjo9
- Sister waves: wzjo9.1 (avg 984), wzjo9.2 (avg ~992)
- Scaffolder: .flywheel/scripts/scaffold-canonical-cli.sh
- Helper lib: .flywheel/lib/canonical-cli-helpers.sh

## Doctrine pointers

- SIGPIPE/pipefail multi-printf trap → single-printf topic_help
- `cli_emit_audit_tail` signature: (path, schema, limit) — path first
- Apply-gate fires BEFORE side-effects (flywheel-hoqq8)
- Verb-collision bypass auto-emitted (flywheel-sacan)
