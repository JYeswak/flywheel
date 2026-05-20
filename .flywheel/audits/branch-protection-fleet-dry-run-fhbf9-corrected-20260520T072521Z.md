# Branch Protection Fleet Dry-Run — 2026-05-20

Mode: `dry-run`
Outcome: `dry-run`

No GitHub branch-protection settings were mutated by this report when mode is `dry-run`.

| Repo | Outcome | Required checks | Review gate | enforce_admins | allow_force_pushes | allow_deletions |
|---|---|---|---|---|---|---|
| JYeswak/flywheel | `dry-run` | Public Surface, Install Doctor Uninstall (ubuntu-22.04), Install Doctor Uninstall (macos-14) | `null` | `false` | `false` | `false` |
| JYeswak/skillos | `dry-run` | Public Readiness | `null` | `false` | `false` | `false` |
| JYeswak/zesttube | `dry-run` | Studio Visual Journey | `null` | `false` | `false` | `false` |
| JYeswak/mobile-eats | `dry-run` | secrets-scan, journey-contract, journeys | `null` | `false` | `false` | `false` |
| JYeswak/ClutterFreeSpaces | `dry-run` | Re-run audit three-source checks, App Store submission readiness, Root Jest baseline, App Vitest, Playwright surface tests, Playwright customer journey, Brand token lint, CFS console next build, CFS TDD aggregate, Canonical CLI gate, Local pre-GitHub gate | `null` | `false` | `false` | `false` |

## Excluded

- `JYeswak/polymarket-pico-z` (picoz): permissions issue tracked by flywheel-02oow

## Raw Envelope

