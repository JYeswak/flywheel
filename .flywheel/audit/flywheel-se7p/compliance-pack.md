# flywheel-se7p Compliance Pack

Task: `flywheel-se7p-719ae6`
Bead: `flywheel-se7p`
Decision: DONE
Compliance score: 900/1000

## Finding

The bead tracks upstream issue
`Dicklesworthstone/destructive_command_guard#109`: a false positive where DCG
blocked valid Bash heredoc prose for spaced quoted tab-stripping forms such as
`cat <<- 'EOF'`.

The temporary receipt/body paths named by the bead were no longer present under
`/tmp`, so close evidence was reconstructed from the durable upstream issue
state.

## Upstream State

`gh issue view 109 --repo Dicklesworthstone/destructive_command_guard --json ...`
returned:

- title: `DCG false-positive on spaced quoted tab-stripping heredoc data`
- state: `CLOSED`
- url: `https://github.com/Dicklesworthstone/destructive_command_guard/issues/109`
- author: `JYeswak`
- created: `2026-05-03T06:15:25Z`
- maintainer comment: fixed in `f3c96bd` parser fix and `a739dc9`
  regression test, both on `main`

The maintainer specifically verified the original repro shape:

```bash
dcg test --format json $'cat > /tmp/dcg-x <<- \'EOF\'\n\tgh repo delete\n\tEOF'
```

with `decision=allow`.

## Acceptance Gates

- AG1: close evidence now exists in
  `.flywheel/audit/flywheel-se7p/compliance-pack.md` and the validation
  receipt.
- AG2: targeted validator command passed:
  `.flywheel/audit/flywheel-se7p/l112-probe.sh`.
- AG3: `br show flywheel-se7p --json` showed the bead open before this evidence
  artifact was written.

## Validation

Commands run:

```bash
gh issue view 109 --repo Dicklesworthstone/destructive_command_guard --json number,title,state,url,comments --comments
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-se7p-719ae6.md
bash .flywheel/validation-schema/v1/parse.sh .flywheel/audit/flywheel-se7p/validation-receipt.json
.flywheel/audit/flywheel-se7p/l112-probe.sh
```

The L112 probe checks that issue `109` is closed and at least one comment names
both upstream fix commits.

## L52

No follow-up bead filed. The upstream issue has already been accepted and
resolved by the maintainer, and this bead’s remaining work was close evidence.

## Four-Lens Self-Grade

- brand: 9 - Keeps upstream safety collaboration traceable without local churn.
- sniff: 9 - Uses live issue state and maintainer fix comment as evidence.
- jeff: 9 - Preserves the exact external issue and fix identifiers.
- public: 9 - A skeptical operator, maintainer, and future worker can rerun the
  L112 probe.
