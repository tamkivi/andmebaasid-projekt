-- Ühise klassifikaatorinimetuse domeeni kasutuse ja piirjuhtude kontroll.
-- Käivita eraldi sessioonis; kõik kontrollmuudatused pööratakse tagasi.
\set ON_ERROR_STOP on
START TRANSACTION;
DO $kontroll$
DECLARE
    v_domeen oid;
    v_kitsendus text;
    v_lause text;
    v_olek text;
BEGIN
    SELECT ty.oid INTO v_domeen FROM pg_catalog.pg_type AS ty
    INNER JOIN pg_catalog.pg_namespace AS n ON n.oid=ty.typnamespace
    WHERE n.nspname='public' AND ty.typname='d_klassifikaatori_nimetus' AND ty.typtype='d' AND ty.typnotnull;
    IF v_domeen IS NULL OR (
        SELECT count(*) FROM pg_catalog.pg_attribute AS a
        INNER JOIN pg_catalog.pg_class AS t ON t.oid=a.attrelid
        INNER JOIN pg_catalog.pg_namespace AS n ON n.oid=t.relnamespace
        WHERE n.nspname='public' AND t.relkind='r' AND a.atttypid=v_domeen
          AND a.attnum>0 AND NOT a.attisdropped
    ) <> 15 THEN
        RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Ootamatu kontrolltulemus',
            DETAIL='Ühine domeen peab olema kasutusel kõigis 15 klassifikaatorinimetuse veerus.',
            HINT='Kontrolli domeeni ja baastabelite deklaratsioone.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM pg_catalog.pg_attribute AS a
        INNER JOIN pg_catalog.pg_constraint AS c ON c.conrelid=a.attrelid AND a.attnum=ANY(c.conkey)
        WHERE a.atttypid=v_domeen AND c.contype IN ('f','c')
    ) THEN
        RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Domeeni reeglid dubleeritud',
            DETAIL='Nimetuse domeen kuulub mitteviitavatele veergudele ja selle CHECK-i tabelis ei korrata.',
            HINT='Hoia ühine väärtusreegel domeeni juures.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM pg_catalog.pg_attribute AS a
        JOIN pg_catalog.pg_class AS t ON t.oid=a.attrelid
        LEFT JOIN pg_catalog.pg_attrdef AS d ON d.adrelid=t.oid AND d.adnum=a.attnum
        WHERE t.relnamespace='public'::regnamespace AND t.relkind='r'
            AND a.atttypid=v_domeen AND a.attnum>0 AND NOT a.attisdropped
            AND (a.attnotnull OR d.oid IS NOT NULL OR a.attname<>'nimetus')
    ) OR EXISTS (
        SELECT 1 FROM pg_catalog.pg_type WHERE oid=v_domeen
            AND (typbasetype<>'varchar'::regtype OR typtypmod<>104 OR typdefault IS NOT NULL)
    ) OR (SELECT count(*) FROM pg_catalog.pg_constraint WHERE contypid=v_domeen AND contype='c')<>1 THEN
        RAISE EXCEPTION 'Domeeni tüüp või kasutus ei vasta ühisele dubleerimata nimetuse reeglile';
    END IF;
    IF (SELECT array_agg(t.relname::text ORDER BY t.relname)
        FROM pg_catalog.pg_attribute AS a
        JOIN pg_catalog.pg_class AS t ON t.oid=a.attrelid
        WHERE t.relnamespace='public'::regnamespace AND t.relkind='r'
            AND a.atttypid=v_domeen AND a.attnum>0 AND NOT a.attisdropped)
        IS DISTINCT FROM ARRAY['brand','diagonaal','ekraani_resolutsioon',
            'isiku_seisundi_liik','kaamera','kauba_kategooria','kauba_kategooria_tyyp',
            'kauba_seisundi_liik','kliendi_seisundi_liik','protsessor','riik','sisemalu',
            'tootaja_roll','tootaja_seisundi_liik','varv']::text[] THEN
        RAISE EXCEPTION 'Domeeni tuleb kasutada järjekindlalt ainult kõigi 15 klassifikaatori nimetuses';
    END IF;
    EXECUTE 'SELECT ''Õige nimetus''::public.d_klassifikaatori_nimetus';
    EXECUTE 'SELECT repeat(''Õ'',100)::public.d_klassifikaatori_nimetus';
    FOR v_lause,v_olek IN SELECT s.lause,s.olek FROM (VALUES
        ('SELECT NULL::public.d_klassifikaatori_nimetus','23502'),
        ('SELECT ''''::public.d_klassifikaatori_nimetus','23514'),
        ('SELECT E'' \t\n''::public.d_klassifikaatori_nimetus','23514')
    ) AS s(lause,olek)
    LOOP
        BEGIN
            EXECUTE v_lause;
            RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Vigane domeeniväärtus võeti vastu',
                DETAIL='Domeen peab keelama puuduva või sisutu nimetuse.', HINT='Kontrolli domeeni kitsendusi.';
        EXCEPTION WHEN not_null_violation OR check_violation THEN
            GET STACKED DIAGNOSTICS v_kitsendus=CONSTRAINT_NAME;
            IF SQLSTATE<>v_olek OR (v_olek='23514' AND v_kitsendus<>'ck_klassifikaatori_nimetus_sisu') THEN
                RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Vale domeenierand',
                    DETAIL='Domeeni SQLSTATE või kitsenduse nimi ei vasta oodatule.', HINT='Kontrolli nimetatud reeglit.';
            END IF;
        END;
    END LOOP;
    BEGIN
        INSERT INTO public.brand (brand_id,kood,nimetus) VALUES (-306,'PIKK',repeat('Õ',101));
        RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Liiga pikk nimetus võeti vastu',
            DETAIL='Veerg lubab kõige rohkem 100 märki.', HINT='Kontrolli domeeni baastüübi pikkust.';
    EXCEPTION WHEN string_data_right_truncation THEN NULL;
    END;
END;
$kontroll$;

-- Tabeliveergude kaudu kontrollitakse mõlemat eraldiseisvat mitte-välisvõtme kasutust.
INSERT INTO public.brand (brand_id,kood,nimetus) VALUES (-306,'U6KONTROLL','Õige bränd');
INSERT INTO public.varv (varv_id,kood,nimetus) VALUES (-306,'U6KONTROLL','Õige värv');
DO $veerud$
DECLARE
    v_tabel text;
    v_vaartus text;
BEGIN
    FOREACH v_tabel IN ARRAY ARRAY['brand','varv']
    LOOP
        FOREACH v_vaartus IN ARRAY ARRAY['', E' \t\n', NULL]
        LOOP
            BEGIN
                EXECUTE format('UPDATE public.%I SET nimetus=$1 WHERE kood=''U6KONTROLL''',v_tabel)
                    USING v_vaartus;
                RAISE EXCEPTION 'Vigane nimetus lubati tabelis %',v_tabel;
            EXCEPTION WHEN check_violation OR not_null_violation THEN
                IF SQLSTATE<>(CASE WHEN v_vaartus IS NULL THEN '23502' ELSE '23514' END) THEN
                    RAISE EXCEPTION 'Vale SQLSTATE tabeli % vigase nimetuse korral: %',v_tabel,SQLSTATE;
                END IF;
            END;
        END LOOP;
    END LOOP;
    BEGIN
        DROP DOMAIN public.d_klassifikaatori_nimetus RESTRICT;
        RAISE EXCEPTION 'Kasutuses oleva domeeni kustutamine peab ebaõnnestuma';
    EXCEPTION WHEN dependent_objects_still_exist THEN NULL;
    END;
END;
$veerud$;

-- Ü6 §4.1: domeenitüübilise tühja alampäringu NULL võib NOT NULL kontrollist mööduda.
CREATE TEMP TABLE u6_null_erijuht (nimetus public.d_klassifikaatori_nimetus);
INSERT INTO u6_null_erijuht (nimetus)
VALUES ((SELECT nimetus FROM u6_null_erijuht WHERE false));
DO $erijuht$
BEGIN
    IF (SELECT count(*) FROM u6_null_erijuht WHERE nimetus IS NULL)<>1 THEN
        RAISE EXCEPTION 'Domeeni NOT NULL erijuhu käitumine on muutunud; vaata dokumentatsiooni';
    END IF;
END;
$erijuht$;
ROLLBACK;
