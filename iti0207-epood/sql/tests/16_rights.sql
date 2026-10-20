-- Rakenduse õiguste positiivsed ja keelatud juurdepääsu kontrollid.
DO $kontroll$
DECLARE
    v_funktsioon record;
BEGIN
    IF (SELECT count(*) FROM pg_proc AS p INNER JOIN pg_namespace AS n ON n.oid=p.pronamespace
        WHERE n.nspname='public')<>11 THEN
        RAISE EXCEPTION 'Kontroll eeldab kümmet lepingulist funktsiooni ja üht abifunktsiooni';
    END IF;
    FOR v_funktsioon IN SELECT p.oid,p.proname,p.proacl,p.proowner
        FROM pg_proc AS p INNER JOIN pg_namespace AS n ON n.oid=p.pronamespace
        WHERE n.nspname='public'
    LOOP
        IF has_function_privilege('epood_rakendus',v_funktsioon.oid,'EXECUTE')
                IS DISTINCT FROM (v_funktsioon.proname<>'f_leia_tootaja')
            OR has_function_privilege('epood_rakendus',v_funktsioon.oid,'EXECUTE WITH GRANT OPTION')
            OR EXISTS (SELECT 1 FROM aclexplode(COALESCE(v_funktsioon.proacl,
                acldefault('f',v_funktsioon.proowner))) AS a
                WHERE a.grantee=0 AND a.privilege_type='EXECUTE') THEN
            RAISE EXCEPTION 'Funktsiooni % käivitusõigused ei vasta minimaalsusele',v_funktsioon.proname;
        END IF;
    END LOOP;
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
SAVEPOINT funktsioonide_kontroll;
SELECT set_config('epood.kontroll_e_meil',(
    SELECT i.e_meil FROM tootaja AS t INNER JOIN isik AS i USING (isik_id)
    ORDER BY t.tootaja_id FETCH FIRST 1 ROW ONLY),true);
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
        'SELECT count(*) FROM public.f_leia_tootaja(p_e_meil:=''puuduv@example.invalid'')',
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
DO $funktsioonid$
DECLARE
    v_e_meil varchar:=current_setting('epood.kontroll_e_meil');
    v_ver text;
