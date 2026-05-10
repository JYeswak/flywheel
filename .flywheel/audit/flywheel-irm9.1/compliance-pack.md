# flywheel-irm9.1 Compliance Pack

Task: `flywheel-irm9.1-02d2f0`
Bead: `flywheel-irm9.1`
Decision: DONE (jsm-push-ready patch artifact produced; direct mutation forbidden per JSM discipline)
Compliance score: 880/1000

## Final receipt

```
jsm_managed=YES (cass version=6, is_saved=true via jsm list --json)
no_direct_skill_mutation_reason=jsm_managed_patch_artifact_written
patch_artifact=.flywheel/audit/flywheel-irm9.1/jsm-push-ready.patch
patched_preview=.flywheel/audit/flywheel-irm9.1/validate-patched.sh
patched_validator_smoke_test=PASS (full run against installed cass 0.2.0 returns "Validation Complete")
```

## Finding

Dispatch `flywheel-irm9-c7d2dd` observed that
`~/.claude/skills/cass/scripts/validate.sh:27` invokes
`cass status --robot-format json`, but installed cass 0.2.0 returns
"Could not parse arguments" for that flag. The current canonical
flag is `--json`, which returns valid JSON with `healthy:true` and
`index.fresh:true`.

```text
$ cass --version
cass 0.2.0

$ cass status --robot-format json
Could not parse arguments

$ cass status --json | jq '.healthy, .index.fresh'
true
true
```

This is a Jeff-substrate version-drift class
(per `feedback_jeff_substrate_version_drift.md`): the validator
script was authored against an older cass CLI surface; the flag
got renamed; the validator never updated.

## JSM discipline (pre-flight gate)

Per the dispatch packet's "Pre-flight before any skill file
mutation" block:

> If `jsm status` or `jsm list --json` shows the skill is
> JSM-managed, direct live mutation under `~/.claude/skills/<skill>/`
> is forbidden. Produce a `jsm-push-ready` patch artifact instead.

Live `jsm list --json` confirms cass IS JSM-managed:

```json
{"name": "cass", "version": 6, "pinned": false,
 "installed_at": "2026-05-08", "status": "? unknown",
 "update_available": false, "latest_version": null,
 "is_saved": true}
```

Direct mutation forbidden. Patch artifact path used instead.

## Repair (jsm-push-ready patch)

Patch artifact at
`.flywheel/audit/flywheel-irm9.1/jsm-push-ready.patch` (unified
diff format, ready for `jsm push` consumption). The fix replaces
the single-flag invocation with a tiered try-then-fallback that
supports BOTH cass surfaces:

```bash
# Try --json first (cass >= 0.2.0); fall back to --robot-format json for
# older cass builds (< 0.2.0). flywheel-irm9.1 fix: cass 0.2.0 emits
# "Could not parse arguments" for --robot-format json; --json is the
# current canonical robot-output flag.
if STATUS=$(cass status --json 2>/dev/null); then
    :
elif STATUS=$(cass status --robot-format json 2>/dev/null); then
    :
else
    echo "ERROR: cass status failed"
    echo "FIX: Run 'cass doctor' to repair"
    exit 2
fi
```

Tiered approach is safer than outright replacement because:
1. Some operators may still have an older cass build cached;
   the fallback preserves their path.
2. The cass 0.2.0 → next version cycle may rename `--json`
   again; structured fallback chains tolerate that.
3. Both probes use `2>/dev/null` so the user-facing error
   only surfaces when BOTH flags fail.

## Patched preview verification

A rendered preview of the patched script is saved at
`.flywheel/audit/flywheel-irm9.1/validate-patched.sh` (same content
that would land in `~/.claude/skills/cass/scripts/validate.sh`
post-patch). Smoke-test ran the rendered preview end-to-end against
the live cass 0.2.0 install:

```text
$ bash .flywheel/audit/flywheel-irm9.1/validate-patched.sh
=== cass Session Search Validation ===
✓ cass found: /Users/josh/.local/bin/cass
Checking cass status...
✓ Index is fresh
✓ Indexed conversations: 33051
Testing basic search...
✓ Basic search works
Testing aggregation...
✓ Aggregation works
=== Validation Complete ===
cass is ready to use
```

Exit code 0. The bead's symptom (validator failing on cass 0.2.0)
is resolved by this patch.

## jsm-push runbook (orch-side application)

When the orchestrator (or a JSM-aware worker) is ready to apply
this patch, the canonical motion is:

```bash
# 1. Pull the latest cass skill source from JSM
cd $(jsm path cass)   # or wherever the JSM-managed source lives

# 2. Apply the patch
patch -p1 < /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-irm9.1/jsm-push-ready.patch

# 3. Verify the patched validator
bash scripts/validate.sh

# 4. Push to JSM (creates a new pinned version)
jsm push cass --message "validate.sh: support cass status --json (flywheel-irm9.1)"

# 5. Reinstall locally
jsm install cass
```

This dispatch's worker-tick scope ENDS at producing the patch
artifact + verification preview. Pushing to JSM is orch-side work
because it's a versioned-skill-substrate mutation that touches
the JSM source-of-truth, not just local files.