```json
{
  "excluded": [
    {
      "alias": "picoz",
      "reason": "permissions issue tracked by flywheel-02oow",
      "repo": "JYeswak/polymarket-pico-z"
    }
  ],
  "mode": "dry-run",
  "outcome": "dry-run",
  "repos": 5,
  "results": [
    {
      "alias": "flywheel",
      "before": {},
      "branch": "main",
      "desired": {
        "allow_deletions": false,
        "allow_force_pushes": false,
        "enforce_admins": false,
        "required_linear_history": true,
        "required_pull_request_reviews": null,
        "required_status_checks": {
          "contexts": [
            "Public Surface",
            "Install Doctor Uninstall (ubuntu-22.04)",
            "Install Doctor Uninstall (macos-14)"
          ],
          "strict": true
        },
        "restrictions": null
      },
      "diff": "--- /dev/fd/63\t2026-05-20 01:25:25\n+++ /dev/fd/62\t2026-05-20 01:25:25\n@@ -1 +1,16 @@\n-{}\n+{\n+  \"allow_deletions\": false,\n+  \"allow_force_pushes\": false,\n+  \"enforce_admins\": false,\n+  \"required_linear_history\": true,\n+  \"required_pull_request_reviews\": null,\n+  \"required_status_checks\": {\n+    \"contexts\": [\n+      \"Public Surface\",\n+      \"Install Doctor Uninstall (ubuntu-22.04)\",\n+      \"Install Doctor Uninstall (macos-14)\"\n+    ],\n+    \"strict\": true\n+  },\n+  \"restrictions\": null\n+}",
      "discovery_decision": "workflow_yml_pr_trigger_filtered_recent_runs_metadata_only",
      "discovery_details": [
        {
          "check": "Public Surface",
          "included": true,
          "job": "public-surface",
          "matrix": null,
          "trigger_reason": "included:pull_request_all_branches",
          "workflow": "ci.yml"
        },
        {
          "check": "Install Doctor Uninstall (ubuntu-22.04)",
          "included": true,
          "job": "install-doctor-uninstall",
          "matrix": {
            "os": "ubuntu-22.04"
          },
          "trigger_reason": "included:pull_request_all_branches",
          "workflow": "installer-smoke.yml"
        },
        {
          "check": "Install Doctor Uninstall (macos-14)",
          "included": true,
          "job": "install-doctor-uninstall",
          "matrix": {
            "os": "macos-14"
          },
          "trigger_reason": "included:pull_request_all_branches",
          "workflow": "installer-smoke.yml"
        },
        {
          "check": "Package Release",
          "included": false,
          "job": "package",
          "matrix": null,
          "trigger_reason": "excluded:no_pull_request_trigger",
          "workflow": "release.yml"
        },
        {
          "check": "Deploy Static Site",
          "included": false,
          "job": "deploy",
          "matrix": null,
          "trigger_reason": "excluded:no_pull_request_trigger",
          "workflow": "site.yml"
        },
        {
          "check": "Fresh-clone preflight + journey-smoke (public path)",
          "included": false,
          "job": "fresh-clone-parity",
          "matrix": null,
          "trigger_reason": "excluded:no_pull_request_trigger",
          "workflow": "v5-w8-public-surface-parity-daily.yml"
        }
      ],
      "discovery_source": "workflow_yml",
      "mode": "dry-run",
      "outcome": "dry-run",
      "override_checks": null,
      "recent_run_names": [
        "CI",
        "Installer Smoke",
        "v5-w8-public-surface-parity-daily"
      ],
      "repo": "JYeswak/flywheel",
      "repo_path": "/Users/josh/Developer/flywheel",
      "repo_view": {
        "defaultBranchRef": {
          "name": "master"
        },
        "nameWithOwner": "JYeswak/flywheel"
      },
      "required_checks": [
        "Public Surface",
        "Install Doctor Uninstall (ubuntu-22.04)",
        "Install Doctor Uninstall (macos-14)"
      ],
      "schema_version": "branch_protection_apply.v1",
      "ts": "2026-05-20T07:25:25Z",
      "workflow_yml_checks": [
        "Public Surface",
        "Install Doctor Uninstall (ubuntu-22.04)",
        "Install Doctor Uninstall (macos-14)"
      ]
    },
    {
      "alias": "skillos",
      "before": {},
      "branch": "main",
      "desired": {
        "allow_deletions": false,
        "allow_force_pushes": false,
        "enforce_admins": false,
        "required_linear_history": true,
        "required_pull_request_reviews": null,
        "required_status_checks": {
          "contexts": [
            "Public Readiness"
          ],
          "strict": true
        },
        "restrictions": null
      },
      "diff": "--- /dev/fd/63\t2026-05-20 01:25:27\n+++ /dev/fd/62\t2026-05-20 01:25:27\n@@ -1 +1,14 @@\n-{}\n+{\n+  \"allow_deletions\": false,\n+  \"allow_force_pushes\": false,\n+  \"enforce_admins\": false,\n+  \"required_linear_history\": true,\n+  \"required_pull_request_reviews\": null,\n+  \"required_status_checks\": {\n+    \"contexts\": [\n+      \"Public Readiness\"\n+    ],\n+    \"strict\": true\n+  },\n+  \"restrictions\": null\n+}",
      "discovery_decision": "workflow_yml_pr_trigger_filtered_recent_runs_metadata_only",
      "discovery_details": [
        {
          "check": "Public Readiness",
          "included": true,
          "job": "public-readiness",
          "matrix": null,
          "trigger_reason": "included:pull_request_all_branches",
          "workflow": "ci.yml"
        }
      ],
      "discovery_source": "workflow_yml",
      "mode": "dry-run",
      "outcome": "dry-run",
      "override_checks": null,
      "recent_run_names": [
        "CI"
      ],
      "repo": "JYeswak/skillos",
      "repo_path": "/Users/josh/Developer/skillos",
      "repo_view": {
        "defaultBranchRef": {
          "name": "main"
        },
        "nameWithOwner": "JYeswak/SkillOS"
      },
      "required_checks": [
        "Public Readiness"
      ],
      "schema_version": "branch_protection_apply.v1",
      "ts": "2026-05-20T07:25:27Z",
      "workflow_yml_checks": [
        "Public Readiness"
      ]
    },
    {
      "alias": "zesttube",
      "before": {},
      "branch": "main",
      "desired": {
        "allow_deletions": false,
        "allow_force_pushes": false,
        "enforce_admins": false,
        "required_linear_history": true,
        "required_pull_request_reviews": null,
        "required_status_checks": {
          "contexts": [
            "Studio Visual Journey"
          ],
          "strict": true
        },
        "restrictions": null
      },
      "diff": "--- /dev/fd/63\t2026-05-20 01:25:32\n+++ /dev/fd/62\t2026-05-20 01:25:32\n@@ -1 +1,14 @@\n-{}\n+{\n+  \"allow_deletions\": false,\n+  \"allow_force_pushes\": false,\n+  \"enforce_admins\": false,\n+  \"required_linear_history\": true,\n+  \"required_pull_request_reviews\": null,\n+  \"required_status_checks\": {\n+    \"contexts\": [\n+      \"Studio Visual Journey\"\n+    ],\n+    \"strict\": true\n+  },\n+  \"restrictions\": null\n+}",
      "discovery_decision": "recent_runs_only",
      "discovery_details": [
        {
          "check": "Studio Visual Journey",
          "included": true,
          "job": null,
          "matrix": null,
          "trigger_reason": "included:recent_runs_only",
          "workflow": null
        }
      ],
      "discovery_source": "recent_runs",
      "mode": "dry-run",
      "outcome": "dry-run",
      "override_checks": null,
      "recent_run_names": [
        "Studio Visual Journey"
      ],
      "repo": "JYeswak/zesttube",
      "repo_path": "/Users/josh/Developer/zesttube",
      "repo_view": {
        "defaultBranchRef": {
          "name": "main"
        },
        "nameWithOwner": "JYeswak/zesttube"
      },
      "required_checks": [
        "Studio Visual Journey"
      ],
      "schema_version": "branch_protection_apply.v1",
      "ts": "2026-05-20T07:25:32Z",
      "workflow_yml_checks": []
    },
    {
      "alias": "mobile-eats",
      "before": {},
      "branch": "main",
      "desired": {
        "allow_deletions": false,
        "allow_force_pushes": false,
        "enforce_admins": false,
        "required_linear_history": true,
        "required_pull_request_reviews": null,
        "required_status_checks": {
          "contexts": [
            "secrets-scan",
            "journey-contract",
            "journeys"
          ],
          "strict": true
        },
        "restrictions": null
      },
      "diff": "--- /dev/fd/63\t2026-05-20 01:25:35\n+++ /dev/fd/62\t2026-05-20 01:25:35\n@@ -1 +1,16 @@\n-{}\n+{\n+  \"allow_deletions\": false,\n+  \"allow_force_pushes\": false,\n+  \"enforce_admins\": false,\n+  \"required_linear_history\": true,\n+  \"required_pull_request_reviews\": null,\n+  \"required_status_checks\": {\n+    \"contexts\": [\n+      \"secrets-scan\",\n+      \"journey-contract\",\n+      \"journeys\"\n+    ],\n+    \"strict\": true\n+  },\n+  \"restrictions\": null\n+}",
      "discovery_decision": "workflow_yml_pr_trigger_filtered_recent_runs_metadata_only",
      "discovery_details": [
        {
          "check": "Mint feedback bead",
          "included": false,
          "job": "mint-feedback-bead",
          "matrix": null,
          "trigger_reason": "excluded:no_pull_request_trigger",
          "workflow": "feedback-bead-mint.yml"
        },
        {
          "check": "validate",
          "included": false,
          "job": "validate",
          "matrix": null,
          "trigger_reason": "excluded:pull_request_path_filter_present",
          "workflow": "mobile-eats-validation.yml"
        },
        {
          "check": "tenant-doctor",
          "included": false,
          "job": "tenant-doctor",
          "matrix": null,
          "trigger_reason": "excluded:pull_request_path_filter_present",
          "workflow": "secrets-doctor.yaml"
        },
        {
          "check": "secrets-scan",
          "included": true,
          "job": "secrets-scan",
          "matrix": null,
          "trigger_reason": "included:pull_request_all_branches",
          "workflow": "secrets-scan.yml"
        },
        {
          "check": "journey-contract",
          "included": true,
          "job": "journey-contract",
          "matrix": null,
          "trigger_reason": "included:pull_request_matches_main",
          "workflow": "user-journeys.yaml"
        },
        {
          "check": "journeys",
          "included": true,
          "job": "journeys",
          "matrix": null,
          "trigger_reason": "included:pull_request_matches_main",
          "workflow": "user-journeys.yaml"
        }
      ],
      "discovery_source": "workflow_yml",
      "mode": "dry-run",
      "outcome": "dry-run",
      "override_checks": null,
      "recent_run_names": [
        "Mobile Eats Validation",
        "Secrets Scan",
        "user-journeys"
      ],
      "repo": "JYeswak/mobile-eats",
      "repo_path": "/Users/josh/Developer/mobile-eats",
      "repo_view": {
        "defaultBranchRef": {
          "name": "main"
        },
        "nameWithOwner": "JYeswak/mobile-eats"
      },
      "required_checks": [
        "secrets-scan",
        "journey-contract",
        "journeys"
      ],
      "schema_version": "branch_protection_apply.v1",
      "ts": "2026-05-20T07:25:35Z",
      "workflow_yml_checks": [
        "secrets-scan",
        "journey-contract",
        "journeys"
      ]
    },
    {
      "alias": "clutterfreespaces",
      "before": {},
      "branch": "main",
      "desired": {
        "allow_deletions": false,
        "allow_force_pushes": false,
        "enforce_admins": false,
        "required_linear_history": true,
        "required_pull_request_reviews": null,
        "required_status_checks": {
          "contexts": [
            "Re-run audit three-source checks",
            "App Store submission readiness",
            "Root Jest baseline",
            "App Vitest",
            "Playwright surface tests",
            "Playwright customer journey",
            "Brand token lint",
            "CFS console next build",
            "CFS TDD aggregate",
            "Canonical CLI gate",
            "Local pre-GitHub gate"
          ],
          "strict": true
        },
        "restrictions": null
      },
      "diff": "--- /dev/fd/63\t2026-05-20 01:25:38\n+++ /dev/fd/62\t2026-05-20 01:25:38\n@@ -1 +1,24 @@\n-{}\n+{\n+  \"allow_deletions\": false,\n+  \"allow_force_pushes\": false,\n+  \"enforce_admins\": false,\n+  \"required_linear_history\": true,\n+  \"required_pull_request_reviews\": null,\n+  \"required_status_checks\": {\n+    \"contexts\": [\n+      \"Re-run audit three-source checks\",\n+      \"App Store submission readiness\",\n+      \"Root Jest baseline\",\n+      \"App Vitest\",\n+      \"Playwright surface tests\",\n+      \"Playwright customer journey\",\n+      \"Brand token lint\",\n+      \"CFS console next build\",\n+      \"CFS TDD aggregate\",\n+      \"Canonical CLI gate\",\n+      \"Local pre-GitHub gate\"\n+    ],\n+    \"strict\": true\n+  },\n+  \"restrictions\": null\n+}",
      "discovery_decision": "workflow_yml_pr_trigger_filtered_recent_runs_metadata_only",
      "discovery_details": [
        {
          "check": "Re-run audit three-source checks",
          "included": true,
          "job": "audit-tick",
          "matrix": null,
          "trigger_reason": "included:pull_request_matches_main",
          "workflow": "cfs-audit-tick.yml"
        },
        {
          "check": "rehearse",
          "included": false,
          "job": "rehearse",
          "matrix": null,
          "trigger_reason": "excluded:no_pull_request_trigger",
          "workflow": "cfs-backup-rehearsal.yml"
        },
        {
          "check": "dump-to-r2",
          "included": false,
          "job": "dump-to-r2",
          "matrix": null,
          "trigger_reason": "excluded:no_pull_request_trigger",
          "workflow": "cfs-backup-substrate.yml"
        },
        {
          "check": "Cross-tenant bleed assertions",
          "included": false,
          "job": "cross-tenant-smoke",
          "matrix": null,
          "trigger_reason": "excluded:pull_request_path_filter_present",
          "workflow": "cfs-cross-tenant-smoke.yml"
        },
        {
          "check": "probe-stage2",
          "included": false,
          "job": "probe-stage2",
          "matrix": null,
          "trigger_reason": "excluded:pull_request_path_filter_present",
          "workflow": "cfs-live-surface-probe-stage2.yml"
        },
        {
          "check": "Run CFS self-audit validation chain",
          "included": false,
          "job": "self-audit",
          "matrix": null,
          "trigger_reason": "excluded:no_pull_request_trigger",
          "workflow": "cfs-self-audit-cron.yml"
        },
        {
          "check": "App Store submission readiness",
          "included": true,
          "job": "submit-ready",
          "matrix": null,
          "trigger_reason": "included:pull_request_matches_main",
          "workflow": "cfs-submit-ready.yml"
        },
        {
          "check": "Root Jest baseline",
          "included": true,
          "job": "unit-jest",
          "matrix": null,
          "trigger_reason": "included:pull_request_matches_main",
          "workflow": "cfs-tdd.yml"
        },
        {
          "check": "App Vitest",
          "included": true,
          "job": "unit-vitest",
          "matrix": null,
          "trigger_reason": "included:pull_request_matches_main",
          "workflow": "cfs-tdd.yml"
        },
        {
          "check": "Playwright surface tests",
          "included": true,
          "job": "e2e-surfaces",
          "matrix": null,
          "trigger_reason": "included:pull_request_matches_main",
          "workflow": "cfs-tdd.yml"
        },
        {
          "check": "Playwright customer journey",
          "included": true,
          "job": "e2e-journey",
          "matrix": null,
          "trigger_reason": "included:pull_request_matches_main",
          "workflow": "cfs-tdd.yml"
        },
        {
          "check": "Brand token lint",
          "included": true,
          "job": "brand-token-lint",
          "matrix": null,
          "trigger_reason": "included:pull_request_matches_main",
          "workflow": "cfs-tdd.yml"
        },
        {
          "check": "CFS console next build",
          "included": true,
          "job": "next-build",
          "matrix": null,
          "trigger_reason": "included:pull_request_matches_main",
          "workflow": "cfs-tdd.yml"
        },
        {
          "check": "CFS TDD aggregate",
          "included": true,
          "job": "cfs-tdd",
          "matrix": null,
          "trigger_reason": "included:pull_request_matches_main",
          "workflow": "cfs-tdd.yml"
        },
        {
          "check": "Canonical CLI gate",
          "included": true,
          "job": "cli-discipline",
          "matrix": null,
          "trigger_reason": "included:pull_request_all_branches",
          "workflow": "cli-discipline.yml"
        },
        {
          "check": "Flag flip gate",
          "included": false,
          "job": "flag-flip-gate",
          "matrix": null,
          "trigger_reason": "excluded:pull_request_path_filter_present",
          "workflow": "flag-flip-gate.yml"
        },
        {
          "check": "testflight-beta",
          "included": false,
          "job": "testflight-beta",
          "matrix": null,
          "trigger_reason": "excluded:no_pull_request_trigger",
          "workflow": "ios-ci.yml"
        },
        {
          "check": "staging-smoke",
          "included": false,
          "job": "staging-smoke",
          "matrix": null,
          "trigger_reason": "excluded:no_pull_request_trigger",
          "workflow": "ios-ci.yml"
        },
        {
          "check": "Local pre-GitHub gate",
          "included": true,
          "job": "local-ci",
          "matrix": null,
          "trigger_reason": "included:pull_request_all_branches",
          "workflow": "local-ci.yml"
        }
      ],
      "discovery_source": "workflow_yml",
      "mode": "dry-run",
      "outcome": "dry-run",
      "override_checks": null,
      "recent_run_names": [
        "CFS Local CI",
        "CFS TDD",
        "CI",
        "Deploy"
      ],
      "repo": "JYeswak/ClutterFreeSpaces",
      "repo_path": "/Users/josh/Developer/clutterfreespaces",
      "repo_view": {
        "defaultBranchRef": {
          "name": "main"
        },
        "nameWithOwner": "JYeswak/ClutterFreeSpaces"
      },
      "required_checks": [
        "Re-run audit three-source checks",
        "App Store submission readiness",
        "Root Jest baseline",
        "App Vitest",
        "Playwright surface tests",
        "Playwright customer journey",
        "Brand token lint",
        "CFS console next build",
        "CFS TDD aggregate",
        "Canonical CLI gate",
        "Local pre-GitHub gate"
      ],
      "schema_version": "branch_protection_apply.v1",
      "ts": "2026-05-20T07:25:38Z",
      "workflow_yml_checks": [
        "Re-run audit three-source checks",
        "App Store submission readiness",
        "Root Jest baseline",
        "App Vitest",
        "Playwright surface tests",
        "Playwright customer journey",
        "Brand token lint",
        "CFS console next build",
        "CFS TDD aggregate",
        "Canonical CLI gate",
        "Local pre-GitHub gate"
      ]
    }
  ],
  "schema_version": "branch_protection_fleet_rollout.v1",
  "ts": "2026-05-20T07:25:38Z"
}
```

