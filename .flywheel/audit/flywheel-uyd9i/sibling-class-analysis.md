# bead-substrate-missing ↔ bead-missing-from-local-db sibling-class analysis

Source: `flywheel-uyd9i` worker-tick on 2026-05-09.

## TL;DR

`bead-substrate-missing` (this bead's class, 7 events in 7d) and
`bead-missing-from-local-db` (concurrent bead `flywheel-s2yd8`'s class,
3 events in 7d) describe the **same trauma**: a dispatched `josh-*`
bead ID is not present in the local `br` substrate, so `br show /
br close` returns `ISSUE_NOT_FOUND` even with `--force`. The classes
are cosmetic variants from slightly different fuckup-log writers.

Recommendation: **merge under one INCIDENTS section** so doctrine
doesn't fork. `flywheel-s2yd8` is currently authoring the canonical
entry (holds INCIDENTS.md reservation as of 2026-05-09T18:48:06Z, pane=2);
this class becomes a Sibling-Classes citation in that section.

## Evidence — event shape comparison

### `bead-missing-from-local-db` (3 events; s2yd8's class)

Sample event texts:

```
2026-05-07T18:43:33Z  "Dispatch bead josh-19yvg was not present in the local bead DB,
                       so br close josh-19yvg could not be applied after PR merg..."
2026-05-07T18:51:36Z  "dispatch bead josh-2jyzb was not present in local br issue DB
                       during React Flow worker tick"
2026-05-07T19:01:43Z  "dispatch bead josh-bmd26 was not present in local br issue DB
                       during simple-mode worker tick"
```

### `bead-substrate-missing` (7 events; this bead's class)

Sample event texts:

```
2026-05-08T02:40:01Z  "dispatch referenced bead josh-q32zp but br show/close could not
                       find it in root or backend bead DB"
2026-05-08T02:50:04Z  "dispatch referenced bead josh-8lliy but br show/close could not
                       find it in bead DB"
2026-05-08T03:00:36Z  "dispatch referenced bead josh-8kp1u but br show/close could not
                       find it in bead DB"
2026-05-08T03:07:14Z  "josh-c8tqy dispatch requested br close josh-c8tqy, but local br
                       substrate returned Issue not found even with --force"
2026-05-08T03:10:50Z  "Dispatch bead josh-e84oj was not present in local br substrate;
                       br show and force close returned ISSUE_NOT_FOUND after
                       implementation and tests passed"
2026-05-08T03:30:43Z  "josh-qrp79 dispatch bead not present in branch worktree bead
                       substrate; br show returned ISSUE_NOT_FOUND, br dep cycles clean;
                       proceeding per dispatch force-close OK"
2026-05-08T03:31:47Z  "josh-ylpa3 dispatch requested br close josh-ylpa3, but local br
                       substrate returned Issue not found even with --force"
```

## Trauma shape

Both describe the same shape:

1. Dispatch packet references a bead with id `josh-<5char>`
2. Worker runs `br show <id>` or `br close <id>` (often with `--force`)
3. Local br DB returns `ISSUE_NOT_FOUND` / "Issue not found"
4. Worker proceeds anyway (force-close, narrow exception, or callback as DONE)

Different vocabulary:
- "local bead DB" vs "local br issue DB" vs "local br substrate" vs
  "root or backend bead DB" vs "branch worktree bead substrate" — all
  refer to the same `.beads/issues.jsonl` + sqlite combination
- "ISSUE_NOT_FOUND" vs "Issue not found" — the same `br` error string

The events cluster on 2026-05-07 and 2026-05-08 (different days for
each class) but reference the same `josh-*` bead-id namespace, suggesting
the same upstream cause (probably a frankensqlite bead-DB that's
missing rows, or a cross-repo bead-id leak family).

## Recommendation

`flywheel-s2yd8` is canonical. Their INCIDENTS section should add a
**Sibling-Classes** line citing `bead-substrate-missing` plus the 7
fuckup-log line numbers from this class (lines 4078, 4081, 4144, 4181,
4182, 4185, 4186). That gives doctrine-ladder scans a single landing
pad and prevents fork.

Two patch shapes drafted for whichever path the orch picks:

| Shape | File | Action |
|---|---|---|
| **Path A — merge** | `s2yd8-sibling-class-cross-link.patch` | Append a "Sibling Classes" paragraph + line-number list to s2yd8's authored entry once it lands. |
| **Path B — separate** | `incidents-bead-substrate-missing.patch` | Standalone INCIDENTS section that cross-links s2yd8's class as the canonical sibling. |

Either path resolves L56 coverage. Path A is cleaner doctrine.

## Status

This bead `flywheel-uyd9i` is **BLOCKED** on the L107 reservation:

```
INCIDENTS.md reservation request at 2026-05-09T18:48Z returned
status=blocked: pane=2 holds task_id=flywheel-s2yd8-e69c8a since
2026-05-09T18:48:06Z (sibling-class authoring).
```

Per the worker-tick contract (do not edit shared surfaces while another
pane holds the reservation), no INCIDENTS.md write happens here. The
analysis + Path A/B drafts give the orchestrator (or `flywheel-s2yd8`'s
pane) everything needed to apply once the reservation releases.
