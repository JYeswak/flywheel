# Repo Hygiene Prompt Template

Session: `<target-session>`
Target repo: `<repo-path>`
Targets YAML: `<repo-path>/.flywheel/hygiene-targets.yaml`
Doctrine version: `<doctrine-version>`

/storage-health /dev-cache-janitor /apfs-snapshot-ops /docker-storage-ops /orbstack-ops /storage-ballast-helper /disk-observer /path-rationalization /canonical-cli-scoping /extreme-software-optimization

## Mission

Run a repo hygiene dry-run for `<repo-path>` using the repo-local
`.flywheel/hygiene-targets.yaml` as the residue contract. This is not a bundled
skill. Compose the listed skills inline, pin the YAML as context, and produce a
read-only receipt the orchestrator can compare across ticks.

## Hard Gates

- Default mode is dry-run.
- Do not delete, move, compress, rewrite, or chmod files.
- Do not use `--apply`.
- Any future apply path requires {operator} review plus `--idempotency-key`.
- Refuse tracked-file targets. Verify candidates with `git ls-files`.
- Evidence classes marked `never-delete-only-document` are report-only unless an
  explicit archive receipt is already present.
- Prefer local prior-art scripts named by the YAML over generic shell deletion.
- If the YAML is missing or invalid, stop and report `hygiene_targets_present=false`.

## Required Context

Read:

```bash
cat "<repo-path>/.flywheel/hygiene-targets.yaml"
```

Validate:

```bash
python3 - <<'PY'
import json, sys, yaml
from jsonschema import Draft202012Validator
schema_path = "<flywheel-repo>/templates/flywheel-install/hygiene-targets.schema.json"
yaml_path = "<repo-path>/.flywheel/hygiene-targets.yaml"
with open(schema_path, encoding="utf-8") as f:
    schema = json.load(f)
with open(yaml_path, encoding="utf-8") as f:
    data = yaml.safe_load(f)
Draft202012Validator.check_schema(schema)
Draft202012Validator(schema).validate(data)
names = [row["name"] for row in data["trauma_classes"]]
if len(names) != len(set(names)):
    raise SystemExit("duplicate trauma class names")
print("hygiene_targets_valid=true")
PY
```

## Dry-Run Phases

1. Storage gate:
   - Run the storage-health read-only probe.
   - Record disk free, repo size, and whether host pressure changes the
     recommendation.

2. Target measurement:
   - For every `trauma_classes[].patterns[]`, measure path glob, total bytes,
     file count, oldest mtime, newest mtime, and recurrence count.
   - Use `du`, `find`, `stat`, or local read-only scripts.
   - No estimates.

3. Git safety:
   - Check every candidate against `git ls-files`.
   - `tracked_target_count > 0` is a FAIL.
   - Separately list recurring untracked patterns not represented in
     `gitignore_gaps`.

4. Tooling pass:
   - Detect Node/Next/Vercel/Python/Beads/Flywheel/Remotion/Supabase/Docker.
   - Use the inline skills to classify whether each target is:
     `always-safe`, `age-gated`, or `never-delete-only-document`.

5. Recommendation:
   - For each class, choose exactly one:
     `no-action`, `add-to-gitignore`, `add-to-hygiene-targets`,
     `dry-run-only`, `archive-before-prune`, or `never-delete-only-document`.

## Output Contract

Emit JSON plus a Markdown receipt:

```json
{
  "schema_version": "repo_hygiene.dry_run_receipt.v1",
  "repo_path": "<repo-path>",
  "doctrine_version": "<doctrine-version>",
  "mode": "dry-run",
  "hygiene_targets_present": true,
  "hygiene_targets_valid": true,
  "storage_gate": {
    "ok": true,
    "notes": []
  },
  "candidate_total_bytes": 0,
  "candidate_count": 0,
  "unsafe_target_count": 0,
  "tracked_target_count": 0,
  "gitignore_gap_count": 0,
  "classes": [],
  "next_actions": []
}
```

## Close Contract

When this prompt is run as a dispatched bead, close with the post-L126 evidence
contract:

```text
DONE repo-hygiene session=<target-session> repo=<repo-path> receipt=<path> compliance_pack_path=<path-or-null> hygiene_targets_present=<true|false> candidate_total_bytes=<N> tracked_target_count=<N>
```

