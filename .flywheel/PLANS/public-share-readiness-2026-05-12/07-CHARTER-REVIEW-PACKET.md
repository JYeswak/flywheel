# Charter Review Packet

Created: 2026-05-12T21:12Z  
Agent: TopazMeadow  
Bead: `flywheel-l44qh` / B0  
Draft under review: `CHARTER.md`  
Status: ready for Joshua or explicitly authorized delegate review; not approved.

## Review Decision Needed

B0 acceptance requires the landing commit for `CHARTER.md` to include:

```text
Reviewed-by: Joshua Nowak <joshua@zeststream.ai>
```

or an equivalent trailer from an explicitly authorized delegate.

The current charter draft is committed locally in:

```text
623f5165 docs(public-share): draft public charter
```

That commit does not yet include the trailer, so B0 remains `in_progress` and
the dependent public-share beads remain blocked by design.

## What The Charter Covers

| B0 requirement | Evidence in `CHARTER.md` |
|---|---|
| Audience | `## Audience` names SMB owner, solo developer, technical lead, operator, and contributor. |
| Business-owner trust path | Opening section and `## Commercial Story` explain the social-media-to-GitHub buyer path, fragmented SMB systems, manual work, and why the repo should build confidence without requiring a deep technical dive. |
| Owned surfaces | `## Owned Surfaces` names repo templates, doctrine, Beads, Agent Mail, Socraticode, doctor/tick/dispatch-or-simulate/closeout/inspection, installer, docs, and website. |
| Excluded Joshua-local state | `## Excluded State` blocks local paths, pane scrollback, client work, secrets, private ledgers, halted propagators, and private SkillOS/Mobile Eats/ZestStream state. |
| Upstream substrate story | `## Substrate Attribution` names Jeff Emanuel's substrate and states that Flywheel adopts, verifies, teaches, and operationalizes upstream improvements. |
| Publishability bar | `## Publishability Bar` requires first-read/first-command credibility, executable receipts, mechanical private-state exclusion, idempotent install/uninstall, journey receipts, and grounded ZestStream voice. |
| Review trailer | `## Governance` states the exact `Reviewed-by` requirement before B0 can close. |

## Objective Coverage

| Active goal requirement | Charter stance |
|---|---|
| Publicly installable | Public Promise requires dependency preflight, install/uninstall, and reduced-mode classification. |
| Understandable from repo or website | Public Promise and Publishability Bar require same first-run journey across docs and website. |
| Dicklesworthstone-derived substrate | Substrate Attribution names Jeff Emanuel's NTM, Beads, Agent Mail, CASS-style memory, and destructive command guard patterns. |
| Claude/Codex/OpenClaw/Gemini/reduced | Public Promise requires honest support tiers for all four harnesses and reduced local mode. |
| Initialize in own repos | Public Promise requires target-repo initialization without Joshua-specific state. |
| doctor/tick/dispatch-or-simulate/validated-closeout | Public Promise names the full command chain. |
| Inspect resulting work state | Public Promise requires Beads, receipts, or doctor output to show the next useful action. |
| Adapt without Joshua-specific state | Excluded State and Publishability Bar require mechanical private-state exclusion before public extraction. |
| SkillOS capability control plane | Boundaries section states SkillOS owns capability-loop substrate, skill governance, Jeff-stack capability ingestion, research-triad signal, and self-improving skill loops. |
| Red Hat/SMB and Mobile Eats proof surfaces | Boundaries section limits Red Hat/SMB to commercial proof surface and Mobile Eats to product/journey proof surface. |
| SMB trust / proof of competence | Commercial Story states the repo should answer whether ZestStream can run AI work safely and visibly for a buyer who does not need to operate the full substrate. |
| ZestTube and future public projects | Boundaries section names ZestTube and future public repos as proof surfaces that demonstrate project types without redefining or contaminating the engine. |

## Non-Approval Findings

Approving the charter does not mean the public-share goal is complete. It only
unblocks B0 dependents:

- B0.5 live-state denylist and probe.
- B1 de-personalization replacement table.
- B16 SkillOS capability boundary handoff.

The full goal still requires implementation and evidence for installer,
preflight matrix, reduced mode, harness support, extraction, docs, website,
fresh-laptop journey smoke, closeout, inspection, release, and public signoff.

## Reviewer Options

1. Approve as-is: amend the charter commit with the required `Reviewed-by`
   trailer, then close B0 with evidence.
2. Request edits: keep B0 `in_progress`, patch `CHARTER.md`, and repeat this
   review packet.
3. Delegate approval: name the authorized delegate and use that delegate's
   review trailer in the landing commit.
