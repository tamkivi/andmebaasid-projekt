-- Tuvastamise, seisundite, rollide ja ühekordse räsimise kontroll.
\set ON_ERROR_STOP on
START TRANSACTION;

DO $kataloog$
DECLARE
    v_naidisrasi text;
    v_meili_nr smallint;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_proc AS p JOIN pg_language AS l ON l.oid=p.prolang
        WHERE p.oid='public.f_on_kaubahaldur(text,text)'::regprocedure
            AND p.prorettype='boolean'::regtype AND l.lanname='plpgsql'
            AND p.prosecdef AND p.provolatile='s' AND NOT p.proisstrict
            AND p.proconfig @> ARRAY['search_path=public, pg_temp']
            AND obj_description(p.oid,'pg_proc') IS NOT NULL) THEN
        RAISE EXCEPTION 'Tuvastamisfunktsiooni omadused või kommentaar on valed';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='kasutajakonto' AND column_name='parool'
            AND data_type='character varying' AND character_maximum_length=60)
        OR EXISTS (SELECT 1 FROM information_schema.columns
            WHERE table_schema='public' AND table_name IN ('isik','kasutajakonto')
                AND column_name ~* '(sool|salt)') THEN
        RAISE EXCEPTION 'Parooliveerg peab mahutama bcrypt-räsi ega vaja eraldi soolaveergu';
    END IF;
    SELECT attnum INTO STRICT v_meili_nr FROM pg_attribute
        WHERE attrelid='public.isik'::regclass AND attname='e_meil';
    IF NOT EXISTS (SELECT 1 FROM pg_index
        WHERE indexrelid='public.ux_isik_e_meil'::regclass AND indisunique AND indisvalid
            AND pg_get_indexdef(indexrelid) LIKE '%lower((e_meil)::text)%')
        OR EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.isik'::regclass
            AND contype IN ('p','u') AND v_meili_nr=ANY(conkey))
        OR EXISTS (SELECT 1 FROM pg_constraint WHERE confrelid='public.isik'::regclass
            AND contype='f' AND v_meili_nr=ANY(confkey)) THEN
        RAISE EXCEPTION 'Meiliaadressi tõstutundetu unikaalsus ei vasta kavandatule';
    END IF;
    SELECT substring(prosrc FROM '\$2a\$12\$[./A-Za-z0-9]{53}') INTO v_naidisrasi
        FROM pg_proc WHERE oid='public.f_on_kaubahaldur(text,text)'::regprocedure;
    IF v_naidisrasi IS NULL OR length(v_naidisrasi)<>60
        OR EXISTS (SELECT 1 FROM kasutajakonto
            WHERE parool !~ '^\$2a\$12\$[./A-Za-z0-9]{53}$' OR parool=v_naidisrasi) THEN
        RAISE EXCEPTION 'Kontode ja näidisräsi algoritm või kulutegur ei ühti';
    END IF;
END;
$kataloog$;

-- Lähteparoolid jäävad tehingu sisse ega jõua väljundisse.
CREATE TEMP TABLE tuvastamise_sisend ON COMMIT DROP AS
SELECT i.isik_id,i.e_meil,jt.parool,t.tootaja_id,r.kood AS rolli_kood
FROM valine.Isik_sisend AS a
CROSS JOIN LATERAL JSON_TABLE(a.isik,'$.isikud[*]' COLUMNS (
    isikukood text PATH '$.isikukood',parool text PATH '$.parool')) AS jt
JOIN public.riik AS ri ON ri.kood=JSON_VALUE(a.isik,'$.riik')
JOIN public.isik AS i ON i.riik_id=ri.riik_id AND i.isikukood=jt.isikukood
LEFT JOIN public.tootaja AS t USING (isik_id)
LEFT JOIN public.tootaja_rolli_omamine AS o ON o.tootaja_id=t.tootaja_id
    AND o.alguse_aeg<=CURRENT_TIMESTAMP AND o.lopu_aeg>CURRENT_TIMESTAMP
