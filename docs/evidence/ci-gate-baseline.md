# CI gate baseline

The flywheel `Contract tests` CI step runs 30 bash test files. This file
names each gate, what it enforces in one line, and the last commit where
the gate was confirmed green on `review/flywheel-2.0-private-20260513`.
Authored 2026-05-15 per the accretive watch goal's "CI baseline tracked"
target.

Source of truth: `.github/workflows/ci.yml` (`Contract tests` step).
Last branch-green at authoring: `d3d2d616`. Last confirmed green:
`62264037` (predates the install-contract addition + automation drift on
`publication-goal-completion-audit.sh`).

## Contract tests (in CI order)

| # | Test | What it gates |
|---|------|---------------|
| 1 | `public-top-level-files.sh` | Required top-level public docs exist (README, LICENSE, CHARTER, CHANGELOG, CONTRIBUTING, SECURITY, SUPPORT, CODE_OF_CONDUCT, ARCHITECTURE, MISSION, GOAL, STATE) + depersonalization-table scan on each |
| 2 | `public-surface-gap-scanner.sh` | Public docs/site free of undispositioned TODO/FIXME/blocker/gap markers; `flywheel.public_surface_gap_scan.v0` |
| 3 | `changelog.sh` | CHANGELOG has v0.2.0 section + required structure |
| 4 | `github-workflows.sh` | Workflow YAMLs match contract (action hashes, job shape, concurrency, permissions) |
| 5 | `naming-conventions.sh` | Public surfaces reject private lowercase fleet slugs + stale operator markers + superseded product names (`rg --case-sensitive`) — no allowlist mechanism |
| 5a | `hosted-install-contract.sh` | Hosted installer contract — `install.sh` + `install.sh.sha256` parity from the release asset set (added by `821b4e95 fix(install): prove hosted installer contract`) |
| 6 | `context-routing-discipline.sh` | Context/model routing rules (grep-before-fetch, batched tool calls, SKILL.md graduation, etc.) |
| 7 | `agent-lane-probe.sh` | Agent-lane support matrix (Claude/Codex/Gemini/OpenClaw) receipt truth |
| 8 | `public-docs.sh` | Public docs internal contract — required surfaces present, no private references |
| 9 | `public-links.sh` | All public doc + site links resolve (no 404s) |
| 10 | `website-static.sh` | Static site shape contract (149 pass) — required literal copy strings present per page |
| 11 | `website-accessibility.sh` | Site WCAG/a11y checks (aria-label presence, etc.) |
| 12 | `live-site-probe.sh` | `flywheel.zeststream.ai` live probe — 17 endpoint passes, deploy-manifest hash matches |
| 13 | `contact-routing.sh` | Contact mailto + route probe correctness |
| 14 | `upstream-substrate-adoption.sh` | Asupersync (and future upstream) adoption gated on live evidence |
| 15 | `release-assets.sh` | Release tarball + SHA256SUMS shape |
| 16 | `cutover-receipts.sh` | Cutover receipt schema validation |
| 17 | `external-review-gate.sh` | External review log valid + at least 2 current reviewer rows |
| 18 | `public-user-journey-pack.sh` | User-journey pack validator — `flywheel.public_user_journey_pack.v0`, 20 rows, zero errors |
| 19 | `repo-story-portability.sh` | Cross-repo `extract_git_story.py` payload portability (Flywheel + ClutterFreeSpaces + Mobile Eats) |
| 20 | `repo-owner-brief.sh` | `render_repo_owner_brief.py` payload contract `zeststream.repo_owner_story_brief.v0` |
| 21 | `story-system-package.sh` | `packages/zeststream-story-system` package contract — 26 pass |
| 22 | `zeststream-ui-package.sh` | `packages/zeststream-ui` package contract — 23 pass |
| 23 | `zeststream-motion-package.sh` | `packages/zeststream-motion` package contract — 20 pass |
| 24 | `publication-goal-completion-audit.sh` | Publication goal audit against `MISSION.md` |
| 25 | `publication-readiness.sh` | The authoritative cutover gate — `publication_readiness.py` schema + 72-row contract |
| 26 | `true-publication-registry-validate.sh` | Publication registry schema validator |
| 27 | `preflight-fixtures.sh` | `scripts/preflight.sh --json` fixture contracts — 19 pass |
| 28 | `journey-smoke.sh` | Reduced-mode journey smoke — 7 pass |
| 29 | `presence-queue.sh` | Presence pipeline `scripts/presence_queue.py` — 7 pass; hermetic voice.yaml fixture |

## Other CI steps

- **Shell lint** — `shellcheck` over 31 named shell files (install/uninstall/scripts/tests).
- **Python syntax lint** — `ruff check --select E9,F63,F7,F82` over 18 named Python scripts.
- **Markdown lint** — `markdownlint` over the top-level docs + `docs/runbooks/*` + `docs/stories/*` + `docs/concepts/*` + `docs/reference/*` + `packages/zeststream-*/README.md` + `docs/evidence/publication-evidence.md` + `docs/evidence/publication-goal-completion-audit.md`.

## Notes

- `naming-conventions.sh:160` has **no allowlist mechanism** — by design, the
  fleet-slug rejection is absolute. See doctrine:
  `.flywheel/doctrine/public-repo-naming-vs-fleet-slugs.md`.
- The `Installer Smoke` job is a separate workflow that runs in parallel
  with `Contract tests`. Both must be green for the branch to be green.
- The `cancel-in-progress: true` concurrency setting means newer commits
  cancel older in-flight CI runs — `cancelled` rows in `gh run list` are
  expected, not failures.
- This baseline is updated when (a) a new test is added to ci.yml or (b)
  the last-green commit transitions, per the accretive-watch regime.
