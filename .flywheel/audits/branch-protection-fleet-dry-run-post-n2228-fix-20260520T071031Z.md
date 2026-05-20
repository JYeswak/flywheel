# Branch Protection Fleet Dry-Run — 2026-05-20

Mode: `dry-run`
Outcome: `dry-run`

No GitHub branch-protection settings were mutated by this report when mode is `dry-run`.

| Repo | Outcome | Required checks | Review gate | enforce_admins | allow_force_pushes | allow_deletions |
|---|---|---|---|---|---|---|
| JYeswak/flywheel | `dry-run` | Public Surface, Install Doctor Uninstall (${{ matrix.os }}), Package Release, Deploy Static Site, Fresh-clone preflight + journey-smoke (public path) | `null` | `false` | `false` | `false` |
| JYeswak/zeststream-skillos | `dry-run` | Public Readiness | `null` | `false` | `false` | `false` |
| JYeswak/zesttube | `dry-run` | Studio visual journey gate | `null` | `false` | `false` | `false` |
| JYeswak/mobile-eats | `dry-run` | Mint feedback bead, validate, tenant-doctor, secrets-scan, journey-contract, journeys | `null` | `false` | `false` | `false` |
| JYeswak/ClutterFreeSpaces | `dry-run` | Re-run audit three-source checks, rehearse, dump-to-r2, Cross-tenant bleed assertions, probe-stage2, Run CFS self-audit validation chain, App Store submission readiness, Root Jest baseline, App Vitest, Playwright surface tests, Playwright customer journey, Brand token lint, CFS console next build, CFS TDD aggregate, Canonical CLI gate, Flag flip gate, testflight-beta, staging-smoke, Local pre-GitHub gate | `null` | `false` | `false` | `false` |

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
            "Install Doctor Uninstall (${{ matrix.os }})",
            "Package Release",
            "Deploy Static Site",
            "Fresh-clone preflight + journey-smoke (public path)"
          ],
          "strict": true
        },
        "restrictions": null
      },
      "diff": "--- /dev/fd/63\t2026-05-20 01:10:33\n+++ /dev/fd/62\t2026-05-20 01:10:33\n@@ -1 +1,18 @@\n-{}\n+{\n+  \"allow_deletions\": false,\n+  \"allow_force_pushes\": false,\n+  \"enforce_admins\": false,\n+  \"required_linear_history\": true,\n+  \"required_pull_request_reviews\": null,\n+  \"required_status_checks\": {\n+    \"contexts\": [\n+      \"Public Surface\",\n+      \"Install Doctor Uninstall (${{ matrix.os }})\",\n+      \"Package Release\",\n+      \"Deploy Static Site\",\n+      \"Fresh-clone preflight + journey-smoke (public path)\"\n+    ],\n+    \"strict\": true\n+  },\n+  \"restrictions\": null\n+}",
      "discovery_decision": "workflow_yml_preferred_recent_runs_no_exact_overlap",
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
      "required_checks": [
        "Public Surface",
        "Install Doctor Uninstall (${{ matrix.os }})",
        "Package Release",
        "Deploy Static Site",
        "Fresh-clone preflight + journey-smoke (public path)"
      ],
      "schema_version": "branch_protection_apply.v1",
      "ts": "2026-05-20T07:10:33Z",
      "workflow_yml_checks": [
        "Public Surface",
        "Install Doctor Uninstall (${{ matrix.os }})",
        "Package Release",
        "Deploy Static Site",
        "Fresh-clone preflight + journey-smoke (public path)"
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
      "diff": "--- /dev/fd/63\t2026-05-20 01:10:36\n+++ /dev/fd/62\t2026-05-20 01:10:36\n@@ -1 +1,14 @@\n-{}\n+{\n+  \"allow_deletions\": false,\n+  \"allow_force_pushes\": false,\n+  \"enforce_admins\": false,\n+  \"required_linear_history\": true,\n+  \"required_pull_request_reviews\": null,\n+  \"required_status_checks\": {\n+    \"contexts\": [\n+      \"Public Readiness\"\n+    ],\n+    \"strict\": true\n+  },\n+  \"restrictions\": null\n+}",
      "discovery_decision": "workflow_yml_preferred_recent_runs_no_exact_overlap",
      "discovery_source": "workflow_yml",
      "mode": "dry-run",
      "outcome": "dry-run",
      "override_checks": null,
      "recent_run_names": [
        "CI"
      ],
      "repo": "JYeswak/zeststream-skillos",
      "repo_path": "/Users/josh/Developer/skillos",
      "required_checks": [
        "Public Readiness"
      ],
      "schema_version": "branch_protection_apply.v1",
      "ts": "2026-05-20T07:10:36Z",
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
            "Studio visual journey gate"
          ],
          "strict": true
        },
        "restrictions": null
      },
      "diff": "--- /dev/fd/63\t2026-05-20 01:10:38\n+++ /dev/fd/62\t2026-05-20 01:10:38\n@@ -1 +1,14 @@\n-{}\n+{\n+  \"allow_deletions\": false,\n+  \"allow_force_pushes\": false,\n+  \"enforce_admins\": false,\n+  \"required_linear_history\": true,\n+  \"required_pull_request_reviews\": null,\n+  \"required_status_checks\": {\n+    \"contexts\": [\n+      \"Studio visual journey gate\"\n+    ],\n+    \"strict\": true\n+  },\n+  \"restrictions\": null\n+}",
      "discovery_decision": "workflow_yml_preferred_recent_runs_no_exact_overlap",
      "discovery_source": "workflow_yml",
      "mode": "dry-run",
      "outcome": "dry-run",
      "override_checks": null,
      "recent_run_names": [
        "Studio Visual Journey"
      ],
      "repo": "JYeswak/zesttube",
      "repo_path": "/Users/josh/Developer/zesttube",
      "required_checks": [
        "Studio visual journey gate"
      ],
      "schema_version": "branch_protection_apply.v1",
      "ts": "2026-05-20T07:10:38Z",
      "workflow_yml_checks": [
        "Studio visual journey gate"
      ]
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
            "Mint feedback bead",
            "validate",
            "tenant-doctor",
            "secrets-scan",
            "journey-contract",
            "journeys"
          ],
          "strict": true
        },
        "restrictions": null
      },
      "diff": "--- /dev/fd/63\t2026-05-20 01:10:41\n+++ /dev/fd/62\t2026-05-20 01:10:41\n@@ -1 +1,19 @@\n-{}\n+{\n+  \"allow_deletions\": false,\n+  \"allow_force_pushes\": false,\n+  \"enforce_admins\": false,\n+  \"required_linear_history\": true,\n+  \"required_pull_request_reviews\": null,\n+  \"required_status_checks\": {\n+    \"contexts\": [\n+      \"Mint feedback bead\",\n+      \"validate\",\n+      \"tenant-doctor\",\n+      \"secrets-scan\",\n+      \"journey-contract\",\n+      \"journeys\"\n+    ],\n+    \"strict\": true\n+  },\n+  \"restrictions\": null\n+}",
      "discovery_decision": "workflow_yml_preferred_recent_runs_no_exact_overlap",
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
      "required_checks": [
        "Mint feedback bead",
        "validate",
        "tenant-doctor",
        "secrets-scan",
        "journey-contract",
        "journeys"
      ],
      "schema_version": "branch_protection_apply.v1",
      "ts": "2026-05-20T07:10:41Z",
      "workflow_yml_checks": [
        "Mint feedback bead",
        "validate",
        "tenant-doctor",
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
            "rehearse",
            "dump-to-r2",
            "Cross-tenant bleed assertions",
            "probe-stage2",
            "Run CFS self-audit validation chain",
            "App Store submission readiness",
            "Root Jest baseline",
            "App Vitest",
            "Playwright surface tests",
            "Playwright customer journey",
            "Brand token lint",
            "CFS console next build",
            "CFS TDD aggregate",
            "Canonical CLI gate",
            "Flag flip gate",
            "testflight-beta",
            "staging-smoke",
            "Local pre-GitHub gate"
          ],
          "strict": true
        },
        "restrictions": null
      },
      "diff": "--- /dev/fd/63\t2026-05-20 01:10:43\n+++ /dev/fd/62\t2026-05-20 01:10:43\n@@ -1 +1,32 @@\n-{}\n+{\n+  \"allow_deletions\": false,\n+  \"allow_force_pushes\": false,\n+  \"enforce_admins\": false,\n+  \"required_linear_history\": true,\n+  \"required_pull_request_reviews\": null,\n+  \"required_status_checks\": {\n+    \"contexts\": [\n+      \"Re-run audit three-source checks\",\n+      \"rehearse\",\n+      \"dump-to-r2\",\n+      \"Cross-tenant bleed assertions\",\n+      \"probe-stage2\",\n+      \"Run CFS self-audit validation chain\",\n+      \"App Store submission readiness\",\n+      \"Root Jest baseline\",\n+      \"App Vitest\",\n+      \"Playwright surface tests\",\n+      \"Playwright customer journey\",\n+      \"Brand token lint\",\n+      \"CFS console next build\",\n+      \"CFS TDD aggregate\",\n+      \"Canonical CLI gate\",\n+      \"Flag flip gate\",\n+      \"testflight-beta\",\n+      \"staging-smoke\",\n+      \"Local pre-GitHub gate\"\n+    ],\n+    \"strict\": true\n+  },\n+  \"restrictions\": null\n+}",
      "discovery_decision": "workflow_yml_preferred_recent_runs_no_exact_overlap",
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
      "required_checks": [
        "Re-run audit three-source checks",
        "rehearse",
        "dump-to-r2",
        "Cross-tenant bleed assertions",
        "probe-stage2",
        "Run CFS self-audit validation chain",
        "App Store submission readiness",
        "Root Jest baseline",
        "App Vitest",
        "Playwright surface tests",
        "Playwright customer journey",
        "Brand token lint",
        "CFS console next build",
        "CFS TDD aggregate",
        "Canonical CLI gate",
        "Flag flip gate",
        "testflight-beta",
        "staging-smoke",
        "Local pre-GitHub gate"
      ],
      "schema_version": "branch_protection_apply.v1",
      "ts": "2026-05-20T07:10:43Z",
      "workflow_yml_checks": [
        "Re-run audit three-source checks",
        "rehearse",
        "dump-to-r2",
        "Cross-tenant bleed assertions",
        "probe-stage2",
        "Run CFS self-audit validation chain",
        "App Store submission readiness",
        "Root Jest baseline",
        "App Vitest",
        "Playwright surface tests",
        "Playwright customer journey",
        "Brand token lint",
        "CFS console next build",
        "CFS TDD aggregate",
        "Canonical CLI gate",
        "Flag flip gate",
        "testflight-beta",
        "staging-smoke",
        "Local pre-GitHub gate"
      ]
    }
  ],
  "schema_version": "branch_protection_fleet_rollout.v1",
  "ts": "2026-05-20T07:10:43Z"
}
```