LEFT JOIN public.tootaja_roll AS r USING (tootaja_roll_id);

CREATE FUNCTION pg_temp.f_kontrolli_tuvastamist(p_oodatav boolean)
RETURNS void LANGUAGE plpgsql AS $keha$
DECLARE
    v_tulemus boolean;
BEGIN
    SELECT public.f_on_kaubahaldur(e_meil,parool) INTO STRICT v_tulemus
        FROM tuvastamise_sisend WHERE rolli_kood='KAUBAHALDUR';
    IF v_tulemus IS DISTINCT FROM p_oodatav THEN
        RAISE EXCEPTION 'Tuvastamisfunktsiooni tulemus ei vasta oodatule';
    END IF;
END;
$keha$;
COMMENT ON FUNCTION pg_temp.f_kontrolli_tuvastamist(boolean) IS
'Võrdleb näidisandmete kaubahalduri tuvastamist oodatud tõeväärtusega.';

DO $sisend$
DECLARE
    v_sisend record;
    v_rida record;
    v_parool text;
BEGIN
    SELECT * INTO STRICT v_sisend FROM tuvastamise_sisend WHERE rolli_kood='KAUBAHALDUR';
    IF NOT public.f_on_kaubahaldur(v_sisend.e_meil,v_sisend.parool)
        OR NOT public.f_on_kaubahaldur(upper(v_sisend.e_meil),v_sisend.parool)
        OR NOT public.f_on_kaubahaldur(initcap(v_sisend.e_meil),v_sisend.parool) THEN
        RAISE EXCEPTION 'Õige parool ja meiliaadressi eri tõstud peavad sobima';
    END IF;
    FOREACH v_parool IN ARRAY ARRAY['kindlasti-vale-naidis',upper(v_sisend.parool),
            v_sisend.parool||' ',NULL] LOOP
        IF public.f_on_kaubahaldur(v_sisend.e_meil,v_parool) IS DISTINCT FROM FALSE THEN
            RAISE EXCEPTION 'Vale, muudetud tõstuga või NULL-parool peab ebaõnnestuma';
        END IF;
    END LOOP;
    FOREACH v_parool IN ARRAY ARRAY['puuduv@example.invalid','',NULL,' '||v_sisend.e_meil||' '] LOOP
        IF public.f_on_kaubahaldur(v_parool,v_sisend.parool) IS DISTINCT FROM FALSE THEN
            RAISE EXCEPTION 'Puuduv või tühikutega kasutajanimi peab ebaõnnestuma';
        END IF;
    END LOOP;
    FOR v_rida IN SELECT * FROM tuvastamise_sisend
        WHERE rolli_kood='JUHATAJA' OR tootaja_id IS NULL LOOP
        IF public.f_on_kaubahaldur(v_rida.e_meil,v_rida.parool) IS DISTINCT FROM FALSE THEN
            RAISE EXCEPTION 'Juhataja ja mittetöötaja ei tohi kaubahalduri rakendusse pääseda';
        END IF;
    END LOOP;
    IF NOT EXISTS (SELECT 1 FROM tuvastamise_sisend WHERE rolli_kood='JUHATAJA')
        OR NOT EXISTS (SELECT 1 FROM tuvastamise_sisend AS s
            JOIN klient USING (isik_id) WHERE s.tootaja_id IS NULL) THEN
        RAISE EXCEPTION 'Juhataja ja kliendi kontrollandmed puuduvad';
    END IF;
END;
$sisend$;

SAVEPOINT konto;
UPDATE kasutajakonto SET on_aktiivne=FALSE
WHERE isik_id=(SELECT isik_id FROM tuvastamise_sisend WHERE rolli_kood='KAUBAHALDUR');
SELECT pg_temp.f_kontrolli_tuvastamist(FALSE);
ROLLBACK TO konto;

SAVEPOINT konto_puudub;
DELETE FROM kasutajakonto
WHERE isik_id=(SELECT isik_id FROM tuvastamise_sisend WHERE rolli_kood='KAUBAHALDUR');
SELECT pg_temp.f_kontrolli_tuvastamist(FALSE);
ROLLBACK TO konto_puudub;

