# flywheel-1gyiv Security Control Conformance Report

status: pass
must_clause_count: 77

## MUST Clause Matrix

| ID | Clause | Status |
|---|---|---|
| `$.schema_version.required` | $.schema_version is required | pass |
| `$.scope.required` | $.scope is required | pass |
| `$.settings_deny.required` | $.settings_deny is required | pass |
| `$.path_denies.required` | $.path_denies is required | pass |
| `$.bash_output_deny.required` | $.bash_output_deny is required | pass |
| `$.override_policy.required` | $.override_policy is required | pass |
| `$.fixture_policy.required` | $.fixture_policy is required | pass |
| `$.doctor_signals.required` | $.doctor_signals is required | pass |
| `$.issued_at.required` | $.issued_at is required | pass |
| `$.expires_at.required` | $.expires_at is required | pass |
| `$.issuer.required` | $.issuer is required | pass |
| `$.rollback_guard.required` | $.rollback_guard is required | pass |
| `$.additionalProperties` | $ MUST satisfy additionalProperties=False | pass |
| `$.schema_version.const` | $.schema_version MUST satisfy const='agent-security-control/v1' | pass |
| `$.scope.env.required` | $.scope.env is required | pass |
| `$.scope.applies_to.required` | $.scope.applies_to is required | pass |
| `$.scope.additionalProperties` | $.scope MUST satisfy additionalProperties=False | pass |
| `$.scope.env.const` | $.scope.env MUST satisfy const='sandbox' | pass |
| `$.scope.applies_to.minItems` | $.scope.applies_to MUST satisfy minItems=1 | pass |
| `$.settings_deny.template_path.required` | $.settings_deny.template_path is required | pass |
| `$.settings_deny.managed_block_id.required` | $.settings_deny.managed_block_id is required | pass |
| `$.settings_deny.minimum_rule_count.required` | $.settings_deny.minimum_rule_count is required | pass |
| `$.settings_deny.required_rule_ids.required` | $.settings_deny.required_rule_ids is required | pass |
| `$.settings_deny.additionalProperties` | $.settings_deny MUST satisfy additionalProperties=False | pass |
| `$.settings_deny.template_path.const` | $.settings_deny.template_path MUST satisfy const='.flywheel/security/v1/claude-settings-deny.json' | pass |
| `$.settings_deny.managed_block_id.const` | $.settings_deny.managed_block_id MUST satisfy const='canonical-agent-security-deny/v1' | pass |
| `$.settings_deny.minimum_rule_count.minimum` | $.settings_deny.minimum_rule_count MUST satisfy minimum=20 | pass |
| `$.settings_deny.required_rule_ids.minItems` | $.settings_deny.required_rule_ids MUST satisfy minItems=1 | pass |
| `$.settings_deny.required_rule_ids.uniqueItems` | $.settings_deny.required_rule_ids MUST satisfy uniqueItems=True | pass |
| `$.path_denies.minItems` | $.path_denies MUST satisfy minItems=1 | pass |
| `$.path_denies[].id.required` | $.path_denies[].id is required | pass |
| `$.path_denies[].pattern.required` | $.path_denies[].pattern is required | pass |
| `$.path_denies[].reason.required` | $.path_denies[].reason is required | pass |
| `$.path_denies[].severity.required` | $.path_denies[].severity is required | pass |
| `$.path_denies[].additionalProperties` | $.path_denies[] MUST satisfy additionalProperties=False | pass |
| `$.bash_output_deny.redaction_required.required` | $.bash_output_deny.redaction_required is required | pass |
| `$.bash_output_deny.emit_secret_values.required` | $.bash_output_deny.emit_secret_values is required | pass |
| `$.bash_output_deny.emit_secret_fragments.required` | $.bash_output_deny.emit_secret_fragments is required | pass |
| `$.bash_output_deny.classes.required` | $.bash_output_deny.classes is required | pass |
| `$.bash_output_deny.additionalProperties` | $.bash_output_deny MUST satisfy additionalProperties=False | pass |
| `$.bash_output_deny.redaction_required.const` | $.bash_output_deny.redaction_required MUST satisfy const=True | pass |
| `$.bash_output_deny.emit_secret_values.const` | $.bash_output_deny.emit_secret_values MUST satisfy const=False | pass |
| `$.bash_output_deny.emit_secret_fragments.const` | $.bash_output_deny.emit_secret_fragments MUST satisfy const=False | pass |
| `$.bash_output_deny.classes.minItems` | $.bash_output_deny.classes MUST satisfy minItems=1 | pass |
| `$.bash_output_deny.classes.uniqueItems` | $.bash_output_deny.classes MUST satisfy uniqueItems=True | pass |
| `$.override_policy.token.required` | $.override_policy.token is required | pass |
| `$.override_policy.requires.required` | $.override_policy.requires is required | pass |
| `$.override_policy.exact_scope_required.required` | $.override_policy.exact_scope_required is required | pass |
| `$.override_policy.max_ttl_hours.required` | $.override_policy.max_ttl_hours is required | pass |
| `$.override_policy.wildcards_allowed.required` | $.override_policy.wildcards_allowed is required | pass |
| `$.override_policy.additionalProperties` | $.override_policy MUST satisfy additionalProperties=False | pass |
| `$.override_policy.token.const` | $.override_policy.token MUST satisfy const='canonical-security-allow' | pass |
| `$.override_policy.requires.uniqueItems` | $.override_policy.requires MUST satisfy uniqueItems=True | pass |
| `$.override_policy.exact_scope_required.const` | $.override_policy.exact_scope_required MUST satisfy const=True | pass |
| `$.override_policy.max_ttl_hours.minimum` | $.override_policy.max_ttl_hours MUST satisfy minimum=1 | pass |
| `$.override_policy.max_ttl_hours.maximum` | $.override_policy.max_ttl_hours MUST satisfy maximum=24 | pass |
| `$.override_policy.wildcards_allowed.const` | $.override_policy.wildcards_allowed MUST satisfy const=False | pass |
| `$.fixture_policy.synthetic_only.required` | $.fixture_policy.synthetic_only is required | pass |
| `$.fixture_policy.production_secret_reads_allowed.required` | $.fixture_policy.production_secret_reads_allowed is required | pass |
| `$.fixture_policy.corpus_path.required` | $.fixture_policy.corpus_path is required | pass |
| `$.fixture_policy.additionalProperties` | $.fixture_policy MUST satisfy additionalProperties=False | pass |
| `$.fixture_policy.synthetic_only.const` | $.fixture_policy.synthetic_only MUST satisfy const=True | pass |
| `$.fixture_policy.production_secret_reads_allowed.const` | $.fixture_policy.production_secret_reads_allowed MUST satisfy const=False | pass |
| `$.fixture_policy.corpus_path.const` | $.fixture_policy.corpus_path MUST satisfy const='.flywheel/security/v1/secret-patterns.json' | pass |
| `$.doctor_signals.minItems` | $.doctor_signals MUST satisfy minItems=1 | pass |
| `$.doctor_signals[].name.required` | $.doctor_signals[].name is required | pass |
| `$.doctor_signals[].status_field.required` | $.doctor_signals[].status_field is required | pass |
| `$.doctor_signals[].failure_class.required` | $.doctor_signals[].failure_class is required | pass |
| `$.doctor_signals[].consumer.required` | $.doctor_signals[].consumer is required | pass |
| `$.doctor_signals[].additionalProperties` | $.doctor_signals[] MUST satisfy additionalProperties=False | pass |
| `$.rollback_guard.rollback_id.required` | $.rollback_guard.rollback_id is required | pass |
| `$.rollback_guard.before_state.required` | $.rollback_guard.before_state is required | pass |
| `$.rollback_guard.after_state.required` | $.rollback_guard.after_state is required | pass |
| `$.rollback_guard.idempotency_key.required` | $.rollback_guard.idempotency_key is required | pass |
| `$.rollback_guard.failure_class.required` | $.rollback_guard.failure_class is required | pass |
| `$.rollback_guard.recovery_hint.required` | $.rollback_guard.recovery_hint is required | pass |
| `$.rollback_guard.additionalProperties` | $.rollback_guard MUST satisfy additionalProperties=True | pass |

## Strict Fixture Matrix

| Fixture | Status | Failure Classes |
|---|---|---|
| `pass` | pass | none |
| `missing-deny` | fail | missing_deny_rules |
| `missing-hook` | fail | missing_security_precommit_hook |
| `leaked-token` | fail | leaked_synthetic_token |

## Redaction Report

- recall: 1.00
- precision: 1.00
- raw_values_emitted: false
- startup_auth_probe_output_shape: class_and_redaction_only
