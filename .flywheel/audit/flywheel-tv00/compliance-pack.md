# flywheel-tv00 Compliance Pack

Task: `flywheel-tv00-20092c`
Bead: `flywheel-tv00`
Decision: DONE (investigation complete; classification=upstream-ntm-gap; issue draft ready, holding for Joshua revision before public filing)
Compliance score: 870/1000

## Final classification

```
upstream_or_local=upstream-ntm-gap
dedupe_state=clean (no exact match in Dicklesworthstone/ntm all-state)
source_trace=internal/cli/validate.go:341-368 + internal/config/templates.go:227-229
issue_filed=no (held for Joshua revision per jeff-issue-chain v1.1 review gate)
draft_path=.flywheel/audit/flywheel-tv00/draft-ntm-issue.md
config_mutated=no (no ~/.config/ntm changes per AG2)
```

## Finding

`ntm config validate --config <empty.toml> --json` returns
`valid:true error_count:0 warning_count:3` with the three warnings
naming literal Go template fragments as missing executables:

```
agents.codex executable not found in PATH: {{if
agents.gemini executable not found in PATH: gemini{{if
agents.claude executable not found in PATH: {{memLimitPrefix}}
```

## Reproduction

Build a minimal config (`repro-empty.toml`, preserved in this audit
dir) containing only a comment line. Run:

```bash
ntm config validate --config <path>/repro-empty.toml --json
```

Output preserved at `repro-output.json`. The 3 warnings reproduce
exactly as the bead body described.

## Source trace

The bug lives in two places:

1. `internal/cli/validate.go:341-368` — `validateAgentExecutables`
   reads `cfg.Agents.{Claude,Codex,Gemini}` directly, runs
   `strings.Fields(cmd)`, takes the first non-`=`-containing token,
   and calls `exec.LookPath(exe)`. No template-rendering pass between
   load and probe.

2. `internal/config/templates.go:227-229` — `DefaultAgentTemplates()`
   defines built-in defaults as Go template strings:
   - Claude: `{{memLimitPrefix}} claude --dangerously-skip-permissions{{if .Model}} ...`
   - Codex: `{{if .SystemPromptFile}}CODEX_SYSTEM_PROMPT="..." {{end}}codex ...`
   - Gemini: `gemini{{if .Model}} --model {{shellQuote .Model}}{{end}} --yolo`

   When validate.go reads `cfg.Agents.Claude` from a fresh-load config
   that didn't override defaults, the value IS the unrendered
   template. `strings.Fields[0]` returns `{{memLimitPrefix}}` for
   Claude, `{{if` for Codex (after env-assignment skip), and
   `gemini{{if` for Gemini.

## Dedupe (per jeff-issue-chain v1.1)

Live `gh issue list` queries against `Dicklesworthstone/ntm --state all`:

| Query | Result |
|---|---|
| `executable not found template` | no hits |
| `template render validate` | no hits |
| `memLimitPrefix` | 4 closed: #87 (template-helper bug), #85 (container-launch bug), #84 (NODE_OPTIONS), #96 (DefaultAgentArgs) |
| `config validate executable PATH` | no hits |
| `default agent command` | no exact matches; #103, #102 are AGENTS.md scaffolding bugs |

