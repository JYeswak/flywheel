# Supabase Local Mirror Discipline

Every Supabase schema, RLS, policy, grant, or security-sensitive database
change must flow through the local mirror substrate before remote mutation:

1. `supabase-local-mirror.sh` starts a local Supabase/Postgres mirror and pulls
   remote schema only. It must never pull production data.
2. `supabase-local-validate-and-push.sh` applies the intended migration or RLS
   fix locally, runs the RLS audit gate and fixtures, and writes a validation
   receipt.
3. Only after a green local validation receipt may the remote project receive a
   schema push.
4. `supabase-prepush-mirror-gate.sh` blocks Supabase schema/RLS pushes unless a
   validation receipt exists in `.flywheel/runtime/supabase-local-mirror-ledger.jsonl`
   within the last 60 minutes.

Anonymized fixture SQL is allowed for local testing. Real production data is
not allowed in the mirror.

## Emergency Path

Emergency direct-prod fixes require an explicit Joshua authorization row in:

`.flywheel/runtime/supabase-emergency-overrides.jsonl`

The pre-push gate reports that override ledger but does not auto-bypass. A
human must make the exceptional call, and the normal local-mirror receipt should
still be produced afterward when the emergency is stabilized.

## Secret And Audit Contract

- Load `SUPABASE_PERSONAL_ACCESS_TOKEN`, `SUPABASE_ACCESS_TOKEN`, and
  project-specific database URLs just-in-time via the configured Infisical
  loader.
- Do not persist tokens, database passwords, service role keys, or API response
  bodies that may contain secrets.
- Log Management API calls as method, endpoint, status, project, and purpose
  only.
- Remote schema pull is read-only and schema-only. `--data-only` is outside the
  contract.
