# flywheel-mzvd0 Evidence

Task: `flywheel-mzvd0-4746c0`
Worker identity: `MagentaPond`
Mission fitness: adjacent

## Socraticode Survey

- `socraticode_queries=10`
- `indexed_chunks_observed=1553`
- Findings: no existing container isolation profile was present; existing
  security fixture tests established the local pattern of executable shell
  policy checks and synthetic secret fixtures.

## Acceptance Evidence

1. `.flywheel/security/v1/container-isolation.md` exists and defines
   `container-isolation/v1`.
2. `tests/security-container-isolation.sh` rejects privileged mode, host
   network mode, Docker socket mounts, `.env` env-file use, and `.env` bind
   mounts.
3. The high-security fixture rejects non-allowlisted env such as
   `AWS_ACCESS_KEY_ID` and passes allowlisted env such as `HOME`.
4. The hardened fixture passes with read-only root, no-new-privileges,
   `--cap-drop=ALL`, no network, tmpfs `/tmp`, and an explicit `/workspace`
   bind mount.
5. `README.md` documents when the sandbox is required for prod credentials and
   when it is not required for synthetic fixtures or redacted/offline work.
6. The profile states `doctor_signal.status: recommendation` and
   `blanket_failure: false`.

## Verification

```bash
bash -n tests/security-container-isolation.sh
bash tests/security-container-isolation.sh
bash tests/canary-secret-scan.sh
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-mzvd0-4746c0.md
```

Observed results:

- `PASS security-container-isolation`
- `PASS canary-secret-scan synthetic_leak_caught=true clean_evidence_passes=true`
- dispatch template audit `valid=true`

## File Reservations

Reserved through `.flywheel/scripts/shared-surface-reservation-check.sh`:

- `.flywheel/security/v1/container-isolation.md`
- `tests/security-container-isolation.sh`
- `README.md`
- `.flywheel/receipts/flywheel-mzvd0/evidence.md`
- `.flywheel/validation-receipts/flywheel-mzvd0-4746c0.json`
- `.flywheel/compliance-packs/flywheel-mzvd0/`

## L52 / Skill Discovery

- `no_bead_reason=completed_existing_bead_acceptance_no_new_issue`
- `skill_discoveries=0`
- No reusable skill gap or broken skill surfaced.

## Four-Lens Self-Grade

`four_lens=brand:9,sniff:9,jeff:9,public:9`

- Brand: the profile is clear, compact, and matches existing flywheel security
  control language.
- Sniff: the test proves both denials and the desired hardened pass path.
- Jeff: the work keeps mutation local, path-scoped, and auditable.
- Public: a skeptical operator, maintainer, and future worker can rerun the
  evidence from the commands above.
