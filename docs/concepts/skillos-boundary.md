# SkillOS Boundary

Flywheel and SkillOS are adjacent systems with different jobs.

Flywheel owns public installability, repo-local loop commands, reduced-mode
fallbacks, doctor gates, receipts, and publication evidence.

SkillOS owns the capability control plane: skill governance, capability-pack
routing, upstream skill ingestion, and validated skill loops.

The boundary matters because public Flywheel can name SkillOS as an integration
point without copying private SkillOS state. That keeps the public repo useful
and honest: Flywheel shows how it would connect to a capability plane, while
reduced mode still works when that plane is absent.
