# Clean Evidence

The evidence names secret classes only: agent_mail_registration_token,
bearer_token, github_pat, openai_key, aws_access_key_id.

Safe redactions:
- [REDACTED:agent_mail_registration_token]
- [CANARY_REDACTED:bearer_token_canary]

False-positive strings that must not match:
- CANARY_TEST_AKIA_PLACEHOLDER
- CANARY_TEST_BEARER_REDACTED
- CANARY_TEST_OPENAI_SK_<redacted>