SAVEPOINT varjutamine;
CREATE TEMP TABLE isik(e_meil text);
SELECT pg_temp.f_kontrolli_tuvastamist(TRUE);
ROLLBACK TO varjutamine;

SAVEPOINT isiku_seisund;
UPDATE isik SET isiku_seisundi_liik_id=(SELECT isiku_seisundi_liik_id FROM isiku_seisundi_liik WHERE kood='SU')
WHERE isik_id=(SELECT isik_id FROM tuvastamise_sisend WHERE rolli_kood='KAUBAHALDUR');
SELECT pg_temp.f_kontrolli_tuvastamist(FALSE);
ROLLBACK TO isiku_seisund;

DO $tootaja_seisund$
DECLARE
    v_seisund record;
    v_vana smallint;
BEGIN
    SELECT tootaja_seisundi_liik_id INTO STRICT v_vana FROM tootaja
        WHERE tootaja_id=(SELECT tootaja_id FROM tuvastamise_sisend WHERE rolli_kood='KAUBAHALDUR');
    INSERT INTO tootaja_seisundi_liik(kood,nimetus) VALUES ('U10','Kontrollseisund');
    FOR v_seisund IN SELECT * FROM tootaja_seisundi_liik LOOP
        UPDATE tootaja SET tootaja_seisundi_liik_id=v_seisund.tootaja_seisundi_liik_id
            WHERE tootaja_id=(SELECT tootaja_id FROM tuvastamise_sisend WHERE rolli_kood='KAUBAHALDUR');
        PERFORM pg_temp.f_kontrolli_tuvastamist(v_seisund.kood IN ('KA','TO','PU'));
    END LOOP;
    UPDATE tootaja SET tootaja_seisundi_liik_id=v_vana
        WHERE tootaja_id=(SELECT tootaja_id FROM tuvastamise_sisend WHERE rolli_kood='KAUBAHALDUR');
    DELETE FROM tootaja_seisundi_liik WHERE kood='U10';
END;
$tootaja_seisund$;

SAVEPOINT rolli_lopp;
UPDATE tootaja_rolli_omamine SET lopu_aeg=date_trunc('second',CURRENT_TIMESTAMP)
WHERE tootaja_id=(SELECT tootaja_id FROM tuvastamise_sisend WHERE rolli_kood='KAUBAHALDUR')
    AND lopu_aeg='infinity';
-- Lõpuhetk enam sisse ei kuulu.
SELECT pg_temp.f_kontrolli_tuvastamist(FALSE);
ROLLBACK TO rolli_lopp;

SAVEPOINT rolli_algus;
UPDATE tootaja_rolli_omamine SET alguse_aeg=CURRENT_TIMESTAMP+INTERVAL '1 day'
WHERE tootaja_id=(SELECT tootaja_id FROM tuvastamise_sisend WHERE rolli_kood='KAUBAHALDUR')
    AND lopu_aeg='infinity';
SELECT pg_temp.f_kontrolli_tuvastamist(FALSE);
ROLLBACK TO rolli_algus;

SAVEPOINT rolli_aktiivsus;
UPDATE tootaja_roll SET on_aktiivne=FALSE WHERE kood='KAUBAHALDUR';
SELECT pg_temp.f_kontrolli_tuvastamist(FALSE);
ROLLBACK TO rolli_aktiivsus;

-- Sama tunnuse juures koodi muutmine peab muutma ka otsust.
SAVEPOINT klassifikaatori_kood;
UPDATE tootaja_roll SET kood='U10' WHERE kood='KAUBAHALDUR';
SELECT pg_temp.f_kontrolli_tuvastamist(FALSE);
ROLLBACK TO klassifikaatori_kood;

SAVEPOINT meili_unikaalsus;
DO $unikaalsus$
DECLARE
    v_kitsendus text;
