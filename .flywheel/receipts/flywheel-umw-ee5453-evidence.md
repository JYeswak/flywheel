# flywheel-umw-ee5453 Evidence

Bead: `flywheel-umw`
Task: `flywheel-umw-ee5453`

## Changes

- Added `.flywheel/scripts/ntm-spawn-templates-versioned.py`.
- Added `.flywheel/ntm-spawn-template-registry.json`.
- Added `tests/ntm-spawn-templates-versioned.sh`.
- Wired live `flywheel-loop doctor` to expose `ntm_spawn_templates_versioned`.

## Validation

```text
tests/ntm-spawn-templates-versioned.sh
ntm-spawn-templates-versioned tests passed
```

```text
python3 -m py_compile .flywheel/scripts/ntm-spawn-templates-versioned.py
pass
```

```text
bash -n /Users/josh/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh
bash -n /Users/josh/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh
pass
```

```json
{
  "standalone_status": "warn",
  "invariant_id": "ntm:spawn-templates-versioned",
  "warning_count": 1,
  "warning_code": "template_dir_missing",
  "template_dir": "/Users/josh/.config/ntm/spawn-templates",
  "template_dir_exists": false,
  "ntm_version": "dev",
  "ntm_commit": "none"
}
```

```json
{
  "flywheel_loop_doctor_status": "fail",
  "flywheel_loop_doctor_action": "repair_validation_receipt_schema",
  "ntm_spawn_templates_versioned_status": "warn",
  "ntm_spawn_templates_versioned_warning_count": 1,
  "warning_code_present": "ntm_spawn_templates_versioned_warn"
}
```

The full doctor status was already failing for unrelated validation-receipt schema state; the new invariant is present and independently warns with the template SHA/version matrix.
