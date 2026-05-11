# JSM-Import-Ready Patch — flywheel-2xdi.155

**Target:** `/Users/josh/.claude/skills/nango-integrations/SKILL.md` (unmanaged in JSM per `jsm list` — direct mutation allowed with paired artifact)
**Patch type:** `jsm-import-ready`
**Operation:** insert 2 bullets in "Operator UX Entrypoints" section (after `migrate-integrations-between-envs.sh`)
**Source bead:** `flywheel-2xdi.155`
**Cluster scope:** N=2 scripts (nango-image-sanity.sh + nango_prepare_env_bundle.sh)
**Pattern:** cluster-maintainer (per `.flywheel/doctrine/cluster-maintainer-pattern.md`)

## Cluster context

This is the **FIRST live cluster-maintainer bead dispatched** following xn5bm's
mechanization. The probe (post-xn5bm) clustered 2 wired-but-cold scripts under
`.claude/skills/nango-integrations/` into a single cluster gap. Worker (this
artifact) authors ONE SKILL.md mutation covering BOTH scripts — 2x reduction
in bead-filing + worker context-load vs individual-bead dispatch.

## Insertion block (2 bullets)

Inserted after the existing `migrate-integrations-between-envs.sh` entry in the
"Operator UX Entrypoints" section:

```markdown
- `scripts/nango-image-sanity.sh`: 4-line hyphen-name wrapper around `nango_image_sanity.sh` (sister underscore-name script). Use either name; both invoke the same image-sanity check (probes the Nango Railway service image tag for known-good vs drift). Operator-on-demand when image-version drift is suspected pre-deploy.
- `scripts/nango_prepare_env_bundle.sh`: pre-deploy env-bundle preparer. Sources `_nango_common.sh`; verifies the 5 required keys (`NANGO_SERVER_URL`, `NANGO_ENCRYPTION_KEY`, `NANGO_DATABASE_URL`, `NANGO_SECRET_KEY`, `NANGO_WEBHOOK_SECRET`) are present + emits a canonical env-bundle file. Operator-on-demand before `repair-run.sh --apply` to validate env shape upstream of the apply path.
```

## Rationale

`flywheel-2xdi.155` (cluster bead) listed 2 scripts in evidence:
- `scripts: nango-image-sanity.sh, nango_prepare_env_bundle.sh`

Per cluster-maintainer-pattern doctrine: ship ONE SKILL.md mutation covering all N targets. Both scripts integrated into the existing "Operator UX Entrypoints" section with Why / How / When framing matching the established bullet shape.

## Design decisions

1. **One mutation, two bullets** — not two separate edits. Cluster-maintainer mandates batch SKILL.md update.
2. **Insertion location: "Operator UX Entrypoints"** — sister section for operator-on-demand scripts (vs the "First Invocation (Ordered)" section which is for the canonical health-check sequence).
3. **Honest documentation of wrapper relationship** — `nango-image-sanity.sh` is a 98-byte hyphen-name wrapper around `nango_image_sanity.sh`; documented explicitly to avoid future maintainer confusion.
4. **Cite required env keys** — `nango_prepare_env_bundle.sh` requires 5 specific keys; documenting them in SKILL.md gives operators the runtime contract.

## Verification post-import

```bash
# 1. SKILL.md citations present
grep -q 'nango-image-sanity.sh' /Users/josh/.claude/skills/nango-integrations/SKILL.md && \
  grep -q 'nango_prepare_env_bundle.sh' /Users/josh/.claude/skills/nango-integrations/SKILL.md

# 2. Probe corpus 4 (skill_md_corpus) contains both
python3 -c "
import os
texts = []
for root, dirs, files in os.walk(os.path.expanduser('~/.claude/skills')):
    for f in files:
        if f == 'SKILL.md':
            try:
                with open(os.path.join(root, f)) as fh:
                    texts.append(fh.read())
            except: pass
corpus = '\n'.join(texts)
assert 'nango-image-sanity.sh' in corpus
assert 'nango_prepare_env_bundle.sh' in corpus
print('both scripts in SKILL.md corpus')
"

# 3. Cluster gap cleared
.flywheel/scripts/gap-hunt-probe.sh --json 2>/dev/null | jq -e '
  [.gap_ids[]? | select(test("nango-integrations"))] | length == 0
' >/dev/null && echo "CLUSTER CLEARED"
```

## Boundary

Per `feedback_no_push_ntm_br.md` + `project_skillos_separated.md`: this patch
targets `~/.claude/skills/nango-integrations/` (skill substrate, separate repo
from flywheel.git). Direct mutation already applied because `nango-integrations`
is UNMANAGED in JSM (`jsm list` does not return it; verified). This artifact
exists for future JSM import if/when the skill becomes managed.

## Cluster-maintainer pattern recipe (formal)

Per `.flywheel/doctrine/cluster-maintainer-pattern.md` (canonical recipe):

1. Read cluster bead's evidence (lists N scripts) ✓
2. Verify all N scripts exist + read their purposes ✓
3. JSM status check (managed → push-ready, unmanaged → import-ready) ✓
4. Single SKILL.md mutation covering all N targets ✓ (Operator UX Entrypoints, 2 bullets)
5. Paired patch artifact (this file) ✓
6. N subordinate beads bulk-close: N/A (no subordinate beads existed; xn5bm absorbed them into the cluster gap)
7. Probe-cleared verification ✓ (`cluster_for_nango: 0`)
8. Evidence pack + journal ✓

8/8 recipe steps complete.
