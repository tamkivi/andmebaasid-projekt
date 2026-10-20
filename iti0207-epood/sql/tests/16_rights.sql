-- Rakenduse õiguste positiivsed ja keelatud juurdepääsu kontrollid.
DO $kontroll$
BEGIN
    IF has_schema_privilege('epood_rakendus','valine','USAGE,CREATE')
        OR has_schema_privilege('epood_rakendus','laiendused','USAGE,CREATE')
        OR has_server_privilege('epood_rakendus','minu_testandmete_server_apex','USAGE')
        OR has_table_privilege('epood_rakendus','valine.riik_sisend','SELECT,INSERT,UPDATE,DELETE')
        OR has_table_privilege('epood_rakendus','valine.isik_sisend','SELECT,INSERT,UPDATE,DELETE') THEN
        RAISE EXCEPTION 'Rakenduseroll ei tohi kasutada välise allika objekte';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname='epood_rakendus'
        AND NOT rolcanlogin AND NOT rolsuper AND NOT rolcreatedb AND NOT rolcreaterole
        AND NOT rolreplication AND NOT rolbypassrls) THEN
        RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Ootamatu kontrolltulemus',
            DETAIL='Lugemisroll ei tohi anda haldus- ega sisselogimisõigusi.', HINT='Kontrolli rolli atribuute.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM pg_catalog.pg_class AS t
        INNER JOIN pg_catalog.pg_namespace AS n ON n.oid=t.relnamespace
        WHERE n.nspname='public' AND t.relkind IN ('r','S')
          AND (CASE WHEN t.relkind='S' THEN has_sequence_privilege('epood_rakendus',t.oid,'USAGE,SELECT,UPDATE')
                  ELSE has_table_privilege('epood_rakendus',t.oid,'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') END
               OR EXISTS (SELECT 1 FROM aclexplode(COALESCE(t.relacl,CASE WHEN t.relkind='S' THEN acldefault('S',t.relowner) ELSE acldefault('r',t.relowner) END)) AS a WHERE a.grantee=0))
    ) THEN
        RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Liigsed baasobjektide õigused',
            DETAIL='Rakenduserollil ja PUBLIC-il ei tohi olla baastabelite ega generaatorite õigusi.',
            HINT='Jaga rakendusele ainult vaadete lugemisõigusi.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM pg_catalog.pg_class AS t
        INNER JOIN pg_catalog.pg_namespace AS n ON n.oid=t.relnamespace
        WHERE n.nspname='public' AND t.relkind='v'
          AND (NOT has_table_privilege('epood_rakendus',t.oid,'SELECT')
               OR has_table_privilege('epood_rakendus',t.oid,'INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
               OR has_table_privilege('epood_rakendus',t.oid,'SELECT WITH GRANT OPTION'))
    ) THEN
        RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Vale vaateõigus',
            DETAIL='Vaadete SELECT peab olema lubatud ilma õiguste edasijagamise ja muutmisõiguseta.',
            HINT='Kontrolli vaadete GRANT-lauseid.';
    END IF;
END;
$kontroll$;
SET LOCAL ROLE epood_rakendus;
SELECT kauba_kood,nimetus FROM public.v_kaubad;
SELECT kauba_kood,nimetus FROM public.v_kaubad_muutmiseks;
SELECT kauba_kood,kategooria_kood FROM public.v_kauba_kategooriad;
SELECT kauba_kood,varvi_kood FROM public.v_kauba_variandid;
DO $keelatud$
DECLARE
    v_lause text;
    v_ridu bigint;
BEGIN
    FOR v_lause IN SELECT unnest(ARRAY[
        'SELECT count(*) FROM valine.riik_sisend',
        'SELECT count(*) FROM valine.isik_sisend',
        'CREATE TABLE valine.keelatud (kood integer)',
        'SELECT count(*) FROM public.isik',
        'SELECT count(*) FROM public.kasutajakonto',
        'INSERT INTO public.brand (kood,nimetus) VALUES (''TEST'',''Katse'')',
        'CREATE TABLE public.keelatud (kood integer)'])
    LOOP
        BEGIN
            EXECUTE v_lause;
            RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Keelatud toiming õnnestus',
                DETAIL='Rakenduseroll peab selle toimingu tagasi lükkama SQLSTATE-iga 42501.',
                HINT='Kontrolli minimaalseid õigusi.';
        EXCEPTION WHEN insufficient_privilege THEN NULL;
        END;
    END LOOP;
    -- DO INSTEAD NOTHING reeglid eemaldavad muutmise enne õiguse kontrolli.
    FOR v_lause IN SELECT unnest(ARRAY[
        'UPDATE public.v_kaubad SET nimetus=''Katse''',
        'DELETE FROM public.v_kaubad',
        'INSERT INTO public.v_kaubad (kauba_kood) VALUES (''ABC123'')'])
    LOOP
        EXECUTE v_lause;
        GET DIAGNOSTICS v_ridu=ROW_COUNT;
        IF v_ridu<>0 THEN
            RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Lugemisvaate muutmiskatse mõjus',
                DETAIL='Toimeta reegel peab tagastama null mõjutatud rida.', HINT='Kontrolli vaate reegleid.';
        END IF;
    END LOOP;
END;
$keelatud$;
RESET ROLE;
