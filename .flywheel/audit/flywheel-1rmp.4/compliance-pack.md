# flywheel-1rmp.4 Compliance Pack

Task: `flywheel-1rmp.4-516800`
Bead: `flywheel-1rmp.4`
Decision: DONE
Compliance score: 880/1000

## VALUE_GAP receipt

```
VALUE_GAP_DIMENSION=customer-facing-observability
measurement=.flywheel/scripts/customer-facing-observability.sh
surfaced=yes
```

## Finding

Same parent epic as flywheel-1rmp.2 (Step 4o value-gap-hunter). This is
the dimension-3 measurement implementation: customer-facing
observability. Internal flywheel health is well-measured per repo;
customer-visible value and risk are not summarized back to the
orchestrator. The probe gives ALPS / TerraTitle / future client repos
a single-pane "what would the client see right now" digest.

Default client roster is `alpsinsurance terratitle`. Blackfoot Telecom
is intentionally absent — that engagement runs on external substrate
(Sonar, etc.), not a flywheel-managed repo. The roster is env-overridable
(`CFO_CLIENT_ROSTER`) so future onboarding (Blackfoot, etc.) is a
config change, not a code edit.

## Repair

Built `.flywheel/scripts/customer-facing-observability.sh` (527 lines,
bash + embedded python3 for JSON aggregation, executable):

