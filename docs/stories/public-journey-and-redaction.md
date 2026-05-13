# Public Journey And Redaction

Flywheel has two public readers.

The first reader is a business owner who has too many disconnected systems,
too much manual work, and no clear way to evaluate whether an AI operator can
run the work safely. That reader does not need to learn the whole agentic coding
stack. They need a grounded reason to trust the method.

The second reader is a developer or technical operator who wants to inspect the
engine, run the first loop, and decide whether the system is coherent enough to
adapt.

Both readers should see the same principle: Flywheel does not ask for trust
because it sounds advanced. It earns trust by exposing the loop, the checks, the
limits, and the evidence.

## Business-Owner Story

Many SMBs live with the same shape of problem:

- five or more systems that do not talk to each other;
- manual reconciliation between tools;
- reporting that depends on one person remembering the process;
- software decisions made without a clear operating picture;
- uncertainty about whether AI work is disciplined or just fast typing.

Flywheel is the public method behind ZestStream's answer to that problem. It
takes fast-moving AI coding substrate, verifies it with doctors and receipts,
and turns project lessons into reusable operating patterns. Each project should
make the next one safer, faster, and easier to inspect.

The business owner does not need to operate NTM, Beads, Agent Mail, or
Socraticode directly. They should be able to see that ZestStream knows how to
use those tools, where the boundaries are, and how the work is checked before
it becomes a claim.

## Developer Story

A developer should be able to land on the repo and answer four questions:

1. What does Flywheel own?
2. What does it depend on?
3. What can I run without private ZestStream state?
4. Which support claims are proven by receipts?

The public answer is reduced mode first. Reduced mode proves the loop shape
without private fleet substrate:

```bash
scripts/preflight.sh --json
scripts/journey-smoke.sh --matrix reduced --dry-run --json
```

Full mode remains substrate-dependent. Claude, Codex, Gemini, and OpenClaw can
be named as supported only when their isolated receipts stay current and pass
the private-state scan.

## Case-Study Boundary

For v0.2, the public story is the Flywheel-on-Flywheel meta-story: how the
system extracted, renamed, tested, and documented itself for public release.
That story can use operator-side release metrics, such as classification counts,
manual-review queue closure, install smoke results, journey-smoke receipts, and
doctor dispositions.

It must not imply customer consent, name private customers, or describe a
customer in a way that makes the customer identifiable by industry, geography,
timeline, or project shape.

External customer stories are post-v0.2 work unless each story has explicit
per-surface consent for:

- customer name;
- industry and geography;
- screenshots or data shape;
- before/after metrics;
- publication venue;
- date range;
- who can approve future edits or takedowns.

Without that consent, public copy must stay at the method level.

## Consent Matrix

Every public example must land in one of these statuses before release:

| Example class | v0.2 status | Public use |
|---|---|---|
| Flywheel-on-Flywheel release metrics | not-applicable-fully-redacted | Allowed when backed by receipts and stripped of private state. |
| ZestStream operator story | granted | Allowed for public method and contact context. |
| External customer names | activated fallback | Replaced with generic SMB problem shapes until per-surface consent exists. |
| External screenshots or data shapes | activated fallback | Excluded from v0.2; use receipt-level methodology instead. |
| Proof-product repository examples | not-applicable-fully-redacted | Allowed only when the repo itself is intentionally public and no private state is copied. |

Allowed statuses are `granted`, `declined`,
`not-applicable-fully-redacted`, and `activated fallback`. Anything else is a
release blocker.

## Redaction Rules

Public Flywheel copy may include:

- ZestStream as the operator and public service provider;
- Flywheel as the installable engine;
- SkillOS as the capability-control-plane integration point;
- upstream substrate names when attribution is useful;
- reduced-mode and publication metrics backed by receipts;
- proof-product labels when the product itself is intentionally public.

Public Flywheel copy must not include:

- private customer names without per-surface consent;
- private repo names that are not public proof surfaces;
- home-directory paths or pane/session identifiers;
- raw local ledgers, archives, or inbox state;
- screenshots or copied data from private systems;
- claims that a harness lane is supported before a strict
  `flywheel.agent_lane_runtime_receipt.v0` receipt proves the isolated journey
  and private-state scan.

## Journey Links

| Reader | First page | Next proof |
|---|---|---|
| Business owner | `CHARTER.md` | This story page, then the public site. |
| Developer | `README.md` | `docs/getting-started/first-run.md`. |
| Operator | `docs/runbooks/public-release-runbook.md` | Smoke receipts and doctor output. |
| Contributor | `CONTRIBUTING.md` | Registry rows and Beads. |

The story is publishable when it explains the method without borrowing trust
from private customer work.
