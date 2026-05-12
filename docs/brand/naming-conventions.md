# Naming Conventions

Flywheel's public language has to do two jobs at once: give business owners a
clear reason to trust ZestStream, and give technical readers a stable map of the
engine they can inspect.

Names should be distinctive without becoming opaque. A reader should know which
surface belongs to ZestStream, which surface belongs to Flywheel, which surface
belongs to SkillOS, and which surface is upstream Dicklesworthstone substrate.

## Canonical Terms

| Term | Use | Do not use for |
|---|---|---|
| ZestStream | The company and service operator. | The open-source engine itself. |
| Flywheel | The public engine: repo initialization, loop commands, receipts, docs, installability, and publication gates. | Product repos, private client systems, or SkillOS capability governance. |
| Yuzu Method | ZestStream's operating method for compounding lessons across projects. | A replacement name for every Flywheel command or file. |
| Yuzu | Mascot or light brand signal. | A technical subsystem name unless the surface is intentionally branded. |
| Peel / Press / Pour | A workflow verb set inside the Yuzu Method. | The entire naming convention. |
| SkillOS | Capability control plane and skill-governance substrate. | Flywheel's public installability engine. |
| ZestTube | Public proof surface showing project output. | The Flywheel engine or a generic template. |
| Mobile Eats | Journey semantics and proof-surface input. | Flywheel's product meaning. |
| Jeff / Dicklesworthstone substrate | Upstream ideas and tools Flywheel adopts, verifies, and teaches. | Anonymous internal infrastructure. |
| NTM, Beads, Agent Mail, CASS-style memory, DCG, Socraticode | Upstream or adjacent substrate names. Preserve them when describing dependencies and detection. | ZestStream-owned inventions. |

## Naming Rules

1. Business-facing copy leads with ZestStream, practical workflow value, and
   proof that the work is operated safely.
2. Technical docs use Flywheel for the engine and keep command names stable
   unless there is a coordinated rename plan.
3. Yuzu Method names the operating philosophy and branded method, not every
   helper script.
4. Upstream substrate names stay intact. Flywheel can explain how it implements
   and verifies them; it should not rename them into ZestStream-owned terms.
5. Product repos such as ZestTube are proof surfaces. They can demonstrate what
   Flywheel enables without becoming part of the engine namespace.
6. Any rename that touches shared substrate is a cross-repo wire-or-explain
   event, not a local cleanup.
7. Domain-collision words such as `doctor`, `ledger`, `worker`, `dispatch`,
   `tick`, and `reap` require scope-aware rename protection. They are legitimate
   words in client domains and cannot be blindly replaced.

## Public Surface Pattern

Use this hierarchy when writing README, docs, website copy, and release notes:

| Layer | Naming stance |
|---|---|
| Company | ZestStream builds and operates the system. |
| Method | The Yuzu Method explains how project lessons compound. |
| Engine | Flywheel is the installable, inspectable operating engine. |
| Substrate | Jeff/Dicklesworthstone and adjacent tools are attributed directly. |
| Proof surfaces | ZestTube and future public repos show outcomes. |

## Rename Gate

Do not perform a broad naming sweep until a plan names:

- old name and new name;
- all consumer repos and files discovered with Socraticode or equivalent search;
- path allowlists for every repo;
- domain-collision sampling result;
- verification commands proving old names are gone only from intended surfaces;
- explicit deferral receipts for upstream or off-limits consumers.

The procedural references are:

- `.flywheel/doctrine/naming-convention-distinguishable-ownership.md`
- `.flywheel/doctrine/naming-rename-cross-repo-wire-or-explain.md`
- `.flywheel/doctrine/scope-aware-rename-domain-collision-protection.md`

Publication can proceed with this convention documented and tested. A later
Yuzu Method rename sweep should use this document as the public-facing naming
contract and the doctrine files as the internal apply discipline.
