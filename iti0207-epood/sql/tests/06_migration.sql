-- Ainult eraldi testandmebaasis: kontrollib täidetud vana või uue skeemi migratsiooni.
-- Varukoopia tehakse ENNE seda skripti. Migratsioon kinnitab oma tehingu ise.
\set ON_ERROR_STOP on
CREATE TEMP TABLE u6_enne (liik text,nimi text,sisu jsonb,PRIMARY KEY (liik,nimi));
INSERT INTO u6_enne (liik,nimi,sisu)
SELECT 'domeen','oid',to_jsonb(COALESCE(to_regtype('public.klassifikaatori_nimetus'),
    to_regtype('public.d_klassifikaatori_nimetus'))::oid);
DO $salvesta$
DECLARE
    v_tabel text;
BEGIN
    FOR v_tabel IN SELECT tablename FROM pg_tables WHERE schemaname='public'
    LOOP
        EXECUTE format('INSERT INTO u6_enne SELECT ''andmed'',%L,'
            'jsonb_agg(to_jsonb(t) ORDER BY to_jsonb(t)::text) FROM public.%I t',v_tabel,v_tabel);
    END LOOP;
    FOR v_tabel IN SELECT sequencename FROM pg_sequences WHERE schemaname='public'
    LOOP
        EXECUTE format('INSERT INTO u6_enne SELECT ''arvujada'',%L,jsonb_build_array(last_value,log_cnt,is_called) FROM public.%I',v_tabel,v_tabel);
    END LOOP;
END;
$salvesta$;
INSERT INTO u6_enne (liik,nimi,sisu)
SELECT 'kataloog','veerud',jsonb_agg(to_jsonb(a) ORDER BY a.attrelid,a.attnum)
FROM pg_attribute a JOIN pg_class t ON t.oid=a.attrelid
WHERE t.relnamespace='public'::regnamespace AND t.relkind IN ('r','v','S');
INSERT INTO u6_enne (liik,nimi,sisu)
SELECT 'kataloog','objektid',jsonb_agg(jsonb_build_object('oid',t.oid,'relname',t.relname,
    'reltype',t.reltype,'relkind',t.relkind,'relacl',t.relacl,'relnatts',t.relnatts) ORDER BY t.oid)
FROM pg_class t WHERE t.relnamespace='public'::regnamespace;
INSERT INTO u6_enne (liik,nimi,sisu)
SELECT 'kataloog','funktsioonid',jsonb_agg(to_jsonb(p) ORDER BY p.oid)
FROM pg_proc p WHERE p.pronamespace='public'::regnamespace;

\ir ../migrations/06_domeeni_nimi.sql
\ir ../migrations/06_domeeni_nimi.sql

DO $kontroll$
DECLARE
    v_enne record;
    v_sisu jsonb;
BEGIN
    IF (SELECT count(*) FROM u6_enne WHERE liik='andmed')<>24
        OR (SELECT count(*) FROM pg_tables WHERE schemaname='public')<>24 THEN
        RAISE EXCEPTION 'Migratsiooni test eeldab 24 baastabelit';
    END IF;
    IF to_jsonb('public.d_klassifikaatori_nimetus'::regtype::oid)
        IS DISTINCT FROM (SELECT sisu FROM u6_enne WHERE liik='domeen')
        OR to_regtype('public.klassifikaatori_nimetus') IS NOT NULL THEN
        RAISE EXCEPTION 'Domeeni identiteet ei säilinud või vana nimi jäi alles';
    END IF;
    FOR v_enne IN SELECT * FROM u6_enne WHERE liik='andmed'
    LOOP
        EXECUTE format('SELECT jsonb_agg(to_jsonb(t) ORDER BY to_jsonb(t)::text) FROM public.%I t',v_enne.nimi)
            INTO v_sisu;
        IF v_sisu IS DISTINCT FROM v_enne.sisu THEN
            RAISE EXCEPTION 'Tabeli % sisu muutus',v_enne.nimi;
        END IF;
    END LOOP;
    FOR v_enne IN SELECT * FROM u6_enne WHERE liik='arvujada'
    LOOP
        EXECUTE format('SELECT jsonb_build_array(last_value,log_cnt,is_called) FROM public.%I',v_enne.nimi) INTO v_sisu;
        IF v_sisu IS DISTINCT FROM v_enne.sisu THEN
            RAISE EXCEPTION 'Arvujada % seis muutus',v_enne.nimi;
        END IF;
    END LOOP;
    IF (SELECT jsonb_agg(to_jsonb(a) ORDER BY a.attrelid,a.attnum)
        FROM pg_attribute a JOIN pg_class t ON t.oid=a.attrelid
        WHERE t.relnamespace='public'::regnamespace AND t.relkind IN ('r','v','S'))
        IS DISTINCT FROM (SELECT sisu FROM u6_enne WHERE nimi='veerud')
        OR (SELECT jsonb_agg(jsonb_build_object('oid',t.oid,'relname',t.relname,
            'reltype',t.reltype,'relkind',t.relkind,'relacl',t.relacl,'relnatts',t.relnatts) ORDER BY t.oid) FROM pg_class t
            WHERE t.relnamespace='public'::regnamespace)
        IS DISTINCT FROM (SELECT sisu FROM u6_enne WHERE nimi='objektid')
        OR (SELECT jsonb_agg(to_jsonb(p) ORDER BY p.oid) FROM pg_proc p
            WHERE p.pronamespace='public'::regnamespace)
        IS DISTINCT FROM (SELECT sisu FROM u6_enne WHERE nimi='funktsioonid') THEN
        RAISE EXCEPTION 'Võrreldud veerukirjed, objektiväljad või funktsioonikirjed muutusid';
    END IF;
END;
$kontroll$;
DROP TABLE u6_enne;
\ir 03_domains.sql