BEGIN
    BEGIN
        UPDATE isik SET e_meil=(SELECT upper(e_meil) FROM tuvastamise_sisend WHERE rolli_kood='KAUBAHALDUR')
            WHERE isik_id=(SELECT isik_id FROM tuvastamise_sisend WHERE rolli_kood='JUHATAJA');
        RAISE EXCEPTION 'Meiliaadressi tõstuvariant peab rikkuma unikaalsust';
    EXCEPTION WHEN unique_violation THEN
        GET STACKED DIAGNOSTICS v_kitsendus=CONSTRAINT_NAME;
        IF v_kitsendus<>'ux_isik_e_meil' THEN RAISE EXCEPTION 'Vale unikaalsuse kontroll'; END IF;
    END;
END;
$unikaalsus$;
ROLLBACK TO meili_unikaalsus;

-- Uue konto avatekstiline näidisparool ja enne uuendust salvestatud räsid.
CREATE TEMP TABLE senised_rasid ON COMMIT DROP AS SELECT isik_id,parool FROM kasutajakonto;
INSERT INTO isik(isikukood,e_meil,riik_id,isiku_seisundi_liik_id,synni_kp,eesnimi)
SELECT 'U10MIG','u10-migratsioon@example.invalid',r.riik_id,s.isiku_seisundi_liik_id,DATE '2000-01-01','Näidis'
FROM riik AS r CROSS JOIN isiku_seisundi_liik AS s WHERE r.kood='EST' AND s.kood='EL';
INSERT INTO kasutajakonto(isik_id,parool)
SELECT isik_id,'naidis-parool-1' FROM isik WHERE isikukood='U10MIG';
\ir ../migrations/10_paroolide_rasimine.sql
DO $esimene$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM kasutajakonto AS k JOIN isik USING (isik_id)
        WHERE isikukood='U10MIG' AND k.parool ~ '^\$2a\$12\$[./A-Za-z0-9]{53}$'
            AND k.parool=laiendused.crypt('naidis-parool-1',k.parool))
        OR EXISTS (SELECT 1 FROM senised_rasid AS s JOIN kasutajakonto AS k USING (isik_id)
            WHERE s.parool IS DISTINCT FROM k.parool) THEN
        RAISE EXCEPTION 'Migratsioon peab muutma ainult avatekstilise konto parooli';
    END IF;
END;
$esimene$;
CREATE TEMP TABLE esimese_korra_rasid ON COMMIT DROP AS SELECT isik_id,parool FROM kasutajakonto;
\ir ../migrations/10_paroolide_rasimine.sql
DO $teine$
BEGIN
    IF EXISTS (SELECT 1 FROM esimese_korra_rasid AS s FULL JOIN kasutajakonto AS k USING (isik_id)
        WHERE s.parool IS DISTINCT FROM k.parool) THEN
        RAISE EXCEPTION 'Korduv migratsioon ei tohi ühtegi räsi muuta';
    END IF;
END;
$teine$;
INSERT INTO tootaja(isik_id,tootaja_seisundi_liik_id)
SELECT i.isik_id,s.tootaja_seisundi_liik_id FROM isik AS i CROSS JOIN tootaja_seisundi_liik AS s
WHERE i.isikukood='U10MIG' AND s.kood='TO';
INSERT INTO tootaja_rolli_omamine(tootaja_id,tootaja_roll_id,alguse_aeg)
SELECT t.tootaja_id,r.tootaja_roll_id,date_trunc('second',CURRENT_TIMESTAMP)
FROM tootaja AS t JOIN isik USING (isik_id) CROSS JOIN tootaja_roll AS r
WHERE isikukood='U10MIG' AND r.kood='KAUBAHALDUR';
DO $parast_migratsiooni$
BEGIN
    IF public.f_on_kaubahaldur('u10-migratsioon@example.invalid','naidis-parool-1') IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'Migreeritud konto ja rolli algushetk peavad sisselogimise lubama';
    END IF;
    PERFORM pg_temp.f_kontrolli_tuvastamist(TRUE);
END;
$parast_migratsiooni$;

ROLLBACK;