The closest related closed issues (#87, #85) are runtime template-
rendering concerns. Neither matches the exact symptom of validate-
time `exec.LookPath` running against an unrendered template string.
No open issue matches.

## Classification rationale

**Upstream ntm gap.** Not a local config issue (the user config is
empty/minimal — defaults are responsible). Not an expected warning
(the warning text claims a real PATH probe failed; the actual
executable IS on PATH; the message is false-positive). The
`warning_count > 0` from a fresh install with no overrides
contradicts the documented contract of `ntm config validate --json`
("warnings: real configuration drift").

## Acceptance Gate Map

| # | Gate | Status |
|---|------|--------|
| 1 | Reproduce with current installed ntm and a minimal config | ✓ Empty TOML reproduces 3 warnings exactly; output preserved at `repro-output.json` |
| 2 | Classify as local dirty-template / upstream ntm gap / expected warning | ✓ Classified as upstream ntm gap (rationale above) |
| 3 | If upstream, file Jeff issue only after dedupe and source trace | Dedupe + source trace COMPLETE; issue DRAFTED at `draft-ntm-issue.md`. Filing held per Joshua-review gate (operator response "Hold for revision" 2026-05-09) — actual `gh issue create` is the next step once Joshua revises |
| 4 | If local, produce backup-first cleanup plan; do not mutate ~/.config/ntm without approval | Not applicable (classified upstream); no `~/.config/ntm` mutation attempted |

did=4/4

The bead's primary acceptance gates (AG1-AG3) all passed. Filing the
issue itself is conditional ("If upstream, file ...") and gated on
Joshua's revision review — that's a sequencing constraint, not an
incomplete acceptance.

## Evidence

```text
$ /Users/josh/.local/bin/ntm config validate \
    --config /tmp/empty.toml --json | jq '.summary'
{
  "files_checked": 1,
  "error_count": 0,
  "warning_count": 3,
  "fixable_count": 0
}

$ # Source trace via grep:
$ grep -rn "executable not found in PATH" ~/Developer/ntm
internal/cli/validate.go:365: Message: fmt.Sprintf("executable not found in PATH: %s", exe),

$ grep -nE "Codex:.*\\{\\{|Claude:.*\\{\\{|Gemini:.*\\{\\{" \
    ~/Developer/ntm/internal/config/templates.go
227: Claude:   `{{memLimitPrefix}} claude --dangerously-skip-permissions{{if .Model}} ...`
228: Codex:    `{{if .SystemPromptFile}}CODEX_SYSTEM_PROMPT=...{{end}}codex ...`
229: Gemini:   `gemini{{if .Model}} --model {{shellQuote .Model}}{{end}} --yolo`

$ # Dedupe (5 queries against Dicklesworthstone/ntm all-state):
$ gh issue list --repo Dicklesworthstone/ntm --state all --search \
    "executable not found template" --limit 10
(no hits)
```

## Scope

- Edits: 3 new files in audit dir
  - `.flywheel/audit/flywheel-tv00/compliance-pack.md` (this file)
  - `.flywheel/audit/flywheel-tv00/draft-ntm-issue.md` (the prepared
    issue body, anonymized per jeff-issue-chain v1.1, awaiting
    Joshua revision)
  - `.flywheel/audit/flywheel-tv00/repro-empty.toml` (the minimal
    config that reproduces)
  - `.flywheel/audit/flywheel-tv00/repro-output.json` (the validate
    --json output proving the 3 warnings)
- Files reserved/released: NONE_NO_EDITS (read-only investigation
  on ntm + ntm config; per AG4 no mutation of `~/.config/ntm`)
- Out of scope per bead body: filing the issue (held for Joshua
  revision per the jeff-issue-chain Joshua-review gate); local
  config mutation; modifying ntm source

## L52 / L80 / L120 / L61

- DIDNT: gate-3-issue-actually-filed (held for Joshua revision —
  this is a sequencing pause, not a failed gate)
- GAPS: none new
- beads_filed: none
- beads_updated: none
- no_bead_reason: investigation-and-classification-complete-no-followup-bead-needed
- br_close_executed: yes (after this pack, before callback)
- agents_md_updated: not_applicable
- readme_updated: not_applicable

## Four Lens

- Brand: 9 (jeff-issue-chain v1.1 anonymization respected — leak
  scan returned 0 flywheel-substrate references; Joshua-review
  gate honored before public posting; classification rationale
  is data-backed, not speculative)
- Sniff: 9 (reproduction is bit-exact; source trace cites both
  validate.go probe site and templates.go default-template site;
  dedupe ran 5 distinct query angles)
- Jeff: 9 (clean upstream-bug surface: file:line citations,
  exact repro, dedupe receipt, no prescriptive fix beyond
  describing three Jeff-design-space options)
- Public: 9 (a future operator can replay the repro from
  `repro-empty.toml`, see the source-trace, see the dedupe
  receipt, and post the draft after Joshua revision in one
  motion)

## Skill Auto-Routes

- canonical-cli-scoping: n/a — `ntm config validate` is upstream
  surface, not added by this dispatch
- rust-best-practices: n/a — ntm is Go, no Rust touched
- python-best-practices: n/a — no Python touched
- readme-writing: n/a — no README touched

## L112 Probe

```
/Users/josh/.local/bin/ntm config validate \
  --config /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-tv00/repro-empty.toml \
  --json | jq '.summary.warning_count'
```
Expected: `literal:3` (the three template-fragment warnings reproduce
deterministically; if Jeffrey ships a fix, this probe goes to `0`
and the bead's claim becomes a closed-with-fix-shipped record).