## FHBF9 Comparison Against Post-n2228 Dry-Run

| Repo | Previous required checks | Corrected required checks | Delta |
|---|---|---|---|
| JYeswak/flywheel | `Public Surface`, `Install Doctor Uninstall (${{ matrix.os }})`, `Package Release`, `Deploy Static Site`, `Fresh-clone preflight + journey-smoke (public path)` | `Public Surface`, `Install Doctor Uninstall (ubuntu-22.04)`, `Install Doctor Uninstall (macos-14)` | added: `Install Doctor Uninstall (ubuntu-22.04)`, `Install Doctor Uninstall (macos-14)`<br>removed: `Install Doctor Uninstall (${{ matrix.os }})`, `Package Release`, `Deploy Static Site`, `Fresh-clone preflight + journey-smoke (public path)` |
| JYeswak/skillos | `Public Readiness` | `Public Readiness` | no check-name delta<br>repo slug corrected from `JYeswak/zeststream-skillos`; `gh repo view` resolved `JYeswak/SkillOS` |
| JYeswak/zesttube | `Studio visual journey gate` | `Studio Visual Journey` | added: `Studio Visual Journey`<br>removed: `Studio visual journey gate` |
| JYeswak/mobile-eats | `Mint feedback bead`, `validate`, `tenant-doctor`, `secrets-scan`, `journey-contract`, `journeys` | `secrets-scan`, `journey-contract`, `journeys` | removed: `Mint feedback bead`, `validate`, `tenant-doctor` |
| JYeswak/ClutterFreeSpaces | `Re-run audit three-source checks`, `rehearse`, `dump-to-r2`, `Cross-tenant bleed assertions`, `probe-stage2`, `Run CFS self-audit validation chain`, `App Store submission readiness`, `Root Jest baseline`, `App Vitest`, `Playwright surface tests`, `Playwright customer journey`, `Brand token lint`, `CFS console next build`, `CFS TDD aggregate`, `Canonical CLI gate`, `Flag flip gate`, `testflight-beta`, `staging-smoke`, `Local pre-GitHub gate` | `Re-run audit three-source checks`, `App Store submission readiness`, `Root Jest baseline`, `App Vitest`, `Playwright surface tests`, `Playwright customer journey`, `Brand token lint`, `CFS console next build`, `CFS TDD aggregate`, `Canonical CLI gate`, `Local pre-GitHub gate` | removed: `rehearse`, `dump-to-r2`, `Cross-tenant bleed assertions`, `probe-stage2`, `Run CFS self-audit validation chain`, `Flag flip gate`, `testflight-beta`, `staging-smoke` |

