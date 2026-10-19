-- Ühise klassifikaatorinimetuse domeeni kasutuse ja piirjuhtude kontroll.
DO $kontroll$
DECLARE
    v_domeen oid;
    v_kitsendus text;
    v_lause text;
    v_olek text;
BEGIN
    SELECT ty.oid INTO v_domeen FROM pg_catalog.pg_type AS ty
    INNER JOIN pg_catalog.pg_namespace AS n ON n.oid=ty.typnamespace
    WHERE n.nspname='public' AND ty.typname='klassifikaatori_nimetus' AND ty.typtype='d' AND ty.typnotnull;
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
    EXECUTE 'SELECT ''Õige nimetus''::public.klassifikaatori_nimetus';
    EXECUTE 'SELECT repeat(''Õ'',100)::public.klassifikaatori_nimetus';
    FOR v_lause,v_olek IN SELECT s.lause,s.olek FROM (VALUES
        ('SELECT NULL::public.klassifikaatori_nimetus','23502'),
        ('SELECT ''''::public.klassifikaatori_nimetus','23514'),
        ('SELECT E'' \t\n''::public.klassifikaatori_nimetus','23514')
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
        INSERT INTO public.brand (kood,nimetus) VALUES ('PIKK',repeat('Õ',101));
        RAISE EXCEPTION USING ERRCODE='XX000', MESSAGE='Liiga pikk nimetus võeti vastu',
            DETAIL='Veerg lubab kõige rohkem 100 märki.', HINT='Kontrolli domeeni baastüübi pikkust.';
    EXCEPTION WHEN string_data_right_truncation THEN NULL;
    END;
END;
$kontroll$;