## Acceptance Gate Map

| # | Gate | Status |
|---|------|--------|
| AG1 | Artifact named in bead body updated with close evidence | ✓ Patch artifact + patched preview + this audit pack ship the close evidence |
| AG2 | Targeted test/validator command passes and is named in close receipt | ✓ Patched preview ran end-to-end against installed cass 0.2.0; 2-line smoke test (`cass status --json | jq '.healthy, .index.fresh'` returns `true / true`) confirms the new code path works |
| AG3 | Bead remains open until evidence artifact exists | ✓ Audit pack written before close |
| Bead-body | Update validator to accept current/live cass status output | ✓ Patch updates line 27 to try `--json` first, fall back to `--robot-format json`; both surfaces accepted |
| Bead-body | OR gate on supported CLI version before failing | The tiered try-then-fallback IS a soft version-gate (no hard `cass --version` parse needed); both surfaces work or both fail with one consolidated error |

did=5/5

## Evidence

```text
$ # JSM management proof:
$ jsm list --json | python3 -c "import sys,json; d=json.load(sys.stdin); print([s for s in (d.get('skills',d) if isinstance(d, dict) else d) if 'cass' == s.get('name')][0])"
{'name': 'cass', 'version': 6, 'pinned': False, 'installed_at': '2026-05-08',
 'status': '? unknown', 'update_available': False, 'latest_version': None,
 'is_saved': True}

$ # Reproduction of the symptom:
$ cass status --robot-format json
Could not parse arguments

$ # Working canonical flag:
$ cass status --json | jq '.healthy, .index.fresh'
true
true

$ # Patch artifact validates as unified diff:
$ head -3 .flywheel/audit/flywheel-irm9.1/jsm-push-ready.patch
--- a/scripts/validate.sh
+++ b/scripts/validate.sh
@@ -23,8 +23,16 @@ echo "✓ cass found: $(command -v cass)"

$ # End-to-end run of patched preview:
$ bash .flywheel/audit/flywheel-irm9.1/validate-patched.sh | tail -3
=== Validation Complete ===
cass is ready to use
```

## Scope

- Edits: 3 new files in audit dir (no source skill mutation per
  JSM discipline)
  - `.flywheel/audit/flywheel-irm9.1/jsm-push-ready.patch` (unified
    diff, ready for `jsm push` consumption)
  - `.flywheel/audit/flywheel-irm9.1/validate-patched.sh` (rendered
    preview of the post-patch script for verification + reviewer
    inspection)
  - `.flywheel/audit/flywheel-irm9.1/compliance-pack.md` (this file)
- Files reserved/released: NONE_NO_EDITS (no skill-source
  mutation; patch artifact lives in flywheel audit dir, not in
  the skill source tree)
- Out of scope: applying the patch to the JSM-managed cass skill
  (orch-side `jsm push` motion); modifying cass CLI itself (Jeff
  substrate ownership); editing the
  `~/.claude/skills/cass/scripts/validate.sh` directly (forbidden
  per JSM discipline)

## L52 / L80 / L120 / L61

- DIDNT: orch-side `jsm push` (sequenced after patch review;
  not a worker-scope action)
- GAPS: none new (the cass CLI surface drift is captured by the
  bead's own existence; the patch closes it)
- beads_filed: none
- beads_updated: none
- no_bead_reason: jsm-managed-patch-artifact-fix-no-followup-bead
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: not_applicable
- no_direct_skill_mutation_reason: `jsm_managed_patch_artifact_written`

## Four Lens

- Brand: 9 (JSM discipline respected — no unilateral skill-tree
  mutation; tiered try-then-fallback approach matches Jeffrey's
  substrate-version-drift handling pattern; runbook for
  orch-side application is operator-actionable)
- Sniff: 9 (reproduction proven both ways:
  `--robot-format json` returns "Could not parse arguments"
  AND `--json` returns valid JSON; patched preview ran end-to-end
  against live cass 0.2.0 with full validation pass)
- Jeff: 8 (no Jeff-repo touch; the substrate-version-drift class
  matches `feedback_jeff_substrate_version_drift.md` pattern;
  patch is conservative — supports BOTH surfaces, doesn't break
  older cass installs)
- Public: 9 (a future operator hitting cass version drift can
  read this audit pack, see the patch + preview, run the
  smoke test, and apply via `jsm push` — full chain reproducible)

## Skill Auto-Routes

- canonical-cli-scoping: addressed=n/a (no NEW CLI surface added;
  the patch updates ONE invocation of an existing CLI surface
  to use the canonical flag)
- rust-best-practices: n/a — no Rust touched
- python-best-practices: n/a — no Python touched
- readme-writing: n/a — no README touched

## L112 Probe

```
cass status --json | jq -e '.healthy == true and .index.fresh == true'
```
Expected: `jq:.healthy==true and .index.fresh==true` returns
`true`. The probe confirms the new code path's primary flag works
on this host.

A complementary probe verifies the patched preview script:

```
bash /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-irm9.1/validate-patched.sh \
  | grep -c "=== Validation Complete ==="
```
Expected: `literal:1` (one completion marker; full validation
pass).