## Flywheel PR Check Cross-Validation

Predicted required checks: `Public Surface`, `Install Doctor Uninstall (ubuntu-22.04)`, `Install Doctor Uninstall (macos-14)`.

| PR | Actual Actions check names | External app checks observed | Actions exact-match rate | All-check coverage note |
|---|---|---|---|---|
| #24 | `Public Surface`, `Install Doctor Uninstall (ubuntu-22.04)`, `Install Doctor Uninstall (macos-14)` | `GitGuardian Security Checks` | 100% | 75%; external app checks are not emitted from workflow YAML discovery |
| #25 | `Public Surface`, `Install Doctor Uninstall (ubuntu-22.04)`, `Install Doctor Uninstall (macos-14)` | `GitGuardian Security Checks` | 100% | 75%; external app checks are not emitted from workflow YAML discovery |

Actions exact-match acceptance rate: `100%` (threshold >=90%).
All-check coverage including external GitHub App checks: `75%`; `GitGuardian Security Checks` is outside workflow YAML discovery and should be handled as a separate explicit policy choice if Joshua wants it required.

## Live Command Evidence

- `gh pr checks 24 --repo JYeswak/flywheel --json name,state,link,bucket` captured above.
- `gh pr checks 25 --repo JYeswak/flywheel --json name,state,link,bucket` captured above.
- `gh repo view JYeswak/skillos --json nameWithOwner,defaultBranchRef,isPrivate,visibility` resolved `JYeswak/SkillOS` on default branch `main`.
- No GitHub branch-protection `--apply` run was executed; this report is dry-run only.
