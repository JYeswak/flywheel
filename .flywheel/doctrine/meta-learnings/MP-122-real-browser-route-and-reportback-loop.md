# MP-122 - Real browser route and report-back loop

**Discovered:** 2026-05-19T07:56Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Browser work needs a route decision before automation, exact user-facing instructions for blocked surfaces, and screenshot or state evidence after every interaction.

## Where it applies

OAuth, 2FA, CAPTCHA, bot-detection flows, logged-in dashboards, extension-driven browsing, accessibility-first browser automation, UX audits, and local visual QA.

## Adoption signal

The skill distinguishes API or curl work from live browser work, names the browser tool, supplies full URLs and exact element text, asks for report-back when humans must act, and verifies with snapshot or screenshot evidence.

## Exemplar skills (>=5)

- `~/.claude/skills/browser-extension-automation/SKILL.md:12` - real Chrome extension work uses exact paste-ready instructions instead of programmatic automation.
- `~/.claude/skills/browser-extension-automation/SKILL.md:16` - Google OAuth blocks Playwright and Puppeteer flows.
- `~/.claude/skills/browser-extension-automation/SKILL.md:25` - the quick start researches exact steps, gives paste-ready instructions, and waits for reported output.
- `~/.claude/skills/browser-extension-automation/SKILL.md:50` - instructions include full URLs and exact element text.
- `~/.claude/skills/browser-extension-automation/SKILL.md:55` - OAuth, 2FA, CAPTCHA, and bot detection are explicit triggers for the browser route.
- `~/.claude/skills/claude-chrome/SKILL.md:10` - real Chrome works with logged-in sites without reauthentication.
- `~/.claude/skills/dev-browser/SKILL.md:35` - the browser workflow opens, snapshots, interacts, and verifies with a screenshot.
- `~/.claude/skills/dev-browser/SKILL.md:64` - route selection changes for simple, local, unknown, visual, and complex tasks.
- `~/.claude/skills/ux-audit/SKILL.md:86` - accessibility review includes keyboard, contrast, color independence, and screen reader checks.

## Adoption recipes

**Recipe 1 - Route selector:** decide `curl`, local browser, extension-mediated human action, or full automation before touching the page.

**Recipe 2 - Exact instruction packet:** include URL, account/context, visible element labels, expected output, and report-back fields for any human-mediated step.

**Recipe 3 - Evidence closure:** capture accessibility snapshot, screenshot, console/network output, or user-reported result before claiming the browser task is complete.

## Compliance test

```bash
grep -E "(OAuth|2FA|CAPTCHA|bot|Chrome|snapshot|screenshot|exact element|report-back|accessibility)" SKILL.md || exit 1
```
