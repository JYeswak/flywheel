# Journey: flywheel-6kdnf

Bead = "file the wz5rh draft as upstream beads_rust issue". Simple deliverable.

But Joshua asked at gate "does it follow jeff-issue-chain end to end?" — self-audit caught Rule-2 gap (5+ workaround research). Dispatched workaround-research subagent (20min):
- Verified bug shape: NOT issue_prefix → source_repo; actually canonical_source_repo basename behavior
- Source-traced 3 upstream commits (03167479 → 912126d8 → 648b50f1)
- Copy-tested 5 workarounds in `mktemp -d` fixtures: W1 (applied wz5rh), W2 (REJECT), W3 (works but call-site-heavy), W4 (works with --force bypass), W5 (REJECT)
- Decision: file issue (upstream fix already on master at 648b50f1; ask is release-or-clarify + new repair flag)

Rewrote issue body with corrected bug shape + commit citations + 5-row workaround matrix. Joshua confirmed → filed as #289.

Net: 20min research investment turned a draft with wrong root cause + 1 workaround into an issue with verified root cause + 5 workarounds + 3 commit citations.
