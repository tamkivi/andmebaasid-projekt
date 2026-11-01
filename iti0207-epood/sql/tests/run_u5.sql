-- Käivita pärast esmast laadimist samade ühenduse muutujatega: psql ... -f tests/run_u5.sql
-- Korduv laadimine peab säilitama iga tabeli sisu, sealhulgas kontode parooliräsid.
\set ON_ERROR_STOP on
CREATE TEMP TABLE u5_sisu_enne (tabel text PRIMARY KEY,ridu bigint,sisu jsonb);
DO $salvesta$
DECLARE
    v_tabel text;
BEGIN
    FOR v_tabel IN SELECT tablename FROM pg_tables WHERE schemaname='public'
    LOOP
        EXECUTE format('INSERT INTO u5_sisu_enne SELECT %L,count(*),'
            'jsonb_agg(to_jsonb(t) ORDER BY to_jsonb(t)::text) FROM public.%I AS t',v_tabel,v_tabel);
    END LOOP;
END;
$salvesta$;

\ir ../run_u5.sql

DO $kontroll$
DECLARE
    v_enne record;
    v_ridu bigint;
    v_sisu jsonb;
BEGIN
    IF (SELECT count(*) FROM u5_sisu_enne)<24 OR
       (SELECT count(*) FROM u5_sisu_enne)<>(SELECT count(*) FROM pg_tables WHERE schemaname='public') THEN
        RAISE EXCEPTION 'Projekti tabelite hulk muutus või oli puudulik';
    END IF;
    FOR v_enne IN SELECT * FROM u5_sisu_enne
    LOOP
        EXECUTE format('SELECT count(*),jsonb_agg(to_jsonb(t) ORDER BY to_jsonb(t)::text) '
            'FROM public.%I AS t',v_enne.tabel) INTO v_ridu,v_sisu;
        IF v_ridu<>v_enne.ridu OR v_sisu IS DISTINCT FROM v_enne.sisu THEN
            RAISE EXCEPTION 'Tabeli % sisu muutus korduval laadimisel',v_enne.tabel;
        END IF;
    END LOOP;
END;
$kontroll$;
DROP TABLE u5_sisu_enne;

\ir 11_klassifikaatorid.sql
\ir 12_json_laadimine.sql
\ir 13_testandmed.sql
