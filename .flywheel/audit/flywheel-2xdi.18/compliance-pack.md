# flywheel-2xdi.18 Compliance Pack

Task: `flywheel-2xdi.18-81aca4`
Bead: `flywheel-2xdi.18`
Decision: DONE (no-edit close — gap no longer reproduces; bead is stale)
Compliance score: 830/1000

## Finding

The bead was auto-filed by `gap-hunt-probe.sh` against the
`doctrine-without-measurement` class with evidence "AGENTS.md mentions L11 but
tick.md has no matching observability hook".

Replaying the exact probe regex
(`re.finditer(r"\b(L\d+|Axiom\s+\d+)\b", text)`) over current AGENTS.md and
`~/.claude/CLAUDE.md` finds **zero** standalone `L11` mentions. Word-boundary
`\b` excludes substrings inside `L100`, `L110`, `L11x`, etc. — those are
different rule numbers.

Today's probe run lists `doctrine-without-measurement` rules surfaced as:
`l001, l002, l003, l004, l005, l006, l007, l008, l009, l010, l011, l29, l35, l48, l50, l51, l52, l53, l54, l55`.
`l11` (no leading zero) is **not** present; `l011` is a sibling rule pointing
at `.flywheel/rules/L011-L57-loop-state-marker-not-driver.md` (file-prefix
sequence number 011, canonical rule L57). That is a different bead concern
already separately handled by sibling beads under `flywheel-2xdi`.

## Evidence

```text
$ python3 -c "import re; t=open('/Users/josh/Developer/flywheel/AGENTS.md').read();
  print(len([m for m in re.finditer(r'\\b(L\\d+|Axiom\\s+\\d+)\\b', t)
             if m.group(1).lower()=='l11']))"
0

$ grep -nE '\\bL11\\b' /Users/josh/Developer/flywheel/AGENTS.md
(no output)

$ bash .flywheel/scripts/gap-hunt-probe.sh | python3 -c "import json,sys;
  d=json.load(sys.stdin);
  print(sorted(set(g.split(':')[1] for g in d.get('gap_ids',[])
                    if 'doctrine-without-measurement' in g)))"
['l001','l002','l003','l004','l005','l006','l007','l008','l009','l010','l011',
 'l29','l35','l48','l50','l51','l52','l53','l54','l55']
```

## Why The Bead Is Stale

AGENTS.md historically referenced Axiom 11 / "L11 Live API Truth" as a sibling
rule (and `.flywheel/rules/L017-L63-...md` and `.flywheel/rules/L018-L64-...md`
still mention `L11` in cross-reference text). Between the bead's filing
(2026-05-03) and today, the AGENTS.md root was edited to drop the standalone
`L11` reference; the regex no longer fires.

## Repair

None — no file edits performed. The original gap evidence cannot be reproduced
by the probe; closing as stale matches the same disposition used for
flywheel-2xdi.17 (L62 stale).

## Scope

- Edits: none
- Files reserved: NONE_NO_EDITS
- Out of scope: any speculative add of `L11` text to tick.md to satisfy a
  regex when AGENTS.md no longer demands it; that would be doctrine-by-
  cargo-cult, not measurement.

## L52 / L80 / L120

- DIDNT: none (1/1 acceptance criterion satisfied — probe no longer fires)
- GAPS: none new
- beads_filed: none
- beads_updated: none
- no_bead_reason: stale-auto-filed-bead-original-evidence-not-reproducible
- br_close_executed: yes (after this pack is committed, before callback)

## Four Lens

- Brand: 7 (closing stale beads is canonical flywheel motion)
- Sniff: 9 (regex replay + probe re-run + dwm-rule list captured as evidence)
- Jeff: 7 (no Jeff-substrate touch)
- Public: 7 (any operator can replay the regex and confirm)

## Skill Auto-Routes

- canonical-cli-scoping: n/a — no CLI changes
- rust-best-practices: n/a — no Rust touched
- python-best-practices: n/a — replay command is a one-liner, not a module
- readme-writing: n/a — no README

## L112 Probe

```
python3 -c "import re; t=open('/Users/josh/Developer/flywheel/AGENTS.md').read(); print(sum(1 for m in re.finditer(r'\\b(L\\d+|Axiom\\s+\\d+)\\b', t) if m.group(1).lower()=='l11'))"
```
Expected: `literal:0` (zero standalone L11 mentions in AGENTS.md proves the
gap evidence cannot reproduce).
