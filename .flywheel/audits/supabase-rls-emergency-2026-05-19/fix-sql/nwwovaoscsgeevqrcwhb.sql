DO $flywheel_rls_p0$
DECLARE
  item jsonb;
  sch text;
  tbl text;
  pol text;
BEGIN
  FOR item IN SELECT * FROM jsonb_array_elements('[{"schema":"public","table":"__drizzle_migrations__"}]'::jsonb)
  LOOP
    sch := item->>'schema';
    tbl := item->>'table';
    pol := 'flywheel_p0_service_role_' || substr(md5(sch || '.' || tbl), 1, 12);
    EXECUTE format('ALTER TABLE %I.%I ENABLE ROW LEVEL SECURITY', sch, tbl);
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', pol, sch, tbl);
    EXECUTE format('CREATE POLICY %I ON %I.%I FOR ALL TO service_role USING (true) WITH CHECK (true)', pol, sch, tbl);
  END LOOP;
END
$flywheel_rls_p0$;