BEGIN
    IF f_registreeri_nutitelefon(p_kauba_kood:='APP001',p_nimetus:='Rakenduse kontrolltelefon',p_hind:=899::numeric,
            p_kirjeldus:='Rakenduserolli kaudu hallatav telefoni kontrollkirje.',
            p_pildi_aadress:=NULL::varchar,p_e_meil:=v_e_meil,p_brandi_kood:='APPLE',
            p_on_veekindel:=TRUE,p_on_sormejalelugeja:=FALSE,
            p_kaamera_kood_eesmine:=12.0::numeric,p_kaamera_kood_tagumine:=48.0::numeric,
            p_sisemalu_kood:=256::integer,p_diagonaali_kood:=6.1::numeric,
            p_protsessori_kood:='A16',p_ekraani_resolutsiooni_kood:='2556x1179') IS DISTINCT FROM 'APP001' THEN
        RAISE EXCEPTION 'Rakenduseroll ei saanud telefoni registreerida';
    END IF;
    IF f_lisa_kaup_kategooriasse(p_kauba_kood:='APP001',
            p_kauba_kategooria_kood:='MEESTELEFONID',p_e_meil:=v_e_meil) IS DISTINCT FROM 'APP001'
        OR f_lisa_kauba_variant(p_kauba_kood:='APP001',
            p_varv_kood:='WHITE',p_e_meil:=v_e_meil) IS DISTINCT FROM 'APP001' THEN
        RAISE EXCEPTION 'Rakenduseroll ei saanud seoseid lisada';
    END IF;
    SELECT xmin::text INTO v_ver FROM v_kaubad_muutmiseks WHERE kauba_kood='APP001';
    IF f_muuda_kaup(p_ver:=v_ver,p_kauba_kood_vana:='APP001',p_kauba_kood_uus:='APP001',
            p_nimetus:='Rakenduse kontrolltelefon',p_hind:=899::numeric,
            p_kirjeldus:='Rakenduserolli kaudu hallatav telefoni kontrollkirje.',
            p_pildi_aadress:=NULL::varchar,p_e_meil:=v_e_meil,p_brandi_kood:='APPLE',
            p_on_veekindel:=TRUE,p_on_sormejalelugeja:=FALSE,
            p_kaamera_kood_eesmine:=12.0::numeric,p_kaamera_kood_tagumine:=48.0::numeric,
            p_sisemalu_kood:=256::integer,p_diagonaali_kood:=6.1::numeric,
            p_protsessori_kood:='A16',p_ekraani_resolutsiooni_kood:='2556x1179') IS DISTINCT FROM 'APP001' THEN
        RAISE EXCEPTION 'Rakenduseroll ei saanud telefoni muuta';
    END IF;
    IF f_aktiveeri_kaup(p_kauba_kood:='APP001',p_e_meil:=v_e_meil) IS DISTINCT FROM 'APP001'
        OR f_muuda_kaup_mitteaktiivseks(p_kauba_kood:='APP001',p_e_meil:=v_e_meil) IS DISTINCT FROM 'APP001' THEN
        RAISE EXCEPTION 'Rakenduseroll ei saanud lubatud seisundimuudatusi teha';
    END IF;
    IF f_eemalda_kaup_kategooriast(p_kauba_kood:='APP001',
            p_kauba_kategooria_kood:='MEESTELEFONID',p_e_meil:=v_e_meil) IS DISTINCT FROM 'APP001'
        OR f_eemalda_kauba_variant(p_kauba_kood:='APP001',
            p_varv_kood:='WHITE',p_e_meil:=v_e_meil) IS DISTINCT FROM 'APP001'
        OR f_lopeta_kaup(p_kauba_kood:='APP001',p_e_meil:=v_e_meil) IS DISTINCT FROM 'APP001' THEN
        RAISE EXCEPTION 'Rakenduseroll ei saanud seoseid eemaldada või kaupa lõpetada';
    END IF;
    IF f_registreeri_nutitelefon(p_kauba_kood:='APP002',p_nimetus:='Rakenduse kontrolltelefon',p_hind:=899::numeric,
            p_kirjeldus:='Rakenduserolli kaudu hallatav telefoni kontrollkirje.',
            p_pildi_aadress:=NULL::varchar,p_e_meil:=v_e_meil,p_brandi_kood:='APPLE',
            p_on_veekindel:=TRUE,p_on_sormejalelugeja:=FALSE,
            p_kaamera_kood_eesmine:=12.0::numeric,p_kaamera_kood_tagumine:=48.0::numeric,
            p_sisemalu_kood:=256::integer,p_diagonaali_kood:=6.1::numeric,
            p_protsessori_kood:='A16',p_ekraani_resolutsiooni_kood:='2556x1179') IS DISTINCT FROM 'APP002'
        OR f_unusta_kaup(p_kauba_kood:='APP002') IS DISTINCT FROM 'APP002' THEN
        RAISE EXCEPTION 'Rakenduseroll ei saanud ootel kaupa unustada';
    END IF;
END;
$funktsioonid$;
RESET ROLE;
DO $tulemus$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM kaup AS k
        INNER JOIN kauba_seisundi_liik AS s USING (kauba_seisundi_liik_id)
        INNER JOIN nutitelefon AS n USING (kaup_id)
        WHERE k.kauba_kood='APP001' AND s.kood=4)
        OR EXISTS (SELECT 1 FROM kaup WHERE kauba_kood='APP002')
        OR EXISTS (SELECT 1 FROM kauba_kategooria_omamine AS o
            INNER JOIN kaup AS k USING (kaup_id) WHERE k.kauba_kood='APP001')
        OR EXISTS (SELECT 1 FROM kauba_variant AS o
            INNER JOIN kaup AS k USING (kaup_id) WHERE k.kauba_kood='APP001') THEN
        RAISE EXCEPTION 'Rakenduserolli funktsioonikutsed ei saavutanud järeltingimusi';
    END IF;
END;
$tulemus$;
ROLLBACK TO SAVEPOINT funktsioonide_kontroll;
RELEASE SAVEPOINT funktsioonide_kontroll;
