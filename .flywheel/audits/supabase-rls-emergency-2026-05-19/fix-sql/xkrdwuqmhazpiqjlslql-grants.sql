DO $flywheel_rls_grants_p0$
DECLARE
  item jsonb;
  sch text;
  tbl text;
BEGIN
  FOR item IN SELECT * FROM jsonb_array_elements('[{"schema":"public","table":"leads"},{"schema":"public","table":"organization_members"},{"schema":"public","table":"organizations"},{"schema":"public","table":"projects"},{"schema":"public","table":"users"}]'::jsonb)
  LOOP
    sch := item->>'schema';
    tbl := item->>'table';
    EXECUTE format('REVOKE ALL PRIVILEGES ON TABLE %I.%I FROM anon, authenticated', sch, tbl);
    EXECUTE format('GRANT ALL PRIVILEGES ON TABLE %I.%I TO service_role', sch, tbl);
  END LOOP;
END
$flywheel_rls_grants_p0$;