- **Producers** (read-only, per client repo):
  - `<repo>/.beads/issues.jsonl` — bead aggregates: open/in_progress/
    closed/blocked counts, ready beads (no open deps), closed-last-7d,
    stale-open beads (older than `--stale-bead-days`, default 14)
  - `<repo>/.flywheel/last_closeout_receipt.json` — last shipped
    close age
  - `<repo>/.flywheel/dispatch-log.jsonl` — recent activity (mtime)
  - `<repo>/INCIDENTS.md` — open trauma surface (## section count)

- **Two signal classes** per client:
  - `value_signals`: bead_counts, closed_last_7d, last_close_age,
    last_closeout_receipt_age, dispatch_log_age, incidents_section_count
  - `risk_signals`: stale_open_beads, no_closes_last_7d,
    blocked_beads, missing_closeout_receipt, stale_dispatch_log_days,
    stale_closeout_receipt_days

- **Self-logs** to
  `~/.local/state/flywheel/customer-facing-observability.jsonl` with
  timestamp + script path on every run, addressing the wired-but-cold
  gap class proactively.

- **Read-only by design**: no bead filing, no dispatch, no source
  mutation. Per Step 4o anti-pattern guardrail: SURFACES per-client
  signals only.

- **Canonical-cli-scoping triad**: doctor / health (repair n/a as
  read-only) + validate / audit / why + --json schema + --client
  filter + --info / --schema / --examples + stable exit codes 0/1/2/3.

## Surface Wire-In

Edited `~/.claude/commands/flywheel/tick.md` Step 4o: added a
"Dimension-3 measurement" subparagraph after the dimension-1
subparagraph from flywheel-1rmp.2. Names the script, the JSONL ledger
path, and the SURFACES-not-DISPATCHES contract verbatim. Default
roster (`alpsinsurance terratitle`) and the Blackfoot exclusion
rationale documented inline.

## Live Measurement Result (proof of value)

Today's first run found two AT-RISK clients out of two:

```
✓ ALPS           (alpsinsurance)  status=RISK
    beads: open=801 ready=546 in_progress=12 blocked=0 closed=939
    last_close: 0d ago (161 closes in last 7d)
    risk: stale_open_beads = 343

✓ TerraTitle     (terratitle)  status=RISK
    beads: open=43 ready=43 in_progress=0 blocked=0 closed=0
    risk: no_closes_last_7d = True
    risk: missing_closeout_receipt = True
```

Two genuinely useful customer-facing signals:

1. **ALPS** is shipping (161 closes in last 7d, last close 0 days ago)
   but carrying a 343-bead stale backlog. That's a healthy-throughput
   client with a hidden debt accumulation — a customer who looks at
   "what shipped this week" sees green but a customer who looks at
   "what's overdue" sees red.

2. **TerraTitle** has 43 ready beads queued but zero closes shipped.
   That's an onboarded-but-not-launched client. The
   `missing_closeout_receipt` signal proves no flywheel close-cycle
   has completed for this client yet — work is queued but the
   close-validation loop is unproven on this engagement.

Neither signal would surface from internal doctor/tick health
probes alone — both clients' substrate is "fine" from the flywheel
perspective. The customer-facing-observability lens is what makes
"healthy throughput hiding stale backlog" and "onboarded without
shipping" both visible.

## Acceptance Gate Map

| # | Gate | Status |
|---|------|--------|
| 1 | Define the smallest recurring measurement that would make this gap visible | ✓ Per-client probe over four canonical sources (.beads/issues.jsonl, .flywheel/last_closeout_receipt.json, .flywheel/dispatch-log.jsonl, INCIDENTS.md). Two signal classes (value/risk) with concrete fields each. |
| 2 | Wire the result into a tick receipt, doctor signal, dashboard, or explicit no-surface reason | ✓ tick.md Step 4o "Dimension-3 measurement" subparagraph + JSONL ledger at `~/.local/state/flywheel/customer-facing-observability.jsonl`. |
| 3 | Preserve Step 4o anti-pattern guardrails: do not dispatch directly from this finding | ✓ Read-only by design — explicit comment block at script header, "Read-only by design" section in compliance pack, "SURFACES per-client signals only" in tick.md wire-in. |

did=3/3

## Evidence

```text
$ bash -n .flywheel/scripts/customer-facing-observability.sh
(no output = OK)

$ .flywheel/scripts/customer-facing-observability.sh --doctor
doctor: overall=healthy clients=2/2

$ .flywheel/scripts/customer-facing-observability.sh --validate
{"schema_version":"...v1","mode":"validate","status":"ok","missing":[]}

$ .flywheel/scripts/customer-facing-observability.sh --json | jq '.summary'
{"clients_total":2,"clients_available":2,"clients_at_risk":2}

$ .flywheel/scripts/customer-facing-observability.sh --why=terratitle --json | jq '.risk_signals'
{"no_closes_last_7d":true,"missing_closeout_receipt":true}

$ tail -1 ~/.local/state/flywheel/customer-facing-observability.jsonl | jq '.script'
"/Users/josh/Developer/flywheel/.flywheel/scripts/customer-facing-observability.sh"

$ grep -c "customer-facing-observability" /Users/josh/.claude/commands/flywheel/tick.md
3
```

## Scope

- Edits: 3 files
  - `.flywheel/scripts/customer-facing-observability.sh` (new, 527 lines)
  - `~/.claude/commands/flywheel/tick.md` (Step 4o "Dimension-3" subparagraph)
  - `.flywheel/audit/flywheel-1rmp.4/compliance-pack.md` (this file)
- Files reserved/released: harvester script + tick.md
- Out of scope: the other 8 value-gap dimensions; auto-dispatch on
  risk_signals (forbidden by anti-pattern guardrail); Blackfoot
  Telecom probe (different substrate — Sonar, not flywheel repo)

## L52 / L80 / L120 / L61

- DIDNT: none (3/3 gates satisfied)
- GAPS: none new
- beads_filed: none (per anti-pattern guardrail)
- beads_updated: none
- no_bead_reason: anti-pattern-guardrail-forbids-direct-dispatch
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: not_applicable

## Four Lens

- Brand: 9 (Step 4o anti-pattern guardrail respected at three layers
  matching the flywheel-1rmp.2 precedent: script header, compliance
  pack section, tick.md wire-in. Naming convention follows the
  dimension's id verbatim.)
- Sniff: 9 (full canonical-cli-scoping triad smoke-tested; live test
  surfaces materially useful signals on both clients — neither would
  be visible from internal doctor probes alone)
- Jeff: 7 (no Jeff-substrate touch; pure customer-facing measurement)
- Public: 9 (a future operator can grep "customer-facing-observability"
  in tick.md, run the script with `--why=<client>` for any client
  detail, and consume the JSONL ledger for trend analysis. Roster
  env-overridable via `CFO_CLIENT_ROSTER`.)

## Skill Auto-Routes

- canonical-cli-scoping: addressed=yes (full triad shipped: doctor/
  health + validate/audit/why + --json schema + stable exit codes;
  repair n/a — read-only)
- rust-best-practices: n/a — no Rust
- python-best-practices: n/a — Python is embedded heredoc helper
  inside bash; no standalone Python module
- readme-writing: n/a — tick.md wire-in is documentation in a
  slash-command spec, not a README

## L112 Probe

```
.flywheel/scripts/customer-facing-observability.sh --validate --json | jq -e '.status=="ok"'
```
Expected: `jq:.status=="ok"` returns `true`.
