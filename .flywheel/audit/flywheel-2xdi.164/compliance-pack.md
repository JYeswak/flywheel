---
bead: flywheel-2xdi.164
score: 935/1000
date: 2026-05-11
---

# Compliance Pack — flywheel-2xdi.164

## Score breakdown (935/1000)

| Axis | Score | Notes |
|------|-------|-------|
| Bead scope adherence | 100/100 | 7/7 gates addressed |
| Mission fitness | 90/100 | adjacent — prevents auto-bead noise for entire script class |
| Root-cause fix | 100/100 | classifier extension matches recommended fix #1 (callsite probe) |
| Evidence quality | 95/100 | empirical disproof in sister + re-verification post-fix |
| Regression test | 95/100 | 4-gate test (AG1-AG4) authored + passing |
| Self-exclusion discipline | 100/100 | gap-hunt-probe.sh self-excluded to avoid matchback noise |
| Pattern lineage | 95/100 | docstring cites 2xdi.157 (discovery) + 2xdi.88/98/106/140 (sister corpus extensions) |
| Four-lens self-grade | 93/100 | brand:9 sniff:10 jeff:9 public:9 (avg 9.25) |

`compliance_score=935/1000` — well above 700/1000 threshold.

## CLI canonical: yes
No new CLI surface; classifier internals only. `canonical-cli-scoping=n/a` for top-level CLI but the function follows the existing gap-hunt-probe scaffold pattern.

## Rust clean: n/a

## Python clean: yes (python heredoc inside bash)
- `bash -n` rc=0
- `python3` compile of extracted PY heredoc rc=0
- file-length: gap-hunt-probe.sh stays under canonical-cli scaffold expectations (heredoc-encapsulated python; allowed-large by historical precedent)
- new function follows existing scaffold pattern (cache global + max_bytes param + early-return)

## README quality: n/a

## Skill auto-routes addressed

- `canonical-cli-scoping=n/a` — no top-level CLI added; classifier internal
- `rust-best-practices=n/a`
- `python-best-practices=yes` — type hint preserved (`-> str`); function follows existing scaffold; cache global pattern matches sibling corpora
- `readme-writing=n/a`

## L61 ecosystem-touch

- `agents_md_updated=not_applicable` — classifier internal; no doctrine/L-rule/INCIDENTS edit
- `readme_updated=not_applicable`
