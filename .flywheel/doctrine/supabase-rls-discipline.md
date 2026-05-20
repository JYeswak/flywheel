# Supabase RLS Discipline

Every table exposed through a Supabase Data API schema must have Row Level
Security enabled. The default emergency posture is deny-all for anon and
authenticated roles, with an explicit service_role-only operational path.

## Contract

- Public-schema tables must have RLS enabled.
- Emergency fixes enable RLS first, then revoke anon/authenticated table grants.
- Service operations use the `service_role` path only; browser/client code must
  regain access through deliberate, narrow policies.
- Sensitive columns include names matching password, pwd, secret, api_key,
  personal, ssn, dob, email, or phone.
- The pre-push Tier 4.5 gate fails closed if any attached Supabase project has
  `rls_disabled_in_public` tables.

## Incident Anchor

On 2026-05-19 the emergency sweep audited seven Supabase projects, fixed 108
public-schema tables across six affected projects, and re-audited zero remaining
RLS-disabled public tables. ZestStream sensitive-column tables were explicitly
denied to anon/authenticated grants.
