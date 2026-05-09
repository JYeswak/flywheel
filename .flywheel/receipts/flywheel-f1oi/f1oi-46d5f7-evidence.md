# flywheel-f1oi-46d5f7 Evidence

## Scope

- Bead: `flywheel-f1oi`
- Task: update canonical doctrine capture examples from legacy `ntm copy` wording to robot-mode `--robot-tail`.
- Files changed:
  - `.flywheel/rules/L002-L29-ntm-only-doctrine.md`
  - `.flywheel/rules/L012-L58-secret-material-never-in-pane-text.md`
  - `.flywheel/rules/MANIFEST.json`

## Acceptance Evidence

Commands:

```bash
rg -n 'Capture pane|ntm copy|robot-tail' .flywheel/rules/L002-L29-ntm-only-doctrine.md .flywheel/rules/L012-L58-secret-material-never-in-pane-text.md
shasum -a 256 .flywheel/rules/L002-L29-ntm-only-doctrine.md .flywheel/rules/L012-L58-secret-material-never-in-pane-text.md
jq -e '.rules[] | select(.id == "L29").sha256 == "decf9a0696ded08fa80d456f6ca7617fd76aa73d8e1af533392510c9c9516ac2"' .flywheel/rules/MANIFEST.json
jq -e '.rules[] | select(.id == "L58").sha256 == "bbbf8e205024c4c42712bcd80f2f3b7d52e3ad74616a30876461190efe77a358"' .flywheel/rules/MANIFEST.json
.flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-f1oi-46d5f7.md
```

Results:

- L29 now uses `ntm --robot-tail=<session> --panes=<pane> --lines=<N> --json` as the doctrine capture example.
- L29 preserves `ntm copy <session>:<pane> -l <N>` only as legacy-compatible manual transcript inspection.
- L58 now requires robot-tail plus redaction for new pane evidence and clarifies historical raw transcript citations are pre-fix evidence only.
- Manifest hashes updated for L29 and L58.

## Socraticode

- Query count: 1
- Query: `AGENTS-CANONICAL L29 Capture pane ntm copy robot-tail L60 token echo incident raw ntm copy evidence collection canonical doctrine`
- Relevant hits: L29 shard, L58 shard, robot-tail usage in tests/incidents.

## L52 Receipt

- New beads filed: none
- Beads updated: none
- No-bead reason: no new gap found; repo-wide doctrine sync to installed copies is intentionally outside this capped migration pass per bead text.

## L61 / Doctrine Touch

- `AGENTS.md` updated: no
- `README.md` updated: no
- Reason: canonical rule bodies are sharded under `.flywheel/rules/`; `AGENTS.md` and `.flywheel/AGENTS-CANONICAL.md` contain the unchanged shard index, not the affected rule body text. Multi-repo propagation rides the existing doctrine-sync path.

## Skill Routes

- `canonical-cli-scoping=yes`: doctrine now names the robot JSON surface for pane capture.
- `readme-writing=yes`: evidence is scannable and source-grounded; README was not in scope.
- `python-best-practices=n/a`: no Python touched.
- `rust-best-practices=n/a`: no Rust touched.

## Compliance Pack

- Score: `910/1000`
- CLI canonical: yes
- Python clean: n/a
- Rust clean: n/a
- README quality: yes
- Evidence redacted: n/a
- Artifact checks:
  - `.flywheel/rules/L002-L29-ntm-only-doctrine.md:exists`
  - `.flywheel/rules/L012-L58-secret-material-never-in-pane-text.md:exists`
  - `.flywheel/rules/MANIFEST.json:exists`

## Four-Lens Self-Grade

- brand: 9
- sniff: 9
- jeff: 9
- public: 9

Three Judges check: a skeptical operator sees the current robot-mode command, a maintainer sees legacy evidence preserved without endorsing it, and a future worker has exact hash/grep probes.

## L112 Probe

```bash
rg -q -- '--robot-tail=<session> --panes=<pane> --lines=<N> --json' .flywheel/rules/L002-L29-ntm-only-doctrine.md
```

Expected: `literal:exit0`
